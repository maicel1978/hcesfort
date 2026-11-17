# The upper-level exhibit of the results report (docs/design-reports-v3.md,
# section 6.4), with the column at compliance 1 (V3.1, P218). Sourced by
# results.qmd after _scenarios.R, whose helpers it uses; do not edit.

# ---- R3.3. Upper level (6.4) -----------------------------------------
# Households above the UL of each nutrient a scenario adds, from the
# scenario intake `x`. The comparison uses the total where the diet part of
# the form is known, else the added part (`ul_scope`).
above_ul_estimates <- function(x = s) {
  ul <- above_ul(x, requirements, min_coverage = choices$min_coverage,
                 min_records_used = choices$min_records_used)
  flagged <- "average_content_understates_ul" %in% audit_log(ul)$cause
  ul <- ul[ul$nutrient %in% choices$nutrients & ul$scenario != "baseline" &
             adds(ul), ]
  ul$above_ul <- ifelse(is.na(ul$above_ul_total), ul$above_ul_added,
                        ul$above_ul_total)
  attr(ul, "understated") <- flagged
  ul
}

# The column at compliance 1 (V3.1, P218): the share above the UL of the
# same scenarios with every compliance set to 1, the upper bound of the
# share under either compliance model. Added to the estimates `e` as
# `above_ul_full` (percent, matched by nutrient and scenario; missing
# where that estimate is hidden by the presentation standard). `e` is
# returned unchanged when every compliance is 1: the column would repeat
# the estimate.
with_ul_bound <- function(e) {
  if (!any(scenarios[["compliance"]] < 1)) {
    return(e)
  }
  full <- scenarios
  full$compliance <- 1
  f <- est(above_ul_estimates(apply_scenario(drop_excluded(intake), use,
                                             full)), "above_ul")
  k <- function(t) paste(t$nutrient, t$scenario)
  e$above_ul_full <- shown_value(f, function(x) pct(x, 2))[match(k(e), k(f))]
  e
}

# Nutrients with no household above the UL under any scenario, at the
# compliance given and at compliance 1, leave the figure for one sentence
# (R21), unless flagged estimates are suppressed. With the column at
# compliance 1, a cell of zero events stays in the table, so its bound is
# shown, and the column is drawn as a hollow point.
above_ul_figure <- function(instance) {
  ul <- above_ul_estimates()
  e <- with_ul_bound(est(ul, "above_ul"))
  bound <- !is.null(e$above_ul_full)
  zero_full <- if (bound) e$above_ul_full %in% 0 else rep(TRUE, nrow(e))
  zero <- tapply(e$estimate %in% 0 & zero_full, e$nutrient, all)
  none <- if (choices$review == "show") names(zero)[zero] else character(0)
  p <- shown_pair(e[!e$nutrient %in% none, ],
                  c(nutrient = "nutrient", scenario = "scenario"), NULL,
                  "above_ul", scale = function(x) pct(x, 2),
                  extra = if (bound) "above_ul_full", drop_exact = !bound)
  if (bound) p <- lapply(p, move_last, "above_ul_full")
  g <- fig_interval(p$data, "above_ul", "scenario",
                    xlab = term("above_ul", "header"),
                    ylab = term("scenario", "header"), ref = 0,
                    facet = "nutrient")
  if (bound) {
    g <- g + geom_point(aes(x = .data$above_ul_full), shape = 1, size = 2.5,
                        na.rm = TRUE)
  }
  list(table = p$table, figure = g,
       rows = panel_rows(p$data, "scenario", "nutrient"),
       lead = ul_zero_sentence(e[e$nutrient %in% none, ]),
       note = c(ul_statements(ul), term("ul_adult", "note"),
                if (any(scenarios[["compliance"]] < 1)) {
                  term(paste0("ul_model_", compliance_model), "note")
                },
                if (bound) term("ul_compliance_1", "note"),
                if (isTRUE(attr(ul, "understated"))) {
                  term("ul_average_content", "note")
                }))
}

# "In the sample (n = …), no household exceeds the UL of <nutrients> under
# any scenario (upper limit: …)", with the largest upper limit of each.
ul_zero_sentence <- function(e) {
  if (nrow(e) == 0) {
    return(NULL)
  }
  nut <- intersect(choices$nutrients, e$nutrient)
  upper <- tapply(e$ci_high, e$nutrient, max)[nut]
  name <- lower_first(as.character(lab(nut, "nutrient")))
  n <- format_n(range(e$n))
  fill(term("ul_zero", "sentence"), n = paste(unique(n), collapse = "–"),
       nutrients = collapse(name), level = 100 * level,
       limits = paste0(name, " ", pct(upper, 2), "%", collapse = "; "))
}

# One statement per nutrient, keyed by the form the UL applies to and by
# what was compared. A missing statement stops the render.
ul_statements <- function(ul) {
  d <- unique(as.data.frame(ul)[c("nutrient", "ul_applies_to", "ul_scope")])
  d <- d[order(match(d$nutrient, choices$nutrients)), ]
  key <- ifelse(d$ul_scope == "not_assessable", "not_assessable",
                paste(d$ul_applies_to, d$ul_scope, sep = "."))
  have <- terms$code[terms$type == "ul_statement"]
  if (!all(key %in% have)) {
    template_abort(paste0(
      "terms.csv has no `ul_statement` for: ",
      paste(unique(setdiff(key, have)), collapse = ", "),
      ". Add one row per form and scope of the upper level."
    ))
  }
  paste0(lab(d$nutrient, "nutrient"), ": ", term(key, "ul_statement"))
}
