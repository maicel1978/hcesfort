# Checks shared by inadequacy() and above_ul(): the requirements table,
# the minimum coverage and the overall coverage of each nutrient.

# A required share: one number in [0, 1], named `arg` in the message.
check_share_arg <- function(value, arg, what, call = rlang::caller_env()) {
  if (!missing(value) && is.numeric(value) && length(value) == 1 &&
        !is.na(value) && value >= 0 && value <= 1) {
    return(value)
  }
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be one number in [0, 1].",
    "i" = "It has no default; 0 accepts any {what} and says so in the log."
  ), arg = arg, call = call)
}

# `min_coverage`: required, one number in [0, 1].
check_min_coverage <- function(min_coverage, call = rlang::caller_env()) {
  if (missing(min_coverage)) min_coverage <- NULL
  check_share_arg(min_coverage, "min_coverage", "coverage", call)
}

# `min_records_used`: required, one number in [0, 1].
check_min_records_used <- function(min_records_used,
                                   call = rlang::caller_env()) {
  if (missing(min_records_used)) min_records_used <- NULL
  check_share_arg(min_records_used, "min_records_used", "record loss", call)
}

# Overall record loss on the baseline: used over included records of the
# households with at least one included record, whatever their status,
# unweighted; and the same share by purchased grams, read from the log of
# apparent_intake(). Abort with hcesfort_error_coverage (measure
# "records_used") below `min_records_used`. Returns both shares.
check_records_used <- function(x, min_records_used,
                               call = rlang::caller_env()) {
  one <- if (is.null(x[["scenario"]])) x else x[x$scenario == x$scenario[1], ]
  n_inc <- sum(one$n_records_included)
  shares <- c(records = if (n_inc > 0) sum(one$n_records_used) / n_inc else
                NA_real_,
              grams = grams_used_share(x))
  if (is.na(shares[["records"]]) || shares[["records"]] >= min_records_used) {
    return(shares)
  }
  shown <- format(round(shares, 3))
  abort_hcesfort("coverage", c(
    "The share of included records used is below {.arg min_records_used} =
    {min_records_used}.",
    "x" = cli_escape(paste0("Records used: ", shown[[1]],
                            " (by purchased grams: ", shown[[2]], ").")),
    "i" = paste(
      "Rank the foods lost with {.fn unmatched_foods} and fix their unit",
      "factors or crosswalk rows, or lower {.arg min_records_used}."
    )
  ), measure = "records_used", nutrients = character(0),
  coverage = shares[["records"]], shares = shares,
  min_coverage = min_records_used, call = call)
}

# Overall share of the purchased grams of the included records that were
# used, from the rows of apparent_intake() in the log of `x`.
grams_used_share <- function(x) {
  log <- audit_get(x)
  l <- log[log$step == "apparent_intake" & log$table == "nutrient_content", ]
  g <- function(cause) sum(l$qty_g[l$cause == cause])
  if (!any(l$cause == "all")) return(NA_real_)
  inc <- g("all") - g("not_included")
  if (is.na(inc) || inc <= 0) NA_real_ else g("used") / inc
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
    paste(
      "The share of the edible grams used that have a composition value",
      "is below {.arg min_coverage} = {min_coverage}."
    ),
    "x" = cli_escape(paste0("Below: ", paste(shown, collapse = ", "), ".")),
    "i" = paste(
      "Fill the gaps with {.fn fill_composition}, or leave these",
      "nutrients out of {.arg requirements}. Records that never reached",
      "the sum are gated by {.arg min_records_used}."
    )
  ), measure = "composition_value", nutrients = names(cov)[low],
  coverage = unname(cov[low]), min_coverage = min_coverage, call = call)
}

# The column `cutpoint_valid` of `requirements`: present, logical, never
# missing where `ear` has a value; `ear_bioavailability`, when present, a
# number in (0, 1] or missing.
check_cutpoint_columns <- function(requirements, call = rlang::caller_env()) {
  if (!is.data.frame(requirements)) return(invisible(TRUE))
  v <- requirements[["cutpoint_valid"]]
  if (is.null(v)) {
    abort_hcesfort("schema", c(
      "{.arg requirements} lacks the column {.field cutpoint_valid}.",
      "i" = paste(
        "Add it: {.val {FALSE}} where the requirement is skewed and the EAR",
        "cut-point does not apply (iron), {.val {TRUE}} otherwise. See",
        "{.code ref_requirements}."
      )
    ), table = "requirements", columns = "cutpoint_valid", call = call)
  }
  ear <- requirements[["ear"]]
  has_ear <- if (is.null(ear)) rep(FALSE, nrow(requirements)) else !is.na(ear)
  b <- requirements[["ear_bioavailability"]]
  bad_b <- !is.null(b) &&
    (!is.numeric(b) || any(!is.na(b) & (b <= 0 | b > 1)))
  if (!is.logical(v) || anyNA(v[has_ear]) || bad_b) {
    col <- if (bad_b) "ear_bioavailability" else "cutpoint_valid"
    abort_hcesfort("value", c(
      "{.field {col}} of {.arg requirements} has invalid values.",
      "i" = paste(
        "{.field cutpoint_valid} is TRUE or FALSE wherever {.field ear} has",
        "a value; {.field ear_bioavailability} a number in (0, 1] or NA."
      )
    ), table = "requirements", columns = col, call = call)
  }
  invisible(TRUE)
}

# Abort with hcesfort_error_value when a nutrient whose cut-point is not
# valid would be assessed by it (no entry in `dist`).
check_cutpoint_valid <- function(req, dist, call = rlang::caller_env()) {
  bad <- req$nutrient[!req$cutpoint_valid & !req$nutrient %in% names(dist)]
  if (length(bad) == 0) {
    return(invisible(TRUE))
  }
  abort_hcesfort("value", c(
    "The EAR cut-point is not valid for {.val {bad}}: the requirement is
    skewed ({.field cutpoint_valid} is FALSE).",
    "i" = paste(
      "Pass its requirement distribution in {.arg distribution} (as",
      "{.code ref_iron_requirements} for iron), or leave it out of",
      "{.arg requirements}."
    )
  ), table = "requirements", columns = "cutpoint_valid", n = length(bad),
  call = call)
}
