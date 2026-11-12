test_that("abort_hcesfort() raises a condition with both classes", {
  err <- expect_error(
    abort_hcesfort("schema", "Bad table.", table = "households"),
    class = "hcesfort_error_schema"
  )
  expect_s3_class(err, "hcesfort_error")
  expect_s3_class(err, "rlang_error")
  expect_identical(err$table, "households")
})

test_that("every error type has its class", {
  for (type in error_types) {
    expect_error(
      abort_hcesfort(type, "x"),
      class = paste0("hcesfort_error_", type)
    )
  }
})

test_that("abort_hcesfort() interpolates in the caller's environment", {
  f <- function() {
    n_bad <- 3L
    cols <- c("weight", "psu")
    abort_hcesfort("value", c(
      "{n_bad} bad row{?s}.",
      "x" = "Columns: {.field {cols}}.",
      "i" = "Fix them."
    ), n = n_bad)
  }
  err <- expect_error(f(), class = "hcesfort_error_value")
  msg <- cli::ansi_strip(conditionMessage(err))
  expect_match(msg, "3 bad rows.", fixed = TRUE)
  expect_match(msg, "weight", fixed = TRUE)
  expect_match(msg, "Fix them.", fixed = TRUE)
  expect_identical(err$n, 3L)
})

test_that("abort_hcesfort() reports the calling function", {
  f <- function() abort_hcesfort("argument", "Wrong.", arg = "y")
  err <- expect_error(f(), class = "hcesfort_error_argument")
  expect_identical(err$arg, "y")
  expect_identical(rlang::call_name(err$call), "f")
})

test_that("an unknown error type is an internal error", {
  expect_error(abort_hcesfort("nonsense", "x"), class = "rlang_error")
  expect_error(abort_hcesfort("nonsense", "x"), "unknown error type")
})

test_that("tryCatch() on hcesfort_error catches every type", {
  caught <- tryCatch(
    abort_hcesfort("join", "x"),
    hcesfort_error = function(e) "caught"
  )
  expect_identical(caught, "caught")
})
