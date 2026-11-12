# The carrier of the audit log: a tibble subclass `hces_tbl` with the log in
# the attribute `audit`. Rules in docs/design-task2.md, section 4: the
# package never relies on the attribute surviving a verb; it re-attaches it
# on exit, requires it on entry, and records changes in the number of rows.

# Attributes of a carrier that are re-attached by the package.
carrier_attrs <- c("audit", "audit_rows", "audit_key", "nutrients",
                   "outlier_decision")

# A carrier: `data` as a tibble of class `c(class, "hces_tbl")`, with its
# log, its key columns, its current number of rows and, for tables with
# nutrient columns, its nutrient registry.
new_hces_tbl <- function(data, class, audit = new_audit_log(), key,
                         nutrients = NULL) {
  data <- dplyr::as_tibble(data)
  class(data) <- c(class, "hces_tbl", "tbl_df", "tbl", "data.frame")
  attr(data, "audit") <- audit
  attr(data, "audit_key") <- key
  attr(data, "audit_rows") <- nrow(data)
  attr(data, "nutrients") <- nutrients
  data
}

# The table name used in the log: the first class without its prefix.
carrier_table <- function(x) {
  sub("^hces_", "", class(x)[[1]])
}

# Abort with `hcesfort_error_audit` unless `x` is a carrier of `class`.
require_hces <- function(x, class, arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  if (inherits(x, class) && inherits(x, "hces_tbl") &&
        !is.null(attr(x, "audit", exact = TRUE))) {
    return(invisible(x))
  }
  abort_hcesfort("audit", c(
    "{.arg {arg}} is not a table of class {.cls {class}} with its audit log.",
    "x" = "It has class {.cls {class(x)}}.",
    "i" = paste(
      "A {.fn summarise}, a pivot or a grouped verb between two hcesfort",
      "functions drops the class and the log."
    ),
    "i" = paste(
      "Use {.code restore_audit(x, from = previous)} to re-attach them",
      "from the table returned by the previous hcesfort function."
    )
  ), arg = arg, expected = class, call = call)
}

# `x` with an `external_change` row in its log when its number of rows
# differs from the one the package last recorded. Called on entry by every
# function that takes a carrier, before anything else.
audit_check_rows <- function(x, step) {
  before <- attr(x, "audit_rows", exact = TRUE)
  now <- nrow(x)
  if (is.null(before) || before == now) {
    return(x)
  }
  x <- audit_add(
    x,
    step = step, table = carrier_table(x), kind = "external_change",
    cause = "rows_changed_outside_package", n_records = abs(now - before),
    detail = if (now < before) "removed" else "added"
  )
  attr(x, "audit_rows") <- now
  x
}

#' Re-attach the audit log to a table
#'
#' Verbs that build a new table, such as `summarise()`, `pivot_longer()` or
#' a `mutate()` on a grouped table, drop the class and the audit log of a
#' table returned by hcesfort. `restore_audit()` gives them back, taken from
#' the table they were computed from.
#'
#' The keys of `x` must be a subset of the keys of `from`: every row of `x`
#' must still identify a row of `from`. A difference in the number of rows
#' is not an error; the next hcesfort function records it in the log as an
#' `external_change`. A grouped `x` is ungrouped.
#'
#' @param x A data frame derived from `from`.
#' @param from A table returned by a function of hcesfort.
#' @returns `x` as a tibble with the class and the audit log of `from`.
#' @seealso [audit_log()], [hcesfort_errors].
#' @export
restore_audit <- function(x, from) {
  require_hces(from, "hces_tbl")
  if (!is.data.frame(x)) {
    abort_hcesfort("argument", c(
      "{.arg x} must be a data frame.",
      "x" = "It has class {.cls {class(x)}}."
    ), arg = "x")
  }
  key <- attr(from, "audit_key", exact = TRUE)
  check_restore_keys(x, from, key)
  out <- dplyr::as_tibble(dplyr::ungroup(x))
  class(out) <- class(from)
  for (a in carrier_attrs) attr(out, a) <- attr(from, a, exact = TRUE)
  out
}

# Abort unless the key columns of `from` are in `x` with a compatible type
# and every key of `x` is a key of `from`.
check_restore_keys <- function(x, from, key, call = rlang::caller_env()) {
  missing <- setdiff(key, names(x))
  if (length(missing) > 0) {
    abort_hcesfort("join", c(
      "{.arg x} lacks the key {cli::qty(missing)}column{?s} of {.arg from}.",
      "x" = "Missing: {.field {missing}}.",
      "i" = "Keep the key columns, or restore before summarising them away."
    ), table = "x", other = "from", columns = missing, n = NA_integer_,
    call = call)
  }
  bad_type <- key[!mapply(same_id_type, x[key], from[key])]
  if (length(bad_type) > 0) {
    abort_hcesfort("join", c(
      "Key columns of {.arg x} and {.arg from} differ in type.",
      "x" = "Column{?s}: {.field {bad_type}}."
    ), table = "x", other = "from", columns = bad_type, n = NA_integer_,
    call = call)
  }
  foreign <- dplyr::anti_join(x[key], from[key], by = key)
  if (nrow(foreign) > 0) {
    n <- nrow(foreign)
    abort_hcesfort("join", c(
      "{n} row{?s} of {.arg x} {?has/have} a key absent from {.arg from}.",
      "i" = paste(
        "{.fn restore_audit} only re-attaches a log to a table derived",
        "from {.arg from}."
      )
    ), table = "x", other = "from", columns = key, n = n, call = call)
  }
  invisible(x)
}

# TRUE when two id columns can be compared: both numeric or both character.
same_id_type <- function(a, b) {
  (is.numeric(a) && is.numeric(b)) || (is.character(a) && is.character(b))
}
