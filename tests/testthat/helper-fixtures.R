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
