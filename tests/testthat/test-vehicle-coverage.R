# vehicle_coverage(). Fixture: invented foods in grams over one day.
#
# Vehicles: flour (flour 1), bread (bread 0.6, biscuit 0.5), pasta (pasta 1,
# never acquired), all of group "wheat"; sugar (sugar 1, biscuit 0.25).
# AFE: h1 2, h2 1, h3 missing, h4 1, h5 1, h6 1. Household 5 did not
# answer the food module; household 4 has no record.
# By hand:
# h1: flour 200 g, bread 100 g, bread without quantity, oil 50 g ->
#     flour 200 / 2 = 100; bread 60 / 2 = 30 (2 records, 1 without grams);
#     wheat 260 / 2 = 130 (3 records); sugar not acquired.
# h2: biscuit 100 g, flour 50 g not included -> flour not acquired;
#     bread 50; sugar 25; wheat 50.
# h3: sugar 30 g, no AFE -> sugar acquired, grams missing.
# h6: bread without quantity -> acquired, 0 g, acquired_without_grams.
vc_grams <- function(quantity_scale = 1) {
  a <- data.frame(
    record_id = 1:9, household_id = c(1, 1, 1, 1, 2, 2, 3, 5, 6),
    food_code = c("flour", "bread", "bread", "oil", "biscuit", "flour",
                  "sugar", "flour", "bread"),
    quantity = c(200, 100, NA, 50, 100, 50, 30, 100, NA) * quantity_scale,
    unit = "g", section = "diary", period_days = 1,
    include = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE)
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  convert_units(a, f, priority = "food")
}

vc_vehicles <- function() {
  data.frame(
    food_code = c("flour", "bread", "biscuit", "pasta", "sugar", "biscuit"),
    vehicle = c("flour", "bread", "bread", "pasta", "sugar", "sugar"),
    vehicle_group = c("wheat", "wheat", "wheat", "wheat", NA, NA),
    vehicle_fraction = c(1, 0.6, 0.5, 1, 1, 0.25), source = "test fixture"
  )
}

vc_afe <- function() {
  new_hces_tbl(
    data.frame(household_id = 1:6, n_members = 1, energy_kcal_d = 2000,
               afe = c(2, 1, NA, 1, 1, 1)),
    "hces_afe", key = "household_id"
  )
}

vc_households <- function() {
  data.frame(household_id = 1:6, weight = 1, stratum = 1, psu = 1:6,
             food_module_response = c(TRUE, TRUE, TRUE, TRUE, FALSE, TRUE))
}

vc_run <- function(grams = vc_grams(), vehicles = vc_vehicles(), ...) {
  vehicle_coverage(grams, vehicles, vc_afe(), vc_households(), ...)
}

pick <- function(u, h, vehicle, col) {
  u[[col]][u$household_id == h & u$vehicle == vehicle]
}

test_that("grams per AFE and acquisition by hand", {
  u <- vc_run(combine = list(any = c("wheat", "sugar")))
  expect_s3_class(u, c("hces_vehicle_use", "hces_tbl"))
  expect_identical(nrow(u), 6L * 6L)
  expect_identical(unique(u$household_id), 1:6)
  expect_equal(pick(u, 1, "flour", "qty_vehicle_g_d"), 100)
  expect_equal(pick(u, 1, "bread", "qty_vehicle_g_d"), 30)
  expect_identical(pick(u, 1, "bread", "n_records"), 2L)
  expect_identical(pick(u, 1, "bread", "n_records_no_grams"), 1L)
  expect_equal(pick(u, 1, "wheat", "qty_vehicle_g_d"), 130)
  expect_identical(pick(u, 1, "wheat", "n_records"), 3L)
  expect_false(pick(u, 1, "sugar", "acquired"))
  expect_equal(pick(u, 1, "sugar", "qty_vehicle_g_d"), 0)
  expect_false(pick(u, 2, "flour", "acquired"))
  expect_equal(pick(u, 2, "bread", "qty_vehicle_g_d"), 50)
  expect_equal(pick(u, 2, "sugar", "qty_vehicle_g_d"), 25)
  expect_true(pick(u, 1, "any", "acquired"))
  expect_true(is.na(pick(u, 1, "any", "qty_vehicle_g_d")))
  expect_identical(pick(u, 1, "any", "level"), "combined")
})

test_that("status: no AFE, no records and non-response", {
  u <- vc_run()
  expect_identical(pick(u, 3, "sugar", "use_status"), "no_afe")
  expect_true(pick(u, 3, "sugar", "acquired"))
  expect_true(is.na(pick(u, 3, "sugar", "qty_vehicle_g_d")))
  expect_identical(pick(u, 4, "flour", "use_status"), "no_food_records")
  expect_true(is.na(pick(u, 4, "flour", "acquired")))
  expect_identical(pick(u, 5, "flour", "use_status"),
                   "food_module_nonresponse")
  expect_true(is.na(pick(u, 5, "flour", "acquired")))
  expect_true(pick(u, 6, "bread", "acquired"))
  expect_equal(pick(u, 6, "bread", "qty_vehicle_g_d"), 0)
})

