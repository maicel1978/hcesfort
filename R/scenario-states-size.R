# The size of the table of states of apply_scenario() under all-or-nothing
# compliance (P213, P219): an optional limit checked before any row is
# built, and the rows and approximate size of each scenario in the log.

# The number of vehicles of partial compliance (strictly between 0 and 1)
# of each scenario of `s`, named by scenario.
partial_counts <- function(s) {
  names_s <- unique(s$scenario)
  vapply(names_s, function(name) {
    comp <- vehicle_compliance(s[s$scenario == name, ])
    sum(comp > 0 & comp < 1)
  }, integer(1))
}

# The checks of apply_scenario() on the states: `max_states`, and under
# all or nothing (`states` TRUE) one compliance per vehicle and the limit.
check_states <- function(s, states, max_states, n_households,
                         call = rlang::caller_env()) {
  check_max_states_arg(max_states, call)
  if (states) {
    check_vehicle_compliance(s, call)
    check_max_states(s, max_states, n_households, call)
  }
  invisible(s)
}

# Abort with hcesfort_error_argument unless `max_states` is NULL or one
# whole number of at least 1.
check_max_states_arg <- function(max_states, call = rlang::caller_env()) {
  ok <- is.null(max_states) ||
    (is.numeric(max_states) && length(max_states) == 1 &&
       is.finite(max_states) && max_states >= 1 &&
       max_states == round(max_states))
  if (!ok) {
    abort_hcesfort("argument", c(
      "{.arg max_states} must be {.code NULL} (no limit) or one whole
      number of at least 1."
    ), arg = "max_states", call = call)
  }
  invisible(max_states)
}

# Abort with hcesfort_error_value, before the rows are built, when a
# scenario of `s` has more than `max_states` states (2^k for k vehicles of
# partial compliance); `n_households` gives the rows the table would have.
check_max_states <- function(s, max_states, n_households,
                             call = rlang::caller_env()) {
  if (is.null(max_states)) {
    return(invisible(s))
  }
  k <- partial_counts(s)
  over <- names(k)[2^k > max_states]
  if (length(over) == 0) {
    return(invisible(s))
  }
  rows <- format(n_households * (1 + sum(2^k)), big.mark = ",",
                 scientific = FALSE)
  each <- paste0(over, " (", k[over], " vehicles, ", 2^k[over], " states)")
  abort_hcesfort("value", c(
    "{length(over)} scenario{?s} ha{?s/ve} more states than
    {.arg max_states} ({max_states}).",
    "x" = cli_escape(paste(each, collapse = "; ")),
    "i" = cli_escape(paste0(
      "The table of states would have ", rows, " rows (", n_households,
      " households times the states of every scenario and the baseline)."
    )),
    "i" = "Use {.val average_content}, raise {.arg max_states}, or split
    the scenario."
  ), table = "scenarios", columns = "compliance",
  rows = which(s$scenario %in% over), n = length(over), call = call)
}

# The rows and approximate size in MB of each scenario `names_s` of the
# table of states `out`, as text ("12 rows, 0.1 MB"): the size of `out`
# shared by rows.
states_size_text <- function(out, names_s) {
  rows <- vapply(names_s, function(name) sum(out$scenario == name),
                 integer(1), USE.NAMES = FALSE)
  per_row <- as.numeric(utils::object.size(out)) / max(nrow(out), 1)
  mb <- rows * per_row / 2^20
  paste0(format(rows, big.mark = ",", trim = TRUE), " rows, ",
         formatC(mb, format = "f", digits = 1), " MB")
}
