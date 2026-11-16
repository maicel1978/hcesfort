# above_ul(). Fixture: as_run() of helper-scenario.R. s1 adds to h1 iron
# 5.5 mg (total 6.5) and 180 ug of folic acid, to h2 iron 2.75 (total
# 3.25) and 90 ug of folic acid; s2 adds 100 ug of retinol to h1.
# Invented ULs: iron 6 mg (total), folate 150 ug of folic acid, vitamin A
# 80 ug of preformed vitamin A; zinc has no nutrient in the registry.
ul_req <- function(iron = 6, folate = 150, folate_unit = "ug") {
  data.frame(
    nutrient = c("iron", "folate", "vitamin_a", "zinc", "energy"),
    unit = c("mg", "ug_dfe", "ug_rae", "mg", "kcal"),
    ul = c(iron, folate, 80, 40, NA),
    ul_unit = c("mg", folate_unit, "ug", "mg", NA),
    ul_applies_to = c("total", "folic_acid", "preformed_vitamin_a", "total",
                      NA)
  )
}

ul_val <- function(u, scenario, h, nutrient, col) {
  u[[col]][u$scenario == scenario & u$household_id == h &
             u$nutrient == nutrient]
}

test_that("total intake and a form with the added part only, by hand", {
  u <- above_ul(as_run(), ul_req(), min_coverage = 0.9, min_records_used = 0)
  expect_s3_class(u, c("hces_above_ul", "hces_tbl"))
  expect_setequal(unique(u$nutrient), c("iron", "folate", "vitamin_a"))
  expect_identical(ul_val(u, "s1", 1, "iron", "above_ul_total"), 1)
  expect_identical(ul_val(u, "s1", 2, "iron", "above_ul_total"), 0)
  expect_identical(ul_val(u, "s1", 1, "iron", "above_ul_added"), NA_real_)
  expect_identical(ul_val(u, "s1", 1, "iron", "ul_scope"), "total_intake")
  expect_equal(ul_val(u, "s1", 1, "folate", "amount_added"), 180)
  expect_identical(ul_val(u, "s1", 1, "folate", "above_ul_added"), 1)
  expect_identical(ul_val(u, "s1", 2, "folate", "above_ul_added"), 0)
  expect_identical(ul_val(u, "s1", 1, "folate", "above_ul_total"), NA_real_)
  expect_identical(ul_val(u, "s1", 1, "folate", "ul_scope"),
                   "form_added_only")
  expect_identical(ul_val(u, "s2", 1, "vitamin_a", "above_ul_added"), 1)
  expect_identical(ul_val(u, "s1", 3, "iron", "above_ul_total"), NA_real_)
})

test_that("baseline rows: nothing added, not above", {
  u <- above_ul(as_run(), ul_req(), min_coverage = 0, min_records_used = 0)
  b <- u[u$scenario == "baseline" & u$intake_status == "estimated", ]
  expect_true(all(b$amount_added == 0))
  expect_false(any(b$above_ul_added > 0, na.rm = TRUE))
  expect_false(any(b$above_ul_total > 0, na.rm = TRUE))
})

test_that("an amount exactly at the UL is not above it", {
  u <- above_ul(as_run(), ul_req(iron = 6.5, folate = 180), min_coverage = 0,
                min_records_used = 0)
  expect_identical(ul_val(u, "s1", 1, "iron", "above_ul_total"), 0)
  expect_identical(ul_val(u, "s1", 1, "folate", "above_ul_added"), 0)
})

test_that("a form without either part is not assessable", {
  cv <- ref_conversions
  cv$ul_form[cv$from_form == "folic_acid"] <- NA
  u <- above_ul(as_run(), ul_req(), conversions = cv, min_coverage = 0,
                min_records_used = 0)
  f <- u[u$nutrient == "folate", ]
  expect_identical(unique(f$ul_scope), "not_assessable")
  expect_true(all(is.na(f$above_ul_added) & is.na(f$above_ul_total)))
  log <- audit_log(u)
  expect_identical(log$detail[log$cause == "not_assessable"], "folate")
})

# A registry with the form: flour of 100 g per AFE with 50 ug of folic acid
# per 100 g; a scenario adds 1 mg/kg (100 ug per 100 g). Folic acid: diet
# 50, added 100, total 150.
ul_form_run <- function(level = 1) {
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
  apply_scenario(intake, vehicle_coverage(g, v, afe, h), sc)
}

