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
  need <- c("place", "survey", "vehicles", "review", "nutrients", "energy",
            "domains", "equity_domains", "comparator", "max_small_cells",
            "min_coverage", "min_records_used", "min_linked_share",
            "iron_bioavailability",
            "iron_bioavailability_sensitivity", "energy_lower",
            "energy_upper", "lonely_psu")
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
  if (!identical(choices$review, "show") &&
        !identical(choices$review, "suppress")) {
    template_abort('`choices$review` must be "show" or "suppress".')
  }
  invisible(TRUE)
}

# The thresholds of the presentation standard by criterion; `criterion`
# and `value` are required.
standard_thresholds <- function(standard) {
  if (!all(c("criterion", "value") %in% names(standard))) {
    template_abort(paste(
      "`presentation_standard` of _inputs.R needs the columns `criterion`",
      "and `value`, as `hcesfort::ref_presentation_standard`."
    ))
  }
  stats::setNames(standard$value, standard$criterion)
}

# The vehicles of `choices$vehicles` (NULL: all). A scenario that fortifies
# a vehicle left out stops the render.
keep_vehicles <- function(vehicles, scenarios, keep) {
  if (is.null(keep) || is.null(vehicles)) {
    return(vehicles)
  }
  out <- setdiff(unique(scenarios$vehicle), keep)
  if (length(out) > 0) {
    bad <- unique(scenarios$scenario[scenarios$vehicle %in% out])
    template_abort(paste0(
      "`choices$vehicles` leaves out vehicles fortified by the scenarios ",
      paste(bad, collapse = ", "), " (", paste(out, collapse = ", "),
      "). Add them to `choices$vehicles` or remove those scenarios."
    ))
  }
  vehicles[vehicles$vehicle %in% keep, , drop = FALSE]
}

# An enrichment table with no rows: no enriched food is declared.
no_enrichment <- function() {
  data.frame(composition_id = character(0), nutrient = character(0),
             source = character(0))
}

check_choices(choices)
standard <- standard_thresholds(presentation_standard)
level <- standard[["conf_level"]]
vehicles <- keep_vehicles(vehicles, scenarios, choices$vehicles)
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
    min_linked_share = choices$min_linked_share,
    households = households, domains = choices$domains,
    min_n = standard[["min_n"]], max_small_cells = choices$max_small_cells
  )
}
verdict <- readiness_verdict(inventory, checks, choices$domains)
terms <- read_labels("terms.csv")
