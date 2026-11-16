# adult_equivalents(). Fixtures in helper-afe.R (invented reference
# tables with round numbers; every expected AFE is worked out there).

test_that("AFE per household matches the hand computation", {
  out <- afe_fixture()
  expect_s3_class(out, "hces_afe")
  expect_identical(out$household_id, c(1, 2, 3))
  expect_identical(out$n_members, c(3L, 3L, 2L))
  expect_equal(out$energy_kcal_d, c(5400, 4200, NA))
  expect_equal(out$afe, c(2.7, 2.1, NA))
})

test_that("the log continues the members log and counts each cause", {
  log <- audit_log(afe_fixture())
  expect_identical(log$step[1:2], c("validate_members", "validate_members"))
  mine <- log[log$step == "adult_equivalents", ]
  expect_identical(mine$cause, c(
    "all", "infant_energy", "infant_annual_mean",
    "pregnant_or_lactating_no_extra", "missing_age_or_sex",
    "household_without_afe"
  ))
  expect_identical(mine$kind, c("input", "note", "note", "note", "flagged",
                                "flagged"))
  expect_identical(mine$n_records, c(8L, 2L, 1L, 1L, 1L, 1L))
  expect_identical(mine$n_households, c(3L, 1L, 1L, 1L, 1L, 1L))
  expect_identical(mine$table[6], "afe")
})

test_that("infants = 'annual_mean' gives every infant the mean", {
  out <- afe_fixture(infants = "annual_mean")
  # Girl: (500 + 700) / 2 = 600, AFE 0.3; household 2: 0.3 + 0.35 + 1.4.
  expect_equal(out$afe[2], 2.05)
  log <- audit_log(out)
  expect_identical(log$n_records[log$cause == "infant_annual_mean"], 2L)
})

test_that("missing_members = 'zero' reproduces the original rule and says so", {
  out <- afe_fixture(missing_members = "zero")
  expect_equal(out$afe, c(2.7, 2.1, 1))
  expect_equal(out$energy_kcal_d[3], 2000)
  log <- audit_log(out)
  expect_true("zero_afe_missing_age_or_sex" %in% log$cause)
  expect_false("household_without_afe" %in% log$cause)
})

test_that("meal share is used only when asked, and NA is flagged", {
  m <- afe_members()
  m$meals_home_share <- c(0.5, 1, 1, 1, 1, NA, 1, 1)
  expect_error(afe_fixture(m), class = "hcesfort_error_argument")
  expect_equal(afe_fixture(m, meal_share = FALSE)$afe, c(2.7, 2.1, NA))
  out <- afe_fixture(m, meal_share = TRUE)
  expect_equal(out$afe, c(2.2, NA, NA))
  log <- audit_log(out)
  expect_identical(log$n_records[log$cause == "missing_meal_share"], 1L)
  expect_error(afe_fixture(meal_share = TRUE),
               class = "hcesfort_error_argument")
})

test_that("the reference woman has exactly one AFE with the shipped tables", {
  reference <- reference_energy("female", 25, weight_kg = 55, pal = 1.76)
  woman <- data.frame(household_id = 1, member_id = 1, age_years = 25,
                      sex = "female")
  out <- adult_equivalents(woman, reference,
                           weight_kg = c(female = 55, male = 65), pal = 1.76)
  expect_identical(out$afe, 1)
  expect_equal(reference, 2290.8, tolerance = 1e-4)
})

test_that("invariants: scaling the reference, row order", {
  base <- afe_fixture()
  half <- adult_equivalents(
    afe_members(), reference_kcal = 4000,
    weight_kg = c(female = 50, male = 70), pal = 2, energy = afe_energy(),
    bmr = afe_bmr(), infant_food_share = 1
  )
  expect_equal(half$afe, base$afe / 2)
  shuffled <- afe_fixture(afe_members()[c(8, 3, 5, 1, 7, 2, 6, 4), ])
  expect_equal(shuffled$afe, base$afe)
  expect_equal(shuffled$energy_kcal_d, base$energy_kcal_d)
})

test_that("a member outside every interval is an error", {
  # Adults' equations start at 25: the woman of 20 years has no interval.
  bmr <- afe_bmr()
  bmr$age_from <- 25
  expect_error(
    adult_equivalents(afe_members(), 2000, c(female = 50, male = 70), 2,
                      energy = afe_energy(), bmr = bmr,
                      infant_food_share = 1),
    class = "hcesfort_error_value"
  )
})

test_that("bad reference tables are classed errors", {
  e <- afe_energy()
  e$age_to[5] <- 11
  expect_error(afe_fixture(), NA)
  expect_error(
    adult_equivalents(afe_members(), 2000, c(female = 50, male = 70), 2,
                      energy = e, bmr = afe_bmr(), infant_food_share = 1),
    class = "hcesfort_error_value"
  )
  expect_error(
    adult_equivalents(afe_members(), 2000, c(female = 50, male = 70), 2,
                      energy = e[-6], bmr = afe_bmr()),
    class = "hcesfort_error_schema"
  )
})

test_that("bad arguments are classed errors", {
  w <- c(female = 50, male = 70)
  m <- afe_members()
  expect_error(adult_equivalents(m, -1, w, 2),
               class = "hcesfort_error_argument")
  expect_error(adult_equivalents(m, c(1, 2), w, 2),
               class = "hcesfort_error_argument")
  expect_error(adult_equivalents(m, 2000, c(50, 70), 2),
               class = "hcesfort_error_argument")
  expect_error(adult_equivalents(m, 2000, c(female = 50), 2),
               class = "hcesfort_error_argument")
  expect_error(adult_equivalents(m, 2000, w, 0),
               class = "hcesfort_error_argument")
  expect_error(adult_equivalents(m, 2000, w, 2, infants = "yearly"),
               class = "hcesfort_error_argument")
  expect_error(adult_equivalents(m, 2000, w, 2, missing_members = c("na", "x")),
               class = "hcesfort_error_argument")
  m$sex[1] <- "woman"
  expect_error(adult_equivalents(m, 2000, w, 2),
               class = "hcesfort_error_value")
})

# Mutation S3 of the review v0.2: the boundaries of the age bands. A girl of
# exactly 1 year is a child (1000 kcal, not the infant mean 600), a girl of
# exactly 10 years is in [10, 18) (2000 kcal) and a woman of exactly 18 is
# an adult ((10 * 50 + 500) * 2 = 2000 kcal). Total 5000 kcal, AFE 2.5.
test_that("a member exactly at an age boundary takes the upper band", {
  m <- data.frame(household_id = 1, member_id = 1:3,
                  age_years = c(1, 10, 18), sex = "female")
  out <- afe_fixture(m)
  expect_equal(out$energy_kcal_d, 5000)
  expect_equal(out$afe, 2.5)
  log <- audit_log(out)
  expect_false("infant_annual_mean" %in% log$cause)
})
