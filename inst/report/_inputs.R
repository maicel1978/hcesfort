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
# Presentation standard of the estimates: the NCHS data presentation
# standards for proportions (Parker et al. 2017), as shipped. It gives the
# confidence level, the minimum number of households of a cell and the
# other thresholds. If you replace it, justify each row in decisions.csv.
presentation_standard <- hcesfort::ref_presentation_standard
# The reference person of the adult female equivalents: woman of 25
# years and 55 kg, physical activity level 1.76 (example values).
reference_kcal <- reference_energy("female", 25, 55, pal = 1.76)

# ---- Steps that take choices -----------------------------------------
# _chain.R calls these only when every essential input is present, so a
# survey that fails its contract still gets its variable inventory.
make_afe <- function(members) {
  # Infants are charged their full energy requirement (breast milk reaches
  # them through the mother's diet) and pregnancy and lactation add no
  # energy: the rules of the original analysis. For other values see
  # ?adult_equivalents and ref_energy_additions, and record the values of
  # infant_food_share, milk_energy_cost, pregnancy_kcal and lactation_kcal
  # in decisions.csv.
  adult_equivalents(members, reference_kcal = reference_kcal,
                    weight_kg = c(female = 55, male = 65), pal = 1.76,
                    infant_food_share = 1, pregnancy_kcal = 0,
                    lactation_kcal = 0)
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
  # Place and survey, appended to every title ("Region X, Survey 2024");
  # NULL leaves them out.
  place = NULL,
  survey = NULL,
  # Vehicles of the coverage section; NULL is every vehicle of `vehicles`.
  # A scenario on a vehicle left out stops the render.
  vehicles = NULL,
  # Estimates flagged for statistical review by the presentation standard:
  # "show" (printed with a mark and the reason) or "suppress".
  review = "show",
  nutrients = c("iron", "zinc", "folate", "vitamin_a"),
  energy = "energy", # registry name of energy, or NULL
  domains = c("region", "area", "expenditure_group"),
  equity_domains = "expenditure_group",
  # NULL: every scenario against "baseline". To compare each addition
  # with the wheat-flour scenario instead:
  # comparator = c(plus_maize = "wheat_flour", plus_rice = "wheat_flour",
  #                plus_sugar = "wheat_flour", plus_oil = "wheat_flour"),
  comparator = NULL,
  # Largest share of the values of a domain with fewer households with an
  # estimated intake than the `min_n` of the presentation standard; above
  # it the domain is disabled.
  max_small_cells = 0.5,
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
  # What the results do with the households outside that range (P148):
  # "keep" or "exclude". The readiness report counts them either way; the
  # results report states the choice. "exclude" needs `energy`. Record the
  # choice and its reason in decisions.csv.
  energy_action = "exclude",
  lonely_psu = "adjust"
)
