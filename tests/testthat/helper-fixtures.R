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
