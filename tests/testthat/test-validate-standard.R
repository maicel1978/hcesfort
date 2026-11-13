test_that("valid tables pass and return their class", {
  h <- validate_households(fixture_households())
  m <- validate_members(fixture_members())
  a <- validate_acquisitions(fixture_acquisitions())
  expect_s3_class(h, c("hces_households", "hces_tbl", "tbl_df"))
  expect_s3_class(m, c("hces_members", "hces_tbl", "tbl_df"))
  expect_s3_class(a, c("hces_acquisitions", "hces_tbl", "tbl_df"))
  expect_identical(attr(m, "audit_key"), c("household_id", "member_id"))
})

test_that("extra columns are kept untouched", {
  h <- validate_households(fixture_households())
  expect_identical(h$region, c("north", "north", "south"))
  expect_identical(names(h), names(fixture_households()))
})

test_that("the log counts input and notes by hand", {
  # households: 3 records, 3 households, no notes.
  log <- audit_log(validate_households(fixture_households()))
  expect_identical(log$kind, "input")
  expect_identical(log$n_records, 3L)
  expect_identical(log$n_households, 3L)
  # members: 4 records in 2 households; 1 missing age, 1 missing sex.
  log <- audit_log(validate_members(fixture_members()))
  expect_identical(log$cause, c("all", "missing_age", "missing_sex"))
  expect_identical(log$kind, c("input", "note", "note"))
  expect_identical(log$n_records, c(4L, 1L, 1L))
  expect_identical(log$n_households, c(2L, 1L, 1L))
  # acquisitions: 4 records; 1 missing quantity, 1 missing unit, 1 excluded
  # by the adapter's rule, the last two in household 2.
  log <- audit_log(validate_acquisitions(fixture_acquisitions()))
  expect_identical(log$cause, c("all", "missing_quantity", "missing_unit",
                                "not_included"))
  expect_identical(log$n_records, c(4L, 1L, 1L, 1L))
  expect_true(all(is.na(log$qty_g)))
})

test_that("food module nonresponse is counted", {
  h <- fixture_households()
  h$food_module_response <- c(TRUE, FALSE, TRUE)
  log <- audit_log(validate_households(h))
  expect_identical(log$cause, c("all", "food_module_nonresponse"))
  expect_identical(log$n_records, c(3L, 1L))
})

test_that("validating twice equals validating once", {
  for (v in list(
    list(validate_households, fixture_households()),
    list(validate_members, fixture_members()),
    list(validate_acquisitions, fixture_acquisitions())
  )) {
    once <- v[[1]](v[[2]])
    expect_identical(v[[1]](once), once)
  }
})

test_that("revalidation after a filter records the change only", {
  a <- validate_acquisitions(fixture_acquisitions())
  b <- validate_acquisitions(dplyr::filter(a, record_id != 2L))
  log <- audit_log(b)
  expect_identical(nrow(log), nrow(audit_log(a)) + 1L)
  expect_identical(log$kind[[nrow(log)]], "external_change")
})

test_that("a missing column and a wrong type are schema errors", {
  h <- fixture_households()
  h$weight <- NULL
  h$psu <- NULL
  err <- expect_error(validate_households(h), class = "hcesfort_error_schema")
  expect_identical(err$columns, c("weight", "psu"))
  m <- fixture_members()
  m$sex <- factor(m$sex)
  m$age_years <- as.character(m$age_years)
  err <- expect_error(validate_members(m), class = "hcesfort_error_schema")
  expect_identical(err$columns, c("age_years", "sex"))
  a <- fixture_acquisitions()
  a$include <- 1L
  expect_error(validate_acquisitions(a), class = "hcesfort_error_schema")
})

test_that("ids accept whole doubles and reject fractions", {
  h <- fixture_households()
  h$household_id <- c(1, 2, 3)
  expect_s3_class(validate_households(h), "hces_households")
  h$household_id <- c(1, 2, 3.5)
  expect_error(validate_households(h), class = "hcesfort_error_schema")
})

test_that("duplicated and missing keys are key errors", {
  h <- fixture_households()
  h$household_id <- c(1L, 1L, NA)
  err <- expect_error(validate_households(h), class = "hcesfort_error_key")
  expect_identical(err$rows, c(2L, 3L))
  expect_identical(err$n, 2L)
  m <- fixture_members()
  m$member_id <- c(1L, 1L, 1L, 2L) # household 1 has member 1 twice: row 2
  err <- expect_error(validate_members(m), class = "hcesfort_error_key")
  expect_identical(err$rows, 2L)
  # Member ids repeated across households are not duplicates.
  expect_s3_class(validate_members(fixture_members()), "hces_members")
})

test_that("impossible values are value errors, all reported at once", {
  h <- fixture_households()
  h$weight[2] <- 0
  h$stratum[3] <- NA
  err <- expect_error(validate_households(h), class = "hcesfort_error_value")
  expect_identical(err$columns, c("weight", "stratum"))
  expect_identical(err$rows, c(2L, 3L))
  m <- fixture_members()
  m$age_years[1] <- -1
  m$sex[2] <- "F"
  m$meals_home_share <- c(1, 0.5, 1.2, NA)
  err <- expect_error(validate_members(m), class = "hcesfort_error_value")
  expect_identical(err$columns, c("age_years", "sex", "meals_home_share"))
  a <- fixture_acquisitions()
  a$quantity[1] <- -2
  a$period_days[3] <- 0
  a$household_share <- c(1, 1, 1, 1.5)
  err <- expect_error(validate_acquisitions(a), class = "hcesfort_error_value")
  expect_identical(err$rows, c(1L, 3L, 4L))
})

test_that("expenditure_lcu is optional, may be missing, not negative", {
  a <- fixture_acquisitions()
  a$expenditure_lcu <- c(10, NA, 0, 2.5)
  expect_s3_class(validate_acquisitions(a), "hces_acquisitions")
  a$expenditure_lcu[[1]] <- -1
  err <- expect_error(validate_acquisitions(a), class = "hcesfort_error_value")
  expect_identical(err$columns, "expenditure_lcu")
  expect_identical(err$rows, 1L)
  a$expenditure_lcu <- as.character(a$expenditure_lcu)
  expect_error(validate_acquisitions(a), class = "hcesfort_error_schema")
})

test_that("infinite numbers are value errors", {
  a <- fixture_acquisitions()
  a$quantity[1] <- Inf
  expect_error(validate_acquisitions(a), "not finite")
})

test_that("implausible but possible values pass", {
  m <- fixture_members()
  m$age_years[1] <- 110
  a <- fixture_acquisitions()
  a$quantity[1] <- 4e5
  expect_s3_class(validate_members(m), "hces_members")
  expect_s3_class(validate_acquisitions(a), "hces_acquisitions")
})

test_that("zero-row tables and all-NA optional columns pass", {
  a <- fixture_acquisitions()[0, ]
  out <- validate_acquisitions(a)
  expect_identical(nrow(out), 0L)
  expect_identical(audit_log(out)$n_records, 0L)
  a <- fixture_acquisitions()
  a$origin <- NA_character_
  a$household_share <- NA_real_
  expect_s3_class(validate_acquisitions(a), "hces_acquisitions")
})

test_that("results do not depend on row or column order", {
  a <- fixture_acquisitions()
  shuffled <- a[c(4, 2, 1, 3), rev(names(a))]
  expect_identical(audit_log(validate_acquisitions(shuffled)),
                   audit_log(validate_acquisitions(a)))
  m <- fixture_members()
  expect_identical(audit_log(validate_members(m[4:1, ])),
                   audit_log(validate_members(m)))
})
