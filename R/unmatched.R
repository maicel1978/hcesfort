#' Work queue: foods whose records are not linked to the composition table
#'
#' List the survey foods with at least one included record that
#' [link_composition()] could not link, with what blocks them, ranked so
#' that the foods worth fixing first come first, and the coverage reached
#' once each food and those ranked before it are resolved. It is the fourth
#' section of the data readiness report: the coverage curve against foods
#' resolved.
#'
#' Only records with `include = TRUE` count, as in [apparent_intake()].
#' Grams and expenditure are weighted by the household weight. A food
#' without a unit factor has no grams, so ranking only by grams would hide
#' it: records, grams and expenditure are all returned, and `order` says
#' which ranks.
#'
#' @param x Table returned by [link_composition()] (or [fill_composition()]).
#' @param households Households table ([hces_schema()]`("households")`); it
#'   must contain every household of `x`.
#' @param order `"grams"` (default: weighted grams per day of the records
#'   not linked, then records), `"records"` (records not linked, then
#'   grams) or `"expenditure"` (weighted expenditure of the records not
#'   linked, then records; needs the column `expenditure_lcu`). Ties are
#'   ordered by `food_code`; missing amounts rank last.
#' @returns A tibble, one row per food with an included record not linked,
#'   in rank order: `food_code`; `match_status` (the food's crosswalk, as in
#'   [link_composition()]: `matched` means the crosswalk is fine and the
#'   records lack grams); `reasons` (the distinct reasons of its records not
#'   linked, separated by `"; "`: the `grams_status` of [convert_units()]
#'   of those without grams, then the `match_status` when it is not
#'   `matched`); `units_no_grams` (the distinct units of its records without
#'   grams, sorted, `NA` when none); `n_records` (its included records);
#'   `n_not_linked`; `n_no_grams`; `n_households` (with a record not
#'   linked); `qty_g_d_not_linked` (weighted grams per day as acquired of
#'   the records not linked that have grams; `NA` when none has);
#'   `expenditure_lcu_d_not_linked` (weighted expenditure per day of those
#'   with an expenditure; `NA` when none has or without the column);
#'   `share_records`, `share_grams` and `share_expenditure` (of the
#'   included records, of their weighted grams, of their weighted
#'   expenditure, as in [linkage_ladder()]); `rank`; and
#'   `cum_share_records`, `cum_share_grams` and `cum_share_expenditure`:
#'   the share linked once this food and all those ranked before it are
#'   resolved. Each cumulative share ends at 1.
#' @seealso [linkage_ladder()], [link_composition()], [audit_log()].
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition,
#'   nutrients = nutrient_registry(hces_example$nutrients)
#' )
#' unmatched_foods(content, hces_example$households)
#' unmatched_foods(content, hces_example$households, order = "records")
#' @export
unmatched_foods <- function(x, households,
                            order = c("grams", "records", "expenditure")) {
  check_required()
  require_hces(x, "hces_nutrient_content")
  order <- check_choice(order, c("grams", "records", "expenditure"))
  if (order == "expenditure" && !has_expenditure(x)) {
    abort_hcesfort("argument", c(
      "{.code order = \"expenditure\"} needs the column
      {.field expenditure_lcu} in the acquisitions.",
      "i" = "Use {.code order = \"grams\"} or {.code \"records\"}."
    ), arg = "order")
  }
  h <- validate_households(households)
  m <- record_measures(x, h)
  d <- dplyr::as_tibble(x)[m$included, ]
  m <- m[m$included, ]
  out <- food_counts(d, m)
  out <- out[out$n_not_linked > 0, ]
  out <- add_food_shares(out, m, has_expenditure(x))
  out <- rank_foods(out, order)
  add_cumulative(out, m, has_expenditure(x))
}
