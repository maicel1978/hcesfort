# Exhibits of the readiness report (docs/design-reports-v3.md, section
# 4.1). Sourced by readiness.qmd after _inputs.R, _chain.R, _tables.R,
# _figures.R and _exhibits.R; do not edit. Each builder named in
# exhibits.csv takes the instance and returns the list that show_exhibit()
# prints; tables have code column names, shares in percent and differences
# of shares in points. Every word comes from terms.csv or labels.csv.

labels <- read_labels("labels.csv", needed = list(
  domain = choices$domains,
  domain_value = lapply(stats::setNames(nm = domains),
                        function(d) unique(as.character(households[[d]]))),
  nutrient = choices$nutrients
))
decisions <- read_decisions("decisions.csv")
absent <- inventory[inventory$role == "essential" & !inventory$present, ]
absent <- ifelse(is.na(absent$variable), absent$table,
                 paste0(absent$table, "$", absent$variable))

# A list of labels in one string.
collapse <- function(x) paste(x, collapse = ", ")

# ---- D2 and DA1. Variables -------------------------------------------

# `needed_by` is one term of type `needed_by` ("domain" is followed by
# the label of the domain) or a list of sections.
format_inventory <- function(inv) {
  single <- terms$code[terms$type == "needed_by"]
  needed <- vapply(seq_len(nrow(inv)), function(i) {
    v <- strsplit(inv$needed_by[[i]], ", ", fixed = TRUE)[[1]]
    if (length(v) == 1 && v == "domain") {
      return(paste(term(v, "needed_by"),
                   tolower(lab(inv$variable[[i]], "domain"))))
    }
    if (length(v) == 1 && v %in% single) {
      return(term(v, "needed_by"))
    }
    collapse(term(v, "section"))
  }, character(1))
  data.frame(table = inv$table, variable = inv$variable,
             role = term(inv$role, "role"),
             present = term(inv$present, "flag"),
             share_missing = pct(inv$share_missing), needed_by = needed)
}

# The essential variables, and the optional ones absent or partly missing
# (DR13).
variables_table <- function(instance) {
  partly <- !is.na(inventory$share_missing) & inventory$share_missing > 0
  keep <- inventory$role == "essential" | !inventory$present | partly
  list(table = format_inventory(inventory[keep, ]),
       note = term("inventory", "note"))
}

inventory_table <- function(instance) {
  list(table = format_inventory(inventory))
}

# ---- D3 to D6. Checks, ladder and work queue -------------------------

# The detail of a check is a household status, a nutrient or a domain.
format_checks <- function(ch) {
  detail <- rep(NA_character_, nrow(ch))
  s <- ch$check == "household_status"
  detail[s] <- term(ch$detail[s], "household_status")
  v <- ch$check == "composition_value"
  detail[v] <- as.character(lab(ch$detail[v], "nutrient"))
  d <- ch$check == "domain_cells"
  detail[d] <- as.character(lab(ch$detail[d], "domain"))
  data.frame(check = term(ch$check, "check"), detail = detail, n = ch$n,
             value = pct(ch$value), threshold = pct(ch$threshold),
             met = term(ch$met, "flag"))
}

checks_table <- function(instance) {
  list(table = format_checks(checks))
}

# Without expenditure its column is dropped and a sentence says why.
ladder_table <- function(instance) {
  out <- data.frame(step = term(ladder$step, "step"),
                    n_records = ladder$n_records,
                    n_households = ladder$n_households,
                    share_records = pct(ladder$share_records),
                    share_grams = pct(ladder$share_grams),
                    share_expenditure = pct(ladder$share_expenditure))
  after <- fill(term("not_included", "sentence"),
                n = format_n(sum(!acquisitions$include)))
  if (has_expenditure) {
    none <- is.na(acquisitions$expenditure_lcu[acquisitions$include])
    after <- c(after, fill(term("no_expenditure_records", "sentence"),
                           n = format_n(sum(none))))
  } else {
    out$share_expenditure <- NULL
    after <- c(after, term("no_expenditure", "sentence"))
  }
  list(table = out, after = after)
}

