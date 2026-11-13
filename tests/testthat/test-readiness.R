# readiness_inventory() and readiness_checks() (U1, U2). Fixtures:
# hces_example (helper-linkage.R) and hand-built tables.

test_that("the inventory has one row per schema column, domain, table", {
  inv <- readiness_inventory(example_tables(),
                             domains = c("region", "expenditure_group"))
  n_cols <- sum(vapply(c("households", "members", "acquisitions"),
                       function(t) nrow(hces_schema(t)), integer(1)))
  expect_identical(nrow(inv), n_cols + 2L + 7L)
  expect_identical(names(inv), c("table", "variable", "role", "present",
                                 "share_missing", "needed_by"))
  tab <- inv[is.na(inv$variable), ]
  expect_identical(tab$table, c("unit_factors", "crosswalk", "composition",
                                "enrichment", "vehicles", "scenarios",
                                "food_groups"))
  expect_true(all(tab$present))
  expect_identical(tab$needed_by[tab$table == "vehicles"],
                   "coverage, quantity, scenarios")
  expect_identical(tab$needed_by[tab$table == "enrichment"], "none")
  essential <- inv$role == "essential"
  expect_true(all(inv$present[essential]))
  expect_true(all(inv$needed_by[essential] == "all"))
  # Absent optional columns of the example.
  absent <- inv$variable[!inv$present & !is.na(inv$variable)]
  expect_setequal(absent, c("age_months", "meals_home_share", "weight_kg",
                            "household_share"))
})

test_that("missing values are shared by hand", {
  inv <- readiness_inventory(example_tables())
  a <- hces_example$acquisitions
  row <- inv[inv$table == "acquisitions" & inv$variable %in% "quantity", ]
  expect_equal(row$share_missing, mean(is.na(a$quantity)))
  m <- inv[inv$table == "members" & inv$variable %in% "sex", ]
  expect_equal(m$share_missing, 1 / nrow(hces_example$members))
  expect_true(m$present)
})

test_that("removing one column or table changes that row only", {
  base <- readiness_inventory(example_tables(), domains = "region")
  t <- example_tables()
  t$households$region <- NULL
  inv <- readiness_inventory(t, domains = "region")
  changed <- which(base$present != inv$present)
  expect_identical(inv$variable[changed], "region")
  t <- example_tables()
  t$acquisitions$quantity <- NA_real_
  inv <- readiness_inventory(t)
  b <- readiness_inventory(example_tables())
  changed <- which(b$present != inv$present)
  expect_identical(inv$variable[changed], "quantity")
  expect_identical(inv$role[changed], "essential")
  t <- example_tables()
  t$crosswalk <- NULL
  t$food_groups <- t$food_groups[0, ]
  inv <- readiness_inventory(t)
  changed <- which(b$present != inv$present)
  expect_identical(inv$table[changed], c("crosswalk", "food_groups"))
})

test_that("the inventory runs on tables that fail their contract", {
  t <- list(households = data.frame(household_id = 1:2, weight = c(-1, NA)),
            acquisitions = data.frame(food = "x"))
  inv <- readiness_inventory(t)
  expect_false(any(inv$present[inv$table == "members"]))
  expect_true(inv$present[inv$variable %in% "weight"])
  expect_equal(inv$share_missing[inv$variable %in% "weight"], 0.5)
  expect_false(any(inv$present[is.na(inv$variable)]))
  expect_identical(nrow(readiness_inventory(list())), nrow(inv))
})

test_that("readiness_inventory() checks its arguments", {
  expect_error(readiness_inventory(), class = "hcesfort_error_argument")
  expect_error(readiness_inventory(list(foo = data.frame())),
               class = "hcesfort_error_argument")
  expect_error(readiness_inventory(list(households = 1)),
               class = "hcesfort_error_argument")
  expect_error(readiness_inventory(hces_example$households),
               class = "hcesfort_error_argument")
  expect_error(readiness_inventory(list(), domains = 1),
               class = "hcesfort_error_argument")
})

