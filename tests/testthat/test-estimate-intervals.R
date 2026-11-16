# Intervals of the estimators in the corner cases of the v0.2 review
# (12e.4): no variation (P165), no degrees of freedom and `exact` (P166),
# the second option of survey (P167), PSU codes in several strata (P168),
# the effective sample size of a mean of probabilities (P164). Fixtures:
# the 8-household design of helper-estimate.R and small designs built in
# each test; expected values by hand or from survey directly.

log_n <- function(x, cause) {
  l <- audit_log(x)
  l$n_records[l$cause == cause]
}

test_that("a mean or a median without variation has no interval (P165)", {
  r <- es_result()
  r$intake <- 5
  for (stat in c("mean", "median")) {
    e <- estimate_households(es_design(), r, "intake", statistic = stat)
    expect_identical(e$estimate, c(5, 5))
    expect_identical(e$se, c(0, 0))
    expect_true(all(is.na(c(e$ci_low, e$ci_high))))
    expect_identical(e$interval_note, rep("no_variation", 2))
    expect_identical(log_n(e, "no_variation"), 2L)
    f <- flag_precision(e, min_n = 1, max_half_width = 1)
    expect_identical(f$precision_status, rep("exact", 2))
  }
})

test_that("a constant probability is no_variation, not degenerate", {
  r <- es_result()
  r$p <- 0.3
  e <- estimate_households(es_design(), r, "p")
  expect_identical(e$interval_note, rep("no_variation", 2))
  expect_identical(log_n(e, "degenerate_proportion"), integer(0))
  r$p <- 1
  e <- estimate_households(es_design(), r, "p")
  expect_identical(e$interval_note, rep("degenerate_proportion", 2))
})

test_that("a difference between identical scenarios has no interval", {
  r <- es_result()
  r$intake[9:16] <- r$intake[1:8]
  e <- estimate_difference(es_design(), r, "intake", reference = "base")
  expect_identical(c(e$estimate, e$se), c(0, 0))
  expect_true(is.na(e$ci_low) && is.na(e$ci_high))
  expect_identical(e$interval_note, "no_variation")
  expect_identical(log_n(e, "no_variation"), 1L)
})

test_that("a domain inside one PSU: no interval, no warning (P166)", {
  r <- es_result()
  r$one_psu <- rep(1:8 %in% 3:4, 2)
  for (stat in c("proportion", "mean", "median")) {
    for (m in c("logit", "korn_graubard")) {
      value <- if (stat == "proportion") "p" else "intake"
      expect_no_warning(e <- estimate_households(
        es_design(), r, value, statistic = stat, domain = "one_psu",
        ci_method = m
      ))
      expect_equal(e$df, c(0, 0))
      expect_true(all(is.na(c(e$ci_low, e$ci_high))))
      expect_identical(e$interval_note, rep("no_degrees_of_freedom", 2))
      expect_identical(log_n(e, "no_degrees_of_freedom"), 2L)
    }
  }
  e <- estimate_households(es_design(), r, "intake", statistic = "mean",
                           domain = "one_psu")
  # Households 3 and 4 (PSU 2 of stratum 1), weights 1 and 3:
  # (2 * 1 + 8 * 3) / 4 and (2 * 1 + 9 * 3) / 4.
  expect_equal(e$estimate, c(26 / 4, 29 / 4), tolerance = 1e-12)
})

test_that("se 0 under certainty with values that vary is not exact", {
  h <- es_households()
  h$psu <- h$stratum
  d <- as_hces_design(h, lonely_psu = "certainty")
  e <- estimate_households(d, es_result(), "intake", statistic = "mean")
  expect_identical(e$se, c(0, 0))
  expect_identical(e$interval_note, rep("no_degrees_of_freedom", 2))
  f <- flag_precision(e, min_n = 1, max_half_width = 1)
  expect_false(any(f$precision_status %in% "exact"))
})

