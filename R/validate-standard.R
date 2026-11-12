# Validators of the standard tables. Each checks the schema, then returns
# the table as a carrier with its audit log started: one `input` row and one
# `note` row per cause with at least one record. Nothing is excluded.

#' Validate the standard tables
#'
#' Check a table against its data contract ([hces_schema()]) and return it
#' as a validated table of the package, with its audit log started. These
#' functions are both validators and constructors: every function of
#' hcesfort that takes a standard table calls them first, so calling them
#' yourself is only needed to check a table early.
#'
#' Checks run in three stages, and each stage reports all its problems in
#' one error: columns and types (`hcesfort_error_schema`), the key
#' (`hcesfort_error_key`), and the values (`hcesfort_error_value`). Only
#' impossible values are rejected: a negative quantity, a weight of zero, a
#' sex outside `"female"` and `"male"`. Implausible values (an adult of 110
#' years, a purchase of 400 kg) are left to the flags of later steps.
#'
#' Missing measurements are accepted and counted as `note` rows of the
#' audit log, with these causes:
#'
#' * households: `food_module_nonresponse` (`food_module_response` is
#'   `FALSE`);
#' * members: `missing_age`, `missing_sex`;
#' * acquisitions: `missing_quantity`, `missing_unit`, `not_included`
#'   (`include` is `FALSE`).
#'
#' A cause is written only when it counts at least one record. Columns not
#' in the schema are kept untouched. Validating a table already validated
#' runs the checks again and adds nothing to its log, except an
#' `external_change` row when its number of rows changed in between.
#'
#' @param x A data frame with the columns of the schema.
#' @returns `x` as a tibble of class `hces_households`, `hces_members` or
#'   `hces_acquisitions` (and `hces_tbl`), with its audit log
#'   ([audit_log()]).
#' @seealso [hces_schema()] for the contracts, [validate_survey()] to
#'   validate the three tables together, [hcesfort_errors].
#' @examples
#' households <- data.frame(
#'   household_id = 1:2, weight = c(150, 210), stratum = 1, psu = 1:2
#' )
#' validate_households(households)
#' @export
validate_households <- function(x) {
  validate_table(x, "households", "validate_households", function(x) {
    list(food_module_nonresponse = if (!is.null(x$food_module_response)) {
      !x$food_module_response
    })
  })
}

#' @rdname validate_households
#' @export
validate_members <- function(x) {
  validate_table(x, "members", "validate_members", function(x) {
    list(missing_age = is.na(x$age_years), missing_sex = is.na(x$sex))
  })
}

#' @rdname validate_households
#' @export
validate_acquisitions <- function(x) {
  validate_table(x, "acquisitions", "validate_acquisitions", function(x) {
    list(
      missing_quantity = is.na(x$quantity),
      missing_unit = is.na(x$unit),
      not_included = !x$include
    )
  })
}

# Shared body of the validators. `flags` returns a named list of logical
# vectors, one per cause of note.
validate_table <- function(x, table, step, flags,
                           call = rlang::caller_env()) {
  schema <- schema_registry()[[table]]()
  class <- paste0("hces_", table)
  key <- attr(schema, "key")
  if (inherits(x, class) && inherits(x, "hces_tbl")) {
    x <- audit_check_rows(x, step)
    check_schema(x, schema, call)
    return(new_hces_tbl(x, class, audit_get(x), key))
  }
  check_schema(x, schema, call)
  log <- dplyr::bind_rows(
    audit_row(step, table, "input", "all", nrow(x), n_distinct_hh(x)),
    count_notes(x, step, table, flags(x))
  )
  new_hces_tbl(x, class, log, key)
}

# Note rows for the causes in `flags` that count at least one record.
count_notes <- function(x, step, table, flags) {
  flags <- Filter(function(f) !is.null(f) && any(f), flags)
  if (length(flags) == 0) {
    return(new_audit_log())
  }
  households <- vapply(flags, function(f) n_distinct_hh(x[f, ]), 1L)
  audit_row(step, table, "note", names(flags),
            vapply(flags, sum, 1L), households)
}

# Number of distinct households of a table.
n_distinct_hh <- function(x) {
  length(unique(x$household_id))
}
