# Fixture of missing_values() and of the log rows and notes on missing
# composition values (P162).
#
# Fixture of finding 8 of the review v0.2 (built here): three households
# of weight 1, each with 400 g of rice a day (vitamin A 0) and 10 g of
# liver whose vitamin A is missing; edible portion 1, so edible grams =
# grams. By hand: one row, vitamin A, the liver, 30 weighted grams of
# 1230, share 10 / 410; with the liver filled every gram has a value.
# With `bread = TRUE`, household 1 also has 50 g of bread (B1), whose
# value is set by `comp`.
liver_case <- function(weight = c(1, 1, 1), comp = NULL, bread = FALSE) {
  a <- data.frame(
    record_id = 1:6, household_id = rep(1:3, each = 2),
    food_code = rep(c("rice", "liver"), 3), quantity = rep(c(400, 10), 3),
    unit = "g", section = "diary", period_days = 1, include = TRUE
  )
  if (bread) {
    a <- rbind(a, data.frame(record_id = 7, household_id = 1,
                             food_code = "bread", quantity = 50, unit = "g",
                             section = "diary", period_days = 1,
                             include = TRUE))
  }
  h <- data.frame(household_id = 1:3, weight = weight, stratum = "s",
                  psu = 1:3)
  cw <- data.frame(food_code = c("rice", "liver", "bread"),
                   composition_id = c("R1", "L1", "B1"), match_type = "exact",
                   validated = TRUE, edible_portion = 1)
  if (is.null(comp)) {
    comp <- data.frame(composition_id = c("R1", "L1", "B1"),
                       iron_mg = c(1, 6, 2), vitamin_a_ug_rae = c(0, NA, 0))
  }
  comp$basis <- "per_100g_edible"
  comp$food_state <- "raw"
  comp$source <- "test fixture"
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  g <- convert_units(a, f, priority = "food")
  reg <- nutrient_registry(c(iron = "mg", vitamin_a = "ug_rae"))
  list(content = link_composition(g, cw, comp, reg), households = h)
}

# The liver case up to the apparent intake, one AFE per household.
liver_intake <- function() {
  x <- liver_case()
  afe <- new_hces_tbl(
    data.frame(household_id = 1:3, n_members = 1, energy_kcal_d = 2000,
               afe = 1),
    "hces_afe", key = "household_id"
  )
  apparent_intake(x$content, afe, x$households)
}
