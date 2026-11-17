# apply_scenario(compliance_model = "all_or_nothing"): the table of states
# (docs/design-12e5.md, section 4). Fixture in helper-scenario.R: vehicle
# grams per AFE h1 flour 100, sugar 20; h2 flour 50, sugar 0; h3 has no
# records (not estimated). Helpers two_vehicles(), aon() and state_val()
# in helper-scenario.R.

test_that("two vehicles at 0.5 and 0.8: four states by hand", {
  s <- aon(two_vehicles())
  expect_s3_class(s, "hces_scenario_states")
  expect_false(inherits(s, "hces_scenario_intake"))
  expect_identical(attr(s, "audit_key"),
                   c("scenario", "state", "household_id"))
  b <- s[s$scenario == "both" & s$household_id == 1, ]
  expect_identical(b$state, c("none", "flour", "sugar", "flour+sugar"))
  # none 0.5 x 0.2, flour 0.5 x 0.2, sugar 0.5 x 0.8, both 0.5 x 0.8.
  expect_equal(b$state_probability, c(0.1, 0.1, 0.4, 0.4))
  # Full levels: flour 5.5 mg per 100 g, sugar 10 mg per 100 g.
  expect_equal(b$iron_mg_added, c(0, 5.5, 2, 7.5))
  expect_equal(b$iron_mg, 1 + c(0, 5.5, 2, 7.5))
  expect_equal(state_val(s, "flour+sugar", 2, "iron_mg_added"), 2.75)
  expect_true(all(is.na(s$iron_mg_added[s$household_id == 3 &
                                          s$scenario == "both"])))
})

test_that("one vehicle at 0.5: the full dose or nothing", {
  sc <- as_scenarios()
  sc$compliance <- c(0.5, 0.5, 1)
  s <- aon(sc)
  s1 <- s[s$scenario == "s1" & s$household_id == 1, ]
  expect_identical(s1$state, c("none", "flour"))
  expect_equal(s1$state_probability, c(0.5, 0.5))
  expect_equal(s1$folate_ug_dfe_added, c(0, 306))
  expect_equal(s1$folic_acid_ug_added, c(0, 180))
  # Compliance 1: one state, always on.
  s2 <- s[s$scenario == "s2" & s$household_id == 1, ]
  expect_identical(s2$state, "sugar")
  expect_equal(s2$state_probability, 1)
  expect_equal(s2$vitamin_a_ug_rae_added, 100)
})

test_that("rows: households times the sum of 2^k; probabilities sum to 1", {
  sc <- rbind(two_vehicles(),
              transform(two_vehicles(c(1, 0.3)), scenario = "one"),
              transform(two_vehicles(c(0, 1)), scenario = "none_partial"))
  s <- aon(sc)
  expect_identical(nrow(s), 3L * (1L + 4L + 2L + 1L))
  total <- tapply(s$state_probability,
                  paste(s$scenario, s$household_id), sum)
  expect_equal(as.vector(total), rep(1, 12), tolerance = 1e-12)
  # Compliance 0: always off.
  expect_identical(unique(s$state[s$scenario == "none_partial"]), "sugar")
  expect_identical(unique(s$state[s$scenario == "one"]),
                   c("flour", "flour+sugar"))
})

test_that("the expected added amount equals that of average content", {
  sc <- dplyr::bind_rows(two_vehicles(),
                         transform(as_scenarios(), compliance = 0.3))
  s <- aon(sc)
  a <- as_run(sc, compliance_model = "average_content")
  for (col in c("iron_mg_added", "folate_ug_dfe_added",
                "folic_acid_ug_added", "vitamin_a_ug_rae_added")) {
    ok <- !is.na(s[[col]])
    e <- tapply(s$state_probability[ok] * s[[col]][ok],
                paste(s$scenario, s$household_id)[ok], sum)
    key <- paste(a$scenario, a$household_id)
    expect_equal(as.vector(e), a[[col]][match(names(e), key)],
                 tolerance = 1e-12)
  }
})

test_that("compliance 1 everywhere: the states are average content", {
  s <- aon(as_scenarios())
  a <- as_run()
  expect_identical(nrow(s), nrow(a))
  expect_true(all(s$state_probability == 1))
  expect_identical(s$state, rep(c("none", "flour", "sugar"), each = 3))
  keep <- setdiff(names(s), c("state", "state_probability"))
  expect_equal(as.data.frame(s)[keep], as.data.frame(a), ignore_attr = TRUE)
})

