# The shipped realistic example (data-raw/hces_example.R): size, structure,
# planted defects and calibration bands (K27; docs/design-reports-v3.md,
# section 7.1). The bands are broad on purpose: they say what the example
# must show, not exact values.

example_chain <- function() {
  e <- hces_example
  n <- nutrient_registry(e$nutrients)
  g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
  b <- unfortified_baseline(e$composition, e$enrichment, n)
  afe <- adult_equivalents(
    e$members,
    reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
    weight_kg = c(female = 55, male = 65), pal = 1.76
  )
  intake <- apparent_intake(link_composition(g, e$crosswalk, b), afe,
                            e$households)
  use <- vehicle_coverage(g, e$vehicles, afe, e$households)
  s <- apply_scenario(intake, use, e$scenarios,
                      compliance_model = "average_content")
  iron <- ref_iron_requirements
  iron <- iron[iron$group == "females_menstruating_adult", ]
  list(
    intake = intake,
    risk = inadequacy(s, ref_requirements, distribution = list(iron = iron),
                      bioavailability = list(iron = 0.10),
                      min_coverage = 0.8, min_records_used = 0.8),
    ul = above_ul(s, ref_requirements, min_coverage = 0.8,
                  min_records_used = 0.8)
  )
}

test_that("hces_example has the size and design of section 7.1", {
  h <- hces_example$households
  expect_named(hces_example, c(
    "households", "members", "acquisitions", "unit_factors", "crosswalk",
    "nutrients", "composition", "enrichment", "vehicles", "scenarios",
    "food_groups"
  ))
  expect_identical(nrow(h), 2000L)
  expect_length(unique(h$stratum), 6L)
  expect_length(unique(h$psu), 200L)
  expect_true(all(table(h$psu) == 10L))
  psu_per_stratum <- tapply(h$psu, h$stratum, function(x) length(unique(x)))
  expect_true(all(psu_per_stratum >= 25 & psu_per_stratum <= 40))
  d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         data = h)
  expect_identical(survey::degf(d), 194L)
  expect_gt(stats::sd(h$weight), 0)
  expect_named(hces_example$nutrients,
               c("energy", "iron", "zinc", "folate", "vitamin_a"))
  expect_length(unique(hces_example$scenarios$scenario), 5L)
})

test_that("its domains have the planned values and sizes", {
  h <- hces_example$households
  expect_setequal(h$region, c("north", "central", "south"))
  expect_true(all(table(h$region) >= 600))
  expect_setequal(h$area, c("urban", "rural"))
  q <- h$expenditure_group
  expect_setequal(stats::na.omit(q), paste0("Q", 1:5))
  # Only households that did not answer the food module have no group.
  expect_identical(is.na(q), !h$food_module_response)
  expect_true(all(table(q) > 300 & table(q) < 500))
})

test_that("every table passes its validator", {
  e <- hces_example
  n <- nutrient_registry(e$nutrients)
  expect_no_error(validate_survey(e$households, e$members, e$acquisitions))
  expect_no_error(validate_unit_factors(e$unit_factors))
  expect_no_error(validate_crosswalk(e$crosswalk))
  expect_no_error(validate_composition(e$composition, n))
  expect_no_error(validate_enrichment(e$enrichment, n))
  expect_no_error(validate_vehicles(e$vehicles))
  expect_no_error(validate_scenarios(e$scenarios, n))
  expect_no_error(validate_food_groups(e$food_groups))
})

test_that("it carries every planted defect", {
  e <- hces_example
  a <- e$acquisitions
  h <- e$households
  expect_gt(sum(!h$food_module_response), 0)
  expect_gt(sum(h$food_module_response &
                  !h$household_id %in% a$household_id), 0)
  expect_gt(sum(is.na(e$members$age_years)), 0)
  expect_gt(sum(is.na(e$members$sex)), 0)
  expect_gt(sum(e$members$pregnant), 0)
  expect_gt(sum(e$members$lactating), 0)
  expect_gt(sum(is.na(a$quantity)), 0)
  expect_gt(sum(is.na(a$unit)), 0)
  expect_gt(sum(!a$include), 0)
  expect_true(all(c("sack", "cup") %in% a$unit))
  expect_false("sack" %in% e$unit_factors$unit)
  expect_setequal(unique(a$period_days), c(7, 30))
  cw <- e$crosswalk
  expect_gt(sum(is.na(cw$composition_id)), 0)
  expect_gt(sum(!cw$validated & !is.na(cw$composition_id)), 0)
  expect_gt(sum(is.na(cw$edible_portion) & !is.na(cw$composition_id)), 0)
  expect_true(anyNA(e$composition[c("iron_mg", "zinc_mg", "folate_ug_dfe",
                                    "vitamin_a_ug_rae")]))
  expect_gt(sum(e$composition$fortified), 1)
  expect_true(any(duplicated(e$vehicles$food_code)))
  expect_true("compound" %in% e$scenarios$level_basis)
  expect_gt(length(setdiff(cw$food_code, e$food_groups$food_code)), 0)
  # About 1% of the households keep a short list without vehicles (V-D20).
  vehicle_buyers <- a$household_id[a$food_code %in% e$vehicles$food_code]
  no_vehicle <- setdiff(a$household_id, vehicle_buyers)
  expect_gt(length(no_vehicle), 0.005 * nrow(h))
  expect_lt(length(no_vehicle), 0.02 * nrow(h))
})

test_that("results fall in the calibration bands", {
  skip_on_cran()
  r <- example_chain()
  h <- hces_example$households
  i <- r$intake[r$intake$intake_status == "estimated", ]
  ref <- reference_energy("female", 25, 55, pal = 1.76)
  expect_gt(stats::median(i$energy_kcal), 0.85 * ref)
  expect_lt(stats::median(i$energy_kcal), 1.25 * ref)
  risk <- r$risk[r$risk$scenario == "baseline" &
                   r$risk$intake_status == "estimated", ]
  risk$w <- h$weight[match(risk$household_id, h$household_id)]
  risk$q <- h$expenditure_group[match(risk$household_id, h$household_id)]
  for (nut in c("iron", "zinc", "folate", "vitamin_a")) {
    x <- risk[risk$nutrient == nut, ]
    p <- stats::weighted.mean(x$p_inadequate, x$w)
    expect_true(p > 0.2 && p < 0.8, info = nut)
    by_q <- tapply(x$p_inadequate, x$q, mean)
    expect_gt(by_q[["Q1"]], by_q[["Q5"]])
  }
  plausible <- i$household_id[i$energy_kcal >= 500 & i$energy_kcal <= 6000]
  ul <- r$ul[r$ul$household_id %in% plausible, ]
  ul$above <- dplyr::coalesce(ul$above_ul_total, ul$above_ul_added)
  n_above <- tapply(ul$above, list(ul$scenario, ul$nutrient), sum)
  expect_true(all(n_above[, c("iron", "zinc", "vitamin_a")] == 0))
  expect_true(all(n_above[c("baseline", "wheat_flour", "plus_maize"),
                          "folate"] == 0))
  expect_true(all(n_above[c("plus_rice", "plus_sugar", "plus_oil"),
                          "folate"] > 0))
})
