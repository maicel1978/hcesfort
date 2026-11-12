test_that("an empty log has the eight columns and their types", {
  log <- new_audit_log()
  expect_identical(nrow(log), 0L)
  expect_identical(
    vapply(log, typeof, ""),
    c(step = "character", table = "character", kind = "character",
      cause = "character", n_records = "integer", n_households = "integer",
      qty_g = "double", detail = "character")
  )
})

test_that("audit_row() recycles and coerces", {
  rows <- audit_row(
    step = "s", table = "t", kind = "note",
    cause = c("missing_age", "missing_sex"), n_records = c(2, 1)
  )
  expect_identical(nrow(rows), 2L)
  expect_identical(names(rows), names(new_audit_log()))
  expect_identical(rows$n_records, c(2L, 1L))
  expect_identical(rows$n_households, c(NA_integer_, NA_integer_))
  expect_identical(rows$qty_g, c(NA_real_, NA_real_))
})

test_that("audit_row() rejects an unknown kind", {
  expect_error(
    audit_row("s", "t", kind = "dropped", cause = "x", n_records = 1),
    "unknown audit kind"
  )
})

test_that("audit_add() appends in order", {
  x <- fixture_carrier()
  x <- audit_add(x, step = "a", table = "acquisitions", kind = "note",
                 cause = "missing_unit", n_records = 1)
  x <- audit_add(x, step = "b", table = "acquisitions", kind = "flagged",
                 cause = "outlier", n_records = 2)
  expect_identical(audit_log(x)$step, c("fixture", "a", "b"))
  expect_identical(audit_log(x)$n_records, c(3L, 1L, 2L))
})

test_that("audit_merge() keeps the primary log first", {
  x <- fixture_carrier()
  y <- audit_add(fixture_carrier(), step = "y", table = "members",
                 kind = "note", cause = "missing_age", n_records = 1)
  y <- new_hces_tbl(y, "hces_members", audit = audit_log(y)[2, ],
                    key = "record_id")
  merged <- audit_merge(x, y)
  expect_identical(audit_log(merged)$step, c("fixture", "y"))
  expect_identical(audit_log(merged)$table, c("acquisitions", "members"))
})

test_that("audit_combine() keeps a branch shared by two inputs once", {
  # x and y both derive from the same validated table (row "fixture");
  # y adds one note. The merged log holds "fixture" once, then the note.
  x <- fixture_carrier()
  y <- audit_add(fixture_carrier(), step = "y", table = "members",
                 kind = "note", cause = "missing_age", n_records = 1)
  log <- audit_combine(x, y)
  expect_identical(log$step, c("fixture", "y"))
  expect_identical(audit_combine(y, x), audit_log(y))
  expect_identical(audit_combine(), new_audit_log())
})

test_that("audit_merge() with no other table leaves the log unchanged", {
  x <- fixture_carrier()
  expect_identical(audit_log(audit_merge(x)), audit_log(x))
})

test_that("audit_log() fails on a table without a log", {
  err <- expect_error(
    audit_log(data.frame(a = 1)),
    class = "hcesfort_error_audit"
  )
  expect_identical(err$expected, "hces_tbl")
})

test_that("audit_add() starts a log on a table without one", {
  x <- audit_add(data.frame(a = 1), step = "s", table = "t", kind = "input",
                 cause = "all", n_records = 1)
  expect_identical(nrow(attr(x, "audit")), 1L)
})

test_that("audit_union() appends the rows not held, with multiplicity", {
  r <- function(cause) audit_row("s", "t", "note", cause, 1L)
  a <- dplyr::bind_rows(r("x"), r("y"), r("y"))
  b <- dplyr::bind_rows(r("y"), r("z"), r("y"), r("y"), r("x"))
  u <- audit_union(a, b)
  expect_identical(u$cause, c("x", "y", "y", "z", "y"))
  expect_identical(audit_union(a, a), a)
  expect_identical(audit_union(a, new_audit_log()), a)
  expect_identical(audit_union(new_audit_log(), b), b)
})
