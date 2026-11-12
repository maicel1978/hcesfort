# validate_food_groups(): fixture of three foods in two groups, built here.

fixture_food_groups <- function() {
  data.frame(
    food_code = c("rice", "bread", "beans"),
    food_group = c("cereals", "cereals", "pulses"),
    source = c("test fixture", "test fixture", "SOURCE PENDING")
  )
}

test_that("a valid grouping passes, with its pending source counted", {
  g <- validate_food_groups(fixture_food_groups())
  expect_s3_class(g, c("hces_food_groups", "hces_tbl"))
  log <- audit_log(g)
  expect_identical(log$cause, c("all", "source_pending"))
  expect_identical(log$n_records, c(3L, 1L))
  expect_identical(attr(g, "audit_key"), "food_code")
})

test_that("food codes may be whole numbers", {
  g <- fixture_food_groups()
  g$food_code <- c(10L, 20L, 30L)
  expect_s3_class(validate_food_groups(g), "hces_food_groups")
})

test_that("a duplicated food is a key error", {
  g <- fixture_food_groups()
  g$food_code[3] <- "rice"
  err <- expect_error(validate_food_groups(g), class = "hcesfort_error_key")
  expect_identical(err$rows, 3L)
})

test_that("a missing, empty or reserved group is a value error", {
  g <- fixture_food_groups()
  g$food_group[2] <- NA
  expect_error(validate_food_groups(g), class = "hcesfort_error_value")
  g <- fixture_food_groups()
  g$food_group[c(1, 3)] <- c("  ", "unclassified")
  err <- expect_error(validate_food_groups(g), class = "hcesfort_error_value")
  expect_identical(err$rows, c(1L, 3L))
  expect_match(conditionMessage(err), "reserved")
})

test_that("missing columns, wrong types and missing argument", {
  g <- fixture_food_groups()
  expect_error(validate_food_groups(g[-3]), class = "hcesfort_error_schema")
  g$food_group <- factor(g$food_group)
  expect_error(validate_food_groups(g), class = "hcesfort_error_schema")
  expect_error(validate_food_groups(), class = "hcesfort_error_argument")
  expect_error(validate_food_groups(list()), class = "hcesfort_error_schema")
})

test_that("its schema is listed by hces_schema()", {
  s <- hces_schema("food_groups")
  expect_identical(s$column, c("food_code", "food_group", "source"))
  expect_identical(s$key, c(TRUE, FALSE, FALSE))
})
