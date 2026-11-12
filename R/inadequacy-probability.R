# Probability approach of inadequacy(): a requirement distribution given
# by percentiles, linear interpolation between them, probability 1 below
# the lowest and 0 above the highest (docs/design-task10.md, section 3).

# `distribution` and `bioavailability` checked together. Returns the list
# of distributions, each as a tibble with `percentile`, `requirement` and
# `b0` (an empty list when `distribution` is NULL).
check_distribution <- function(distribution, bioavailability, nutrients,
                               call = rlang::caller_env()) {
  if (is.null(distribution)) {
    if (!is.null(bioavailability)) {
      abort_hcesfort("argument", c(
        "{.arg bioavailability} is given without {.arg distribution}."
      ), arg = "bioavailability", call = call)
    }
    return(list())
  }
  ok <- is.list(distribution) && !is.null(names(distribution)) &&
    !anyDuplicated(names(distribution)) &&
    all(names(distribution) %in% nutrients$nutrient)
  if (!ok) {
    abort_hcesfort("argument", c(
      "{.arg distribution} must be a list named by registry nutrients.",
      "i" = "Nutrients: {.val {nutrients$nutrient}}."
    ), arg = "distribution", call = call)
  }
  check_bioavailability(bioavailability, names(distribution), call)
  rlang::set_names(lapply(names(distribution), function(n) {
    unit <- nutrients$unit[nutrients$nutrient == n]
    distribution_table(distribution[[n]], n, unit, call)
  }), names(distribution))
}

# Abort unless `bioavailability` has, for each nutrient of `names`, one or
# more distinct values in (0, 1].
check_bioavailability <- function(bioavailability, names, call) {
  ok <- is.list(bioavailability) && setequal(names(bioavailability), names) &&
    all(vapply(bioavailability, function(b) {
      is.numeric(b) && length(b) > 0 && !anyNA(b) && all(b > 0 & b <= 1) &&
        !anyDuplicated(b)
    }, logical(1)))
  if (ok) {
    return(invisible(TRUE))
  }
  abort_hcesfort("argument", c(
    "{.arg bioavailability} must give values in (0, 1] for {.val {names}}.",
    "i" = paste(
      "It has no default: for example {.code list(iron = c(0.10, 0.18))}."
    )
  ), arg = "bioavailability", call = call)
}

# One requirement distribution as a tibble (percentile, requirement, b0),
# after checking its columns, its group and its order.
distribution_table <- function(d, n, unit, call) {
  req_col <- paste0("requirement_", unit, "_d")
  needed <- c("percentile", req_col, "bioavailability")
  if (!is.data.frame(d) || !all(needed %in% names(d)) ||
        !all(vapply(d[needed], is.numeric, logical(1)))) {
    abort_hcesfort("schema", c(
      "The distribution of {.val {n}} needs numeric {.field {needed}}."
    ), table = "distribution", columns = needed, call = call)
  }
  if (!is.null(d[["group"]]) && length(unique(d$group)) > 1) {
    abort_hcesfort("key", c(
      "The distribution of {.val {n}} must describe one group.",
      "x" = "Groups: {.val {unique(d$group)}}.",
      "i" = "Filter one group, for example with {.fn subset}."
    ), table = "distribution", columns = "group", rows = integer(0),
    n = length(unique(d$group)), call = call)
  }
  p <- d$percentile
  r <- d[[req_col]]
  b0 <- unique(d$bioavailability)
  ok <- nrow(d) >= 2 && !anyNA(c(p, r)) && all(diff(p) > 0) &&
    all(diff(r) >= 0) && all(p > 0 & p < 100) && length(b0) == 1 &&
    !is.na(b0) && b0 > 0 && b0 <= 1
  if (!ok) {
    abort_hcesfort("value", c(
      "The distribution of {.val {n}} is not usable.",
      "i" = paste(
        "Percentiles strictly increasing in (0, 100), requirements",
        "non-decreasing, one bioavailability in (0, 1]."
      )
    ), table = "distribution", columns = needed, rows = integer(0),
    n = NA_integer_, call = call)
  }
  dplyr::tibble(percentile = p, requirement = r, b0 = b0)
}

# Probability rows of nutrient `n`, one block per value of `b`.
probability_rows <- function(x, nutrients, n, d, b) {
  base <- risk_base(x, nutrients, n)
  dplyr::bind_rows(lapply(b, function(bi) {
    out <- base
    out$method <- "probability"
    out$ear <- NA_real_
    out$bioavailability <- bi
    out$p_inadequate <- p_inadequate_probability(out$intake, bi, d)
    out$p_inadequate[out$intake_status != "estimated"] <- NA_real_
    out
  }))
}

# 1 - F(intake * b / b0), F interpolated linearly, 0 below the table and 1
# above it.
p_inadequate_probability <- function(intake, b, d) {
  if (length(intake) == 0 || all(is.na(intake))) {
    return(rep(NA_real_, length(intake)))
  }
  f <- stats::approx(d$requirement, d$percentile / 100,
                     xout = intake * b / d$b0[[1]], yleft = 0, yright = 1,
                     ties = list("ordered", mean))$y
  1 - f
}

# Number of households whose probability is set by the tail rule.
n_tails <- function(intake, b, d) {
  eq <- intake * b / d$b0[[1]]
  sum(!is.na(eq) & (eq < min(d$requirement) | eq > max(d$requirement)))
}
