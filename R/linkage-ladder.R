#' Linkage ladder: how far the included records get towards a nutrient
#'
#' Follow the records the adapter's rule includes through the steps that
#' lead to a nutrient value, each step a subset of the one before, and
#' give the share kept at each step by records, by grams and by
#' expenditure. It is the third section of the data readiness report.
#'
#' The steps, on the records with `include = TRUE`:
#'
#' - `records`: included by the adapter's rule;
#' - `with_quantity`: with a quantity and a unit;
#' - `with_grams`: converted to grams ([convert_units()]);
#' - `matched`: with grams, of a food with a composition match, validated
#'   or not;
#' - `validated`: linked, a validated match with an edible portion
#'   ([link_composition()]).
#'
#' `share_records` is unweighted, over the first step: the measure that
#' `min_records_used` of [inadequacy()] uses. `share_grams` is the weighted
#' grams per day as acquired over those of the included records with
#' grams; it is missing for the first two steps, where grams are unknown.
#' `share_expenditure` is the weighted expenditure per day
#' (`expenditure_lcu * household_share / period_days`) over that of the
#' included records with an expenditure; records with a missing
#' `expenditure_lcu` count in neither. Weights are the household weights of
#' `households`.
#'
#' @param x Table returned by [link_composition()] (or [fill_composition()]).
#' @param households Households table ([hces_schema()]`("households")`); it
#'   must contain every household of `x`.
#' @returns A tibble with one row per step, in the order above: `step`,
#'   `n_records`, `n_households` (with at least one record at the step),
#'   `share_records`, `share_grams` and `share_expenditure` (`NA` when
#'   `x` has no column `expenditure_lcu`). Shares are `NA` when their
#'   denominator is 0.
#' @seealso [unmatched_foods()] for the foods behind each loss.
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition,
#'   nutrients = nutrient_registry(hces_example$nutrients)
#' )
#' linkage_ladder(content, hces_example$households)
#' @export
linkage_ladder <- function(x, households) {
  check_required()
  require_hces(x, "hces_nutrient_content")
  h <- validate_households(households)
  m <- record_measures(x, h)
  steps <- c("records", "with_quantity", "with_grams", "matched",
             "validated")
  flags <- lapply(c("included", steps[-1]), function(s) m[[s]])
  ratio <- function(num, den) if (den > 0) num / den else NA_real_
  has_exp <- !is.na(m$expenditure_w)
  den_g <- sum(m$grams_w[m$with_grams])
  den_e <- sum(m$expenditure_w[m$included & has_exp])
  n_first <- sum(m$included)
  rows <- lapply(seq_along(steps), function(i) {
    f <- flags[[i]]
    dplyr::tibble(
      step = steps[[i]],
      n_records = sum(f),
      n_households = length(unique(m$household_id[f])),
      share_records = ratio(sum(f), n_first),
      share_grams = if (i < 3) NA_real_ else ratio(sum(m$grams_w[f]), den_g),
      share_expenditure = if (has_expenditure(x)) {
        ratio(sum(m$expenditure_w[f & has_exp]), den_e)
      } else {
        NA_real_
      }
    )
  })
  dplyr::bind_rows(rows)
}
