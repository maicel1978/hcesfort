# Argument checks and audit rows of vehicle_coverage().

# Abort when `food_code` has another type in `grams` and `vehicles` (P45).
check_vehicle_food_type <- function(x, v, call = rlang::caller_env()) {
  if (nrow(x) == 0 || nrow(v) == 0 ||
        same_id_type(x$food_code, v$food_code)) {
    return(invisible(TRUE))
  }
  abort_hcesfort("join", c(
    "{.field food_code} differs in type between {.arg grams} and
    {.arg vehicles}.",
    "i" = "Convert one of them so both are text or both are numbers."
  ), table = "vehicles", other = "grams", columns = "food_code",
  n = NA_integer_, call = call)
}

# `combine` as a named list of character vectors whose elements are
# vehicle or group names; an empty list when NULL.
check_combine <- function(combine, known, call = rlang::caller_env()) {
  if (is.null(combine)) {
    return(list())
  }
  ok <- is.list(combine) && length(combine) > 0 &&
    !is.null(names(combine)) && all(nzchar(names(combine))) &&
    !anyDuplicated(names(combine)) && !any(names(combine) %in% known) &&
    all(vapply(combine, is.character, logical(1)))
  unknown <- if (ok) setdiff(unlist(combine), known) else character(0)
  if (ok && length(unknown) == 0) {
    return(combine)
  }
  abort_hcesfort("argument", c(
    "{.arg combine} must be a named list of vehicle or group names.",
    "x" = if (length(unknown) > 0) "Unknown name{?s}: {.val {unknown}}.",
    "i" = paste(
      "Names must be unique and differ from the vehicles and groups:",
      "{.val {known}}."
    )
  ), arg = "combine", call = call)
}

# Audit rows of vehicle_coverage().
vehicle_log <- function(x, reasons, used, v, items, out, status) {
  step <- "vehicle_coverage"
  rec <- function(kind, cause, f, detail = NA_character_) {
    if (!any(f)) return(NULL)
    g <- x$qty_g_d[f & !is.na(x$qty_g_d)]
    audit_row(step, carrier_table(x), kind, cause, sum(f),
              length(unique(x$household_id[f])),
              qty_g = if (length(g) > 0) sum(g) else NA_real_,
              detail = detail)
  }
  hh <- function(kind, cause, f, detail = NA_character_) {
    if (!any(f)) return(NULL)
    audit_row(step, "vehicle_use", kind, cause, sum(f),
              length(unique(out$household_id[f])), detail = detail)
  }
  absent <- setdiff(unique(v$food_code), x$food_code)
  vehicle_rows <- out$level == "vehicle"
  dplyr::bind_rows(
    rec("input", "all", rep(TRUE, nrow(x))),
    lapply(names(reasons), function(r) rec("excluded", r, reasons[[r]])),
    if (length(absent) > 0) {
      audit_row(step, "vehicles", "note", "vehicle_food_not_acquired",
                length(absent))
    },
    unlist(lapply(unique(v$vehicle), function(name) {
      foods <- items$food_code[items$level == "vehicle" &
                                 items$vehicle == name]
      mine <- used & x$food_code %in% foods
      list(rec("note", "records_of_vehicle_foods", mine, name),
           rec("flagged", "vehicle_record_without_grams",
               mine & is.na(x$qty_g_d), name))
    }), recursive = FALSE),
    lapply(unique(v$vehicle), function(name) {
      hh("flagged", "acquired_without_grams",
         vehicle_rows & out$vehicle == name & out$acquired %in% TRUE &
           out$n_records == out$n_records_no_grams, name)
    }),
    status_rows(step, "vehicle_use", status)
  )
}

# Flagged rows of a log: households by status, other than "estimated".
status_rows <- function(step, table, status) {
  lapply(sort(setdiff(unique(status), "estimated")), function(s) {
    n <- sum(status == s)
    audit_row(step, table, "flagged", s, n, n)
  })
}
