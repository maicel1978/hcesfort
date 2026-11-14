# readiness_inventory() and readiness_checks() (U1, U2). Fixtures:
# hces_fixture() (helper-linkage.R) and hand-built tables.

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
  expect_identical(tab$needed_by[tab$table == "enrichment"], "baseline")
  essential <- inv$role == "essential"
  expect_true(all(inv$present[essential]))
  expect_true(all(inv$needed_by[essential] == "all"))
  # Absent optional columns of the example.
  absent <- inv$variable[!inv$present & !is.na(inv$variable)]
  expect_setequal(absent, c("age_months", "meals_home_share", "weight_kg",
                            "household_share"))
})

# U16 (docs/design-reports-v3.md, section 4.2, C4): every row of the map,
# typed by hand.
test_that("needed_by follows the dependency map row by row", {
  inv <- readiness_inventory(example_tables(), domains = "region")
  got <- stats::setNames(inv$needed_by,
                         ifelse(is.na(inv$variable), inv$table,
                                inv$variable))
  expected <- c(
    food_module_response = "household_status",
    age_months = "adult_equivalents", pregnant = "adult_equivalents",
    lactating = "adult_equivalents", meals_home_share = "adult_equivalents",
    weight_kg = "adult_equivalents", household_share = "quantities",
    expenditure_lcu = "linkage_expenditure", origin = "none",
    region = "domain", enrichment = "baseline",
    vehicles = "coverage, quantity, scenarios", scenarios = "scenarios",
    food_groups = "food_groups", unit_factors = "all", crosswalk = "all",
    composition = "all", household_id = "all", weight = "all",
    stratum = "all", psu = "all", member_id = "all", age_years = "all",
    sex = "all", record_id = "all", food_code = "all", quantity = "all",
    unit = "all", section = "all", period_days = "all", include = "all"
  )
  expect_identical(got[names(expected)], expected)
  # Every row is in the map: no optional input falls through to "none".
  expect_setequal(names(got), names(expected))
})

test_that("missing values are shared by hand", {
  inv <- readiness_inventory(example_tables())
  a <- hces_fixture()$acquisitions
  row <- inv[inv$table == "acquisitions" & inv$variable %in% "quantity", ]
  expect_equal(row$share_missing, mean(is.na(a$quantity)))
  m <- inv[inv$table == "members" & inv$variable %in% "sex", ]
  expect_equal(m$share_missing, 1 / nrow(hces_fixture()$members))
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
  expect_error(readiness_inventory(hces_fixture()$households),
               class = "hcesfort_error_argument")
  expect_error(readiness_inventory(list(), domains = 1),
               class = "hcesfort_error_argument")
})

