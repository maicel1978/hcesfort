# as_hces_design(), estimate_households(), estimate_difference() and
# flag_precision(). Fixture: an invented design of 8 households in 2 strata
# of 2 PSUs each, and a result table with two scenarios. Every estimate is
# compared with a direct computation by survey on the same design.
es_households <- function() {
  data.frame(household_id = 1:8, weight = c(1, 2, 1, 3, 2, 1, 1, 2),
             stratum = rep(1:2, each = 4), psu = rep(c(1, 1, 2, 2), 2),
             region = rep(c("a", "b"), 4),
             urban = c(TRUE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, FALSE))
}

# Household 5 has no estimate (NA) in both scenarios.
es_result <- function() {
  data <- data.frame(
    scenario = rep(c("base", "fort"), each = 8), household_id = rep(1:8, 2),
    p = c(1, 0, 1, 0.5, NA, 0, 1, 1, 0, 0, 1, 0.25, NA, 0, 0.5, 1),
    ok = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE),
    intake = c(3, 5, 2, 8, NA, 6, 1, 4, 4, 6, 2, 9, NA, 7, 2, 5)
  )
  new_hces_tbl(data, "hces_inadequacy", key = c("scenario", "household_id"))
}

es_design <- function(lonely = "adjust") {
  as_hces_design(es_households(), lonely_psu = lonely)
}

# The reference: survey on a design built by hand, the domain as a subset.
ref_design <- function(y, keep) {
  h <- es_households()
  inside_ref <- keep & !is.na(y)
  h$y <- ifelse(is.na(y), 0, y)
  d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         nest = TRUE, data = h)
  d[inside_ref, ]
}

pick_est <- function(e, scenario) e[e$scenario == scenario, ]

test_that("as_hces_design() builds a srvyr design and needs lonely_psu", {
  d <- es_design()
  expect_s3_class(d, c("tbl_svy", "survey.design2"))
  expect_identical(attr(d, "hces_lonely_psu"), "adjust")
  expect_error(as_hces_design(es_households()),
               class = "hcesfort_error_argument")
  expect_error(as_hces_design(es_households(), "drop"),
               class = "hcesfort_error_argument")
  expect_error(as_hces_design(es_households()[-2], "adjust"),
               class = "hcesfort_error_schema")
})

test_that("proportion agrees with survey::svyciprop() to 1e-8", {
  x <- es_result()
  y <- x$p[x$scenario == "base"]
  sub <- ref_design(y, rep(TRUE, 8))
  for (m in c("logit", "mean", "beta")) {
    e <- pick_est(estimate_households(es_design(), x, "p", ci_method = m),
                  "base")
    r <- survey::svyciprop(~y, sub, method = m, df = survey::degf(sub))
    expect_equal(e$estimate, as.vector(stats::coef(r)), tolerance = 1e-8)
    expect_equal(e$se, as.vector(survey::SE(r)), tolerance = 1e-8)
    expect_equal(c(e$ci_low, e$ci_high), unname(attr(r, "ci")),
                 tolerance = 1e-8)
  }
  e <- pick_est(estimate_households(es_design(), x, "p"), "base")
  expect_identical(e$n, 7L)
  expect_identical(e$n_missing, 1L)
  expect_identical(e$df, survey::degf(sub))
})

test_that("mean and median agree with svymean() and svyquantile()", {
  x <- es_result()
  y <- x$intake[x$scenario == "fort"]
  sub <- ref_design(y, rep(TRUE, 8))
  e <- pick_est(estimate_households(es_design(), x, "intake",
                                    statistic = "mean", df = "design"),
                "fort")
  r <- survey::svymean(~y, sub)
  df <- survey::degf(es_design())
  expect_equal(e$estimate, as.vector(stats::coef(r)), tolerance = 1e-8)
  expect_equal(c(e$ci_low, e$ci_high),
               unname(stats::confint(r, df = df)[1, ]), tolerance = 1e-8)
  e <- pick_est(estimate_households(es_design(), x, "intake",
                                    statistic = "median", level = 0.9),
                "fort")
  q <- survey::svyquantile(~y, sub, quantiles = 0.5, ci = TRUE,
                           alpha = 0.1, df = survey::degf(sub))
  expect_equal(e$estimate, unname(stats::coef(q)), tolerance = 1e-8)
  expect_equal(c(e$ci_low, e$ci_high), unname(stats::confint(q)[1, ]),
               tolerance = 1e-8)
  expect_identical(e$conf_level, 0.9)
})

