# Validators of the user-supplied tables. Same pattern as the standard
# tables: check the schema, return the carrier with its log started, and
# count what later steps will need to know; nothing is excluded.

#' Validate the tables supplied by the user
#'
#' Check a user-supplied table against its data contract
#' ([hces_schema()]) and return it as a validated table of the package,
#' with its audit log started. As for the standard tables
#' ([validate_households()]), checks run in three stages (columns and
#' types, key, values), only impossible values are rejected, and missing
#' values that later steps must handle are counted as `note` rows of the
#' audit log:
#'
#' * `unit_factors`: no note. A `volume_ml` row without density and a
#'   `count` row without piece weight are valid; the conversion step counts
#'   the records they leave without grams. A missing `food_code` means the
#'   factor is valid for every food, and two such rows for one unit are a
#'   duplicated key.
#' * `crosswalk`: `unmatched_food` (no `composition_id`), `not_validated`,
#'   `missing_edible_portion`. A validated row without `composition_id`
#'   or without `match_type` is an error: a validated row is a match that
#'   enters the calculation.
#' * `vehicles`: `source_pending` (`source` is `"SOURCE PENDING"`). The
#'   optional `vehicle_group` gathers vehicles that share one substance
#'   (flour, bread and pasta made of wheat flour); a food may belong to
#'   several vehicles, but to at most one vehicle of each group, otherwise
#'   its grams would count twice in the group (`hcesfort_error_key`).
#'
#' @inheritParams validate_households
#' @returns `x` as a tibble of class `hces_unit_factors`, `hces_crosswalk`
#'   or `hces_vehicles` (and `hces_tbl`), with its audit log.
#' @seealso [validate_composition()], [validate_scenarios()],
#'   [hcesfort_errors].
#' @examples
#' crosswalk <- data.frame(
#'   food_code = c("rice", "oil"), composition_id = c("C01", NA),
#'   match_type = c("exact", NA), validated = c(TRUE, FALSE),
#'   edible_portion = c(1, NA)
#' )
#' audit_log(validate_crosswalk(crosswalk))
#' @export
validate_unit_factors <- function(x) {
  check_required()
  validate_table(x, schema_unit_factors(), "validate_unit_factors",
                 function(x) list())
}

#' @rdname validate_unit_factors
#' @export
validate_crosswalk <- function(x) {
  check_required()
  validate_table(
    x, schema_crosswalk(), "validate_crosswalk",
    function(x) {
      list(
        unmatched_food = is.na(x$composition_id),
        not_validated = !x$validated,
        missing_edible_portion = is.na(x$edible_portion)
      )
    },
    extra = function(x, call) {
      for (col in c("composition_id", "match_type")) {
        check_required_when(x, col, x$validated, "crosswalk",
                            "`validated` is TRUE", call)
      }
    }
  )
}

#' @rdname validate_unit_factors
#' @export
validate_vehicles <- function(x) {
  check_required()
  validate_table(
    x, schema_vehicles(), "validate_vehicles",
    function(x) list(source_pending = is_source_pending(x$source)),
    extra = check_vehicle_groups
  )
}

# TRUE where a source is the marker of a value not yet verified.
is_source_pending <- function(source) {
  grepl("^(# )?SOURCE PENDING", source)
}

# Abort with hcesfort_error_key when a food has two vehicles of one group.
check_vehicle_groups <- function(x, call) {
  group <- x[["vehicle_group"]]
  if (is.null(group)) {
    return(invisible(x))
  }
  grouped <- !is.na(group)
  rows <- which(grouped)[duplicated(
    data.frame(x$food_code, group)[grouped, , drop = FALSE]
  )]
  if (length(rows) == 0) {
    return(invisible(x))
  }
  bullet <- problem_bullet("second vehicle of a group", rows)
  abort_hcesfort("key", c(
    "In {.arg vehicles} a food has two vehicles of one {.field vehicle_group}.",
    "x" = cli_escape(bullet),
    "i" = "Its grams would count twice in the group: keep one vehicle."
  ), table = "vehicles", columns = c("food_code", "vehicle_group"),
  rows = rows, n = length(rows), call = call)
}

# Abort with hcesfort_error_value when `column` is missing (absent or NA)
# in rows where `when` is TRUE.
check_required_when <- function(x, column, when, table, condition, call) {
  values <- if (is.null(x[[column]])) rep(NA, nrow(x)) else x[[column]]
  rows <- which(when & is.na(values))
  if (length(rows) == 0) {
    return(invisible(x))
  }
  bullet <- problem_bullet(paste0("`", column, "` is missing"), rows)
  abort_hcesfort("value", c(
    "{.arg {table}} needs {.field {column}} when {condition}.",
    "x" = cli_escape(bullet)
  ), table = table, columns = column, rows = rows, n = length(rows),
  call = call)
}

# Abort with hcesfort_error_value when `column` has a value in rows where
# `when` is TRUE.
check_absent_when <- function(x, column, when, table, condition, call) {
  values <- if (is.null(x[[column]])) rep(NA, nrow(x)) else x[[column]]
  rows <- which(when & !is.na(values))
  if (length(rows) == 0) {
    return(invisible(x))
  }
  bullet <- problem_bullet(paste0("`", column, "` is given"), rows)
  abort_hcesfort("value", c(
    "{.arg {table}} must leave {.field {column}} missing when {condition}.",
    "x" = cli_escape(bullet)
  ), table = table, columns = column, rows = rows, n = length(rows),
  call = call)
}
