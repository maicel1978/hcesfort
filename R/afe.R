#' Adult female equivalents per household
#'
#' Express the members of each household as adult female equivalents
#' (AFE): the energy requirement of each member divided by the energy
#' requirement of a reference person, summed over the household. Intake per
#' AFE is the household's apparent intake divided by its AFE.
#'
#' The energy requirement of each member comes from reference tables, each
#' replaceable by argument:
#'
#' * infants under one year: the requirement of their month of age
#'   (`age_months`) in `energy`; when the month is not known, the mean of
#'   the twelve months of their sex (counted in the log as
#'   `infant_annual_mean`). With `infants = "annual_mean"` every infant gets
#'   the mean, the rule of the original ENGIH 2018 analysis. The household
#'   is charged \eqn{E (s + (1 - s) c)} of a requirement \eqn{E}: `s`
#'   (`infant_food_share`) is eaten from the household's food and the rest
#'   is breast milk, charged at `c` (`milk_energy_cost`) per unit of its
#'   energy (see below);
#' * children: the requirement of their year of age in `energy`, up to the
#'   last tabulated year (18 in [ref_energy_requirements]);
#' * adults: basal metabolic rate from `bmr` at the member's `weight_kg`
#'   when the column is present and not missing, otherwise at `weight_kg`
#'   for their sex, times `pal`.
#'
#' **Pregnancy and lactation.** `pregnancy_kcal` is added to the
#' requirement of each member flagged `pregnant`, and `lactation_kcal` to
#' each member flagged `lactating` (both to a member flagged both); a
#' missing flag counts as not flagged. Each is required when a member
#' carries its flag; `0` adds nothing, the rule of the original analysis,
#' and the log counts those members (`pregnant_or_lactating_no_extra`);
#' a value above 0 is noted (`pregnancy_energy_added`,
#' `lactation_energy_added`). [ref_energy_additions] lists the values of
#' FAO/WHO/UNU (2004) to choose from. Breast milk must be charged once: to
#' the mother with `lactation_kcal`, or through the infant with
#' `milk_energy_cost`. Both above 0, with an infant whose share is below
#' 1, is an error. A survey seldom says which woman feeds which infant, and
#' the AFE is a household sum, so either way gives the same household AFE
#' when the mother and the infant live together.
#'
#' **Infants and breast milk.** A breastfed infant eats none of the food
#' recorded, but its mother eats for it: the energy of the milk belongs in
#' the household's AFE. With `infant_food_share = 1` (the rule of the
#' original analysis) or `milk_energy_cost = 1`, the infant counts its full
#' requirement: the milk is charged at par, and the infant requirements of
#' the source are consistent with a healthy woman producing enough milk for
#' an exclusively breastfed infant up to six months (FAO/WHO/UNU 2004,
#' section 3.4). Making milk costs more than its energy: 1.25 per unit, the
#' milk energy over an efficiency of 0.80 (section 7.2), so
#' `milk_energy_cost = 1.25` with a share below 1 charges the full cost.
#' `milk_energy_cost = 0` charges nothing for the milk, and the log flags it
#' (`breast_milk_energy_not_counted`). No value of the share is shipped: it
#' describes how infants are fed in the survey's population. The log notes
#' the values given and the energy charged against the full requirement
#' (`infant_energy`).
#'
#' A member without age or sex has no requirement. With
#' `missing_members = "na"` the AFE of the household is `NA`: the household
#' is flagged (`missing_age_or_sex`), not dropped, and the decision to
#' exclude it is left to the caller. `missing_members = "zero"` reproduces
#' the original analysis (the member counts zero AFE), and the log records
#' it.
#'
#' @param members Members table ([hces_schema()]`("members")`), validated
#'   or not.
#' @param reference_kcal Energy requirement of the reference person, kcal
#'   per day (one positive number). See the examples to compute it.
#' @param weight_kg Body weight of adults, kg: a numeric vector named
#'   `female` and `male`.
#' @param pal Physical activity level of adults (one positive number),
#'   the multiple of BMR.
#' @param meal_share Required when `members` has the column
#'   `meals_home_share`: `TRUE` multiplies each member's AFE by the share of
#'   meals taken at home (a missing share leaves the household without AFE,
#'   flagged `missing_meal_share`); `FALSE` ignores the column. Must be
#'   `NULL` or `FALSE` when the column is absent.
#' @param infant_food_share Required when `members` has an infant
#'   (`age_years` below 1): the share of an infant's energy requirement
#'   eaten from the household's food (formula, complementary foods), the
#'   rest being breast milk. One number in \[0, 1\], or a data frame with
#'   `age_from` and `age_to` (months; intervals \[from, to) that cover 0 to
#'   12 without gap or overlap) and `food_share` in \[0, 1\]; an infant whose
#'   month is not known gets the mean over the months of the table of
#'   `energy`, each at the share of its first month. `1` charges the full
#'   requirement. Accepted and ignored when there are no infants.
#' @param milk_energy_cost Required when an infant has a share below 1:
#'   dietary energy charged to the household per unit of breast-milk
#'   energy, one number, 0 or more. `1` charges the milk at par, `1.25` its
#'   full cost, `0` nothing through the infant (to charge it to the mother
#'   with `lactation_kcal`, or not at all, flagged in the log; see
#'   Details).
#' @param pregnancy_kcal,lactation_kcal Required when a member is flagged
#'   `pregnant` (`lactating`): energy added to the requirement of each such
#'   member, kcal per day, one number, 0 or more. See
#'   [ref_energy_additions].
#' @param energy Energy requirements by sex and age; default
#'   [ref_energy_requirements]. Schema: `hces_schema("energy_requirements")`.
#' @param bmr Equations for basal metabolic rate; default
#'   [ref_bmr_equations]. Schema: `hces_schema("bmr_equations")`.
#' @param infants `"monthly"` (default) or `"annual_mean"`; see Details.
#' @param missing_members `"na"` (default) or `"zero"`; see Details.
#' @returns A tibble of class `hces_afe` (and `hces_tbl`), one row per
#'   household with members: `household_id`, `n_members`, `energy_kcal_d`
#'   (sum of the members' requirements) and `afe`. Its audit log continues
#'   the log of `members`. Households without members are not in the
#'   table ([validate_survey()] counts them).
#' @seealso [ref_energy_requirements], [ref_bmr_equations], [audit_log()].
#' @examples
#' # Reference: woman of 18-30 years, 55 kg, physical activity level 1.76.
#' reference <- reference_energy("female", 25, weight_kg = 55, pal = 1.76)
#' afe <- adult_equivalents(
#'   hces_example$members, reference_kcal = reference,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' afe
#' audit_log(afe)
#' # Infants exclusively breastfed to six months, milk at its full cost.
#' feeding <- data.frame(age_from = c(0, 6), age_to = c(6, 12),
#'                       food_share = c(0, 1))
#' adult_equivalents(
#'   hces_example$members, reference_kcal = reference,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = feeding, milk_energy_cost = 1.25,
#'   pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' # Pregnancy (FAO/WHO/UNU 2004, section 6.3, second trimester
#' # recommendation) and lactation (section 7.2, first six months).
#' adult_equivalents(
#'   hces_example$members, reference_kcal = reference,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 360, lactation_kcal = 505
#' )
#' @export
adult_equivalents <- function(members, reference_kcal, weight_kg, pal,
                              meal_share = NULL, infant_food_share = NULL,
                              milk_energy_cost = NULL,
                              pregnancy_kcal = NULL, lactation_kcal = NULL,
                              energy = hcesfort::ref_energy_requirements,
                              bmr = hcesfort::ref_bmr_equations,
                              infants = c("monthly", "annual_mean"),
                              missing_members = c("na", "zero")) {
  check_required()
  infants <- check_choice(infants, c("monthly", "annual_mean"))
  missing_members <- check_choice(missing_members, c("na", "zero"))
  check_afe_args(reference_kcal, weight_kg, pal)
  m <- validate_members(members)
  m <- audit_check_rows(m, "adult_equivalents")
  meal_share <- check_meal_share(meal_share, m)
  check_reference(energy, schema_energy_requirements(), c("sex", "age_unit"))
  check_reference(bmr, schema_bmr_equations(), "sex")
  infant <- check_infant_args(infant_food_share, milk_energy_cost, m)
  extra <- check_extra_args(pregnancy_kcal, lactation_kcal, m, infant)
  infant$lactation_added <- extra$lactation_added
  kcal <- member_energy(m, energy, bmr, weight_kg, pal, infants, infant)
  kcal[] <- kcal + extra_energy(extra)
  check_covered(m, kcal)
  afe <- kcal / reference_kcal
  share <- if (meal_share) m[["meals_home_share"]] else rep(1, nrow(m))
  afe <- afe * share
  unknown <- is.na(m$age_years) | is.na(m$sex)
  if (missing_members == "zero") {
    afe[unknown] <- 0
    kcal[unknown] <- 0
  }
  out <- household_afe(m$household_id, kcal, afe)
  log <- afe_log(m, kcal, infant, extra, unknown, share, missing_members,
                 out)
  new_hces_tbl(out, "hces_afe", dplyr::bind_rows(audit_get(m), log),
               "household_id")
}