test_that("a form with both parts: added only is a lower bound", {
  req <- data.frame(nutrient = "folate", unit = "ug_dfe", ul = 120,
                    ul_unit = "ug", ul_applies_to = "folic_acid")
  u <- above_ul(ul_form_run(), req, min_coverage = 0, min_records_used = 0)
  expect_identical(ul_val(u, "s", 1, "folate", "ul_scope"),
                   "form_diet_and_added")
  expect_equal(ul_val(u, "s", 1, "folate", "amount_added"), 100)
  expect_equal(ul_val(u, "s", 1, "folate", "amount_total"), 150)
  expect_identical(ul_val(u, "s", 1, "folate", "above_ul_added"), 0)
  expect_identical(ul_val(u, "s", 1, "folate", "above_ul_total"), 1)
  expect_equal(ul_val(u, "baseline", 1, "folate", "amount_total"), 50)
})

test_that("an hces_intake works: nothing added", {
  u <- above_ul(as_pipeline()$intake, ul_req(), min_coverage = 0,
                min_records_used = 0)
  expect_true(all(is.na(u$scenario)))
  expect_identical(u$amount_added[u$household_id == 1 &
                                    u$nutrient == "iron"], 0)
})

test_that("the audit log notes scopes and lower bounds", {
  log <- audit_log(above_ul(as_run(), ul_req(), min_coverage = 0,
                            min_records_used = 0))
  log <- log[log$step == "above_ul", ]
  expect_setequal(log$detail[log$cause == "ul_scope"], c(
    "iron: total_intake", "folate: form_added_only",
    "vitamin_a: form_added_only"
  ))
  expect_setequal(log$detail[log$cause == "added_only_lower_bound"],
                  c("folate", "vitamin_a"))
  expect_identical(log$detail[log$cause == "not_estimated"],
                   "no_food_records")
})

test_that("the log says the figures are on apparent intake", {
  log <- audit_log(above_ul(as_run(), ul_req(), min_coverage = 0,
                            min_records_used = 0))
  usual <- log[log$step == "above_ul" &
                 log$cause == "apparent_intake_not_usual_intake", ]
  expect_identical(usual$detail, "period_days of the records used: 1 to 1")
  expect_identical(usual$n_records, 9L)
})

test_that("average content below compliance 1 is flagged, with its bound", {
  # s1 at compliance 0.8: h1 receives 0.8 x 180 = 144 ug of folic acid,
  # below the UL of 150; at compliance 1 it receives 180, above it.
  sc <- as_scenarios()
  sc$compliance <- c(0.8, 0.8, 1)
  part <- above_ul(as_run(sc, compliance_model = "average_content"),
                   ul_req(), min_coverage = 0, min_records_used = 0)
  full <- above_ul(as_run(), ul_req(), min_coverage = 0,
                   min_records_used = 0)
  expect_identical(ul_val(part, "s1", 1, "folate", "above_ul_added"), 0)
  expect_identical(ul_val(full, "s1", 1, "folate", "above_ul_added"), 1)
  log <- audit_log(part)
  f <- log[log$cause == "average_content_understates_ul", ]
  expect_identical(f$kind, "flagged")
  expect_identical(f$detail, "s1: rerun at compliance 1 for the upper bound")
  expect_identical(f$n_records, 3L)
  expect_identical(f$n_households, 3L)
  expect_false("average_content_understates_ul" %in% audit_log(full)$cause)
})

test_that("no compliance flag without a scenario or an assessable UL", {
  i <- as_pipeline()$intake
  u <- above_ul(i, ul_req(), min_coverage = 0, min_records_used = 0)
  expect_false("average_content_understates_ul" %in% audit_log(u)$cause)
  sc <- as_scenarios()
  sc$compliance <- 0.5
  s <- as_run(sc, compliance_model = "average_content")
  req <- ul_req()
  req$ul <- NA_real_
  u <- above_ul(s, req, min_coverage = 0, min_records_used = 0)
  expect_false("average_content_understates_ul" %in% audit_log(u)$cause)
})

test_that("errors are classed", {
  s <- as_run()
  expect_error(above_ul(s, ul_req(folate_unit = "ug_dfe"), min_coverage = 0,
                        min_records_used = 0),
               class = "hcesfort_error_units")
  req <- ul_req()
  req$ul_unit[[1]] <- "ug"
  expect_error(above_ul(s, req, min_coverage = 0, min_records_used = 0),
               class = "hcesfort_error_units")
  cv <- ref_conversions[setdiff(names(ref_conversions), "ul_form")]
  expect_error(above_ul(s, ul_req(), conversions = cv, min_coverage = 0,
                        min_records_used = 0),
               class = "hcesfort_error_schema")
  expect_error(above_ul(s, ul_req()[-5], min_coverage = 0,
                        min_records_used = 0),
               class = "hcesfort_error_schema")
  s$iron_mg_coverage[s$household_id == 1] <- 0.5
  expect_error(above_ul(s, ul_req(), min_coverage = 0.6, min_records_used = 0),
               class = "hcesfort_error_coverage")
  expect_error(above_ul(s, ul_req()), class = "hcesfort_error_argument")
})

