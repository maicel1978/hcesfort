#' Apparent intake per adult female equivalent, by food group
#'
#' Split the apparent intake of each household ([apparent_intake()]) by
#' the food groups of `food_groups`: one row per household and group, with
#' the amount of each nutrient that the foods of the group bring, per adult
#' female equivalent (AFE) and day. The amounts of a household add up, over
#' its groups, to its apparent intake. [food_group_shares()] turns this
#' table into design-based shares.
#'
#' The composition must be the **unfortified baseline**: `content` is
#' refused (`hcesfort_error_audit`) unless its log holds the step
#' [unfortified_baseline()]. Shares computed on a table with enriched foods
#' would attribute to cereals what enrichment added (E1 of the original
#' analysis).
#'
#' Records enter under the rules of [apparent_intake()], with the same
#' code: the `include` flag, the composition link, the outlier decision and
#' the household status; a record without a value for a nutrient adds
#' nothing to that nutrient. A food of `content` absent from `food_groups`
#' goes to the group `"unclassified"`, which is shown, never dropped.
#'
#' @inheritParams apparent_intake
#' @param content Table returned by [link_composition()] on a composition
#'   passed through [unfortified_baseline()].
#' @param food_groups Food groups table
#'   ([hces_schema()]`("food_groups")`), validated or not.
#' @returns A tibble of class `hces_group_intake` (and `hces_tbl`), keyed by
#'   `household_id` and `food_group`: every household of `households`, in
#'   its order, times every group (in the order of `food_groups`, then
#'   `"unclassified"` when some food of `content` has no group). Columns:
#'   `household_id`, `intake_status`, `afe`, `food_group`, `acquired` (at
#'   least one used record of the group; `NA` unless the household is
#'   `estimated`), `n_records_used`, `qty_edible_g_d` and one column per
#'   nutrient, per AFE and day. Amounts are `NA` unless `intake_status` is
#'   `"estimated"`; a group not acquired has zeros. The audit log
#'   (`step = "food_group_intake"`) counts the records excluded by cause,
#'   the used records without a group (`unclassified`), the foods of
#'   `food_groups` absent from `content` (`group_not_in_content`) and, per
#'   group and nutrient, the used records without a value
#'   (`no_nutrient_value`, detail `"<group>: <column>"`).
#' @seealso [food_group_shares()], [apparent_intake()],
#'   [validate_food_groups()].
#' @examples
#' e <- hces_example
#' nutrients <- nutrient_registry(e$nutrients)
#' grams <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
#' base <- unfortified_baseline(e$composition, e$enrichment, nutrients)
#' content <- link_composition(grams, e$crosswalk, base, nutrients)
#' afe <- adult_equivalents(
#'   e$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' groups <- food_group_intake(content, e$food_groups, afe, e$households)
#' subset(groups, household_id == 1)
#' subset(audit_log(groups), step == "food_group_intake")
#' @export
food_group_intake <- function(content, food_groups, afe, households,
                              outliers = NULL) {
  check_required()
  require_hces(content, "hces_nutrient_content")
  require_hces(afe, "hces_afe")
  check_baseline_step(content, arg = "content")
  x <- audit_check_rows(content, "food_group_intake")
  g <- validate_food_groups(food_groups)
  h <- validate_households(households)
  nutrients <- attr(x, "nutrients", exact = TRUE)
  outliers <- check_outlier_decision(outliers, x)
  check_intake_ids(x, afe, h)
  check_food_code_type(x, g)
  reasons <- excluded_reasons(x, outliers)
  used <- !Reduce(`|`, reasons)
  ids <- h$household_id
  afe_h <- afe$afe[match(ids, afe$household_id)]
  status <- intake_status(h, household_sums(x, used, ids, nutrients), afe_h)
  group <- g$food_group[match(x$food_code, g$food_code)]
  group[is.na(group)] <- unclassified_group
  levels <- unique(c(g$food_group, group))
  out <- dplyr::bind_rows(lapply(levels, function(lv) {
    group_amounts(x, used & group == lv, ids, nutrients, status, afe_h, lv)
  }))
  out <- out[order(match(out$household_id, ids)), ]
  est_record <- status[match(x$household_id, ids)] == "estimated"
  log <- food_group_log(x, g, reasons, used & est_record, group, nutrients)
  log <- dplyr::bind_rows(audit_combine(x, afe, h, g), log)
  out <- new_hces_tbl(out, "hces_group_intake", log,
                      c("household_id", "food_group"), nutrients)
  attr(out, "outlier_decision") <- outlier_decision(x, outliers)
  out
}

# The rows of one group: per household of `ids`, the used records of the
# group (`f`) summed and divided by the AFE, NA unless estimated.
group_amounts <- function(x, f, ids, nutrients, status, afe_h, group) {
  sums <- household_sums(x, f, ids, nutrients)
  ok <- status == "estimated"
  per_afe <- function(v) ifelse(ok, v / afe_h, NA_real_)
  out <- dplyr::tibble(
    household_id = ids, intake_status = status, afe = afe_h,
    food_group = rep(group, length(ids)),
    acquired = ifelse(ok, sums$n_used > 0, NA),
    n_records_used = sums$n_used, qty_edible_g_d = per_afe(sums$edible)
  )
  for (col in nutrients$column) out[[col]] <- per_afe(sums[[col]])
  out
}
