# Exhibits of the results report (docs/design-reports-v3.md, sections
# 6.2 to 6.6): scenarios, food groups and the technical note. Sourced by
# results.qmd after _results.R, whose helpers it uses; do not edit.

# ---- R3.1. Scenarios table (6.2) -------------------------------------
# Level as mg of nutrient per kg: compound rows times their fraction. The
# compound where the scenario names one, else the form; neither is "not
# stated", never "—".
scenario_table <- function(instance) {
  sc <- as.data.frame(scenarios)
  for (col in c("compound", "form")) {
    if (is.null(sc[[col]])) sc[[col]] <- NA_character_
  }
  compound <- sc$level_basis %in% "compound"
  level_mg_kg <- ifelse(compound, sc$level_mg_kg * sc$nutrient_fraction,
                        sc$level_mg_kg)
  what <- ifelse(is.na(sc$compound), as.character(lab(sc$form, "form")),
                 as.character(lab(sc$compound, "compound")))
  what[is.na(what)] <- term("not_stated", "format")
  list(table = data.frame(
    scenario = lab(sc$scenario, "scenario"),
    abbreviation = lab(sc$scenario, "scenario", short = TRUE),
    vehicle = lab(sc$vehicle, "vehicle"),
    nutrient = lab(sc$nutrient, "nutrient"), compound_form = what,
    level_mg_kg = signif(level_mg_kg, 3),
    compliance = pct(sc$compliance, 0),
    source = lab(sc$source, "source")
  ), note = c(term("cumulative", "note"),
              if (fortifiable_used()) fortifiable_note()))
}

# ---- R3.2 and R3.4. Effect of a scenario (6.3) -----------------------
# Paired change of each scenario against its comparator, only for the
# scenario and nutrient pairs of `scenarios`, with both points; computed
# once for each `by`.
effects_by <- new.env()
effects <- function(by = NULL) {
  key <- if (is.null(by)) ".national" else by
  if (is.null(effects_by[[key]])) effects_by[[key]] <- compute_effects(by)
  effects_by[[key]]
}

compute_effects <- function(by) {
  points <- est(risk, "p_inadequate", by = by)
  key <- function(d, scenario) {
    paste(scenario, d$nutrient, if (!is.null(by)) d[[by]])
  }
  out <- lapply(unique(comparators), function(cmp) {
    d <- precision(estimate_difference(design, risk, "p_inadequate",
                                       reference = cmp, by = by,
                                       level = level))
    d <- as.data.frame(d)
    d <- d[d$scenario %in% names(comparators)[comparators == cmp] &
             adds(d), ]
    d$comparator <- cmp
    d$from <- points$estimate[match(key(d, cmp), key(points, points$scenario))]
    d$to <- points$estimate[match(key(d, d$scenario),
                                  key(points, points$scenario))]
    d
  })
  do.call(rbind, out)
}

# The points of a suppressed difference are not printed either. The
# table names the interval of the difference as such; the figure keeps
# `ci_low` and `ci_high`.
effect_display <- function(d, by, figure = FALSE) {
  small <- d$presentation %in% "suppress"
  d$from <- ifelse(small, NA, pct(d$from))
  d$to <- ifelse(small, NA, pct(d$to))
  keys <- c(if (!is.null(by)) "domain_value", "nutrient", "scenario",
            "comparator")
  out <- display(d, keys, "difference", unit = "", extra = c("from", "to"))
  if (!figure) names(out) <- sub("^ci_", "difference_ci_", names(out))
  out
}

# One nutrient, nationally (`by = NULL`, rows by scenario) or by one
# equity domain (rows by domain value, one band per scenario).
effect_exhibit <- function(nutrient, by) {
  d <- effects(by)
  d <- d[d$nutrient == nutrient, ]
  types <- c(scenario = "scenario", comparator = "scenario",
             nutrient = "nutrient")
  shown <- function(short) {
    effect_display(label_columns(d, types, by, short = short), by, short)
  }
  data <- shown(TRUE)
  y <- if (is.null(by)) "scenario" else "domain_value"
  g <- fig_effect(data, y, xlab = term("effect_x", "axis"),
                  ylab = if (is.null(by)) {
                    term("scenario", "header")
                  } else {
                    as.character(lab(by, "domain"))
                  },
                  panels = term(c("effect_level", "effect_difference"),
                                "axis"),
                  band = if (!is.null(by)) "scenario")
  cmp <- collapse(unique(as.character(lab(d$comparator, "scenario"))))
  list(table = shown(FALSE), figure = g, rows = nrow(data),
       headers = if (!is.null(by)) value_header(by),
       note = c(fill(term("effect", "note"), comparators = cmp,
                     level = 100 * level), term("not_proportion", "note"),
                term("usual_intake", "note")))
}

