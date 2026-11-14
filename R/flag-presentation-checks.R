# Checks and audit rows of flag_presentation().

presentation_criteria <- c(
  "conf_level", "min_n", "min_n_effective", "small_absolute_width",
  "large_absolute_width", "max_relative_width", "min_df"
)

# The thresholds of `standard` as a named list, after checking: a data
# frame with `criterion` (text) and `value` (number), each criterion once,
# every value finite, conf_level in (0, 1) and the others at least 0.
standard_values <- function(standard, call = rlang::caller_env()) {
  ok <- is.data.frame(standard) && is.character(standard$criterion) &&
    is.numeric(standard$value) &&
    setequal(standard$criterion, presentation_criteria) &&
    !anyDuplicated(standard$criterion) && all(is.finite(standard$value))
  if (ok) {
    s <- as.list(stats::setNames(standard$value, standard$criterion))
    ok <- s$conf_level > 0 && s$conf_level < 1 &&
      all(unlist(s[presentation_criteria[-1]]) >= 0)
  }
  if (ok) return(s)
  abort_hcesfort("schema", c(
    "{.arg standard} must be a table like {.code ref_presentation_standard}.",
    "i" = "It needs {.field criterion} (text) and {.field value} (number),
    one row for each of {.val {presentation_criteria}}.",
    "i" = "Values are finite; {.val conf_level} is in (0, 1) and the others
    are 0 or more."
  ), table = "standard", columns = c("criterion", "value"), call = call)
}

# Abort unless every proportion of `x` has the Korn-Graubard interval at
# the confidence level of the standard, the interval the standards judge.
check_presentation_input <- function(x, s, call = rlang::caller_env()) {
  if (is.null(x[["ci_method"]])) {
    abort_hcesfort("argument", c(
      "{.arg estimates} has no column {.field ci_method}.",
      "i" = "Estimate again with this version of hcesfort."
    ), arg = "estimates", call = call)
  }
  prop <- x$statistic %in% "proportion"
  bad <- prop & (!x$ci_method %in% "korn_graubard" |
                   abs(x$conf_level - s$conf_level) > 1e-12)
  if (!any(bad %in% TRUE)) return(invisible(TRUE))
  abort_hcesfort("argument", c(
    "The standards judge the Korn-Graubard interval at a confidence level
    of {s$conf_level}.",
    "x" = "{sum(bad)} proportion{?s} of {.arg estimates} {?was/were}
    estimated otherwise.",
    "i" = "Use {.code estimate_households(ci_method = \"korn_graubard\",
    level = {s$conf_level})}."
  ), arg = "estimates", call = call)
}

# Audit rows: the standard applied, then one row per status and per
# reason that occurs, and the estimates without a status.
presentation_log <- function(out, s) {
  step <- "flag_presentation"
  rule <- paste0(names(s), " = ", unlist(s), collapse = "; ")
  count <- function(kind, values, cause, label = cause) {
    n <- sum(values %in% cause)
    if (n == 0) return(NULL)
    audit_row(step, "estimate", kind, label, n)
  }
  reasons <- c("sample_size", "effective_sample_size", "absolute_width",
               "relative_width", "zero_events", "degrees_of_freedom")
  dplyr::bind_rows(
    audit_row(step, "estimate", "note", "standard", nrow(out),
              detail = rule),
    count("note", out$presentation, "present"),
    count("flagged", out$presentation, "review"),
    count("flagged", out$presentation, "suppress"),
    lapply(reasons, function(r) count("flagged", out$presentation_reason, r)),
    count("flagged", is.na(out$presentation), TRUE,
          "presentation_undefined"),
    count("flagged", out$complement_unreliable, TRUE,
          "complement_unreliable")
  )
}