test_that("readiness_checks() gives every threshold with its value", {
  ch <- example_chain()
  out <- readiness_checks(ch$intake, ch$ladder, c("iron", "folate"),
                          min_records_used = 0.5, min_coverage = 0.5,
                          min_linked_share = 0.5)
  expect_identical(unique(out$check), c(
    "household_status", "records_without_quantity",
    "records_without_grams", "records_used", "composition_value",
    "linked_grams", "linked_expenditure"
  ))
  st <- out[out$check == "household_status", ]
  # Household 40 did not answer, 39 has no records; two households have a
  # member without age or sex, hence no AFE.
  expect_identical(st$n, as.integer(c(1, 1, 0, 2, 36)))
  expect_equal(st$value, st$n / 40)
  expect_true(all(is.na(st$met)))
  expect_identical(out$detail[out$check == "composition_value"],
                   c("iron", "folate"))
  l <- ch$ladder
  expect_identical(out$n[out$check == "records_without_grams"],
                   l$n_records[[1]] - l$n_records[[3]])
  expect_equal(out$value[out$check == "linked_grams"], l$share_grams[[5]])
  expect_equal(out$value[out$check == "linked_expenditure"],
               l$share_expenditure[[5]])
  gated <- out[!is.na(out$threshold), ]
  expect_true(all(gated$met))
  expect_equal(unique(gated$threshold), 0.5)
})

test_that("met is FALSE exactly when inadequacy() fails for that measure", {
  ch <- example_chain(biscuit = TRUE)
  req <- data.frame(nutrient = c("folate", "vitamin_a"),
                    unit = c("ug_dfe", "ug_rae"), ear = c(320, 500),
                    cutpoint_valid = TRUE)
  base <- readiness_checks(ch$intake, ch$ladder, c("folate", "vitamin_a"),
                           0, 0, 0)
  used <- base$value[base$check == "records_used"]
  cov <- base$value[base$check == "composition_value"]
  expect_lt(cov[[1]], 1)
  fails <- function(min_used, min_cov) {
    tryCatch({
      inadequacy(ch$intake, req, min_coverage = min_cov,
                 min_records_used = min_used)
      "none"
    }, hcesfort_error_coverage = function(e) e$measure)
  }
  for (u in c(used - 1e-6, used, used + 1e-6)) {
    out <- readiness_checks(ch$intake, ch$ladder, c("folate", "vitamin_a"),
                            u, 0, 0)
    met <- out$met[out$check == "records_used"]
    expect_identical(fails(u, 0) == "records_used", !met)
  }
  for (k in c(min(cov) - 1e-6, min(cov) + 1e-6, min(max(cov) + 1e-6, 1))) {
    out <- readiness_checks(ch$intake, ch$ladder, c("folate", "vitamin_a"),
                            0, k, 0)
    met <- out$met[out$check == "composition_value"]
    expect_identical(fails(0, k) == "composition_value", any(!met))
  }
})

test_that("without expenditure, linked_expenditure has no verdict", {
  e <- hces_example
  a <- e$acquisitions
  a$expenditure_lcu <- NULL
  g <- convert_units(a, e$unit_factors, priority = "food")
  x <- link_composition(g, e$crosswalk, e$composition,
                        nutrient_registry(e$nutrients))
  ch <- example_chain()
  out <- readiness_checks(ch$intake, linkage_ladder(x, e$households),
                          "iron", 0.5, 0.5, 0.99)
  row <- out[out$check == "linked_expenditure", ]
  expect_true(is.na(row$value) && is.na(row$met))
  expect_false(out$met[out$check == "linked_grams"])
})

test_that("readiness_checks() checks its arguments", {
  ch <- example_chain()
  expect_error(readiness_checks(ch$intake, ch$ladder, "iron", 0.5, 0.5),
               class = "hcesfort_error_argument")
  expect_error(readiness_checks(ch$intake, ch$ladder, "zinc", 0.5, 0.5, 0.5),
               class = "hcesfort_error_argument")
  expect_error(readiness_checks(ch$intake, ch$ladder, "iron", 2, 0.5, 0.5),
               class = "hcesfort_error_argument")
  expect_error(readiness_checks(ch$intake, ch$ladder[, 1:2], "iron", 0.5,
                                0.5, 0.5),
               class = "hcesfort_error_schema")
  expect_error(readiness_checks(ch$content, ch$ladder, "iron", 0.5, 0.5,
                                0.5),
               class = "hcesfort_error_audit")
})

