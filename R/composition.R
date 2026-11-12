#' Link records to a food composition table
#'
#' Give each acquisition record its nutrient content, through the crosswalk
#' (survey food to composition food) and the composition table. Every
#' record is kept: a record that cannot be linked has missing nutrients and
#' a `composition_status` that says why, so coverage is measured over all
#' records, by records and by grams, before anything is dropped.
#'
#' Only validated crosswalk rows enter the calculation. Edible grams per
#' day are `qty_g_d * edible_portion * yield_factor`; a missing or absent
#' `yield_factor` means no change of state between purchase and the
#' composition row, and counts as 1; the linked records concerned are
#' counted in the audit log (`yield_factor_assumed_one`). Nutrients per
#' record are edible grams per day times the content per 100 g, divided by
#' 100, in the unit of the registry (the columns keep the registry's
#' names: `iron_mg` is mg per day for the household). A missing
#' composition value leaves that nutrient missing for the record, never
#' zero; fill gaps first with [fill_composition()].
#'
#' @param grams Table returned by [convert_units()] (or [flag_outliers()]).
#' @param crosswalk Crosswalk ([hces_schema()]`("crosswalk")`), validated or
#'   not.
#' @param composition Composition table, validated by
#'   [validate_composition()] or not.
#' @param nutrients Registry built by [nutrient_registry()]; needed when
#'   `composition` is not validated, otherwise taken from it.
#' @returns `grams` as a tibble of class `hces_nutrient_content` (and
#'   `hces_tbl`), one row per record, with the columns added:
#'   `composition_id`, `edible_portion`, `yield_factor` (as used),
#'   `qty_edible_g_d`, `fortified` (when the composition has it), one
#'   column per nutrient, `match_status` (the food's crosswalk:
#'   `"matched"`, `not_in_crosswalk`, `unmatched_food`, `not_validated` or
#'   `missing_edible_portion`) and `composition_status`: `"linked"` or the
#'   first reason the record has no nutrients, `no_grams` or the
#'   `match_status`. The audit log continues the logs of `grams`,
#'   `crosswalk` and `composition`. It counts each reason with the grams
#'   per day as acquired (`qty_g` of the log); records with no grams and no
#'   validated match also as `no_grams_and_no_match`; linked records;
#'   linked records whose yield factor was taken as 1; and,
#'   per nutrient, linked records without a value
#'   (`missing_nutrient_value`, `detail` = the column).
#' @seealso [fill_composition()], [unmatched_foods()], [audit_log()].
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition,
#'   nutrients = nutrient_registry(hces_example$nutrients)
#' )
#' table(content$composition_status)
#' audit_log(content)
#' @export
link_composition <- function(grams, crosswalk, composition,
                             nutrients = NULL) {
  check_required()
  require_hces(grams, "hces_grams")
  g <- audit_check_rows(grams, "link_composition")
  nutrients <- composition_registry(composition, nutrients)
  cw <- validate_crosswalk(crosswalk)
  comp <- validate_composition(composition, nutrients)
  check_composition_ids(g, cw, comp)
  out <- dplyr::as_tibble(g)
  linked <- join_composition(out, cw, comp, nutrients)
  reasons <- link_reasons(out, linked)
  status <- first_reason(reasons, none = "linked")
  edible <- out$qty_g_d * linked$edible_portion * linked$yield_factor
  edible[status != "linked"] <- NA_real_
  out$composition_id <- linked$match_id
  out$edible_portion <- linked$edible_portion
  out$yield_factor <- linked$yield_factor
  out$qty_edible_g_d <- edible
  if (!is.null(comp[["fortified"]])) out$fortified <- linked$fortified
  for (col in nutrients$column) {
    out[[col]] <- edible * linked[[col]] / 100
  }
  out$match_status <- first_reason(reasons[-1], none = "matched")
  out$composition_status <- status
  log <- link_log(out, reasons, nutrients, linked$yield_assumed)
  log <- dplyr::bind_rows(audit_combine(g, cw, comp), log)
  new_hces_tbl(out, "hces_nutrient_content", log, "record_id", nutrients)
}

# The registry to use: the one stored on a validated composition table,
# or `nutrients`; abort when neither is there or both disagree.
composition_registry <- function(composition, nutrients,
                                 call = rlang::caller_env()) {
  stored <- attr(composition, "nutrients", exact = TRUE)
  if (is.null(nutrients) && is.null(stored)) {
    abort_hcesfort("argument", c(
      "{.arg nutrients} is needed: {.arg composition} is not validated.",
      "i" = "Pass a registry built by {.fn nutrient_registry}."
    ), arg = "nutrients", call = call)
  }
  if (is.null(nutrients)) {
    return(stored)
  }
  require_registry(nutrients, call = call)
  if (!is.null(stored) && !identical(stored$column, nutrients$column)) {
    abort_hcesfort("argument", c(
      "{.arg nutrients} differs from the registry of {.arg composition}.",
      "i" = "Leave {.arg nutrients} out to use the stored one."
    ), arg = "nutrients", call = call)
  }
  nutrients
}

# Crosswalk and composition columns for each record, in order: the
# crosswalk row of its food (at most one) and, for validated rows, the
# composition row of its match (at most one).
join_composition <- function(out, cw, comp, nutrients) {
  keys <- dplyr::tibble(food_code = out$food_code)
  cw <- dplyr::as_tibble(cw)
  if (is.null(cw[["yield_factor"]])) cw$yield_factor <- NA_real_
  cw$in_crosswalk <- TRUE
  cw_cols <- c("food_code", "composition_id", "validated", "edible_portion",
               "yield_factor", "in_crosswalk")
  x <- dplyr::left_join(keys, cw[cw_cols], by = "food_code",
                        relationship = "many-to-one", unmatched = "drop",
                        na_matches = "never")
  x$in_crosswalk <- !is.na(x$in_crosswalk)
  x$yield_assumed <- is.na(x$yield_factor)
  x$yield_factor[x$yield_assumed] <- 1
  use <- !is.na(x$validated) & x$validated
  x$match_id <- x$composition_id
  x$match_id[!use] <- x$composition_id[NA_integer_]
  comp_cols <- c("composition_id", nutrients$column,
                 if (!is.null(comp[["fortified"]])) "fortified")
  comp <- dplyr::as_tibble(comp)[comp_cols]
  names(comp)[1] <- "match_id"
  dplyr::left_join(x, comp, by = "match_id", relationship = "many-to-one",
                   unmatched = "drop", na_matches = "never")
}

# A named list of logical vectors, one per reason a record has no
# nutrients.
link_reasons <- function(out, linked) {
  validated <- !is.na(linked$validated) & linked$validated
  list(
    no_grams = is.na(out$qty_g_d),
    not_in_crosswalk = !linked$in_crosswalk,
    unmatched_food = linked$in_crosswalk & !validated &
      is.na(linked$composition_id),
    not_validated = linked$in_crosswalk & !validated &
      !is.na(linked$composition_id),
    missing_edible_portion = validated & is.na(linked$edible_portion)
  )
}