effect_figure <- function(instance) {
  effect_exhibit(instance[[1]], NULL)
}

effect_by_domain <- function(instance) {
  effect_exhibit(instance[[1]], instance[[2]])
}

# R3.2 for each nutrient a scenario adds; with `equity`, R3.4 for each
# equity domain and nutrient.
show_effects <- function(equity = FALSE) {
  added <- intersect(choices$nutrients, scenarios$nutrient)
  if (!equity) {
    for (n in added) show_exhibit("R3.2", n)
    return(invisible(NULL))
  }
  for (d in choices$equity_domains) {
    if (!enabled("scenarios", d)) {
      print_sentences(disabled_sentence("scenarios", d))
      next
    }
    for (n in added) show_exhibit("R3.4", c(n, d))
  }
  invisible(NULL)
}

# ---- R4.1. Food groups (6.5) -----------------------------------------
# A group with no content of a nutrient (share exactly 0) and the foods
# without a group leave the figure for the note (R20).
food_group_figure <- function(instance) {
  groups <- drop_excluded(food_group_intake(content, food_groups, afe,
                                            households))
  e <- as.data.frame(precision(food_group_shares(design, groups,
                                                 level = level)))
  cols <- nutrients$column[match(choices$nutrients, nutrients$nutrient)]
  e <- e[e$variable %in% cols, ]
  e$nutrient <- choices$nutrients[match(e$variable, cols)]
  other <- e$food_group == "unclassified"
  absent <- e$estimate %in% 0 & !other
  p <- shown_pair(e[!absent & !other, ],
                  c(nutrient = "nutrient", food_group = "food_group"),
                  NULL, "share", drop_exact = FALSE)
  g <- fig_interval(p$data, "share", "food_group",
                    xlab = term("share", "header"),
                    ylab = term("food_group", "header"), facet = "nutrient",
                    percent = TRUE)
  list(table = p$table, figure = g,
       rows = panel_rows(p$data, "food_group", "nutrient"),
       note = c(no_content_note(e[absent, ]), unclassified_note(e[other, ]),
                term("not_proportion", "note")))
}

# "No iron from: fats and oils, dairy and fruits", one line per nutrient.
no_content_note <- function(e) {
  vapply(intersect(choices$nutrients, e$nutrient), function(n) {
    g <- as.character(lab(e$food_group[e$nutrient == n], "food_group"))
    fill(term("no_content", "note"),
         nutrient = lower_first(as.character(lab(n, "nutrient"))),
         groups = collapse(lower_first(g)))
  }, character(1), USE.NAMES = FALSE)
}

unclassified_note <- function(e) {
  if (nrow(e) == 0) {
    return(NULL)
  }
  e <- e[order(match(e$nutrient, choices$nutrients)), ]
  name <- lower_first(as.character(lab(e$nutrient, "nutrient")))
  fill(term("unclassified", "note"),
       shares = paste0(name, " ", pct(e$estimate), "%", collapse = "; "))
}

# ---- Technical note (6.6) --------------------------------------------
requirements_table <- function(instance) {
  r <- as.data.frame(requirements)
  r <- r[r$nutrient %in% choices$nutrients, ]
  list(table = data.frame(
    nutrient = lab(r$nutrient, "nutrient"), ear = r$ear,
    unit = lab(r$unit, "unit"), ul = r$ul, ul_unit = lab(r$ul_unit, "unit"),
    source = r$source
  ))
}

# The rows of the presentation standard, the departures S1 to S4 and the
# choice for strata with one PSU.
standard_table <- function(instance) {
  st <- as.data.frame(presentation_standard)
  list(table = data.frame(criterion = term(st$criterion, "criterion"),
                          value = st$value, source = st$source,
                          location = st$location),
       after = c(term(c("s1", "s2"), "sentence"),
                 fill(term("s3", "sentence"),
                      review = term(choices$review, "review")),
                 term("s4", "sentence"),
                 fill(term("lonely_psu", "sentence"),
                      choice = term(choices$lonely_psu, "lonely_psu"))))
}

iron_sensitivity <- function(instance) {
  b <- sort(unique(c(choices$iron_bioavailability,
                     choices$iron_bioavailability_sensitivity)))
  base <- if (is.null(s$scenario)) s else s[s$scenario == "baseline", ]
  r <- do.call(inadequacy, c(list(base), risk_args,
                             list(bioavailability = list(iron = b))))
  e <- est(r[r$nutrient == "iron", ], "p_inadequate")
  e$bioavailability_pct <- paste0(pct(e$bioavailability, 0), "%")
  list(table = display(e, "bioavailability_pct", "inadequate"),
       note = fill(term("sensitivity", "note"),
                   pct = pct(choices$iron_bioavailability, 0)))
}
