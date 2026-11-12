# The nutrient registry: the set of nutrients a user works with, and the
# unit each is expressed in. Design: docs/design-task2.md, section 6.

# Base units the core computes with.
unit_bases <- c("g", "mg", "ug", "kcal", "kj")

# Regular expression of a unit: a base optionally followed by an
# equivalent tag ("ug_dfe", "ug_rae", "mg_ne").
unit_pattern <- paste0("^(", paste(unit_bases, collapse = "|"),
                       ")(_[a-z][a-z0-9]*)?$")

#' Declare the nutrients of an analysis
#'
#' The package ships no default set of nutrients: the user declares them,
#' each with its unit. The registry fixes the name of the column that holds
#' each nutrient in the composition table and in every result
#' (`<nutrient>_<unit>`, for example `iron_mg`), so units are never implicit.
#'
#' A unit is a base (`"g"`, `"mg"`, `"ug"`, `"kcal"` or `"kj"`), optionally
#' followed by an equivalent tag: `"ug_dfe"` (dietary folate equivalents),
#' `"ug_rae"` (retinol activity equivalents), `"mg_ne"` (niacin
#' equivalents). The base is what the package converts with; the tag is kept
#' as text, and conversions between a compound and its equivalent come
#' from reference tables with their source, never from the registry.
#'
#' @param units A named character vector: names are the nutrients, in snake
#'   case and unique; values are their units.
#' @returns A tibble of class `hces_nutrients` with columns `nutrient`,
#'   `unit` and `column`.
#' @seealso [validate_composition()], [validate_scenarios()].
#' @examples
#' nutrient_registry(c(energy = "kcal", iron = "mg", folate = "ug_dfe"))
#' @export
nutrient_registry <- function(units) {
  check_registry_names(units)
  bad <- names(units)[!grepl(unit_pattern, units)]
  if (length(bad) > 0) {
    abort_hcesfort("units", c(
      "{length(bad)} nutrient{?s} {?has/have} a unit that is not understood.",
      "x" = "Nutrient{?s}: {.field {bad}}.",
      "i" = paste(
        "A unit is a base ({.val {unit_bases}}), optionally followed by a",
        "tag: {.val ug_dfe}, {.val ug_rae}, {.val mg_ne}."
      )
    ), table = "units", columns = bad)
  }
  registry <- dplyr::tibble(
    nutrient = names(units), unit = unname(units),
    column = paste0(names(units), "_", units)
  )
  class(registry) <- c("hces_nutrients", class(registry))
  registry
}

# Abort unless `units` is a non-empty named character vector with unique
# snake-case names.
check_registry_names <- function(units, call = rlang::caller_env()) {
  ok <- is.character(units) && length(units) > 0 && !anyNA(units) &&
    !is.null(names(units)) &&
    all(grepl("^[a-z][a-z0-9_]*$", names(units))) &&
    !anyDuplicated(names(units))
  if (ok) {
    return(invisible(units))
  }
  abort_hcesfort("argument", c(
    "{.arg units} must be a named character vector of units.",
    "i" = paste(
      "Names are the nutrients: unique, lower-case snake case",
      "(for example {.code c(iron = \"mg\", folate = \"ug_dfe\")})."
    )
  ), arg = "units", call = call)
}

# The base of each unit: "ug" for "ug_dfe".
unit_base <- function(unit) {
  sub("_.*$", "", unit)
}

# Abort unless `nutrients` is a registry built by nutrient_registry().
require_registry <- function(nutrients, call = rlang::caller_env()) {
  if (inherits(nutrients, "hces_nutrients")) {
    return(invisible(nutrients))
  }
  abort_hcesfort("argument", c(
    "{.arg nutrients} must be a nutrient registry.",
    "i" = "Build it with {.fn nutrient_registry}."
  ), arg = "nutrients", call = call)
}
