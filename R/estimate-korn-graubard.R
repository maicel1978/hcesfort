# Korn-Graubard interval of a proportion, as the NCHS data presentation
# standards for proportions use it (Parker et al. 2017, Vital Health Stat
# 2(175), pages 3 to 4 and the footnotes of Tables I and II, pages 8 to 9).
# Design: C2 of docs/design-reports-v3.md.

# Korn-Graubard limits of a proportion `p` with standard error `se`,
# estimated on `n` households with `df` degrees of freedom. The effective
# sample size p (1 - p) / se^2 is multiplied by (t(n - 1) / t(df))^2 and
# capped at `n`; the limits are the Clopper-Pearson limits on that size.
# A standard error of 0 (variance-free) gives the size `n`. Undefined (NA)
# when `n` < 2, `df` is not positive or `p` or `se` is missing.
korn_graubard_interval <- function(p, se, n, df, level) {
  if (is.na(p) || is.na(se) || is.na(df) || n < 2 || df <= 0) {
    return(c(NA_real_, NA_real_))
  }
  alpha <- 1 - level
  n_e <- if (se > 0) p * (1 - p) / se^2 else n
  n_e <- n_e * (stats::qt(alpha / 2, n - 1) / stats::qt(alpha / 2, df))^2
  n_e <- min(n_e, n)
  clopper_pearson(n_e * p, n_e, level)
}

# Clopper-Pearson limits for `x` events out of `n`; both may be
# non-integer, as effective sizes are. The lower limit is 0 without events
# and the upper limit 1 when every household has the event.
clopper_pearson <- function(x, n, level) {
  alpha <- 1 - level
  low <- if (x <= 0) 0 else stats::qbeta(alpha / 2, x, n - x + 1)
  high <- if (x >= n) 1 else stats::qbeta(1 - alpha / 2, x + 1, n - x)
  c(low, high)
}