test_that("by and domain are domains of the full design", {
  x <- es_result()
  y <- x$p[x$scenario == "base"]
  h <- es_households()
  e <- estimate_households(es_design(), x, "p", by = "region",
                           statistic = "mean")
  e <- pick_est(e, "base")
  expect_identical(e$region, c("a", "b"))
  for (reg in c("a", "b")) {
    r <- survey::svymean(~y, ref_design(y, h$region == reg))
    expect_equal(e$estimate[e$region == reg], as.vector(stats::coef(r)),
                 tolerance = 1e-8)
    expect_equal(e$se[e$region == reg], as.vector(survey::SE(r)),
                 tolerance = 1e-8)
  }
  # domain in the design (urban) and in x (ok).
  e <- pick_est(estimate_households(es_design(), x, "p", domain = "urban",
                                    statistic = "mean"), "base")
  r <- survey::svymean(~y, ref_design(y, h$urban))
  expect_equal(e$estimate, as.vector(stats::coef(r)), tolerance = 1e-8)
  e <- pick_est(estimate_households(es_design(), x, "p", domain = "ok",
                                    statistic = "mean"), "base")
  r <- survey::svymean(~y, ref_design(y, x$ok[x$scenario == "base"]))
  expect_equal(e$estimate, as.vector(stats::coef(r)), tolerance = 1e-8)
})

test_that("an empty domain gives a missing estimate and is flagged", {
  x <- es_result()
  x$ok <- FALSE
  e <- estimate_households(es_design(), x, "p", domain = "ok")
  expect_true(all(is.na(e$estimate)))
  expect_identical(e$n, c(0L, 0L))
  log <- audit_log(e)
  expect_identical(log$n_records[log$cause == "empty_domain"], 2L)
})

test_that("lonely PSU: the choice is applied and the option restored", {
  h <- es_households()
  h$psu[h$stratum == 2] <- 1
  x <- es_result()
  old <- getOption("survey.lonely.psu")
  d <- as_hces_design(h, lonely_psu = "fail")
  expect_error(estimate_households(d, x, "p", statistic = "mean"))
  expect_identical(getOption("survey.lonely.psu"), old)
  d <- as_hces_design(h, lonely_psu = "adjust")
  e <- estimate_households(d, x, "p", statistic = "mean")
  expect_false(anyNA(e$se))
  log <- audit_log(e)
  expect_identical(log$detail[log$cause == "lonely_psu"], "adjust")
})

test_that("the paired difference agrees with svymean() of the difference", {
  x <- es_result()
  y <- x$p[x$scenario == "fort"] - x$p[x$scenario == "base"]
  sub <- ref_design(y, rep(TRUE, 8))
  e <- estimate_difference(es_design(), x, "p", reference = "base")
  expect_identical(e$scenario, "fort")
  expect_identical(e$reference, "base")
  expect_identical(e$statistic, "mean_difference")
  r <- survey::svymean(~y, sub)
  expect_equal(e$estimate, as.vector(stats::coef(r)), tolerance = 1e-8)
  expect_equal(e$se, as.vector(survey::SE(r)), tolerance = 1e-8)
  expect_equal(c(e$ci_low, e$ci_high),
               unname(stats::confint(r, df = survey::degf(sub))[1, ]),
               tolerance = 1e-8)
  # Same domain in both scenarios: the mean difference is the difference
  # of the means.
  m <- estimate_households(es_design(), x, "p", statistic = "mean")
  expect_equal(e$estimate, m$estimate[2] - m$estimate[1], tolerance = 1e-12)
})

