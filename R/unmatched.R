#' Foods whose records are not linked to the composition table
#'
#' List the survey foods with at least one record that
#' [link_composition()] could not link, with what blocks them, ranked so
#' that the foods worth fixing first come first. It is the coverage of the
#' audit log seen by food.
#'
#' A food without a unit factor has no grams, so ranking only by grams
#' would hide it: both counts are returned, and `order` says which ranks.
#'
#' @param x Table returned by [link_composition()].
#' @param order `"grams"` (default: grams per day of the records not
#'   linked, then records) or `"records"` (records not linked, then grams).
#'   Ties are ordered by `food_code`.
#' @returns A tibble, one row per food with a record not linked:
#'   `food_code`; `match_status` (the food's crosswalk, as in
#'   [link_composition()]: `matched` means the crosswalk is fine and the
#'   records lack grams); `n_records` (all records of the food);
#'   `n_not_linked`; `n_no_grams` (records without grams, see
#'   `grams_status` of [convert_units()]); `n_households` (with a record not
#'   linked); `qty_g_d_not_linked` (grams per day as acquired of the
#'   records not linked that have grams; `NA` when none has); and
#'   `share_records` and `share_grams` of the not-linked records over all
#'   records and all grams of `x`.
#' @seealso [link_composition()], [audit_log()].
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition,
#'   nutrients = nutrient_registry(hces_example$nutrients)
#' )
#' unmatched_foods(content)
#' unmatched_foods(content, order = "records")
#' @export
unmatched_foods <- function(x, order = c("grams", "records")) {
  require_hces(x, "hces_nutrient_content")
  order <- check_choice(order, c("grams", "records"))
  d <- dplyr::as_tibble(x)
  out <- food_counts(d)
  out <- out[out$n_not_linked > 0, ]
  out$share_records <- out$n_not_linked / nrow(d)
  total_g <- sum(d$qty_g_d[!is.na(d$qty_g_d)])
  out$share_grams <- out$qty_g_d_not_linked / total_g
  rank_foods(out, order)
}

# Counts per food, in base R: one row per distinct `food_code` of `d`.
food_counts <- function(d) {
  ids <- unique(d$food_code)
  k <- match(d$food_code, ids)
  by_food <- function(v, f) {
    vapply(split(v, factor(k, seq_along(ids))), f, numeric(1),
           USE.NAMES = FALSE)
  }
  out_rec <- d$composition_status != "linked"
  has_g <- out_rec & !is.na(d$qty_g_d)
  grams <- by_food(ifelse(has_g, d$qty_g_d, 0), sum)
  grams[by_food(has_g, sum) == 0] <- NA_real_
  hh <- vapply(seq_along(ids), function(i) {
    length(unique(d$household_id[k == i & out_rec]))
  }, numeric(1))
  dplyr::tibble(
    food_code = ids,
    match_status = d$match_status[match(seq_along(ids), k)],
    n_records = tabulate(k, nbins = length(ids)),
    n_not_linked = tabulate(k[out_rec], nbins = length(ids)),
    n_no_grams = tabulate(k[is.na(d$qty_g_d)], nbins = length(ids)),
    n_households = as.integer(hh),
    qty_g_d_not_linked = grams
  )
}

# Rows of `out` in the order asked; missing grams last, ties by food.
rank_foods <- function(out, order) {
  g <- -out$qty_g_d_not_linked
  r <- -out$n_not_linked
  i <- if (order == "grams") {
    base::order(g, r, out$food_code, na.last = TRUE)
  } else {
    base::order(r, g, out$food_code, na.last = TRUE)
  }
  out[i, ]
}
