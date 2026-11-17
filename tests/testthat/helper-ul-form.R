# Fixture of the upper-level tests with a form that has a diet part
# (test-above-ul.R, test-risk-states.R).

# A registry with the form: flour of 100 g per AFE with 50 ug of folic acid
# per 100 g; a scenario adds 1 mg/kg (100 ug per 100 g). Folic acid: diet
# 50, added 100, total 150. `compliance` (optional) is the
# column of the scenario; `...` goes to apply_scenario().
ul_form_run <- function(level = 1, compliance = NULL, ...) {
  r <- nutrient_registry(c(folate = "ug_dfe", folic_acid = "ug"))
  a <- data.frame(record_id = 1, household_id = 1, food_code = "flour",
                  quantity = 100, unit = "g", section = "diary",
                  period_days = 1, include = TRUE)
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  cw <- data.frame(food_code = "flour", composition_id = "C1",
                   match_type = "exact", validated = TRUE, edible_portion = 1)
  comp <- data.frame(composition_id = "C1", folate_ug_dfe = 105,
                     folic_acid_ug = 50, basis = "per_100g_edible",
                     food_state = "raw", source = "test fixture")
  none <- data.frame(composition_id = character(0),
                     nutrient = character(0), source = character(0))
  comp <- unfortified_baseline(comp, none, r)
  h <- data.frame(household_id = 1, weight = 1, stratum = 1, psu = 1)
  afe <- new_hces_tbl(data.frame(household_id = 1, n_members = 1, afe = 1),
                      "hces_afe", key = "household_id")
  v <- data.frame(food_code = "flour", vehicle = "flour",
                  vehicle_fraction = 1, source = "test fixture")
  g <- convert_units(a, f, priority = "food")
  intake <- apparent_intake(link_composition(g, cw, comp, r), afe, h)
  sc <- data.frame(scenario = "s", vehicle = "flour", nutrient = "folate",
                   level_mg_kg = level, level_basis = "nutrient",
                   form = "folic_acid", source = "test fixture")
  sc$compliance <- compliance
  apply_scenario(intake, vehicle_coverage(g, v, afe, h), sc, ...)
}
