# flag_presentation() (12d.4, C3 of docs/design-reports-v3.md; tests of its
# section 3.4). Fixtures: estimate tables built by hand, one row per case,
# with the expected status written in the test; the published rows of the
# NCHS report (helper-nchs.R); and the 8-household design of
# helper-estimate.R.

# A hand-built estimate table: one row per element of the arguments.
fp_estimates <- function(estimate, ci_low, ci_high, n = 100, df = 20,
                         se = 0.01, statistic = "proportion",
                         ci_method = "korn_graubard", conf_level = 0.95) {
  k <- length(estimate)
  stat <- rep(statistic, length.out = k)
  data <- data.frame(
    id = seq_len(k), statistic = stat, estimate = estimate,
    se = rep(se, length.out = k), ci_low = ci_low, ci_high = ci_high,
    ci_method = ifelse(stat == "proportion", ci_method, "t"),
    conf_level = conf_level, df = rep(df, length.out = k),
    n = rep(n, length.out = k)
  )
  new_hces_tbl(data, "hces_estimate", key = "id")
}

# The published limits are used, not the limits recomputed from the
# rounded estimate and SE: near a boundary (non-Hispanic Asian, elevated:
# published width 0.051, recomputed 0.0498) the rounding of the inputs
# would decide the row.
test_that("the published decisions of Tables I and II are reproduced", {
  t <- nchs_published_rows()
  p <- t$percent / 100
  se <- t$se / 100
  e <- fp_estimates(p, t$lower / 100, t$upper / 100, n = t$n, df = t$df,
                    se = se)
  f <- flag_presentation(e)
  expected <- c(present = "present", complement = "present",
                suppress = "suppress", review = "review")[t$decision]
  expect_identical(f$presentation, unname(expected))
  expect_identical(f$complement_unreliable[f$presentation == "present"],
                   t$decision[f$presentation == "present"] == "complement")
  expect_identical(unique(f$presentation_reason[t$decision == "suppress"]),
                   "relative_width")
  expect_identical(unique(f$presentation_reason[t$decision == "review"]),
                   "degrees_of_freedom")
  # Effective sample size above n: n is used (footnotes 8 and 6).
  capped <- t$n_effective > t$n
  expect_identical(f$n_effective[capped], as.numeric(t$n[capped]))
  expect_equal(f$n_effective[!capped], t$n_effective[!capped],
               tolerance = 0.03)
})

test_that("each criterion and its boundary, in the order of the flow chart", {
  # Rows: n 29 / 30; n_e below 30; width 0.30 / just below; relative width
  # 1.3 / just above; width 0.05 with p = 0; p = 0 with a wider interval;
  # p = 1 with width 0.1; df 7 / 8.
  e <- fp_estimates(
    estimate = c(0.5, 0.5, 0.5, 0.5, 0.5, 0.2, 0.2, 0, 0, 1, 0.5, 0.5),
    ci_low = c(0.45, 0.45, 0.45, 0.3, 0.3, 0, 0, 0, 0, 0.9, 0.45, 0.45),
    ci_high = c(0.5, 0.5, 0.5, 0.6, 0.5999, 0.26, 0.2601, 0.05, 0.06, 1,
                0.5, 0.5),
    n = c(29, 30, 100, rep(100, 9)),
    se = c(0.01, 0.01, 0.1, rep(0.01, 4), 0, 0, 0, 0.01, 0.01),
    df = c(rep(20, 10), 7, 8)
  )
  f <- flag_presentation(e)
  expect_identical(f$presentation_reason, c(
    "sample_size", NA, "effective_sample_size", "absolute_width", NA, NA,
    "relative_width", "zero_events", "relative_width", "zero_events",
    "degrees_of_freedom", NA
  ))
  expect_identical(f$presentation, c(
    "suppress", "present", "suppress", "suppress", "present", "present",
    "suppress", "review", "suppress", "review", "review", "present"
  ))
  expect_equal(f$n_effective[c(3, 8)], c(25, 100), tolerance = 1e-12)
  expect_identical(f$ci_relative_width[8], Inf)
})

test_that("other estimators: only sample size and degrees of freedom", {
  e <- fp_estimates(estimate = c(10, 10, 10, 10), ci_low = c(0, 0, 0, 9),
                    ci_high = c(100, 100, 100, 11), n = c(29, 30, 30, 30),
                    df = c(20, 20, 7, 20), statistic = "mean")
  f <- flag_presentation(e)
  expect_identical(f$presentation, c("suppress", "present", "review",
                                     "present"))
  expect_true(all(is.na(c(f$n_effective, f$ci_relative_width,
                          f$complement_unreliable))))
  expect_identical(f$ci_width, c(100, 100, 100, 2))
})

