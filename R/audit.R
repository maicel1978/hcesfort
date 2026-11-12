# The audit log: one row per fact, in chronological order. Format in
# docs/design-task2.md, section 3.

# Kinds of row in the audit log.
audit_kinds <- c(
  "input", "excluded", "flagged", "filled", "note", "external_change"
)

# An empty audit log with its eight typed columns.
new_audit_log <- function() {
  dplyr::tibble(
    step = character(0),
    table = character(0),
    kind = character(0),
    cause = character(0),
    n_records = integer(0),
    n_households = integer(0),
    qty_g = double(0),
    detail = character(0)
  )
}

# Rows of an audit log. Arguments of length one are recycled to the
# longest, so one call can write several causes of one step.
audit_row <- function(step, table, kind, cause, n_records,
                      n_households = NA_integer_, qty_g = NA_real_,
                      detail = NA_character_) {
  if (!all(kind %in% audit_kinds)) {
    rlang::abort("Internal error: unknown audit kind.", .internal = TRUE)
  }
  rows <- dplyr::tibble(
    step = as.character(step),
    table = as.character(table),
    kind = as.character(kind),
    cause = as.character(cause),
    n_records = as.integer(n_records),
    n_households = as.integer(n_households),
    qty_g = as.double(qty_g),
    detail = as.character(detail)
  )
  rows[names(new_audit_log())]
}

# `x` with the rows of `audit_row(...)` appended to its log.
audit_add <- function(x, ...) {
  log <- dplyr::bind_rows(audit_get(x), audit_row(...))
  attr(x, "audit") <- log
  x
}

# `x` with the logs of the tables in `...` appended to its own, in order.
audit_merge <- function(x, ...) {
  others <- lapply(list(...), audit_get)
  attr(x, "audit") <- dplyr::bind_rows(c(list(audit_get(x)), others))
  x
}

# Log `a` followed by the rows of log `b` that `a` does not already hold,
# compared as whole rows with multiplicity: a row twice in `b` and once in
# `a` is appended once.
audit_union <- function(a, b) {
  if (nrow(b) == 0) return(a)
  id <- function(log) {
    do.call(paste, c(lapply(log, as.character), sep = "\r"))
  }
  ka <- id(a)
  kb <- id(b)
  seen <- table(factor(ka, levels = unique(kb)))
  occurrence <- stats::ave(seq_along(kb), kb, FUN = seq_along)
  keep <- occurrence > as.integer(seen[kb])
  dplyr::bind_rows(a, b[keep, ])
}

# The log of `x`, or an empty log when it has none.
audit_get <- function(x) {
  log <- attr(x, "audit", exact = TRUE)
  if (is.null(log)) new_audit_log() else log
}

#' Audit log of a table
#'
#' Every table validated or produced by hcesfort carries an audit log: a
#' record of what each step received, excluded, flagged or filled, and of
#' the changes made to the table outside the package. `audit_log()` returns
#' it.
#'
#' The log has one row per fact, in the order the facts were written:
#'
#' * `step`: function that wrote the row.
#' * `table`: table the row refers to.
#' * `kind`: `"input"` (size on entry to the step), `"excluded"`,
#'   `"flagged"`, `"filled"`, `"note"` (a fact that excludes nothing) or
#'   `"external_change"` (the number of rows changed between two functions
#'   of the package).
#' * `cause`: reason, in snake case; `"all"` for `input` rows. Causes are
#'   not hierarchical: a record with two problems is counted under each.
#' * `n_records`: records affected.
#' * `n_households`: distinct households with at least one affected record;
#'   `NA` when the table has no household.
#' * `qty_g`: grams affected; `NA` when grams do not exist at that step.
#' * `detail`: optional qualifier (a nutrient, a unit, or for
#'   `external_change` rows, `"removed"` or `"added"`).
#'
#' The log travels as an attribute of the table. Verbs that build a new
#' table (`summarise()`, pivots, grouped verbs) drop it; see
#' [restore_audit()].
#'
#' A change of values that keeps the number of rows (for example a
#' `mutate()` of a quantity) is not detected.
#'
#' @param x A table returned by a function of hcesfort.
#' @returns A tibble with the eight columns described above.
#' @seealso [restore_audit()], [hcesfort_errors].
#' @export
audit_log <- function(x) {
  check_required()
  log <- attr(x, "audit", exact = TRUE)
  if (!inherits(x, "hces_tbl") || is.null(log)) {
    abort_hcesfort("audit", c(
      "{.arg x} carries no audit log.",
      "i" = "Only tables returned by hcesfort functions carry one."
    ), arg = "x", expected = "hces_tbl")
  }
  log
}
