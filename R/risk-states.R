# inadequacy() and above_ul() on the table of states of apply_scenario()
# under all-or-nothing compliance (docs/design-12e5.md, section 4.2): each
# state is computed as any scenario, then the rows collapse to the usual
# key with the weights `state_probability`.

# The probability of the state of each row of `x`, for the result rows of
# inadequacy() and above_ul(); NULL when `x` is not a table of states (the
# column is then not created).
state_weights <- function(x) {
  if (inherits(x, "hces_scenario_states")) x$state_probability else NULL
}

# Collapse the result rows `out` (with the column `state_probability`) to
# one row per `key`: the columns `expect` become their expectation over
# the states, sum(p * value), missing when a value is missing; every other
# column is equal across the states (it comes from the baseline) and keeps
# its first value. Without the column, `out` is returned unchanged.
collapse_states <- function(out, key, expect) {
  p <- out[["state_probability"]]
  if (is.null(p)) {
    return(out)
  }
  k <- do.call(paste, c(unname(as.list(out[key])), sep = "\r"))
  id <- match(k, unique(k))
  res <- out[!duplicated(id), setdiff(names(out), "state_probability")]
  for (col in expect) {
    res[[col]] <- as.vector(rowsum(p * out[[col]], id, reorder = TRUE))
  }
  res
}

# Note row of inadequacy() or above_ul() when `x` is a table of states.
states_collapsed_row <- function(step, x) {
  if (!inherits(x, "hces_scenario_states")) {
    return(NULL)
  }
  audit_row(step, step, "note", "states_collapsed", nrow(x),
            length(unique(x$household_id)),
            detail = paste(
              "expectation over the states of all-or-nothing compliance,",
              "weights state_probability"
            ))
}

# Abort with hcesfort_error_audit when `x` is a table of states: the
# estimators take the household results of inadequacy() or above_ul().
refuse_states <- function(x, arg = rlang::caller_arg(x),
                          call = rlang::caller_env()) {
  if (!inherits(x, "hces_scenario_states")) {
    return(invisible(x))
  }
  abort_hcesfort("audit", c(
    "{.arg {arg}} is a table of states of all-or-nothing compliance.",
    "x" = "Its rows are states of a household, not households.",
    "i" = "Pass it to {.fn inadequacy} or {.fn above_ul} first; the means of
    intake by scenario are those of {.code compliance_model =
    \"average_content\"}."
  ), arg = arg, expected = "hces_tbl", call = call)
}
