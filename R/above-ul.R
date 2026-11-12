#' Households above a tolerable upper intake level
#'
#' For each household, scenario and nutrient with an upper level (UL),
#' whether the intake the UL applies to is above it. As [inadequacy()], the
#' result is one row per household and estimates nothing; the share of
#' households above the UL is computed with the survey design later.
#'
#' What is compared depends on `ul_applies_to` (E7 of the original
#' analysis):
#'
#' * `"total"` (iron, zinc): the total intake of the scenario
#'   (`ul_scope = "total_intake"`); `above_ul_total` is returned.
#' * a form (`"folic_acid"`, `"preformed_vitamin_a"`): only that form
#'   counts. The forms of the category are the rows of `conversions` whose
#'   `ul_form` is the category. The **added part** is what the scenarios
#'   added in those forms (the `<form>_<unit>_added` columns of
#'   [apply_scenario()], in the mass unit of the form, not DFE or RAE). The
#'   **diet part** is the intake of the registry nutrients that are forms of
#'   the category (`folic_acid_ug`, `retinol_ug`), when the composition has
#'   them. With a diet part, `ul_scope = "form_diet_and_added"` and both
#'   comparisons are returned. Without it, `ul_scope = "form_added_only"`,
#'   `above_ul_total` is missing, and `above_ul_added` is a **lower bound**
#'   of the share above the UL, since the form already in the diet is
#'   ignored (the original analysis called this figure an upper bound).
#'   With neither part, `ul_scope = "not_assessable"`.
#'
#' The unit of each UL (`ul_unit`) must be the unit of what it is compared
#' with: the registry unit for `"total"`, the mass unit of the form
#' otherwise; else `hcesfort_error_units`. The comparison is strict. The UL
#' is that of adults, applied to intake per adult female equivalent:
#' children have lower upper levels and are the most exposed to excess from
#' fortified staples, and a household figure says nothing about them.
#' `min_coverage` applies to the diet part of each comparison, as in
#' [inadequacy()]; low coverage understates the share above the UL. So
#' does record loss: `min_records_used` is required and gated as in
#' [inadequacy()].
#'
#' @inheritParams inadequacy
#' @param requirements A table with one row per nutrient: `nutrient`,
#'   `unit`, `ul`, `ul_unit` and `ul_applies_to`, such as one group of
#'   [ref_requirements].
#' @param conversions Conversions table with the column `ul_form`, by
#'   default [ref_conversions].
#' @returns A tibble of class `hces_above_ul` (and `hces_tbl`), long, key
#'   `scenario` + `household_id` + `nutrient`: `scenario`, `household_id`,
#'   `intake_status`, `nutrient`, `ul`, `ul_unit`, `ul_applies_to`,
#'   `ul_scope`, `amount_added`, `amount_total`, `above_ul_added` (missing
#'   for `total_intake`), `above_ul_total` (missing without a diet part) and
#'   `coverage` (of the diet part) and `share_records_used`.
#' @seealso [inadequacy()], [apply_scenario()].
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
#' ul <- above_ul(s, ref_requirements, min_coverage = 0.8,
#'               min_records_used = 0.6)
#' table(ul$nutrient, ul$ul_scope)
#' @export
above_ul <- function(x, requirements, conversions = hcesfort::ref_conversions,
                     min_coverage, min_records_used) {
  check_required()
  require_hces(x, c("hces_intake", "hces_scenario_intake"))
  x <- audit_check_rows(x, "above_ul")
  nutrients <- attr(x, "nutrients", exact = TRUE)
  min_coverage <- check_min_coverage(min_coverage)
  min_used <- check_min_records_used(min_records_used)
  req <- check_requirements(requirements, nutrients, "ul",
                            extra = c("ul_unit", "ul_applies_to"))
  check_conversions(conversions)
  if (is.null(conversions[["ul_form"]])) {
    abort_hcesfort("schema", c(
      "{.arg conversions} lacks the column {.field ul_form}.",
      "i" = "See {.code ref_conversions}."
    ), table = "conversions", columns = "ul_form")
  }
  parts <- lapply(seq_len(nrow(req)), function(i) {
    ul_parts(x, nutrients, req[i, ], conversions)
  })
  diet <- unique(unlist(lapply(parts, `[[`, "diet")))
  used <- check_records_used(x, min_used)
  cov <- check_coverage(x, nutrients, diet, min_coverage)
  rows <- lapply(seq_len(nrow(req)), function(i) {
    ul_rows(x, nutrients, req[i, ], parts[[i]])
  })
  out <- if (length(rows) == 0) ul_rows_empty(x) else dplyr::bind_rows(rows)
  log <- dplyr::bind_rows(above_ul_log(x, req, parts, cov, min_coverage),
                          records_used_row("above_ul", x, used, min_used))
  new_hces_tbl(out, "hces_above_ul", dplyr::bind_rows(audit_get(x), log),
               c("scenario", "household_id", "nutrient"), nutrients)
}

# Rows of one nutrient with a UL, from its parts (see ul_parts()).
ul_rows <- function(x, nutrients, r, p) {
  ok <- x$intake_status == "estimated"
  scenario <- x[["scenario"]]
  if (is.null(scenario)) scenario <- rep(NA_character_, nrow(x))
  sum_cols <- function(cols) {
    if (length(cols) == 0) return(ifelse(ok, 0, NA_real_))
    Reduce(`+`, lapply(cols, function(col) x[[col]]))
  }
  added <- sum_cols(p$added)
  total <- if (p$scope %in% c("total_intake", "form_diet_and_added")) {
    sum_cols(c(p$total, p$added_outside))
  } else {
    rep(NA_real_, nrow(x))
  }
  coverage <- if (length(p$diet) == 0) rep(NA_real_, nrow(x)) else
    do.call(pmin, lapply(p$diet, function(n) {
      x[[paste0(nutrients$column[nutrients$nutrient == n], "_coverage")]]
    }))
  form_scope <- p$scope %in% c("form_diet_and_added", "form_added_only")
  dplyr::tibble(
    scenario = scenario, household_id = x$household_id,
    intake_status = x$intake_status, nutrient = r$nutrient, ul = r$ul,
    ul_unit = r$ul_unit, ul_applies_to = r$ul_applies_to,
    ul_scope = p$scope,
    amount_added = if (p$scope == "not_assessable") NA_real_ else added,
    amount_total = total,
    above_ul_added = if (form_scope) added > r$ul else NA,
    above_ul_total = total > r$ul, coverage = coverage,
    share_records_used = x$share_records_used
  )
}

# A result with no rows and the column types of the result.
ul_rows_empty <- function(x) {
  r <- dplyr::tibble(nutrient = character(0), ul = double(0),
                     ul_unit = character(0), ul_applies_to = character(0))
  p <- list(scope = "not_assessable", added = character(0),
            diet = character(0), total = character(0),
            added_outside = character(0))
  ul_rows(x[0, ], NULL, r, p)
}
