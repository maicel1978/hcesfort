# link_composition(). Fixtures: invented foods, all in grams over one day,
# so grams per day equal the quantities.
#
# Crosswalk: rice -> C1 (portion 1); oil -> C2 (portion 0.5, yield 2);
# beans -> C3 not validated; herb unmatched; egg -> C4 without portion;
# fish -> C5 (portion 1). salt is not in the crosswalk.
# Composition per 100 g: C1 iron 2, folate 10; C2 iron 1, folate 0;
# C3 iron 5, folate 100; C4 iron 1.8, folate 47; C5 iron NA, folate 4.
link_crosswalk <- function() {
  data.frame(
    food_code = c("rice", "oil", "beans", "herb", "egg", "fish"),
    composition_id = c("C1", "C2", "C3", NA, "C4", "C5"),
    match_type = c("exact", "exact", NA, NA, "exact", "proxy"),
    validated = c(TRUE, TRUE, FALSE, FALSE, TRUE, TRUE),
    edible_portion = c(1, 0.5, 1, NA, NA, 1),
    yield_factor = c(NA, 2, NA, NA, NA, NA)
  )
}

link_comp <- function() {
  data.frame(
    composition_id = paste0("C", 1:5), iron_mg = c(2, 1, 5, 1.8, NA),
    folate_ug_dfe = c(10, 0, 100, 47, 4), basis = "per_100g_edible",
    food_state = "raw", source = "test fixture",
    fortified = c(FALSE, TRUE, FALSE, FALSE, FALSE)
  )
}

link_nutrients <- function() {
  nutrient_registry(c(iron = "mg", folate = "ug_dfe"))
}

