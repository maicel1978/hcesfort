# Fixtures of the AFE tests (test-adult-equivalents.R, test-afe-infants.R):
# invented reference tables with round numbers, so every expected AFE is
# worked out by hand below.
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

afe_fixture <- function(members = afe_members(), ...,
                        infant_food_share = 1, pregnancy_kcal = 0,
                        lactation_kcal = 0) {
  adult_equivalents(
    members, reference_kcal = 2000, weight_kg = c(female = 50, male = 70),
    pal = 2, energy = afe_energy(), bmr = afe_bmr(),
    infant_food_share = infant_food_share, pregnancy_kcal = pregnancy_kcal,
    lactation_kcal = lactation_kcal, ...
  )
}

# Energy charged to household 2 (two infants and a man of 2800 kcal).
hh2_kcal <- function(...) afe_fixture(...)$energy_kcal_d[[2]]

# Household 1 of afe_members(): woman 2000 kcal, man 2400, girl of 5 years
# 1000 (5400 kcal, AFE 2.7); the woman flagged pregnant or lactating as the
# arguments say.
afe_mother <- function(pregnant = FALSE, lactating = FALSE) {
  m <- afe_members()[afe_members()$household_id == 1, ]
  m$pregnant <- c(pregnant, NA, NA)
  m$lactating <- c(lactating, FALSE, NA)
  m
}
