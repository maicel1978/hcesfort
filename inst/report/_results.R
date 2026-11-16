# Exhibits of the results report (docs/design-reports-v3.md, section 6):
# its inputs and sections 0 to 2. Sourced by results.qmd after _inputs.R,
# _chain.R, _tables.R, _figures.R and _exhibits.R, before _scenarios.R;
# do not edit. Each builder named in exhibits.csv takes the instance and
# returns the list that show_exhibit() prints. Tables have code column
# names, labels in the order of labels.csv, shares in percent and
# differences in points; figures print the short labels (R22). Each
# section, nationally and by domain, is shown only where the readiness
# verdict enables it.

# Each scenario of `scenarios` and the scenario it is compared with
# (decision 7): "baseline" unless `choices$comparator` names another.
# Every chain of comparators must end at "baseline".
scenario_comparators <- function(comparator, codes) {
  out <- stats::setNames(rep("baseline", length(codes)), codes)
  if (is.null(comparator)) {
    return(out)
  }
  nm <- names(comparator)
  bad <- unique(c(setdiff(nm, codes),
                  setdiff(comparator, c(codes, "baseline"))))
  if (is.null(nm) || any(nm %in% "") || anyDuplicated(nm) > 0 ||
        length(bad) > 0) {
    template_abort(paste0(
      "`choices$comparator` must map scenario codes of `scenarios` to a ",
      "scenario code or \"baseline\", once each. Unknown: ",
      paste(bad, collapse = ", "), "."
    ))
  }
  out[nm] <- comparator
  for (s in codes) {
    seen <- s
    while (out[[seen[1]]] != "baseline") {
      if (out[[seen[1]]] %in% seen) {
        template_abort(paste0("`choices$comparator` has a cycle: ",
                              paste(rev(c(out[[seen[1]]], seen)),
                                    collapse = " -> "), "."))
      }
      seen <- c(out[[seen[1]]], seen)
    }
  }
  out
}

# Header of the domain value column of a by-domain table: the domain label.
value_header <- function(d) {
  c(domain_value = as.character(lab(d, "domain")))
}

# Status of each estimate under the presentation standard of _inputs.R.
precision <- function(e) {
  flag_presentation(e, presentation_standard)
}
# Proportions use the Korn-Graubard interval, the one the standard judges.
est <- function(x, value, by = NULL, ...) {
  precision(estimate_households(design, x, value, by = by, level = level,
                                ci_method = "korn_graubard", ...))
}

# Label columns of an estimate table: the code columns in `types` (column
# = label type) and the domain values of `by`, as factors; rows in the
# order of the labels (domain value first).
label_columns <- function(e, types, by = NULL, short = FALSE) {
  d <- as.data.frame(e)
  for (col in names(types)) {
    d[[col]] <- lab(d[[col]], types[[col]], short = short)
  }
  if (!is.null(by)) d$domain_value <- domain_label(d[[by]], by, short)
  keys <- c(if (!is.null(by)) "domain_value", names(types))
  d[do.call(order, unname(d[keys])), , drop = FALSE]
}

# One estimate table for display() twice: `table` with the labels, for
# `tables` and the appendix, and `data` with the short labels, for the
# figure.
shown_pair <- function(e, types, by, value, ...) {
  keys <- c(if (!is.null(by)) "domain_value", names(types))
  list(table = display(label_columns(e, types, by), keys, value, ...),
       data = display(label_columns(e, types, by, short = TRUE), keys,
                      value, ...))
}

# Height of a figure in rows: the most rows of a panel times the rows of
# panels (two panels a row).
panel_rows <- function(d, y, facet = NULL) {
  if (is.null(facet) || nrow(d) == 0) {
    return(length(unique(d[[y]])))
  }
  per <- tapply(as.character(d[[y]]), as.character(d[[facet]]),
                function(v) length(unique(v)))
  max(per) * ceiling(length(per) / 2)
}

