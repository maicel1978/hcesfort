#' Unfortified baseline of a composition table
#'
#' Remove from a composition table what enrichment or fortification added,
#' so that intake can be computed without the fortification a scenario will
#' add (E1, E6 of the original analysis). The result is a composition table
#' and is passed to [link_composition()] in place of the original;
#' `apply_scenario()` refuses an intake not built on one.
#'
#' Each row of `enrichment` (see [validate_enrichment()]) names a cell, a
#' composition row and a nutrient, and states what enrichment added to it,
#' by a reference pair or by an amount. With `v` the value of the cell, `E`
#' and `U` the values of the enriched and unenriched reference rows and `f`
#' the ingredient fraction:
#'
#' * `method = "subtract"` (default): the removed amount is
#'   `f * max(E - U, 0)`, or `added`; the baseline is `v` minus that amount,
#'   never below the floor `f * U` for a pair rule (the food holds at least
#'   what its unenriched ingredient brings) or 0 for an `added` rule. A cell
#'   whose value falls below the floor is set to the floor, or kept at `v`
#'   when `v` is already below it (no cell increases), and is flagged
#'   (`floored`): the row is probably not made with that ingredient at that
#'   fraction.
#' * `method = "replace_by_ingredient"`: the baseline is `f * U`. This is
#'   the rule of the original analysis, kept to reproduce it; it deletes the
#'   nutrients of every other ingredient. `added` rules are an error under
#'   it.
#'
#' All rules read the values of the table as given, so a row may be its own
#' enriched reference (enriched rice against plain rice, `f = 1`: both
#' methods give `U`). A missing value stays missing; a reference row without
#' a value for the nutrient is an `hcesfort_error_value`. Cells without a
#' rule are unchanged.
#'
#' The column `baseline_status` says, per row: `enrichment_removed` (a rule
#' names the row), `fortified_no_rule` (the `fortified` flag is `TRUE` and
#' no rule names the row: whether that fortification belongs to the
#' baseline is the user's decision, taken by writing or not writing the
#' rule) or `unchanged`. When the registry holds a form of a nutrient
#' (`folic_acid_ug` next to `folate_ug_dfe`, read from `conversions`), a row
#' with a rule for the nutrient and none for its form is flagged
#' (`form_without_rule`).
#'
#' @inheritParams fill_composition
#' @param enrichment Enrichment rules ([hces_schema()]`("enrichment")`),
#'   validated or not. A table with no rows states that the composition has
#'   nothing to remove.
#' @param method `"subtract"` or `"replace_by_ingredient"`.
#' @param conversions Conversions table, by default [ref_conversions]; used
#'   to recognise the forms of a nutrient in the registry.
#' @returns `composition` as a validated table of class `hces_composition`,
#'   with the corrected values and the column `baseline_status`. Its audit
#'   log continues the logs of `composition` and `enrichment` and adds
#'   (`step = "unfortified_baseline"`): `input`; notes
#'   `enrichment_removed`, `difference_not_positive` (`E <= U`, nothing
#'   removed), `rule_not_needed` (missing value), per nutrient column in
#'   `detail`, and `no_enrichment_rules` or `method_replace_by_ingredient`;
#'   flags `floored` (per column), `fortified_no_rule` and
#'   `form_without_rule` (per form column).
#' @seealso [validate_enrichment()], [link_composition()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' baseline <- unfortified_baseline(
#'   hces_example$composition, hces_example$enrichment, nutrients
#' )
#' baseline[baseline$composition_id %in% c("C04", "C13"),
#'          c("composition_id", "iron_mg", "folate_ug_dfe", "baseline_status")]
#' subset(audit_log(baseline), step == "unfortified_baseline")
#' @export
unfortified_baseline <- function(composition, enrichment, nutrients = NULL,
                                 method = "subtract",
                                 conversions = hcesfort::ref_conversions) {
  nutrients <- composition_registry(composition, nutrients)
  comp <- validate_composition(composition, nutrients)
  comp <- audit_check_rows(comp, "unfortified_baseline")
  check_baseline_args(comp, method, conversions)
  e <- validate_enrichment(enrichment, nutrients)
  check_enrichment_ids(comp, e)
  rules <- enrichment_rules(comp, e, nutrients, method)
  out <- dplyr::as_tibble(comp)
  for (i in which(!is.na(rules$value))) {
    out[[rules$column[i]]][rules$row[i]] <- rules$new[i]
  }
  named <- out$composition_id %in% e$composition_id
  fortified <- if (is.null(out[["fortified"]])) FALSE else
    out$fortified %in% TRUE
  out$baseline_status <- first_reason(list(
    enrichment_removed = named, fortified_no_rule = !named & fortified
  ), none = "unchanged")
  forms <- forms_without_rule(e, nutrients, conversions)
  log <- baseline_log(rules, method, out, forms, nrow(e))
  log <- dplyr::bind_rows(audit_get(comp), audit_get(e), log)
  new_hces_tbl(out, "hces_composition", log, "composition_id", nutrients)
}

# One row per rule: the cell, the reference values and the new value.
enrichment_rules <- function(comp, e, nutrients, method,
                             call = rlang::caller_env()) {
  column <- nutrients$column[match(e$nutrient, nutrients$nutrient)]
  cell <- function(ids) {
    r <- match(ids, comp$composition_id)
    vapply(seq_along(r), function(i) {
      if (is.na(r[i])) NA_real_ else as.double(comp[[column[i]]][[r[i]]])
    }, numeric(1))
  }
  rules <- dplyr::tibble(
    row = match(e$composition_id, comp$composition_id), column = column,
    value = cell(e$composition_id), enriched = cell(e$enriched_ref_id),
    unenriched = cell(e$unenriched_ref_id),
    fraction = as.double(e$ingredient_fraction),
    added = as.double(e$added), pair = is.na(e$added)
  )
  check_rule_values(rules, method, call)
  removed <- ifelse(rules$pair,
                    rules$fraction * pmax(rules$enriched - rules$unenriched, 0),
                    rules$added)
  floor <- ifelse(rules$pair, rules$fraction * rules$unenriched, 0)
  tol <- sqrt(.Machine$double.eps) * pmax(1, abs(floor))
  subtract <- method == "subtract"
  rules$floored <- subtract & rules$value - removed < floor - tol
  rules$new <- if (subtract) {
    pmax(rules$value - removed, pmin(floor, rules$value))
  } else {
    rules$fraction * rules$unenriched
  }
  rules$not_positive <- rules$pair & rules$enriched <= rules$unenriched
  rules
}

# For each form of the registry, the composition rows with a rule for its
# parent nutrient and none for the form.
forms_without_rule <- function(e, nutrients, conversions) {
  forms <- registry_forms(nutrients, conversions)
  n <- vapply(seq_len(nrow(forms)), function(i) {
    with_parent <- e$composition_id[e$nutrient == forms$parent[[i]]]
    with_form <- e$composition_id[e$nutrient == forms$form[[i]]]
    length(setdiff(with_parent, with_form))
  }, integer(1))
  dplyr::tibble(column = forms$column, n = n)
}
