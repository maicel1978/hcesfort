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
#' **What the figures are and are not.** Both methods are defined on the
#' *usual* intake of persons: "To accurately determine the proportion of a
#' group that has a usual intake of a nutrient less than the requirement,
#' information on both usual intakes and nutrient requirements for each
#' individual in the group is needed" (IOM 2000b, p. 73). The package
#' applies them to what a household acquired over `period_days`, per adult
#' equivalent, with no adjustment. Purchase frequency and stocks add
#' variance that usual intake does not have, and "the variance of the
#' estimated distribution will contain an unwanted day-to-day variability
#' component. Therefore, estimates of the prevalence of nutrient inadequacy
#' will be biased" (IOM 2000b, p. 99): the share below a fixed requirement
#' moves towards 50%, up when the requirement is below the median intake
#' and down when it is above. The cut-point "works well when: intakes are
#' accurately measured; actual prevalence in the group is neither very low
#' nor very high; estimated usual intakes of individuals are independent of
#' each individual's requirement; the distribution of requirements is
#' approximately symmetrical; variability in intakes among individuals in
#' the group is greater than the variability in requirements" (IOM 2000b,
#' p. 81, Box 4-1). The iron probabilities "may be used ... to evaluate
#' adjusted distributions of usual intakes ... Not to be applied in the
#' assessment of individuals" (IOM 2001, Table I-7, p. 703, footnote a). A
#' result is the share of households whose *apparent* intake is below the
#' requirement, a screening figure for comparing scenarios on the same
#' data, not a prevalence of inadequacy. The log says so for every call
#' (`apparent_intake_not_usual_intake`, with the range of `period_days` of
#' the records used).
#'
#' **Cut-point.** For the nutrients of `requirements` with an `ear`,
#' `p_inadequate` is 1 when the intake is below the EAR and 0 otherwise
#' (strict comparison: an intake equal to the EAR is adequate).
#'
#' **Where the cut-point is not valid.** `requirements` must have the
#' logical column `cutpoint_valid`. A nutrient with an `ear` and
#' `cutpoint_valid = FALSE` (its requirement is skewed: iron in
#' menstruating women, IOM 2000, *Applications in Dietary Assessment*,
#' pp. 81 and 91) must be given in `distribution`; otherwise the call fails
#' with `hcesfort_error_value`. There is no option to force the cut-point.
#' The optional column `ear_bioavailability`, the absorption the EAR
#' assumes, is written in the log for the cut-point nutrients that have
#' it; it rescales nothing. For a diet of lower absorption, pass a
#' requirements table derived for it.
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
#' percentile and 0 above the highest, the rule of the source: "a
#' probability of 1 has been assigned to all usual intakes falling below
#' the two and one-half percentile of requirement and a probability of 0
#' has been assigned to all usual intakes falling above the ninety-seven
#' and one-half percentile" (IOM 2001, Table I-7, p. 703, footnote d). The
#' jump at each end is the share outside the table; the households in the
#' tails are counted in the log (`tails_fixed`). One `b` applies to the
#' whole intake, baseline and added.
#' `bioavailability` has no default; several values give several rows.
#'
#' **Coverage.** `min_coverage` is required. For each nutrient assessed, the
#' share of the edible grams of the estimated households that carry a
#' composition value (weighted by AFE, unweighted by survey weights, on the
#' baseline) must reach it, otherwise the call fails with
#' `hcesfort_error_coverage`: a share below a requirement computed with
#' much of the grams missing is a different quantity. `0` accepts any
#' coverage and says so in the log. The coverage of each household is
#' returned, so a domain can be defined on it. Coverage is measured on the
#' records used: it does not see the records that never reached the sum.
#'
#' **What the coverage gate cannot see.** A linked record without a value
#' for a nutrient adds zero, so intake is understated: the share below a
#' requirement is overstated and the share above an upper level
#' understated. The size of the error is not known. The gate measures
#' grams, and for a nutrient concentrated in few foods (vitamin A, vitamin
#' B12) grams say little: three households with 400 g of rice a day (no
#' vitamin A) and 10 g of liver without a vitamin A value pass a gate of
#' 0.95 at 0.976, and every household is inadequate. [missing_values()]
#' lists, by nutrient, the foods without a value and their grams; read it
#' before any figure.
#'
#' **Record loss.** `min_records_used` is required. The share of the
#' included records that were used ([apparent_intake()],
#' `share_records_used`), over all households with at least one included
#' record whatever their status, unweighted, on the baseline, must reach
#' it; otherwise the call fails with `hcesfort_error_coverage` (field
#' `measure = "records_used"`). The share by purchased grams is reported
#' with it. `0` accepts any loss and says so in the log.
#'
#' @param x Table returned by [apply_scenario()] or [apparent_intake()].
#'   Under `compliance_model = "all_or_nothing"` of [apply_scenario()], the
#'   table of states: each state is assessed as a scenario, and
#'   `p_inadequate`, `intake` and `added` are the expectations over the
#'   states with the weights `state_probability` (the intake and the added
#'   amount equal those of average content); the log notes
#'   `states_collapsed`. The gates read the baseline, as always.
#' @param requirements A table with one row per nutrient: `nutrient`, `unit`
#'   (the registry unit), `ear` and `cutpoint_valid` (optionally
#'   `ear_bioavailability`), such as one group of
#'   [ref_requirements]. Several rows for a nutrient are an
#'   `hcesfort_error_key`: select the group first.
#' @param distribution `NULL`, or a named list of requirement distributions,
#'   one per nutrient of the registry assessed by the probability approach.
#' @param bioavailability Named list of one or more values in (0, 1] per
#'   nutrient of `distribution`; required with it.
#' @param min_coverage Minimum share of the edible grams used that have a
#'   composition value, in `[0, 1]`.
#' @param min_records_used Minimum overall share of the included records
#'   that were used, in `[0, 1]`.
#' @returns A tibble of class `hces_inadequacy` (and `hces_tbl`), long, key
#'   `scenario` + `household_id` + `nutrient` + `bioavailability`:
#'   `scenario` (missing for an `hces_intake`), `household_id`,
#'   `intake_status`, `nutrient`, `unit`, `intake`, `added`, `coverage`,
#'   `share_records_used`, `method` (`"ear_cutpoint"` or `"probability"`),
#'   `ear`, `bioavailability` and `p_inadequate` (missing when the household
#'   is not `estimated`).
#' @seealso [above_ul()], [apply_scenario()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' baseline <- unfortified_baseline(hces_example$composition,
#'                                  hces_example$enrichment, nutrients)
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' content <- link_composition(grams, hces_example$crosswalk, baseline)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' intake <- apparent_intake(content, afe, hces_example$households)
#' iron <- subset(ref_iron_requirements,
#'                group == "females_menstruating_adult")
#' risk <- inadequacy(intake, ref_requirements,
#'                    distribution = list(iron = iron),
#'                    bioavailability = list(iron = c(0.10, 0.18)),
#'                    min_coverage = 0.8, min_records_used = 0.6)
#' aggregate(p_inadequate ~ nutrient + bioavailability, risk, mean,
#'           na.action = na.pass)
#' @export
inadequacy <- function(x, requirements, distribution = NULL,
                       bioavailability = NULL, min_coverage,
                       min_records_used) {
  check_required()
  require_hces(x, c("hces_intake", "hces_scenario_intake",
                    "hces_scenario_states"))
  x <- audit_check_rows(x, "inadequacy")
  nutrients <- attr(x, "nutrients", exact = TRUE)
  min_coverage <- check_min_coverage(min_coverage)
  min_used <- check_min_records_used(min_records_used)
  check_cutpoint_columns(requirements)
  req <- check_requirements(requirements, nutrients, "ear")
  dist <- check_distribution(distribution, bioavailability, nutrients)
  check_cutpoint_valid(req, dist)
  cut <- setdiff(req$nutrient, names(dist))
  assessed <- c(cut, names(dist))
  used <- check_records_used(x, min_used)
  cov <- check_coverage(x, nutrients, assessed, min_coverage)
  key <- c("scenario", "household_id", "nutrient", "bioavailability")
  out <- collapse_states(
    inadequacy_rows(x, nutrients, req, cut, dist, bioavailability), key,
    c("intake", "added", "p_inadequate")
  )
  log <- inadequacy_log(x, req, dist, bioavailability, cov, out, nutrients,
                        min_coverage)
  log <- dplyr::bind_rows(log, records_used_row("inadequacy", x, used,
                                                min_used),
                          ear_bioavailability_rows(x, req, cut),
                          usual_intake_row("inadequacy", x),
                          states_collapsed_row("inadequacy", x))
  new_hces_tbl(out, "hces_inadequacy", dplyr::bind_rows(audit_get(x), log),
               key, nutrients)
}

# The rows of every nutrient assessed, by the cut-point (`cut`) or the
# probability approach (`dist`); an empty table of the same columns when
# none is assessed.
inadequacy_rows <- function(x, nutrients, req, cut, dist, bioavailability) {
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
  dplyr::bind_rows(rows)
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
    added = added, coverage = x[[paste0(col, "_coverage")]],
    share_records_used = x$share_records_used,
    state_probability = state_weights(x)
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