# Records and expected result by hand:
# 1 h1 rice 100 g: edible 100; iron 2 mg; folate 10 ug.
# 2 h1 oil 50 g: edible 50 * 0.5 * 2 = 50; iron 0.5 mg; folate 0.
# 3 h2 beans 30 g: not_validated.
# 4 h2 herb 20 g: unmatched_food.
# 5 h2 salt 10 g: not_in_crosswalk.
# 6 h3 egg 40 g: missing_edible_portion.
# 7 h3 fish 60 g: linked; iron missing, folate 2.4 ug.
# 8 h3 rice, quantity missing: no_grams.
# 9 h3 salt, quantity missing: no_grams (also not in crosswalk; overlap 1).
link_grams <- function() {
  a <- data.frame(
    record_id = 1:9, household_id = c(1, 1, 2, 2, 2, 3, 3, 3, 3),
    food_code = c("rice", "oil", "beans", "herb", "salt", "egg", "fish",
                  "rice", "salt"),
    quantity = c(100, 50, 30, 20, 10, 40, 60, NA, NA), unit = "g",
    section = "diary", period_days = 1, include = TRUE
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  convert_units(a, f, priority = "food")
}

link_default <- function(grams = link_grams(), crosswalk = link_crosswalk(),
                         composition = link_comp()) {
  link_composition(grams, crosswalk, composition, link_nutrients())
}

test_that("link_composition() gives nutrients per record by hand", {
  x <- link_default()
  expect_s3_class(x, c("hces_nutrient_content", "hces_tbl"))
  expect_equal(nrow(x), 9)
  expect_equal(
    x$composition_status,
    c("linked", "linked", "not_validated", "unmatched_food",
      "not_in_crosswalk", "missing_edible_portion", "linked", "no_grams",
      "no_grams")
  )
  expect_equal(x$qty_edible_g_d[c(1, 2, 7)], c(100, 50, 60))
  expect_equal(x$iron_mg[c(1, 2, 7)], c(2, 0.5, NA))
  expect_equal(x$folate_ug_dfe[c(1, 2, 7)], c(10, 0, 2.4))
  expect_true(all(is.na(x$iron_mg[3:6])))
  expect_equal(x$composition_id[1:4], c("C1", "C2", NA, NA))
  expect_equal(x$yield_factor[1:2], c(1, 2))
  expect_equal(x$fortified[1:2], c(FALSE, TRUE))
  expect_identical(attr(x, "nutrients"), link_nutrients())
})

test_that("the log measures coverage over all records and grams", {
  log <- audit_log(link_default())
  l <- log[log$step == "link_composition", ]
  get <- function(cause, what) l[[what]][l$cause == cause]
  expect_equal(get("all", "n_records"), 9)
  expect_equal(get("all", "qty_g"), 310)
  expect_equal(get("linked", "n_records"), 3)
  expect_equal(get("linked", "qty_g"), 210)
  for (cause in c("not_validated", "unmatched_food",
                  "missing_edible_portion")) {
    expect_equal(get(cause, "n_records"), 1, label = cause)
  }
  expect_equal(get("not_validated", "qty_g"), 30)
  expect_equal(get("no_grams", "n_records"), 2)
  expect_true(is.na(get("no_grams", "qty_g")))
  # causes are not hierarchical: record 9 counts under no_grams and here
  expect_equal(get("not_in_crosswalk", "n_records"), 2)
  expect_equal(get("not_in_crosswalk", "qty_g"), 10)
  expect_equal(get("no_grams_and_no_match", "n_records"), 1)
  miss <- l[l$cause == "missing_nutrient_value", ]
  expect_equal(miss$detail, "iron_mg")
  expect_equal(miss$qty_g, 60)
  # the logs of the three input tables come first
  expect_true(all(c("validate_crosswalk", "validate_composition") %in%
                    log$step))
})

test_that("invariants: grams scale nutrients; row order; no record lost", {
  base <- link_default()
  g <- link_grams()
  g$qty_g_d <- g$qty_g_d * 4
  four <- link_default(grams = g)
  expect_equal(four$iron_mg, base$iron_mg * 4)
  perm <- c(9, 1, 8, 2, 7, 3, 6, 4, 5)
  gp <- restore_audit(g[perm, ], from = g)
  gp$qty_g_d <- gp$qty_g_d / 4
  xp <- link_composition(gp, link_crosswalk()[6:1, ], link_comp()[5:1, ],
                         link_nutrients())
  expect_equal(xp$iron_mg, base$iron_mg[perm])
  expect_equal(xp$composition_status, base$composition_status[perm])
})

test_that("a validated composition table brings its registry", {
  comp <- validate_composition(link_comp(), link_nutrients())
  x <- link_composition(link_grams(), link_crosswalk(), comp)
  expect_equal(x$iron_mg[1], 2)
  expect_error(link_composition(link_grams(), link_crosswalk(), link_comp()),
               class = "hcesfort_error_argument")
  other <- nutrient_registry(c(iron = "mg"))
  expect_error(link_composition(link_grams(), link_crosswalk(), comp, other),
               class = "hcesfort_error_argument")
})

test_that("without fortified or yield_factor the columns adapt", {
  cw <- link_crosswalk()
  cw$yield_factor <- NULL
  comp <- link_comp()
  comp$fortified <- NULL
  x <- link_default(crosswalk = cw, composition = comp)
  expect_equal(x$qty_edible_g_d[2], 25)
  expect_false("fortified" %in% names(x))
})

test_that("joins are checked", {
  cw <- link_crosswalk()
  cw$composition_id[1] <- "C9"
  expect_error(link_default(crosswalk = cw), class = "hcesfort_error_join")
  comp <- link_comp()
  comp$composition_id <- 1:5
  expect_error(link_default(composition = comp),
               class = "hcesfort_error_join")
  cw <- link_crosswalk()
  cw$food_code <- seq_len(nrow(cw))
  expect_error(link_default(crosswalk = cw), class = "hcesfort_error_join")
  cw <- rbind(link_crosswalk(), link_crosswalk()[1, ])
  expect_error(link_default(crosswalk = cw), class = "hcesfort_error_key")
})

test_that("grams must come from convert_units()", {
  expect_error(link_default(grams = dplyr::as_tibble(link_grams())),
               class = "hcesfort_error_audit")
})

test_that("an empty table keeps the types", {
  g <- link_grams()
  g0 <- restore_audit(g[0, ], from = g)
  x <- link_default(grams = g0)
  expect_type(x$iron_mg, "double")
  expect_identical(x$composition_status, character(0))
})
