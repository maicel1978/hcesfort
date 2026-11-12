#' Flag households with implausible energy intake
#'
#' Flag the households whose apparent energy intake per adult female
#' equivalent is outside a range given by the user. Nothing is excluded:
#' the flag is meant to be used as a domain or a sensitivity analysis. The
#' original ENGIH 2018 analysis used 500 and 6,000 kcal per AFE per day;
#' those limits have no published source, so they are not a default.
#'
#' @param intake Table returned by [apparent_intake()] or
#'   [apply_scenario()].
#' @param energy Energy column of the registry, for example
#'   `"energy_kcal"`; required.
#' @param lower,upper Limits of the plausible range, in the unit of `energy`
#'   per AFE per day; required. Values equal to a limit are plausible.
#' @returns `intake` with the column `energy_plausible`: `TRUE` inside the
#'   range, `FALSE` outside, `NA` when the household has no estimate. The
#'   audit log counts the households below and above the range, with the
#'   rule in `detail`.
#' @seealso [apparent_intake()], [nutrient_density()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition, nutrients
#' )
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' intake <- apparent_intake(content, afe, hces_example$households)
#' flagged <- flag_energy_plausibility(intake, "energy_kcal", 500, 6000)
#' table(flagged$energy_plausible, useNA = "ifany")
#' @export
flag_energy_plausibility <- function(intake, energy, lower, upper) {
  check_required()
  require_hces(intake, c("hces_intake", "hces_scenario_intake"))
  x <- audit_check_rows(intake, "flag_energy_plausibility")
  column <- check_nutrient_column(energy, x, arg = "energy")
  check_one_number(lower, "lower")
  check_one_number(upper, "upper")
  if (lower > upper) {
    abort_hcesfort("argument", c(
      "{.arg upper} ({upper}) is below {.arg lower} ({lower})."
    ), arg = "upper")
  }
  e <- x[[column]]
  out <- dplyr::as_tibble(x)
  out$energy_plausible <- e >= lower & e <= upper
  rule <- paste0(column, " in [", lower, ", ", upper, "]")
  step <- "flag_energy_plausibility"
  count <- function(cause, f) {
    if (!any(f)) return(NULL)
    audit_row(step, "intake", "flagged", cause, sum(f), sum(f),
              detail = rule)
  }
  log <- dplyr::bind_rows(
    audit_row(step, "intake", "input", "all", nrow(x), nrow(x),
              detail = rule),
    count("energy_below_lower", !is.na(e) & e < lower),
    count("energy_above_upper", !is.na(e) & e > upper)
  )
  same_carrier(out, x, dplyr::bind_rows(audit_get(x), log))
}

#' Nutrient density of the apparent intake
#'
#' Express each nutrient per `per` units of energy (by default per 1,000
#' kcal when the energy column is in kcal). Density does not depend on the
#' AFE or on the reference period, so it suits comparisons between groups
#' whose recorded energy differs for reasons unrelated to diet.
#'
#' @param intake Table returned by [apparent_intake()] or
#'   [apply_scenario()].
#' @param energy Energy column of the registry, for example
#'   `"energy_kcal"`; required.
#' @param per Units of energy the density refers to (one positive number).
#' @returns `intake` with one column per other nutrient, named
#'   `<nutrient column>_per_<per><energy unit>` (for example
#'   `iron_mg_per_1000kcal`). Households without an estimate or with zero
#'   energy get `NA`; the latter are counted in the audit log
#'   (`zero_energy`).
#' @seealso [apparent_intake()], [flag_energy_plausibility()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition, nutrients
#' )
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' intake <- apparent_intake(content, afe, hces_example$households)
#' d <- nutrient_density(intake, "energy_kcal")
#' summary(d$iron_mg_per_1000kcal)
#' @export
nutrient_density <- function(intake, energy, per = 1000) {
  check_required()
  require_hces(intake, c("hces_intake", "hces_scenario_intake"))
  x <- audit_check_rows(intake, "nutrient_density")
  energy <- check_nutrient_column(energy, x, "energy")
  if (is.null(per) || !is.numeric(per) || length(per) != 1 ||
        !is.finite(per) || per <= 0) {
    abort_hcesfort("argument", "{.arg per} must be one positive number.",
                   arg = "per")
  }
  nutrients <- attr(x, "nutrients", exact = TRUE)
  e <- x[[energy]]
  unit <- nutrients$unit[nutrients$column == energy]
  zero <- !is.na(e) & e <= 0
  out <- dplyr::as_tibble(x)
  for (col in setdiff(nutrients$column, energy)) {
    name <- paste0(col, "_per_", format(per, scientific = FALSE), unit)
    out[[name]] <- ifelse(zero, NA_real_, x[[col]] / e * per)
  }
  log <- audit_row("nutrient_density", "intake", "input", "all", nrow(x),
                   nrow(x), detail = paste("per", per, unit))
  if (any(zero)) {
    log <- dplyr::bind_rows(log, audit_row(
      "nutrient_density", "intake", "flagged", "zero_energy", sum(zero),
      sum(zero)
    ))
  }
  same_carrier(out, x, dplyr::bind_rows(audit_get(x), log))
}

# The name of a nutrient column of the registry stored on `x`; required.
check_nutrient_column <- function(column, x, arg = "column",
                                  call = rlang::caller_env()) {
  cols <- attr(x, "nutrients", exact = TRUE)$column
  if (!missing(column) && rlang::is_string(column) && column %in% cols) {
    return(column)
  }
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be one nutrient column of the registry.",
    "i" = "Columns: {.val {cols}}."
  ), arg = arg, call = call)
}

# `out` as a carrier of the class, key and registry of `x`, with `log`.
same_carrier <- function(out, x, log) {
  new_hces_tbl(out, class(x)[[1]], log, attr(x, "audit_key", exact = TRUE),
               attr(x, "nutrients", exact = TRUE))
}
