#' Convert acquired quantities to grams
#'
#' Convert the quantity of each acquisition record to grams, using a typed
#' table of unit factors, and to grams per day for the household. Every
#' record is kept: a record that cannot be converted has `qty_g` missing
#' and a `grams_status` that says why, so later steps measure coverage
#' over all records.
#'
#' Each factor says what it measures (`factor_type`), so no factor is
#' read as grams unless it is grams:
#'
#' * `mass_g`: grams per unit.
#' * `volume_ml`: millilitres per unit, times the density of the row
#'   (`density_g_ml`). A row without density converts nothing unless the
#'   caller gives `density_g_ml`, which is then used for every such row
#'   and counted in the log (`density_assumed`).
#' * `count`: pieces per unit (a dozen is 12), times the weight of one
#'   piece (`piece_weight_g`). Without it, as for density.
#'
#' A factor with `food_code` missing is generic: it holds for every food in
#' that unit. When a record has both a factor for its food and a generic
#' one, `priority` decides which is used, and the log counts those records
#' (`food_and_generic_factor`). The original ENGIH 2018 analysis used the
#' generic factor first (`priority = "generic"`).
#'
#' Grams per day are `qty_g * household_share / period_days`; without the
#' column `household_share` the share is 1. The edible portion is not
#' applied here: it belongs to the crosswalk and is applied by the
#' composition step.
#'
#' @param acquisitions Acquisitions table ([hces_schema()]`("acquisitions")`),
#'   validated or not.
#' @param unit_factors Unit factors ([hces_schema()]`("unit_factors")`),
#'   validated or not.
#' @param priority Required, no default: `"food"` uses the factor of the
#'   food before the generic one, `"generic"` the generic one first.
#' @param density_g_ml `NULL` (default) or one positive number: density
#'   used for `volume_ml` rows without their own.
#' @param piece_weight_g `NULL` (default) or one positive number: weight of
#'   one piece used for `count` rows without their own.
#' @returns `acquisitions` as a tibble of class `hces_grams` (and
#'   `hces_tbl`), one row per record, with the columns added:
#'   `factor_from` (`"food"`, `"generic"` or `NA`), `factor_type`,
#'   `g_per_unit`, `qty_g` (grams as acquired), `qty_g_d` (grams per day
#'   for the household) and `grams_status`: `"converted"` or the first
#'   reason that left the record without grams, in this order:
#'   `missing_quantity`, `missing_unit`, `no_factor`, `no_density`,
#'   `no_piece_weight`, `missing_household_share`. The audit log continues
#'   the log of `acquisitions` and counts every reason (a record is counted
#'   under each reason that applies), the records filled with the density or
#'   piece weight given by the caller, and the records converted with their
#'   grams per day (`qty_g` of the log is grams per day in this step).
#' @seealso [validate_unit_factors()], [audit_log()].
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' table(grams$grams_status)
#' audit_log(grams)
#' @export
convert_units <- function(acquisitions, unit_factors, priority,
                          density_g_ml = NULL, piece_weight_g = NULL) {
  priority <- check_priority(priority)
  check_optional_positive(density_g_ml)
  check_optional_positive(piece_weight_g)
  a <- validate_acquisitions(acquisitions)
  a <- audit_check_rows(a, "convert_units")
  f <- validate_unit_factors(unit_factors)
  check_factor_ids(a, f)
  chosen <- choose_factor(a, f, priority)
  g <- grams_per_unit(chosen, density_g_ml, piece_weight_g)
  share <- if (is.null(a[["household_share"]])) 1 else a[["household_share"]]
  qty_g <- a$quantity * g
  reasons <- grams_reasons(a, chosen, g, rep_len(share, nrow(a)))
  status <- first_reason(reasons)
  converted <- status == "converted"
  out <- dplyr::as_tibble(a)
  out$factor_from <- chosen$factor_from
  out$factor_type <- chosen$factor_type
  out$g_per_unit <- g
  out$qty_g <- ifelse(converted, qty_g, NA_real_)
  out$qty_g_d <- ifelse(converted, qty_g * share / a$period_days, NA_real_)
  out$grams_status <- status
  log <- units_log(out, reasons, chosen, g, priority)
  new_hces_tbl(out, "hces_grams", dplyr::bind_rows(audit_get(a), log),
               "record_id")
}

