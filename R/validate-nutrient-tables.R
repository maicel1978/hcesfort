# Validators of the tables whose schema depends on the nutrient registry:
# composition and scenarios. Design: docs/design-task2.md, section 6.

#' Validate a food composition table
#'
#' Check a composition table against its data contract for a set of
#' nutrients and return it as a validated table, with its audit log started
#' and the registry stored with it.
#'
#' The table needs one column per nutrient of the registry, named
#' `<nutrient>_<unit>` (for example `iron_mg`), with the content per 100 g
#' of edible portion; `basis` must be `"per_100g_edible"` (the adapter
#' converts other bases), `food_state` one of `"raw"`, `"cooked"`,
#' `"as_consumed"` or `"unknown"`, and `source` names the table and its
#' edition. See `hces_schema("composition")`.
#'
#' A nutrient column with another unit (`iron_ug` when the registry says
#' `mg`) is an `hcesfort_error_units`. Missing nutrient values are accepted,
#' never read as zero, and counted per nutrient in the audit log (cause
#' `missing_nutrient_value`, `detail` = the column).
#'
#' @inheritParams validate_households
#' @param nutrients A registry built by [nutrient_registry()].
#' @returns `x` as a tibble of class `hces_composition` (and `hces_tbl`).
#' @seealso [nutrient_registry()], [hcesfort_errors].
#' @examples
#' nutrients <- nutrient_registry(c(iron = "mg", folate = "ug_dfe"))
#' composition <- data.frame(
#'   composition_id = c("C01", "C02"), iron_mg = c(0.8, NA),
#'   folate_ug_dfe = c(8, 20), basis = "per_100g_edible",
#'   food_state = "raw", source = "invented example"
#' )
#' audit_log(validate_composition(composition, nutrients))
#' @export
validate_composition <- function(x, nutrients) {
  require_registry(nutrients)
  if (is.data.frame(x)) check_nutrient_units(x, nutrients)
  validate_table(
    x, schema_composition(nutrients), "validate_composition",
    function(x) {
      flags <- lapply(nutrients$column, function(col) is.na(x[[col]]))
      rlang::set_names(
        flags, paste0("missing_nutrient_value:", nutrients$column)
      )
    },
    nutrients = nutrients
  )
}

# Abort with hcesfort_error_units when `x` has a column named like a
# nutrient of the registry with another unit.
check_nutrient_units <- function(x, nutrients, call = rlang::caller_env()) {
  units <- sub("^\\^", "", unit_pattern)
  wrong <- unlist(lapply(seq_len(nrow(nutrients)), function(i) {
    like <- grepl(paste0("^", nutrients$nutrient[[i]], "_", units), names(x))
    setdiff(names(x)[like], nutrients$column[[i]])
  }))
  if (length(wrong) == 0) {
    return(invisible(x))
  }
  abort_hcesfort("units", c(
    "{.arg composition} has nutrient columns with another unit.",
    "x" = "Column{?s}: {.field {wrong}}.",
    "i" = "The registry expects {.field {nutrients$column}}.",
    "i" = "Convert the values, or declare the unit in the registry."
  ), table = "composition", columns = wrong, call = call)
}

#' Validate fortification scenarios
#'
#' Check a table of fortification scenarios against its data contract and
#' return it as a validated table, with its audit log started. Each row
#' gives the level of one nutrient added to one vehicle in one scenario,
#' in mg per kg of vehicle (see `hces_schema("scenarios")`).
#'
#' `level_basis` says what the level measures: the nutrient itself
#' (`"nutrient"`) or the compound that carries it (`"compound"`); in the
#' second case `nutrient_fraction`, the mass of nutrient per mass of
#' compound, is required. `nutrient` must be a nutrient of the registry.
#'
#' `compliance`, the share of the vehicle actually fortified, is optional.
#' When the column is absent it is added as 1 and the assumption is written
#' in the audit log (cause `compliance_assumed_full`), so full compliance is
#' never a hidden default.
#'
#' @inheritParams validate_composition
#' @returns `x` as a tibble of class `hces_scenarios` (and `hces_tbl`).
#' @seealso [nutrient_registry()], [hcesfort_errors].
#' @examples
#' nutrients <- nutrient_registry(c(iron = "mg"))
#' scenarios <- data.frame(
#'   scenario = "example", vehicle = "wheat flour", nutrient = "iron",
#'   level_mg_kg = 30, level_basis = "nutrient", source = "invented example"
#' )
#' audit_log(validate_scenarios(scenarios, nutrients))
#' @export
validate_scenarios <- function(x, nutrients) {
  require_registry(nutrients)
  added <- is.data.frame(x) && is.null(x$compliance)
  if (added) x$compliance <- rep(1, nrow(x))
  validate_table(
    x, schema_scenarios(nutrients), "validate_scenarios",
    function(x) list(compliance_assumed_full = rep(added, nrow(x))),
    extra = function(x, call) {
      check_required_when(x, "nutrient_fraction",
                          x$level_basis == "compound", "scenarios",
                          "`level_basis` is compound", call)
    }
  )
}
