# apparent_intake(), flag_energy_plausibility() and nutrient_density().
# Fixtures: invented foods in grams over one day.
#
# Composition per 100 g: C1 (rice) energy 300 kcal, iron 2 mg; C2 (oil)
# energy 900 kcal, iron missing. salt is not in the crosswalk.
# Households: 1 to 6; household 5 did not answer the food module.
# AFE: h1 2, h2 1, h3 1, h4 1, h5 1, h6 missing.
# Records and result by hand:
# h1: rice 100 g, oil 50 g, salt 10 g -> used rice and oil, edible 150 g,
#     energy 300 + 450 = 750 kcal, iron 2 mg (oil has no value); per AFE:
#     75 g, 375 kcal, 1 mg; iron coverage 100 / 150.
# h2: rice 200 g not included, rice 100 g -> 300 kcal, 2 mg.
# h3: salt 10 g only -> all_records_lost.
# h4: no record -> no_food_records.
# h5: rice 100 g -> food_module_nonresponse.
# h6: rice 100 g -> no_afe.
ai_content <- function() {
  a <- data.frame(
    record_id = 1:8, household_id = c(1, 1, 1, 2, 2, 3, 5, 6),
    food_code = c("rice", "oil", "salt", "rice", "rice", "salt", "rice",
                  "rice"),
    quantity = c(100, 50, 10, 200, 100, 10, 100, 100), unit = "g",
    section = "diary", period_days = 1,
    include = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE)
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  cw <- data.frame(food_code = c("rice", "oil"), composition_id = c("C1", "C2"),
                   match_type = "exact", validated = TRUE, edible_portion = 1)
  comp <- data.frame(composition_id = c("C1", "C2"), energy_kcal = c(300, 900),
                     iron_mg = c(2, NA), basis = "per_100g_edible",
                     food_state = "raw", source = "test fixture")
  g <- convert_units(a, f, priority = "food")
  link_composition(g, cw, comp, nutrient_registry(c(energy = "kcal",
                                                    iron = "mg")))
}

ai_afe <- function() {
  new_hces_tbl(
    data.frame(household_id = 1:6, n_members = 1, energy_kcal_d = 2000,
               afe = c(2, 1, 1, 1, 1, NA)),
    "hces_afe", key = "household_id"
  )
}

ai_households <- function() {
  data.frame(household_id = 1:6, weight = 1, stratum = 1, psu = 1:6,
             food_module_response = c(TRUE, TRUE, TRUE, TRUE, FALSE, TRUE))
}

test_that("apparent_intake() sums per household and divides by AFE", {
  i <- apparent_intake(ai_content(), ai_afe(), ai_households())
  expect_s3_class(i, c("hces_intake", "hces_tbl"))
  expect_equal(i$household_id, 1:6)
  expect_equal(i$intake_status,
               c("estimated", "estimated", "all_records_lost",
                 "no_food_records", "food_module_nonresponse", "no_afe"))
  expect_equal(i$energy_kcal, c(375, 300, NA, NA, NA, NA))
  expect_equal(i$iron_mg, c(1, 2, NA, NA, NA, NA))
  expect_equal(i$iron_mg_coverage, c(100 / 150, 1, NA, NA, NA, NA))
  expect_equal(i$energy_kcal_coverage[1:2], c(1, 1))
  expect_equal(i$qty_edible_g_d[1:2], c(75, 100))
  expect_equal(i$n_records, c(3, 2, 1, 0, 1, 1))
  expect_equal(i$n_records_used, c(2, 1, 0, 0, 1, 1))
})

test_that("the log counts records left out and households by status", {
  log <- audit_log(apparent_intake(ai_content(), ai_afe(), ai_households()))
  l <- log[log$step == "apparent_intake", ]
  n <- function(cause) l$n_records[l$cause == cause]
  expect_equal(n("all"), 8)
  expect_equal(n("not_included"), 1)
  expect_equal(l$qty_g[l$cause == "not_included"], 200)
  expect_equal(n("not_linked"), 2)
  expect_equal(n("used"), 5)
  for (s in c("all_records_lost", "no_food_records",
              "food_module_nonresponse", "no_afe")) {
    expect_equal(n(s), 1, label = s)
  }
  expect_equal(n("estimated"), 2)
  inc <- l[l$cause == "incomplete_nutrient_value", ]
  expect_equal(inc$detail, "iron_mg")
  expect_equal(inc$n_records, 1)
})

