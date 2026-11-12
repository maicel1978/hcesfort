# Argument checks and audit rows of apply_scenario().

# Abort with hcesfort_error_audit unless the log of `x` holds the step
# unfortified_baseline() (E1).
check_baseline_step <- function(x, call = rlang::caller_env()) {
  if ("unfortified_baseline" %in% audit_get(x)$step) {
    return(invisible(x))
  }
  abort_hcesfort("audit", c(
    "{.arg intake} was not built on an unfortified baseline.",
    "x" = "Its audit log has no step {.fn unfortified_baseline}.",
    "i" = paste(
      "Pass the composition through {.fn unfortified_baseline} before",
      "{.fn link_composition}; with nothing to remove, give it an empty",
      "{.arg enrichment} table."
    )
  ), arg = "intake", expected = "unfortified_baseline", call = call)
}

# Abort on a bad compliance model or baseline label, or a scenario named
# like the baseline.
check_scenario_args <- function(s, compliance_model, baseline_label,
                                call = rlang::caller_env()) {
  models <- "average_content"
  partial <- any(s$compliance < 1)
  bad_model <- if (is.null(compliance_model)) partial else
    !rlang::is_string(compliance_model) || !compliance_model %in% models
  if (bad_model) {
    abort_hcesfort("argument", c(
      "{.arg compliance_model} must be {.val {models}}.",
      "i" = if (partial) {
        "Some compliance is below 1: the model must be named; it has no
        default."
      }
    ), arg = "compliance_model", call = call)
  }
  if (!rlang::is_string(baseline_label) || is.na(baseline_label)) {
    abort_hcesfort("argument", "{.arg baseline_label} must be one string.",
                   arg = "baseline_label", call = call)
  }
  rows <- which(s$scenario == baseline_label)
  if (length(rows) > 0) {
    abort_hcesfort("value", c(
      "A scenario of {.arg scenarios} is named like the baseline.",
      "x" = cli_escape(problem_bullet(
        paste0("scenario \"", baseline_label, "\""), rows
      )),
      "i" = "Rename it, or change {.arg baseline_label}."
    ), table = "scenarios", columns = "scenario", rows = rows,
    n = length(rows), call = call)
  }
  invisible(TRUE)
}

# Abort with hcesfort_error_join when a scenario vehicle is not a vehicle
# of `use`, or `intake` and `use` do not cover the same households, or a
# household with an intake has no use estimated.
check_scenario_use <- function(x, use, s, call = rlang::caller_env()) {
  vehicles <- unique(use$vehicle[use$level == "vehicle"])
  absent <- setdiff(s$vehicle, vehicles)
  if (length(absent) > 0) {
    n <- length(absent)
    abort_hcesfort("join", c(
      "{n} vehicle{?s} of {.arg scenarios} {?is/are} not in {.arg use}.",
      "x" = "Vehicle{?s}: {.val {absent}}.",
      "i" = "Add the missing vehicles to the table of {.fn vehicle_coverage}."
    ), table = "scenarios", other = "use", columns = "vehicle", n = n,
    call = call)
  }
  ids <- unique(use$household_id)
  only_intake <- sum(!unique(x$household_id) %in% ids)
  only_use <- sum(!ids %in% x$household_id)
  if (only_intake + only_use > 0) {
    abort_hcesfort("join", c(
      "{.arg intake} and {.arg use} must describe the same households.",
      "x" = "Only in {.arg intake}: {only_intake}; only in {.arg use}:
      {only_use}.",
      "i" = "A filter of one table between the two calls is the usual
      cause: filter the result of {.fn apply_scenario} instead."
    ), table = "intake", other = "use", columns = "household_id",
    n = only_intake + only_use, call = call)
  }
  check_scenario_basis(x, use, call)
  est <- unique(use$household_id[use$use_status == "estimated"])
  missing <- x$household_id[x$intake_status == "estimated" &
                              !x$household_id %in% est]
  if (length(missing) > 0) {
    abort_hcesfort("join", c(
      "{.arg intake} and {.arg use} must describe the same households.",
      "x" = "Households estimated in {.arg intake} without use estimated:
      {length(missing)}.",
      "i" = "Build both from the same households and AFE tables."
    ), table = "intake", other = "use", columns = "household_id",
    n = length(missing), call = call)
  }
  invisible(TRUE)
}

