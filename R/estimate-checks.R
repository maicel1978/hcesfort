# Argument checks, domain cells and audit rows of the estimators.

# Abort unless `value` is one logical or numeric column of `x`, and `x` has
# households in its key.
check_value_column <- function(x, value, call = rlang::caller_env()) {
  key <- attr(x, "audit_key", exact = TRUE)
  if (!"household_id" %in% key) {
    abort_hcesfort("argument", c(
      "{.arg x} must have one row per household (and group).",
      "i" = "Pass a table returned by {.fn inadequacy}, {.fn above_ul},
      {.fn apply_scenario}, {.fn apparent_intake} or
      {.fn vehicle_coverage}."
    ), arg = "x", call = call)
  }
  ok <- rlang::is_string(value) && value %in% names(x) &&
    (is.logical(x[[value]]) || is.numeric(x[[value]]))
  if (!ok) {
    abort_hcesfort("argument", c(
      "{.arg value} must name one logical or numeric column of {.arg x}."
    ), arg = "value", call = call)
  }
  invisible(TRUE)
}

# Check the arguments of the estimators; returns where `domain` lives:
# `x_domain` (a column of `x`) or `design_domain` (a design variable).
check_estimate_args <- function(design, x, statistic, by, domain,
                                ci_method, level, df,
                                call = rlang::caller_env()) {
  bad <- function(arg, msg) {
    abort_hcesfort("argument", msg, arg = arg, call = call)
  }
  stats_ok <- c("proportion", "mean", "median")
  if (!rlang::is_string(statistic) || !statistic %in% stats_ok) {
    bad("statistic", "{.arg statistic} must be one of {.val {stats_ok}}.")
  }
  methods <- c("logit", "likelihood", "asin", "beta", "mean", "xlogit",
               "wilson")
  if (!rlang::is_string(ci_method) || !ci_method %in% methods) {
    bad("ci_method", "{.arg ci_method} must be one of {.val {methods}}.")
  }
  if (!is.numeric(level) || length(level) != 1 || is.na(level) ||
        level <= 0 || level >= 1) {
    bad("level", "{.arg level} must be one number in (0, 1).")
  }
  df_ok <- (rlang::is_string(df) && df %in% c("domain", "design")) ||
    (is.numeric(df) && length(df) == 1 && !is.na(df) && df > 0)
  if (!df_ok) {
    bad("df", "{.arg df} must be {.val domain}, {.val design} or a number.")
  }
  vars <- design$variables
  key <- attr(x, "audit_key", exact = TRUE)
  if (!is.null(by) && (!is.character(by) || !all(by %in% names(vars)) ||
                         any(by %in% c("household_id", key)))) {
    bad("by", "{.arg by} must name domain columns of the households table.")
  }
  where <- domain_place(domain, x, vars)
  if (is.na(where)) {
    bad("domain", "{.arg domain} must name a logical column of {.arg x} or
        of the households table.")
  }
  list(x_domain = if (identical(where, "x")) domain,
       design_domain = if (identical(where, "design")) domain)
}

# "x", "design", "none" (domain NULL) or NA (not found).
domain_place <- function(domain, x, vars) {
  if (is.null(domain)) return("none")
  if (!rlang::is_string(domain)) return(NA_character_)
  if (is.logical(x[[domain]])) return("x")
  if (is.logical(vars[[domain]])) return("design")
  NA_character_
}

# The cells of `by`: a tibble of their levels (one row per combination
# present in the design, sorted) and, per cell, the households of the
# design that belong to it (and to `design_domain` when given).
by_cells <- function(design, by, design_domain) {
  vars <- design$variables
  inside <- if (is.null(design_domain)) rep(TRUE, nrow(vars)) else
    vars[[design_domain]] %in% TRUE
  if (length(by) == 0) {
    return(list(levels = dplyr::tibble(.rows = 1), masks = list(inside)))
  }
  levels <- unique(dplyr::as_tibble(vars)[by])
  levels <- levels[do.call(order, unname(as.list(levels))), ]
  id <- group_id(vars, by)
  masks <- lapply(group_id(levels, by), function(g) inside & id == g)
  list(levels = levels, masks = masks)
}

# Audit rows of an estimator.
estimate_log <- function(step, design, x, value, statistic, ci_method, df,
                         out) {
  note <- function(cause, detail) {
    audit_row(step, "estimate", "note", cause, nrow(out), detail = detail)
  }
  empty <- sum(out$n == 0)
  dplyr::bind_rows(
    audit_row(step, "estimate", "input", "all", nrow(out),
              nrow(design$variables), detail = value),
    note("statistic", statistic),
    if (statistic == "proportion") note("ci_method", ci_method),
    note("df", as.character(df)),
    note("lonely_psu", attr(design, "hces_lonely_psu", exact = TRUE)),
    if (empty > 0) {
      audit_row(step, "estimate", "flagged", "empty_domain", empty)
    }
  )
}