test_that("a missing estimate with enough households has no status", {
  e <- fp_estimates(estimate = c(NA, NA), ci_low = NA_real_,
                    ci_high = NA_real_, n = c(0, 50), se = NA_real_,
                    statistic = "share")
  f <- flag_presentation(e)
  expect_identical(f$presentation, c("suppress", NA))
  log <- audit_log(f)
  expect_identical(log$n_records[log$cause == "presentation_undefined"], 1L)
})

test_that("the audit log counts each status and reason, and the standard", {
  e <- fp_estimates(estimate = c(0.5, 0.5, 0.5, 0.02), n = c(10, 100, 100, 100),
                    ci_low = c(0.45, 0.45, 0.45, 0.01),
                    ci_high = c(0.5, 0.5, 0.5, 0.1), df = c(20, 20, 5, 20))
  log <- audit_log(flag_presentation(e))
  n_of <- function(cause) log$n_records[log$cause == cause]
  expect_identical(n_of("present"), 1L)
  expect_identical(n_of("review"), 1L)
  expect_identical(n_of("suppress"), 2L)
  expect_identical(n_of("sample_size"), 1L)
  expect_identical(n_of("relative_width"), 1L)
  expect_identical(n_of("degrees_of_freedom"), 1L)
  expect_match(log$detail[log$cause == "standard"], "min_n = 30")
})

test_that("only the Korn-Graubard interval at the standard's level is judged", {
  e <- fp_estimates(0.5, 0.45, 0.5, ci_method = "logit")
  expect_error(flag_presentation(e), class = "hcesfort_error_argument")
  e <- fp_estimates(0.5, 0.45, 0.5, conf_level = 0.9)
  expect_error(flag_presentation(e), class = "hcesfort_error_argument")
  m <- fp_estimates(10, 9, 11, statistic = "mean", conf_level = 0.9)
  expect_s3_class(flag_presentation(m), "hces_estimate")
  old <- fp_estimates(0.5, 0.45, 0.5)
  old$ci_method <- NULL
  expect_error(flag_presentation(old), class = "hcesfort_error_argument")
  expect_error(flag_presentation(data.frame(x = 1)),
               class = "hcesfort_error_audit")
})

test_that("a malformed standard is a schema error", {
  e <- fp_estimates(0.5, 0.45, 0.5)
  s <- ref_presentation_standard
  bad <- list(s[-1, ], rbind(s, s[1, ]), transform(s, value = NA_real_),
              transform(s, value = as.character(value)),
              transform(s, value = ifelse(criterion == "conf_level", 1,
                                          value)),
              transform(s, value = ifelse(criterion == "min_n", -1, value)))
  for (b in bad) {
    expect_error(flag_presentation(e, b), class = "hcesfort_error_schema")
  }
})

test_that("a stricter standard never presents what was suppressed", {
  t <- nchs_published_rows()
  p <- t$percent / 100
  se <- t$se / 100
  e <- fp_estimates(p, t$lower / 100, t$upper / 100, n = t$n, df = t$df,
                    se = se)
  rank <- c(present = 1, review = 2, suppress = 3)
  base <- rank[flag_presentation(e)$presentation]
  s <- ref_presentation_standard
  stricter <- list(min_n = 200, min_n_effective = 200, min_df = 14,
                   small_absolute_width = 0.01, large_absolute_width = 0.1,
                   max_relative_width = 0.5)
  for (k in names(stricter)) {
    s2 <- s
    s2$value[s2$criterion == k] <- stricter[[k]]
    now <- rank[flag_presentation(e, s2)$presentation]
    expect_true(all(now >= base), label = k)
    expect_true(any(now > base), label = k)
  }
})

test_that("the status does not depend on row order", {
  t <- nchs_published_rows()
  p <- t$percent / 100
  se <- t$se / 100
  e <- fp_estimates(p, t$lower / 100, t$upper / 100, n = t$n, df = t$df,
                    se = se)
  o <- rev(seq_len(nrow(e)))
  r <- fp_estimates(p[o], t$lower[o] / 100, t$upper[o] / 100, n = t$n[o],
                    df = t$df[o], se = se[o])
  expect_identical(flag_presentation(r)$presentation[o],
                   flag_presentation(e)$presentation)
})

test_that("it judges estimates of the package and keeps their log", {
  x <- es_result()
  e <- estimate_households(es_design(), x, "p", ci_method = "korn_graubard")
  f <- flag_presentation(e)
  expect_s3_class(f, "hces_estimate")
  expect_identical(f$presentation_reason, rep("sample_size", 2))
  expect_true(all(audit_log(e)$cause %in% audit_log(f)$cause))
})
