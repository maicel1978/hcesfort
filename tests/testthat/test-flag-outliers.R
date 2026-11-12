# flag_outliers(). Fixtures: invented records in grams with one day, so
# grams per day equal the quantities; the quantiles are worked out by hand.
#
# Food "a", households 1 to 11, one record each: 0.5, 2, 3, ..., 10, 100.
#   Type 7 quantiles of 11 values: p = 0.1 -> x[2] = 2; p = 0.9 -> x[10] =
#   10. With multiplier 2: high above 20 (100), low below 1 (0.5).
# Food "b", households 1 to 3: 5, 6, 500; too small for min_group 5.
# Record 15: food "a", household 12, quantity missing.
outlier_grams <- function(quantity = NULL) {
  q <- c(0.5, 2:10, 100, 5, 6, 500, NA)
  if (!is.null(quantity)) q <- quantity
  a <- data.frame(
    record_id = 1:15, household_id = c(1:11, 1:3, 12),
    food_code = c(rep("a", 11), rep("b", 3), "a"),
    quantity = q, unit = "g", section = "diary", period_days = 1,
    include = TRUE
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  convert_units(a, f, priority = "food")
}

flag_default <- function(g, ...) {
  flag_outliers(g, by = "food_code", scale = "household", level = "record",
                probs = c(0.1, 0.9), multiplier = 2, min_group = 5, ...)
}

test_that("flag_outliers() flags high and low values by hand", {
  f <- flag_default(outlier_grams())
  expect_s3_class(f, c("hces_grams", "hces_tbl"))
  expected <- c(TRUE, rep(FALSE, 9), TRUE, NA, NA, NA, NA)
  expect_identical(f$outlier, expected)
  expect_equal(f$quantity, outlier_grams()$quantity) # nothing changed
  log <- audit_log(f)
  log <- log[log$step == "flag_outliers", ]
  expect_equal(log$cause, c("all", "outlier_high", "outlier_low",
                            "not_assessed_no_grams",
                            "not_assessed_small_group"))
  expect_equal(log$n_records, c(15, 1, 1, 1, 3))
  expect_equal(log$qty_g[2:3], c(100, 0.5))
  expect_match(log$detail[1], "probs=0.1,0.9; multiplier=2; min_group=5")
})

test_that("the fences agree with stats::quantile() on the group", {
  g <- outlier_grams()
  v <- g$qty_g_d[g$food_code == "a" & !is.na(g$qty_g_d)]
  for (type in c(1, 6, 7, 9)) {
    q <- stats::quantile(v, c(0.1, 0.9), type = type, names = FALSE)
    f <- flag_default(g, type = type)
    a <- f$food_code == "a" & !is.na(f$qty_g_d)
    expect_identical(f$outlier[a], v > 2 * q[2] | (v > 0 & v < q[1] / 2))
  }
})

test_that("zero is never flagged low", {
  f <- flag_default(outlier_grams(c(0, 2:10, 100, 5, 6, 500, NA)))
  expect_false(f$outlier[1])
})

test_that("per_capita and per_afe divide by the household's divisor", {
  g <- outlier_grams()
  afe <- new_hces_tbl(
    data.frame(household_id = 1:12, n_members = c(rep(1, 10), 10, 1),
               energy_kcal_d = 2000, afe = c(rep(1, 10), 10, NA)),
    "hces_afe", key = "household_id"
  )
  # household 11 has 10 members: 100 g becomes 10 g, inside the fence.
  pc <- flag_outliers(g, "food_code", "per_capita", "record", c(0.1, 0.9),
                      2, 5, afe = afe)
  expect_false(pc$outlier[11])
  pa <- flag_outliers(g, "food_code", "per_afe", "record", c(0.1, 0.9), 2,
                      5, afe = afe)
  expect_false(pa$outlier[11])
  # household 12 has no AFE but also no grams; give it grams
  g2 <- outlier_grams(c(0.5, 2:10, 100, 5, 6, 500, 7))
  pa2 <- flag_outliers(g2, "food_code", "per_afe", "record", c(0.1, 0.9), 2,
                       5, afe = afe)
  expect_true(is.na(pa2$outlier[15]))
  log <- audit_log(pa2)
  expect_equal(log$n_records[log$cause == "not_assessed_no_afe"], 1)
})

test_that("household level sums the records of a household and group", {
  # Household 5 buys "a" in two records of 30 g each.
  a <- data.frame(
    record_id = 1:12, household_id = c(1:11, 5), food_code = "a",
    quantity = c(10:13, 30, 15:20, 30), unit = "g", section = "diary",
    period_days = 1, include = TRUE
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  g <- convert_units(a, f, "food")
  # Record level, 12 values 10..13, 15..20, 30, 30. Type 7: q(0.9) at
  # h = 11 * 0.9 + 1 = 10.9 -> 20 + 0.9 * (30 - 20) = 29, fence 58;
  # q(0.1) at h = 2.1 -> 11.1, fence 5.55. Nothing flagged.
  r <- flag_outliers(g, "food_code", "household", "record", c(0.1, 0.9), 2,
                     5)
  expect_false(any(r$outlier))
  # Household level, 11 values 10..13, 15..20, 60: q(0.9) = x[10] = 20,
  # fence 40; 60 is above, so both records of household 5 are flagged.
  h <- flag_outliers(g, "food_code", "household", "household", c(0.1, 0.9),
                     2, 5)
  expect_identical(h$outlier, c(rep(FALSE, 4), TRUE, rep(FALSE, 6), TRUE))
  log <- audit_log(h)
  expect_equal(log$qty_g[log$cause == "outlier_high"], 60)
})

test_that("invariants: scale, row order and a larger multiplier", {
  g <- outlier_grams()
  base <- flag_default(g)
  g3 <- outlier_grams(outlier_grams()$quantity * 3)
  expect_identical(flag_default(g3)$outlier, base$outlier)
  perm <- c(15, 3, 12, 1, 14, 2, 11, 4, 13, 5, 10, 6, 9, 7, 8)
  gp <- convert_units(
    dplyr::as_tibble(g)[perm, names(outlier_grams())[1:8]],
    data.frame(unit = "g", factor = 1, factor_type = "mass_g",
               source = "test fixture"), "food"
  )
  expect_identical(flag_default(gp)$outlier, base$outlier[perm])
  wide <- flag_outliers(g, "food_code", "household", "record", c(0.1, 0.9),
                        50, 5)
  expect_true(all(wide$outlier <= base$outlier, na.rm = TRUE))
})

test_that("a missing group value forms its own group", {
  g <- outlier_grams()
  g$section <- c(rep("x", 6), rep(NA, 9))
  f <- flag_outliers(g, "section", "household", "record", c(0.1, 0.9), 2, 5)
  expect_equal(sum(!is.na(f$outlier)), 14)
})

test_that("arguments are checked with classed errors", {
  g <- outlier_grams()
  e <- "hcesfort_error_argument"
  expect_error(flag_outliers(g, "food_code"), class = e)
  expect_error(flag_outliers(g, "nope", "household", "record", c(0.1, 0.9),
                             2, 5), class = e)
  expect_error(flag_outliers(g, "food_code", "household", "record",
                             c(0.9, 0.1), 2, 5), class = e)
  expect_error(flag_outliers(g, "food_code", "household", "record",
                             c(0.1, 0.9), 0.5, 5), class = e)
  expect_error(flag_outliers(g, "food_code", "household", "record",
                             c(0.1, 0.9), 2, 0), class = e)
  expect_error(flag_default(g, type = 10), class = e)
  expect_error(flag_outliers(g, "food_code", "per_afe", "record",
                             c(0.1, 0.9), 2, 5), class = e)
  expect_error(flag_outliers(g, "food_code", "household", "nope",
                             c(0.1, 0.9), 2, 5), class = e)
})

test_that("inputs must be products of the package", {
  g <- outlier_grams()
  expect_error(flag_default(dplyr::as_tibble(g)),
               class = "hcesfort_error_audit")
  afe <- data.frame(household_id = 1:12, n_members = 1, afe = 1)
  expect_error(flag_outliers(g, "food_code", "per_afe", "record",
                             c(0.1, 0.9), 2, 5, afe = afe),
               class = "hcesfort_error_audit")
  afe <- new_hces_tbl(data.frame(household_id = as.character(1:12),
                                 n_members = 1, afe = 1),
                      "hces_afe", key = "household_id")
  expect_error(flag_outliers(g, "food_code", "per_afe", "record",
                             c(0.1, 0.9), 2, 5, afe = afe),
               class = "hcesfort_error_join")
})

test_that("an empty table passes through both steps", {
  a <- outlier_grams()[0, 1:8]
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  g <- convert_units(dplyr::as_tibble(a), f, "food")
  expect_type(g$qty_g_d, "double")
  expect_type(g$factor_from, "character")
  out <- flag_default(g)
  expect_identical(out$outlier, logical(0))
})
