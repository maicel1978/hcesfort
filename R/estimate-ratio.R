# Ratio of weighted totals on the survey design. Internal in v0.1: the
# public estimate_ratio() is P91/P98 of docs/improvements.md. Design:
# docs/design-food-group-shares.md, section 3.2 and decision 5.

# Ratio of the weighted totals of `num` and `den` over the households of
# the design where `inside` is TRUE (the others stay in the design, outside
# the domain). `num` and `den` are aligned with the design; their values
# outside the domain are ignored. Returns a list: estimate and se (NA when
# the domain is empty or the total of `den` is zero), df (by the rule of
# estimate_households()) and n.
ratio_cell <- function(design, num, den, inside, df) {
  num[!inside] <- 0
  den[!inside] <- 0
  d <- stats::update(design, .num = num, .den = den)
  sub <- d[inside, ]
  n <- sum(inside)
  dfv <- if (identical(df, "domain")) survey::degf(sub) else
    if (identical(df, "design")) survey::degf(design) else df
  out <- list(estimate = NA_real_, se = NA_real_, df = dfv, n = n)
  if (n == 0 || sum(stats::weights(sub) * den[inside]) == 0) return(out)
  r <- with_lonely_psu(design, survey::svyratio(~.num, ~.den, sub))
  out$estimate <- unname(stats::coef(r))
  out$se <- unname(survey::SE(r))[[1]]
  out
}

# Interval of a share on the logit scale by the delta method,
# logit(p) +/- t se / (p (1 - p)), back-transformed. A share of exactly 0
# or 1 (or a missing one), or a domain without degrees of freedom, has no
# interval.
logit_interval <- function(p, se, level, df) {
  if (is.na(p) || p <= 0 || p >= 1 || df <= 0) return(c(NA_real_, NA_real_))
  t <- stats::qt(1 - (1 - level) / 2, df)
  half <- t * se / (p * (1 - p))
  stats::plogis(stats::qlogis(p) + c(-half, half))
}
