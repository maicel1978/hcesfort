# Level basis of apply_scenario(): a level in mg per kg of vehicle becomes
# an amount per 100 g of vehicle in the unit of the registry nutrient, by
# three explicit factors (docs/design-task9.md, section 5):
#   level_mg_kg x nutrient_fraction x (mg -> unit) / 10 x equivalent factor.

# Units of each mass unit in one mg (written so that the factors are exact
# in floating point: 1000 ug, not 1e-3 / 1e-6).
mass_units <- c(g = 1e-3, mg = 1, ug = 1000)

# Factor from mg per kg to `unit` per 100 g.
mg_kg_to_per_100g <- function(unit) {
  unname(mass_units[unit] / 10)
}

# One row per amount a scenario row adds: to the column of its nutrient
# (`target = "nutrient"`) and, when the level is a mass of a form with an
# equivalent factor, to the column of the form in its own mass unit
# (`target = "form"`, named `<form>_<unit>`, or the registry column when
# the form is a registry nutrient). `per_100g` includes compliance.
scenario_targets <- function(s, nutrients, conversions,
                             call = rlang::caller_env()) {
  unit <- nutrients$unit[match(s$nutrient, nutrients$nutrient)]
  check_scenario_units(s, unit, call)
  form <- if (is.null(s[["form"]])) rep(NA_character_, nrow(s)) else s$form
  conv <- scenario_conversions(s, form, unit, conversions, call)
  fraction <- ifelse(s$level_basis == "compound", s$nutrient_fraction, 1)
  mass_mg <- s$level_mg_kg * fraction * s$compliance
  form_unit <- conv$from_unit
  in_registry <- form %in% nutrients$nutrient
  form_unit[in_registry] <- nutrients$unit[match(form[in_registry],
                                                 nutrients$nutrient)]
  form_col <- paste0(form, "_", form_unit)
  form_col[in_registry] <- nutrients$column[match(form[in_registry],
                                                  nutrients$nutrient)]
  tagged <- !is.na(conv$factor)
  nutrient_amount <- as.double(ifelse(
    tagged, mass_mg * mg_kg_to_per_100g(conv$from_unit) * conv$factor,
    mass_mg * mg_kg_to_per_100g(unit_base(unit))
  ))
  rows <- dplyr::tibble(
    scenario = s$scenario, vehicle = s$vehicle, target = "nutrient",
    column = nutrients$column[match(s$nutrient, nutrients$nutrient)],
    per_100g = nutrient_amount
  )
  forms <- dplyr::tibble(
    scenario = s$scenario[tagged], vehicle = s$vehicle[tagged],
    target = "form", column = form_col[tagged],
    per_100g = mass_mg[tagged] * mg_kg_to_per_100g(form_unit[tagged])
  )
  dplyr::bind_rows(rows, forms)
}

# Abort with hcesfort_error_units when a scenario row names an energy
# nutrient, or a nutrient whose unit is not a mass.
check_scenario_units <- function(s, unit, call) {
  rows <- which(!unit_base(unit) %in% names(mass_units))
  if (length(rows) == 0) {
    return(invisible(s))
  }
  abort_hcesfort("units", c(
    "A fortification level must be added to a nutrient measured in mass.",
    "x" = cli_escape(problem_bullet("nutrient in energy units", rows)),
    "i" = "Remove these rows from {.arg scenarios}."
  ), table = "scenarios", columns = "nutrient", call = call)
}

# For each scenario row, the conversion of its form (from_unit, factor):
# required when the unit of the nutrient carries an equivalent tag; both
# missing for an untagged unit.
scenario_conversions <- function(s, form, unit, conversions, call) {
  tagged <- grepl("_", unit)
  key <- paste(form, unit, sep = "\r")
  i <- match(key, paste(conversions$from_form, conversions$to_unit,
                        sep = "\r"))
  from_unit <- conversions$from_unit[i]
  factor <- conversions$factor[i]
  no_form <- which(tagged & is.na(form))
  bad <- which(tagged & !is.na(form) &
                 (is.na(i) | !from_unit %in% names(mass_units) |
                    is.na(factor)))
  if (length(no_form) + length(bad) > 0) {
    abort_hcesfort("units", c(
      "{.arg scenarios} has levels that cannot become an equivalent.",
      "x" = cli_escape(problem_bullet(
        "`form` missing for a nutrient in equivalents", no_form
      )),
      "x" = cli_escape(problem_bullet(
        "`form` without a mass conversion to the unit of the nutrient", bad
      )),
      "i" = paste(
        "Name in {.field form} a {.field from_form} of {.arg conversions}",
        "whose {.field to_unit} is the unit of the nutrient."
      )
    ), table = "scenarios", columns = "form", call = call)
  }
  from_unit[!tagged] <- NA_character_
  factor[!tagged] <- NA_real_
  list(from_unit = from_unit, factor = factor)
}