test_that("the audit log counts by hand", {
  log <- audit_log(vc_run())
  l <- log[log$step == "vehicle_coverage", ]
  n <- function(cause, detail = NA) {
    rows <- l$cause == cause & (is.na(detail) | l$detail %in% detail)
    l$n_records[rows]
  }
  expect_identical(n("all"), 9L)
  expect_identical(n("not_included"), 1L)
  expect_identical(n("vehicle_food_not_acquired"), 1L)
  expect_identical(n("records_of_vehicle_foods", "bread"), 4L)
  expect_identical(n("vehicle_record_without_grams", "bread"), 2L)
  expect_identical(n("acquired_without_grams", "bread"), 1L)
  expect_identical(n("no_afe"), 1L)
  expect_identical(n("no_food_records"), 1L)
  expect_identical(n("food_module_nonresponse"), 1L)
})

test_that("outliers are excluded only when asked", {
  g <- vc_grams()
  g$outlier <- c(TRUE, rep(NA, 8))
  expect_error(vc_run(grams = g), class = "hcesfort_error_argument")
  u <- vc_run(grams = g, outliers = "exclude")
  expect_false(pick(u, 1, "flour", "acquired"))
  u <- vc_run(grams = g, outliers = "keep")
  expect_equal(pick(u, 1, "flour", "qty_vehicle_g_d"), 100)
  expect_error(vc_run(outliers = "keep"), class = "hcesfort_error_argument")
})

test_that("group rows equal the sum of their vehicles", {
  u <- vc_run()
  est <- u$use_status == "estimated"
  for (h in unique(u$household_id[est])) {
    parts <- u$level == "vehicle" & u$household_id == h &
      u$vehicle %in% c("flour", "bread", "pasta")
    expect_equal(sum(u$qty_vehicle_g_d[parts]), pick(u, h, "wheat",
                                                     "qty_vehicle_g_d"))
  }
})

test_that("errors are classed", {
  v <- vc_vehicles()
  v$food_code <- seq_len(nrow(v))
  v$vehicle_group <- NA
  expect_error(vc_run(vehicles = v), class = "hcesfort_error_join")
  v <- vc_vehicles()
  v$vehicle_group[[6]] <- "wheat"
  expect_error(vc_run(vehicles = v), class = "hcesfort_error_key")
  expect_error(vc_run(combine = list(any = c("wheat", "salt"))),
               class = "hcesfort_error_argument")
  expect_error(vc_run(combine = list(flour = "wheat")),
               class = "hcesfort_error_argument")
  expect_error(vc_run(combine = c("wheat", "sugar")),
               class = "hcesfort_error_argument")
  expect_error(vc_run(grams = as.data.frame(vc_grams())),
               class = "hcesfort_error_audit")
})

test_that("invariant: scaling every quantity by k scales grams by k", {
  u1 <- vc_run()
  u3 <- vc_run(grams = vc_grams(3))
  expect_equal(u3$qty_vehicle_g_d, 3 * u1$qty_vehicle_g_d)
  expect_identical(u3$acquired, u1$acquired)
})

test_that("invariant: results do not depend on row order", {
  g <- vc_grams()
  g2 <- restore_audit(g[rev(seq_len(nrow(g))), ], from = g)
  v2 <- vc_vehicles()[6:1, ]
  u1 <- vc_run()
  u2 <- vc_run(grams = g2, vehicles = v2)
  key <- function(u) paste(u$household_id, u$level, u$vehicle)
  u2 <- u2[match(key(u1), key(u2)), ]
  expect_equal(u2$qty_vehicle_g_d, u1$qty_vehicle_g_d)
  expect_identical(u2$acquired, u1$acquired)
})

test_that("a link_composition() table is accepted, and the example runs", {
  nutrients <- nutrient_registry(hces_example$nutrients)
  g <- convert_units(hces_example$acquisitions, hces_example$unit_factors,
                     priority = "food")
  content <- link_composition(g, hces_example$crosswalk,
                              hces_example$composition, nutrients)
  afe <- new_hces_tbl(
    data.frame(household_id = hces_example$households$household_id,
               n_members = 1, afe = 1),
    "hces_afe", key = "household_id"
  )
  u1 <- vehicle_coverage(g, hces_example$vehicles, afe,
                         hces_example$households)
  u2 <- vehicle_coverage(content, hces_example$vehicles, afe,
                         hces_example$households)
  expect_identical(u1$qty_vehicle_g_d, u2$qty_vehicle_g_d)
  expect_identical(nrow(u1), 40L * 5L)
})

test_that("a vehicles table without rows gives no rows", {
  u <- vc_run(vehicles = vc_vehicles()[0, ])
  expect_identical(nrow(u), 0L)
  expect_s3_class(u, "hces_vehicle_use")
})

test_that("the outlier rule of flag_outliers() is the decision recorded", {
  g <- flag_outliers(vc_grams(), by = "food_code", scale = "household",
                     level = "record", probs = c(0.25, 0.75),
                     multiplier = 3, min_group = 2)
  u <- vc_run(g, outliers = "exclude")
  expect_identical(
    attr(u, "outlier_decision"),
    paste0("exclude; by=food_code; scale=household; level=record; ",
           "probs=0.25,0.75; multiplier=3; min_group=2; type=7")
  )
})
