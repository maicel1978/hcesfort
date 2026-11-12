#' Households below a nutrient requirement
#'
#' For each household, scenario and nutrient, whether the apparent intake
#' per adult female equivalent (AFE) is below the requirement of the
#' reference person, as a number between 0 and 1. The result estimates
#' nothing: the share of households below the requirement, its interval and
#' the differences between scenarios are computed with the survey design in
#' a later step. The numbers describe households, not persons: the intake is
#' apparent, and it is shared within the household in proportion to energy
#' requirements, while nutrient requirements do not scale with energy.
#'
#' **Cut-point.** For the nutrients of `requirements` with an `ear`,
#' `p_inadequate` is 1 when the intake is below the EAR and 0 otherwise
#' (strict comparison: an intake equal to the EAR is adequate).
#'
#' **Probability approach.** For the nutrients named in `distribution` the
#' cut-point is not valid (their requirement is skewed) and the caller gives
#' the percentiles of the requirement for one group: a table with
#' `percentile`, the requirement per day in the registry unit (column
#' `requirement_<unit>_d`, for example `requirement_mg_d`) and the
#' `bioavailability` `b0` the requirement assumes ([ref_iron_requirements]
#' has this form; filter one group). For a diet of bioavailability `b`, the
#' intake is compared on absorbed amounts: `intake * b / b0`, and
#' `p_inadequate = 1 - F(intake * b / b0)`, where `F` is the distribution
#' function of the tabulated requirement, interpolated linearly between
#' percentiles. Beyond the table the probability is 1 below the lowest
#' percentile and 0 above the highest: a convention, since the source does
#' not tabulate the tails (the jump at each end is the share outside the
#' table). One `b` applies to the whole intake, baseline and added.
#' `bioavailability` has no default; several values give several rows.
#'
#' **Coverage.** `min_coverage` is required. For each nutrient assessed, the
#' share of the edible grams of the estimated households that carry a
#' composition value (weighted by AFE, unweighted by survey weights, on the
#' baseline) must reach it, otherwise the call fails with
#' `hcesfort_error_coverage`: a share below a requirement computed with
#' much of the grams missing is a different quantity. `0` accepts any
#' coverage and says so in the log. The coverage of each household is
#' returned, so a domain can be defined on it.
#'
#' @param x Table returned by [apply_scenario()] or [apparent_intake()].
#' @param requirements A table with one row per nutrient: `nutrient`, `unit`
#'   (the registry unit) and `ear`, such as one group of
#'   [ref_requirements]. Several rows for a nutrient are an
#'   `hcesfort_error_key`: select the group first.
#' @param distribution `NULL`, or a named list of requirement distributions,
#'   one per nutrient of the registry assessed by the probability approach.
#' @param bioavailability Named list of one or more values in (0, 1] per
#'   nutrient of `distribution`; required with it.
#' @param min_coverage Minimum share of grams with a value, in `[0, 1]`.
#' @returns A tibble of class `hces_inadequacy` (and `hces_tbl`), long, key
#'   `scenario` + `household_id` + `nutrient` + `bioavailability`:
#'   `scenario` (missing for an `hces_intake`), `household_id`,
#'   `intake_status`, `nutrient`, `unit`, `intake`, `added`, `coverage`,
#'   `method` (`"ear_cutpoint"` or `"probability"`), `ear`,
#'   `bioavailability` and `p_inadequate` (missing when the household is not
#'   `estimated`).
#' @seealso `above_ul()`, [apply_scenario()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' baseline <- unfortified_baseline(hces_example$composition,
#'                                  hces_example$enrichment, nutrients)
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' content <- link_composition(grams, hces_example$crosswalk, baseline)
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' intake <- apparent_intake(content, afe, hces_example$households)
#' iron <- subset(ref_iron_requirements,
#'                group == "females_menstruating_adult")
#' risk <- inadequacy(intake, ref_requirements,
#'                    distribution = list(iron = iron),
#'                    bioavailability = list(iron = c(0.10, 0.18)),
#'                    min_coverage = 0.8)
#' aggregate(p_inadequate ~ nutrient + bioavailability, risk, mean,
#'           na.action = na.pass)
#' @export
inadequacy <- function(x, requirements, distribution = NULL,
                       bioavailability = NULL, min_coverage) {
  require_hces(x, c("hces_intake", "hces_scenario_intake"))
  x <- audit_check_rows(x, "inadequacy")
  nutrients <- attr(x, "nutrients", exact = TRUE)
  min_coverage <- check_min_coverage(min_coverage)
  req <- check_requirements(requirements, nutrients, "ear")
  dist <- check_distribution(distribution, bioavailability, nutrients)
  cut <- setdiff(req$nutrient, names(dist))
  assessed <- c(cut, names(dist))
  cov <- check_coverage(x, nutrients, assessed, min_coverage)
  rows <- c(
    lapply(cut, function(n) {
      cutpoint_rows(x, nutrients, n, req$ear[req$nutrient == n])
    }),
    lapply(names(dist), function(n) {
      probability_rows(x, nutrients, n, dist[[n]], bioavailability[[n]])
    })
  )
  if (length(rows) == 0) {
    rows <- list(cutpoint_rows(x[0, ], nutrients, nutrients$nutrient[[1]],
                               NA_real_))
  }
  out <- dplyr::bind_rows(rows)
  log <- inadequacy_log(x, req, dist, bioavailability, cov, out, nutrients,
                        min_coverage)
  new_hces_tbl(out, "hces_inadequacy", dplyr::bind_rows(audit_get(x), log),
               c("scenario", "household_id", "nutrient", "bioavailability"),
               nutrients)
}

# The columns every row of the result shares, for nutrient `n` of `x`.
risk_base <- function(x, nutrients, n) {
  col <- nutrients$column[nutrients$nutrient == n]
  ok <- x$intake_status == "estimated"
  added <- x[[paste0(col, "_added")]]
  if (is.null(added)) added <- ifelse(ok, 0, NA_real_)
  scenario <- x[["scenario"]]
  if (is.null(scenario)) scenario <- rep(NA_character_, nrow(x))
  dplyr::tibble(
    scenario = scenario, household_id = x$household_id,
    intake_status = x$intake_status, nutrient = n,
    unit = nutrients$unit[nutrients$nutrient == n], intake = x[[col]],
    added = added, coverage = x[[paste0(col, "_coverage")]]
  )
}

# Cut-point rows of nutrient `n`.
cutpoint_rows <- function(x, nutrients, n, ear) {
  out <- risk_base(x, nutrients, n)
  out$method <- "ear_cutpoint"
  out$ear <- ear
  out$bioavailability <- NA_real_
  out$p_inadequate <- ifelse(out$intake_status == "estimated",
                             as.numeric(out$intake < ear), NA_real_)
  out
}
