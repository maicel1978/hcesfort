# convert_units(). Fixtures: invented records and factors with round
# numbers; every expected gram is worked out by hand below.
#
# Factors: lb generic 450 g; lb for rice 500 g; l generic 1000 ml without
# density; l for oil 1000 ml at 0.9 g/ml; dozen for egg 12 pieces of 50 g;
# piece for bread 1 piece without weight.
units_factors <- function() {
  data.frame(
    unit = c("lb", "lb", "l", "l", "dozen", "piece"),
    food_code = c(NA, "rice", NA, "oil", "egg", "bread"),
    factor = c(450, 500, 1000, 1000, 12, 1),
    factor_type = c("mass_g", "mass_g", "volume_ml", "volume_ml", "count",
                    "count"),
    density_g_ml = c(NA, NA, NA, 0.9, NA, NA),
    piece_weight_g = c(NA, NA, NA, NA, 50, NA),
    source = "test fixture"
  )
}

# Records (household, food, quantity, unit, days) and grams by hand:
# 1 (h1) rice 2 lb, 7 d: food 1000 g / generic 900 g.
# 2 (h1) beans 1 lb, 7 d: generic 450 g, 64.2857 g/d.
# 3 (h1) oil 2 l, 7 d: 2000 ml * 0.9 = 1800 g, 257.1429 g/d.
# 4 (h2) milk 1 l, 1 d: generic l without density -> no_density.
# 5 (h2) egg 1 dozen, 2 d: 12 * 50 = 600 g, 300 g/d.
# 6 (h2) bread 3 piece, 1 d: no piece weight -> no_piece_weight.
# 7 (h3) beans NA lb: missing_quantity.
# 8 (h3) beans 1 NA: missing_unit.
# 9 (h3) beans 1 sack: no_factor.
units_acquisitions <- function() {
  data.frame(
    record_id = 1:9, household_id = c(1, 1, 1, 2, 2, 2, 3, 3, 3),
    food_code = c("rice", "beans", "oil", "milk", "egg", "bread", "beans",
                  "beans", "beans"),
    quantity = c(2, 1, 2, 1, 1, 3, NA, 1, 1),
    unit = c("lb", "lb", "l", "l", "dozen", "piece", "lb", NA, "sack"),
    section = "diary", period_days = c(7, 7, 7, 1, 2, 1, 7, 7, 7),
    include = TRUE
  )
}

cause_count <- function(log, cause, kind = NULL) {
  r <- log[log$step == "convert_units" & log$cause == cause, ]
  if (!is.null(kind)) r <- r[r$kind == kind, ]
  r$n_records
}

test_that("convert_units() converts mass, volume and count by hand", {
  g <- convert_units(units_acquisitions(), units_factors(), priority = "food")
  expect_s3_class(g, c("hces_grams", "hces_tbl"))
  expect_equal(nrow(g), 9)
  expect_equal(g$qty_g[1:3], c(1000, 450, 1800))
  expect_equal(g$qty_g[5], 600)
  expect_equal(g$qty_g_d[c(1, 2, 3, 5)], c(1000 / 7, 450 / 7, 1800 / 7, 300))
  expect_equal(g$factor_from[1:3], c("food", "generic", "food"))
  expect_equal(
    g$grams_status,
    c("converted", "converted", "converted", "no_density", "converted",
      "no_piece_weight", "missing_quantity", "missing_unit", "no_factor")
  )
  expect_true(all(is.na(g$qty_g[g$grams_status != "converted"])))
})

test_that("priority picks the food or the generic factor and is counted", {
  food <- convert_units(units_acquisitions(), units_factors(), "food")
  generic <- convert_units(units_acquisitions(), units_factors(), "generic")
  expect_equal(food$qty_g[1], 1000)
  expect_equal(generic$qty_g[1], 900)
  expect_equal(generic$factor_from[1], "generic")
  # Under "generic" oil takes the generic l row, which has no density, even
  # though its own row has one: priority is applied before conversion.
  expect_equal(generic$grams_status[3], "no_density")
  log <- audit_log(generic)
  both <- log[log$cause == "food_and_generic_factor", ]
  expect_equal(both$n_records, 2)
  expect_equal(both$detail, "used: generic")
})