test_that("estimation errors are classed", {
  x <- es_result()
  d <- es_design()
  expect_error(estimate_households(es_households(), x, "p"),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, as.data.frame(x), "p"),
               class = "hcesfort_error_audit")
  expect_error(estimate_households(d, x, "nope"),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, x, "p", statistic = "total"),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, x, "p", ci_method = "exact"),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, x, "p", level = 95),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, x, "p", df = "full"),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, x, "p", by = "province"),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, x, "p", domain = "region"),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(d, x, "p", domain = c("ok", "urban")),
               class = "hcesfort_error_argument")
  big <- new_hces_tbl(data.frame(household_id = 9, p = 1), "hces_intake",
                      key = "household_id")
  expect_error(estimate_households(d, big, "p"),
               class = "hcesfort_error_join")
  noh <- new_hces_tbl(data.frame(id = 1, p = 1), "hces_intake", key = "id")
  expect_error(estimate_households(d, noh, "p"),
               class = "hcesfort_error_argument")
  expect_error(estimate_difference(d, x, "p", reference = "none"),
               class = "hcesfort_error_argument")
  one <- new_hces_tbl(data.frame(household_id = 1:8, p = 1), "hces_intake",
                      key = "household_id")
  expect_error(estimate_difference(d, one, "p", reference = "base"),
               class = "hcesfort_error_argument")
})

test_that("flag_precision() by hand", {
  e <- estimate_households(es_design(), es_result(), "p", by = "region",
                           statistic = "mean")
  half <- (e$ci_high - e$ci_low) / 2
  f <- flag_precision(e, min_n = 4, max_half_width = 0.4)
  expect_identical(f$low_precision, e$n < 4 | half > 0.4)
  expect_s3_class(f, "hces_estimate")
  expect_error(flag_precision(e, min_n = 4), class = "hcesfort_error_argument")
  expect_error(flag_precision(e, -1, 0.1), class = "hcesfort_error_argument")
  log <- audit_log(f)
  expect_identical(log$n_records[log$cause == "low_precision"],
                   sum(f$low_precision))
})

test_that("invariants: row order, scaling, households order", {
  x <- es_result()
  e1 <- estimate_households(es_design(), x, "intake", statistic = "mean")
  x2 <- restore_audit(x[rev(seq_len(nrow(x))), ], from = x)
  e2 <- estimate_households(es_design(), x2, "intake", statistic = "mean")
  e2 <- e2[match(e1$scenario, e2$scenario), ]
  expect_equal(e2$estimate, e1$estimate, tolerance = 1e-12)
  x3 <- x
  x3$intake <- 3 * x3$intake
  for (st in c("mean", "median")) {
    a <- estimate_households(es_design(), x, "intake", statistic = st)
    b <- estimate_households(es_design(), x3, "intake", statistic = st)
    expect_equal(b$estimate, 3 * a$estimate, tolerance = 1e-10)
  }
  h <- es_households()[8:1, ]
  e3 <- estimate_households(as_hces_design(h, "adjust"), x, "intake",
                            statistic = "mean")
  expect_equal(e3$estimate, e1$estimate, tolerance = 1e-12)
  expect_equal(e3$se, e1$se, tolerance = 1e-12)
})

test_that("the example chain runs to estimates", {
  g <- convert_units(hces_example$acquisitions, hces_example$unit_factors,
                     priority = "food")
  afe <- new_hces_tbl(
    data.frame(household_id = hces_example$households$household_id,
               n_members = 1, afe = 1),
    "hces_afe", key = "household_id"
  )
  use <- vehicle_coverage(g, hces_example$vehicles, afe,
                          hces_example$households)
  d <- as_hces_design(hces_example$households, lonely_psu = "adjust")
  e <- estimate_households(d, use, "acquired", by = "region")
  expect_identical(nrow(e), 5L * 2L)
  ci <- !is.na(e$ci_low)
  expect_true(all(e$ci_low[ci] <= e$estimate[ci] &
                    e$estimate[ci] <= e$ci_high[ci]))
  expect_true(all(e$se[!ci] == 0 & e$estimate[!ci] %in% c(0, 1)))
})

# Degenerate proportions, lonely PSU, and the tests the mutation run of the
# v0.1 review showed to be weak (M5, M6, P84, T1 to T4).
test_that("a proportion of exactly 0 or 1 is exact, without interval", {
  x <- es_result()
  x$zero <- 0
  x$one <- ifelse(x$household_id == 5, NA, TRUE)
  for (m in c("logit", "beta", "mean")) {
    e <- estimate_households(es_design(), x, "zero", ci_method = m)
    expect_identical(e$estimate, c(0, 0))
    expect_identical(e$se, c(0, 0))
    expect_true(all(is.na(e$ci_low) & is.na(e$ci_high)))
  }
  e <- estimate_households(es_design(), x, "one")
  expect_identical(e$estimate, c(1, 1))
  expect_identical(e$n, c(7L, 7L))
  log <- audit_log(e)
  expect_identical(log$n_records[log$cause == "degenerate_proportion"], 2L)
  m <- estimate_households(es_design(), x, "zero", statistic = "mean")
  expect_false("degenerate_proportion" %in% audit_log(m)$cause)
})

