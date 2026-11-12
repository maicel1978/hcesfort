# Fixture of apply_scenario(), inadequacy() and above_ul(): a pipeline of
# three invented households (hand values below).
#
# Composition per 100 g: flour iron 1 mg, folate 20 ug DFE; sugar nothing.
# AFE: h1 2, h2 1, h3 1 (no records). Records: h1 flour 200 g, sugar 40 g;
# h2 flour 50 g. Vehicles: flour, sugar, pasta (never acquired).
# Baseline per AFE: h1 iron 1, folate 20; h2 iron 0.5, folate 10.
# Vehicle grams per AFE: h1 flour 100, sugar 20; h2 flour 50, sugar 0.
# Levels (design of task 9, section 5):
# - iron 55 mg/kg as nutrient -> 5.5 mg per 100 g: h1 + 5.5, h2 + 2.75;
# - folic acid 1.8 mg/kg -> 180 ug folic acid -> 306 ug DFE per 100 g:
#   h1 + 306 (180 ug folic acid), h2 + 153 (90);
# - a compound at 10 mg/kg, fraction 0.5, form retinol -> 500 ug RAE per
#   100 g: h1 + 100, h2 + 0.
# Energy h1: (200 x 3.6 + 40 x 3.9) / 2 = 438 kcal.
no_rules <- function() {
  data.frame(composition_id = character(0), nutrient = character(0),
             source = character(0))
}

as_registry <- function() {
  nutrient_registry(c(energy = "kcal", iron = "mg", folate = "ug_dfe",
                      vitamin_a = "ug_rae"))
}

as_pipeline <- function(scale = 1, baseline = TRUE) {
  a <- data.frame(
    record_id = 1:3, household_id = c(1, 1, 2),
    food_code = c("flour", "sugar", "flour"),
    quantity = c(200, 40, 50) * scale, unit = "g", section = "diary",
    period_days = 1, include = TRUE
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  cw <- data.frame(food_code = c("flour", "sugar"),
                   composition_id = c("C1", "C2"), match_type = "exact",
                   validated = TRUE, edible_portion = 1)
  comp <- data.frame(composition_id = c("C1", "C2"),
                     energy_kcal = c(360, 390), iron_mg = c(1, 0),
                     folate_ug_dfe = c(20, 0), vitamin_a_ug_rae = 0,
                     basis = "per_100g_edible", food_state = "raw",
                     source = "test fixture")
  if (baseline) {
    comp <- unfortified_baseline(comp, no_rules(), as_registry())
  }
  h <- data.frame(household_id = 1:3, weight = 1, stratum = 1, psu = 1:3)
  afe <- new_hces_tbl(data.frame(household_id = 1:3, n_members = 1,
                                 afe = c(2, 1, 1)),
                      "hces_afe", key = "household_id")
  v <- data.frame(food_code = c("flour", "sugar", "pasta"),
                  vehicle = c("flour", "sugar", "pasta"),
                  vehicle_fraction = 1, source = "test fixture")
  g <- convert_units(a, f, priority = "food")
  content <- link_composition(g, cw, comp, as_registry())
  list(intake = apparent_intake(content, afe, h),
       use = vehicle_coverage(g, v, afe, h))
}

as_scenarios <- function() {
  data.frame(
    scenario = c("s1", "s1", "s2"), vehicle = c("flour", "flour", "sugar"),
    nutrient = c("iron", "folate", "vitamin_a"),
    level_mg_kg = c(55, 1.8, 10),
    level_basis = c("nutrient", "nutrient", "compound"),
    form = c(NA, "folic_acid", "retinol"),
    nutrient_fraction = c(NA, NA, 0.5), source = "test fixture"
  )
}

as_run <- function(scenarios = as_scenarios(), p = as_pipeline(), ...) {
  apply_scenario(p$intake, p$use, scenarios, ...)
}

val <- function(s, scenario, h, col) {
  s[[col]][s$scenario == scenario & s$household_id == h]
}
