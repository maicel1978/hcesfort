# Argument checks and audit rows of flag_outliers().

# The value of a required character argument with a fixed set of choices
# and no default.
check_required_choice <- function(x, choices, arg = rlang::caller_arg(x),
                                  call = rlang::caller_env()) {
  if (!missing(x) && rlang::is_string(x) && x %in% choices) {
    return(x)
  }
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be one of {.val {choices}}.",
    "i" = "It has no default."
  ), arg = arg, call = call)
}

# Abort unless the rule of flag_outliers() is complete and coherent.
check_outlier_args <- function(g, by, probs, multiplier, min_group, type,
                               call = rlang::caller_env()) {
  bad <- function(arg, what) {
    abort_hcesfort("argument", paste0("{.arg ", arg, "} must be ", what, "."),
                   arg = arg, call = call)
  }
  if (missing(by) || !is.character(by) || length(by) == 0 ||
        !all(by %in% names(g))) {
    bad("by", "the names of one or more columns of {.arg grams}")
  }
  if (missing(probs) || !is.numeric(probs) || length(probs) != 2 ||
        anyNA(probs) || any(probs < 0 | probs > 1) || probs[1] >= probs[2]) {
    bad("probs", "two probabilities in [0, 1], lower first")
  }
  if (missing(multiplier) || !is.numeric(multiplier) ||
        length(multiplier) != 1 || !is.finite(multiplier) || multiplier < 1) {
    bad("multiplier", "one number of at least 1")
  }
  if (missing(min_group) || !rlang::is_scalar_integerish(min_group) ||
        is.na(min_group) || min_group < 1) {
    bad("min_group", "a positive whole number")
  }
  if (!rlang::is_scalar_integerish(type) || !type %in% 1:9) {
    bad("type", "a quantile algorithm from 1 to 9")
  }
  invisible(TRUE)
}

# The rule in one line, written in the log.
outlier_rule <- function(by, scale, level, probs, multiplier, min_group,
                         type) {
  paste0(
    "by=", paste(by, collapse = "+"), "; scale=", scale, "; level=", level,
    "; probs=", paste(probs, collapse = ","), "; multiplier=", multiplier,
    "; min_group=", min_group, "; type=", type
  )
}

# Audit rows of flag_outliers(): records received (with the rule), records
# flagged high and low with their grams per day, and records not assessed
# by cause.
outlier_log <- function(out, res, unit, divisor, rule) {
  step <- "flag_outliers"
  has_g <- !is.na(out$qty_g_d)
  row <- function(kind, cause, f, with_g = FALSE) {
    if (!any(f)) return(NULL)
    audit_row(step, "grams", kind, cause, sum(f),
              length(unique(out$household_id[f])),
              qty_g = if (with_g) sum(out$qty_g_d[f]) else NA_real_)
  }
  dplyr::bind_rows(
    audit_row(step, "grams", "input", "all", nrow(out),
              length(unique(out$household_id)), detail = rule),
    row("flagged", "outlier_high", has_g & res$high[unit], with_g = TRUE),
    row("flagged", "outlier_low", has_g & res$low[unit], with_g = TRUE),
    row("note", "not_assessed_no_grams", !has_g),
    row("note", "not_assessed_no_afe", has_g & is.na(divisor)),
    row("note", "not_assessed_small_group", has_g & res$small[unit])
  )
}
