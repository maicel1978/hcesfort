#' Which sections of the results report the data can support
#'
#' The verdict of the data readiness report (DR8), read also by the
#' results report: for each section and each domain, whether it is enabled
#' and, if not, why. A section is computed only when it is enabled;
#' otherwise the report prints one sentence.
#'
#' | Section | Needs | Gated by |
#' |---|---|---|
#' | `coverage`, `quantity` | `vehicles` | none |
#' | `risk` | none | the checks below |
#' | `scenarios` | `vehicles`, `scenarios` | the checks below |
#' | `food_groups` | `food_groups` | the checks below |
#'
#' A gated section is disabled when `records_used`, `linked_grams` or
#' `linked_expenditure` is not met, or when no nutrient meets
#' `composition_value` ([readiness_checks()]); a check whose `met` is
#' missing does not disable. A nutrient that fails `min_coverage` while
#' others meet it leaves the sections enabled: the report leaves that
#' nutrient out and names it. An essential input absent from the inventory
#' disables every section. A domain row is disabled when its column is
#' absent from `households` or its national row is disabled, and also when
#' its check `domain_cells` is not met (DR11: too many of its values have
#' fewer than `min_n` households with an estimated intake; reason
#' `"threshold_not_met"`, detail `"domain_cells"`). Only that domain is
#' disabled.
#'
#' @param inventory Table returned by [readiness_inventory()].
#' @param checks Table returned by [readiness_checks()]; may be `NULL` when
#'   an essential input is absent (the checks cannot be computed).
#' @param domains `NULL` or the names of the domain columns; each adds one
#'   row per section.
#' @returns A tibble with one row per section and domain (national first):
#'   `section`, `domain` (`NA` = national), `enabled`, `reason` (`NA`,
#'   `"missing_input"` or `"threshold_not_met"`) and `detail` (the absent
#'   inputs or the checks not met, separated by `", "`).
#' @seealso [readiness_inventory()], [readiness_checks()].
#' @examples
#' e <- hces_example
#' nutrients <- nutrient_registry(e$nutrients)
#' grams <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
#' content <- link_composition(grams, e$crosswalk, e$composition, nutrients)
#' afe <- adult_equivalents(
#'   e$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' intake <- apparent_intake(content, afe, e$households)
#' checks <- readiness_checks(intake, linkage_ladder(content, e$households),
#'                            "iron", min_records_used = 0.95,
#'                            min_coverage = 0.9, min_linked_share = 0.9,
#'                            households = e$households, domains = "region",
#'                            min_n = 30, max_small_cells = 0.5)
#' inventory <- readiness_inventory(e[names(e) != "nutrients"], "region")
#' readiness_verdict(inventory, checks, domains = "region")
#' @export
readiness_verdict <- function(inventory, checks, domains = NULL) {
  check_required()
  check_verdict_args(inventory, checks, domains)
  absent <- inventory[!inventory$present & inventory$role == "essential", ]
  absent <- ifelse(is.na(absent$variable), absent$table, absent$variable)
  if (length(absent) == 0 && is.null(checks)) {
    abort_hcesfort("argument", c(
      "{.arg checks} is needed: no essential input is absent."
    ), arg = "checks")
  }
  failed <- failed_gates(checks)
  sections <- readiness_sections()
  national <- dplyr::bind_rows(lapply(names(sections), function(s) {
    verdict_row(s, NA_character_, absent, sections[[s]], inventory, failed)
  }))
  rows <- lapply(domains, function(d) {
    here <- inventory$present[inventory$table == "households" &
                                inventory$variable %in% d]
    out <- national
    out$domain <- d
    if (!isTRUE(any(here))) {
      off <- out$enabled | out$reason %in% "threshold_not_met"
      out$enabled <- FALSE
      out$reason[off] <- "missing_input"
      out$detail[off] <- d
    } else if (small_cells(checks, d)) {
      out <- disable_small_cells(out)
    }
    out
  })
  dplyr::bind_rows(c(list(national), rows))
}

# One national row of the verdict.
verdict_row <- function(section, domain, absent, spec, inventory, failed) {
  tabs <- inventory[is.na(inventory$variable), ]
  missing <- c(absent, spec$needs[!spec$needs %in% tabs$table[tabs$present]])
  reason <- NA_character_
  detail <- NA_character_
  if (length(missing) > 0) {
    reason <- "missing_input"
    detail <- paste(missing, collapse = ", ")
  } else if (spec$gated && length(failed) > 0) {
    reason <- "threshold_not_met"
    detail <- paste(failed, collapse = ", ")
  }
  dplyr::tibble(section = section, domain = domain, enabled = is.na(reason),
                reason = reason, detail = detail)
}

# Whether the check `domain_cells` of domain `d` is not met.
small_cells <- function(checks, d) {
  !is.null(checks) &&
    any(checks$met[checks$check == "domain_cells" &
                     checks$detail %in% d] %in% FALSE)
}

# Verdict rows of a domain with too many small cells: enabled rows are
# disabled for `threshold_not_met`; rows already disabled for a threshold
# add `domain_cells` to their detail.
disable_small_cells <- function(out) {
  on <- out$enabled
  gated <- out$reason %in% "threshold_not_met"
  out$detail[gated] <- paste(out$detail[gated], "domain_cells", sep = ", ")
  out$reason[on] <- "threshold_not_met"
  out$detail[on] <- "domain_cells"
  out$enabled <- FALSE
  out
}

# The gating checks not met; `composition_value` when no nutrient meets it.
failed_gates <- function(checks) {
  if (is.null(checks)) {
    return(character(0))
  }
  gate <- checks[checks$check %in% readiness_gates & checks$met %in% FALSE, ]
  cov <- checks$met[checks$check == "composition_value"]
  c(unique(gate$check),
    if (length(cov) > 0 && all(cov %in% FALSE)) "composition_value")
}

# Abort unless the inventory and the checks have the columns of their
# functions and `domains` is NULL or text.
check_verdict_args <- function(inventory, checks, domains,
                               call = rlang::caller_env()) {
  need <- list(
    inventory = c("table", "variable", "role", "present"),
    checks = c("check", "detail", "met")
  )
  for (arg in names(need)) {
    x <- if (arg == "inventory") inventory else checks
    if (arg == "checks" && is.null(x)) next
    if (!is.data.frame(x) || !all(need[[arg]] %in% names(x))) {
      abort_hcesfort("schema", c(
        "{.arg {arg}} must be the table returned by
        {.fn {paste0('readiness_', arg)}}."
      ), table = arg, columns = need[[arg]], call = call)
    }
  }
  if (!is.null(domains) && (!is.character(domains) || anyNA(domains))) {
    abort_hcesfort("argument", c(
      "{.arg domains} must be NULL or the names of household columns."
    ), arg = "domains", call = call)
  }
  invisible(TRUE)
}
