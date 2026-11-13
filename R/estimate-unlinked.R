#' Share of the included records not linked, on the survey design
#'
#' Estimate the share of what the households acquired that has no nutrient
#' value, by grams, records or expenditure, nationally or by domain, with
#' its standard error and confidence interval. By domain, it also compares
#' each domain with the rest of the population, so that the data readiness
#' report can say whether the foods left unlinked weigh more in some
#' groups than in others (DR5).
#'
#' For the measure \eqn{a} of each included record (grams per day as
#' acquired, 1 per record, or expenditure per day), household totals of
#' the records not linked (\eqn{u_h}) and of all of them (\eqn{t_h}) give
#' the ratio of weighted totals \eqn{\sum_h w_h u_h / \sum_h w_h t_h},
#' estimated with [survey::svyratio()], with the logit interval of
#' [food_group_shares()]. By grams only records with grams count; by
#' expenditure only records with one. Nationally, by grams and by
#' expenditure, `1 - estimate` is the last step of [linkage_ladder()].
#'
#' With `by`, `difference` is the share of the domain minus that of the
#' rest of the population (every other household of the design), with its
#' standard error by the delta method on the four weighted totals
#' ([survey::svytotal()], then [survey::svycontrast()]) and a *t* interval
#' with the degrees of freedom of the design. `differs` is `TRUE` when that
#' interval excludes zero. The flags are not adjusted for the number of
#' comparisons.
#'
#' @inheritParams estimate_households
#' @param x Table returned by [link_composition()] (or [fill_composition()]).
#' @param by `NULL` (national) or domain columns of the households table.
#' @param measure `"grams"` (default), `"records"` or `"expenditure"`
#'   (needs the column `expenditure_lcu`).
#' @returns A tibble of class `hces_estimate` (and `hces_tbl`): the `by`
#'   columns, `statistic` (`"share"`), `variable` (`"unlinked_<measure>"`),
#'   `estimate`, `se`, `ci_low`, `ci_high`, `conf_level`, `df`, `n`
#'   (households in the domain), `n_missing` (0: every household counts),
#'   `rest_estimate`, `difference`, `difference_ci_low`,
#'   `difference_ci_high` and `differs` (the last five missing for the
#'   national row). A share of exactly 0 or 1 has `se = 0` and no interval.
#'   It passes through [flag_precision()]. Its audit log continues the log
#'   of `x`.
#' @seealso [linkage_ladder()], [unmatched_foods()].
#' @examples
#' e <- hces_example
#' grams <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
#' content <- link_composition(grams, e$crosswalk, e$composition,
#'                             nutrient_registry(e$nutrients))
#' design <- as_hces_design(e$households, lonely_psu = "adjust")
#' estimate_unlinked(design, content)
#' estimate_unlinked(design, content, by = "region", measure = "expenditure")
#' @export
estimate_unlinked <- function(design, x, by = NULL, measure = "grams",
                              level = 0.95, df = "domain") {
  check_required()
  require_design(design)
  require_hces(x, "hces_nutrient_content")
  x <- audit_check_rows(x, "estimate_unlinked")
  check_estimate_args(design, x, "proportion", by, "logit", level, df)
  measure <- check_choice(measure, c("grams", "records", "expenditure"))
  check_unlinked_measure(x, measure)
  h <- household_unlinked(design, x, measure)
  cells <- by_cells(design, by)
  out <- dplyr::bind_rows(lapply(seq_along(cells$masks), function(j) {
    est <- unlinked_cell(design, h, cells$masks[[j]], level, df,
                         compare = length(by) > 0)
    dplyr::bind_cols(cells$levels[j, ], dplyr::tibble(
      statistic = "share", variable = paste0("unlinked_", measure)
    ), est)
  }))
  log <- dplyr::bind_rows(audit_get(x), unlinked_log(design, df, out))
  new_hces_tbl(out, "hces_estimate", log, c(by, "variable"))
}