test_that("readiness_checks() gives every threshold with its value", {
  ch <- example_chain()
  out <- rc(ch$intake, ch$ladder, c("iron", "folate"),
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
  base <- rc(ch$intake, ch$ladder, c("folate", "vitamin_a"),
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
    out <- rc(ch$intake, ch$ladder, c("folate", "vitamin_a"),
              u, 0, 0)
    met <- out$met[out$check == "records_used"]
    expect_identical(fails(u, 0) == "records_used", !met)
  }
  for (k in c(min(cov) - 1e-6, min(cov) + 1e-6, min(max(cov) + 1e-6, 1))) {
    out <- rc(ch$intake, ch$ladder, c("folate", "vitamin_a"),
              0, k, 0)
    met <- out$met[out$check == "composition_value"]
    expect_identical(fails(0, k) == "composition_value", any(!met))
  }
})

test_that("without expenditure, linked_expenditure has no verdict", {
  e <- hces_fixture()
  a <- e$acquisitions
  a$expenditure_lcu <- NULL
  g <- convert_units(a, e$unit_factors, priority = "food")
  x <- link_composition(g, e$crosswalk, e$composition,
                        nutrient_registry(e$nutrients))
  ch <- example_chain()
  out <- rc(ch$intake, linkage_ladder(x, e$households),
            "iron", 0.5, 0.5, 0.99)
  row <- out[out$check == "linked_expenditure", ]
  expect_true(is.na(row$value) && is.na(row$met))
  expect_false(out$met[out$check == "linked_grams"])
})

test_that("readiness_checks() checks its arguments", {
  ch <- example_chain()
  expect_error(rc(ch$intake, ch$ladder, "iron", 0.5, 0.5),
               class = "hcesfort_error_argument")
  expect_error(rc(ch$intake, ch$ladder, "zinc", 0.5, 0.5, 0.5),
               class = "hcesfort_error_argument")
  expect_error(rc(ch$intake, ch$ladder, "iron", 2, 0.5, 0.5),
               class = "hcesfort_error_argument")
  expect_error(rc(ch$intake, ch$ladder[, 1:2], "iron", 0.5,
                  0.5, 0.5),
               class = "hcesfort_error_schema")
  expect_error(rc(ch$content, ch$ladder, "iron", 0.5, 0.5,
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

# U15 (docs/design-reports-v3.md, section 4.3, C5): domains with small
# cells. Fixture small_cell_fixture() in helper-linkage.R.

test_that("domain_cells counts values below min_n by hand", {
  f <- small_cell_fixture()
  out <- readiness_checks(f$ch$intake, f$ch$ladder, "iron", 0, 0, 0,
                          households = f$h, domains = c("region", "size"),
                          min_n = 18, max_small_cells = 0.5)
  cells <- out[out$check == "domain_cells", ]
  expect_identical(cells$detail, c("region", "size"))
  expect_identical(cells$n, c(2L, 3L))
  # region: 18 and 18, none below 18. size: 30, 6, 0; two of three below.
  expect_equal(cells$value, c(0, 2 / 3), tolerance = 1e-12)
  expect_identical(cells$threshold, c(0.5, 0.5))
  expect_identical(cells$met, c(TRUE, FALSE))
  # Boundary: min_n 19 puts both regions below; met only at a threshold
  # of 1. The share equal to the threshold is met.
  out <- readiness_checks(f$ch$intake, f$ch$ladder, "iron", 0, 0, 0,
                          households = f$h, domains = "region",
                          min_n = 19, max_small_cells = 1)
  expect_identical(out$value[out$check == "domain_cells"], 1)
  expect_true(out$met[out$check == "domain_cells"])
  same <- readiness_checks(f$ch$intake, f$ch$ladder, "iron", 0, 0, 0,
                           households = f$h, domains = "size",
                           min_n = 18, max_small_cells = 2 / 3)
  expect_true(same$met[same$check == "domain_cells"])
})

test_that("domain_cells: row order, missing values, absent column", {
  f <- small_cell_fixture()
  run <- function(h, domains = "size") {
    out <- readiness_checks(f$ch$intake, f$ch$ladder, "iron", 0, 0, 0,
                            households = h, domains = domains, min_n = 18,
                            max_small_cells = 0.5)
    out[out$check == "domain_cells", ]
  }
  base <- run(f$h)
  expect_identical(run(f$h[rev(seq_len(nrow(f$h))), ]), base)
  # A missing value is one more value (a cell of estimate_households()).
  h <- f$h
  h$size[h$size == "empty"] <- NA
  expect_identical(run(h), base)
  h$size[h$size == "small"] <- NA
  expect_identical(run(h)$n, 2L)
  expect_identical(run(h)$value, 0.5)
  absent <- run(f$h, "district")
  expect_true(is.na(absent$value) && is.na(absent$met) && is.na(absent$n))
  out <- readiness_checks(f$ch$intake, f$ch$ladder, "iron", 0, 0, 0,
                          households = f$h, domains = NULL, min_n = 18,
                          max_small_cells = 0.5)
  expect_false("domain_cells" %in% out$check)
})

test_that("domain_cells checks its arguments", {
  f <- small_cell_fixture()
  call <- function(...) {
    args <- list(
      intake = f$ch$intake, ladder = f$ch$ladder, nutrients = "iron",
      min_records_used = 0, min_coverage = 0, min_linked_share = 0,
      households = f$h, domains = "size", min_n = 18, max_small_cells = 0.5
    )
    new <- list(...)
    args[names(new)] <- new
    do.call(readiness_checks, args)
  }
  for (bad in list(0, 2.5, NA, c(1, 2), "30")) {
    expect_error(call(min_n = bad), class = "hcesfort_error_argument")
  }
  for (bad in list(-0.1, 1.1, NA_real_, "0.5", c(0, 1))) {
    expect_error(call(max_small_cells = bad),
                 class = "hcesfort_error_argument")
  }
  expect_error(call(domains = c("size", NA)),
               class = "hcesfort_error_argument")
  expect_error(call(households = f$h[-1, ]), class = "hcesfort_error_join")
  expect_error(call(households = rbind(f$h, f$h[1, ])),
               class = "hcesfort_error_join")
  expect_error(call(households = f$h["size"]),
               class = "hcesfort_error_schema")
  expect_error(readiness_checks(f$ch$intake, f$ch$ladder, "iron", 0, 0, 0,
                                domains = NULL, min_n = 18,
                                max_small_cells = 0.5),
               class = "hcesfort_error_argument")
  expect_error(readiness_checks(f$ch$intake, f$ch$ladder, "iron", 0, 0, 0,
                                households = f$h, domains = NULL,
                                max_small_cells = 0.5),
               class = "hcesfort_error_argument")
})

test_that("a domain with too many small cells is disabled, and only it", {
  f <- small_cell_fixture()
  inv <- readiness_inventory(example_tables(), domains = "region")
  inv <- dplyr::bind_rows(inv, dplyr::tibble(
    table = "households", variable = "size", role = "optional",
    present = TRUE, share_missing = 0, needed_by = "domain"
  ))
  checks <- readiness_checks(f$ch$intake, f$ch$ladder, c("iron", "folate"),
                             0.8, 0.9, 0.9, households = f$h,
                             domains = c("region", "size"), min_n = 18,
                             max_small_cells = 0.5)
  v <- readiness_verdict(inv, checks, domains = c("region", "size"))
  national <- v[is.na(v$domain), ]
  region <- v[v$domain %in% "region", ]
  size <- v[v$domain %in% "size", ]
  expect_identical(region$enabled, national$enabled)
  expect_identical(region$reason, national$reason)
  expect_false(any(size$enabled))
  on <- national$enabled
  expect_identical(size$reason[on], rep("threshold_not_met", sum(on)))
  expect_identical(size$detail[on], rep("domain_cells", sum(on)))
  # Rows disabled for a missing input keep their reason and detail.
  expect_identical(size$reason[!on], national$reason[!on])
  expect_identical(size$detail[!on], national$detail[!on])
  # A domain that meets the check keeps the national verdict.
  ok <- checks
  ok$met[ok$check == "domain_cells"] <- TRUE
  v2 <- readiness_verdict(inv, ok, domains = "size")
  expect_identical(v2$enabled[v2$domain %in% "size"], national$enabled)
})
