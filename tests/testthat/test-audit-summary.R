test_that("audit_summary() lists exclusions with the share of their input", {
  s <- audit_summary(summary_fixture())
  expect_identical(names(s), c("step", "kind", "cause", "detail",
                               "n_records", "share_records",
                               "n_households", "qty_g"))
  expect_identical(s$step, c("s1", "s2", "s1", "s3"))
  expect_identical(s$kind, c("excluded", "flagged", "filled",
                             "external_change"))
  expect_identical(s$n_records, c(2L, 3L, 2L, 1L))
  expect_equal(s$share_records, c(0.2, NA, 0.25, NA), tolerance = 1e-12)
  expect_identical(s$qty_g, c(50, 30, 20, NA))
})

test_that("audit_summary() of a log with nothing to report has no rows", {
  s <- audit_summary(fixture_carrier())
  expect_identical(nrow(s), 0L)
  expect_identical(ncol(s), 8L)
})

test_that("audit_summary() gives NA share for an input of zero records", {
  x <- fixture_carrier()
  attr(x, "audit") <- audit_row("s", "t", c("input", "excluded"),
                                c("all", "a"), c(0, 0))
  expect_identical(audit_summary(x)$share_records, NA_real_)
})

test_that("audit_summary() needs a table with a log", {
  expect_error(audit_summary(data.frame(a = 1)),
               class = "hcesfort_error_audit")
  expect_error(audit_summary(), class = "hcesfort_error_argument")
})

test_that("audit_record() appends one row, by default for the table of x", {
  x <- fixture_carrier()
  y <- audit_record(x, step = "adapter::combine", kind = "excluded",
                    cause = "duplicated_section", n_records = 2,
                    n_households = NA_integer_, qty_g = 12.5)
  log <- audit_log(y)
  expect_identical(nrow(log), 2L)
  expect_identical(log[1, ], audit_log(x))
  expect_identical(log$table[[2]], "acquisitions")
  expect_identical(log$n_records[[2]], 2L)
  expect_identical(log$n_households[[2]], NA_integer_)
  expect_identical(log$qty_g[[2]], 12.5)
  expect_identical(log$detail[[2]], NA_character_)
  # The data are untouched; the adapter's step has no input row, so its
  # share in the summary is NA.
  for (col in names(x)) expect_identical(y[[col]], x[[col]])
  z <- audit_record(x, "adapter::combine", "note", "a", 1, table = "other",
                    detail = "flour")
  expect_identical(audit_log(z)$table[[2]], "other")
  expect_identical(audit_log(z)$detail[[2]], "flour")
  expect_identical(audit_summary(y)$share_records, NA_real_)
})

test_that("audit_record() refuses a step of the package", {
  x <- fixture_carrier()
  for (step in c("convert_units", "hcesfort::convert_units")) {
    err <- expect_error(
      audit_record(x, step, "note", "a", 1),
      class = "hcesfort_error_argument"
    )
    expect_identical(err$arg, "step")
  }
})

test_that("audit_record() checks every argument", {
  x <- fixture_carrier()
  bad <- list(
    list(kind = "input"), list(kind = "external_change"),
    list(cause = "Not Snake"), list(cause = ""), list(n_records = -1),
    list(n_records = 1.5), list(n_records = NA), list(n_households = 0.5),
    list(qty_g = -1), list(qty_g = Inf), list(detail = 3),
    list(table = c("a", "b")), list(step = NA_character_)
  )
  base <- list(x = x, step = "a::b", kind = "note", cause = "c",
               n_records = 1)
  for (b in bad) {
    args <- utils::modifyList(base, b)
    err <- expect_error(do.call(audit_record, args),
                        class = "hcesfort_error_argument")
    expect_identical(err$arg, names(b))
  }
  expect_error(audit_record(data.frame(a = 1), "a::b", "note", "c", 1),
               class = "hcesfort_error_audit")
  expect_error(audit_record(x, "a::b", "note"),
               class = "hcesfort_error_argument")
})
