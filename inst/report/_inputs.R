# Inputs of both reports: the only file where a survey enters.
#
# readiness.qmd and results.qmd source this file, then _chain.R. Replace
# the tables and the choices below with those of your survey. No choice
# has a default in hcesfort: every value here is written by the analyst.
# The values shipped are those of hces_example (invented data); they are
# examples, not recommendations.

library(hcesfort)

# ---- Standard tables -------------------------------------------------
# Optional tables may be NULL: the readiness report says which sections
# of the results report they disable.
ex <- hcesfort::hces_example
households <- ex$households
members <- ex$members
acquisitions <- ex$acquisitions
unit_factors <- ex$unit_factors
crosswalk <- ex$crosswalk
composition <- ex$composition
nutrients <- nutrient_registry(ex$nutrients)
enrichment <- ex$enrichment # NULL: no enriched food is declared
vehicles <- ex$vehicles
scenarios <- ex$scenarios
food_groups <- ex$food_groups

# ---- Reference values ------------------------------------------------
requirements <- hcesfort::ref_requirements
iron <- hcesfort::ref_iron_requirements
iron_distribution <- iron[iron$group == "females_menstruating_adult", ]
# The reference person of the adult female equivalents: woman of 25
# years and 55 kg, physical activity level 1.76 (example values).
reference_kcal <- reference_energy("female", 25, 55, pal = 1.76)

# ---- Steps that take choices -----------------------------------------
# _chain.R calls these only when every essential input is present, so a
# survey that fails its contract still gets its variable inventory.
make_afe <- function(members) {
  adult_equivalents(members, reference_kcal = reference_kcal,
                    weight_kg = c(female = 55, male = 65), pal = 1.76)
}
make_grams <- function(acquisitions, unit_factors) {
  # Outlier decision: none in this example. To act on flag_outliers(),
  # change `include` of the flagged records here and record the rule in
  # decisions.csv.
  convert_units(acquisitions, unit_factors, priority = "food")
}
compliance_model <- "average_content"

# ---- Choices shared by both reports ----------------------------------
choices <- list(
  nutrients = c("iron", "folate", "vitamin_a"),
  energy = "energy", # registry name of energy, or NULL
  domains = c("region", "expenditure_group"),
  equity_domains = "expenditure_group",
  comparator = NULL, # NULL: every scenario against "baseline"
  min_n = 8, # example value: shows a suppressed and a shown cell
  max_half_width = 0.15,
  min_coverage = 0.8,
  min_records_used = 0.8,
  min_linked_share = 0.9,
  iron_bioavailability = 0.10,
  iron_bioavailability_sensitivity = c(0.05, 0.15),
  # Plausible apparent energy, kcal per AFE per day. Example values: the
  # original ENGIH 2018 analysis used 500 and 6000, without a published
  # source. Justify yours in decisions.csv.
  energy_lower = 500,
  energy_upper = 6000,
  level = 0.95,
  lonely_psu = "adjust"
)
