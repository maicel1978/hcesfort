#' Reference tables shipped with hcesfort
#'
#' Small generic reference tables of the method, each with its source. Every
#' row was read in the document named in its `source` column, at the place
#' given in `location`; values that could not be checked in a document are
#' kept out of the package (they stay in `data-raw/` of the source
#' repository, listed in `data-raw/SOURCES.md` as pending). The functions
#' that use these tables take them as an argument, so any of them can be
#' replaced by the user's own table with the same columns.
#'
#' Age intervals are `[age_from, age_to)`, in the unit of the table: the
#' lower bound is included and the upper bound is not. A requirement for
#' "19–30 years" (completed years) is therefore `[19, 31)`.
#'
#' * [ref_requirements]: Estimated Average Requirement (EAR) and Tolerable
#'   Upper Intake Level (UL), with the intake the UL applies to.
#' * [ref_iron_requirements]: percentiles of the distribution of iron
#'   requirements, for the probability approach.
#' * [ref_energy_requirements]: energy requirements of infants, children and
#'   adolescents.
#' * [ref_bmr_equations]: equations for basal metabolic rate from body
#'   weight, for adult energy requirements.
#' * [ref_conversions]: factors from a form of a nutrient to its equivalent
#'   unit (DFE, RAE).
#' * [ref_who2009_flour]: WHO (2009) average levels of nutrients to consider
#'   adding to wheat flour.
#'
#' @name reference_tables
#' @family reference tables
NULL

#' Estimated Average Requirements and Tolerable Upper Intake Levels
#'
#' EAR and UL of the Institute of Medicine (IOM) for women 19–30 years, the
#' reference group of the method. The UL of each nutrient is the UL for
#' adults (19 years and older) and applies to the intake named in
#' `ul_applies_to`, which is what the share above the UL must be computed on.
#'
#' Vitamin D is not included: its EAR (10 µg) and UL (100 µg) were read in
#' IOM (2011), but the intake its UL applies to was not found stated in the
#' report, so the row stays pending in `data-raw/`.
#'
#' @format A tibble with one row per nutrient and population group:
#' \describe{
#'   \item{nutrient}{Nutrient name.}
#'   \item{unit}{Unit of `ear`, written as in [nutrient_registry()]
#'     (`"mg"`, `"ug"`, `"ug_dfe"`, `"ug_rae"`).}
#'   \item{expressed_as}{What the value measures (for example
#'     `"dietary folate equivalents"`, `"alpha-tocopherol"`).}
#'   \item{sex, age_from, age_to}{Population group; ages in years,
#'     `[age_from, age_to)`.}
#'   \item{ear}{Estimated Average Requirement per day.}
#'   \item{ul}{Tolerable Upper Intake Level per day, in `ul_unit`; missing
#'     where none was set.}
#'   \item{ul_unit}{Unit of `ul`. It differs from `unit` where the UL
#'     applies to a form: the folate UL is in µg of folic acid, not DFE
#'     (IOM 1998, p. 282); the vitamin A UL in µg of preformed vitamin A,
#'     not RAE (IOM 2001, pp. 143–145).}
#'   \item{ul_applies_to}{Intake the UL refers to: `"total"` (food, water
#'     and supplements), `"preformed_vitamin_a"`, `"folic_acid"` (folate
#'     from fortified food or supplements) or
#'     `"supplemental_alpha_tocopherol"`; missing where there is no UL.}
#'   \item{cutpoint_valid}{`FALSE` when the requirement is known to be
#'     skewed, so the EAR cut-point does not apply (iron: IOM 2000,
#'     *Applications in Dietary Assessment*, pp. 81 and 91). `TRUE` means
#'     no skewed requirement is recorded: the same report assumes symmetry
#'     by default (p. 91); it is not a positive finding.}
#'   \item{ear_bioavailability}{Absorption the EAR assumes, when the source
#'     states one (iron: 0.18); missing otherwise. Informative only.}
#'   \item{source}{Document.}
#'   \item{location}{Chapter and page of the EAR, of the UL and of the two
#'     columns above.}
#' }
#' @source Institute of Medicine (1998, 2000, 2001). Dietary Reference
#'   Intakes. Washington, DC: The National Academies Press; doi
#'   10.17226/6015, 10.17226/9810, 10.17226/9956, 10.17226/10026.
#' @family reference tables
#' @examples
#' ref_requirements[, c("nutrient", "unit", "ear", "ul", "ul_unit",
#'                      "ul_applies_to")]
"ref_requirements"

