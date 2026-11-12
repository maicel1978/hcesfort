# Schemas of the standard tables: households, members, acquisitions.
# Design: docs/design-task2.md, section 5.

schema_households <- function() {
  new_schema(
    "households", "household_id",
    schema_col("household_id", "id", "household identifier"),
    schema_col("weight", "number", "sampling (expansion) weight",
               bounds = "(0, Inf)"),
    schema_col("stratum", "id", paste(
      "design stratum; a survey without strata passes a constant column"
    )),
    schema_col("psu", "id", paste(
      "primary sampling unit; a survey without clusters passes",
      "`household_id`"
    )),
    schema_col("food_module_response", "flag", paste(
      "`FALSE` when the household did not answer the food module"
    ), required = FALSE)
  )
}

schema_members <- function() {
  new_schema(
    "members", c("household_id", "member_id"),
    schema_col("household_id", "id", "household identifier"),
    schema_col("member_id", "id", paste(
      "member identifier, unique within the household (a row number is",
      "enough)"
    )),
    schema_col("age_years", "number", "age in years", na = TRUE,
               bounds = "[0, Inf)"),
    schema_col("sex", "text", "sex", na = TRUE,
               values = c("female", "male")),
    schema_col("age_months", "number", "age in months, for infants",
               required = FALSE, na = TRUE, bounds = "[0, Inf)"),
    schema_col("pregnant", "flag", "pregnant", required = FALSE, na = TRUE),
    schema_col("lactating", "flag", "lactating", required = FALSE,
               na = TRUE),
    schema_col("meals_home_share", "number",
               "share of meals taken at home", required = FALSE,
               na = TRUE, bounds = "[0, 1]")
  )
}

schema_acquisitions <- function() {
  new_schema(
    "acquisitions", "record_id",
    schema_col("record_id", "id", paste(
      "record identifier (a row number is enough)"
    )),
    schema_col("household_id", "id", "household identifier"),
    schema_col("food_code", "id", "survey food code"),
    schema_col("quantity", "number", "quantity in the unit of `unit`",
               na = TRUE, bounds = "[0, Inf)"),
    schema_col("unit", "id", "unit code or name, matched to unit factors",
               na = TRUE),
    schema_col("section", "text",
               "questionnaire module or source of the record"),
    schema_col("period_days", "number", paste(
      "days the quantity is divided by; the adapter documents the rule"
    ), bounds = "(0, Inf)"),
    schema_col("include", "flag", paste(
      "`FALSE` when the section-combination rule of the adapter leaves the",
      "record out"
    )),
    schema_col("origin", "text", "purchase, own production, gift...",
               required = FALSE, na = TRUE),
    schema_col("household_share", "number", paste(
      "share of the acquisition destined to the household"
    ), required = FALSE, na = TRUE, bounds = "[0, 1]")
  )
}

# Schema functions by table name; later tasks add theirs.
schema_registry <- function() {
  list(
    households = schema_households,
    members = schema_members,
    acquisitions = schema_acquisitions,
    unit_factors = schema_unit_factors,
    crosswalk = schema_crosswalk,
    composition = schema_composition,
    vehicles = schema_vehicles,
    scenarios = schema_scenarios
  )
}

#' Schema of an input table
#'
#' Returns the data contract of one of the tables hcesfort takes as input:
#' its columns, their type, whether they are required, whether a missing
#' value is accepted, the rule their values follow, and what they mean.
#' The validators (`validate_households()` and the others) check exactly
#' these rules.
#'
#' Types: `id` is text or a whole number (a factor is rejected); `number` is
#' numeric and finite; `flag` is logical; `text` is character. Columns not
#' in the schema are kept untouched by the validators.
#'
#' The schemas of `composition` and `scenarios` depend on the nutrient
#' registry: `hces_schema("composition")` shows one placeholder row,
#' `<nutrient>_<unit>`, for the nutrient columns, and `nutrient` in
#' `scenarios` must be a nutrient of the registry.
#'
#' @param table Name of the table: `"households"`, `"members"`,
#'   `"acquisitions"`, `"unit_factors"`, `"crosswalk"`, `"composition"`,
#'   `"vehicles"` or `"scenarios"`.
#' @returns A tibble with columns `column`, `type`, `required`, `na`
#'   (`TRUE` when a missing value is accepted), `key` (`TRUE` for the
#'   columns of the key), `rule` and `description`.
#' @seealso [validate_households()], [validate_survey()],
#'   [validate_unit_factors()], [validate_composition()],
#'   [validate_scenarios()].
#' @examples
#' hces_schema("acquisitions")
#' @export
hces_schema <- function(table) {
  known <- names(schema_registry())
  if (!rlang::is_string(table) || !table %in% known) {
    abort_hcesfort("argument", c(
      "{.arg table} must be one table name.",
      "i" = "Known tables: {.val {known}}."
    ), arg = "table")
  }
  schema <- schema_registry()[[table]]()
  rules <- vapply(seq_len(nrow(schema)), function(i) {
    gsub("^\\(|\\)$", "", rule_text(schema[i, ]))
  }, "")
  dplyr::tibble(
    column = schema$column, type = schema$type,
    required = schema$required, na = schema$na,
    key = schema$column %in% attr(schema, "key"),
    rule = rules, description = schema$description
  )
}
