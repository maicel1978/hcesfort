# The fortifiable vehicle in vehicle_coverage() (docs/design-12e5.md,
# section 2.2; P159, decision R3-D4): the records that count as
# fortifiable, their three columns and their log.

# "use", "ignore", or NULL when `x` has no column `fortifiable`: required
# when it has the column, must be NULL otherwise (the rule of `outliers`).
check_fortifiable_decision <- function(fortifiable, x,
                                       call = rlang::caller_env()) {
  has_column <- !is.null(x[["fortifiable"]])
  if (!has_column && is.null(fortifiable)) return(NULL)
  if (has_column && rlang::is_string(fortifiable) &&
        fortifiable %in% c("use", "ignore")) {
    return(fortifiable)
  }
  abort_hcesfort("argument", c(
    if (has_column) {
      "{.arg grams} has the column {.field fortifiable}: say whether to use
      it."
    } else {
      "{.arg fortifiable} is given but {.arg grams} has no column
      {.field fortifiable}."
    },
    "i" = if (has_column) {
      "Set {.arg fortifiable} to {.val use} or {.val ignore}."
    } else {
      "Leave {.arg fortifiable} as NULL: every record of a vehicle counts as
      fortifiable."
    }
  ), arg = "fortifiable", call = call)
}

# TRUE for the records that count as fortifiable: all of them unless the
# decision is "use"; then every record but those with `FALSE` (a missing
# value counts, and is flagged).
fortifiable_records <- function(x, decision) {
  if (!identical(decision, "use")) return(rep(TRUE, nrow(x)))
  !x$fortifiable %in% FALSE
}

# use_rows() on the records `used`, with acquired_fortifiable after
# `acquired`, and qty_fortifiable_g_d and qty_fortifiable_g_d_pc at the
# end, from use_rows() on the records `fort` (same households and items,
# same order).
use_rows_fortifiable <- function(x, used, fort, items, ids, status, afe_h,
                                 members_h) {
  out <- use_rows(x[used, ], items, ids, status, afe_h, members_h)
  fort <- use_rows(x[fort, ], items, ids, status, afe_h, members_h)
  out$acquired_fortifiable <- fort$acquired
  out$qty_fortifiable_g_d <- fort$qty_vehicle_g_d
  out$qty_fortifiable_g_d_pc <- fort$qty_vehicle_g_d_pc
  dplyr::relocate(out, "acquired_fortifiable", .after = "acquired")
}

# One audit row for the records of `x` where `f` is TRUE, with their
# households and grams, or none.
use_record_row <- function(step, x, kind, cause, f, detail = NA_character_) {
  if (!any(f)) return(NULL)
  g <- x$qty_g_d[f & !is.na(x$qty_g_d)]
  audit_row(step, carrier_table(x), kind, cause, sum(f),
            length(unique(x$household_id[f])),
            qty_g = if (length(g) > 0) sum(g) else NA_real_,
            detail = detail)
}

# Audit rows of the fortifiable vehicle: the decision, and for "use", per
# vehicle, the records not fortifiable, those of unknown value (counted
# as fortifiable) and the households that acquired the vehicle only in a
# form that is not fortifiable.
fortifiable_log <- function(x, used, decision, v, items, out) {
  step <- "vehicle_coverage"
  vehicle_foods <- used & x$food_code %in% v$food_code
  if (is.null(decision)) {
    return(use_record_row(step, x, "note", "all_vehicle_assumed_fortifiable",
                          vehicle_foods))
  }
  if (decision == "ignore") {
    return(use_record_row(step, x, "note", "fortifiable_ignored",
                          vehicle_foods))
  }
  dplyr::bind_rows(lapply(unique(v$vehicle), function(name) {
    foods <- items$food_code[items$level == "vehicle" & items$vehicle == name]
    mine <- used & x$food_code %in% foods
    only <- out$level == "vehicle" & out$vehicle == name &
      out$acquired %in% TRUE & out$acquired_fortifiable %in% FALSE
    dplyr::bind_rows(
      use_record_row(step, x, "note", "not_fortifiable",
                     mine & x$fortifiable %in% FALSE, name),
      use_record_row(step, x, "flagged", "fortifiable_unknown",
                     mine & is.na(x$fortifiable), name),
      if (any(only)) {
        audit_row(step, "vehicle_use", "flagged", "acquired_not_fortifiable",
                  sum(only), sum(only), detail = name)
      }
    )
  }))
}

# Abort with `hcesfort_error_schema` when `use` has no fortifiable grams
# (a table built by a version before 12e.5.3).
check_use_fortifiable <- function(use, call = rlang::caller_env()) {
  if (!is.null(use[["qty_fortifiable_g_d"]])) return(invisible(TRUE))
  abort_hcesfort("schema", c(
    "{.arg use} lacks the column {.field qty_fortifiable_g_d}.",
    "i" = "It was built by an older version of hcesfort: build it again
    with {.fn vehicle_coverage}."
  ), table = "use", columns = "qty_fortifiable_g_d", call = call)
}

# Audit rows of apply_scenario(): per vehicle of the scenarios, the
# fortifiable grams over the vehicle grams of the estimated households
# (household grams, qty x AFE; not weighted by the survey weights).
fortifiable_share_log <- function(use, s) {
  vu <- use[use$level == "vehicle" & use$use_status == "estimated", ]
  dplyr::bind_rows(lapply(unique(s$vehicle), function(name) {
    r <- vu[vu$vehicle == name, ]
    total <- sum(r$qty_vehicle_g_d * r$afe)
    share <- if (total > 0) {
      format(round(sum(r$qty_fortifiable_g_d * r$afe) / total, 4),
             nsmall = 4)
    } else {
      "no grams"
    }
    audit_row("apply_scenario", "vehicle_use", "note", "fortifiable_share",
              nrow(r), nrow(r), detail = paste0(name, ": ", share))
  }))
}
