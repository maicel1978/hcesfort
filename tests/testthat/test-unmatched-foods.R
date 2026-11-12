# unmatched_foods(). Fixtures of test-link-composition.R (helpers are
# redefined here so that this file stands alone).
#
# By hand, from link_grams(): not linked are beans (30 g, not_validated),
# herb (20 g, unmatched_food), salt (10 g and one record without grams,
# not_in_crosswalk), egg (40 g, missing_edible_portion) and rice (one
# record of two, without grams, matched). Total grams 310, records 9.
uf_content <- function() {
  cw <- data.frame(
    food_code = c("rice", "oil", "beans", "herb", "egg", "fish"),
    composition_id = c("C1", "C2", "C3", NA, "C4", "C5"),
    match_type = c("exact", "exact", NA, NA, "exact", "proxy"),
    validated = c(TRUE, TRUE, FALSE, FALSE, TRUE, TRUE),
    edible_portion = c(1, 0.5, 1, NA, NA, 1)
  )
  comp <- data.frame(
    composition_id = paste0("C", 1:5), iron_mg = c(2, 1, 5, 1.8, NA),
    basis = "per_100g_edible", food_state = "raw", source = "test fixture"
  )
  a <- data.frame(
    record_id = 1:9, household_id = c(1, 1, 2, 2, 2, 3, 3, 3, 3),
    food_code = c("rice", "oil", "beans", "herb", "salt", "egg", "fish",
                  "rice", "salt"),
    quantity = c(100, 50, 30, 20, 10, 40, 60, NA, NA), unit = "g",
    section = "diary", period_days = 1, include = TRUE
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  g <- convert_units(a, f, priority = "food")
  link_composition(g, cw, comp, nutrient_registry(c(iron = "mg")))
}

test_that("unmatched_foods() lists foods with records not linked", {
  u <- unmatched_foods(uf_content())
  expect_equal(u$food_code, c("egg", "beans", "herb", "salt", "rice"))
  expect_equal(u$match_status, c("missing_edible_portion", "not_validated",
                                 "unmatched_food", "not_in_crosswalk",
                                 "matched"))
  expect_equal(u$qty_g_d_not_linked, c(40, 30, 20, 10, NA))
  expect_equal(u$n_not_linked, c(1, 1, 1, 2, 1))
  expect_equal(u$n_records, c(1, 1, 1, 2, 2))
  expect_equal(u$n_no_grams, c(0, 0, 0, 1, 1))
  expect_equal(u$n_households, c(1, 1, 1, 2, 1))
  expect_equal(u$share_records, u$n_not_linked / 9)
  expect_equal(u$share_grams, c(40, 30, 20, 10, NA) / 310)
})

test_that("order = 'records' ranks by records, then grams, then food", {
  u <- unmatched_foods(uf_content(), order = "records")
  expect_equal(u$food_code, c("salt", "egg", "beans", "herb", "rice"))
})

test_that("the list agrees with the audit log", {
  x <- uf_content()
  u <- unmatched_foods(x)
  log <- audit_log(x)
  linked <- log$n_records[log$step == "link_composition" &
                            log$cause == "linked"]
  expect_equal(sum(u$n_not_linked) + linked, nrow(x))
})

test_that("unmatched_foods() needs the product of link_composition()", {
  expect_error(unmatched_foods(dplyr::as_tibble(uf_content())),
               class = "hcesfort_error_audit")
  expect_error(unmatched_foods(uf_content(), order = "x"),
               class = "hcesfort_error_argument")
})
