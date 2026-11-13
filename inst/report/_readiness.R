# Objects of the readiness report only. Sourced by readiness.qmd after
# _inputs.R, _chain.R, _tables.R and _figures.R; do not edit. Every
# builder returns a table for `tables`, with code column names, values in
# percent (shares) or points (differences of shares).

labels <- read_labels("labels.csv", needed = list(
  domain = choices$domains,
  domain_value = lapply(stats::setNames(nm = domains),
                        function(d) unique(as.character(households[[d]]))),
  nutrient = choices$nutrients
))
decisions <- read_decisions("decisions.csv")

# Section 1. `needed_by` is "all", "none" or a list of sections.
inventory_table <- function(inv) {
  needed <- vapply(strsplit(inv$needed_by, ", ", fixed = TRUE), function(v) {
    if (length(v) == 1 && v %in% c("all", "none")) {
      return(term(v, "needed_by"))
    }
    paste(term(v, "section"), collapse = ", ")
  }, character(1))
  data.frame(table = inv$table, variable = inv$variable,
             role = term(inv$role, "role"),
             present = term(inv$present, "flag"),
             share_missing = pct(inv$share_missing), needed_by = needed)
}

# Section 2. The detail is a household status or a nutrient.
checks_table <- function(ch) {
  detail <- rep(NA_character_, nrow(ch))
  s <- ch$check == "household_status"
  detail[s] <- term(ch$detail[s], "household_status")
  v <- ch$check == "composition_value"
  detail[v] <- as.character(lab(ch$detail[v], "nutrient"))
  data.frame(check = term(ch$check, "check"), detail = detail, n = ch$n,
             value = pct(ch$value), threshold = pct(ch$threshold),
             met = term(ch$met, "flag"))
}

# Section 3. Without expenditure its column is dropped.
ladder_table <- function(ladder) {
  out <- data.frame(step = term(ladder$step, "step"),
                    n_records = ladder$n_records,
                    n_households = ladder$n_households,
                    share_records = pct(ladder$share_records),
                    share_grams = pct(ladder$share_grams),
                    share_expenditure = pct(ladder$share_expenditure))
  if (!has_expenditure) out$share_expenditure <- NULL
  out
}

# Section 4. The work queue, in rank order.
queue_table <- function(queue) {
  out <- data.frame(
    rank = queue$rank, food_code = queue$food_code,
    reasons = term_list(queue$reasons, "reason", "; "),
    units_no_grams = queue$units_no_grams,
    n_not_linked = queue$n_not_linked,
    share_grams = pct(queue$share_grams),
    share_expenditure = pct(queue$share_expenditure),
    cum_share_grams = pct(queue$cum_share_grams),
    cum_share_expenditure = pct(queue$cum_share_expenditure)
  )
  if (!has_expenditure) {
    out$share_expenditure <- out$cum_share_expenditure <- NULL
  }
  out
}

# Section 5. Share not linked by measure, national (`by = NULL`) or by one
# domain, with the difference from the rest of the population.
unlinked_table <- function(by = NULL) {
  measures <- c("grams", if (has_expenditure) "expenditure")
  dplyr::bind_rows(lapply(measures, function(m) {
    e <- estimate_unlinked(design, content, by = by, measure = m,
                           level = choices$level)
    out <- data.frame(measure = term(rep(m, nrow(e)), "measure"), n = e$n,
                      unlinked = pct(e$estimate), ci_low = pct(e$ci_low),
                      ci_high = pct(e$ci_high))
    if (is.null(by)) {
      return(out)
    }
    cbind(data.frame(domain_value = lab(e[[by]], "domain_value", by)), out,
          data.frame(rest = pct(e$rest_estimate),
                     difference = pct(e$difference),
                     difference_ci_low = pct(e$difference_ci_low),
                     difference_ci_high = pct(e$difference_ci_high),
                     differs = term(e$differs, "flag")))
  }))
}

# Section 6. Median apparent energy per AFE and share of households
# outside the plausible range, national (`by = NULL`) or by one domain.
energy_table <- function(flagged, column, by = NULL) {
  est <- function(value, statistic) {
    estimate_households(design, flagged, value, statistic = statistic,
                        by = by, level = choices$level)
  }
  m <- est(column, "median")
  o <- est("energy_outside", "proportion")
  if (!is.null(by) && !identical(m[[by]], o[[by]])) {
    template_abort("Internal: the two energy estimates differ in rows.")
  }
  out <- data.frame(n = m$n, median = round(m$estimate),
                    ci_low = round(m$ci_low), ci_high = round(m$ci_high),
                    pct_reference = pct(m$estimate / reference_kcal),
                    outside = pct(o$estimate),
                    outside_ci_low = pct(o$ci_low),
                    outside_ci_high = pct(o$ci_high))
  if (is.null(by)) out else
    cbind(data.frame(domain_value = lab(m[[by]], "domain_value", by)), out)
}

# Section 8. Sections by rows, national and each domain by columns.
verdict_table <- function(v) {
  detail <- ifelse(v$reason %in% "threshold_not_met",
                   term_list(v$detail, "check"), v$detail)
  cell <- ifelse(v$enabled, term(rep("enabled", nrow(v)), "verdict"),
                 paste0(term(v$reason, "verdict_reason"), " (", detail, ")"))
  where <- ifelse(is.na(v$domain), "national", v$domain)
  out <- data.frame(section = term(unique(v$section), "section"))
  for (w in unique(where)) out[[w]] <- cell[where == w]
  out
}

# Headers of the domain columns of the verdict: the domain labels.
domain_headers <- function(d) {
  stats::setNames(as.character(lab(d, "domain")), d)
}

if (ready) {
  queue <- unmatched_foods(content, households)
  energy_column <- NULL
  if (!is.null(choices$energy)) {
    energy_column <- nutrients$column[nutrients$nutrient == choices$energy]
    if (!identical(nutrients$unit[nutrients$nutrient == choices$energy],
                   "kcal")) {
      template_abort(paste(
        "`choices$energy` must name a nutrient of the registry in kcal:",
        "it is compared with the energy of the reference person."
      ))
    }
    flagged <- flag_energy_plausibility(intake, energy_column,
                                        choices$energy_lower,
                                        choices$energy_upper)
    flagged$energy_outside <- !flagged$energy_plausible
  }
}
