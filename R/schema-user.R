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
    schema_col("vehicle_group", "text", paste(
      "vehicles that share one substance (flour, bread, pasta: wheat flour);",
      "a food has at most one vehicle of each group"
    ), required = FALSE, na = TRUE),
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

# Schema of the values that fill gaps of a composition table; without a
# registry, `nutrient` has no vocabulary.
schema_composition_fills <- function(nutrients = NULL) {
  new_schema(
    "composition_fills", c("composition_id", "nutrient"),
    schema_col("composition_id", "id", "composition food to fill"),
    schema_col("nutrient", "text", "nutrient of the registry",
               values = nutrients$nutrient),
    schema_col("value", "number", paste(
      "content per 100 g edible portion, in the unit of the registry"
    ), bounds = "[0, Inf)"),
    schema_col("source", "text", paste(
      "where the value comes from (a borrowed food, a rule such as",
      "\"zero in unprocessed plant foods\")"
    ))
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
    schema_col("form", "text", paste(
      "form of the nutrient the level is a mass of (a `from_form` of the",
      "conversions table); required when the unit of the nutrient is an",
      "equivalent (DFE, RAE)"
    ), required = FALSE, na = TRUE),
    schema_col("nutrient_fraction", "number", paste(
      "mass of the form per mass of compound; required when `level_basis`",
      "is compound, missing when it is nutrient"
    ), required = FALSE, na = TRUE, bounds = "(0, 1]"),
    schema_col("compliance", "number", paste(
      "share of the vehicle actually fortified; added as 1 when absent"
    ), required = FALSE, bounds = "[0, 1]"),
    schema_col("source", "text", "standard or document")
  )
}

# Schema of what enrichment added to composition rows; without a registry,
# `nutrient` has no vocabulary. Design: docs/design-task9.md, section 3.
schema_enrichment <- function(nutrients = NULL) {
  ref <- "composition row of the %s ingredient; with the pair rule"
  new_schema(
    "enrichment", c("composition_id", "nutrient"),
    schema_col("composition_id", "id", "composition row to correct"),
    schema_col("nutrient", "text", "nutrient of the registry",
               values = nutrients$nutrient),
    schema_col("enriched_ref_id", "id", sprintf(ref, "enriched"),
               required = FALSE, na = TRUE),
    schema_col("unenriched_ref_id", "id", sprintf(ref, "unenriched"),
               required = FALSE, na = TRUE),
    schema_col("ingredient_fraction", "number", paste(
      "grams of the ingredient per gram of the food, in the state of the",
      "composition row; with the pair rule"
    ), required = FALSE, na = TRUE, bounds = "(0, 1]"),
    schema_col("added", "number", paste(
      "amount enrichment added per 100 g, in the unit of the registry;",
      "alternative to the pair rule"
    ), required = FALSE, na = TRUE, bounds = "[0, Inf)"),
    schema_col("source", "text", paste(
      "origin of the pair, fraction or amount; `SOURCE PENDING` is",
      "accepted and counted"
    ))
  )
}

# Schema of the grouping of survey foods for food_group_intake(). Design:
# docs/design-food-group-shares.md, section 2.
schema_food_groups <- function() {
  new_schema(
    "food_groups", "food_code",
    schema_col("food_code", "id", "survey food code"),
    schema_col("food_group", "text", paste(
      "group name; not empty; `unclassified` is reserved for the foods",
      "without a group"
    )),
    schema_col("source", "text", paste(
      "classification and edition the groups come from"
    ))
  )
}
