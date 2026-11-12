# The conversions table (ref_conversions or the user's own): from a form of
# a nutrient (folic acid, retinol) to the unit of the nutrient (ug_dfe,
# ug_rae). Used to find which registry nutrients are forms of others and,
# in apply_scenario(), the factor of a form.

# Abort with hcesfort_error_schema unless `conversions` is a data frame
# with the columns the package reads, of the right type.
check_conversions <- function(conversions, call = rlang::caller_env()) {
  needed <- c(from_form = "character", from_unit = "character",
              to_unit = "character", factor = "numeric")
  ok <- is.data.frame(conversions) &&
    all(names(needed) %in% names(conversions)) &&
    all(vapply(names(needed), function(col) {
      inherits(conversions[[col]], needed[[col]])
    }, logical(1)))
  if (ok) {
    return(invisible(conversions))
  }
  abort_hcesfort("schema", c(
    "{.arg conversions} must be a data frame like {.code ref_conversions}.",
    "i" = paste(
      "It needs {.field from_form}, {.field from_unit}, {.field to_unit}",
      "(text) and {.field factor} (number)."
    )
  ), table = "conversions", columns = names(needed), call = call)
}

# The registry nutrients that are forms of another registry nutrient: a
# name that is a `from_form` of `conversions` whose `to_unit` is the unit
# of a registry nutrient (its parent). A tibble with `form`, `column`
# (column of the form) and `parent` (nutrient).
registry_forms <- function(nutrients, conversions) {
  i <- match(nutrients$nutrient, conversions$from_form)
  parent <- nutrients$nutrient[match(conversions$to_unit[i], nutrients$unit)]
  keep <- !is.na(i) & !is.na(parent) & parent != nutrients$nutrient
  dplyr::tibble(form = nutrients$nutrient[keep],
                column = nutrients$column[keep], parent = parent[keep])
}
