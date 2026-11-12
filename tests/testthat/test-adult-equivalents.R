# adult_equivalents(). Fixtures: invented reference tables with round
# numbers, so every expected AFE is worked out by hand below.
#
# energy: infants female 500 kcal in months [0, 6), 700 in [6, 12); male
#   600 and 800. Children of both sexes 1000 kcal in [1, 10) years, 2000
#   in [10, 18).
# bmr: adults of both sexes from 18 years, 10 kcal/kg + 500.
# Weights female 50 kg, male 70 kg; PAL 2; reference 2000 kcal.
afe_energy <- function() {
  data.frame(
    sex = c("female", "female", "male", "male", "female", "female",
            "male", "male"),
    age_from = c(0, 6, 0, 6, 1, 10, 1, 10),
    age_to = c(6, 12, 6, 12, 10, 18, 10, 18),
    age_unit = rep(c("month", "year"), each = 4),
    energy_kcal_d = c(500, 700, 600, 800, 1000, 2000, 1000, 2000),
    source = "test fixture"
  )
}

afe_bmr <- function() {
  data.frame(
    sex = c("female", "male"), age_from = 18, age_to = Inf,
    slope_kcal_kg = 10, intercept_kcal = 500, source = "test fixture"
  )
}

# Household 1: woman 30 y (10 * 50 + 500) * 2 = 2000 kcal, AFE 1; man 40 y
#   (10 * 70 + 500) * 2 = 2400, AFE 1.2; girl 5 y 1000, AFE 0.5. Total
#   5400 kcal, AFE 2.7.
# Household 2: girl of 7 months 700, AFE 0.35; boy of unknown month (mean
#   of 600 and 800) 700, AFE 0.35; man of 90 kg (900 + 500) * 2 = 2800,
#   AFE 1.4. Total 4200 kcal, AFE 2.1.
# Household 3: woman 20 y, AFE 1; a member without age.
afe_members <- function() {
  data.frame(
    household_id = c(1, 1, 1, 2, 2, 2, 3, 3),
    member_id = c(1, 2, 3, 1, 2, 3, 1, 2),
    age_years = c(30, 40, 5, 0.5, 0.2, 45, 20, NA),
    sex = c("female", "male", "female", "female", "male", "male",
            "female", "female"),
    age_months = c(NA, NA, NA, 7, NA, NA, NA, NA),
    weight_kg = c(NA, NA, NA, NA, NA, 90, NA, NA),
    pregnant = c(FALSE, NA, NA, NA, NA, NA, TRUE, NA)
  )
}

afe_fixture <- function(members = afe_members(), ...) {
  adult_equivalents(
    members, reference_kcal = 2000, weight_kg = c(female = 50, male = 70),
    pal = 2, energy = afe_energy(), bmr = afe_bmr(), ...
  )
}

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
    "all", "infant_annual_mean", "pregnant_or_lactating_no_extra",
    "missing_age_or_sex", "household_without_afe"
  ))
  expect_identical(mine$kind, c("input", "note", "note", "flagged",
                                "flagged"))
  expect_identical(mine$n_records, c(8L, 1L, 1L, 1L, 1L))
  expect_identical(mine$n_households, c(3L, 1L, 1L, 1L, 1L))
  expect_identical(mine$table[5], "afe")
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
  eq <- ref_bmr_equations[ref_bmr_equations$sex == "female" &
                            ref_bmr_equations$age_from == 18, ]
  reference <- (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76
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
    bmr = afe_bmr()
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
                      energy = afe_energy(), bmr = bmr),
    class = "hcesfort_error_value"
  )
})

test_that("bad reference tables are classed errors", {
  e <- afe_energy()
  e$age_to[5] <- 11
  expect_error(afe_fixture(), NA)
  expect_error(
    adult_equivalents(afe_members(), 2000, c(female = 50, male = 70), 2,
                      energy = e, bmr = afe_bmr()),
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
