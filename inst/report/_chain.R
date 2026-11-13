# The chain up to the analysis table, shared by both reports. Sourced
# after _inputs.R; do not edit. It tolerates absent optional tables and
# computes the variable inventory, the linkage ladder, the quality checks
# and the readiness verdict, so that both reports read the same verdict.

# Abort with the class of hcesfort's argument errors.
template_abort <- function(message) {
  rlang::abort(message, class = c("hcesfort_error_argument",
                                  "hcesfort_error"))
}

# Every choice is named in `choices`; none has a default.
check_choices <- function(choices) {
  need <- c("nutrients", "energy", "domains", "equity_domains",
            "comparator", "min_n", "max_half_width", "min_coverage",
            "min_records_used", "min_linked_share", "iron_bioavailability",
            "iron_bioavailability_sensitivity", "energy_lower",
            "energy_upper", "level", "lonely_psu")
  absent <- setdiff(need, names(choices))
  if (length(absent) > 0) {
    template_abort(paste0(
      "`choices` of _inputs.R lacks: ", paste(absent, collapse = ", "),
      ". Write each one; an empty choice is `name = NULL` inside list()."
    ))
  }
  if (!all(choices$equity_domains %in% choices$domains)) {
    template_abort("`choices$equity_domains` must be among `choices$domains`.")
  }
  invisible(TRUE)
}

# An enrichment table with no rows: no enriched food is declared.
no_enrichment <- function() {
  data.frame(composition_id = character(0), nutrient = character(0),
             source = character(0))
}

check_choices(choices)
inputs <- list(
  households = households, members = members, acquisitions = acquisitions,
  unit_factors = unit_factors, crosswalk = crosswalk,
  composition = composition, enrichment = enrichment, vehicles = vehicles,
  scenarios = scenarios, food_groups = food_groups
)
inventory <- readiness_inventory(inputs, choices$domains)
ready <- all(inventory$present[inventory$role == "essential"])
domain_rows <- inventory$table == "households" &
  inventory$variable %in% choices$domains
domains <- intersect(choices$domains,
                     inventory$variable[domain_rows & inventory$present])
has_expenditure <- any(inventory$present[
  inventory$variable %in% "expenditure_lcu"
])

checks <- NULL
if (ready) {
  if (is.null(enrichment)) enrichment <- no_enrichment()
  design <- as_hces_design(households, lonely_psu = choices$lonely_psu)
  afe <- make_afe(members)
  grams <- make_grams(acquisitions, unit_factors)
  base <- unfortified_baseline(composition, enrichment, nutrients)
  content <- link_composition(grams, crosswalk, base, nutrients)
  intake <- apparent_intake(content, afe, households)
  ladder <- linkage_ladder(content, households)
  checks <- readiness_checks(
    intake, ladder, choices$nutrients,
    min_records_used = choices$min_records_used,
    min_coverage = choices$min_coverage,
    min_linked_share = choices$min_linked_share
  )
}
verdict <- readiness_verdict(inventory, checks, choices$domains)
terms <- read_labels("terms.csv")
