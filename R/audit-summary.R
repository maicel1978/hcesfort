# Exported readers and writers of the audit log for users and adapters.
# Design in docs/design-review-v0.1.md, section 5.

# Kinds summarised by `audit_summary()` and kinds an adapter may record.
audit_summary_kinds <- c("excluded", "flagged", "filled", "external_change")
audit_record_kinds <- c("excluded", "flagged", "filled", "note")

#' Summary of the audit log of a table
#'
#' `audit_summary()` lists what each step of the chain excluded, flagged or
#' filled, and the changes made outside the package, with the share of the
#' records that step received.
#'
#' One row per row of the log of kind `"excluded"`, `"flagged"`, `"filled"`
#' or `"external_change"`, in log order. A step run twice gives two rows:
#' counts of different runs are never added. `share_records` is
#' `n_records` divided by the `n_records` of the closest earlier `"input"`
#' row of the same step and table; it is `NA` when there is none (for
#' example for `external_change` rows, or for rows written by an adapter
#' with [audit_record()]).
#'
#' @param x A table returned by a function of hcesfort.
#' @returns A tibble with columns `step`, `kind`, `cause`, `detail`,
#'   `n_records`, `share_records`, `n_households` and `qty_g`; no rows
#'   when nothing was excluded, flagged or filled.
#' @seealso [audit_log()] for the full log, [audit_record()].
#' @examples
#' ex <- hces_example
#' g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
#' audit_summary(g)
#' @export
audit_summary <- function(x) {
  check_required()
  log <- audit_log(x)
  rows <- which(log$kind %in% audit_summary_kinds)
  base <- vapply(rows, function(i) audit_input_size(log, i), 1L)
  dplyr::tibble(
    step = log$step[rows],
    kind = log$kind[rows],
    cause = log$cause[rows],
    detail = log$detail[rows],
    n_records = log$n_records[rows],
    share_records = log$n_records[rows] / base,
    n_households = log$n_households[rows],
    qty_g = log$qty_g[rows]
  )
}

# `n_records` of the closest `input` row before row `i` of `log` with the
# same step and table; `NA` when there is none or it counts no record.
audit_input_size <- function(log, i) {
  before <- seq_len(i - 1L)
  hit <- before[log$kind[before] == "input" &
                  log$step[before] == log$step[[i]] &
                  log$table[before] == log$table[[i]]]
  if (length(hit) == 0) return(NA_integer_)
  n <- log$n_records[[max(hit)]]
  if (is.na(n) || n == 0L) NA_integer_ else n
}

#' Record a step of an adapter in the audit log
#'
#' `audit_record()` appends one row to the audit log of a table. It is the
#' way for a survey adapter, or a user, to state what they did to a table
#' between two functions of hcesfort: records combined or excluded, an
#' age imputed, `acquired` set to `FALSE`. A `dplyr::mutate()` keeps the
#' table and its log; `audit_record()` says what the mutate did.
#'
#' The kinds `"input"` and `"external_change"` are written only by the
#' package. A `step` named after a function of hcesfort is refused, so the
#' rows of the package and those of an adapter cannot be confused: prefix
#' it with the adapter's name, as in `"engih2018::combine_sections"`.
#'
#' @param x A table returned by a function of hcesfort.
#' @param step Name of the step that did the change: one string.
#' @param kind `"excluded"`, `"flagged"`, `"filled"` or `"note"`.
#' @param cause Reason, in snake case (`"duplicated_section"`).
#' @param n_records Number of records affected: one count.
#' @param n_households Number of distinct households affected, or `NA`.
#' @param qty_g Grams affected, or `NA`.
#' @param detail Optional qualifier (a nutrient, a unit), or `NA`.
#' @param table Table the row refers to; `NULL` for the table of `x`.
#' @returns `x` with the row appended to its log.
#' @seealso [audit_log()], [audit_summary()].
#' @examples
#' m <- validate_members(hces_example$members)
#' m <- audit_record(m, step = "my_adapter::impute_age", kind = "filled",
#'                   cause = "age_from_household_roster", n_records = 0)
#' tail(audit_log(m), 1)
#' @export
audit_record <- function(x, step, kind, cause, n_records,
                         n_households = NA, qty_g = NA, detail = NA,
                         table = NULL) {
  check_required()
  require_hces(x, "hces_tbl")
  check_record_step(step)
  kind <- check_required_choice(kind, audit_record_kinds)
  check_record_string(cause, "cause", pattern = "^[a-z][a-z0-9_]*$")
  check_record_number(n_records, "n_records", whole = TRUE)
  if (!is_scalar_na(n_households)) {
    check_record_number(n_households, "n_households", whole = TRUE)
  }
  if (!is_scalar_na(qty_g)) check_record_number(qty_g, "qty_g")
  if (!is_scalar_na(detail)) check_record_string(detail, "detail")
  if (is.null(table)) table <- carrier_table(x)
  check_record_string(table, "table")
  audit_add(x, step = step, table = table, kind = kind, cause = cause,
            n_records = n_records, n_households = n_households,
            qty_g = qty_g, detail = detail)
}

# Abort unless `step` is one string that names no function of hcesfort.
check_record_step <- function(step, call = rlang::caller_env()) {
  check_record_string(step, "step", call = call)
  own <- ls(asNamespace("hcesfort"), all.names = TRUE)
  if (sub("^hcesfort::", "", step) %in% own) {
    abort_hcesfort("argument", c(
      "{.arg step} must not name a function of hcesfort.",
      "x" = "{.val {step}} is a step of the package.",
      "i" = "Prefix it with your adapter, as in {.val my_adapter::{step}}."
    ), arg = "step", call = call)
  }
  invisible(step)
}

# Abort unless `value` is one non-empty string matching `pattern`.
check_record_string <- function(value, arg, pattern = ".",
                                call = rlang::caller_env()) {
  if (rlang::is_string(value) && !is.na(value) && grepl(pattern, value)) {
    return(invisible(value))
  }
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be one non-empty string.",
    "i" = if (pattern != ".") "It must match {.code {pattern}}."
  ), arg = arg, call = call)
}

# TRUE when `value` is one missing value of any atomic type.
is_scalar_na <- function(value) {
  is.atomic(value) && length(value) == 1 && is.na(value)
}

# Abort unless `value` is one finite number >= 0, whole when `whole`.
check_record_number <- function(value, arg, whole = FALSE,
                                call = rlang::caller_env()) {
  ok <- is.numeric(value) && length(value) == 1 && is.finite(value) &&
    value >= 0 && (!whole || value == round(value))
  if (ok) return(invisible(value))
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be one {if (whole) 'whole ' else ''}number >= 0."
  ), arg = arg, call = call)
}