test_that("a compliance that differs within a vehicle is a value error", {
  sc <- as_scenarios()
  sc$compliance <- c(0.5, 0.8, 1)
  expect_error(aon(sc), class = "hcesfort_error_value")
  expect_snapshot(aon(sc), error = TRUE)
  # The same vehicle in two scenarios may differ.
  sc2 <- rbind(two_vehicles(), transform(two_vehicles(c(0.2, 0.8)),
                                         scenario = "other"))
  expect_no_error(aon(sc2))
})

test_that("the log: model, states, independence, households once", {
  s <- aon(rbind(two_vehicles(),
                 transform(two_vehicles(c(1, 0.3)), scenario = "one")))
  log <- audit_log(s)
  log <- log[log$step == "apply_scenario" & log$table == "scenario_states", ]
  expect_identical(log$detail[log$cause == "compliance_model"],
                   "all_or_nothing")
  st <- log[log$cause == "states", ]
  expect_identical(sub(";.*", "", st$detail), c(
    "both: 2 vehicles with partial compliance, 4 states",
    "one: 1 vehicle with partial compliance, 2 states"
  ))
  expect_identical(st$n_records, c(4L, 2L))
  ind <- log[log$cause == "vehicles_assumed_independent", ]
  expect_identical(ind$detail, "both")
  expect_identical(ind$n_records, 2L)
  added <- log[log$cause == "households_with_added", ]
  expect_identical(added$n_households, c(2L, 2L))
  expect_identical(log$n_records[log$cause == "all"], nrow(s))
})

test_that("no scenario rows: the baseline as one state", {
  sc <- two_vehicles()[0, ]
  s <- aon(sc)
  expect_identical(s$state, rep("none", 3))
  expect_identical(s$state_probability, rep(1, 3))
  expect_false(any(audit_log(s)$cause == "states"))
})

test_that("invariant: row order of the scenarios and of the inputs", {
  sc <- dplyr::bind_rows(two_vehicles(),
                         transform(as_scenarios(), compliance = 0.3))
  s <- aon(sc)
  p <- as_pipeline()
  r <- aon(sc[rev(seq_len(nrow(sc))), ],
           p = list(intake = restore_audit(p$intake[3:1, ], from = p$intake),
                    use = restore_audit(p$use[rev(seq_len(nrow(p$use))), ],
                                        from = p$use)))
  key <- function(t) paste(t$scenario, t$state, t$household_id)
  r <- r[match(key(s), key(r)), ]
  expect_equal(as.data.frame(r)[names(s)], as.data.frame(s),
               ignore_attr = TRUE)
})

test_that("functions of the scenario intake refuse the states table", {
  s <- aon(two_vehicles())
  expect_error(nutrient_density(s, "energy_kcal"),
               class = "hcesfort_error_audit")
  expect_error(flag_energy_plausibility(s, "energy_kcal", 100, 6000),
               class = "hcesfort_error_audit")
})

test_that("max_states stops a call before the rows are built (P219)", {
  sc <- rbind(two_vehicles(),
              transform(two_vehicles(c(1, 0.3)), scenario = "one"))
  # "both" has 4 states, "one" 2.
  expect_error(aon(sc, max_states = 3), class = "hcesfort_error_value")
  expect_snapshot(aon(sc, max_states = 3), error = TRUE)
  expect_identical(nrow(aon(sc, max_states = 4)), nrow(aon(sc)))
  # Average content has one state per scenario: never above the limit.
  a <- as_run(sc, compliance_model = "average_content", max_states = 1)
  expect_s3_class(a, "hces_scenario_intake")
  for (bad in list(0, 2.5, "4", c(4, 8), NA_real_, Inf)) {
    expect_error(aon(sc, max_states = bad), class = "hcesfort_error_argument")
  }
})

test_that("the log row states gives the rows and the size (P219)", {
  s <- aon(rbind(two_vehicles(),
                 transform(two_vehicles(c(1, 0.3)), scenario = "one")))
  st <- audit_log(s)
  st <- st[st$cause == "states", ]
  # Three households: 4 x 3 and 2 x 3 rows.
  expect_match(st$detail[1], "^both: .*; 12 rows, [0-9]+\\.[0-9] MB$")
  expect_match(st$detail[2], "^one: .*; 6 rows, [0-9]+\\.[0-9] MB$")
  expect_identical(sum(s$scenario %in% c("both", "one")), 18L)
})
