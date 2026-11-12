# Test fixtures: small invented tables, not survey data. Each test works out
# its expected result by hand from these values.

# Three acquisition records of two households, as a carrier with a log of
# one `input` row. Grams: 100 + 250 + 50.
fixture_carrier <- function() {
  data <- data.frame(
    record_id = c(1L, 2L, 3L),
    household_id = c(10L, 10L, 20L),
    qty_g = c(100, 250, 50)
  )
  log <- audit_row(
    step = "fixture", table = "acquisitions", kind = "input", cause = "all",
    n_records = 3L, n_households = 2L, qty_g = 400
  )
  new_hces_tbl(data, "hces_acquisitions", audit = log, key = "record_id")
}

# A carrier for audit_summary() whose log has, by hand,
#  1 s1/acquisitions input   10 records
#  2 s1/acquisitions excluded 2 records  -> share 2/10 = 0.2
#  3 s1/acquisitions note     4 records  -> not summarised
#  4 s2/grams        flagged  3 records  -> no input of s2: NA
#  5 s1/acquisitions input    8 records  (second run of s1)
#  6 s1/acquisitions filled   2 records  -> share 2/8 = 0.25
#  7 s3/acquisitions external_change 1 record -> NA
summary_fixture <- function() {
  x <- fixture_carrier()
  attr(x, "audit") <- audit_row(
    step = c("s1", "s1", "s1", "s2", "s1", "s1", "s3"),
    table = c(rep("acquisitions", 3), "grams", rep("acquisitions", 3)),
    kind = c("input", "excluded", "note", "flagged", "input", "filled",
             "external_change"),
    cause = c("all", "no_qty", "x", "outlier", "all", "unit", "rows"),
    n_records = c(10, 2, 4, 3, 8, 2, 1),
    n_households = c(5, 1, 2, 2, 4, 1, NA),
    qty_g = c(1000, 50, NA, 30, 900, 20, NA)
  )
  x
}

# Standard tables of an invented survey of three households. Household 3 has
# no members and no acquisitions. By hand:
# members: 1 missing age (household 1), 1 missing sex (household 2);
# acquisitions: 1 missing quantity (household 1), 1 missing unit
# (household 2), 1 record not included (household 2).
fixture_households <- function() {
  data.frame(
    household_id = 1:3, weight = c(100, 200, 300), stratum = c(1L, 1L, 2L),
    psu = 1:3, region = c("north", "north", "south")
  )
}

fixture_members <- function() {
  data.frame(
    household_id = c(1L, 1L, 2L, 2L), member_id = c(1L, 2L, 1L, 2L),
    age_years = c(34, NA, 70, 5), sex = c("female", "male", NA, "female")
  )
}

fixture_acquisitions <- function() {
  data.frame(
    record_id = 1:4, household_id = c(1L, 1L, 2L, 2L),
    food_code = c("rice", "oil", "rice", "beans"),
    quantity = c(2, NA, 1, 0.5), unit = c("lb", "l", NA, "kg"),
    section = "diary", period_days = 7,
    include = c(TRUE, TRUE, TRUE, FALSE)
  )
}

# User-supplied tables, invented. Values are not taken from any composition
# table or standard.
fixture_nutrients <- function() {
  nutrient_registry(c(iron = "mg", folate = "ug_dfe"))
}

# One generic factor per unit (food_code NA) and one food-specific factor;
# the volume row has no density and is still valid.
fixture_unit_factors <- function() {
  data.frame(
    unit = c("lb", "lb", "l", "piece"),
    food_code = c(NA, "rice", NA, "egg"),
    factor = c(453.6, 453.6, 1000, 1),
    factor_type = c("mass_g", "mass_g", "volume_ml", "count"),
    density_g_ml = NA_real_, piece_weight_g = c(NA, NA, NA, 50),
    source = "invented"
  )
}

# By hand: 1 unmatched food (beans), 1 not validated (oil), 1 missing edible
# portion (oil).
fixture_crosswalk <- function() {
  data.frame(
    food_code = c("rice", "oil", "beans"),
    composition_id = c("C01", "C02", NA),
    match_type = c("exact", NA, NA), validated = c(TRUE, FALSE, FALSE),
    edible_portion = c(1, NA, 0.9)
  )
}

# By hand: iron_mg missing in 1 row, folate_ug_dfe missing in 2 rows.
fixture_composition <- function() {
  data.frame(
    composition_id = c("C01", "C02", "C03"),
    iron_mg = c(0.8, NA, 2), folate_ug_dfe = c(NA, 20, NA),
    basis = "per_100g_edible", food_state = c("raw", "cooked", "unknown"),
    source = "invented", label = c("a", "b", "c")
  )
}

# One food with two vehicles; 1 source pending.
fixture_vehicles <- function() {
  data.frame(
    food_code = c("bread", "biscuit", "biscuit"),
    vehicle = c("wheat_flour", "wheat_flour", "sugar"),
    vehicle_fraction = c(0.7, 0.6, 0.2),
    source = c("invented", "invented", "SOURCE PENDING")
  )
}

fixture_scenarios <- function() {
  data.frame(
    scenario = "s1", vehicle = c("wheat_flour", "wheat_flour"),
    nutrient = c("iron", "folate"), level_mg_kg = c(30, 1.5),
    level_basis = c("nutrient", "compound"),
    nutrient_fraction = c(NA, 0.9), source = "invented"
  )
}
