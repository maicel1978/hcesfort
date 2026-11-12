# Validator of the grouping of survey foods. Design:
# docs/design-food-group-shares.md, section 2.

#' Validate a grouping of survey foods
#'
#' Check the table that assigns each survey food to one food group
#' ([hces_schema()]`("food_groups")`) and return it as a validated table of
#' the package, with its audit log started. The grouping is the analyst's
#' (or the adapter's): hcesfort ships no classification, because the
#' groups depend on the country and on the question. A finer level (single
#' foods under a common name) is the same table with other labels.
#'
#' Rules: one row per `food_code` (`hcesfort_error_key`); `food_group` not
#' missing and not empty, and not `"unclassified"`, a name reserved for the
#' foods without a group in [food_group_intake()] (`hcesfort_error_value`).
#' A `source` equal to `"SOURCE PENDING"` is accepted and counted
#' (`source_pending`).
#'
#' @param x Food groups table: `food_code`, `food_group`, `source`.
#' @returns `x` as a tibble of class `hces_food_groups` (and `hces_tbl`),
#'   with its audit log.
#' @seealso [food_group_intake()], [food_group_shares()].
#' @examples
#' validate_food_groups(hces_example$food_groups)
#' @export
validate_food_groups <- function(x) {
  check_required()
  validate_table(
    x, schema_food_groups(), "validate_food_groups",
    function(x) list(source_pending = is_source_pending(x$source)),
    extra = check_group_names
  )
}

# Name reserved for the foods without a group.
unclassified_group <- "unclassified"

# Abort with hcesfort_error_value when a group name is empty or reserved.
check_group_names <- function(x, call) {
  group <- x$food_group
  rows <- which(!is.na(group) &
                  (trimws(group) == "" | group == unclassified_group))
  if (length(rows) == 0) {
    return(invisible(x))
  }
  bullet <- problem_bullet("empty or reserved group name", rows)
  abort_hcesfort("value", c(
    "{.arg food_groups} has {length(rows)} unusable {.field food_group}
    value{?s}.",
    "x" = cli_escape(bullet),
    "i" = "Name every group; {.val {unclassified_group}} is reserved for
    the foods without a group."
  ), table = "food_groups", columns = "food_group", rows = rows,
  n = length(rows), call = call)
}
