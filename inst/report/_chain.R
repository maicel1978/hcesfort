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
            "energy_upper", "energy_action", "lonely_psu")
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
  if (!identical(choices$energy_action, "keep") &&
        !identical(choices$energy_action, "exclude")) {
    template_abort('`choices$energy_action` must be "keep" or "exclude".')
  }
  if (identical(choices$energy_action, "exclude") && is.null(choices$energy)) {
    template_abort(paste(
      '`choices$energy_action = "exclude"` needs `choices$energy`:',
      "without energy no household can be judged implausible."
    ))
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

# The registry column of `choices$energy`, which must be in kcal: it is
# compared with the energy of the reference person.
energy_registry_column <- function(nutrients, energy) {
  if (is.null(energy)) {
    return(NULL)
  }
  if (!identical(nutrients$unit[nutrients$nutrient == energy], "kcal")) {
    template_abort(paste(
      "`choices$energy` must name a nutrient of the registry in kcal:",
      "it is compared with the energy of the reference person."
    ))
  }
  nutrients$column[nutrients$nutrient == energy]
}

# The rows of a household table of the results without the households of
# `excluded` (choice `energy_action`), with the exclusion in its audit log.
# Those households stay in the design, outside every domain of estimation.
drop_excluded <- function(x) {
  out <- x$household_id %in% excluded
  if (!any(out)) {
    return(x)
  }
  kept <- restore_audit(x[!out, , drop = FALSE], x)
  audit_record(kept, "template::energy_action", "excluded",
               "energy_outside_plausible_range", n_records = sum(out),
               n_households = length(unique(x$household_id[out])),
               detail = energy_range)
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
absent <- inventory[inventory$role == "essential" & !inventory$present, ]
absent <- ifelse(is.na(absent$variable), absent$table,
                 paste0(absent$table, "$", absent$variable))
domain_rows <- inventory$table == "households" &
  inventory$variable %in% choices$domains
domains <- intersect(choices$domains,
                     inventory$variable[domain_rows & inventory$present])
has_expenditure <- any(inventory$present[
  inventory$variable %in% "expenditure_lcu"
])

checks <- NULL
energy_column <- NULL
flagged <- NULL
excluded <- character(0)
energy_range <- paste(choices$energy_lower, "to", choices$energy_upper, "kcal")
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
  energy_column <- energy_registry_column(nutrients, choices$energy)
  if (!is.null(energy_column)) {
    flagged <- flag_energy_plausibility(intake, energy_column,
                                        choices$energy_lower,
                                        choices$energy_upper)
    flagged$energy_outside <- !flagged$energy_plausible
    if (choices$energy_action == "exclude") {
      excluded <- flagged$household_id[flagged$energy_outside %in% TRUE]
    }
  }
}
verdict <- readiness_verdict(inventory, checks, choices$domains)
terms <- read_labels("terms.csv")
