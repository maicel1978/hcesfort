#' Apparent intake per adult female equivalent
#'
#' Sum the nutrients of each household's records and divide by its adult
#' female equivalents (AFE): apparent intake per AFE per day. The result
#' has one row per household of `households`, each with a status, so the
#' households without an estimate stay in the design and are counted
#' (E5).
#'
#' A record enters the sum when it is included by the adapter (`include`),
#' linked to the composition table (`composition_status == "linked"`) and,
#' with `outliers = "exclude"`, not flagged as an outlier (a record not
#' assessed, `NA`, is kept). Every record left out is counted in the audit
#' log by cause, with its grams.
#'
#' A linked record without a value for a nutrient adds nothing to that
#' nutrient: the sum covers the records with a value, and the column
#' `<nutrient column>_coverage` gives, per household, the share of the
#' edible grams used that have a value for the nutrient (1 when complete;
#' `NA` when the records used weigh zero grams).
#' Missing values are therefore never hidden (E21), and the risk step can
#' require a minimum coverage.
#'
#' **Record loss.** The coverage columns say nothing about the records that
#' never reached the sum (no grams, no composition link, an excluded
#' outlier). `share_records_used` is the share of the household's included
#' records that were used; `share_grams_used` the same share by purchased
#' grams per day (`qty_g_d`), over the included records that have grams. A
#' record without grams is in neither term, so `share_grams_used` is an
#' upper bound of what was kept. A record left out by `outliers =
#' "exclude"` counts as not used. [inadequacy()] and [above_ul()] require a
#' minimum overall share (`min_records_used`).
#'
#' Status, in this order: `food_module_nonresponse` (`households` says the
#' household did not answer the food module), `no_food_records` (no
#' record in `content`), `all_records_lost` (records, none used), `no_afe`
#' (no AFE, or an AFE of zero), `estimated`. Intake is `NA` unless the
#' status is `estimated`.
#'
#' @param content Table returned by [link_composition()].
#' @param afe Table returned by [adult_equivalents()].
#' @param households Households table ([hces_schema()]`("households")`),
#'   validated or not: the households the result must cover.
#' @param outliers Required when `content` has the column `outlier` (from
#'   [flag_outliers()]): `"exclude"` leaves the flagged records out,
#'   `"keep"` uses them. Must be `NULL` otherwise.
#' @returns A tibble of class `hces_intake` (and `hces_tbl`), one row per
#'   household of `households`, in its order: `household_id`,
#'   `intake_status`, `afe`, `n_records` (in `content`), `n_records_used`,
#'   `n_records_included`, `share_records_used`, `share_grams_used`,
#'   `qty_edible_g_d` (edible grams per AFE per day), one column per
#'   nutrient (amount per AFE per day, in the unit of the registry) and its
#'   `_coverage` column. The registry travels with the table. The audit log
#'   continues the logs of `content`, `afe` and `households`.
#' @seealso [flag_energy_plausibility()], [nutrient_density()],
#'   [audit_log()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition, nutrients
#' )
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' intake <- apparent_intake(content, afe, hces_example$households)
#' table(intake$intake_status)
#' subset(audit_log(intake), step == "apparent_intake")
#' @export
apparent_intake <- function(content, afe, households, outliers = NULL) {
  require_hces(content, "hces_nutrient_content")
  require_hces(afe, "hces_afe")
  x <- audit_check_rows(content, "apparent_intake")
  h <- validate_households(households)
  nutrients <- attr(x, "nutrients", exact = TRUE)
  outliers <- check_outlier_decision(outliers, x)
  check_intake_ids(x, afe, h)
  reasons <- excluded_reasons(x, outliers)
  used <- !Reduce(`|`, reasons)
  sums <- household_sums(x, used, h$household_id, nutrients)
  afe_h <- afe$afe[match(h$household_id, afe$household_id)]
  status <- intake_status(h, sums, afe_h)
  ok <- status == "estimated"
  out <- dplyr::tibble(household_id = h$household_id, intake_status = status,
                       afe = afe_h, n_records = sums$n_records,
                       n_records_used = sums$n_used)
  out <- dplyr::bind_cols(out, records_used_shares(sums))
  per_afe <- function(v) ifelse(ok, v / afe_h, NA_real_)
  out$qty_edible_g_d <- per_afe(sums$edible)
  for (col in nutrients$column) {
    out[[col]] <- per_afe(sums[[col]])
    out[[paste0(col, "_coverage")]] <- ifelse(ok, sums$coverage[[col]],
                                              NA_real_)
  }
  log <- intake_log(x, reasons, used, out, nutrients)
  log <- dplyr::bind_rows(audit_get(x), audit_get(afe), audit_get(h), log)
  new_hces_tbl(out, "hces_intake", log, "household_id", nutrients)
}

# A named list of logical vectors, one per reason a record is left out of
# the sums. Causes are not hierarchical.
excluded_reasons <- function(x, outliers) {
  flagged <- if (identical(outliers, "exclude")) {
    !is.na(x$outlier) & x$outlier
  } else {
    rep(FALSE, nrow(x))
  }
  list(
    not_included = !x$include,
    not_linked = x$composition_status != "linked",
    outlier_excluded = flagged
  )
}

# Per household of `ids`: records in `x`, records used, edible grams and
# the sum of each nutrient over the used records with a value, and the
# share of edible grams with a value.
household_sums <- function(x, used, ids, nutrients) {
  k <- match(x$household_id, ids)
  n <- length(ids)
  total <- function(v, f) {
    vapply(split(v[f], factor(k[f], seq_len(n))), sum, numeric(1),
           USE.NAMES = FALSE)
  }
  edible <- total(x$qty_edible_g_d, used)
  inc <- x$include
  g <- !is.na(x$qty_g_d)
  out <- list(n_records = tabulate(k, nbins = n),
              n_used = tabulate(k[used], nbins = n), edible = edible,
              n_included = tabulate(k[inc], nbins = n),
              g_included = total(x$qty_g_d, inc & g),
              g_used = total(x$qty_g_d, used & g), coverage = list())
  for (col in nutrients$column) {
    has <- used & !is.na(x[[col]])
    out[[col]] <- total(x[[col]], has)
    cov <- total(x$qty_edible_g_d, has) / edible
    cov[edible == 0] <- NA_real_
    out$coverage[[col]] <- cov
  }
  out
}

# Record loss per household: records included, and the shares of them used,
# by count and by purchased grams (records without grams are in neither
# term). NA when the denominator is 0.
records_used_shares <- function(sums) {
  share <- function(a, b) ifelse(b > 0, a / b, NA_real_)
  dplyr::tibble(
    n_records_included = sums$n_included,
    share_records_used = share(sums$n_used, sums$n_included),
    share_grams_used = share(sums$g_used, sums$g_included)
  )
}

# The status of each household of `h`, in the documented order.
intake_status <- function(h, sums, afe_h) {
  response <- h[["food_module_response"]]
  if (is.null(response)) response <- rep(TRUE, nrow(h))
  reasons <- list(
    food_module_nonresponse = !is.na(response) & !response,
    no_food_records = sums$n_records == 0,
    all_records_lost = sums$n_records > 0 & sums$n_used == 0,
    no_afe = is.na(afe_h) | afe_h <= 0
  )
  first_reason(reasons, none = "estimated")
}
