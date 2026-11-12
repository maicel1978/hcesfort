#' Paired differences between scenarios
#'
#' Estimate, for each scenario and each group of a result table, the mean
#' of the within-household difference between the scenario and a reference
#' scenario, with its standard error and *t* interval, on the full design.
#' Because both values belong to the same household, the difference is
#' paired: its variance accounts for the correlation between scenarios,
#' which two separate intervals ignore. The domain is the households with a
#' value under both scenarios (and in `domain`, `by`).
#'
#' For a proportion (`p_inadequate`, `above_ul_total`), the mean difference
#' is the difference in prevalence between the two scenarios. No
#' `significant` column is returned: report the interval; multiplicity is
#' the reader's decision.
#'
#' @inheritParams estimate_prevalence
#' @param x A table with the column `scenario`, returned by [inadequacy()],
#'   [above_ul()] or [apply_scenario()].
#' @param reference Name of the reference scenario (for example
#'   `"baseline"`); required.
#' @returns A tibble of class `hces_estimate` (and `hces_tbl`): the group
#'   columns of `x`, `reference`, the `by` columns, `statistic`
#'   (`"mean_difference"`), `variable`, `estimate` (scenario minus
#'   reference), `se`, `ci_low`, `ci_high`, `conf_level`, `df`, `n` and
#'   `n_missing`.
#' @seealso [estimate_prevalence()].
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
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households)
#' s <- apply_scenario(intake, use, hces_example$scenarios,
#'                     compliance_model = "average_content")
#' risk <- inadequacy(s, ref_requirements, min_coverage = 0.8)
#' design <- as_hces_design(hces_example$households, lonely_psu = "adjust")
#' estimate_difference(design, risk, "p_inadequate", reference = "baseline")
#' @export
estimate_difference <- function(design, x, value, reference, by = NULL,
                                domain = NULL, level = 0.95,
                                df = "domain") {
  require_design(design)
  require_hces(x, "hces_tbl")
  check_reference_scenario(x, reference)
  args <- check_estimate_args(design, x, "mean", by, domain, "logit", level,
                              df)
  a <- align_values(design, x, value, args$x_domain)
  cells <- by_cells(design, by, args$design_domain)
  rest <- setdiff(names(a$keys), "scenario")
  other <- group_id(a$keys, rest)
  ref <- which(a$keys$scenario == reference)
  out <- lapply(which(a$keys$scenario != reference), function(k) {
    r <- ref[match(other[k], other[ref])]
    y <- if (is.na(r)) rep(NA_real_, nrow(a$values)) else
      a$values[, k] - a$values[, r]
    dplyr::bind_rows(lapply(seq_along(cells$masks), function(j) {
      est <- with_lonely_psu(design, estimate_cell(
        design, y, cells$masks[[j]], "mean", "logit", level, df
      ))
      dplyr::bind_cols(a$keys[k, ], dplyr::tibble(reference = reference),
                       cells$levels[j, ], est)
    }))
  })
  out <- dplyr::bind_rows(out)
  out$statistic <- rep("mean_difference", nrow(out))
  out$variable <- rep(value, nrow(out))
  log <- estimate_log("estimate_difference", design, x, value, "mean",
                      "logit", df, out)
  new_hces_tbl(out, "hces_estimate", dplyr::bind_rows(audit_get(x), log),
               c(names(a$keys), "reference", by))
}

# Abort unless `x` has scenarios and `reference` is one of them.
check_reference_scenario <- function(x, reference, call = rlang::caller_env()) {
  scenarios <- unique(x[["scenario"]])
  if (rlang::is_string(reference) && reference %in% scenarios) {
    return(invisible(TRUE))
  }
  abort_hcesfort("argument", c(
    "{.arg reference} must be one scenario of {.arg x}.",
    "i" = if (length(scenarios) > 0 && !all(is.na(scenarios))) {
      "Scenarios: {.val {scenarios}}."
    } else {
      "{.arg x} has no scenarios: build it from {.fn apply_scenario}."
    }
  ), arg = "reference", call = call)
}

#' Flag estimates of low precision
#'
#' Flag the estimates computed on few households or with a wide interval.
#' Nothing is removed: the flag is for reporting. The limits have no
#' default: the original ENGIH 2018 analysis used 50 households and a
#' half-width of 10 percentage points (0.10 for a proportion), without a
#' published source.
#'
#' @param estimates Table returned by [estimate_prevalence()] or
#'   [estimate_difference()].
#' @param min_n Smallest number of households in the domain (`n`).
#' @param max_half_width Largest half-width of the interval, in the unit of
#'   the estimate.
#' @returns `estimates` with the column `low_precision`: `TRUE` when `n` is
#'   below `min_n` or the half-width of the interval above
#'   `max_half_width`. The audit log counts the flagged estimates.
#' @seealso [estimate_prevalence()].
#' @examples
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households)
#' design <- as_hces_design(hces_example$households, lonely_psu = "adjust")
#' est <- estimate_prevalence(design, use, "acquired", by = "region")
#' flag_precision(est, min_n = 10, max_half_width = 0.10)
#' @export
flag_precision <- function(estimates, min_n, max_half_width) {
  require_hces(estimates, "hces_estimate")
  x <- audit_check_rows(estimates, "flag_precision")
  ok <- function(v) is.numeric(v) && length(v) == 1 && !is.na(v) && v >= 0
  if (missing(min_n) || missing(max_half_width) || !ok(min_n) ||
        !ok(max_half_width)) {
    abort_hcesfort("argument", c(
      "{.arg min_n} and {.arg max_half_width} must be two numbers >= 0.",
      "i" = "They have no default."
    ), arg = "min_n")
  }
  half <- (x$ci_high - x$ci_low) / 2
  out <- dplyr::as_tibble(x)
  out$low_precision <- x$n < min_n | (!is.na(half) & half > max_half_width)
  rule <- paste0("n < ", min_n, " or half-width > ", max_half_width)
  log <- audit_row("flag_precision", "estimate", "flagged", "low_precision",
                   sum(out$low_precision), detail = rule)
  same_carrier(out, x, dplyr::bind_rows(audit_get(x), log))
}
