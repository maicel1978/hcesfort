# Helpers of estimate_unlinked(). Design: docs/design-reports-v2.md,
# section 5.2.

# Abort unless `x` has what `measure` needs.
check_unlinked_measure <- function(x, measure, call = rlang::caller_env()) {
  if (measure == "expenditure" && !has_expenditure(x)) {
    abort_hcesfort("argument", c(
      "{.code measure = \"expenditure\"} needs the column
      {.field expenditure_lcu} in the acquisitions.",
      "i" = "Use {.code measure = \"grams\"} or {.code \"records\"}."
    ), arg = "measure", call = call)
  }
  invisible(TRUE)
}

# Household totals aligned with the design: `num`, the measure of the
# included records not linked, and `den`, that of all included records
# with the measure (0 for a household without records).
household_unlinked <- function(design, x, measure,
                               call = rlang::caller_env()) {
  m <- record_measures(x, design$variables, call = call)
  amount <- switch(measure,
    grams = ifelse(m$with_grams, x$qty_g_d, 0),
    records = as.numeric(m$included),
    expenditure = ifelse(m$included & !is.na(m$expenditure_d),
                         m$expenditure_d, 0)
  )
  ids <- design$variables$household_id
  total <- function(v) {
    s <- rowsum(v, factor(x$household_id, levels = unique(ids)),
                reorder = FALSE)
    out <- s[match(as.character(ids), rownames(s)), 1]
    ifelse(is.na(out), 0, unname(out))
  }
  list(num = total(amount * !m$validated), den = total(amount))
}

# One row of estimate_unlinked(): the share of the cell `mask`, and when
# `compare`, the rest of the population and the difference.
unlinked_cell <- function(design, h, mask, level, df, compare) {
  r <- ratio_cell(design, h$num, h$den, mask, df)
  y <- h$num[mask]
  t <- h$den[mask]
  if (!is.na(r$estimate) && (all(y == 0) || all(y == t))) {
    r$estimate <- if (all(y == 0)) 0 else 1
    r$se <- 0
  }
  ci <- logit_interval(r$estimate, r$se, level, r$df)
  out <- dplyr::tibble(
    estimate = r$estimate, se = r$se, ci_low = ci[[1]], ci_high = ci[[2]],
    conf_level = level, df = r$df, n = r$n, n_missing = 0L,
    rest_estimate = NA_real_, difference = NA_real_,
    difference_ci_low = NA_real_, difference_ci_high = NA_real_,
    differs = NA
  )
  if (!compare) {
    return(out)
  }
  out$rest_estimate <- ratio_cell(design, h$num, h$den, !mask, df)$estimate
  d <- unlinked_contrast(design, h, mask, level)
  out$difference <- d[[1]]
  out$difference_ci_low <- d[[2]]
  out$difference_ci_high <- d[[3]]
  out$differs <- d[[2]] > 0 | d[[3]] < 0
  out
}

# Share of the cell `inside` minus that of the other households, with a t
# interval on the design degrees of freedom: the delta method on four
# weighted totals. `NA` when either side has a zero total.
unlinked_contrast <- function(design, h, inside, level) {
  w <- stats::weights(design)
  if (sum(w * h$den * inside) == 0 || sum(w * h$den * !inside) == 0) {
    return(rep(NA_real_, 3))
  }
  d <- stats::update(design, hcesfort_u1 = h$num * inside,
                     hcesfort_t1 = h$den * inside,
                     hcesfort_u0 = h$num * !inside,
                     hcesfort_t0 = h$den * !inside)
  tot <- with_lonely_psu(design, survey::svytotal(
    ~hcesfort_u1 + hcesfort_t1 + hcesfort_u0 + hcesfort_t0, d
  ))
  con <- survey::svycontrast(
    tot, quote(hcesfort_u1 / hcesfort_t1 - hcesfort_u0 / hcesfort_t0)
  )
  est <- unname(stats::coef(con))
  se <- unname(survey::SE(con))[[1]]
  t <- stats::qt(1 - (1 - level) / 2, survey::degf(design))
  c(est, est - t * se, est + t * se)
}

# Audit rows of estimate_unlinked().
unlinked_log <- function(design, df, out) {
  log <- shares_log(design, df, out, step = "estimate_unlinked")
  n <- sum(out$differs %in% TRUE)
  if (n == 0) {
    return(log)
  }
  dplyr::bind_rows(log, audit_row("estimate_unlinked", "estimate",
                                  "flagged", "differs_from_rest", n))
}
