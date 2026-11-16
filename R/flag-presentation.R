#' Flag estimates by the NCHS data presentation standards
#'
#' Judge each estimate by the National Center for Health Statistics data
#' presentation standards for proportions (Parker et al. 2017), with the
#' thresholds of `standard`. Detection only: nothing is removed; a report
#' decides what each status does.
#'
#' Proportions (`statistic == "proportion"`) follow the flow chart of the
#' standards (Appendix I, p. 7), in this order. Suppress when: the number
#' of households `n` is below `min_n` (`"sample_size"`); the effective
#' sample size is below `min_n_effective` (`"effective_sample_size"`); the
#' absolute width of the interval is `large_absolute_width` or more
#' (`"absolute_width"`); the width is above `small_absolute_width` and the
#' relative width (width divided by the proportion) above
#' `max_relative_width` (`"relative_width"`). Otherwise, review when: the
#' proportion is exactly 0 or 1, that is 0 or `n` events (`"zero_events"`);
#' the degrees of freedom are below `min_df` (`"degrees_of_freedom"`).
#' Otherwise present. A proportion of 0 has an infinite relative width, so
#' it is suppressed unless its interval is narrow, as the flow chart does.
#' Means of probabilities (the iron probability approach) are judged as
#' proportions. The width criteria are then conservative, since the
#' variance of a probability is at most that of a 0/1 outcome. The
#' effective sample size is the one the standards define, `n` divided by
#' the design effect: the column `n_effective` of [estimate_households()],
#' computed from the variance of the values themselves, so a mean of
#' probabilities is not credited with the size of a 0/1 outcome. A table
#' without that column (built by hand) gets \eqn{p(1 - p) / se^2}, which
#' is the same for a 0/1 outcome.
#'
#' The standards judge the 95% Korn-Graubard interval and no other, so
#' every proportion must come from
#' `estimate_households(ci_method = "korn_graubard")` at the `conf_level`
#' of `standard`.
#'
#' The standards give no thresholds for means, medians, differences or
#' shares (p. 5). For them only `sample_size` (suppress) and
#' `degrees_of_freedom` (review) apply, and the interval is always shown.
#'
#' An estimate that is missing although `n` reaches `min_n` (a share whose
#' total is zero) has no status (`NA`) and is counted in the log
#' (`presentation_undefined`). A proportion whose interval is undefined
#' (no degrees of freedom) is judged on its sizes and degrees of freedom.
#'
#' @param estimates A table returned by [estimate_households()],
#'   [estimate_difference()], [food_group_shares()] or
#'   [estimate_unlinked()].
#' @param standard The thresholds: [ref_presentation_standard] or a
#'   modified copy, with the columns `criterion` and `value` and one row
#'   per criterion.
#' @returns `estimates` with the columns `n_effective` (proportions: as
#'   given by [estimate_households()], else \eqn{p(1 - p) / se^2}, capped
#'   at `n`; `n` when `se` is 0; `NA` for other statistics),
#'   `ci_width`, `ci_relative_width` (proportions: width divided by the
#'   estimate), `presentation` (`"present"`, `"review"` or `"suppress"`),
#'   `presentation_reason` (the first criterion that applies; `NA` when
#'   presented) and `complement_unreliable` (proportions: `TRUE` when the
#'   complement, one minus the proportion, fails the relative width
#'   criterion; the standards present the proportion with a footnote).
#'   Its audit log counts each status and each reason.
#' @seealso [ref_presentation_standard], [estimate_households()].
#' @examples
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households, fortifiable = "use")
#' design <- as_hces_design(hces_example$households, lonely_psu = "adjust")
#' est <- estimate_households(design, use, "acquired", by = "region",
#'                            ci_method = "korn_graubard")
#' flag_presentation(est)[c("vehicle", "region", "estimate", "presentation",
#'                          "presentation_reason")]
#' @export
flag_presentation <- function(estimates,
                              standard = hcesfort::ref_presentation_standard) {
  check_required()
  require_hces(estimates, "hces_estimate")
  x <- audit_check_rows(estimates, "flag_presentation")
  s <- standard_values(standard)
  check_presentation_input(x, s)
  prop <- x$statistic %in% "proportion"
  out <- dplyr::as_tibble(x)
  out$n_effective <- effective_size(x, prop)
  out$ci_width <- x$ci_high - x$ci_low
  out$ci_relative_width <- ifelse(prop, out$ci_width / x$estimate, NA_real_)
  reason <- presentation_reason(out, prop, s)
  out$presentation <- presentation_status(reason, out$estimate, x$n, s)
  out$presentation_reason <- reason
  out$complement_unreliable <- ifelse(
    prop, relative_fails(out$ci_width, 1 - x$estimate, s), NA
  )
  log <- presentation_log(out, s)
  same_carrier(out, x, dplyr::bind_rows(audit_get(x), log))
}

# Effective sample size of the proportions: the column n_effective of the
# estimators when present (n over the design effect, P164); else
# p (1 - p) / se^2 capped at n, and n when se is 0 (0 or n events; NCHS
# 2017, p. 3). NA elsewhere.
effective_size <- function(x, prop) {
  p <- x$estimate
  n_e <- if (!is.null(x[["n_effective"]])) x$n_effective else
    ifelse(x$se %in% 0, x$n, p * (1 - p) / x$se^2)
  ifelse(prop, pmin(n_e, x$n), NA_real_)
}

# TRUE where the width is above the small width and width / p above the
# largest relative width (the relative width criterion; p = 0 gives an
# infinite relative width).
relative_fails <- function(width, p, s) {
  !is.na(width) & width > s$small_absolute_width &
    width / p > s$max_relative_width
}

# The first criterion that applies to each estimate, in the order of the
# flow chart: the suppress criteria, then the review criteria. Criteria
# that need a missing value do not apply.
presentation_reason <- function(out, prop, s) {
  w <- out$ci_width
  tests <- list(
    sample_size = out$n < s$min_n,
    effective_sample_size = prop & out$n_effective < s$min_n_effective,
    absolute_width = prop & w >= s$large_absolute_width,
    relative_width = prop & relative_fails(w, out$estimate, s),
    zero_events = prop & out$estimate %in% c(0, 1),
    degrees_of_freedom = out$df < s$min_df
  )
  reason <- rep(NA_character_, nrow(out))
  for (k in rev(names(tests))) reason[tests[[k]] %in% TRUE] <- k
  reason
}

# The status of each reason; NA for a missing estimate with n >= min_n.
presentation_status <- function(reason, estimate, n, s) {
  suppress <- c("sample_size", "effective_sample_size", "absolute_width",
                "relative_width")
  status <- ifelse(is.na(reason), "present",
                   ifelse(reason %in% suppress, "suppress", "review"))
  status[is.na(estimate) & n >= s$min_n] <- NA_character_
  status
}
