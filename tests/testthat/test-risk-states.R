# inadequacy() and above_ul() on the table of states of all-or-nothing
# compliance (docs/design-12e5.md, sections 4.2 and 4.3). Fixture of
# helper-scenario.R; requirements states_ear() and states_ul() there.
# Folate per AFE: h1 baseline 20, + 306 ug DFE (180 ug folic acid) at the
# full level of s1 (folic()); h2 baseline 10, + 153 (90). h3 is not
# estimated.

test_that("the hand example: average content 1, all or nothing 0.5", {
  # h1: baseline 20, full 326, EAR 200. Average content at 0.5: 173 < 200.
  a <- risk_of(as_run(folic(0.5), compliance_model = "average_content"))
  r <- risk_of(aon(folic(0.5)))
  expect_s3_class(r, "hces_inadequacy")
  expect_identical(attr(r, "audit_key"), attr(a, "audit_key"))
  expect_identical(names(r), names(a))
  expect_identical(risk_val(a, "s1", 1, "folate", "p_inadequate"), 1)
  expect_equal(risk_val(r, "s1", 1, "folate", "p_inadequate"), 0.5)
  # h2: full 163, below in both states.
  expect_equal(risk_val(r, "s1", 2, "folate", "p_inadequate"), 1)
  expect_identical(risk_val(r, "s1", 3, "folate", "p_inadequate"),
                   NA_real_)
  expect_equal(risk_val(r, "s1", 1, "folate", "intake"), 20 + 153)
})

test_that("two vehicles at 0.5 and 0.8: inadequacy by hand", {
  r <- risk_of(aon(two_vehicles()))
  # h1 iron by state: none 1, flour 6.5, sugar 3, both 8.5; EAR 5. Below
  # in none (0.1) and sugar (0.4).
  expect_equal(risk_val(r, "both", 1, "iron", "p_inadequate"), 0.5)
  # h2: none 0.5, flour 3.25, sugar 0.5, both 3.25: always below.
  expect_equal(risk_val(r, "both", 2, "iron", "p_inadequate"), 1)
  # Expected intake: 1 + 0.5 x 5.5 + 0.8 x 2.
  expect_equal(risk_val(r, "both", 1, "iron", "intake"), 1 + 2.75 + 1.6)
  expect_identical(nrow(r), 3L * 2L * 2L)
  log <- audit_log(r)
  expect_identical(log$n_records[log$cause == "states_collapsed"], 15L)
})

test_that("one vehicle: above the UL is c x [full] + (1 - c) x [baseline]", {
  for (c in c(0.3, 0.5, 0.9)) {
    u <- risk_of(aon(folic(c)), "above_ul")
    full <- risk_of(as_run(folic(1)), "above_ul")
    k <- full$scenario == "s1"
    w <- u$scenario == "s1"
    base <- full$scenario == "baseline"
    expect_equal(u$above_ul_added[w], c * full$above_ul_added[k] +
                   (1 - c) * full$above_ul_added[base], tolerance = 1e-12)
    a <- risk_of(as_run(folic(c), compliance_model = "average_content"),
                 "above_ul")
    expect_equal(u$amount_added, a$amount_added, tolerance = 1e-12)
  }
  expect_identical(risk_val(u, "s1", 1, "folate", "above_ul_added"), 0.9)
  expect_identical(risk_val(a, "s1", 1, "folate", "above_ul_added"), 1)
  log <- audit_log(a)
  expect_true(any(log$cause == "average_content_understates_ul"))
  expect_false(any(audit_log(u)$cause == "average_content_understates_ul"))
})

test_that("the estimate is the same combination of two svymean()", {
  h <- data.frame(household_id = 1:3, weight = c(1, 2, 1), stratum = 1,
                  psu = 1:3)
  d <- as_hces_design(h, lonely_psu = "adjust")
  u <- risk_of(aon(folic(0.3)), "above_ul")
  e <- estimate_households(d, u[u$scenario == "s1", ], "above_ul_added",
                           statistic = "mean")
  full <- risk_of(as_run(folic(1)), "above_ul")
  s <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         data = h)
  ref <- function(v) {
    ids <- full$household_id[full$scenario == "baseline"]
    s$variables$y <- v[match(h$household_id, ids)]
    unname(stats::coef(survey::svymean(~y, subset(s, !is.na(y)))))
  }
  y_full <- full$above_ul_added[full$scenario == "s1"]
  y_base <- full$above_ul_added[full$scenario == "baseline"]
  expect_equal(e$estimate, 0.3 * ref(y_full) + 0.7 * ref(y_base),
               tolerance = 1e-8)
  # h1 above (weight 1), h2 not (weight 2): 0.3 x 1 / 3.
  expect_equal(e$estimate, 0.3 / 3, tolerance = 1e-8)
})

