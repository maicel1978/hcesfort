# The map of the results report: what each section needs and which checks
# gate it. One constant, used by readiness_inventory() (`needed_by`) and
# readiness_verdict(). Design: docs/design-reports-v2.md, section 5.5.

# Sections of the results report, in order, with the optional tables each
# needs and whether the quality checks gate it.
readiness_sections <- function() {
  list(
    coverage = list(needs = "vehicles", gated = FALSE),
    quantity = list(needs = "vehicles", gated = FALSE),
    risk = list(needs = character(0), gated = TRUE),
    scenarios = list(needs = c("vehicles", "scenarios"), gated = TRUE),
    food_groups = list(needs = "food_groups", gated = TRUE)
  )
}

# User-supplied tables: essential ones disable every section when absent.
readiness_tables <- function() {
  c(unit_factors = "essential", crosswalk = "essential",
    composition = "essential", enrichment = "optional",
    vehicles = "optional", scenarios = "optional", food_groups = "optional")
}

# Checks that gate the gated sections; `composition_value` gates them when
# no nutrient meets it.
readiness_gates <- c("records_used", "linked_grams", "linked_expenditure")

# The sections that depend on an optional input, separated by ", ", or
# "none".
needed_by <- function(input) {
  s <- readiness_sections()
  hit <- names(s)[vapply(s, function(x) input %in% x$needs, logical(1))]
  if (length(hit) == 0) "none" else paste(hit, collapse = ", ")
}
