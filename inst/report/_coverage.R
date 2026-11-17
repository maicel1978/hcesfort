# Section 1 of the results report (docs/design-reports-v3.md, section
# 6.1): coverage and quantity of the vehicles, with the coverage of the
# fortifiable vehicle (P159, P210). Sourced by results.qmd after
# _results.R, whose helpers it uses; do not edit.

# ---- Section 1. Coverage and quantity --------------------------------
coverage_exhibit <- function(e, col, value = "acquired", ...) {
  p <- shown_pair(e, stats::setNames(col, col), NULL, value, ...)
  list(table = p$table,
       figure = fig_interval(p$data, value, col,
                             xlab = term(value, "header"),
                             ylab = term(col, "header"),
                             percent = value == "acquired"))
}

# With a `fortifiable` column in use, the coverage of the fortifiable
# vehicle (Aaron et al. 2017) beside that of the vehicle in any form, as a
# column and a hollow point, and the fortifiable share of the grams (P210).
coverage_vehicle <- function(instance) {
  x <- use[use$level == "vehicle", ]
  e <- est(x, "acquired")
  if (!fortifiable_used()) {
    return(coverage_exhibit(e, "vehicle"))
  }
  f <- est(x, "acquired_fortifiable")
  e$acquired_fortifiable <- shown_value(f)[match(e$vehicle, f$vehicle)]
  out <- coverage_exhibit(e, "vehicle", extra = "acquired_fortifiable")
  out$table <- move_last(out$table, "acquired_fortifiable")
  out$figure <- out$figure +
    geom_point(aes(x = .data$acquired_fortifiable), shape = 1, size = 2.5,
               na.rm = TRUE)
  out$note <- c(term("fortifiable_coverage", "note"), fortifiable_note())
  out
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

# ---- The fortifiable vehicle (P159, P210) ----------------------------
# TRUE when the acquisitions say which records are fortifiable and the
# choice of _inputs.R uses it.
fortifiable_used <- function() {
  !is.null(grams[["fortifiable"]]) && identical(fortifiable_choice, "use")
}

# The note with the fortifiable share of the grams of each vehicle, in the
# order of the labels, weighted by the survey weights times the AFE, over
# the households with an estimated use; only these grams get the
# fortificant in the scenarios.
fortifiable_note <- function() {
  vu <- use[use$level == "vehicle" & use$use_status == "estimated", ]
  w <- households$weight[match(vu$household_id, households$household_id)] *
    vu$afe
  v <- unique(vu$vehicle)
  v <- v[order(lab(v, "vehicle"))]
  total <- vapply(v, function(x) {
    sum((w * vu$qty_vehicle_g_d)[vu$vehicle == x])
  }, numeric(1))
  fort <- vapply(v, function(x) {
    sum((w * vu$qty_fortifiable_g_d)[vu$vehicle == x])
  }, numeric(1))
  v <- v[total > 0]
  shares <- paste0(lab(v, "vehicle"), " ", pct(fort[v] / total[v]), "%")
  fill(term("fortifiable_share", "note"), shares = collapse(shares))
}
