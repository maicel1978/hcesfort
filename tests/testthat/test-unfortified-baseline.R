# Fixture: the hand example of docs/design-task9.md, section 3 (invented
# values, iron in mg and folate in ug DFE per 100 g). Bread B1 is made
# with 0.6 g of flour per g; bread B2 is recorded with too little iron for
# that rule; R1 is enriched rice, its own reference against plain rice R0;
# P1 is a pasta whose folate is given by an amount added.
baseline_comp <- function() {
  data.frame(
    composition_id = c("B1", "B2", "FE", "FU", "R1", "R0", "P1", "X1"),
    iron_mg = c(3.0, 1.5, 4.4, 1.2, 2.9, 0.8, 2.0, 5),
    folate_ug_dfe = c(40, NA, 280, 26, 150, 8, 300, 10),
    basis = "per_100g_edible", food_state = "raw", source = "invented",
    fortified = c(FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE)
  )
}

baseline_rules <- function() {
  data.frame(
    composition_id = c("B1", "B2", "B2", "FE", "R1", "P1"),
    nutrient = c("iron", "iron", "folate", "iron", "iron", "folate"),
    enriched_ref_id = c("FE", "FE", "FE", "FE", "R1", NA),
    unenriched_ref_id = c("FU", "FU", "FU", "FU", "R0", NA),
    ingredient_fraction = c(0.6, 0.6, 0.6, 1, 1, NA),
    added = c(NA, NA, NA, NA, NA, 120), source = "invented"
  )
}

run_baseline <- function(comp = baseline_comp(), rules = baseline_rules(),
                         ...) {
  nutrients <- nutrient_registry(c(iron = "mg", folate = "ug_dfe"))
  unfortified_baseline(comp, rules, nutrients, ...)
}

test_that("subtract: the hand example of the design", {
  out <- run_baseline()
  expect_s3_class(out, "hces_composition")
  # B1: 3.0 - 0.6 x (4.4 - 1.2) = 1.08. B2: 1.5 - 1.92 < 0.72 -> 0.72.
  # FE: 4.4 - 3.2 = 1.2. R1: own reference, U = 0.8. P1: 300 - 120 = 180.
  expect_equal(out$iron_mg, c(1.08, 0.72, 1.2, 1.2, 0.8, 0.8, 2.0, 5))
  expect_equal(out$folate_ug_dfe, c(40, NA, 280, 26, 150, 8, 180, 10))
  expect_identical(out$baseline_status, c(
    "enrichment_removed", "enrichment_removed", "enrichment_removed",
    "unchanged", "enrichment_removed", "unchanged", "enrichment_removed",
    "fortified_no_rule"
  ))
})

test_that("replace_by_ingredient: the rule of the original", {
  rules <- baseline_rules()[1:5, ]
  out <- run_baseline(rules = rules, method = "replace_by_ingredient")
  # B1 and B2: 0.6 x 1.2 = 0.72; FE 1.2; R1 0.8.
  expect_equal(out$iron_mg, c(0.72, 0.72, 1.2, 1.2, 0.8, 0.8, 2.0, 5))
  log <- audit_log(out)
  expect_identical(log$n_records[log$cause == "method_replace_by_ingredient"],
                   5L)
})

test_that("the audit log counts each cause by hand", {
  log <- audit_log(run_baseline())
  log <- log[log$step == "unfortified_baseline", ]
  expect_identical(log$cause, c(
    "all", "enrichment_removed", "enrichment_removed", "rule_not_needed",
    "floored", "fortified_no_rule"
  ))
  expect_identical(log$n_records, c(8L, 1L, 4L, 1L, 1L, 1L))
  expect_identical(log$detail, c(NA, "folate_ug_dfe", "iron_mg",
                                 "folate_ug_dfe", "iron_mg", NA))
  expect_true("validate_enrichment" %in% audit_log(run_baseline())$step)
})

test_that("an empty enrichment table leaves the table unchanged", {
  out <- run_baseline(rules = baseline_rules()[0, ])
  expect_identical(out$iron_mg, baseline_comp()$iron_mg)
  log <- audit_log(out)
  expect_true("no_enrichment_rules" %in% log$cause)
})

test_that("a difference not positive removes nothing and is noted", {
  comp <- baseline_comp()
  comp$iron_mg[comp$composition_id == "FE"] <- 1.0
  out <- run_baseline(comp = comp, rules = baseline_rules()[1, ])
  expect_identical(out$iron_mg[[1]], 3.0)
  log <- audit_log(out)
  expect_identical(log$n_records[log$cause == "difference_not_positive"], 1L)
})

test_that("a value below the floor is kept, never increased", {
  comp <- baseline_comp()
  comp$iron_mg[[2]] <- 0.5
  out <- run_baseline(comp = comp)
  expect_identical(out$iron_mg[[2]], 0.5)
})

test_that("a zero-row composition with no rules passes", {
  out <- run_baseline(comp = baseline_comp()[0, ],
                      rules = baseline_rules()[0, ])
  expect_identical(nrow(out), 0L)
  expect_identical(out$baseline_status, character(0))
})