# readiness_verdict() (U7). Fixture verdict_fixture() in helper-linkage.R.

test_that("every section is enabled on the example", {
  f <- verdict_fixture()
  v <- readiness_verdict(f$inventory, f$checks, domains = "region")
  expect_identical(names(v), c("section", "domain", "enabled", "reason",
                               "detail"))
  expect_identical(v$section, rep(c("coverage", "quantity", "risk",
                                    "scenarios", "food_groups"), 2))
  expect_identical(v$domain, rep(c(NA, "region"), each = 5))
  expect_true(all(v$enabled))
  expect_true(all(is.na(v$reason) & is.na(v$detail)))
})

test_that("an absent domain disables only its rows", {
  t <- example_tables()
  t$households$region <- NULL
  domains <- c("region", "expenditure_group")
  f <- verdict_fixture(t, domains = domains)
  v <- readiness_verdict(f$inventory, f$checks, domains = domains)
  off <- !v$enabled
  expect_identical(unique(v$domain[off]), "region")
  expect_identical(sum(off), 5L)
  expect_true(all(v$reason[off] == "missing_input" & v$detail[off] ==
                    "region"))
})

test_that("an absent optional table disables exactly its sections", {
  expected <- list(food_groups = "food_groups",
                   vehicles = c("coverage", "quantity", "scenarios"),
                   scenarios = "scenarios")
  for (tab in names(expected)) {
    t <- example_tables()
    t[[tab]] <- NULL
    f <- verdict_fixture(t)
    v <- readiness_verdict(f$inventory, f$checks)
    expect_identical(v$section[!v$enabled], expected[[tab]], info = tab)
    expect_true(all(v$reason[!v$enabled] == "missing_input"))
    expect_true(all(grepl(tab, v$detail[!v$enabled], fixed = TRUE)))
  }
})

test_that("a threshold not met disables the gated sections", {
  f <- verdict_fixture(min_used = 0.95)
  v <- readiness_verdict(f$inventory, f$checks, domains = "region")
  off <- v[!v$enabled, ]
  expect_identical(off$section, rep(c("risk", "scenarios", "food_groups"),
                                    2))
  expect_true(all(off$reason == "threshold_not_met"))
  expect_true(all(off$detail == "records_used"))
  # composition_value disables only when no nutrient meets it.
  ch <- f$checks
  ch$met[ch$check == "composition_value"] <- c(FALSE, TRUE)
  expect_true(all(readiness_verdict(f$inventory, ch)$enabled[c(1, 2)]))
  expect_true(all(readiness_verdict(f$inventory, ch)$section[
    !readiness_verdict(f$inventory, ch)$enabled
  ] %in% c("risk", "scenarios", "food_groups")))
  ch$met[ch$check == "records_used"] <- TRUE
  expect_true(all(readiness_verdict(f$inventory, ch)$enabled))
  ch$met[ch$check == "composition_value"] <- FALSE
  ch$met[ch$check == "linked_expenditure"] <- NA
  v <- readiness_verdict(f$inventory, ch)
  expect_identical(unique(v$detail[!v$enabled]), "composition_value")
})

test_that("an absent essential input disables everything", {
  t <- example_tables()
  t$crosswalk <- NULL
  t$acquisitions$unit <- NULL
  inv <- readiness_inventory(t, domains = "region")
  v <- readiness_verdict(inv, NULL, domains = "region")
  expect_false(any(v$enabled))
  expect_true(all(v$reason == "missing_input"))
  expect_true(all(v$detail == "unit, crosswalk"))
})

test_that("readiness_verdict() checks its arguments", {
  f <- verdict_fixture()
  expect_error(readiness_verdict(f$inventory), class =
                 "hcesfort_error_argument")
  expect_error(readiness_verdict(f$inventory, NULL),
               class = "hcesfort_error_argument")
  expect_error(readiness_verdict(f$inventory[, 1:2], f$checks),
               class = "hcesfort_error_schema")
  expect_error(readiness_verdict(f$inventory, f$checks[, 1:2]),
               class = "hcesfort_error_schema")
  expect_error(readiness_verdict(f$inventory, f$checks, domains = 1),
               class = "hcesfort_error_argument")
})
