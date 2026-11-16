#' Energy added in pregnancy and lactation
#'
#' The additional energy of pregnancy and lactation of FAO/WHO/UNU (2004),
#' one row per value. A list to choose from: [adult_equivalents()] does not
#' read it. Pass the value chosen as `pregnancy_kcal` or `lactation_kcal`,
#' one number for every member flagged; a survey that does not record the
#' trimester or the month of lactation needs one number, the analyst's
#' choice (the mean of the three trimesters is about 282 kcal per day;
#' 77,000 kcal over 280 days, section 6.3, is about 275).
#'
#' The pregnancy values by trimester are for healthy well-nourished women
#' with an average gestational weight gain of 12 kg; the source recommends
#' 360 kcal per day from the second trimester (the first-trimester amount
#' folded in) where many women do not seek prenatal advice before the
#' second or third month of pregnancy. The lactation values of the first six
#' months depend on the mother's nutrition before and during pregnancy.
#'
#' @format A tibble with one row per value:
#' \describe{
#'   \item{condition}{`"pregnancy"` or `"lactation"`.}
#'   \item{period}{Trimester of pregnancy, or months of lactation.}
#'   \item{group}{The women the value is for, as the source states it.}
#'   \item{energy_kcal_d}{Energy added, kcal per day.}
#'   \item{source, location}{Document and section of the value.}
#' }
#' @source FAO. 2004. *Human energy requirements. Report of a Joint
#'   FAO/WHO/UNU Expert Consultation.* FAO Food and Nutrition Technical
#'   Report Series 1. Rome. Sections 6.3 and 7.2.
#' @family reference tables
#' @examples
#' ref_energy_additions[c("condition", "period", "energy_kcal_d")]
"ref_energy_additions"