test_that("density and piece weight given by the caller fill and are logged", {
  g <- convert_units(units_acquisitions(), units_factors(), "food",
                     density_g_ml = 1.03, piece_weight_g = 60)
  expect_equal(g$qty_g[4], 1030)
  expect_equal(g$qty_g[6], 180)
  expect_equal(g$qty_g[3], 1800) # the row's own density wins
  log <- audit_log(g)
  expect_equal(cause_count(log, "density_assumed", "filled"), 1)
  expect_equal(log$qty_g[log$cause == "density_assumed"], 1030)
  expect_equal(log$qty_g[log$cause == "piece_weight_assumed"], 180)
})

test_that("the log counts every reason, records and grams per day", {
  log <- audit_log(convert_units(units_acquisitions(), units_factors(),
                                 "food"))
  expect_equal(cause_count(log, "all", "input"), 9)
  for (cause in c("missing_quantity", "missing_unit", "no_factor",
                  "no_density", "no_piece_weight")) {
    expect_equal(cause_count(log, cause, "flagged"), 1, label = cause)
  }
  conv <- log[log$cause == "converted", ]
  expect_equal(conv$n_records, 4)
  expect_equal(conv$n_households, 2)
  expect_equal(conv$qty_g, (1000 + 450 + 1800) / 7 + 300)
  # the log of the acquisitions comes first
  expect_equal(log$step[1], "validate_acquisitions")
})

test_that("household_share scales grams per day; a missing share is flagged", {
  a <- units_acquisitions()
  a$household_share <- c(0.5, 1, 1, 1, 1, 1, 1, 1, NA)
  g <- convert_units(a, units_factors(), "food")
  expect_equal(g$qty_g_d[1], 500 / 7)
  expect_equal(g$qty_g[1], 1000)
  # record 9 has no factor and no share: counted under both, status no_factor
  expect_equal(g$grams_status[9], "no_factor")
  expect_equal(cause_count(audit_log(g), "missing_household_share"), 1)
  a$household_share[9] <- 1
  a$household_share[2] <- NA
  g <- convert_units(a, units_factors(), "food")
  expect_equal(g$grams_status[2], "missing_household_share")
  expect_true(is.na(g$qty_g_d[2]))
})

test_that("invariants: scaling quantities by k scales grams; row order", {
  a <- units_acquisitions()
  g1 <- convert_units(a, units_factors(), "food")
  a3 <- a
  a3$quantity <- a3$quantity * 3
  g3 <- convert_units(a3, units_factors(), "food")
  expect_equal(g3$qty_g_d, g1$qty_g_d * 3)
  perm <- c(9, 3, 1, 7, 5, 2, 8, 4, 6)
  gp <- convert_units(a[perm, ], units_factors()[c(6, 1, 4, 2, 5, 3), ],
                      "food")
  expect_equal(gp$qty_g_d, g1$qty_g_d[perm])
  expect_equal(gp$grams_status, g1$grams_status[perm])
})

test_that("a dozen is never read as grams", {
  f <- units_factors()
  f$piece_weight_g[5] <- NA
  g <- convert_units(units_acquisitions(), f, "food")
  expect_equal(g$grams_status[5], "no_piece_weight")
})

test_that("arguments are checked with classed errors", {
  a <- units_acquisitions()
  f <- units_factors()
  expect_error(convert_units(a, f), class = "hcesfort_error_argument")
  expect_error(convert_units(a, f, "both"), class = "hcesfort_error_argument")
  expect_error(convert_units(a, f, "food", density_g_ml = 0),
               class = "hcesfort_error_argument")
  expect_error(convert_units(a, f, "food", piece_weight_g = c(1, 2)),
               class = "hcesfort_error_argument")
  expect_error(convert_units(a[-1], f, "food"),
               class = "hcesfort_error_schema")
  f$factor_type[1] <- "kg"
  expect_error(convert_units(a, f, "food"), class = "hcesfort_error_value")
})

test_that("food codes of different types fail as a join error", {
  a <- units_acquisitions()
  a$food_code <- seq_len(nrow(a))
  expect_error(convert_units(a, units_factors(), "food"),
               class = "hcesfort_error_join")
})

test_that("generic factors only, with numeric units, work", {
  a <- units_acquisitions()[1:2, ]
  a$unit <- c(1, 1)
  f <- data.frame(unit = 1, factor = 450, factor_type = "mass_g",
                  source = "test fixture")
  g <- convert_units(a, f, "food")
  expect_equal(g$qty_g, c(900, 450))
  expect_equal(g$factor_from, c("generic", "generic"))
})

test_that("a filter between steps is recorded as an external change", {
  a <- validate_acquisitions(units_acquisitions())
  a <- a[1:5, ]
  log <- audit_log(convert_units(a, units_factors(), "food"))
  expect_true("rows_changed_outside_package" %in% log$cause)
})