test_that("df: domain and design differ when a domain empties a PSU", {
  x <- es_result()
  x$ok <- !x$household_id %in% 1:2
  y <- x$intake[x$scenario == "fort"]
  sub <- ref_design(y, x$ok[x$scenario == "fort"])
  r <- survey::svymean(~y, sub)
  dfs <- c(domain = survey::degf(sub), design = survey::degf(es_design()))
  expect_false(dfs[["domain"]] == dfs[["design"]])
  for (k in names(dfs)) {
    e <- pick_est(estimate_households(es_design(), x, "intake",
                                      statistic = "mean", domain = "ok",
                                      df = k), "fort")
    expect_identical(e$df, dfs[[k]])
    expect_equal(c(e$ci_low, e$ci_high),
                 unname(stats::confint(r, df = dfs[[k]])[1, ]),
                 tolerance = 1e-8)
  }
})

test_that("SE of the mean and of the median agree with survey", {
  x <- es_result()
  y <- x$intake[x$scenario == "fort"]
  sub <- ref_design(y, rep(TRUE, 8))
  e <- pick_est(estimate_households(es_design(), x, "intake",
                                    statistic = "mean"), "fort")
  expect_equal(e$se, as.vector(survey::SE(survey::svymean(~y, sub))),
               tolerance = 1e-8)
  e <- pick_est(estimate_households(es_design(), x, "intake",
                                    statistic = "median"), "fort")
  q <- survey::svyquantile(~y, sub, quantiles = 0.5, ci = TRUE,
                           df = survey::degf(sub))
  expect_equal(e$se, unname(survey::SE(q)), tolerance = 1e-8)
})

test_that("lonely PSU: classed error under fail, adjust as in survey", {
  h <- es_households()
  h$psu[h$stratum == 2] <- 1
  x <- es_result()
  d <- as_hces_design(h, lonely_psu = "fail")
  err <- expect_error(estimate_households(d, x, "p", statistic = "mean"),
                      class = "hcesfort_error_value")
  expect_match(conditionMessage(err), "Stratum")
  expect_identical(err$columns, c("stratum", "psu"))
  e <- pick_est(estimate_households(as_hces_design(h, "adjust"), x, "p",
                                    statistic = "mean"), "base")
  y <- x$p[x$scenario == "base"]
  h$y <- ifelse(is.na(y), 0, y)
  ref <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                           nest = TRUE, data = h)
  r <- withr::with_options(list(survey.lonely.psu = "adjust"),
                           survey::svymean(~y, ref[!is.na(y), ]))
  expect_equal(e$se, as.vector(survey::SE(r)), tolerance = 1e-8)
})

test_that("flag_precision(): literal flags at the limits", {
  e <- new_hces_tbl(
    data.frame(group = c("a", "b", "c", "d", "e"), n = c(3L, 4L, 5L, 4L, 9L),
               estimate = 0.5, ci_low = c(0, 0, 0, NA, 0.1),
               ci_high = c(0.2, 0.8, 0.82, NA, 0.9)),
    "hces_estimate", key = "group"
  )
  f <- flag_precision(e, min_n = 4, max_half_width = 0.4)
  expect_identical(f$low_precision, c(TRUE, FALSE, TRUE, FALSE, FALSE))
})

# domain_from (correction 3): a household table carrying the flag. Flag:
# TRUE for households 1, 2, 3, 6, 7; FALSE for 4; NA for 5 and 8.
es_flags <- function(flag = c(TRUE, TRUE, TRUE, FALSE, NA, TRUE, TRUE, NA)) {
  t <- new_hces_tbl(data.frame(household_id = 8:1, plausible = rev(flag)),
                    "hces_intake", key = "household_id")
  audit_add(t, "flag_energy_plausibility", "intake", "note", "range", 8L,
            detail = "1000 to 4000 kcal")
}

