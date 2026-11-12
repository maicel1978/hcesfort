#' Errors raised by hcesfort
#'
#' Every error raised by the package is a condition with two classes: a
#' specific class `hcesfort_error_<type>` and the common class
#' `hcesfort_error`. Catch any of them with
#' `tryCatch(..., hcesfort_error = function(e) ...)`, or one kind with its
#' specific class.
#'
#' * `hcesfort_error_argument`: a function argument (not a table) has the
#'   wrong type, length or value. Fields: `arg`.
#' * `hcesfort_error_schema`: input is not a data frame, a required column
#'   is missing, or a column has the wrong type. Fields: `table`, `columns`.
#' * `hcesfort_error_key`: a key is duplicated or missing. Fields: `table`,
#'   `columns`, `rows`, `n`.
#' * `hcesfort_error_value`: a value is impossible, outside the vocabulary,
#'   or missing where it cannot be. Fields: `table`, `columns`, `rows`, `n`.
#' * `hcesfort_error_units`: a nutrient column lacks its unit suffix, a unit
#'   is not understood, or two tables disagree on a unit. Fields: `table`,
#'   `columns`.
#' * `hcesfort_error_join`: rows of one table refer to keys absent from
#'   another, key types differ, or a join breaks its declared cardinality.
#'   Fields: `table`, `other`, `columns`, `n`.
#' * `hcesfort_error_audit`: a table that should carry an audit log does
#'   not, or its log lacks a step the function requires. Fields: `arg`,
#'   `expected`.
#' * `hcesfort_error_coverage`: the share of grams with a composition value
#'   for a nutrient is below the minimum the caller set. Fields:
#'   `nutrients`, `coverage`, `min_coverage`.
#'
#' The fields are elements of the condition object (`e$table`, `e$rows`).
#' Messages state what failed and in which table, list the offending columns
#' or the first rows with the total count, and say how to fix it.
#'
#' @seealso [audit_log()] and [restore_audit()] for the audit log.
#' @name hcesfort_errors
NULL

# Types of error the package raises; `hcesfort_error_<type>` is the class.
error_types <- c(
  "argument", "schema", "key", "value", "units", "join", "audit",
  "coverage"
)

# Raise a classed error.
#
# `message` is a cli message (a character vector with bullet names), which
# is interpolated in the environment of the caller. Fields in `...` become
# elements of the condition object.
abort_hcesfort <- function(type, message, ..., call = rlang::caller_env(),
                           .envir = parent.frame()) {
  if (!rlang::is_string(type) || !type %in% error_types) {
    rlang::abort(
      paste0("Internal error: unknown error type `", type, "`."),
      .internal = TRUE
    )
  }
  cli::cli_abort(
    message,
    class = c(paste0("hcesfort_error_", type), "hcesfort_error"),
    ...,
    call = call,
    .envir = .envir
  )
}
