test_that("unit factors: each factor type passes", {
  u <- validate_unit_factors(fixture_unit_factors())
  expect_s3_class(u, c("hces_unit_factors", "hces_tbl"))
  log <- audit_log(u)
  expect_identical(log$cause, "all")
  expect_identical(log$n_records, 4L)
  expect_identical(log$n_households, NA_integer_)
})

test_that("unit factors: an all-NA logical food_code means generic", {
  u <- fixture_unit_factors()[c(1, 3), ]
  u$food_code <- NA
  expect_s3_class(validate_unit_factors(u), "hces_unit_factors")
})

test_that("unit factors: duplicated unit and food are key errors", {
  u <- fixture_unit_factors()
  u$food_code[2] <- NA # two generic rows for "lb": row 2 duplicates row 1
  err <- expect_error(validate_unit_factors(u), class = "hcesfort_error_key")
  expect_identical(err$rows, 2L)
  u <- fixture_unit_factors()
  u$food_code <- NULL # without food_code the key is unit: row 2 duplicate
  err <- expect_error(validate_unit_factors(u), class = "hcesfort_error_key")
  expect_identical(err$rows, 2L)
  u <- fixture_unit_factors()
  u$unit[1] <- NA
  expect_error(validate_unit_factors(u), class = "hcesfort_error_key")
})

test_that("unit factors: impossible values are value errors", {
  u <- fixture_unit_factors()
  u$factor[1] <- 0
  u$factor_type[2] <- "mass"
  u$piece_weight_g[4] <- -1
  err <- expect_error(validate_unit_factors(u), class = "hcesfort_error_value")
  expect_identical(err$rows, c(1L, 2L, 4L))
  u <- fixture_unit_factors()
  u$factor <- as.character(u$factor)
  expect_error(validate_unit_factors(u), class = "hcesfort_error_schema")
})

test_that("crosswalk: notes counted by hand", {
  log <- audit_log(validate_crosswalk(fixture_crosswalk()))
  expect_identical(log$cause, c("all", "unmatched_food", "not_validated",
                                "missing_edible_portion"))
  expect_identical(log$n_records, c(3L, 1L, 2L, 1L))
})

test_that("crosswalk: validated row without match_type is a value error", {
  x <- fixture_crosswalk()
  x$match_type[1] <- NA
  err <- expect_error(validate_crosswalk(x), class = "hcesfort_error_value")
  expect_identical(err$rows, 1L)
  expect_identical(err$columns, "match_type")
})

test_that("crosswalk: edible portion must be in (0, 1]", {
  for (bad in c(0, 1.2)) {
    x <- fixture_crosswalk()
    x$edible_portion[1] <- bad
    expect_error(validate_crosswalk(x), class = "hcesfort_error_value")
  }
  x <- fixture_crosswalk()
  x$yield_factor <- c(2.5, NA, NA)
  expect_s3_class(validate_crosswalk(x), "hces_crosswalk")
  x <- fixture_crosswalk()
  x$food_code[3] <- "rice"
  expect_error(validate_crosswalk(x), class = "hcesfort_error_key")
})

test_that("crosswalk: revalidation runs the cross-column check again", {
  x <- validate_crosswalk(fixture_crosswalk())
  expect_identical(validate_crosswalk(x), x)
  x$match_type[1] <- NA
  expect_error(validate_crosswalk(x), class = "hcesfort_error_value")
})

test_that("vehicles: one food with two vehicles passes", {
  v <- validate_vehicles(fixture_vehicles())
  expect_s3_class(v, "hces_vehicles")
  log <- audit_log(v)
  expect_identical(log$cause, c("all", "source_pending"))
  expect_identical(log$n_records, c(3L, 1L))
})

test_that("vehicles: fraction 0 and duplicated pairs fail", {
  v <- fixture_vehicles()
  v$vehicle_fraction[1] <- 0
  expect_error(validate_vehicles(v), class = "hcesfort_error_value")
  v <- fixture_vehicles()
  v$vehicle[3] <- "wheat_flour"
  expect_error(validate_vehicles(v), class = "hcesfort_error_key")
})