test_that("outliers are excluded or kept only when asked", {
  x <- ai_content()
  expect_error(apparent_intake(x, ai_afe(), ai_households(), "exclude"),
               class = "hcesfort_error_argument")
  x$outlier <- c(NA, FALSE, NA, NA, TRUE, NA, NA, NA)
  expect_error(apparent_intake(x, ai_afe(), ai_households()),
               class = "hcesfort_error_argument")
  keep <- apparent_intake(x, ai_afe(), ai_households(), "keep")
  expect_equal(keep$energy_kcal[2], 300)
  ex <- apparent_intake(x, ai_afe(), ai_households(), "exclude")
  expect_equal(ex$intake_status[2], "all_records_lost")
  expect_equal(ex$energy_kcal[1], 375) # NA outlier = not assessed, kept
  log <- audit_log(ex)
  expect_equal(log$n_records[log$cause == "outlier_excluded"], 1)
})

test_that("invariants: scaling grams scales intake; row order; AFE", {
  base <- apparent_intake(ai_content(), ai_afe(), ai_households())
  x <- ai_content()
  x$qty_edible_g_d <- x$qty_edible_g_d * 3
  x$energy_kcal <- x$energy_kcal * 3
  x$iron_mg <- x$iron_mg * 3
  three <- apparent_intake(x, ai_afe(), ai_households())
  expect_equal(three$energy_kcal, base$energy_kcal * 3)
  expect_equal(three$iron_mg_coverage, base$iron_mg_coverage)
  x <- ai_content()
  xp <- restore_audit(x[8:1, ], from = x)
  hp <- ai_households()[6:1, ]
  p <- apparent_intake(xp, ai_afe(), hp)
  expect_equal(p$energy_kcal, base$energy_kcal[6:1])
  afe2 <- ai_afe()
  afe2$afe <- afe2$afe * 2
  half <- apparent_intake(ai_content(), afe2, ai_households())
  expect_equal(half$energy_kcal, base$energy_kcal / 2)
})

test_that("households are the frame: ids are checked", {
  h <- ai_households()[-1, ]
  expect_error(apparent_intake(ai_content(), ai_afe(), h),
               class = "hcesfort_error_join")
  h <- ai_households()
  h$household_id <- as.character(h$household_id)
  h$psu <- as.character(h$psu)
  expect_error(apparent_intake(ai_content(), ai_afe(), h),
               class = "hcesfort_error_join")
  expect_error(apparent_intake(dplyr::as_tibble(ai_content()), ai_afe(),
                               ai_households()),
               class = "hcesfort_error_audit")
})

test_that("without food_module_response every household responded", {
  h <- ai_households()
  h$food_module_response <- NULL
  i <- apparent_intake(ai_content(), ai_afe(), h)
  expect_equal(i$intake_status[5], "estimated")
})

test_that("flag_energy_plausibility() flags outside the range by hand", {
  i <- apparent_intake(ai_content(), ai_afe(), ai_households())
  f <- flag_energy_plausibility(i, "energy_kcal", 310, 400)
  expect_identical(f$energy_plausible, c(TRUE, FALSE, NA, NA, NA, NA))
  f2 <- flag_energy_plausibility(i, "energy_kcal", 300, 375)
  expect_identical(f2$energy_plausible[1:2], c(TRUE, TRUE))
  log <- audit_log(flag_energy_plausibility(i, "energy_kcal", 310, 370))
  l <- log[log$step == "flag_energy_plausibility", ]
  expect_equal(l$cause, c("all", "energy_below_min", "energy_above_max"))
  expect_match(l$detail[1], "energy_kcal in \\[310, 370\\]")
  e <- "hcesfort_error_argument"
  expect_error(flag_energy_plausibility(i, "energy_kcal"), class = e)
  expect_error(flag_energy_plausibility(i, "energy_kcal", 5, 1), class = e)
  expect_error(flag_energy_plausibility(i, "zinc_mg", 1, 5), class = e)
})

test_that("nutrient_density() divides by energy by hand", {
  i <- apparent_intake(ai_content(), ai_afe(), ai_households())
  d <- nutrient_density(i, "energy_kcal")
  expect_equal(d$iron_mg_per_1000kcal, c(1 / 375, 2 / 300, NA, NA, NA, NA) *
                 1000)
  d100 <- nutrient_density(i, "energy_kcal", per = 100)
  expect_equal(d100$iron_mg_per_100kcal, d$iron_mg_per_1000kcal / 10)
  # density does not depend on the AFE
  afe2 <- ai_afe()
  afe2$afe <- afe2$afe * 2
  d2 <- nutrient_density(apparent_intake(ai_content(), afe2, ai_households()),
                         "energy_kcal")
  expect_equal(d2$iron_mg_per_1000kcal, d$iron_mg_per_1000kcal)
  z <- i
  z$energy_kcal[1] <- 0
  dz <- nutrient_density(z, "energy_kcal")
  expect_true(is.na(dz$iron_mg_per_1000kcal[1]))
  expect_true("zero_energy" %in% audit_log(dz)$cause)
  expect_error(nutrient_density(i), class = "hcesfort_error_argument")
  expect_error(nutrient_density(i, "energy_kcal", per = NULL),
               class = "hcesfort_error_argument")
  expect_error(nutrient_density(i, "energy_kcal", per = -1),
               class = "hcesfort_error_argument")
})

