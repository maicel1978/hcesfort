test_that("validate_survey() returns the three validated tables", {
  s <- validate_survey(fixture_households(), fixture_members(),
                       fixture_acquisitions())
  expect_s3_class(s, "hces_survey")
  expect_named(s, c("households", "members", "acquisitions"))
  expect_s3_class(s$members, "hces_members")
})

test_that("households without members or acquisitions are counted", {
  # Household 3 has neither.
  s <- validate_survey(fixture_households(), fixture_members(),
                       fixture_acquisitions())
  log <- audit_log(s$households)
  expect_identical(log$cause, c("all", "households_without_members",
                                "households_without_acquisitions"))
  expect_identical(log$n_records, c(3L, 1L, 1L))
  expect_identical(log$step[2:3], rep("validate_survey", 2))
  expect_identical(nrow(s$households), 3L)
})

test_that("validating a validated survey adds no rows", {
  s <- validate_survey(fixture_households(), fixture_members(),
                       fixture_acquisitions())
  s2 <- validate_survey(s$households, s$members, s$acquisitions)
  expect_identical(s2, s)
})

test_that("orphan members and acquisitions are join errors", {
  m <- fixture_members()
  m$household_id[4] <- 9L
  err <- expect_error(
    validate_survey(fixture_households(), m, fixture_acquisitions()),
    class = "hcesfort_error_join"
  )
  expect_identical(err$table, "members")
  expect_identical(err$n, 1L)
  a <- fixture_acquisitions()
  a$household_id[1:2] <- 8L
  err <- expect_error(
    validate_survey(fixture_households(), fixture_members(), a),
    class = "hcesfort_error_join"
  )
  expect_identical(err$table, "acquisitions")
  expect_identical(err$n, 2L)
  expect_match(conditionMessage(err), "8", fixed = TRUE)
})

test_that("household ids of different types are a join error", {
  a <- fixture_acquisitions()
  a$household_id <- as.character(a$household_id)
  expect_error(
    validate_survey(fixture_households(), fixture_members(), a),
    class = "hcesfort_error_join"
  )
})

test_that("integer and whole double ids are compatible", {
  m <- fixture_members()
  m$household_id <- as.double(m$household_id)
  s <- validate_survey(fixture_households(), m, fixture_acquisitions())
  expect_s3_class(s, "hces_survey")
})