# ---- Inputs of the results ------------------------------------------
comparators <- if (!is.null(scenarios)) {
  scenario_comparators(choices$comparator, unique(scenarios$scenario))
}
use <- NULL
if (ready && !is.null(vehicles)) {
  all_vehicles <- unique(c(vehicles$vehicle,
                           stats::na.omit(vehicles$vehicle_group)))
  use <- drop_excluded(vehicle_coverage(
    grams, vehicles, afe, households,
    fortifiable = if (!is.null(grams[["fortifiable"]])) fortifiable_choice,
    combine = list(any_vehicle = all_vehicles)
  ))
}
labels <- read_labels("labels.csv", needed = list(
  domain = choices$domains,
  domain_value = lapply(stats::setNames(nm = domains), function(d) {
    unique(stats::na.omit(as.character(households[[d]])))
  }),
  nutrient = choices$nutrients,
  vehicle = unique(vehicles$vehicle),
  vehicle_group = unique(c(stats::na.omit(vehicles$vehicle_group),
                           if (!is.null(use)) "any_vehicle")),
  scenario = c("baseline", unique(scenarios$scenario)),
  food_group = unique(food_groups$food_group),
  form = unique(stats::na.omit(scenarios$form)),
  compound = unique(stats::na.omit(scenarios$compound)),
  source = unique(scenarios$source)
))
risk <- NULL
if (enabled("risk")) {
  s <- if (enabled("scenarios")) {
    apply_scenario(drop_excluded(intake), use, scenarios,
                   compliance_model = compliance_model)
  } else {
    drop_excluded(intake)
  }
  risk_args <- list(requirements,
                    distribution = list(iron = iron_distribution),
                    min_coverage = choices$min_coverage,
                    min_records_used = choices$min_records_used)
  risk <- do.call(inadequacy, c(list(s), risk_args, list(
    bioavailability = list(iron = choices$iron_bioavailability)
  )))
  risk <- risk[risk$nutrient %in% choices$nutrients, ]
  risk$scenario[is.na(risk$scenario)] <- "baseline"
}

# Rows of the baseline, and of each scenario for the nutrients it adds.
adds <- function(x) {
  pairs <- unique(paste(scenarios$scenario, scenarios$nutrient))
  x$scenario == "baseline" | paste(x$scenario, x$nutrient) %in% pairs
}

# Method of each nutrient and its bioavailability, for the notes (R22:
# "Iron: probability approach, iron bioavailability 10%"), followed by the
# note that the shares are of apparent, not usual, intake (P183).
method_note <- function() {
  m <- unique(risk[c("nutrient", "method", "bioavailability")])
  m <- m[match(choices$nutrients, m$nutrient), ]
  name <- as.character(lab(m$nutrient, "nutrient"))
  b <- ifelse(is.na(m$bioavailability), "", paste0(
    ", ", fill(term("bioavailability", "note"), nutrient = lower_first(name)),
    " ", pct(m$bioavailability, 0), "%"
  ))
  c(fill(term("method", "note"),
         methods = paste0(name, ": ", term(m$method, "method"), b,
                          collapse = "; ")),
    term("usual_intake", "note"))
}

# The households the results cover (P148): those outside the plausible
# energy range are kept or left out by `choices$energy_action`.
population_sentence <- function() {
  if (is.null(flagged)) {
    return(term("no_energy", "sentence"))
  }
  fill(term(paste0("population_", choices$energy_action), "sentence"),
       n = format_n(sum(flagged$energy_outside %in% TRUE)),
       total = format_n(sum(!is.na(flagged$energy_outside))),
       lower = format_n(choices$energy_lower),
       upper = format_n(choices$energy_upper))
}

# ---- R0. Main findings -----------------------------------------------
findings_figure <- function(instance) {
  p <- shown_pair(est(risk[adds(risk), ], "p_inadequate"),
                  c(nutrient = "nutrient", scenario = "scenario"), NULL,
                  "inadequate")
  g <- fig_interval(p$data, "inadequate", "scenario",
                    xlab = term("inadequate", "header"),
                    ylab = term("scenario", "header"), facet = "nutrient",
                    percent = TRUE)
  list(table = p$table, figure = g,
       rows = panel_rows(p$data, "scenario", "nutrient"),
       note = method_note())
}