# The work queue, in rank order.
format_queue <- function(queue) {
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

queue_table <- function(instance) {
  list(table = format_queue(queue),
       after = if (nrow(queue) == 0) term("queue_empty", "sentence"))
}

queue_curve <- function(instance) {
  d <- format_queue(queue)
  measures <- c(grams = term("grams", "measure"))
  if (has_expenditure) {
    measures <- c(measures, expenditure = term("expenditure", "measure"))
  }
  g <- fig_coverage_curve(d, measures,
                          threshold = 100 * choices$min_linked_share,
                          xlab = term("queue_x", "axis"),
                          ylab = term("queue_y", "axis"),
                          colour_lab = term("measure", "header"))
  list(table = d, figure = g, rows = 10, note = term("queue", "note"))
}

# ---- D7 and D8. Stopping rule and the unlinked share -----------------

# Share not linked by measure, national (`by = NULL`) or by one domain,
# with the difference from the rest of the population.
unlinked_table <- function(by = NULL) {
  measures <- c("grams", if (has_expenditure) "expenditure")
  dplyr::bind_rows(lapply(measures, function(m) {
    e <- estimate_unlinked(design, content, by = by, measure = m,
                           level = level)
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

stopping_table <- function(instance) {
  rule <- checks[checks$check %in% c("linked_grams", "linked_expenditure"), ]
  met <- all(rule$met %in% TRUE | is.na(rule$value))
  lead <- fill(term("rule", "sentence"),
               threshold = 100 * choices$min_linked_share,
               expenditure = if (has_expenditure) {
                 paste0(" ", term("rule_expenditure", "sentence"))
               } else {
                 ""
               },
               status = term(if (met) "met" else "not_met", "sentence"))
  list(table = unlinked_table(), lead = lead)
}

# The tables by domain, computed once by show_unlinked_domains().
unlinked_by <- new.env()

unlinked_by_domain <- function(instance) {
  list(table = unlinked_by[[instance]],
       headers = c(domain_value = as.character(lab(instance, "domain"))),
       note = fill(term("differs", "note"), level = 100 * level))
}

# Table D8 for each domain variable with a value that differs from the
# rest of the population (DR10); one sentence naming the others, and one
# for each domain variable absent from the households table.
show_unlinked_domains <- function() {
  same <- character(0)
  for (d in domains) {
    unlinked_by[[d]] <- unlinked_table(d)
    if (any(unlinked_by[[d]]$differs == term("TRUE", "flag"))) {
      show_exhibit("D8", d)
    } else {
      same <- c(same, d)
    }
  }
  print_sentences(c(
    if (length(same) > 0) {
      fill(term("no_domain_differs", "sentence"),
           domains = collapse(tolower(lab(same, "domain"))))
    },
    vapply(setdiff(choices$domains, domains), function(d) {
      fill(term("domain_absent", "sentence"),
           domain = as.character(lab(d, "domain")))
    }, character(1))
  ))
}

# ---- D9. Energy plausibility -----------------------------------------

# Median apparent energy per AFE and share of households outside the
# plausible range, national.
energy_table <- function() {
  est <- function(value, statistic) {
    estimate_households(design, flagged, value, statistic = statistic,
                        level = level)
  }
  m <- est(energy_column, "median")
  o <- est("energy_outside", "proportion")
  data.frame(n = m$n, median = round(m$estimate),
             ci_low = round(m$ci_low), ci_high = round(m$ci_high),
             pct_reference = pct(m$estimate / reference_kcal),
             outside = pct(o$estimate), outside_ci_low = pct(o$ci_low),
             outside_ci_high = pct(o$ci_high))
}

# One sentence and a weighted histogram (% of households) with the bounds
# and the reference energy (DR10: no by-domain exhibit).
energy_histogram <- function(instance) {
  e <- energy_table()
  h <- flagged[!is.na(flagged[[energy_column]]), ]
  w <- households$weight[match(h$household_id, households$household_id)]
  if (anyNA(w)) {
    template_abort("Internal: a household of the intake has no weight.")
  }
  h$share <- 100 * w / sum(w)
  g <- fig_histogram(h, energy_column, "share",
                     bounds = c(choices$energy_lower, choices$energy_upper),
                     reference = reference_kcal,
                     xlab = term("energy_x", "axis"),
                     ylab = term("energy_y", "axis"))
  lead <- fill(term("energy", "sentence"), median = format_n(e$median),
               low = format_n(e$ci_low), high = format_n(e$ci_high),
               pct = e$pct_reference, level = 100 * level,
               reference = format_n(round(reference_kcal)),
               lower = format_n(choices$energy_lower),
               upper = format_n(choices$energy_upper), outside = e$outside,
               outside_low = e$outside_ci_low,
               outside_high = e$outside_ci_high)
  list(table = e, figure = g, rows = 10, lead = lead,
       note = term("energy_lines", "note"))
}

# ---- D10. Decisions --------------------------------------------------

decisions_table <- function(instance) {
  list(table = as.data.frame(decisions))
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