test_that("records of zero grams give zero intake and no coverage", {
  x <- ai_content()
  x$qty_edible_g_d[5] <- 0
  x$energy_kcal[5] <- 0
  x$iron_mg[5] <- 0
  i <- apparent_intake(x, ai_afe(), ai_households())
  expect_equal(i$energy_kcal[2], 0)
  expect_true(is.na(i$iron_mg_coverage[2]))
})

# Record loss (correction 1). By hand from ai_content(): included records
# h1 3 (used 2: salt is not linked), h2 1 (1; the 200 g record is not
# included), h3 1 (0), h4 none, h5 1 (1), h6 1 (1). Purchased grams of the
# included records: h1 160 (used 150), h3 10 (0), h2, h5, h6 100 (100).
# Overall: records 5 / 7; grams 450 / 470.
test_that("record loss per household, by records and by grams", {
  i <- apparent_intake(ai_content(), ai_afe(), ai_households())
  expect_equal(i$n_records_included, c(3, 1, 1, 0, 1, 1))
  expect_equal(i$share_records_used, c(2 / 3, 1, 0, NA, 1, 1))
  expect_equal(i$share_grams_used, c(150 / 160, 1, 0, NA, 1, 1))
})

test_that("an excluded outlier counts as a record not used", {
  x <- ai_content()
  x$outlier <- x$record_id == 2
  i <- apparent_intake(x, ai_afe(), ai_households(), outliers = "exclude")
  expect_equal(i$share_records_used[1], 1 / 3)
  expect_equal(i$share_grams_used[1], 100 / 160)
})

ai_req <- function() {
  data.frame(nutrient = "iron", unit = "mg", ear = 1, ul = 45, ul_unit = "mg",
             ul_applies_to = "total")
}

test_that("the record-loss gate is overall, with both shares", {
  i <- apparent_intake(ai_content(), ai_afe(), ai_households())
  err <- expect_error(inadequacy(i, ai_req(), min_coverage = 0,
                                 min_records_used = 0.72),
                      class = "hcesfort_error_coverage")
  expect_identical(err$measure, "records_used")
  expect_equal(err$coverage, 5 / 7)
  expect_equal(err$shares, c(records = 5 / 7, grams = 450 / 470))
  expect_error(above_ul(i, ai_req(), min_coverage = 0,
                        min_records_used = 0.72),
               class = "hcesfort_error_coverage")
  r <- inadequacy(i, ai_req(), min_coverage = 0, min_records_used = 5 / 7)
  expect_equal(unique(r$share_records_used[r$household_id == 1]), 2 / 3)
  log <- audit_log(r)
  note <- log[log$step == "inadequacy" & log$cause == "records_used", ]
  expect_equal(note$n_records, 7)
  expect_equal(note$n_households, 5)
  expect_match(note$detail, "records: 0.7143; grams: 0.9574")
  u <- above_ul(i, ai_req(), min_coverage = 0, min_records_used = 0)
  expect_equal(u$share_records_used, i$share_records_used)
})

test_that("min_records_used is required, in [0, 1]", {
  i <- apparent_intake(ai_content(), ai_afe(), ai_households())
  for (bad in list(NULL, -0.1, 1.5, NA_real_, c(0.5, 0.6), "0.5")) {
    expect_error(inadequacy(i, ai_req(), min_coverage = 0,
                            min_records_used = bad),
                 class = "hcesfort_error_argument")
  }
  err <- expect_error(above_ul(i, ai_req(), min_coverage = 0),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "min_records_used")
})

test_that("the composition-value gate names its measure", {
  i <- apparent_intake(ai_content(), ai_afe(), ai_households())
  err <- expect_error(inadequacy(i, ai_req(), min_coverage = 0.99,
                                 min_records_used = 0),
                      class = "hcesfort_error_coverage")
  expect_identical(err$measure, "composition_value")
})
