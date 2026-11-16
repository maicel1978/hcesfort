#' Minimum quantity and quality of the data, with their thresholds
#'
#' The second section of the data readiness report (DR2): the status of
#' every household, the records lost before grams, and each threshold the
#' analysis depends on, with its value and whether it is met.
#'
#' | `check` | `detail` | Threshold |
#' |---|---|---|
#' | `household_status` | each `intake_status` of [apparent_intake()] | none |
#' | `records_without_quantity` | | none |
#' | `records_without_grams` | | none |
#' | `records_used` | | `min_records_used` |
#' | `composition_value` | each nutrient of `nutrients` | `min_coverage` |
#' | `linked_grams` | | `min_linked_share` |
#' | `linked_expenditure` | | `min_linked_share` |
#' | `domain_cells` | each domain of `domains` | `max_small_cells` |
#'
#' `records_used` and `composition_value` are computed by the functions
#' [inadequacy()] and [above_ul()] use, so `met` is `FALSE` exactly when
#' those would fail with `hcesfort_error_coverage` for that measure (a
#' missing value does not fail them, and `met` is then missing).
#' `linked_grams` and `linked_expenditure` are the last step of the
#' linkage ladder; `linked_expenditure` is missing without the column
#' `expenditure_lcu`.
#'
#' `domain_cells` (DR11) has `n` the number of values of the domain in
#' `households`, and `value` the share of them with fewer than `min_n`
#' households whose intake is estimated (`intake_status == "estimated"`);
#' it is met when `value` is at most `max_small_cells`, the one check met
#' from below. The effective sample size cannot be used: it is known only
#' once an estimate exists. A missing value of the domain is one more
#' value, as in the cells of [estimate_households()]. A domain column
#' absent from `households` gives missing `value` and `met`;
#' [readiness_verdict()] disables that domain as a missing input.
#'
#' @param intake Table returned by [apparent_intake()] on the baseline.
#' @param ladder Table returned by [linkage_ladder()].
#' @param nutrients Registry names of the nutrients the results report
#'   assesses (`nutrient` of [nutrient_registry()]).
#' @param min_records_used,min_coverage As in [inadequacy()].
#' @param min_linked_share Minimum share of the included grams and of the
#'   included expenditure that is linked to the composition table. No
#'   default.
#' @param households The households table the intake was computed from,
#'   with the domain columns.
#' @param domains `NULL` or the names of the domain columns of
#'   `households`.
#' @param min_n Smallest number of households with an estimated intake a
#'   value of a domain needs (the `min_n` of [ref_presentation_standard]).
#'   No default.
#' @param max_small_cells Largest share of the values of a domain that may
#'   fall below `min_n`. No default.
#' @returns A tibble: `check`, `detail` (`NA` when the check has one row),
#'   `n` (households or records; `NA` for `composition_value`), `value` (a
#'   share), `threshold` and `met` (both `NA` for rows without a
#'   threshold).
#' @seealso [readiness_inventory()], [readiness_verdict()].
#' @examples
#' e <- hces_example
#' nutrients <- nutrient_registry(e$nutrients)
#' grams <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
#' content <- link_composition(grams, e$crosswalk, e$composition, nutrients)
#' afe <- adult_equivalents(
#'   e$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' intake <- apparent_intake(content, afe, e$households)
#' readiness_checks(intake, linkage_ladder(content, e$households),
#'                  c("iron", "folate", "vitamin_a"),
#'                  min_records_used = 0.8, min_coverage = 0.9,
#'                  min_linked_share = 0.9, households = e$households,
#'                  domains = "region", min_n = 30, max_small_cells = 0.5)
#' @export
readiness_checks <- function(intake, ladder, nutrients, min_records_used,
                             min_coverage, min_linked_share, households,
                             domains, min_n, max_small_cells) {
  check_required()
  require_hces(intake, "hces_intake")
  min_used <- check_min_records_used(min_records_used)
  min_cov <- check_min_coverage(min_coverage)
  min_link <- check_share_arg(min_linked_share, "min_linked_share",
                              "linked share")
  check_ladder(ladder)
  registry <- attr(intake, "nutrients", exact = TRUE)
  check_assessed(nutrients, registry)
  check_domain_cell_args(min_n, max_small_cells)
  check_domains_arg(domains, households)
  step <- function(s, col) ladder[[col]][ladder$step == s]
  n_inc <- step("records", "n_records")
  lost <- function(s) n_inc - step(s, "n_records")
  cov <- nutrient_coverage(intake, registry, nutrients)
  dplyr::bind_rows(
    status_checks(intake),
    check_row("records_without_quantity", NA, lost("with_quantity"),
              lost("with_quantity") / n_inc),
    check_row("records_without_grams", NA, lost("with_grams"),
              lost("with_grams") / n_inc),
    check_row("records_used", NA, sum(intake$n_records_used),
              overall_records_used(intake)[["records"]], min_used),
    check_row("composition_value", nutrients, NA, unname(cov), min_cov),
    check_row("linked_grams", NA, step("validated", "n_records"),
              step("validated", "share_grams"), min_link),
    check_row("linked_expenditure", NA, step("validated", "n_records"),
              step("validated", "share_expenditure"), min_link),
    domain_cell_checks(intake, households, domains, min_n, max_small_cells)
  )
}

# Rows of one check; `met` is missing without threshold or value.
check_row <- function(check, detail, n, value, threshold = NA_real_) {
  value <- ifelse(is.nan(value), NA_real_, value)
  dplyr::tibble(
    check = check, detail = as.character(detail), n = as.integer(n),
    value = as.numeric(value), threshold = threshold,
    met = ifelse(is.na(value) | is.na(threshold), NA, value >= threshold)
  )
}

# One row per household status, in the order of apparent_intake().
status_checks <- function(intake) {
  levels <- c("food_module_nonresponse", "no_food_records",
              "all_records_lost", "no_afe", "estimated")
  n <- vapply(levels, function(s) sum(intake$intake_status == s),
              numeric(1))
  check_row("household_status", levels, n, n / nrow(intake))
}

# Abort unless `ladder` has the columns and steps of linkage_ladder().
check_ladder <- function(ladder, call = rlang::caller_env()) {
  cols <- c("step", "n_records", "share_grams", "share_expenditure")
  steps <- c("records", "with_quantity", "with_grams", "validated")
  if (!is.data.frame(ladder) || !all(cols %in% names(ladder)) ||
        !all(steps %in% ladder$step)) {
    abort_hcesfort("schema", c(
      "{.arg ladder} must be the table returned by {.fn linkage_ladder}."
    ), table = "ladder", columns = cols, call = call)
  }
  invisible(TRUE)
}

# Abort unless `nutrients` are registry names of `registry`.
check_assessed <- function(nutrients, registry, call = rlang::caller_env()) {
  if (!is.character(nutrients) || length(nutrients) == 0 ||
        !all(nutrients %in% registry$nutrient)) {
    abort_hcesfort("argument", c(
      "{.arg nutrients} must be registry names of the intake.",
      "i" = "Known: {.val {registry$nutrient}}."
    ), arg = "nutrients", call = call)
  }
  invisible(TRUE)
}
