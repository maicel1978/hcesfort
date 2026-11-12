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
#'   `missing_edible_portion`. A validated row without `match_type` is an
#'   error.
#' * `vehicles`: `source_pending` (`source` is `"SOURCE PENDING"`).
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
  validate_table(x, schema_unit_factors(), "validate_unit_factors",
                 function(x) list())
}

#' @rdname validate_unit_factors
#' @export
validate_crosswalk <- function(x) {
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
      check_required_when(x, "match_type", x$validated, "crosswalk",
                          "`validated` is TRUE", call)
    }
  )
}

#' @rdname validate_unit_factors
#' @export
validate_vehicles <- function(x) {
  validate_table(x, schema_vehicles(), "validate_vehicles", function(x) {
    list(source_pending = grepl("^(# )?SOURCE PENDING$", x$source))
  })
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
