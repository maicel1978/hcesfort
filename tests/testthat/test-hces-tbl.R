test_that("new_hces_tbl() builds a classed tibble with its attributes", {
  x <- fixture_carrier()
  expect_identical(
    class(x),
    c("hces_acquisitions", "hces_tbl", "tbl_df", "tbl", "data.frame")
  )
  expect_identical(attr(x, "audit_rows"), 3L)
  expect_identical(attr(x, "audit_key"), "record_id")
  expect_identical(carrier_table(x), "acquisitions")
})

test_that("require_hces() accepts a carrier of the class", {
  x <- fixture_carrier()
  expect_identical(require_hces(x, "hces_acquisitions"), x)
  expect_identical(require_hces(x, "hces_tbl"), x)
})

test_that("require_hces() fails after summarise()", {
  x <- fixture_carrier()
  totals <- dplyr::summarise(x, qty_g = sum(qty_g), .by = household_id)
  f <- function(tab) require_hces(tab, "hces_acquisitions")
  err <- expect_error(f(totals), class = "hcesfort_error_audit")
  expect_identical(err$arg, "tab")
  expect_identical(err$expected, "hces_acquisitions")
  expect_match(conditionMessage(err), "restore_audit", fixed = TRUE)
  expect_identical(rlang::call_name(err$call), "f")
})

test_that("require_hces() fails on a carrier of another class", {
  expect_error(
    require_hces(fixture_carrier(), "hces_members"),
    class = "hcesfort_error_audit"
  )
})

test_that("restore_audit() repairs a table that lost its log", {
  x <- fixture_carrier()
  y <- dplyr::ungroup(dplyr::mutate(
    dplyr::group_by(x, household_id), share = qty_g / sum(qty_g)
  ))
  expect_false(inherits(y, "hces_tbl"))
  z <- restore_audit(y, from = x)
  expect_s3_class(z, "hces_acquisitions")
  expect_identical(audit_log(z), audit_log(x))
  expect_identical(attr(z, "audit_rows"), 3L)
  # 100 / 350, 250 / 350, 50 / 50
  expect_equal(z$share, c(100 / 350, 250 / 350, 1))
})

test_that("restore_audit() ungroups a grouped table", {
  x <- fixture_carrier()
  z <- restore_audit(dplyr::group_by(x, household_id), from = x)
  expect_false(dplyr::is_grouped_df(z))
  expect_s3_class(z, "hces_acquisitions")
})

test_that("restore_audit() rejects a table with foreign keys", {
  x <- fixture_carrier()
  y <- data.frame(record_id = c(1L, 99L), qty_g = c(1, 2))
  err <- expect_error(restore_audit(y, from = x),
                      class = "hcesfort_error_join")
  expect_identical(err$n, 1L)
})

test_that("restore_audit() rejects a table without the key", {
  x <- fixture_carrier()
  totals <- dplyr::summarise(x, qty_g = sum(qty_g), .by = household_id)
  err <- expect_error(restore_audit(totals, from = x),
                      class = "hcesfort_error_join")
  expect_identical(err$columns, "record_id")
})

test_that("restore_audit() rejects a key of another type", {
  x <- fixture_carrier()
  y <- data.frame(record_id = c("1", "2"))
  expect_error(restore_audit(y, from = x), class = "hcesfort_error_join")
})

test_that("restore_audit() checks its arguments", {
  x <- fixture_carrier()
  expect_error(restore_audit(list(record_id = 1L), from = x),
               class = "hcesfort_error_argument")
  expect_error(restore_audit(x, from = data.frame(record_id = 1L)),
               class = "hcesfort_error_audit")
})

test_that("a filter() between two steps yields one external_change row", {
  x <- fixture_carrier()
  y <- dplyr::filter(x, qty_g > 60) # drops record 3: 1 record removed
  y <- audit_check_rows(y, step = "next_step")
  log <- audit_log(y)
  expect_identical(nrow(log), 2L)
  expect_identical(log$kind[[2]], "external_change")
  expect_identical(log$cause[[2]], "rows_changed_outside_package")
  expect_identical(log$n_records[[2]], 1L)
  expect_identical(log$detail[[2]], "removed")
  expect_identical(attr(y, "audit_rows"), 2L)
  # A second check without change writes nothing more.
  expect_identical(audit_check_rows(y, "again"), y)
})

test_that("added rows are recorded as added", {
  x <- fixture_carrier()
  y <- dplyr::bind_rows(x, x[1, ]) # 1 record added
  log <- audit_log(audit_check_rows(y, step = "next_step"))
  expect_identical(log$n_records[[2]], 1L)
  expect_identical(log$detail[[2]], "added")
})

test_that("a filter() before restore_audit() is recorded at the next step", {
  x <- fixture_carrier()
  y <- dplyr::filter(dplyr::group_by(x, household_id), qty_g > 60)
  z <- audit_check_rows(restore_audit(y, from = x), step = "next_step")
  expect_identical(audit_log(z)$n_records[[2]], 1L)
})

test_that("the log does not depend on row order", {
  x <- fixture_carrier()
  shuffled <- restore_audit(x[c(3, 1, 2), ], from = x)
  a <- audit_check_rows(dplyr::filter(x, qty_g > 60), "s")
  b <- audit_check_rows(dplyr::filter(shuffled, qty_g > 60), "s")
  expect_identical(audit_log(a), audit_log(b))
})
