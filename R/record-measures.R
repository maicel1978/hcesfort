# Measures of each record used by the data readiness report:
# linkage_ladder(), unmatched_foods() and estimate_unlinked().
# Design: docs/design-reports-v2.md, sections 3.1 and 5.1.

# Match statuses of a food that has a composition match, validated or not.
has_match_status <- c("matched", "not_validated", "missing_edible_portion")

# One row per record of `x` (from link_composition()), in its order:
# `household_id`, `weight` (of the household, by a checked many-to-one
# lookup in `h`), the logical steps of the linkage ladder (`included`,
# `with_quantity`, `with_grams`, `matched`, `validated`), the weighted
# grams per day as acquired (`grams_w`, 0 without grams) and the
# expenditure per day for the household (`expenditure_d`, `NA` when the
# record or the table has none) with its weighted value (`expenditure_w`).
record_measures <- function(x, h, arg = "x", call = rlang::caller_env()) {
  check_household_ids(stats::setNames(list(x), arg), h, call = call)
  weight <- h$weight[match(x$household_id, h$household_id)]
  has_grams <- !is.na(x$qty_g_d)
  exp_d <- record_expenditure(x)
  dplyr::tibble(
    household_id = x$household_id,
    weight = weight,
    included = x$include,
    with_quantity = x$include & !is.na(x$quantity) & !is.na(x$unit),
    with_grams = x$include & has_grams,
    matched = x$include & has_grams & x$match_status %in% has_match_status,
    validated = x$include & x$composition_status == "linked",
    grams_w = ifelse(has_grams, x$qty_g_d * weight, 0),
    expenditure_d = exp_d,
    expenditure_w = exp_d * weight
  )
}

# Expenditure per day for the household: `expenditure_lcu *
# household_share / period_days`, the rule of `qty_g_d`; a missing or
# absent `household_share` counts as for grams (absent: 1; missing: NA).
record_expenditure <- function(x) {
  if (is.null(x[["expenditure_lcu"]])) {
    return(rep(NA_real_, nrow(x)))
  }
  share <- if (is.null(x[["household_share"]])) 1 else x$household_share
  x$expenditure_lcu * share / x$period_days
}

# TRUE when `x` (or the table it came from) has the column
# `expenditure_lcu`.
has_expenditure <- function(x) {
  !is.null(x[["expenditure_lcu"]])
}
