# The parts of an upper-level comparison and the audit rows of above_ul().

# What can be compared with the UL of requirement row `r`: a list with the
# `scope`, the columns of `x` that hold the added part (`added`), the
# registry columns whose sum is the total (`total`), the added columns not
# already in a registry total (`added_outside`), and the registry nutrients
# of the diet part (`diet`, for coverage). Aborts when a unit differs from
# `ul_unit`.
ul_parts <- function(x, nutrients, r, conversions,
                     call = rlang::caller_env()) {
  col <- nutrients$column[nutrients$nutrient == r$nutrient]
  if (r$ul_applies_to == "total") {
    check_ul_unit(r, nutrients$unit[nutrients$nutrient == r$nutrient], call)
    added <- intersect(paste0(col, "_added"), names(x))
    return(list(scope = "total_intake", added = added, total = col,
                added_outside = character(0), diet = r$nutrient))
  }
  cv <- conversions[conversions$ul_form %in% r$ul_applies_to, ]
  reg <- cv$from_form %in% nutrients$nutrient
  i <- match(cv$from_form, nutrients$nutrient)
  form_col <- ifelse(reg, nutrients$column[i],
                     paste0(cv$from_form, "_", cv$from_unit))
  form_unit <- ifelse(reg, nutrients$unit[i], cv$from_unit)
  present <- paste0(form_col, "_added") %in% names(x)
  check_ul_unit(r, unique(form_unit[reg | present]), call)
  diet <- unique(cv$from_form[reg])
  added <- unique(paste0(form_col, "_added")[present])
  scope <- if (length(diet) > 0) "form_diet_and_added" else
    if (length(added) > 0) "form_added_only" else "not_assessable"
  list(scope = scope, added = added, total = unique(form_col[reg]),
       added_outside = unique(paste0(form_col, "_added")[present & !reg]),
       diet = diet)
}

# Abort with hcesfort_error_units when a unit compared differs from the
# unit of the UL.
check_ul_unit <- function(r, units, call) {
  bad <- setdiff(units, r$ul_unit)
  if (length(bad) == 0) {
    return(invisible(TRUE))
  }
  abort_hcesfort("units", c(
    "The UL of {.val {r$nutrient}} is in {.val {r$ul_unit}}.",
    "x" = "It would be compared with an amount in {.val {bad}}.",
    "i" = paste(
      "Give {.field ul_unit} in the unit of the intake the UL applies to",
      "(the registry unit for total intake, the mass of the form otherwise)."
    )
  ), table = "requirements", columns = "ul_unit", call = call)
}

# Audit rows of above_ul().
above_ul_log <- function(x, req, parts, cov, min_coverage) {
  step <- "above_ul"
  scope <- vapply(parts, `[[`, "", "scope")
  row <- function(cause, f, detail) {
    if (!any(f)) return(NULL)
    audit_row(step, "above_ul", "note", cause, nrow(x), detail = detail[f])
  }
  dplyr::bind_rows(
    audit_row(step, "above_ul", "input", "all", nrow(x),
              length(unique(x$household_id))),
    row("ul_scope", rep(TRUE, nrow(req)), paste0(req$nutrient, ": ", scope)),
    row("not_assessable", scope == "not_assessable", req$nutrient),
    row("added_only_lower_bound", scope == "form_added_only", req$nutrient),
    if (length(cov) > 0) {
      audit_row(step, "above_ul", "note", "coverage",
                sum(x$intake_status == "estimated"),
                detail = paste0(names(cov), ": ", format(round(cov, 4)),
                                " (min_coverage ", min_coverage, ")"))
    },
    not_estimated_rows(step, "above_ul", x)
  )
}