# The factor of each record, one row per record in the order of `a`:
# the food-specific and the generic factor are looked up by checked joins
# and one is chosen by `priority`.
choose_factor <- function(a, f, priority) {
  keys <- dplyr::tibble(.row = seq_len(nrow(a)), food_code = a$food_code,
                        unit = a$unit)
  cols <- c("factor", "factor_type", "density_g_ml", "piece_weight_g")
  f <- add_optional_factor_cols(f, a)
  food <- lookup_factor(keys, f[!is.na(f$food_code), ], c("food_code", "unit"),
                        cols)
  generic <- lookup_factor(keys, f[is.na(f$food_code), ], "unit", cols)
  has_food <- !is.na(food$factor)
  has_generic <- !is.na(generic$factor)
  use_food <- has_food & (priority == "food" | !has_generic)
  out <- generic
  out[use_food, ] <- food[use_food, ]
  out$factor_from <- ifelse(use_food, "food",
                            ifelse(has_generic, "generic", NA_character_))
  out$both <- has_food & has_generic
  out
}

# Columns `cols` of `f` for each row of `keys`, joined by `by`: at most one
# factor per record (the key of `f` is unique), records without a factor
# get NA, and a missing key never matches.
lookup_factor <- function(keys, f, by, cols) {
  f <- f[c(by, cols)]
  out <- dplyr::left_join(
    keys, f, by = by, relationship = "many-to-one", unmatched = "drop",
    na_matches = "never"
  )
  if (nrow(out) != nrow(keys) || !identical(out$.row, keys$.row)) {
    rlang::abort("Internal error: factor lookup changed the records.",
                 .internal = TRUE)
  }
  out[cols]
}

# `f` with the optional columns it lacks added as missing values: a
# generic `food_code` of the type of the acquisitions, no density and no
# piece weight.
add_optional_factor_cols <- function(f, a) {
  if (is.null(f[["food_code"]])) {
    f$food_code <- rep(a$food_code[NA_integer_], nrow(f))
  }
  for (col in c("density_g_ml", "piece_weight_g")) {
    if (is.null(f[[col]])) f[[col]] <- rep(NA_real_, nrow(f))
  }
  f
}

# Grams per unit: the factor for mass, times the density for volume and
# times the piece weight for counts; the caller's value fills a missing
# density or piece weight when given.
grams_per_unit <- function(chosen, density_g_ml, piece_weight_g) {
  density <- chosen$density_g_ml
  piece <- chosen$piece_weight_g
  if (!is.null(density_g_ml)) density[is.na(density)] <- density_g_ml
  if (!is.null(piece_weight_g)) piece[is.na(piece)] <- piece_weight_g
  type <- chosen$factor_type
  multiplier <- ifelse(type == "volume_ml", density,
                       ifelse(type == "count", piece, 1))
  chosen$factor * multiplier
}

# The status of each record: "converted" or the first reason, in the
# order of `reasons`, that left it without grams.
first_reason <- function(reasons) {
  status <- rep("converted", length(reasons[[1]]))
  for (cause in rev(names(reasons))) status[reasons[[cause]]] <- cause
  status
}

# A named list of logical vectors, one per reason a record has no grams.
grams_reasons <- function(a, chosen, g, share) {
  has_factor <- !is.na(chosen$factor)
  type <- chosen$factor_type
  list(
    missing_quantity = is.na(a$quantity),
    missing_unit = is.na(a$unit),
    no_factor = !is.na(a$unit) & !has_factor,
    no_density = has_factor & type == "volume_ml" & is.na(g),
    no_piece_weight = has_factor & type == "count" & is.na(g),
    missing_household_share = is.na(share)
  )
}