#' Distribution of iron requirements
#'
#' Estimated percentiles of the distribution of dietary iron requirements
#' (IOM 2001, Appendix Tables I-3 and I-4), for the probability approach to
#' the prevalence of inadequate iron intake. Each requirement is the absorbed
#' requirement divided by `bioavailability`; for another bioavailability `b`
#' the dietary requirement is `requirement_mg_d * bioavailability / b`.
#'
#' @format A tibble with 13 percentiles (2.5 to 97.5) for each of 14 groups:
#' \describe{
#'   \item{group}{Group identifier (for example
#'     `"females_menstruating_adult"`).}
#'   \item{description}{Group as named in the source table.}
#'   \item{sex}{`"female"`, `"male"` or `"both"`.}
#'   \item{percentile}{Percentile of the requirement distribution.}
#'   \item{requirement_mg_d}{Dietary iron requirement, mg per day.}
#'   \item{bioavailability}{Bioavailability assumed by the source (0.10 for
#'     infants 7–12 months, 0.18 otherwise).}
#'   \item{source, location}{Document, table and page.}
#' }
#' @source Institute of Medicine (2001). Dietary Reference Intakes for
#'   Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron,
#'   Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc. Washington,
#'   DC: The National Academies Press. doi:10.17226/10026.
#' @family reference tables
#' @examples
#' subset(ref_iron_requirements, group == "females_menstruating_adult")
"ref_iron_requirements"

#' Energy requirements of infants, children and adolescents
#'
#' Daily energy requirements by sex and age of the joint FAO/WHO/UNU expert
#' consultation (2004): infants by month of age (Table 3.2) and children and
#' adolescents 1 to 18 years with moderate physical activity (Tables 4.2 and
#' 4.3). Adults (18 years and older) have no tabulated requirement: it is
#' basal metabolic rate ([ref_bmr_equations]) times a physical activity
#' level, both chosen by the user.
#'
#' @format A tibble:
#' \describe{
#'   \item{sex}{`"female"` or `"male"`.}
#'   \item{age_from, age_to}{Age interval `[age_from, age_to)`.}
#'   \item{age_unit}{`"month"` (infants) or `"year"`.}
#'   \item{energy_kcal_d}{Daily energy requirement, kcal per day.}
#'   \item{physical_activity}{`"moderate"`, or `"not applicable"` for
#'     infants.}
#'   \item{source, location}{Document and table.}
#' }
#' @source FAO (2004). Human energy requirements. Report of a Joint
#'   FAO/WHO/UNU Expert Consultation. FAO Food and Nutrition Technical
#'   Report Series 1. Rome.
#' @family reference tables
#' @examples
#' subset(ref_energy_requirements, age_unit == "year" & sex == "female")
"ref_energy_requirements"

#' Equations for basal metabolic rate
#'
#' Equations for basal metabolic rate (BMR) from body weight, by sex and age
#' (FAO/WHO/UNU 2004, Table 5.2, after Schofield 1985):
#' `BMR (kcal/day) = slope_kcal_kg * weight_kg + intercept_kcal`.
#'
#' @format A tibble:
#' \describe{
#'   \item{sex}{`"female"` or `"male"`.}
#'   \item{age_from, age_to}{Age interval in years, `[age_from, age_to)`;
#'     the last interval is open (`age_to = Inf`).}
#'   \item{slope_kcal_kg}{kcal per day per kg of body weight.}
#'   \item{intercept_kcal}{kcal per day.}
#'   \item{see_kcal}{Standard error of the estimate, kcal per day.}
#'   \item{source, location}{Document and table.}
#' }
#' @source FAO (2004). Human energy requirements. Report of a Joint
#'   FAO/WHO/UNU Expert Consultation. FAO Food and Nutrition Technical
#'   Report Series 1. Rome.
#' @family reference tables
#' @examples
#' # BMR of a woman of 25 years and 55 kg, kcal/day.
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' eq$slope_kcal_kg * 55 + eq$intercept_kcal
"ref_bmr_equations"

