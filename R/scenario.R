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
#' vehicles of `qty_fortifiable_g_d` (from [vehicle_coverage()]: the grams
#' of the vehicle that could have been fortified, all of them unless the
#' acquisitions say otherwise) times the amount per 100 g, divided by 100.
#' A vehicle of own production or home processing gets nothing. The log
#' notes, per vehicle, the fortifiable grams over the vehicle grams of the
#' estimated households (`fortifiable_share`, unweighted).
#'
#' `compliance` is the share of the fortifiable vehicle that is fortified;
#' it enters under the model named by `compliance_model`, which has no
#' default and is required whenever a compliance is below 1. The scenarios
#' with a compliance below 1 are listed in the log (`compliance_below_one`).
#'
#' - `"average_content"`: every fortifiable gram carries `compliance` times
#'   the level. It gives the right mean but understates the share of
#'   households above an upper level, since no household receives the full
#'   level: [above_ul()] flags each scenario with a compliance below 1, and
#'   the same levels at compliance 1 give the upper bound.
#' - `"all_or_nothing"`: a share `compliance` of each vehicle carries the
#'   full level and the rest none, and a household has one or the other for
#'   the whole period. A scenario with `k` vehicles of compliance strictly
#'   between 0 and 1 has `2^k` states, each a subset of those vehicles at the
#'   full level (vehicles at compliance 1 are always on, at 0 always off);
#'   vehicles are assumed independent, so the probability of a state is the
#'   product of `compliance` over its vehicles on and `1 - compliance` over
#'   those off. Every vehicle of a scenario must have one compliance (a
#'   compliance that differs by nutrient is under-dosing, which is average
#'   content); otherwise an `hcesfort_error_value`. The result is the table
#'   of states described under Value: one row per household for each state,
#'   so the number of rows is the households times the sum of `2^k` over the
#'   scenarios (1 for the baseline). The expected amounts over the states
#'   equal those of average content, so the means of intake by scenario are
#'   those of average content; percentiles of intake under all or nothing
#'   are not offered. The log holds a note `states` per scenario and a note
#'   `vehicles_assumed_independent` for each scenario with more than one
#'   vehicle of partial compliance.
#'
#' Totals are missing for households whose intake is not `estimated`. A
#' household that acquired a vehicle with records without grams gets what
#' its records with grams give, and is counted (`added_understated`).
#'
#' @param intake Table returned by [apparent_intake()] on a baseline
#'   composition.
#' @param use Table returned by [vehicle_coverage()] for the same
#'   households (by this version: a table without `qty_fortifiable_g_d` is
#'   an `hcesfort_error_schema`).
#' @param scenarios Scenarios table ([hces_schema()]`("scenarios")`),
#'   validated or not. Every `vehicle` must be a vehicle of `use`.
#' @param conversions Conversions table, by default [ref_conversions].
#' @param compliance_model `NULL`, `"average_content"` or
#'   `"all_or_nothing"`; required when a compliance is below 1.
#' @param baseline_label Name of the scenario that holds the baseline.
#' @returns A tibble of class `hces_scenario_intake` (and `hces_tbl`), key
#'   `scenario` + `household_id`: the column `scenario`, the columns of
#'   `intake` (nutrient columns now hold the total of the scenario; the
#'   `_coverage` columns are those of the baseline) and one `<column>_added`
#'   per nutrient or form touched by any scenario (0 under the baseline).
#'   The baseline is `total - added`. The registry travels with the table.
#'
#'   Under `compliance_model = "all_or_nothing"`, a tibble of class
#'   `hces_scenario_states` (and `hces_tbl`; it does not inherit from
#'   `hces_scenario_intake`), key `scenario` + `state` + `household_id`: the
#'   same columns for each state, with the vehicles of the state at the full
#'   level, plus `state` (the vehicles on, sorted and joined by `"+"`, or
#'   `"none"`) and `state_probability`. The baseline has one state, `"none"`,
#'   with probability 1.
#' @seealso [vehicle_coverage()], [unfortified_baseline()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' baseline <- unfortified_baseline(hces_example$composition,
#'                                  hces_example$enrichment, nutrients)
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' content <- link_composition(grams, hces_example$crosswalk, baseline)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' intake <- apparent_intake(content, afe, hces_example$households)
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households, fortifiable = "use")
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
  check_use_fortifiable(use)
  states <- identical(compliance_model, "all_or_nothing")
  if (states) check_vehicle_compliance(s)
  targets <- scenario_targets(if (states) at_full_level(s) else s,
                              nutrients, conversions)
  names_s <- c(baseline_label, unique(s$scenario))
  added_cols <- unique(targets$column)
  out <- if (states) {
    states_rows(x, use, s, targets, names_s, added_cols)
  } else {
    dplyr::bind_rows(lapply(names_s, function(name) {
      scenario_rows(x, use, targets[targets$scenario == name, ], name,
                    added_cols)
    }))
  }
  class <- if (states) "hces_scenario_states" else "hces_scenario_intake"
  table <- sub("^hces_", "", class)
  log <- scenario_log(x, use, s, out, names_s, added_cols, compliance_model,
                      table)
  log <- dplyr::bind_rows(audit_combine(x, use, s), log,
                          if (states) states_log(s, table),
                          fortifiable_share_log(use, s))
  new_hces_tbl(out, class, log,
               c("scenario", if (states) "state", "household_id"), nutrients)
}

# The rows of one scenario: `x` with its name, the amounts added to each
# column of `added_cols` (0 when the scenario does not touch it; missing
# for households not estimated) and the totals of the registry columns.
scenario_rows <- function(x, use, rows, name, added_cols) {
  vu <- use[use$level == "vehicle", ]
  qty <- function(vehicle) {
    key <- paste(vu$household_id, vu$vehicle, sep = "\r")
    vu$qty_fortifiable_g_d[match(paste(x$household_id, vehicle, sep = "\r"),
                                 key)]
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