test_that("domain_from: the flag of another table is a domain", {
  x <- es_result()
  flag <- c(TRUE, TRUE, TRUE, FALSE, NA, TRUE, TRUE, NA)
  e <- pick_est(estimate_households(es_design(), x, "p", domain = "plausible",
                                    domain_from = es_flags()), "base")
  y <- x$p[x$scenario == "base"]
  sub <- ref_design(y, flag %in% TRUE)
  r <- survey::svyciprop(~y, sub, method = "logit", df = survey::degf(sub))
  expect_equal(e$estimate, as.vector(stats::coef(r)), tolerance = 1e-8)
  expect_equal(e$se, as.vector(survey::SE(r)), tolerance = 1e-8)
  expect_identical(e$n, 5L)
  d <- pick_est(estimate_difference(es_design(), x, "p", reference = "base",
                                    domain = "plausible",
                                    domain_from = es_flags()), "fort")
  dy <- x$p[x$scenario == "fort"] - y
  rd <- survey::svymean(~y, ref_design(dy, flag %in% TRUE))
  expect_equal(d$estimate, as.vector(stats::coef(rd)), tolerance = 1e-8)
  expect_equal(d$se, as.vector(survey::SE(rd)), tolerance = 1e-8)
})

test_that("domain_from: log of the flag, missing flags counted once", {
  x <- es_result()
  x <- audit_add(x, "flag_energy_plausibility", "intake", "note", "range",
                 8L, detail = "1000 to 4000 kcal")
  e <- estimate_households(es_design(), x, "p", domain = "plausible",
                           domain_from = es_flags())
  log <- audit_log(e)
  expect_identical(sum(log$cause == "range"), 1L)
  expect_identical(log$detail[log$cause == "domain"],
                   "plausible (domain_from)")
  expect_identical(log$n_households[log$cause == "domain_flag_missing"], 2L)
  e2 <- estimate_households(es_design(), es_result(), "p",
                            domain = "plausible", domain_from = es_flags())
  expect_identical(sum(audit_log(e2)$cause == "range"), 1L)
  e3 <- estimate_households(es_design(), es_result(), "p", domain = "ok")
  expect_identical(audit_log(e3)$detail[audit_log(e3)$cause == "domain"],
                   "ok (x)")
})

test_that("domain_from: one row per household, same households", {
  x <- es_result()
  two <- new_hces_tbl(data.frame(household_id = c(1:8, 1),
                                 plausible = TRUE, vehicle = c(rep("a", 8),
                                                               "b")),
                      "hces_vehicle_use", key = c("household_id", "vehicle"))
  err <- expect_error(estimate_households(es_design(), x, "p",
                                          domain = "plausible",
                                          domain_from = two),
                      class = "hcesfort_error_key")
  expect_match(conditionMessage(err), "one vehicle")
  short <- dplyr::filter(es_flags(), household_id != 3)
  err <- expect_error(estimate_households(es_design(), x, "p",
                                          domain = "plausible",
                                          domain_from = short),
                      class = "hcesfort_error_join")
  expect_identical(err$n, 1L)
  expect_error(estimate_households(es_design(), x, "p", domain = "nope",
                                   domain_from = es_flags()),
               class = "hcesfort_error_argument")
  expect_error(estimate_households(es_design(), x, "p", domain = "plausible",
                                   domain_from = as.data.frame(es_flags())),
               class = "hcesfort_error_audit")
  err <- expect_error(estimate_households(es_design(), x, "p",
                                          domain = "plausible"),
                      class = "hcesfort_error_argument")
  expect_match(conditionMessage(err), "domain_from")
})

test_that("flag_precision() names the argument that failed", {
  e <- estimate_households(es_design(), es_result(), "p")
  err <- expect_error(flag_precision(e, 4, -1),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "max_half_width")
  err <- expect_error(flag_precision(e, max_half_width = 0.1),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "min_n")
})

test_that("a table keyed by household only is one group", {
  # Before 12b, unique() of a tibble without columns failed here.
  x <- es_result()
  one <- new_hces_tbl(as.data.frame(x)[x$scenario == "fort",
                                       c("household_id", "intake")],
                      "hces_intake", key = "household_id")
  e <- estimate_households(es_design(), one, "intake", statistic = "mean",
                           by = "region")
  expect_identical(names(e)[1], "region")
  r <- survey::svymean(~y, ref_design(one$intake, es_households()$region ==
                                        "a"))
  expect_equal(e$estimate[e$region == "a"], as.vector(stats::coef(r)),
               tolerance = 1e-8)
  expect_identical(nrow(estimate_households(es_design(), one, "intake",
                                            statistic = "median")), 1L)
})
