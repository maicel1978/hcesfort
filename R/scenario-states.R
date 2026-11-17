# All-or-nothing compliance in apply_scenario() (docs/design-12e5.md,
# section 4): a vehicle with a compliance strictly between 0 and 1 is, for
# the whole period, either fortified at the full level or not at all. A
# scenario with k such vehicles has 2^k states; vehicles at compliance 1
# are always on, at 0 always off; vehicles are independent.

# Abort with hcesfort_error_value when a vehicle of a scenario has more
# than one compliance: a compliance that differs by nutrient is
# under-dosing, which is average content.
check_vehicle_compliance <- function(s, call = rlang::caller_env()) {
  key <- paste(s$scenario, s$vehicle, sep = "\r")
  n_values <- tapply(s$compliance, key, function(v) length(unique(v)))
  rows <- which(key %in% names(n_values)[n_values > 1])
  if (length(rows) == 0) {
    return(invisible(s))
  }
  abort_hcesfort("value", c(
    "Under {.val all_or_nothing} every vehicle of a scenario needs one
    compliance.",
    "x" = cli_escape(problem_bullet(
      "vehicle with more than one compliance in its scenario", rows
    )),
    "i" = "A compliance that differs by nutrient is under-dosing: give the
    vehicle one compliance, or use {.val average_content}."
  ), table = "scenarios", columns = "compliance", rows = rows,
  n = length(rows), call = call)
}

# `s` with every compliance set to 1: under all or nothing a vehicle that
# is on carries the full level.
at_full_level <- function(s) {
  s$compliance <- rep(1, nrow(s))
  s
}

# The vehicles of the rows `s1` (one scenario) with their compliance.
vehicle_compliance <- function(s1) {
  first <- !duplicated(s1$vehicle)
  stats::setNames(s1$compliance[first], s1$vehicle[first])
}

# The states of one scenario (its rows `s1`; none for the baseline): a
# list with, per state, `on` (the vehicles fortified, sorted), `state`
# (them joined by "+", or "none") and `state_probability`.
scenario_state_list <- function(s1) {
  comp <- vehicle_compliance(s1)
  always <- names(comp)[comp == 1]
  partial <- sort(names(comp)[comp > 0 & comp < 1], method = "radix")
  k <- length(partial)
  lapply(seq_len(2^k) - 1, function(i) {
    on <- (i %/% 2^(seq_len(k) - 1)) %% 2 == 1
    vehicles <- sort(c(always, partial[on]), method = "radix")
    list(
      on = vehicles,
      state = if (length(vehicles) == 0) "none" else
        paste(vehicles, collapse = "+"),
      state_probability = prod(ifelse(on, comp[partial], 1 - comp[partial]))
    )
  })
}

# The rows of apply_scenario() under all or nothing: per scenario and
# state, scenario_rows() with the vehicles on at the full level (`targets`
# built at compliance 1), and the columns `state` and `state_probability`
# after `scenario`.
states_rows <- function(x, use, s, targets, names_s, added_cols) {
  dplyr::bind_rows(lapply(names_s, function(name) {
    states <- scenario_state_list(s[s$scenario == name, ])
    dplyr::bind_rows(lapply(states, function(st) {
      rows <- targets[targets$scenario == name &
                        targets$vehicle %in% st$on, ]
      one <- scenario_rows(x, use, rows, name, added_cols)
      one$state <- rep(st$state, nrow(one))
      one$state_probability <- rep(st$state_probability, nrow(one))
      dplyr::relocate(one, "state", "state_probability", .after = "scenario")
    }))
  }))
}

# Audit notes of the states: one `states` row per scenario of `s` (n =
# number of states; the detail adds the rows of the scenario in `out` and
# their approximate size), and one `vehicles_assumed_independent` row per
# scenario with more than one vehicle of partial compliance (n = vehicles).
states_log <- function(s, table, out) {
  k <- unname(partial_counts(s))
  names_s <- unique(s$scenario)
  detail <- paste0(names_s, ": ", k, " vehicle", ifelse(k == 1, "", "s"),
                   " with partial compliance, ", 2^k, " state",
                   ifelse(k == 0, "", "s"), "; ",
                   states_size_text(out, names_s))
  indep <- k > 1
  dplyr::bind_rows(
    audit_row("apply_scenario", table, "note", "states", 2^k,
              detail = detail),
    if (any(indep)) {
      audit_row("apply_scenario", table, "note",
                "vehicles_assumed_independent", k[indep],
                detail = names_s[indep])
    }
  )
}