test_that("a requirements table without ULs gives no rows", {
  req <- ul_req()
  req$ul <- NA_real_
  u <- above_ul(as_run(), req, min_coverage = 0, min_records_used = 0)
  expect_identical(nrow(u), 0L)
  expect_s3_class(u, "hces_above_ul")
})

test_that("invariants: total never below added; monotone in level and UL", {
  req <- data.frame(nutrient = "folate", unit = "ug_dfe", ul = 120,
                    ul_unit = "ug", ul_applies_to = "folic_acid")
  for (level in c(0.5, 1, 2)) {
    u <- above_ul(ul_form_run(level), req, min_coverage = 0,
                  min_records_used = 0)
    expect_true(all(!u$above_ul_added | u$above_ul_total))
  }
  low <- above_ul(as_run(), ul_req(), min_coverage = 0, min_records_used = 0)
  sc <- as_scenarios()
  sc$level_mg_kg <- 2 * sc$level_mg_kg
  high <- above_ul(as_run(sc), ul_req(), min_coverage = 0, min_records_used = 0)
  ok <- !is.na(low$above_ul_total)
  expect_true(all(high$above_ul_total[ok] >= low$above_ul_total[ok]))
  ok <- !is.na(low$above_ul_added)
  expect_true(all(high$above_ul_added[ok] >= low$above_ul_added[ok]))
  loose <- above_ul(as_run(), ul_req(iron = 60, folate = 1500),
                    min_coverage = 0, min_records_used = 0)
  ok <- !is.na(low$above_ul_total)
  expect_true(all(loose$above_ul_total[ok] <= low$above_ul_total[ok]))
})

test_that("invariant: row order of requirements", {
  u1 <- above_ul(as_run(), ul_req(), min_coverage = 0, min_records_used = 0)
  u2 <- above_ul(as_run(), ul_req()[5:1, ], min_coverage = 0,
                 min_records_used = 0)
  k <- function(u) paste(u$scenario, u$household_id, u$nutrient)
  expect_identical(u2$above_ul_total[match(k(u1), k(u2))], u1$above_ul_total)
  expect_identical(u2$above_ul_added[match(k(u1), k(u2))], u1$above_ul_added)
})

# Mutation S4 of the review v0.2: two registry forms of one UL category.
# Invented conversions: retinol and a "retinyl" form, both in ug and both
# counted against preformed vitamin A. Records per AFE: flour 100 g (C1:
# retinol 5, retinyl 2 per 100 g) and milk 100 g (C2: retinol 3, retinyl
# missing). Coverage by edible grams: retinol 200 / 200 = 1, retinyl
# 100 / 200 = 0.5; the coverage of the UL is the smaller, 0.5. Total
# 5 + 3 + 2 = 10 ug.
test_that("the coverage of a UL with two diet forms is the smallest", {
  r <- nutrient_registry(c(retinol = "ug", retinyl = "ug"))
  a <- data.frame(record_id = 1:2, household_id = 1,
                  food_code = c("flour", "milk"), quantity = 100, unit = "g",
                  section = "diary", period_days = 1, include = TRUE)
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  cw <- data.frame(food_code = c("flour", "milk"),
                   composition_id = c("C1", "C2"), match_type = "exact",
                   validated = TRUE, edible_portion = 1)
  comp <- data.frame(composition_id = c("C1", "C2"), retinol_ug = c(5, 3),
                     retinyl_ug = c(2, NA), basis = "per_100g_edible",
                     food_state = "raw", source = "test fixture")
  comp <- unfortified_baseline(comp, no_rules(), r)
  h <- data.frame(household_id = 1, weight = 1, stratum = 1, psu = 1)
  afe <- new_hces_tbl(data.frame(household_id = 1, n_members = 1, afe = 1),
                      "hces_afe", key = "household_id")
  g <- convert_units(a, f, priority = "food")
  intake <- apparent_intake(link_composition(g, cw, comp, r), afe, h)
  cv <- ref_conversions[ref_conversions$from_form == "retinol", ]
  cv <- rbind(cv, cv)
  cv$from_form[2] <- "retinyl"
  req <- data.frame(nutrient = "retinol", unit = "ug", ul = 9,
                    ul_unit = "ug", ul_applies_to = "preformed_vitamin_a")
  u <- above_ul(intake, req, conversions = cv, min_coverage = 0,
                min_records_used = 0)
  expect_identical(u$ul_scope, "form_diet_and_added")
  expect_equal(u$coverage, 0.5)
  expect_equal(u$amount_total, 10)
  expect_identical(u$above_ul_total, 1)
})
