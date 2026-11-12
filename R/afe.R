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
#'   the mean, the rule of the original ENGIH 2018 analysis;
#' * children: the requirement of their year of age in `energy`, up to the
#'   last tabulated year (18 in [ref_energy_requirements]);
#' * adults: basal metabolic rate from `bmr` at the member's `weight_kg`
#'   when the column is present and not missing, otherwise at `weight_kg`
#'   for their sex, times `pal`.
#'
#' Pregnancy and lactation add no energy; members flagged as pregnant or
#' lactating are counted in the log (`pregnant_or_lactating_no_extra`).
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
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' reference <- (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76
#' afe <- adult_equivalents(
#'   hces_example$members, reference_kcal = reference,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' afe
#' audit_log(afe)
#' @export
adult_equivalents <- function(members, reference_kcal, weight_kg, pal,
                              meal_share = NULL,
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
  kcal <- member_energy(m, energy, bmr, weight_kg, pal, infants)
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
  log <- afe_log(m, attr(kcal, "infant_mean"), unknown, share, missing_members,
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

# Audit rows of adult_equivalents(): members received, infants given the
# annual mean, pregnant or lactating members, members without age or sex
# (flagged, or set to zero), members without meal share, and households
# left without AFE.
afe_log <- function(m, infant_mean, unknown, share, missing_members,
                    out) {
  step <- "adult_equivalents"
  hh <- function(f) length(unique(m$household_id[f]))
  pregnant <- flag_or_false(m[["pregnant"]]) | flag_or_false(m[["lactating"]])
  no_share <- is.na(share) & !unknown
  rows <- list(
    audit_row(step, "members", "input", "all", nrow(m), hh(TRUE)),
    afe_note(step, "note", "infant_annual_mean", infant_mean, hh),
    afe_note(step, "note", "pregnant_or_lactating_no_extra", pregnant, hh),
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

# A logical column with missing values and absence read as FALSE (used
# only to count members in the log, never in the computation).
flag_or_false <- function(v) {
  if (is.null(v)) FALSE else !is.na(v) & v
}