test_that("compliance 1 everywhere: both models give the same tables", {
  sc <- as_scenarios()
  for (fun in c("inadequacy", "above_ul")) {
    a <- risk_of(as_run(sc), fun)
    r <- risk_of(aon(sc), fun)
    expect_equal(as.data.frame(r), as.data.frame(a), ignore_attr = TRUE)
  }
})

test_that("the expected added amount equals that of average content", {
  sc <- dplyr::bind_rows(two_vehicles(),
                         transform(as_scenarios(), compliance = 0.3))
  a <- risk_of(as_run(sc, compliance_model = "average_content"))
  r <- risk_of(aon(sc))
  expect_equal(r$added, a$added, tolerance = 1e-12)
  expect_equal(r$intake, a$intake, tolerance = 1e-12)
  expect_true(all(r$p_inadequate >= 0 & r$p_inadequate <= 1, na.rm = TRUE))
})

test_that("invariant: row order of the table of states", {
  s <- aon(two_vehicles())
  shuffled <- restore_audit(s[rev(seq_len(nrow(s))), ], from = s)
  # The gates read the first scenario of the table: keep the baseline first.
  shuffled <- restore_audit(
    shuffled[order(shuffled$scenario != "baseline"), ], from = s
  )
  r1 <- risk_of(s)
  r2 <- risk_of(shuffled)
  k <- function(t) paste(t$scenario, t$household_id, t$nutrient)
  expect_equal(r2$p_inadequate[match(k(r1), k(r2))], r1$p_inadequate,
               tolerance = 1e-12)
})

test_that("the estimators refuse the table of states", {
  s <- aon(two_vehicles())
  h <- data.frame(household_id = 1:3, weight = 1, stratum = 1, psu = 1:3)
  d <- as_hces_design(h, lonely_psu = "adjust")
  expect_error(estimate_households(d, s, "iron_mg", statistic = "mean"),
               class = "hcesfort_error_audit")
  expect_error(estimate_difference(d, s, "iron_mg", reference = "baseline"),
               class = "hcesfort_error_audit")
  expect_snapshot(estimate_households(d, s, "iron_mg", statistic = "mean"),
                  error = TRUE)
})

test_that("a UL on total iron: amount_total and above_ul_total by hand", {
  # P217. Fixture two_vehicles(): h1 iron by state none 1 (0.1), flour 6.5
  # (0.1), sugar 3 (0.4), both 8.5 (0.4); UL 6 mg on the total.
  ul <- data.frame(nutrient = "iron", unit = "mg", ul = 6, ul_unit = "mg",
                   ul_applies_to = "total")
  u <- above_ul(aon(two_vehicles()), ul, min_coverage = 0.9,
                min_records_used = 0)
  expect_equal(risk_val(u, "both", 1, "iron", "amount_total"),
               1 + 0.5 * 5.5 + 0.8 * 2, tolerance = 1e-12)
  expect_equal(risk_val(u, "both", 1, "iron", "above_ul_total"),
               0.1 + 0.4, tolerance = 1e-12)
  # h2: none 0.5, flour 3.25, sugar 0.5, both 3.25: never above.
  expect_identical(risk_val(u, "both", 2, "iron", "above_ul_total"), 0)
  expect_equal(risk_val(u, "both", 2, "iron", "amount_total"),
               0.5 + 0.5 * 2.75, tolerance = 1e-12)
})

test_that("a form with a diet part: total by hand under all or nothing", {
  # P217. Folic acid: diet 50, added 100 in the state "flour" (0.3);
  # UL 120 on the form: only the total can pass it.
  req <- data.frame(nutrient = "folate", unit = "ug_dfe", ul = 120,
                    ul_unit = "ug", ul_applies_to = "folic_acid")
  s <- ul_form_run(compliance = 0.3, compliance_model = "all_or_nothing")
  u <- above_ul(s, req, min_coverage = 0, min_records_used = 0)
  expect_identical(risk_val(u, "s", 1, "folate", "ul_scope"),
                   "form_diet_and_added")
  expect_equal(risk_val(u, "s", 1, "folate", "amount_added"), 30,
               tolerance = 1e-12)
  expect_equal(risk_val(u, "s", 1, "folate", "amount_total"), 80,
               tolerance = 1e-12)
  expect_identical(risk_val(u, "s", 1, "folate", "above_ul_added"), 0)
  expect_equal(risk_val(u, "s", 1, "folate", "above_ul_total"), 0.3,
               tolerance = 1e-12)
})

test_that("the understates flag is written only under average content", {
  # S3.3 of docs/review-12e5-states.md.
  a <- risk_of(as_run(folic(0.5), compliance_model = "average_content"),
               "above_ul")
  r <- risk_of(aon(folic(0.5)), "above_ul")
  log_a <- audit_log(a)
  row <- log_a[log_a$cause == "average_content_understates_ul", ]
  expect_identical(nrow(row), 1L)
  expect_identical(row$kind, "flagged")
  expect_false(any(audit_log(r)$cause == "average_content_understates_ul"))
})
