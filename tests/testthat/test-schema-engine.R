test_that("type_ok() follows the four types", {
  expect_true(type_ok(c("a", NA), "id"))
  expect_true(type_ok(1:2, "id"))
  expect_true(type_ok(c(1, 2, NA), "id"))
  expect_false(type_ok(c(1, 1.5), "id"))
  expect_false(type_ok(factor("a"), "id"))
  expect_false(type_ok(TRUE, "id"))
  expect_true(type_ok(c(1.5, NA), "number"))
  expect_true(type_ok(1L, "number"))
  expect_false(type_ok("1", "number"))
  expect_true(type_ok(NA, "flag"))
  expect_false(type_ok(1L, "flag"))
  expect_true(type_ok("a", "text"))
  expect_false(type_ok(factor("a"), "text"))
})

test_that("in_bounds() respects open and closed ends", {
  v <- c(-1, 0, 0.5, 1, 2, NA, Inf)
  expect_identical(in_bounds(v, "[0, 1]"),
                   c(FALSE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE))
  expect_identical(in_bounds(v, "(0, 1]"),
                   c(FALSE, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE))
  expect_identical(in_bounds(v, "(0, Inf)"),
                   c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE))
})

test_that("rule_text() describes intervals and vocabularies", {
  rule <- function(...) rule_text(schema_col("a", description = "", ...))
  expect_identical(rule(type = "number", bounds = "(0, Inf)"), "(> 0)")
  expect_identical(rule(type = "number", bounds = "[0, Inf)"), "(>= 0)")
  expect_identical(rule(type = "number", bounds = "[0, 1]"), "(in [0, 1])")
  expect_identical(rule(type = "text", values = c("x", "y")), "(x, y)")
  expect_identical(rule(type = "text"), "")
})

test_that("problem_bullet() shows at most five rows", {
  expect_identical(problem_bullet("bad", integer(0)), character(0))
  expect_identical(problem_bullet("bad", 4L), "bad: 1 row (4)")
  expect_identical(problem_bullet("bad", 1:7),
                   "bad: 7 rows (1, 2, 3, 4, 5, ...)")
})

test_that("cli_escape() keeps braces literal", {
  expect_identical(cli_escape("a {b} c"), "a {{b}} c")
  msg <- tryCatch(abort_hcesfort("value", c(x = cli_escape("{oops}"))),
                  error = conditionMessage)
  expect_match(msg, "{oops}", fixed = TRUE)
})

# A two-column schema built by hand: key `id`, `share` in [0, 1].
toy_schema <- function() {
  new_schema(
    "toy", "id",
    schema_col("id", "id", "identifier"),
    schema_col("share", "number", "a share", na = TRUE, bounds = "[0, 1]")
  )
}

test_that("check_schema() rejects a non-data-frame", {
  err <- expect_error(check_schema(list(id = 1), toy_schema()),
                      class = "hcesfort_error_schema")
  expect_identical(err$table, "toy")
})

test_that("check_schema() runs its stages in order", {
  expect_error(check_schema(data.frame(share = 1), toy_schema()),
               class = "hcesfort_error_schema")
  expect_error(check_schema(data.frame(id = 1.5, share = 1), toy_schema()),
               class = "hcesfort_error_schema")
  # A duplicated key is reported before an impossible value.
  expect_error(check_schema(data.frame(id = c(1, 1), share = c(1, 2)),
                            toy_schema()),
               class = "hcesfort_error_key")
  err <- expect_error(
    check_schema(data.frame(id = 1:3, share = c(2, NA, -1)), toy_schema()),
    class = "hcesfort_error_value"
  )
  expect_identical(err$rows, c(1L, 3L))
  x <- data.frame(id = 1:2, share = c(0, NA))
  expect_identical(check_schema(x, toy_schema()), x)
})