test_that("survey.adjust.domain.lonely is fixed at FALSE (P167)", {
  # Region a has a single PSU in stratum 1 (PSU 1).
  h <- es_households()
  h$region <- c("a", "b", "b", "b", "a", "b", "a", "b")
  r <- es_result()
  y <- r$intake[1:8]
  d <- as_hces_design(h, lonely_psu = "adjust")
  run <- function(opt) {
    withr::with_options(list(survey.adjust.domain.lonely = opt),
                        estimate_households(d, r, "intake", "mean",
                                            by = "region"))
  }
  before <- getOption("survey.adjust.domain.lonely")
  e_false <- run(FALSE)
  e_true <- run(TRUE)
  expect_identical(e_true$se, e_false$se)
  ref <- function(opt) {
    h$y <- ifelse(is.na(y), 0, y)
    s <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                           nest = TRUE, data = h)
    keep <- h$region == "a" & !is.na(y)
    withr::with_options(
      list(survey.lonely.psu = "adjust", survey.adjust.domain.lonely = opt),
      suppressWarnings(survey::SE(survey::svymean(~y, s[keep, ])))
    )
  }
  base_a <- pick_est(e_false, "base")
  expect_equal(base_a$se[base_a$region == "a"], unname(ref(FALSE))[[1]],
               tolerance = 1e-8)
  # The option matters on this design, so the test can fail.
  expect_false(isTRUE(all.equal(ref(FALSE), ref(TRUE))))
  expect_identical(getOption("survey.adjust.domain.lonely"), before)
  l <- audit_log(e_false)
  expect_identical(l$detail[l$cause == "adjust_domain_lonely"], "FALSE")
})

test_that("PSU codes in several strata are counted in the log (P168)", {
  e <- estimate_households(es_design(), es_result(), "p")
  # PSU codes 1 and 2 appear in strata 1 and 2.
  expect_identical(log_n(e, "psu_in_several_strata"), 2L)
  h <- es_households()
  h$psu <- c(1, 1, 2, 2, 3, 3, 4, 4)
  e <- estimate_households(as_hces_design(h, "adjust"), es_result(), "p")
  expect_identical(log_n(e, "psu_in_several_strata"), integer(0))
})

test_that("n_effective is n over the design effect, by hand (P164)", {
  r <- es_result()
  e <- estimate_households(es_design(), r, "p")
  y <- r$p[1:8]
  keep <- !is.na(y)
  w <- es_households()$weight[keep]
  v <- y[keep]
  s2 <- sum(w * (v - sum(w * v) / sum(w))^2) / sum(w)
  se <- survey::SE(survey::svymean(~y, ref_design(y, rep(TRUE, 8))))
  expected <- min(s2 / unname(se)[[1]]^2, sum(keep))
  expect_equal(pick_est(e, "base")$n_effective, expected, tolerance = 1e-8)
  # A 0/1 outcome: s^2 is p (1 - p), the formula of the standards.
  r$ind <- r$intake > 3
  e <- estimate_households(es_design(), r, "ind")
  b <- pick_est(e, "base")
  expect_equal(b$n_effective,
               min(b$estimate * (1 - b$estimate) / b$se^2, b$n),
               tolerance = 1e-10)
  expect_true(is.na(estimate_households(es_design(), r, "intake",
                                        "median")$n_effective[[1]]))
})

test_that("a mean of probabilities clustered by PSU is suppressed (P164)", {
  # 10 PSUs of 20 households in one stratum; the probability of each
  # household is the mean of its PSU (0.30 to 0.70): p (1 - p) / se^2 is
  # far above 30, n over the design effect is about 9 (finding 10).
  h <- data.frame(household_id = 1:200, weight = 1,
                  stratum = 1, psu = rep(1:10, each = 20))
  x <- new_hces_tbl(
    data.frame(household_id = 1:200,
               p = rep(seq(0.30, 0.70, length.out = 10), each = 20)),
    "hces_inadequacy", key = "household_id"
  )
  e <- estimate_households(as_hces_design(h, "adjust"), x, "p",
                           ci_method = "korn_graubard")
  expect_gt(e$estimate * (1 - e$estimate) / e$se^2, 30)
  expect_lt(e$n_effective, 30)
  f <- flag_presentation(e)
  expect_identical(f$presentation_reason, "effective_sample_size")
  expect_identical(f$n_effective, e$n_effective)
})
