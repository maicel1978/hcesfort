# Bounds that are identities, and a month that contradicts the age
# (P168, finding 14 of the v0.2 review). Fixtures of helper-fixtures.R,
# with one value changed in each test.

test_that("a level above 1e6 mg per kg is impossible", {
  s <- fixture_scenarios()
  s$level_mg_kg[[1]] <- 1e6
  expect_s3_class(validate_scenarios(s, fixture_nutrients()), "hces_tbl")
  s$level_mg_kg[[1]] <- 2e6
  expect_error(validate_scenarios(s, fixture_nutrients()),
               class = "hcesfort_error_value")
})

test_that("a mass above 100 g per 100 g is impossible, by unit", {
  n <- nutrient_registry(c(iron = "mg", zinc = "ug", fat = "g",
                           folate = "ug_dfe", energy = "kcal"))
  comp <- data.frame(composition_id = "C1", iron_mg = 1e5, zinc_ug = 1e8,
                     fat_g = 100, folate_ug_dfe = 2e8, energy_kcal = 2000,
                     basis = "per_100g_edible", food_state = "raw",
                     source = "invented")
  # At the bound, and equivalents and energy without an upper bound.
  expect_s3_class(validate_composition(comp, n), "hces_tbl")
  for (col in c("iron_mg", "zinc_ug", "fat_g")) {
    bad <- comp
    bad[[col]] <- bad[[col]] * 1.01
    expect_error(validate_composition(bad, n),
                 class = "hcesfort_error_value")
  }
})

test_that("age_months must agree with age_years", {
  m <- fixture_members()
  m$age_months <- c(NA, NA, NA, 60)
  expect_s3_class(validate_members(m), "hces_tbl")
  m$age_months[[4]] <- 71
  expect_s3_class(validate_members(m), "hces_tbl")
  m$age_months[[4]] <- 72
  err <- expect_error(validate_members(m), class = "hcesfort_error_value")
  expect_match(conditionMessage(err), "contradict")
  # An infant of half a year with 14 months (finding 14).
  m <- data.frame(household_id = 1L, member_id = 1L, age_years = 0.5,
                  sex = "female", age_months = 14)
  expect_error(validate_members(m), class = "hcesfort_error_value")
  m$age_months <- 6
  expect_s3_class(validate_members(m), "hces_tbl")
})
