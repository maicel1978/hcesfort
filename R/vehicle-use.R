#' Use of fortification vehicles per household
#'
#' For each household and each vehicle, whether the household acquired the
#' vehicle and how many grams of it per adult female equivalent (AFE) per
#' day. The result has one row per household of `households` and per
#' vehicle, so coverage, mean use and the reach of several vehicles can be
#' estimated with the survey design (task 11); the function itself
#' estimates nothing. The same table feeds `apply_scenario()`, so the
#' vehicle is defined once for coverage and scenarios (E12).
#'
#' Grams are on the purchased basis: `qty_g_d * vehicle_fraction`, without
#' edible portion or yield factor, because `vehicle_fraction` is a fraction
#' of the food as purchased. Every included record with grams counts,
#' linked to the composition table or not (a bread without a composition
#' match still carries flour). A record enters when `include` is `TRUE`
#' and, with `outliers = "exclude"`, it is not flagged (a record not
#' assessed, `NA`, is kept).
#'
#' Rows are given at three levels: `"vehicle"` (each vehicle of
#' `vehicles`), `"group"` (each `vehicle_group`: the sum of its vehicles,
#' since a food has at most one vehicle of a group) and `"combined"` (each
#' element of `combine`, a set of vehicles or groups: acquired when at least
#' one of them was acquired; grams are missing, as they would mix
#' substances).
#'
#' `use_status`, in this order: `food_module_nonresponse`,
#' `no_food_records` (no record in `grams`), `no_afe` (missing or zero
#' AFE), `estimated`. For the first two `acquired` is missing: an absent
#' record is not evidence of non-consumption, and the households stay in
#' the frame with the same denominator as risk (E5). The original analysis
#' counted them as non-consumers; an adapter that wants that sets the
#' missing values to `FALSE` explicitly. A household whose records of a
#' vehicle all lack grams has `acquired = TRUE` and a quantity that
#' understates its use; it is counted (`acquired_without_grams`).
#'
#' @param grams Table returned by [convert_units()], [flag_outliers()] or
#'   [link_composition()].
#' @param vehicles Vehicles table ([hces_schema()]`("vehicles")`),
#'   validated or not.
#' @inheritParams apparent_intake
#' @param outliers Required when `grams` has the column `outlier`:
#'   `"exclude"` or `"keep"`. Must be `NULL` otherwise.
#' @param combine `NULL`, or a named list of character vectors, each a set
#'   of vehicle or group names, for example
#'   `list(any_staple = c("wheat_flour", "sugar"))`.
#' @returns A tibble of class `hces_vehicle_use` (and `hces_tbl`), key
#'   `household_id` + `level` + `vehicle`, in the order of `households`:
#'   `household_id`, `use_status`, `level`, `vehicle`, `acquired`,
#'   `n_records` (included records of the vehicle's foods),
#'   `n_records_no_grams` and `qty_vehicle_g_d` (grams of vehicle per AFE
#'   per day; missing unless `use_status` is `estimated`, and for
#'   `combined` rows). The audit log continues the logs of `grams`,
#'   `vehicles`, `afe` and `households`.
#' @seealso `apply_scenario()`, [apparent_intake()].
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households,
#'                         combine = list(any = c("wheat_flour", "sugar")))
#' table(use$vehicle, use$acquired, useNA = "ifany")
#' @export
vehicle_coverage <- function(grams, vehicles, afe, households,
                             outliers = NULL, combine = NULL) {
  require_hces(grams, c("hces_grams", "hces_nutrient_content"))
  require_hces(afe, "hces_afe")
  x <- audit_check_rows(grams, "vehicle_coverage")
  v <- validate_vehicles(vehicles)
  h <- validate_households(households)
  outliers <- check_outlier_decision(outliers, x, arg = "grams")
  check_intake_ids(x, afe, h, arg = "grams")
  check_vehicle_food_type(x, v)
  items <- vehicle_items(v, combine)
  reasons <- excluded_reasons_use(x, outliers)
  used <- !Reduce(`|`, reasons)
  afe_h <- afe$afe[match(h$household_id, afe$household_id)]
  status <- first_reason(list(
    food_module_nonresponse = h[["food_module_response"]] %in% FALSE,
    no_food_records = !h$household_id %in% x$household_id,
    no_afe = is.na(afe_h) | afe_h <= 0
  ), none = "estimated")
  out <- use_rows(x[used, ], items, h$household_id, status, afe_h)
  log <- vehicle_log(x, reasons, used, v, items, out, status)
  log <- dplyr::bind_rows(audit_get(x), audit_get(v), audit_get(afe),
                          audit_get(h), log)
  new_hces_tbl(out, "hces_vehicle_use", log,
               c("household_id", "level", "vehicle"))
}

