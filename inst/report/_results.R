# Estimates and tables of the results report. Sourced by results.qmd after
# _inputs.R, _chain.R, _tables.R and _figures.R; do not edit. Each
# section, nationally and by domain, is computed only where the readiness
# verdict enables it. Every builder returns a table for `tables`, with code
# column names and values in percent (shares) or points (differences).

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

# Whether the verdict enables a section, nationally (`domain = NA`) or for
# one domain, and the sentence printed when it does not.
enabled <- function(section, domain = NA) {
  v <- verdict[verdict$section == section & verdict$domain %in% domain, ]
  nrow(v) == 1 && v$enabled
}
disabled_sentence <- function(section, domain = NA) {
  v <- verdict[verdict$section == section & verdict$domain %in% domain, ]
  where <- if (is.na(domain)) {
    term(section, "section")
  } else {
    lab(domain, "domain")
  }
  paste0(where, ": ", verdict_text(v), ".")
}

# Header of the domain value column of a by-domain table: the domain label.
value_header <- function(d) {
  c(domain_value = as.character(lab(d, "domain")))
}

precision <- function(e) {
  flag_precision(e, min_n = choices$min_n,
                 max_half_width = choices$max_half_width)
}
est <- function(x, value, by = NULL, ...) {
  precision(estimate_households(design, x, value, by = by,
                                level = choices$level, ...))
}
# Label columns of an estimate table: the code columns in `types` (column
# = label type) and the domain values of `by`.
label_columns <- function(e, types, by = NULL) {
  d <- as.data.frame(e)
  for (col in names(types)) d[[col]] <- lab(d[[col]], types[[col]])
  if (!is.null(by)) d$domain_value <- lab(d[[by]], "domain_value", by)
  d
}

