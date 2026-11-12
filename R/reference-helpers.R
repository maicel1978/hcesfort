# Helpers that read the reference tables: the energy requirement of a
# reference person and the WHO 2009 wheat flour levels for an availability.
# Design in docs/design-review-v0.1.md, section 6.

#' Energy requirement of a reference person
#'
#' The daily energy requirement of one person from a basal metabolic rate
#' (BMR) equation and a physical activity level (PAL):
#' `(slope_kcal_kg * weight_kg + intercept_kcal) * pal`, with the equation
#' of `bmr` for that sex and age. Its use is the `reference_kcal` of
#' [adult_equivalents()], so that the reference person and the members are
#' computed from the same equations.
#'
#' @param sex `"female"` or `"male"`.
#' @param age_years Age in years: one number; the equation is the row of
#'   `bmr` whose interval `[age_from, age_to)` holds it.
#' @param weight_kg Body weight in kg: one positive number.
#' @param pal Physical activity level: one positive number.
#' @param bmr BMR equations, by default [ref_bmr_equations] (FAO/WHO/UNU
#'   2004).
#' @returns One number, kcal per day.
#' @seealso [adult_equivalents()], [ref_bmr_equations].
#' @examples
#' # A woman of 18-30 years, 55 kg, PAL 1.76: about 2,291 kcal per day.
#' reference_energy("female", 25, weight_kg = 55, pal = 1.76)
#' @export
reference_energy <- function(sex, age_years, weight_kg, pal,
                             bmr = hcesfort::ref_bmr_equations) {
  check_required()
  sex <- check_required_choice(sex, c("female", "male"))
  check_one_number(age_years, "age_years", lower = 0)
  for (arg in c("weight_kg", "pal")) {
    value <- get(arg)
    if (!is.numeric(value) || length(value) != 1 || !is.finite(value) ||
          value <= 0) {
      abort_afe_arg(arg, "one positive number", rlang::current_env())
    }
  }
  check_reference(bmr, schema_bmr_equations(), "sex")
  row <- which(bmr$sex == sex & age_years >= bmr$age_from &
                 age_years < bmr$age_to)
  if (length(row) == 0) {
    abort_hcesfort("value", c(
      "{.arg bmr} has no equation for a {sex} of {age_years} years.",
      "i" = "Its intervals are [age_from, age_to)."
    ), table = "bmr", columns = c("sex", "age_from", "age_to"),
    rows = integer(0), n = 0L)
  }
  (bmr$slope_kcal_kg[[row]] * weight_kg + bmr$intercept_kcal[[row]]) * pal
}

#' WHO 2009 wheat flour levels for an availability
#'
#' The rows of [ref_who2009_flour] that apply to an estimated average per
#' capita wheat flour availability and a flour extraction rate: one level
#' per nutrient and compound. A filter with checked arguments: choosing the
#' compound, the vehicle and the compliance, and turning the rows into a
#' scenarios table, is left to the caller.
#'
#' WHO (2009, Table 1) prints the bands `<75`, `75-149`, `150-300` and
#' `>300` g per day; the text of the same report gives the second one as
#' "75-150 g/day". A value is placed in the band with the highest lower
#' bound it reaches, a lower bound printed with `>` being exclusive: below
#' 75 is `<75`; from 75 to below 150 (149.5 included) is `75-149`; from
#' 150 to 300 inclusive is `150-300`; above 300 is `>300`. The printed
#' upper bounds are not used.
#'
#' The availability is per person. From a survey, it is the mean of
#' `qty_vehicle_g_d_pc` of [vehicle_coverage()] for the flour vehicle; see
#' there for how it differs from the figure WHO used.
#'
#' @param availability_g_d Estimated average per capita wheat flour
#'   availability, g per day: one number >= 0.
#' @param extraction Flour extraction rate: `"low"` or `"high"`. Rows for
#'   `"low or high"` apply to both.
#' @param table Levels table, by default [ref_who2009_flour].
#' @returns The rows of `table` that apply, one per nutrient, extraction
#'   and compound. A compound not recommended at that availability is kept
#'   with `recommended = FALSE` and a missing level.
#' @seealso [ref_who2009_flour], [vehicle_coverage()], [apply_scenario()].
#' @examples
#' who2009_levels(120, extraction = "low")
#' @export
who2009_levels <- function(availability_g_d, extraction,
                           table = hcesfort::ref_who2009_flour) {
  check_required()
  check_one_number(availability_g_d, "availability_g_d", lower = 0)
  if (!is.finite(availability_g_d)) {
    abort_afe_arg("availability_g_d", "one finite number >= 0",
                  rlang::current_env())
  }
  extraction <- check_required_choice(extraction, c("low", "high"))
  check_who2009_table(table)
  x <- table[table$extraction %in% c(extraction, "low or high"), ]
  open <- startsWith(x$availability_g_d, ">")
  reached <- ifelse(open, availability_g_d > x$availability_from_g_d,
                    availability_g_d >= x$availability_from_g_d)
  x <- x[reached, ]
  group <- paste(x$nutrient, x$extraction, x$compound, sep = "\r")
  top <- stats::ave(x$availability_from_g_d, group, FUN = max)
  x[x$availability_from_g_d == top, ]
}

# Abort unless `table` has the columns who2009_levels() reads, with the
# types it needs.
check_who2009_table <- function(table, call = rlang::caller_env()) {
  text <- c("nutrient", "extraction", "compound", "availability_g_d")
  number <- c("availability_from_g_d", "level_mg_kg")
  ok <- is.data.frame(table) && all(c(text, number) %in% names(table)) &&
    all(vapply(table[intersect(text, names(table))], is.character, TRUE)) &&
    all(vapply(table[intersect(number, names(table))], is.numeric, TRUE))
  if (ok) return(invisible(table))
  abort_hcesfort("schema", c(
    "{.arg table} is not a table of levels like {.code ref_who2009_flour}.",
    "i" = "Text columns: {.field {text}}; numeric: {.field {number}}."
  ), table = "table", columns = c(text, number), call = call)
}
