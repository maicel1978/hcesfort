# Daily energy requirement of each member, the numerator of the adult
# female equivalent. Infants (< 1 year) by month or by the mean of the
# months; children by year of age from the tabulated requirements; adults
# (from the end of the tabulated years) as BMR x PAL. Design decisions:
# docs/improvements.md, "Decisions (2026-11-12, task 5)".

# Energy requirement of each member, kcal per day; NA where age or sex is
# missing, or where the reference tables have no interval for the member.
member_energy <- function(m, energy, bmr, weight_kg, pal, infants) {
  kcal <- rep(NA_real_, nrow(m))
  known <- !is.na(m$age_years) & !is.na(m$sex)
  years <- energy[energy$age_unit == "year", ]
  adult_from <- if (nrow(years) > 0) max(years$age_to) else 1
  infant <- known & m$age_years < 1
  months <- infant_months(m, infants)
  by_month <- infant & !is.na(months)
  kcal[by_month] <- lookup_interval(
    energy[energy$age_unit == "month", ], m$sex[by_month], months[by_month],
    "energy_kcal_d"
  )
  by_mean <- infant & is.na(months)
  kcal[by_mean] <- infant_mean(energy, m$sex[by_mean])
  child <- known & m$age_years >= 1 & m$age_years < adult_from
  kcal[child] <- lookup_interval(years, m$sex[child], m$age_years[child],
                                 "energy_kcal_d")
  adult <- known & m$age_years >= adult_from
  kcal[adult] <- adult_energy(m[adult, ], bmr, weight_kg, pal)
  attr(kcal, "infant_mean") <- by_mean
  kcal
}

# Age in months of each member when it can be used for the monthly table
# (rule "monthly", `age_months` present and in [0, 12)); NA otherwise.
infant_months <- function(m, infants) {
  if (infants == "annual_mean" || is.null(m[["age_months"]])) {
    return(rep(NA_real_, nrow(m)))
  }
  months <- m[["age_months"]]
  months[!is.na(months) & months >= 12] <- NA_real_
  months
}

# For each (sex, age), the value of column `value` in the row of `table`
# whose interval [age_from, age_to) holds the age; NA when none does.
lookup_interval <- function(table, sex, age, value) {
  out <- rep(NA_real_, length(age))
  for (i in seq_len(nrow(table))) {
    hit <- sex == table$sex[[i]] & age >= table$age_from[[i]] &
      age < table$age_to[[i]]
    out[hit] <- table[[value]][[i]]
  }
  out
}

# Mean of the monthly requirements of the first year, by sex (the rule of
# the original analysis); NA when the table has no month for that sex.
infant_mean <- function(energy, sex) {
  first_year <- energy[energy$age_unit == "month" & energy$age_to <= 12, ]
  means <- tapply(first_year$energy_kcal_d, first_year$sex, mean)
  unname(means[sex])
}

# Adults: BMR from body weight (the member's `weight_kg` when present,
# otherwise the weight given for the sex) times the physical activity level.
adult_energy <- function(adults, bmr, weight_kg, pal) {
  weight <- unname(weight_kg[adults$sex])
  if (!is.null(adults[["weight_kg"]])) {
    own <- !is.na(adults[["weight_kg"]])
    weight[own] <- adults[["weight_kg"]][own]
  }
  slope <- lookup_interval(bmr, adults$sex, adults$age_years,
                           "slope_kcal_kg")
  intercept <- lookup_interval(bmr, adults$sex, adults$age_years,
                               "intercept_kcal")
  (slope * weight + intercept) * pal
}
