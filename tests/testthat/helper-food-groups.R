# Fixture of food_group_intake() and food_group_shares(): four invented
# households (hand values in test-food-group-intake.R).
#
# Composition per 100 g: rice iron 1 mg, folate 10 ug DFE; beans iron 5,
# folate missing; milk iron 0, folate 5; egg iron 2, folate 50. Energy
# 100 kcal per 100 g for every food.
# Groups: rice and bread cereals, beans pulses, milk dairy; the egg has no
# group (unclassified); bread is never acquired.
# Records, grams per day: h1 rice 200, beans 100, egg 50 (AFE 2); h2 rice
# 100, milk 400 (AFE 1); h3 beans 50 and a rice record left out by
# `include` (AFE 1); h4 no record (AFE 1).
fg_registry <- function() {
  nutrient_registry(c(energy = "kcal", iron = "mg", folate = "ug_dfe"))
}

fg_food_groups <- function() {
  data.frame(food_code = c("rice", "beans", "milk", "bread"),
             food_group = c("cereals", "pulses", "dairy", "cereals"),
             source = "test fixture")
}

fg_households <- function() {
  data.frame(household_id = 1:4, weight = c(10, 20, 30, 40),
             stratum = c(1, 1, 2, 2), psu = 1:4)
}

fg_afe <- function() {
  new_hces_tbl(data.frame(household_id = 1:4, n_members = 1,
                          afe = c(2, 1, 1, 1)),
               "hces_afe", key = "household_id")
}

fg_content <- function(scale = 1, baseline = TRUE, order = NULL,
                       six = FALSE) {
  a <- data.frame(
    record_id = 1:6, household_id = c(1, 1, 1, 2, 2, 3),
    food_code = c("rice", "beans", "egg", "rice", "milk", "beans"),
    quantity = c(200, 100, 50, 100, 400, 50), unit = "g",
    section = "diary", period_days = 1, include = TRUE
  )
  a <- rbind(a, data.frame(
    record_id = 7, household_id = 3, food_code = "rice", quantity = 999,
    unit = "g", section = "diary", period_days = 1, include = FALSE
  ))
  if (six) a <- rbind(a, fg_records_56())
  a$quantity <- a$quantity * scale
  if (!is.null(order)) a <- a[order, ]
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  cw <- data.frame(food_code = c("rice", "beans", "milk", "egg"),
                   composition_id = c("C1", "C2", "C3", "C4"),
                   match_type = "exact", validated = TRUE, edible_portion = 1)
  comp <- data.frame(composition_id = c("C1", "C2", "C3", "C4"),
                     energy_kcal = 100, iron_mg = c(1, 5, 0, 2),
                     folate_ug_dfe = c(10, NA, 5, 50),
                     basis = "per_100g_edible", food_state = "raw",
                     source = "test fixture")
  rules <- data.frame(composition_id = character(0), nutrient = character(0),
                      source = character(0))
  if (baseline) comp <- unfortified_baseline(comp, rules, fg_registry())
  g <- convert_units(a, f, priority = "food")
  link_composition(g, cw, comp, fg_registry())
}

# Six households for food_group_shares(): h5 rice 300, milk 100 (AFE 1.5);
# h6 beans 80, egg 20 (AFE 1). Strata 1 (h1-h3) and 2 (h4-h6), one PSU per
# household.
fg_records_56 <- function() {
  data.frame(
    record_id = 8:11, household_id = c(5, 5, 6, 6),
    food_code = c("rice", "milk", "beans", "egg"),
    quantity = c(300, 100, 80, 20), unit = "g", section = "diary",
    period_days = 1, include = TRUE
  )
}

fg_households6 <- function() {
  data.frame(household_id = 1:6, weight = c(10, 20, 30, 40, 15, 25),
             stratum = rep(1:2, each = 3), psu = 1:6,
             region = c("a", "b", "a", "b", "a", "b"))
}

fg_afe6 <- function() {
  new_hces_tbl(data.frame(household_id = 1:6, n_members = 1,
                          afe = c(2, 1, 1, 1, 1.5, 1)),
               "hces_afe", key = "household_id")
}

fg_intake6 <- function(scale = 1, groups = fg_food_groups(), order = NULL) {
  food_group_intake(fg_content(scale, six = TRUE, order = order), groups,
                    fg_afe6(), fg_households6())
}

fg_intake <- function(...) {
  food_group_intake(fg_content(...), fg_food_groups(), fg_afe(),
                    fg_households())
}

fg_val <- function(x, h, group, col) {
  x[[col]][x$household_id == h & x$food_group == group]
}

fg_design <- function(h = fg_households6()) {
  as_hces_design(h, lonely_psu = "fail")
}

# The share by survey::svyratio() called directly on the same design.
direct_share <- function(x, group, col, mask = TRUE) {
  h <- fg_households6()
  est <- x[x$food_group == group, ]
  num <- est[[col]][match(h$household_id, est$household_id)]
  tot <- tapply(x[[col]], x$household_id, sum)[as.character(h$household_id)]
  inside <- !is.na(tot) & mask
  h$num <- ifelse(inside, num, 0)
  h$den <- ifelse(inside, tot, 0)
  d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         data = h, nest = TRUE)
  survey::svyratio(~num, ~den, subset(d, inside))
}