test_that("a form without its own rule is flagged", {
  nutrients <- nutrient_registry(c(folate = "ug_dfe", folic_acid = "ug"))
  comp <- data.frame(
    composition_id = c("A", "B"), folate_ug_dfe = c(300, 100),
    folic_acid_ug = c(100, 0), basis = "per_100g_edible",
    food_state = "raw", source = "invented"
  )
  rules <- data.frame(composition_id = "A", nutrient = "folate",
                      added = 170, source = "invented")
  out <- unfortified_baseline(comp, rules, nutrients)
  log <- audit_log(out)
  row <- log$cause == "form_without_rule"
  expect_identical(log$n_records[row], 1L)
  expect_identical(log$detail[row], "folic_acid_ug")
  rules <- rbind(rules, data.frame(composition_id = "A",
                                   nutrient = "folic_acid", added = 100,
                                   source = "invented"))
  out <- unfortified_baseline(comp, rules, nutrients)
  expect_false("form_without_rule" %in% audit_log(out)$cause)
  expect_identical(out$folic_acid_ug, c(0, 0))
})

test_that("ids absent from the composition are join errors", {
  rules <- baseline_rules()
  rules$unenriched_ref_id[[1]] <- "ZZ"
  err <- expect_error(run_baseline(rules = rules),
                      class = "hcesfort_error_join")
  expect_identical(err$columns, "unenriched_ref_id")
  rules <- baseline_rules()
  rules$composition_id[[6]] <- "ZZ"
  expect_error(run_baseline(rules = rules), class = "hcesfort_error_join")
  comp <- baseline_comp()
  comp$composition_id <- seq_len(nrow(comp))
  expect_error(run_baseline(comp = comp), class = "hcesfort_error_join")
})

test_that("rules that cannot be applied are value errors", {
  comp <- baseline_comp()
  comp$iron_mg[comp$composition_id == "FU"] <- NA
  err <- expect_error(run_baseline(comp = comp),
                      class = "hcesfort_error_value")
  expect_identical(err$rows, c(1L, 2L, 4L))
  expect_error(run_baseline(method = "replace_by_ingredient"),
               class = "hcesfort_error_value")
  rules <- baseline_rules()
  rules$nutrient[[1]] <- "zinc"
  expect_error(run_baseline(rules = rules), class = "hcesfort_error_value")
  rules <- baseline_rules()
  rules$added[[1]] <- 1
  expect_error(run_baseline(rules = rules), class = "hcesfort_error_value")
})

test_that("bad arguments and duplicated keys are classed errors", {
  rules <- rbind(baseline_rules(), baseline_rules()[1, ])
  expect_error(run_baseline(rules = rules), class = "hcesfort_error_key")
  expect_error(run_baseline(method = "zero"),
               class = "hcesfort_error_argument")
  expect_error(run_baseline(conversions = data.frame(a = 1)),
               class = "hcesfort_error_schema")
  out <- run_baseline()
  expect_error(unfortified_baseline(out, baseline_rules()),
               class = "hcesfort_error_argument")
})

test_that("invariants: no cell increases, other cells identical", {
  comp <- baseline_comp()
  out <- run_baseline()
  for (col in c("iron_mg", "folate_ug_dfe")) {
    ok <- !is.na(comp[[col]])
    expect_true(all(out[[col]][ok] <= comp[[col]][ok]))
    expect_identical(is.na(out[[col]]), is.na(comp[[col]]))
  }
  untouched <- !comp$composition_id %in% baseline_rules()$composition_id
  expect_identical(out$iron_mg[untouched], comp$iron_mg[untouched])
})

test_that("invariant: subtract is never below replace_by_ingredient", {
  rules <- baseline_rules()[1:5, ]
  sub <- run_baseline(rules = rules)
  rep <- run_baseline(rules = rules, method = "replace_by_ingredient")
  expect_true(all(sub$iron_mg >= rep$iron_mg - 1e-12))
})

test_that("invariant: results do not depend on row order", {
  out <- run_baseline()
  comp <- baseline_comp()[8:1, ]
  rules <- baseline_rules()[6:1, ]
  rev_out <- run_baseline(comp = comp, rules = rules)
  rev_out <- rev_out[match(out$composition_id, rev_out$composition_id), ]
  expect_equal(rev_out$iron_mg, out$iron_mg)
  expect_equal(rev_out$folate_ug_dfe, out$folate_ug_dfe)
})

test_that("the example data run end to end", {
  nutrients <- nutrient_registry(hces_example$nutrients)
  out <- unfortified_baseline(hces_example$composition,
                              hces_example$enrichment, nutrients)
  # Pasta C04: iron 3.3 - (3 - 1.2) = 1.5; folate 400 - (290 - 26) = 136.
  expect_equal(out$iron_mg[out$composition_id == "C04"], 1.5)
  expect_equal(out$folate_ug_dfe[out$composition_id == "C04"], 136)
  expect_equal(out$iron_mg[out$composition_id == "C13"], 1.2)
})
