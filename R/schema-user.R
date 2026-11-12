# Schemas of the user-supplied tables. Design: docs/design-task2.md,
# section 6.

schema_unit_factors <- function() {
  new_schema(
    "unit_factors", c("unit", "food_code"),
    schema_col("unit", "id", "unit code or name"),
    schema_col("food_code", "id", "survey food; missing = every food",
               required = FALSE, na = TRUE),
    schema_col("factor", "number", paste(
      "per one unit: grams (mass_g), millilitres (volume_ml) or pieces",
      "(count)"
    ), bounds = "(0, Inf)"),
    schema_col("factor_type", "text", "what `factor` means",
               values = c("mass_g", "volume_ml", "count")),
    schema_col("density_g_ml", "number", "needed by volume_ml rows",
               required = FALSE, na = TRUE, bounds = "(0, Inf)"),
    schema_col("piece_weight_g", "number", "needed by count rows",
               required = FALSE, na = TRUE, bounds = "(0, Inf)"),
    schema_col("source", "text", "where the factor comes from")
  )
}

schema_crosswalk <- function() {
  new_schema(
    "crosswalk", "food_code",
    schema_col("food_code", "id", "survey food code"),
    schema_col("composition_id", "id", paste(
      "composition food; missing = no match; required when `validated` is",
      "TRUE"
    ), na = TRUE),
    schema_col("match_type", "text", paste(
      "kind of equivalence (exact, similar, proxy...); required when",
      "`validated` is TRUE"
    ), na = TRUE),
    schema_col("validated", "flag",
               "only validated rows enter the calculation"),
    schema_col("edible_portion", "number", paste(
      "edible fraction of the food as purchased"
    ), na = TRUE, bounds = "(0, 1]"),
    schema_col("yield_factor", "number", paste(
      "grams of the composition food per gram purchased"
    ), required = FALSE, na = TRUE, bounds = "(0, Inf)")
  )
}

schema_vehicles <- function() {
  new_schema(
    "vehicles", c("food_code", "vehicle"),
    schema_col("food_code", "id", "survey food code"),
    schema_col("vehicle", "text", "vehicle name"),
    schema_col("vehicle_fraction", "number",
               "fraction of the food that is the vehicle", bounds = "(0, 1]"),
    schema_col("source", "text", paste(
      "origin of the fraction; `SOURCE PENDING` is accepted and counted"
    ))
  )
}

# Composition schema for a registry; without one, a placeholder row stands
# for the nutrient columns.
schema_composition <- function(nutrients = NULL) {
  columns <- if (is.null(nutrients)) "<nutrient>_<unit>" else
    nutrients$column
  new_schema(
    "composition", "composition_id",
    schema_col("composition_id", "id", "composition food identifier"),
    schema_col(columns, "number", "content per 100 g edible portion",
               na = TRUE, bounds = "[0, Inf)"),
    schema_col("basis", "text", "basis of the values",
               values = "per_100g_edible"),
    schema_col("food_state", "text", "state the values refer to",
               values = c("raw", "cooked", "as_consumed", "unknown")),
    schema_col("source", "text", "table and edition"),
    schema_col("fortified", "flag",
               "row describes an enriched or fortified food",
               required = FALSE, na = TRUE)
  )
}

# Scenarios schema for a registry; without one, `nutrient` has no
# vocabulary.
schema_scenarios <- function(nutrients = NULL) {
  new_schema(
    "scenarios", c("scenario", "vehicle", "nutrient"),
    schema_col("scenario", "text", "scenario name"),
    schema_col("vehicle", "text", "vehicle name"),
    schema_col("nutrient", "text", "nutrient of the registry",
               values = nutrients$nutrient),
    schema_col("level_mg_kg", "number", "level added, mg per kg of vehicle",
               bounds = "[0, Inf)"),
    schema_col("level_basis", "text", "what the level measures",
               values = c("nutrient", "compound")),
    schema_col("compound", "text", "name of the compound", required = FALSE,
               na = TRUE),
    schema_col("nutrient_fraction", "number", paste(
      "mass of nutrient per mass of compound; required when `level_basis`",
      "is compound"
    ), required = FALSE, na = TRUE, bounds = "(0, 1]"),
    schema_col("compliance", "number", paste(
      "share of the vehicle actually fortified; added as 1 when absent"
    ), required = FALSE, bounds = "[0, 1]"),
    schema_col("source", "text", "standard or document")
  )
}
