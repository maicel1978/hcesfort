#' Apparent intake under fortification scenarios
#'
#' Add to the baseline intake of each household what each scenario puts in
#' the vehicles it acquires. The result has one row per scenario and
#' household, the baseline included as a scenario of its own, so every
#' later table compares scenarios with the baseline.
#'
#' **The intake must be built on an unfortified baseline.** The audit log of
#' `intake` must hold the step [unfortified_baseline()]; otherwise the call
#' fails, because adding a fortificant to a composition that already holds
#' it counts it twice (E1). A composition with nothing to remove needs one
#' call with an empty `enrichment` table.
#'
#' A level in mg per kg of vehicle becomes an amount per 100 g of vehicle in
#' the unit of the nutrient by three stated factors: `nutrient_fraction`
#' (compound to form; 1 when `level_basis` is `"nutrient"`), the mass unit
#' of the nutrient (mg per kg to unit per 100 g), and, when the unit is an
#' equivalent (DFE, RAE), the factor of the `form` in `conversions` (folic
#' acid to DFE, retinol to RAE). A scenario row for a nutrient in
#' equivalents without `form` is an `hcesfort_error_units`. When the level
#' is a mass of a form with such a factor, the amount of the form is also
#' returned in its own mass unit (`folic_acid_ug_added`), because upper
#' levels apply to the form; if the form is itself a registry nutrient, its
#' total is updated too. Losses in storage and cooking are not applied.
#'
#' Added per household, scenario and nutrient: the sum over the scenario's
#' vehicles of `qty_vehicle_g_d` (from [vehicle_coverage()]) times the
#' amount per 100 g, divided by 100. `compliance` enters under the model
#' named by `compliance_model`; v0.1 offers `"average_content"`: every gram
#' of vehicle carries `compliance` times the level. The argument has no
#' default and is required whenever a compliance is below 1.
#'
#' Totals are missing for households whose intake is not `estimated`. A
#' household that acquired a vehicle with records without grams gets what
#' its records with grams give, and is counted (`added_understated`).
#'
#' @param intake Table returned by [apparent_intake()] on a baseline
#'   composition.
#' @param use Table returned by [vehicle_coverage()] for the same
#'   households.
#' @param scenarios Scenarios table ([hces_schema()]`("scenarios")`),
#'   validated or not. Every `vehicle` must be a vehicle of `use`.
#' @param conversions Conversions table, by default [ref_conversions].
#' @param compliance_model `NULL` or `"average_content"`; required when a
#'   compliance is below 1.
#' @param baseline_label Name of the scenario that holds the baseline.
#' @returns A tibble of class `hces_scenario_intake` (and `hces_tbl`), key
#'   `scenario` + `household_id`: the column `scenario`, the columns of
#'   `intake` (nutrient columns now hold the total of the scenario; the
#'   `_coverage` columns are those of the baseline) and one `<column>_added`
#'   per nutrient or form touched by any scenario (0 under the baseline).
#'   The baseline is `total - added`. The registry travels with the table.
#' @seealso [vehicle_coverage()], [unfortified_baseline()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' baseline <- unfortified_baseline(hces_example$composition,
#'                                  hces_example$enrichment, nutrients)
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' content <- link_composition(grams, hces_example$crosswalk, baseline)
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' intake <- apparent_intake(content, afe, hces_example$households)
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households)
#' s <- apply_scenario(intake, use, hces_example$scenarios,
#'                     compliance_model = "average_content")
#' tapply(s$iron_mg, s$scenario, mean, na.rm = TRUE)
#' @export
apply_scenario <- function(intake, use, scenarios,
                           conversions = hcesfort::ref_conversions,
                           compliance_model = NULL,
                           baseline_label = "baseline") {
  check_required()
  require_hces(intake, "hces_intake")
  require_hces(use, "hces_vehicle_use")
  x <- audit_check_rows(intake, "apply_scenario")
  nutrients <- attr(x, "nutrients", exact = TRUE)
  s <- validate_scenarios(scenarios, nutrients)
  check_baseline_step(x)
  check_conversions(conversions)
  check_scenario_args(s, compliance_model, baseline_label)
  check_scenario_use(x, use, s)
  targets <- scenario_targets(s, nutrients, conversions)
  names_s <- c(baseline_label, unique(s$scenario))
  added_cols <- unique(targets$column)
  out <- dplyr::bind_rows(lapply(names_s, function(name) {
    scenario_rows(x, use, targets[targets$scenario == name, ], name,
                  added_cols)
  }))
  log <- scenario_log(x, use, s, out, names_s, added_cols, compliance_model)
  log <- dplyr::bind_rows(audit_get(x), audit_get(use), audit_get(s), log)
  new_hces_tbl(out, "hces_scenario_intake", log,
               c("scenario", "household_id"), nutrients)
}

# The rows of one scenario: `x` with its name, the amounts added to each
# column of `added_cols` (0 when the scenario does not touch it; missing
# for households not estimated) and the totals of the registry columns.
scenario_rows <- function(x, use, rows, name, added_cols) {
  vu <- use[use$level == "vehicle", ]
  qty <- function(vehicle) {
    vu$qty_vehicle_g_d[match(paste(x$household_id, vehicle, sep = "\r"),
                             paste(vu$household_id, vu$vehicle, sep = "\r"))]
  }
  ok <- x$intake_status == "estimated"
  one <- dplyr::bind_cols(dplyr::tibble(scenario = rep(name, nrow(x))),
                          dplyr::as_tibble(x))
  for (col in added_cols) {
    add <- rep(0, nrow(x))
    for (r in which(rows$column == col)) {
      add <- add + qty(rows$vehicle[r]) * rows$per_100g[r] / 100
    }
    add[!ok] <- NA_real_
    if (!is.null(one[[col]])) one[[col]] <- one[[col]] + add
    one[[paste0(col, "_added")]] <- add
  }
  one
}
