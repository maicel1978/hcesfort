# A carrier whose key is repeated (finding 1 of the review v0.2, P155) is
# refused by every function that takes it, and the estimators log a change
# in the number of rows made outside the package (`audit_check_rows()`).
# Fixtures: `as_pipeline()` (helper-scenario.R, three invented households)
# and `es_result()` (helper-estimate.R, eight invented households).

# `x` with its first `n` rows appended again, keeping class and attributes,
# as a `bind_rows()` or a fanning `left_join()` between two calls would.
repeat_rows <- function(x, n = 1) {
  out <- x[c(seq_len(nrow(x)), seq_len(n)), ]
  attributes(out)[carrier_attrs] <- attributes(x)[carrier_attrs]
  out
}

test_that("require_hces() refuses a carrier with a repeated key", {
  x <- repeat_rows(fixture_carrier(), 2)
  f <- function(tab) require_hces(tab, "hces_acquisitions")
  err <- expect_error(f(x), class = "hcesfort_error_key")
  expect_identical(err$table, "tab")
  expect_identical(err$columns, "record_id")
  expect_identical(err$rows, 4:5)
  expect_identical(err$n, 2L)
  expect_identical(rlang::call_name(err$call), "f")
  expect_match(conditionMessage(err), "repeated key: 2 rows (4, 5)",
               fixed = TRUE)
})

test_that("require_hces() checks the key columns together", {
  # Same household twice, in two scenarios: not a repeated key.
  x <- es_result()
  expect_identical(require_hces(x, "hces_inadequacy"), x)
  y <- repeat_rows(x)
  err <- expect_error(require_hces(y, "hces_inadequacy"),
                      class = "hcesfort_error_key")
  expect_identical(err$columns, c("scenario", "household_id"))
  expect_identical(err$rows, 17L)
})

test_that("require_hces() refuses a carrier without its key columns", {
  x <- fixture_carrier()
  x$record_id <- NULL
  err <- expect_error(require_hces(x, "hces_acquisitions"),
                      class = "hcesfort_error_key")
  expect_identical(err$columns, "record_id")
})

test_that("the functions of the chain refuse a repeated key", {
  # The key is checked on entry, before any other argument.
  p <- as_pipeline()
  s <- repeat_rows(as_run())
  bad <- function(expr) expect_error(expr, class = "hcesfort_error_key")
  bad(apply_scenario(repeat_rows(p$intake), p$use, as_scenarios()))
  bad(apply_scenario(p$intake, repeat_rows(p$use), as_scenarios()))
  bad(inadequacy(s, NULL, min_coverage = 0, min_records_used = 0))
  bad(above_ul(s, NULL, min_coverage = 0, min_records_used = 0))
  bad(nutrient_density(s, "energy"))
  bad(flag_energy_plausibility(s, "energy", 1000, 4000))
})

test_that("apparent_intake() refuses adult equivalents with a repeated key", {
  a <- data.frame(record_id = 1:2, household_id = 1:2, food_code = "flour",
                  quantity = 100, unit = "g", section = "diary",
                  period_days = 1, include = TRUE)
  f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                  source = "test fixture")
  cw <- data.frame(food_code = "flour", composition_id = "C1",
                   match_type = "exact", validated = TRUE, edible_portion = 1)
  comp <- data.frame(composition_id = "C1", iron_mg = 1,
                     basis = "per_100g_edible", food_state = "raw",
                     source = "test fixture")
  content <- link_composition(convert_units(a, f, priority = "food"), cw,
                              comp, nutrient_registry(c(iron = "mg")))
  afe <- new_hces_tbl(data.frame(household_id = 1:2, n_members = 1,
                                 afe = 1), "hces_afe", key = "household_id")
  h <- data.frame(household_id = 1:2, weight = 1, stratum = 1, psu = 1:2)
  expect_s3_class(apparent_intake(content, afe, h), "hces_intake")
  expect_error(apparent_intake(content, repeat_rows(afe), h),
               class = "hcesfort_error_key")
})

test_that("the estimators refuse a repeated household", {
  d <- es_design()
  x <- repeat_rows(es_result(), 3)
  x$intake[17:19] <- 1e6
  expect_error(estimate_households(d, x, "intake", statistic = "mean"),
               class = "hcesfort_error_key")
  expect_error(estimate_difference(d, x, "intake", reference = "base"),
               class = "hcesfort_error_key")
  expect_error(estimate_households(d, es_result(), "ok",
                                   domain = "ok", domain_from = x),
               class = "hcesfort_error_key")
})

test_that("the estimators log rows removed outside the package", {
  d <- es_design()
  x <- es_result()
  x <- x[x$household_id != 8, ]
  attributes(x)[carrier_attrs] <- attributes(es_result())[carrier_attrs]
  for (f in c("estimate_households", "estimate_difference")) {
    e <- if (f == "estimate_households") {
      estimate_households(d, x, "intake", statistic = "mean")
    } else {
      estimate_difference(d, x, "intake", reference = "base")
    }
    log <- audit_log(e)
    row <- log[log$kind == "external_change", ]
    expect_identical(row$step, f)
    expect_identical(row$n_records, 2L)
    expect_identical(row$detail, "removed")
  }
})

test_that("an estimate is unchanged when no row changed", {
  d <- es_design()
  e <- estimate_households(d, es_result(), "intake", statistic = "mean")
  expect_false("external_change" %in% audit_log(e)$kind)
})
