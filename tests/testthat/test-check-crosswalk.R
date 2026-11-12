# check_crosswalk(). Fixture: invented crosswalk and composition; flags
# worked out by hand.
#
# rice  -> C1, portion 1          composition C1 raw,    iron 2,  kcal 360
# rice2 -> C1, portion 0.9        (same C1: shared match, portion conflict)
# bread -> C2, portion 1, review  composition C2 cooked, iron NA, kcal 250
# soup  -> C3, portion 1, yield 3 composition C3 as_consumed, fortified,
#                                 iron 1, kcal 1200 (above 900)
# egg   -> C4, no portion         composition C4 raw, iron 1.8, kcal 140
# herb  -> not validated
ck_crosswalk <- function() {
  data.frame(
    food_code = c("rice", "rice2", "bread", "soup", "egg", "herb"),
    composition_id = c("C1", "C1", "C2", "C3", "C4", "C4"),
    match_type = c("exact", "exact", "needs_review", "proxy", "exact", NA),
    validated = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
    edible_portion = c(1, 0.9, 1, 1, NA, 1),
    yield_factor = c(NA, NA, NA, 3, NA, NA)
  )
}

ck_comp <- function() {
  data.frame(
    composition_id = paste0("C", 1:4), iron_mg = c(2, NA, 1, 1.8),
    energy_kcal = c(360, 250, 1200, 140), basis = "per_100g_edible",
    food_state = c("raw", "cooked", "as_consumed", "raw"),
    source = "test fixture", fortified = c(FALSE, FALSE, TRUE, FALSE),
    group = c("cereal", "cereal", "dish", "egg")
  )
}

ck_nutrients <- function() nutrient_registry(c(iron = "mg", energy = "kcal"))

test_that("check_crosswalk() flags each control by hand", {
  x <- check_crosswalk(ck_crosswalk(), ck_comp(), ck_nutrients(),
                       review_types = "needs_review",
                       ranges = data.frame(column = "energy_kcal", min = 50,
                                           max = 900))
  expect_s3_class(x, c("hces_crosswalk", "hces_tbl"))
  expect_identical(x$flag_missing_edible_portion,
                   c(FALSE, FALSE, FALSE, FALSE, TRUE, NA))
  expect_identical(x$flag_portion_conflict,
                   c(TRUE, TRUE, FALSE, FALSE, FALSE, NA))
  expect_identical(x$flag_shared_match,
                   c(TRUE, TRUE, FALSE, FALSE, FALSE, NA))
  expect_identical(x$flag_consumed_no_yield,
                   c(FALSE, FALSE, TRUE, FALSE, FALSE, NA))
  expect_equal(x$n_missing_nutrients, c(0, 0, 1, 0, 0, NA))
  expect_identical(x$flag_fortified, c(FALSE, FALSE, FALSE, TRUE, FALSE, NA))
  expect_identical(x$flag_review_type,
                   c(FALSE, FALSE, TRUE, FALSE, FALSE, NA))
  expect_identical(x$flag_outside_range,
                   c(FALSE, FALSE, FALSE, TRUE, FALSE, NA))
  log <- audit_log(x)
  l <- log[log$step == "check_crosswalk" & log$kind == "flagged", ]
  expect_equal(
    setNames(l$n_records, l$cause),
    c(missing_edible_portion = 1, portion_conflict = 2, shared_match = 2,
      consumed_no_yield = 1, fortified = 1, review_type = 1,
      outside_range = 1, missing_nutrients = 1)
  )
})

test_that("ranges by group apply only to their group", {
  ranges <- data.frame(group = c("cereal", "egg"), column = "energy_kcal",
                       min = c(300, NA), max = c(400, 100))
  x <- check_crosswalk(ck_crosswalk(), ck_comp(), ck_nutrients(),
                       ranges = ranges, group = "group")
  # bread (cereal, 250 < 300) and egg (140 > 100); soup is not ranged
  expect_identical(x$flag_outside_range,
                   c(FALSE, FALSE, TRUE, FALSE, TRUE, NA))
})

test_that("grams add records and grams per food and weight the log", {
  a <- data.frame(
    record_id = 1:4, household_id = 1, food_code = c("rice", "rice", "egg",
                                                     "salt"),
    quantity = c(100, NA, 40, 5), unit = "g", section = "diary",
    period_days = 1, include = TRUE
  )
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  g <- convert_units(a, f, "food")
  x <- check_crosswalk(ck_crosswalk(), ck_comp(), ck_nutrients(), grams = g)
  expect_equal(x$n_records, c(2, 0, 0, 0, 1, 0))
  expect_equal(x$qty_g_d, c(100, NA, NA, NA, 40, NA))
  log <- audit_log(x)
  expect_equal(log$qty_g[log$cause == "portion_conflict"], 100)
  expect_true(is.na(log$qty_g[log$cause == "consumed_no_yield"]))
})

test_that("optional controls are absent without their inputs", {
  comp <- ck_comp()
  comp$fortified <- NULL
  cw <- ck_crosswalk()
  cw$yield_factor <- NULL
  x <- check_crosswalk(cw, comp, ck_nutrients())
  expect_false(any(c("flag_fortified", "flag_review_type",
                     "flag_outside_range", "n_records") %in% names(x)))
  expect_identical(x$flag_consumed_no_yield,
                   c(FALSE, FALSE, TRUE, TRUE, FALSE, NA))
})

test_that("nothing is changed and row order does not matter", {
  x <- check_crosswalk(ck_crosswalk(), ck_comp(), ck_nutrients())
  expect_equal(x$composition_id, ck_crosswalk()$composition_id)
  p <- check_crosswalk(ck_crosswalk()[6:1, ], ck_comp()[4:1, ],
                       ck_nutrients())
  expect_identical(p$flag_portion_conflict, x$flag_portion_conflict[6:1])
  expect_identical(p$flag_consumed_no_yield, x$flag_consumed_no_yield[6:1])
})

test_that("arguments are checked with classed errors", {
  e <- "hcesfort_error_argument"
  cw <- ck_crosswalk()
  comp <- ck_comp()
  n <- ck_nutrients()
  expect_error(check_crosswalk(cw, comp, n, review_types = 1), class = e)
  expect_error(check_crosswalk(cw, comp, n, group = "nope"), class = e)
  expect_error(check_crosswalk(cw, comp, n, ranges = data.frame(min = 1)),
               class = e)
  expect_error(check_crosswalk(cw, comp, n, ranges = data.frame(
    column = "zinc_mg", min = 1, max = 2
  )), class = e)
  expect_error(check_crosswalk(cw, comp, n, ranges = data.frame(
    column = "iron_mg", min = 3, max = 2
  )), class = e)
  expect_error(check_crosswalk(cw, comp, n, grams = data.frame()),
               class = "hcesfort_error_audit")
  cw$composition_id[1] <- "C9"
  expect_error(check_crosswalk(cw, comp, n), class = "hcesfort_error_join")
})

test_that("a clean crosswalk has no flagged row in the log", {
  x <- check_crosswalk(ck_crosswalk()[1, ], ck_comp(), ck_nutrients())
  log <- audit_log(x)
  expect_false(any(log$step == "check_crosswalk" & log$kind == "flagged"))
})
