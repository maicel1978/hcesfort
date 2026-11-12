# Checks shared by inadequacy() and above_ul(): the requirements table,
# the minimum coverage and the overall coverage of each nutrient.

# `min_coverage`: required, one number in [0, 1].
check_min_coverage <- function(min_coverage, call = rlang::caller_env()) {
  if (!missing(min_coverage) && is.numeric(min_coverage) &&
        length(min_coverage) == 1 && !is.na(min_coverage) &&
        min_coverage >= 0 && min_coverage <= 1) {
    return(min_coverage)
  }
  abort_hcesfort("argument", c(
    "{.arg min_coverage} must be one number in [0, 1].",
    "i" = "It has no default; 0 accepts any coverage and says so in the log."
  ), arg = "min_coverage", call = call)
}

# The rows of `requirements` for registry nutrients with a value in
# `value_col`, after checking columns, one row per nutrient and units. The
# nutrients of `requirements` outside the registry are the attribute
# `outside`.
check_requirements <- function(requirements, nutrients, value_col,
                               extra = character(0),
                               call = rlang::caller_env()) {
  needed <- c("nutrient", "unit", value_col, extra)
  if (!is.data.frame(requirements) ||
        !all(needed %in% names(requirements))) {
    abort_hcesfort("schema", c(
      "{.arg requirements} must be a data frame with {.field {needed}}.",
      "i" = "See {.code ref_requirements}."
    ), table = "requirements", columns = needed, call = call)
  }
  r <- dplyr::as_tibble(requirements)
  mine <- r$nutrient %in% nutrients$nutrient
  dup <- which(mine & duplicated(r$nutrient))
  if (length(dup) > 0) {
    abort_hcesfort("key", c(
      "{.arg requirements} must have one row per nutrient.",
      "x" = cli_escape(problem_bullet("second row of a nutrient", dup)),
      "i" = "Select the population group first (one sex and age)."
    ), table = "requirements", columns = "nutrient", rows = dup,
    n = length(dup), call = call)
  }
  r <- r[mine & !is.na(r[[value_col]]), ]
  expected <- nutrients$unit[match(r$nutrient, nutrients$nutrient)]
  bad <- r$nutrient[r$unit != expected]
  if (length(bad) > 0) {
    abort_hcesfort("units", c(
      "{.arg requirements} and the registry disagree on units.",
      "x" = "Nutrient{?s}: {.val {bad}}.",
      "i" = "Convert the requirement to the registry unit."
    ), table = "requirements", columns = "unit", call = call)
  }
  attr(r, "outside") <- unique(requirements$nutrient[!mine])
  r
}

# Overall coverage of each nutrient of `assessed`: the share of the edible
# grams of the estimated households (weighted by AFE) with a value, on the
# baseline. Abort with hcesfort_error_coverage below `min_coverage`.
check_coverage <- function(x, nutrients, assessed, min_coverage,
                           call = rlang::caller_env()) {
  one <- if (is.null(x[["scenario"]])) x else x[x$scenario == x$scenario[1], ]
  est <- one$intake_status == "estimated"
  w <- one$qty_edible_g_d[est] * one$afe[est]
  cov <- vapply(assessed, function(n) {
    col <- nutrients$column[nutrients$nutrient == n]
    v <- one[[paste0(col, "_coverage")]][est]
    if (sum(w) > 0) sum((v * w)[w > 0]) / sum(w) else NA_real_
  }, numeric(1))
  low <- !is.na(cov) & cov < min_coverage
  if (!any(low)) {
    return(cov)
  }
  shown <- paste0(names(cov)[low], " (", format(round(cov[low], 3)), ")")
  abort_hcesfort("coverage", c(
    "Coverage is below {.arg min_coverage} = {min_coverage}.",
    "x" = cli_escape(paste0("Below: ", paste(shown, collapse = ", "), ".")),
    "i" = paste(
      "Fill the gaps with {.fn fill_composition}, or leave these",
      "nutrients out of {.arg requirements}."
    )
  ), nutrients = names(cov)[low], coverage = unname(cov[low]),
  min_coverage = min_coverage, call = call)
}
