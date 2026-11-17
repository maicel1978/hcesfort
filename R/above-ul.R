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
#' **What the figures are and are not.** The UL, like the EAR, refers to
#' usual intake; the comparison here is with the apparent intake of a
#' household over `period_days`, whose extra variance raises the share
#' above an upper level (see "What the figures are and are not" in
#' [inadequacy()]; the log notes it, `apparent_intake_not_usual_intake`).
#'
#' **Compliance below 1.** Under `compliance_model = "average_content"`
#' of [apply_scenario()], every gram of the vehicle carries `compliance`
#' times the level, so no household receives the full level. If instead a
#' share `c` of the product is fortified at the full level and the rest is
#' not (`"all_or_nothing"`), a household near the UL at compliance 1 counts
#' with weight `c`, and one above it at `c` times the level counts 1 under
#' average content and `c` under all or nothing. The two models give the
#' same mean amount and **are not ordered** in the share above the UL:
#' either can be the larger. The same levels at compliance 1 bound both
#' from above and are the figure to report with them. Each scenario with a
#' compliance below 1 under average content is flagged in the log
#' (`average_content_understates_ul`, understated against that bound). Under
#' `compliance_model = "all_or_nothing"` the table of states is accepted:
#' each state is compared with the UL, and `above_ul_added`,
#' `above_ul_total`, `amount_added` and `amount_total` are the expectations
#' over the states with the weights `state_probability` (the amounts equal
#' those of average content); the log notes `states_collapsed`.
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
#'   for `total_intake`), `above_ul_total` (missing without a diet part),
#'   `coverage` (of the diet part) and `share_records_used`. `above_ul_added`
#'   and `above_ul_total` are numbers in `[0, 1]`, as `p_inadequate` of
#'   [inadequacy()]: 0 or 1 for one intake, the probability of being above
#'   the UL under all-or-nothing compliance.
#' @seealso [inadequacy()], [apply_scenario()].
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
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households, fortifiable = "use")
#' s <- apply_scenario(intake, use, hces_example$scenarios,
#'                     compliance_model = "average_content")
#' ul <- above_ul(s, ref_requirements, min_coverage = 0.8,
#'               min_records_used = 0.6)
#' table(ul$nutrient, ul$ul_scope)
#' @export
above_ul <- function(x, requirements, conversions = hcesfort::ref_conversions,
                     min_coverage, min_records_used) {
  check_required()
  require_hces(x, c("hces_intake", "hces_scenario_intake",
                    "hces_scenario_states"))
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
  out <- collapse_states(out, c("scenario", "household_id", "nutrient"),
                         c("amount_added", "amount_total", "above_ul_added",
                           "above_ul_total"))
  log <- dplyr::bind_rows(above_ul_log(x, req, parts, cov, min_coverage),
                          records_used_row("above_ul", x, used, min_used),
                          states_collapsed_row("above_ul", x))
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
    above_ul_added = if (form_scope) as.numeric(added > r$ul) else NA_real_,
    above_ul_total = as.numeric(total > r$ul), coverage = coverage,
    share_records_used = x$share_records_used,
    state_probability = state_weights(x)
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