# ---- Inputs of the results ------------------------------------------
comparators <- if (!is.null(scenarios)) {
  scenario_comparators(choices$comparator, unique(scenarios$scenario))
}
use <- NULL
if (ready && !is.null(vehicles)) {
  all_vehicles <- unique(c(vehicles$vehicle,
                           stats::na.omit(vehicles$vehicle_group)))
  use <- vehicle_coverage(grams, vehicles, afe, households,
                          combine = list(any_vehicle = all_vehicles))
}
labels <- read_labels("labels.csv", needed = list(
  domain = choices$domains,
  domain_value = lapply(stats::setNames(nm = domains),
                        function(d) unique(as.character(households[[d]]))),
  nutrient = choices$nutrients,
  vehicle = unique(vehicles$vehicle),
  vehicle_group = unique(c(stats::na.omit(vehicles$vehicle_group),
                           if (!is.null(use)) "any_vehicle")),
  scenario = c("baseline", unique(scenarios$scenario)),
  food_group = c(unique(food_groups$food_group),
                 if (!is.null(food_groups)) "unclassified"),
  form = unique(stats::na.omit(scenarios$form)),
  source = unique(scenarios$source)
))
risk <- NULL
if (enabled("risk")) {
  s <- if (enabled("scenarios")) {
    apply_scenario(intake, use, scenarios, compliance_model = compliance_model)
  } else {
    intake
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

# ---- Section 1. Coverage and quantity --------------------------------
coverage_table <- function(level, by = NULL) {
  e <- est(use[use$level %in% level, ], "acquired", by = by)
  col <- if ("vehicle" %in% level) "vehicle" else "vehicle_group"
  e[[col]] <- e$vehicle
  e <- label_columns(e, stats::setNames(col, col), by)
  display(e, c(if (!is.null(by)) "domain_value", col), "acquired")
}

quantity_table <- function() {
  x <- use[use$level == "vehicle", ]
  e <- precision(estimate_households(
    design, x, "qty_vehicle_g_d", statistic = "median", domain = "acquired",
    level = choices$level
  ))
  e <- label_columns(e, c(vehicle = "vehicle"))
  display(e, "vehicle", "median_g", scale = round, unit = " g")
}

no_vehicle_table <- function(by = NULL) {
  e <- est(use[use$vehicle == "any_vehicle", ], "acquired", by = by)
  e[c("estimate", "ci_low", "ci_high")] <-
    1 - e[c("estimate", "ci_high", "ci_low")]
  if (is.null(by)) {
    e$population <- term("national", "header")
    return(display(e, "population", "none"))
  }
  display(label_columns(e, list(), by), "domain_value", "none")
}

# The members of each vehicle group, for the note of exhibit 1.2.
group_note <- function() {
  g <- unique(stats::na.omit(vehicles$vehicle_group))
  parts <- vapply(g, function(x) {
    paste0(lab(x, "vehicle_group"), ": ", paste(
      lab(unique(vehicles$vehicle[vehicles$vehicle_group %in% x]), "vehicle"),
      collapse = ", "
    ))
  }, character(1))
  any <- paste0(lab("any_vehicle", "vehicle_group"), ": ",
                paste(lab(unique(vehicles$vehicle), "vehicle"),
                      collapse = ", "))
  paste0(paste(c(parts, any), collapse = ". "), ".")
}

# ---- Section 2. Risk without fortification ---------------------------
risk_table <- function(by = NULL) {
  e <- est(risk[risk$scenario == "baseline", ], "p_inadequate", by = by)
  e <- label_columns(e, c(nutrient = "nutrient"), by)
  display(e, c(if (!is.null(by)) "domain_value", "nutrient"), "inadequate")
}

# Method of each nutrient and the iron bioavailability, for the note.
method_note <- function() {
  m <- unique(risk[c("nutrient", "method", "bioavailability")])
  m <- m[match(choices$nutrients, m$nutrient), ]
  b <- ifelse(is.na(m$bioavailability), "",
              paste0(" (", pct(m$bioavailability, 0), "%)"))
  paste0(paste0(lab(m$nutrient, "nutrient"), ": ",
                term(m$method, "method"), b, collapse = "; "), ".")
}

# ---- Section 3. Scenarios --------------------------------------------
# Level as mg of nutrient per kg: compound rows times their fraction.
scenario_table <- function() {
  sc <- as.data.frame(scenarios)
  compound <- sc$level_basis %in% "compound"
  level <- ifelse(compound, sc$level_mg_kg * sc$nutrient_fraction,
                  sc$level_mg_kg)
  data.frame(scenario = lab(sc$scenario, "scenario"),
             vehicle = lab(sc$vehicle, "vehicle"),
             nutrient = lab(sc$nutrient, "nutrient"),
             level_mg_kg = signif(level, 3),
             form = lab(sc$form, "form"),
             compliance = pct(sc$compliance, 0),
             source = lab(sc$source, "source"))
}

# Paired change of each scenario against its comparator, only for the
# scenario and nutrient pairs of `scenarios`, with both points.
effects <- function(by = NULL) {
  pairs <- unique(paste(scenarios$scenario, scenarios$nutrient))
  points <- est(risk, "p_inadequate", by = by)
  key <- function(d, scenario) {
    paste(scenario, d$nutrient, if (!is.null(by)) d[[by]])
  }
  out <- lapply(unique(comparators), function(cmp) {
    d <- precision(estimate_difference(design, risk, "p_inadequate",
                                       reference = cmp, by = by,
                                       level = choices$level))
    d <- as.data.frame(d)
    d <- d[d$scenario %in% names(comparators)[comparators == cmp] &
             paste(d$scenario, d$nutrient) %in% pairs, ]
    d$comparator <- cmp
    d$from <- points$estimate[match(key(d, cmp), key(points, points$scenario))]
    d$to <- points$estimate[match(key(d, d$scenario),
                                  key(points, points$scenario))]
    d
  })
  do.call(rbind, out)
}

effects_table <- function(by = NULL) {
  d <- effects(by)
  small <- d$precision_status %in% "small_cell"
  d$from <- ifelse(small, NA, pct(d$from))
  d$to <- ifelse(small, NA, pct(d$to))
  d <- label_columns(d, c(scenario = "scenario", comparator = "scenario",
                          nutrient = "nutrient"), by)
  keys <- c(if (!is.null(by)) "domain_value", "nutrient", "scenario",
            "comparator")
  out <- display(d, keys, "difference", unit = "", extra = c("from", "to"))
  names(out) <- sub("^ci_", "difference_ci_", names(out))
  out
}

# Households above the UL of each nutrient. The comparison uses the total
# where the diet part of the form is known, else the added part; the
# scope table says which, and the direction of its bias.
above_ul_estimates <- function() {
  ul <- above_ul(s, requirements, min_coverage = choices$min_coverage,
                 min_records_used = choices$min_records_used)
  ul <- ul[ul$nutrient %in% choices$nutrients, ]
  ul$above_ul <- ifelse(is.na(ul$above_ul_total), ul$above_ul_added,
                        ul$above_ul_total)
  ul
}

ul_scope_table <- function(ul) {
  d <- unique(as.data.frame(ul)[c("nutrient", "ul_scope")])
  data.frame(nutrient = lab(d$nutrient, "nutrient"),
             ul_compared = term(d$ul_scope, "ul_scope"),
             ul_bias = term(d$ul_scope, "ul_bias"))
}

above_ul_table <- function(ul) {
  e <- label_columns(est(ul, "above_ul"),
                     c(scenario = "scenario", nutrient = "nutrient"))
  display(e, c("nutrient", "scenario"), "above_ul")
}

# ---- Section 4. Food groups ------------------------------------------
food_group_table <- function() {
  groups <- food_group_intake(content, food_groups, afe, households)
  e <- precision(food_group_shares(design, groups, level = choices$level))
  cols <- nutrients$column[match(choices$nutrients, nutrients$nutrient)]
  e <- e[e$variable %in% cols, ]
  e$nutrient <- choices$nutrients[match(e$variable, cols)]
  e <- label_columns(e, c(nutrient = "nutrient", food_group = "food_group"))
  display(e, c("nutrient", "food_group"), "share", drop_exact = FALSE)
}

# ---- Technical note --------------------------------------------------
reference_table <- function() {
  r <- as.data.frame(requirements)
  r <- r[r$nutrient %in% choices$nutrients, ]
  data.frame(nutrient = lab(r$nutrient, "nutrient"), ear = r$ear,
             unit = lab(r$unit, "unit"), ul = r$ul,
             ul_unit = lab(r$ul_unit, "unit"), source = r$source)
}

iron_sensitivity_table <- function() {
  b <- sort(unique(c(choices$iron_bioavailability,
                     choices$iron_bioavailability_sensitivity)))
  base <- if (is.null(s$scenario)) s else s[s$scenario == "baseline", ]
  r <- do.call(inadequacy, c(list(base), risk_args,
                             list(bioavailability = list(iron = b))))
  e <- est(r[r$nutrient == "iron", ], "p_inadequate")
  e$bioavailability_pct <- paste0(pct(e$bioavailability, 0), "%")
  display(e, "bioavailability_pct", "inadequate")
}