# One row per household: number of members, energy and AFE summed without
# removing missing values (a member without AFE leaves the household NA).
household_afe <- function(household_id, kcal, afe) {
  ids <- sort(unique(household_id))
  g <- factor(match(household_id, ids), levels = seq_along(ids))
  dplyr::tibble(
    household_id = ids,
    n_members = tabulate(g, nbins = length(ids)),
    energy_kcal_d = vapply(split(kcal, g), sum, numeric(1), USE.NAMES = FALSE),
    afe = vapply(split(afe, g), sum, numeric(1), USE.NAMES = FALSE)
  )
}

# Audit rows of adult_equivalents(): members received, the energy of
# infants, infants given the annual mean, energy of pregnant or lactating
# members, members without age or sex (flagged, or set to zero), members
# without meal share, and households left without AFE.
afe_log <- function(m, kcal, infant, extra, unknown, share, missing_members,
                    out) {
  step <- "adult_equivalents"
  hh <- function(f) length(unique(m$household_id[f]))
  no_share <- is.na(share) & !unknown
  rows <- list(
    audit_row(step, "members", "input", "all", nrow(m), hh(TRUE)),
    infant_log(step, m, kcal, attr(kcal, "infant_full"), infant, hh),
    afe_note(step, "note", "infant_annual_mean", attr(kcal, "infant_mean"),
             hh),
    extra_log(step, extra, hh),
    if (missing_members == "na") {
      afe_note(step, "flagged", "missing_age_or_sex", unknown, hh)
    } else {
      afe_note(step, "filled", "zero_afe_missing_age_or_sex", unknown, hh)
    },
    afe_note(step, "flagged", "missing_meal_share", no_share, hh),
    if (anyNA(out$afe)) {
      audit_row(step, "afe", "flagged", "household_without_afe",
                sum(is.na(out$afe)), sum(is.na(out$afe)))
    }
  )
  dplyr::bind_rows(rows)
}

# One audit row for the members where `f` is TRUE, or none.
afe_note <- function(step, kind, cause, f, hh) {
  if (!any(f)) {
    return(NULL)
  }
  audit_row(step, "members", kind, cause, sum(f), hh(f))
}

# A logical column with missing values and absence read as FALSE: a
# member whose flag is missing is not flagged.
flag_or_false <- function(v) {
  if (is.null(v)) FALSE else !is.na(v) & v
}
