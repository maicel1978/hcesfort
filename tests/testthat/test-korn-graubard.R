# estimate_households(ci_method = "korn_graubard") and the column
# ci_method (12d.3, C2 of docs/design-reports-v3.md; tests U11 and U12 of
# its section 3.4). References: survey::svyciprop(method = "beta"),
# stats::binom.test() and the published rows of the NCHS standards
# (helper-nchs.R). Fixtures: the 8-household design of test-estimate.R
# (es_design(), es_result(), ref_design()) and a design of equal weights.

test_that("korn_graubard equals svyciprop(beta) where the cap does not bind", {
  x <- es_result()
  for (s in c("base", "fort")) {
    y <- x$p[x$scenario == s]
    sub <- ref_design(y, rep(TRUE, 8))
    r <- survey::svyciprop(~y, sub, method = "beta")
    p <- as.vector(stats::coef(r))
    v <- as.vector(attr(r, "var"))
    n <- nrow(sub)
    adj <- (stats::qt(0.025, n - 1) / stats::qt(0.025, survey::degf(sub)))^2
    expect_lt(p * (1 - p) / v * adj, n)
    e <- pick_est(estimate_households(es_design(), x, "p",
                                      ci_method = "korn_graubard"), s)
    expect_equal(e$estimate, p, tolerance = 1e-8)
    expect_equal(e$se, sqrt(v), tolerance = 1e-8)
    expect_equal(c(e$ci_low, e$ci_high), unname(attr(r, "ci")),
                 tolerance = 1e-8)
    expect_identical(e$ci_method, "korn_graubard")
  }
})

test_that("with variance p(1 - p) / n the interval is the exact binomial", {
  n <- 12
  for (x in 0:n) {
    p <- x / n
    ci <- korn_graubard_interval(p, sqrt(p * (1 - p) / n), n, n - 1, 0.95)
    ref <- stats::binom.test(x, n)$conf.int
    expect_equal(ci, as.vector(ref), tolerance = 1e-8)
  }
})

test_that("0 and n events give the Clopper-Pearson interval on n", {
  h <- data.frame(household_id = 1:12, weight = 5, stratum = 1,
                  psu = 1:12, region = "a")
  d <- as_hces_design(h, lonely_psu = "adjust")
  x <- new_hces_tbl(data.frame(household_id = 1:12, none = 0, all = 1),
                    "hces_inadequacy", key = "household_id")
  for (v in c("none", "all")) {
    e <- estimate_households(d, x, v, ci_method = "korn_graubard")
    ref <- stats::binom.test(sum(x[[v]]), 12)$conf.int
    expect_equal(c(e$ci_low, e$ci_high), as.vector(ref), tolerance = 1e-8)
    expect_identical(e$se, 0)
    log <- audit_log(e)
    expect_identical(log$n_records[log$cause == "degenerate_proportion"], 1L)
  }
})

test_that("the published NCHS limits are reproduced within 0.15 point", {
  t <- nchs_published_rows()
  ci <- t(mapply(function(p, se, n, df) {
    100 * korn_graubard_interval(p / 100, se / 100, n, df, 0.95)
  }, t$percent, t$se, t$n, t$df))
  expect_true(all(abs(ci[, 1] - t$lower) <= 0.15))
  expect_true(all(abs(ci[, 2] - t$upper) <= 0.15))
  expect_identical(nrow(t), 16L)
})

test_that("the cap at n widens the interval, never narrows it", {
  x <- es_result()
  kg <- estimate_households(es_design(), x, "p", ci_method = "korn_graubard")
  beta <- estimate_households(es_design(), x, "p", ci_method = "beta")
  expect_true(all(kg$ci_low <= beta$ci_low + 1e-12))
  expect_true(all(kg$ci_high >= beta$ci_high - 1e-12))
  # A variance far below the binomial one: the cap binds.
  capped <- korn_graubard_interval(0.3, 0.001, 50, 49, 0.95)
  expect_equal(capped, as.vector(stats::binom.test(15, 50)$conf.int),
               tolerance = 1e-8)
})

test_that("the interval holds the estimate, stays in [0, 1], undefined cases", {
  for (p in c(0, 0.01, 0.2, 0.5, 0.97, 1)) {
    for (se in c(0, 0.005, 0.05, 0.2)) {
      ci <- korn_graubard_interval(p, se, 40, 6, 0.95)
      expect_true(ci[[1]] >= 0 && ci[[2]] <= 1)
      expect_true(ci[[1]] <= p && p <= ci[[2]])
    }
  }
  na2 <- c(NA_real_, NA_real_)
  expect_identical(korn_graubard_interval(0.2, 0.1, 1, 1, 0.95), na2)
  expect_identical(korn_graubard_interval(0.2, 0.1, 10, 0, 0.95), na2)
  expect_identical(korn_graubard_interval(NA, 0.1, 10, 3, 0.95), na2)
  expect_identical(korn_graubard_interval(0.2, NA, 10, 3, 0.95), na2)
})

test_that("korn_graubard does not depend on row order and honours df", {
  x <- es_result()
  e <- estimate_households(es_design(), x, "p", ci_method = "korn_graubard",
                           by = "region")
  h <- es_households()[8:1, ]
  d <- as_hces_design(h, lonely_psu = "adjust")
  r <- estimate_households(d, x[16:1, ], "p", ci_method = "korn_graubard",
                           by = "region")
  r <- r[match(paste(e$scenario, e$region), paste(r$scenario, r$region)), ]
  expect_equal(r$ci_low, e$ci_low, tolerance = 1e-12)
  expect_equal(r$ci_high, e$ci_high, tolerance = 1e-12)
  big <- estimate_households(es_design(), x, "p", ci_method = "korn_graubard",
                             df = Inf)
  small <- estimate_households(es_design(), x, "p",
                               ci_method = "korn_graubard")
  expect_true(all(big$ci_high - big$ci_low <= small$ci_high - small$ci_low))
})

test_that("every hces_estimate names its interval method", {
  x <- es_result()
  d <- es_design()
  pr <- estimate_households(d, x, "p")
  me <- estimate_households(d, x, "intake", statistic = "mean")
  md <- estimate_households(d, x, "intake", statistic = "median")
  df <- estimate_difference(d, x, "intake", reference = "base")
  expect_identical(unique(pr$ci_method), "logit")
  expect_identical(unique(me$ci_method), "t")
  expect_identical(unique(md$ci_method), "woodruff")
  expect_identical(unique(df$ci_method), "t")
  expect_identical(names(pr)[match("ci_method", names(pr)) + -1:1],
                   c("ci_high", "ci_method", "conf_level"))
  expect_error(estimate_households(d, x, "p", ci_method = "kg"),
               class = "hcesfort_error_argument")
})