# Audit rows of apply_scenario(). Rows about scenario rows have no
# household count; rows about households count them.
scenario_log <- function(x, use, s, out, names_s, added_cols, model) {
  step <- "apply_scenario"
  note <- function(cause, n, detail = NA_character_, kind = "note",
                   households = FALSE) {
    keep <- n > 0
    if (!any(keep)) return(NULL)
    audit_row(step, "scenario_intake", kind, cause, n[keep],
              if (households) n[keep] else NA_integer_,
              detail = detail[keep])
  }
  vu <- use[use$level == "vehicle", ]
  not_acquired <- setdiff(s$vehicle, vu$vehicle[vu$acquired %in% TRUE])
  understated <- vapply(names_s, function(name) {
    f <- vu$vehicle %in% s$vehicle[s$scenario == name] &
      vu$acquired %in% TRUE & vu$n_records_no_grams > 0
    length(unique(vu$household_id[f]))
  }, integer(1))
  added <- expand.grid(scenario = names_s[-1], column = added_cols,
                       stringsAsFactors = FALSE)
  added$n <- mapply(function(sc, col) {
    v <- out[[paste0(col, "_added")]][out$scenario == sc]
    sum(!is.na(v) & v > 0)
  }, added$scenario, added$column)
  dplyr::bind_rows(
    audit_row(step, "scenario_intake", "input", "all", nrow(out), nrow(x),
              detail = paste(length(names_s), "scenarios")),
    note("compliance_model", sum(s$compliance < 1), model),
    note("compliance_below_one", sum(s$compliance < 1)),
    note("scenario_source_pending", sum(is_source_pending(s$source))),
    note("vehicle_not_acquired", rep(1L, length(not_acquired)),
         not_acquired),
    note("no_losses_applied", nrow(s)),
    note("households_with_added", added$n,
         paste0(added$scenario, ": ", added$column), households = TRUE),
    note("added_understated", understated, names_s, kind = "flagged",
         households = TRUE)
  )
}

# Abort with hcesfort_error_join when `intake` and `use` were built with a
# different AFE for a household or a different outlier decision.
check_scenario_basis <- function(x, use, call) {
  a <- x$afe
  b <- use$afe[match(x$household_id, use$household_id)]
  differ <- xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & a != b)
  n <- sum(differ)
  if (n > 0) {
    abort_hcesfort("join", c(
      "{.arg intake} and {.arg use} were built with different AFE.",
      "x" = "{n} household{?s} differ{?s/}, for example
      {.val {utils::head(x$household_id[differ], 3)}}.",
      "i" = "Build both from the same {.fn adult_equivalents} table."
    ), table = "intake", other = "use", columns = "afe", n = n, call = call)
  }
  d <- vapply(list(x, use), function(t) {
    v <- attr(t, "outlier_decision", exact = TRUE)
    if (is.null(v)) "not recorded" else v
  }, character(1))
  if (d[[1]] != d[[2]]) {
    abort_hcesfort("join", c(
      "{.arg intake} and {.arg use} were built with different outlier
      decisions.",
      "x" = cli_escape(paste0("intake: ", d[[1]], "; use: ", d[[2]], ".")),
      "i" = "Pass the same grams and the same {.arg outliers} choice to
      {.fn apparent_intake} and {.fn vehicle_coverage}."
    ), table = "intake", other = "use", columns = "outlier", n = NA_integer_,
    call = call)
  }
  invisible(TRUE)
}
