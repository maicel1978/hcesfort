# apply_scenario(). Fixture: invented foods in grams over one day.
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
  afe <- new_hces_tbl(data.frame(household_id = 1:3, afe = c(2, 1, 1)),
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

test_that("the three hand checks of the level basis", {
  s <- as_run()
  expect_s3_class(s, c("hces_scenario_intake", "hces_tbl"))
  expect_identical(unique(s$scenario), c("baseline", "s1", "s2"))
  expect_equal(val(s, "s1", 1, "iron_mg_added"), 5.5)
  expect_equal(val(s, "s1", 2, "iron_mg_added"), 2.75)
  expect_equal(val(s, "s1", 1, "iron_mg"), 6.5)
  expect_equal(val(s, "s1", 1, "folate_ug_dfe_added"), 306)
  expect_equal(val(s, "s1", 2, "folate_ug_dfe"), 10 + 153)
  expect_equal(val(s, "s1", 1, "folic_acid_ug_added"), 180)
  expect_equal(val(s, "s2", 1, "vitamin_a_ug_rae_added"), 100)
  expect_equal(val(s, "s2", 1, "retinol_ug_added"), 100)
  expect_equal(val(s, "s2", 2, "vitamin_a_ug_rae_added"), 0)
  expect_equal(val(s, "s2", 1, "iron_mg"), 1)
})

test_that("baseline rows have nothing added", {
  s <- as_run()
  base <- s[s$scenario == "baseline", ]
  expect_equal(base$iron_mg, c(1, 0.5, NA))
  expect_equal(base$iron_mg_added, c(0, 0, NA))
  expect_equal(base$folic_acid_ug_added, c(0, 0, NA))
})

test_that("a household not estimated has missing totals", {
  s <- as_run()
  expect_identical(val(s, "s1", 3, "intake_status"), "no_food_records")
  expect_true(is.na(val(s, "s1", 3, "iron_mg")))
  expect_true(is.na(val(s, "s1", 3, "iron_mg_added")))
})

test_that("two vehicles in one scenario add up", {
  sc <- data.frame(scenario = "both", vehicle = c("flour", "sugar"),
                   nutrient = "iron", level_mg_kg = c(55, 100),
                   level_basis = "nutrient", source = "test fixture")
  s <- as_run(sc)
  # h1: 100 x 5.5 / 100 + 20 x 10 / 100 = 7.5.
  expect_equal(val(s, "both", 1, "iron_mg_added"), 7.5)
})

test_that("compliance 0.8 under average content", {
  sc <- as_scenarios()
  sc$compliance <- 0.8
  expect_error(as_run(sc), class = "hcesfort_error_argument")
  s <- as_run(sc, compliance_model = "average_content")
  expect_equal(val(s, "s1", 1, "iron_mg_added"), 0.8 * 5.5)
  log <- audit_log(s)
  expect_identical(log$detail[log$cause == "compliance_model"],
                   "average_content")
  expect_error(as_run(sc, compliance_model = "all_or_nothing"),
               class = "hcesfort_error_argument")
})

test_that("level 0, a vehicle nobody acquired and losses are noted", {
  sc <- data.frame(scenario = "p", vehicle = c("pasta", "flour"),
                   nutrient = "iron", level_mg_kg = c(30, 0),
                   level_basis = "nutrient", source = "SOURCE PENDING")
  s <- as_run(sc)
  expect_equal(val(s, "p", 1, "iron_mg"), 1)
  log <- audit_log(s)
  log <- log[log$step == "apply_scenario", ]
  expect_identical(log$detail[log$cause == "vehicle_not_acquired"], "pasta")
  expect_identical(log$n_records[log$cause == "scenario_source_pending"], 2L)
  expect_identical(log$n_records[log$cause == "no_losses_applied"], 2L)
})

test_that("households with added and understated additions are counted", {
  log <- audit_log(as_run())
  log <- log[log$step == "apply_scenario", ]
  n <- log$n_records[log$cause == "households_with_added"]
  d <- log$detail[log$cause == "households_with_added"]
  expect_identical(n[d == "s1: iron_mg"], 2L)
  expect_identical(n[d == "s2: vitamin_a_ug_rae"], 1L)
  expect_false("added_understated" %in% log$cause)
})

test_that("an intake without the baseline step is an audit error", {
  p <- as_pipeline(baseline = FALSE)
  expect_error(as_run(p = p), class = "hcesfort_error_audit")
})

test_that("join, units and value errors are classed", {
  sc <- as_scenarios()
  sc$vehicle[[3]] <- "salt"
  expect_error(as_run(sc), class = "hcesfort_error_join")
  sc <- as_scenarios()
  sc$form[[2]] <- NA
  expect_error(as_run(sc), class = "hcesfort_error_units")
  sc <- as_scenarios()
  sc$form[[2]] <- "folinic_acid"
  expect_error(as_run(sc), class = "hcesfort_error_units")
  sc <- as_scenarios()
  sc$nutrient[[1]] <- "energy"
  expect_error(as_run(sc), class = "hcesfort_error_units")
  sc <- as_scenarios()
  sc$nutrient_fraction[[1]] <- 0.5
  expect_error(as_run(sc), class = "hcesfort_error_value")
  sc <- as_scenarios()
  sc$scenario[[3]] <- "baseline"
  expect_error(as_run(sc), class = "hcesfort_error_value")
  expect_error(as_run(baseline_label = NA_character_),
               class = "hcesfort_error_argument")
  p <- as_pipeline()
  expect_error(apply_scenario(p$intake, as.data.frame(p$use), as_scenarios()),
               class = "hcesfort_error_audit")
  p$use <- restore_audit(p$use[p$use$household_id != 3, ], from = p$use)
  expect_error(as_run(p = p), class = "hcesfort_error_join")
})

test_that("invariants: total = baseline + added, never lower", {
  s <- as_run()
  base <- s[s$scenario == "baseline", ]
  for (sc in c("s1", "s2")) {
    one <- s[s$scenario == sc, ]
    for (col in c("iron_mg", "folate_ug_dfe", "vitamin_a_ug_rae")) {
      expect_identical(one[[col]] - one[[paste0(col, "_added")]],
                       base[[col]] + 0 * one[[paste0(col, "_added")]])
      expect_true(all(one[[col]] >= base[[col]], na.rm = TRUE))
    }
    expect_identical(one$energy_kcal, base$energy_kcal)
  }
})

test_that("invariants: linear in level and compliance; compound = nutrient", {
  sc <- as_scenarios()
  s1 <- as_run(sc)
  sc2 <- sc
  sc2$level_mg_kg <- 2 * sc2$level_mg_kg
  s2 <- as_run(sc2)
  expect_equal(s2$iron_mg_added, 2 * s1$iron_mg_added)
  sc0 <- sc
  sc0$compliance <- 0
  s0 <- as_run(sc0, compliance_model = "average_content")
  expect_equal(s0$iron_mg, s0$iron_mg - s0$iron_mg_added)
  expect_equal(s0$iron_mg[s0$scenario == "s1"],
               s0$iron_mg[s0$scenario == "baseline"])
  scn <- sc
  scn$level_basis[[3]] <- "nutrient"
  scn$nutrient_fraction[[3]] <- NA
  scn$level_mg_kg[[3]] <- 10 * 0.5
  expect_equal(as_run(scn)$vitamin_a_ug_rae, s1$vitamin_a_ug_rae)
})

test_that("invariant: row order of every input", {
  s1 <- as_run()
  s2 <- as_run(as_scenarios()[3:1, ])
  expect_setequal(unique(s2$scenario), c("baseline", "s1", "s2"))
  k1 <- paste(s1$scenario, s1$household_id)
  k2 <- paste(s2$scenario, s2$household_id)
  expect_equal(s2$iron_mg[match(k1, k2)], s1$iron_mg)
  expect_equal(s2$folic_acid_ug_added[match(k1, k2)], s1$folic_acid_ug_added)
})

test_that("a form in the registry gets its total updated", {
  r <- nutrient_registry(c(folate = "ug_dfe", folic_acid = "ug"))
  a <- data.frame(record_id = 1, household_id = 1, food_code = "flour",
                  quantity = 100, unit = "g", section = "diary",
                  period_days = 1, include = TRUE)
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  cw <- data.frame(food_code = "flour", composition_id = "C1",
                   match_type = "exact", validated = TRUE, edible_portion = 1)
  comp <- data.frame(composition_id = "C1", folate_ug_dfe = 20,
                     folic_acid_ug = 0, basis = "per_100g_edible",
                     food_state = "raw", source = "test fixture")
  comp <- unfortified_baseline(comp, no_rules(), r)
  h <- data.frame(household_id = 1, weight = 1, stratum = 1, psu = 1)
  afe <- new_hces_tbl(data.frame(household_id = 1, afe = 1), "hces_afe",
                      key = "household_id")
  v <- data.frame(food_code = "flour", vehicle = "flour",
                  vehicle_fraction = 1, source = "test fixture")
  g <- convert_units(a, f, priority = "food")
  intake <- apparent_intake(link_composition(g, cw, comp, r), afe, h)
  sc <- data.frame(scenario = "s", vehicle = "flour", nutrient = "folate",
                   level_mg_kg = 1, level_basis = "nutrient",
                   form = "folic_acid", source = "test fixture")
  s <- apply_scenario(intake, vehicle_coverage(g, v, afe, h), sc)
  # 1 mg/kg -> 100 ug folic acid per 100 g -> 170 ug DFE.
  expect_equal(val(s, "s", 1, "folic_acid_ug"), 100)
  expect_equal(val(s, "s", 1, "folate_ug_dfe"), 20 + 170)
})

test_that("derived functions accept the scenario table", {
  s <- as_run()
  d <- nutrient_density(s, "energy_kcal")
  expect_s3_class(d, "hces_scenario_intake")
  expect_equal(d$iron_mg_per_1000kcal[[4]], 6.5 / 438 * 1000)
  e <- flag_energy_plausibility(s, "energy_kcal", 100, 6000)
  expect_identical(attr(e, "audit_key"), c("scenario", "household_id"))
})

test_that("the example data run end to end", {
  nutrients <- nutrient_registry(hces_example$nutrients)
  baseline <- unfortified_baseline(hces_example$composition,
                                   hces_example$enrichment, nutrients)
  g <- convert_units(hces_example$acquisitions, hces_example$unit_factors,
                     priority = "food")
  afe <- new_hces_tbl(
    data.frame(household_id = hces_example$households$household_id,
               afe = 1),
    "hces_afe", key = "household_id"
  )
  intake <- apparent_intake(
    link_composition(g, hces_example$crosswalk, baseline), afe,
    hces_example$households
  )
  use <- vehicle_coverage(g, hces_example$vehicles, afe,
                          hces_example$households)
  s <- apply_scenario(intake, use, hces_example$scenarios,
                      compliance_model = "average_content")
  expect_identical(nrow(s), 3L * 40L)
  ok <- s$intake_status == "estimated"
  expect_true(all(s$iron_mg_added[ok] >= 0))
})

test_that("a scenarios table without rows returns the baseline only", {
  s <- as_run(as_scenarios()[0, ])
  expect_identical(unique(s$scenario), "baseline")
  expect_identical(nrow(s), 3L)
})
