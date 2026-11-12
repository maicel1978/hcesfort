#' Synthetic example survey
#'
#' An invented household survey, with every table hcesfort takes as input,
#' for examples, tests and vignettes. **All values are invented**: nothing
#' comes from a real survey, food composition table or fortification
#' standard, and the numbers must not be used for analysis. The tables are
#' plain data frames in the standard schemas ([hces_schema()]); they pass
#' the validators of the package.
#'
#' The data contain, on purpose, the cases the package has to handle and
#' count: a household that did not answer the food module and one without
#' acquisitions; a member without age and one without sex; an acquisition
#' without quantity, one without unit, one left out by the section rule,
#' one with an implausibly large quantity and one in a unit without factor
#' (`"sack"`); a milk record in cups, a volume unit without a density for
#' milk; two recall periods (7 and 30 days); an unmatched and an
#' unvalidated food; a missing nutrient value
#' and two enriched composition rows with the rules that remove what
#' enrichment added; a food with two vehicles of different groups; a
#' scenario that fortifies only some vehicles of a group; a scenario level
#' given for a compound; a grouping of foods that leaves the egg without a
#' group. The planted defects stay in a few records, so
#' that most included records reach the intake.
#'
#' Quantities were recalibrated (2026-11-12) so that results read like a
#' survey: the median apparent energy intake is about 2,200 kcal per adult
#' female equivalent per day, iron, folate and vitamin A straddle their
#' requirements, and the scenario `flour_and_sugar` takes a few households
#' above the upper level of folic acid.
#'
#' @format A list of eleven elements:
#' \describe{
#'   \item{households}{40 households in 2 strata and 8 primary sampling
#'     units, with a `region` domain.}
#'   \item{members}{Members of the households, with age, sex and pregnancy
#'     and lactation flags.}
#'   \item{acquisitions}{Food acquisitions in survey units.}
#'   \item{unit_factors}{Factors from survey units to grams, millilitres
#'     or pieces.}
#'   \item{crosswalk}{Survey foods matched to the composition table.}
#'   \item{nutrients}{Named character vector of units for
#'     [nutrient_registry()]: energy, iron, folate and vitamin A.}
#'   \item{composition}{An invented composition table of 14 foods, per
#'     100 g edible portion.}
#'   \item{enrichment}{What enrichment added to the enriched pasta and
#'     flour, for [unfortified_baseline()].}
#'   \item{vehicles}{Fraction of each food that is a fortification
#'     vehicle, by product class, with a vehicle group.}
#'   \item{scenarios}{Two invented fortification scenarios.}
#'   \item{food_groups}{An invented grouping of the survey foods, for
#'     [food_group_intake()]; the egg has no group.}
#' }
#' @source Invented by the package authors; built by
#'   `data-raw/hces_example.R` in the source repository.
#' @examples
#' survey <- validate_survey(
#'   hces_example$households, hces_example$members,
#'   hces_example$acquisitions
#' )
#' audit_log(survey$acquisitions)
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' validate_composition(hces_example$composition, nutrients)
"hces_example"
