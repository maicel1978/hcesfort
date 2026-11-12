# Argument checks and audit rows of convert_units().

# The chosen priority; abort when it is missing or not one of the two
# values (no default: the choice changes the grams).
check_priority <- function(priority, call = rlang::caller_env()) {
  if (missing(priority) || !rlang::is_string(priority) ||
        !priority %in% c("food", "generic")) {
    abort_hcesfort("argument", c(
      "{.arg priority} must be {.val food} or {.val generic}.",
      "i" = paste(
        "It decides which factor is used when a record has both a factor",
        "for its food and a generic one; it has no default."
      )
    ), arg = "priority", call = call)
  }
  priority
}

# Abort unless `x` is NULL or one positive finite number.
check_optional_positive <- function(x, arg = rlang::caller_arg(x),
                                    call = rlang::caller_env()) {
  if (is.null(x) || (is.numeric(x) && length(x) == 1 && is.finite(x) &&
                       x > 0)) {
    return(invisible(x))
  }
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be {.code NULL} or one positive number."
  ), arg = arg, call = call)
}

# Abort when `food_code` or `unit` have incompatible types in the
# acquisitions and the unit factors: every lookup would fail.
check_factor_ids <- function(a, f, call = rlang::caller_env()) {
  cols <- c("food_code", "unit")
  ok <- vapply(cols, function(col) {
    all(is.na(f[[col]])) || same_id_type(a[[col]], f[[col]])
  }, logical(1))
  if (all(ok)) {
    return(invisible(TRUE))
  }
  bad <- cols[!ok]
  abort_hcesfort("join", c(
    "{.field {bad}} differ{?s/} in type between {.arg acquisitions} and
    {.arg unit_factors}.",
    "i" = "Use the same type (both character or both numeric) in both tables."
  ), table = "acquisitions", other = "unit_factors", columns = bad,
  n = NA_integer_, call = call)
}

# Audit rows of convert_units(): records received, records with both a
# food and a generic factor, records filled with the caller's density or
# piece weight, each reason for no grams, and the records converted with
# their grams per day.
units_log <- function(out, reasons, chosen, g, priority) {
  step <- "convert_units"
  hh <- function(f) length(unique(out$household_id[f]))
  grams <- function(f) sum(out$qty_g_d[f & out$grams_status == "converted"])
  row <- function(kind, cause, f, detail = NA_character_, with_g = FALSE) {
    if (!any(f)) return(NULL)
    audit_row(step, "acquisitions", kind, cause, sum(f), hh(f),
              qty_g = if (with_g) grams(f) else NA_real_, detail = detail)
  }
  assumed <- function(type, col) {
    chosen$factor_type %in% type & is.na(chosen[[col]]) & !is.na(g)
  }
  converted <- out$grams_status == "converted"
  dplyr::bind_rows(
    audit_row(step, "acquisitions", "input", "all", nrow(out), hh(TRUE)),
    row("note", "food_and_generic_factor", chosen$both,
        detail = paste("used:", priority)),
    row("filled", "density_assumed", assumed("volume_ml", "density_g_ml"),
        with_g = TRUE),
    row("filled", "piece_weight_assumed", assumed("count", "piece_weight_g"),
        with_g = TRUE),
    lapply(names(reasons), function(r) row("flagged", r, reasons[[r]])),
    row("note", "converted", converted, detail = "qty_g per day",
        with_g = TRUE)
  )
}
