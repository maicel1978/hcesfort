# Fixture of the data readiness functions (linkage_ladder(),
# unmatched_foods(), estimate_unlinked()): the foods of
# test-unmatched-foods.R with weights, expenditure, a record left out by
# the section rule, a record without unit and one without expenditure.
#
# Households 1, 2, 3 and 4 have weights 2, 1, 3 and 1; household 4 has no
# records. Unit "g", factor 1, period 1 day, so grams per day = quantity.
#
# | rec | hh | food  | g   | exp | status                         |
# |-----|----|-------|-----|-----|--------------------------------|
# | 1   | 1  | rice  | 100 | 10  | linked                         |
# | 2   | 1  | oil   | 50  | 20  | linked                         |
# | 3   | 2  | beans | 30  | 6   | not_validated                  |
# | 4   | 2  | herb  | 20  | 4   | unmatched_food                 |
# | 5   | 2  | salt  | 10  | 1   | not_in_crosswalk               |
# | 6   | 3  | egg   | 40  | 8   | missing_edible_portion         |
# | 7   | 3  | fish  | 60  | 12  | linked                         |
# | 8   | 3  | rice  | NA  | 5   | no grams (missing quantity)    |
# | 9   | 3  | salt  | NA  | 2   | no grams (missing unit)        |
# | 10  | 1  | rice  | 70  | 7   | include = FALSE                |
# | 11  | 1  | oil   | 10  | NA  | linked, expenditure missing    |
lk_acquisitions <- function() {
  data.frame(
    record_id = 1:11,
    household_id = c(1, 1, 2, 2, 2, 3, 3, 3, 3, 1, 1),
    food_code = c("rice", "oil", "beans", "herb", "salt", "egg", "fish",
                  "rice", "salt", "rice", "oil"),
    quantity = c(100, 50, 30, 20, 10, 40, 60, NA, 5, 70, 10),
    unit = c(rep("g", 8), NA, "g", "g"),
    section = "diary", period_days = 1,
    include = c(rep(TRUE, 9), FALSE, TRUE),
    expenditure_lcu = c(10, 20, 6, 4, 1, 8, 12, 5, 2, 7, NA)
  )
}

lk_households <- function(weight = c(2, 1, 3, 1)) {
  data.frame(household_id = 1:4, weight = weight, stratum = "s",
             psu = 1:4, region = c("north", "south", "north", "south"))
}

lk_content <- function(a = lk_acquisitions()) {
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
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  g <- convert_units(a, f, priority = "food")
  link_composition(g, cw, comp, nutrient_registry(c(iron = "mg")))
}

# The example survey linked to its composition table.
example_content <- function() {
  e <- hcesfort::hces_example
  g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
  link_composition(g, e$crosswalk, e$composition,
                   nutrient_registry(e$nutrients))
}

# Eight households, each with a linked food (rice) and an unlinked one
# (herb, `herb_g` grams), in two strata, one PSU per household, two
# regions; `num` and `den` are the household totals of the unlinked and of
# all grams.
ul_case <- function(herb_g, rice_g = rep(100, 8)) {
  a <- data.frame(
    record_id = 1:16, household_id = rep(1:8, each = 2),
    food_code = rep(c("rice", "herb"), 8),
    quantity = as.vector(rbind(rice_g, herb_g)), unit = "g",
    section = "diary", period_days = 1, include = TRUE
  )
  h <- data.frame(household_id = 1:8,
                  weight = c(10, 20, 15, 30, 25, 10, 20, 15),
                  stratum = rep(c("a", "b"), each = 4), psu = 1:8,
                  region = rep(c("north", "south"), 4))
  list(content = lk_content(a), households = h,
       design = as_hces_design(h, lonely_psu = "fail"),
       num = herb_g, den = herb_g + rice_g)
}

reference_design <- function(case) {
  h <- case$households
  h$num <- case$num
  h$den <- case$den
  north <- h$region == "north"
  h$n1 <- h$num * north
  h$d1 <- h$den * north
  h$n0 <- h$num * !north
  h$d0 <- h$den * !north
  survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                    data = h, nest = TRUE)
}
