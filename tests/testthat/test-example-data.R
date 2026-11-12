# The synthetic dataset must pass every validator and contain the cases
# it is documented to contain (data-raw/hces_example.R).

test_that("hces_example has its ten tables", {
  expect_named(hces_example, c(
    "households", "members", "acquisitions", "unit_factors", "crosswalk",
    "nutrients", "composition", "enrichment", "vehicles", "scenarios"
  ))
  expect_identical(nrow(hces_example$households), 40L)
  expect_identical(length(unique(hces_example$households$psu)), 8L)
})

test_that("the survey tables pass and their notes are the planted cases", {
  e <- hces_example
  s <- validate_survey(e$households, e$members, e$acquisitions)
  expect_identical(
    audit_log(s$households)$cause,
    c("all", "food_module_nonresponse", "households_without_acquisitions")
  )
  # Households 39 (no acquisitions) and 40 (no food module).
  expect_identical(audit_log(s$households)$n_records, c(40L, 1L, 2L))
  expect_identical(audit_log(s$members)$n_records[-1], c(1L, 1L))
  log <- audit_log(s$acquisitions)
  expect_identical(log$cause, c("all", "missing_quantity", "missing_unit",
                                "not_included"))
  expect_identical(log$n_records[-1], c(1L, 1L, 1L))
  expect_true("sack" %in% e$acquisitions$unit)
  expect_setequal(unique(e$acquisitions$period_days), c(7, 30))
})

test_that("the user tables pass with the planted notes", {
  e <- hces_example
  r <- nutrient_registry(e$nutrients)
  expect_identical(r$column, c("energy_kcal", "iron_mg", "folate_ug_dfe",
                               "vitamin_a_ug_rae"))
  expect_identical(audit_log(validate_unit_factors(e$unit_factors))$cause,
                   "all")
  expect_identical(
    audit_log(validate_crosswalk(e$crosswalk))$cause,
    c("all", "unmatched_food", "not_validated", "missing_edible_portion")
  )
  log <- audit_log(validate_composition(e$composition, r))
  expect_identical(log$detail[-1], "folate_ug_dfe")
  expect_identical(sum(e$composition$fortified), 2L)
  expect_identical(audit_log(validate_enrichment(e$enrichment, r))$cause,
                   "all")
  expect_true(all(c(e$enrichment$composition_id, e$enrichment$enriched_ref_id,
                    e$enrichment$unenriched_ref_id) %in%
                    e$composition$composition_id))
  v <- validate_vehicles(e$vehicles)
  expect_identical(sort(unique(v$vehicle_group)), "wheat_flour")
  expect_identical(audit_log(validate_scenarios(e$scenarios, r))$cause,
                   "all")
})

test_that("every validated food code has a vehicle or composition row", {
  e <- hces_example
  expect_true(all(e$vehicles$food_code %in% e$crosswalk$food_code))
  matched <- e$crosswalk$composition_id[!is.na(e$crosswalk$composition_id)]
  expect_true(all(matched %in% e$composition$composition_id))
  expect_true(all(e$acquisitions$food_code %in% e$crosswalk$food_code))
})