#' Conversion factors to nutrient equivalents
#'
#' Factors from a form of a nutrient to the equivalent unit the requirements
#' are expressed in: `amount in to_unit = factor * amount in from_unit`.
#' Folic acid consumed with food counts 1.7 µg of dietary folate equivalents
#' (DFE) per µg; retinol and provitamin A carotenoids are converted to
#' retinol activity equivalents (RAE).
#'
#' No factor is given for retinyl palmitate: none was found in a document
#' opened for the package, and it stays pending in `data-raw/`.
#'
#' @format A tibble:
#' \describe{
#'   \item{from_form}{Form of the nutrient.}
#'   \item{from_unit, to_unit}{Units, written as in [nutrient_registry()]
#'     (`"IU"` for international units).}
#'   \item{factor}{Multiplier.}
#'   \item{condition}{When the factor applies.}
#'   \item{source, location}{Document, chapter, table and page.}
#'   \item{ul_form}{The upper level the form counts towards, as named in
#'     `ref_requirements$ul_applies_to`: `"folic_acid"` for folic acid,
#'     `"preformed_vitamin_a"` for retinol; missing for food folate and the
#'     carotenoids, which no UL of the table covers.}
#'   \item{ul_form_location}{Chapter and page that place the form under
#'     that upper level.}
#' }
#' @source Institute of Medicine (1998, 2001). Dietary Reference Intakes.
#'   Washington, DC: The National Academies Press; doi 10.17226/6015,
#'   10.17226/10026.
#' @family reference tables
#' @examples
#' ref_conversions[, c("from_form", "from_unit", "to_unit", "factor")]
"ref_conversions"

#' WHO (2009) levels of nutrients for wheat flour fortification
#'
#' Average levels of nutrients to consider adding to fortified wheat flour,
#' by flour extraction rate, fortificant compound and estimated average per
#' capita wheat flour availability (WHO 2009, Table 1). The table header
#' gives the level of the nutrient to be added, in parts per million
#' (mg/kg), so `level_basis` is `"nutrient"`. The footnotes of the table
#' are in `note`.
#'
#' @format A tibble:
#' \describe{
#'   \item{nutrient}{Nutrient as named in the table, in snake case.}
#'   \item{extraction}{Flour extraction rate: `"low"`, `"high"` or
#'     `"low or high"`.}
#'   \item{compound}{Fortificant compound.}
#'   \item{availability_g_d}{Availability category as printed (`"<75"`,
#'     `"75-149"`, `"150-300"`, `">300"` g per day).}
#'   \item{availability_from_g_d, availability_to_g_d}{The numbers of the
#'     category as printed; they do not decide which category a boundary
#'     value belongs to. [who2009_levels()] states the rule it applies.}
#'   \item{level_mg_kg}{Level of nutrient to be added, mg per kg of flour;
#'     missing when not recommended.}
#'   \item{recommended}{`FALSE` where the table says "not recommended".}
#'   \item{level_basis}{What the level measures (`"nutrient"`).}
#'   \item{note}{Footnotes that apply to the row.}
#'   \item{source, location}{Document and table.}
#' }
#' @source World Health Organization (2009). Recommendations on wheat and
#'   maize flour fortification. Meeting report: interim consensus statement.
#'   WHO/NMH/NHD/MNM/09.1. Geneva.
#' @family reference tables
#' @examples
#' subset(ref_who2009_flour, nutrient == "iron" & availability_g_d == "<75")
"ref_who2009_flour"