# ---- Section 1. Coverage and quantity --------------------------------
coverage_exhibit <- function(e, col, value = "acquired", ...) {
  p <- shown_pair(e, stats::setNames(col, col), NULL, value, ...)
  list(table = p$table,
       figure = fig_interval(p$data, value, col,
                             xlab = term(value, "header"),
                             ylab = term(col, "header"),
                             percent = value == "acquired"))
}

coverage_vehicle <- function(instance) {
  coverage_exhibit(est(use[use$level == "vehicle", ], "acquired"),
                   "vehicle")
}

coverage_group <- function(instance) {
  e <- est(use[use$level %in% c("group", "combined"), ], "acquired")
  e$vehicle_group <- e$vehicle
  out <- coverage_exhibit(e, "vehicle_group")
  out$note <- fill(term("groups", "note"), groups = group_note())
  out
}

# The members of each vehicle group and of "any vehicle".
group_note <- function() {
  g <- unique(stats::na.omit(vehicles$vehicle_group))
  members <- function(v) collapse(as.character(lab(unique(v), "vehicle")))
  parts <- vapply(g, function(x) {
    paste0(lab(x, "vehicle_group"), ": ",
           members(vehicles$vehicle[vehicles$vehicle_group %in% x]))
  }, character(1))
  any <- paste0(lab("any_vehicle", "vehicle_group"), ": ",
                members(vehicles$vehicle))
  paste(c(parts, any), collapse = "; ")
}

# Median among acquirers, judged by sample size and degrees of freedom
# only (S1).
quantity_vehicle <- function(instance) {
  e <- precision(estimate_households(
    design, use[use$level == "vehicle", ], "qty_vehicle_g_d",
    statistic = "median", domain = "acquired", level = level
  ))
  out <- coverage_exhibit(e, "vehicle", "median_g", scale = round,
                          unit = " g")
  out$note <- term("not_proportion", "note")
  out
}

# Households acquiring no vehicle, one domain variable (the national
# figure is the complement of R1.2). The proportion is estimated as such,
# so the standard judges the estimate that is printed.
no_vehicle_by_domain <- function(instance) {
  x <- use[use$vehicle == "any_vehicle", ]
  x$no_vehicle <- !x$acquired
  p <- shown_pair(est(x, "no_vehicle", by = instance), list(), instance,
                  "none")
  g <- fig_interval(p$data, "none", "domain_value",
                    xlab = term("none", "header"),
                    ylab = as.character(lab(instance, "domain")),
                    percent = TRUE)
  list(table = p$table, figure = g, headers = value_header(instance))
}

# ---- Section 2. Inadequate apparent intake ---------------------------
risk_national <- function(instance) {
  p <- shown_pair(est(risk[risk$scenario == "baseline", ], "p_inadequate"),
                  c(nutrient = "nutrient"), NULL, "inadequate")
  g <- fig_interval(p$data, "inadequate", "nutrient",
                    xlab = term("inadequate", "header"),
                    ylab = term("nutrient", "header"), percent = TRUE)
  list(table = p$table, figure = g, note = method_note())
}

# Panels by nutrient, a dashed line at the national estimate.
risk_by_domain <- function(instance) {
  base <- risk[risk$scenario == "baseline", ]
  p <- shown_pair(est(base, "p_inadequate", by = instance),
                  c(nutrient = "nutrient"), instance, "inadequate")
  national <- est(base, "p_inadequate")
  names(national$estimate) <- as.character(
    lab(national$nutrient, "nutrient", short = TRUE)
  )
  p$data$national <- pct(national$estimate[as.character(p$data$nutrient)])
  g <- fig_interval(p$data, "inadequate", "domain_value",
                    xlab = term("inadequate", "header"),
                    ylab = as.character(lab(instance, "domain")),
                    ref = "national", facet = "nutrient", percent = TRUE)
  list(table = p$table, figure = g,
       rows = panel_rows(p$data, "domain_value", "nutrient"),
       headers = value_header(instance),
       note = c(term("national_line", "note"), method_note()))
}

# Each domain variable of `choices$domains`: the exhibit, or the sentence
# of the verdict where the domain is disabled or absent.
show_domains <- function(id) {
  for (d in choices$domains) show_exhibit(id, d)
  invisible(NULL)
}
