#' Work queue: foods without a composition value, by nutrient
#'
#' List, for each nutrient, the survey foods with at least one record that
#' is linked to the composition table but has no value for that nutrient,
#' ranked by their weighted edible grams, with the share of grams that
#' would carry a value once each food and those ranked before it are
#' filled. It is the twin of [unmatched_foods()] for values: a record
#' without a value adds zero to the nutrient in [apparent_intake()].
#'
#' A linked record without a value for a nutrient adds zero. The sign of
#' the error is known: intake is understated, so the share below a
#' requirement is overstated and the share above an upper level
#' understated. Its size is not: the coverage gate of [inadequacy()] and
#' [above_ul()] (`min_coverage`) measures grams, and for a nutrient
#' concentrated in few foods (vitamin A, vitamin B12) the grams say little.
#' Three households with 400 g of rice a day (no vitamin A) and 10 g of
#' liver without a vitamin A value pass a gate of 0.95 at 0.976, and every
#' household is inadequate. No statistic of the data at hand sees that
#' concentration; this list makes it visible, so that a person who knows
#' the foods reads "liver: no vitamin A" before any figure and fills it
#' with [fill_composition()].
#'
#' Records counted: those included by the adapter (`include`) and linked
#' (`composition_status == "linked"`); the outlier decision is not applied,
#' as in [unmatched_foods()]. Grams are the edible grams per day of the
#' records (`qty_edible_g_d`) weighted by the household weight. These
#' shares rank the work; they are not the coverage of the gate, which is
#' weighted by adult female equivalents, unweighted by survey weights and
#' computed on the records used.
#'
#' @param x Table returned by [link_composition()] (or [fill_composition()]).
#' @param households Households table ([hces_schema()]`("households")`); it
#'   must contain every household of `x`.
#' @param nutrients `NULL` (default: every nutrient of the registry of `x`)
#'   or a character vector of registry names.
#' @returns A tibble with one row per nutrient and food with a record
#'   without the value, by nutrient in registry order and within it in rank
#'   order: `nutrient` and `column` (registry name and column);
#'   `food_code`; `composition_id` (the distinct composition rows of those
#'   records, sorted, separated by `"; "`); `n_records` (records without
#'   the value) and `n_households` (households with one); `qty_edible_g_d`
#'   (their weighted edible grams per day); `share_grams` (of the weighted
#'   edible grams of all included linked records; `NA` when those weigh
#'   zero); `rank` (within the nutrient: grams, then records, then
#'   `food_code`); and `cum_share_grams`: the share of grams with a value
#'   once this food and those before it are filled (it ends at 1). No rows,
#'   with the same columns, when no value is missing.
#' @seealso [unmatched_foods()], [fill_composition()], [inadequacy()].
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' content <- link_composition(
#'   grams, hces_example$crosswalk, hces_example$composition,
#'   nutrients = nutrient_registry(hces_example$nutrients)
#' )
#' missing_values(content, hces_example$households)
#' missing_values(content, hces_example$households, nutrients = "iron")
#' @export
missing_values <- function(x, households, nutrients = NULL) {
  check_required()
  require_hces(x, "hces_nutrient_content")
  registry <- attr(x, "nutrients", exact = TRUE)
  if (is.null(nutrients)) nutrients <- registry$nutrient
  check_assessed(nutrients, registry)
  h <- validate_households(households)
  m <- record_measures(x, h)
  d <- dplyr::as_tibble(x)[m$validated, ]
  w <- m$weight[m$validated]
  total <- sum(d$qty_edible_g_d * w)
  reg <- registry[registry$nutrient %in% nutrients, ]
  rows <- lapply(seq_len(nrow(reg)), function(i) {
    missing_foods(d, w, total, reg$nutrient[[i]], reg$column[[i]])
  })
  dplyr::bind_rows(missing_values_empty(), rows)
}

# The columns of missing_values(), with no rows.
missing_values_empty <- function() {
  dplyr::tibble(
    nutrient = character(0), column = character(0), food_code = character(0),
    composition_id = character(0), n_records = integer(0),
    n_households = integer(0), qty_edible_g_d = double(0),
    share_grams = double(0), rank = integer(0), cum_share_grams = double(0)
  )
}

# The rows of one nutrient: the included linked records `d`, their
# household weights `w`, and the weighted edible grams of all of them
# (`total`).
missing_foods <- function(d, w, total, nutrient, column) {
  miss <- is.na(d[[column]])
  if (!any(miss)) {
    return(NULL)
  }
  g <- d$qty_edible_g_d * w
  food <- d$food_code[miss]
  ids <- sort(unique(food))
  k <- factor(match(food, ids), seq_along(ids))
  per_food <- function(v, f) {
    vapply(split(v, k), f, FUN.VALUE = f(v[0]), USE.NAMES = FALSE)
  }
  ids_of <- function(v) paste(sort(unique(v)), collapse = "; ")
  out <- dplyr::tibble(
    nutrient = nutrient, column = column, food_code = ids,
    composition_id = per_food(as.character(d$composition_id[miss]), ids_of),
    n_records = per_food(rep(1L, sum(miss)), function(v) length(v)),
    n_households = per_food(d$household_id[miss],
                            function(v) length(unique(v))),
    qty_edible_g_d = per_food(g[miss], sum)
  )
  out$share_grams <- if (total > 0) out$qty_edible_g_d / total else NA_real_
  out <- out[order(-out$qty_edible_g_d, -out$n_records, out$food_code), ]
  out$rank <- seq_len(nrow(out))
  with_value <- if (total > 0) sum(g[!miss]) / total else NA_real_
  out$cum_share_grams <- with_value + cumsum(out$share_grams)
  out
}