# Reasons a record of `grams` is left out of vehicle use.
excluded_reasons_use <- function(x, outliers) {
  flagged <- if (identical(outliers, "exclude")) {
    x$outlier %in% TRUE
  } else {
    rep(FALSE, nrow(x))
  }
  list(not_included = !x$include, outlier_excluded = flagged)
}

# The foods of each row level: one row per item (level, vehicle) and food,
# with the fraction of the food that is the vehicle (missing for combined
# items).
vehicle_items <- function(v, combine) {
  v <- dplyr::as_tibble(v)
  base <- dplyr::tibble(level = "vehicle", vehicle = v$vehicle,
                        food_code = v$food_code, fraction = v$vehicle_fraction)
  group <- v[["vehicle_group"]]
  if (is.null(group)) group <- rep(NA_character_, nrow(v))
  g <- !is.na(group)
  groups <- dplyr::tibble(level = "group", vehicle = group[g],
                          food_code = v$food_code[g],
                          fraction = v$vehicle_fraction[g])
  items <- dplyr::bind_rows(base, groups)
  combine <- check_combine(combine, unique(items$vehicle))
  combined <- lapply(names(combine), function(name) {
    foods <- unique(items$food_code[items$vehicle %in% combine[[name]]])
    dplyr::tibble(level = "combined", vehicle = name, food_code = foods,
                  fraction = NA_real_)
  })
  dplyr::bind_rows(items, combined)
}

# One row per household of `ids` and item (household-major order):
# records, records without grams, acquired and grams per AFE per day.
use_rows <- function(x, items, ids, status, afe_h) {
  keys <- unique(items[c("level", "vehicle")])
  nk <- nrow(keys)
  items$item <- match(paste(items$level, items$vehicle, sep = "\r"),
                      paste(keys$level, keys$vehicle, sep = "\r"))
  rec <- dplyr::tibble(household_id = x$household_id,
                       food_code = x$food_code, qty_g_d = x$qty_g_d)
  joined <- dplyr::inner_join(rec, items, by = "food_code",
                              relationship = "many-to-many",
                              na_matches = "never")
  cell <- (match(joined$household_id, ids) - 1L) * nk + joined$item
  cells <- factor(cell, levels = seq_len(length(ids) * nk))
  has <- !is.na(joined$qty_g_d)
  grams <- ifelse(has, joined$qty_g_d * joined$fraction, 0)
  qty <- vapply(split(grams, cells), sum, numeric(1), USE.NAMES = FALSE)
  out <- dplyr::tibble(
    household_id = rep(ids, each = nk),
    use_status = rep(status, each = nk),
    level = rep(keys$level, length(ids)),
    vehicle = rep(keys$vehicle, length(ids)),
    acquired = NA,
    n_records = tabulate(cells, nbins = nlevels(cells)),
    n_records_no_grams = tabulate(cells[!has], nbins = nlevels(cells))
  )
  known <- !out$use_status %in% c("food_module_nonresponse",
                                  "no_food_records")
  out$acquired[known] <- out$n_records[known] > 0
  ok <- out$use_status == "estimated" & out$level != "combined"
  out$qty_vehicle_g_d <- ifelse(ok, qty / rep(afe_h, each = nk), NA_real_)
  out
}
