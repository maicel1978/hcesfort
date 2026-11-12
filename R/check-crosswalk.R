#' Quality controls of a crosswalk
#'
#' Flag crosswalk rows that deserve a second look before they enter the
#' calculation. Nothing is changed or excluded: each control adds a flag
#' column, and deciding what to do with a flagged row is left to the user.
#' Only validated rows are checked; the flags of other rows are `NA`.
#'
#' Controls:
#'
#' * `flag_missing_edible_portion`: no edible portion.
#' * `flag_portion_conflict`: the composition food is matched by other
#'   validated rows with another edible portion (found in the original
#'   ENGIH 2018 analysis).
#' * `flag_shared_match`: the composition food is matched by another
#'   validated food (often legitimate; worth a look when the foods differ).
#' * `flag_consumed_no_yield`: the composition row describes a cooked food
#'   or a food as consumed and the row has no `yield_factor`, while the
#'   survey records purchases (E20).
#' * `n_missing_nutrients`: nutrients of the registry missing in the
#'   composition row (E21).
#' * `flag_fortified`: the composition row is enriched or fortified (E1,
#'   E6); only when `composition` has the column `fortified`.
#' * `flag_review_type`: `match_type` is one of `review_types`; only when
#'   given.
#' * `flag_outside_range`: a nutrient of the composition row is outside a
#'   range of `ranges`; only when given. Ranges come from the user: the
#'   package has no reference range.
#'
#' @inheritParams link_composition
#' @param grams Optional table returned by [convert_units()]: adds the
#'   records (`n_records`) and grams per day as acquired (`qty_g_d`) of each
#'   food, and the grams of the flagged rows to the log, to rank the review.
#' @param review_types Optional values of `match_type` that mark a match as
#'   needing review (for example `"requires_review"`).
#' @param ranges Optional data frame with columns `column` (a nutrient
#'   column of the registry), `min` and `max` (per 100 g edible portion,
#'   either may be `NA` for no bound) and, when `group` is given, `group`.
#' @param group Optional name of a column of `composition` whose values
#'   select the rows of `ranges` that apply to each composition row.
#' @returns `crosswalk` as a validated table (class `hces_crosswalk`) with
#'   the flag columns added; its audit log counts the rows flagged by each
#'   control (`kind = "flagged"`, with grams per day when `grams` is
#'   given).
#' @seealso [link_composition()], [unmatched_foods()].
#' @examples
#' checked <- check_crosswalk(
#'   hces_example$crosswalk, hces_example$composition,
#'   nutrients = nutrient_registry(hces_example$nutrients),
#'   ranges = data.frame(column = "energy_kcal", min = 20, max = 900)
#' )
#' checked[, c("food_code", "flag_fortified", "flag_consumed_no_yield")]
#' subset(audit_log(checked), step == "check_crosswalk")
#' @export
check_crosswalk <- function(crosswalk, composition, nutrients = NULL,
                            grams = NULL, review_types = NULL,
                            ranges = NULL, group = NULL) {
  nutrients <- composition_registry(composition, nutrients)
  cw <- validate_crosswalk(crosswalk)
  cw <- audit_check_rows(cw, "check_crosswalk")
  comp <- validate_composition(composition, nutrients)
  if (!is.null(grams)) require_hces(grams, "hces_grams")
  check_composition_ids(grams, cw, comp)
  check_review_args(review_types, ranges, group, comp, nutrients)
  out <- dplyr::as_tibble(cw)
  v <- out$validated
  m <- comp[match(out$composition_id, comp$composition_id), ]
  only_valid <- function(f) ifelse(v, f, NA)
  out$flag_missing_edible_portion <- only_valid(is.na(out$edible_portion))
  out$flag_portion_conflict <- only_valid(portion_conflict(out))
  out$flag_shared_match <- only_valid(shared_match(out))
  yield <- out[["yield_factor"]]
  if (is.null(yield)) yield <- rep(NA_real_, nrow(out))
  out$flag_consumed_no_yield <- only_valid(
    m$food_state %in% c("cooked", "as_consumed") & is.na(yield)
  )
  out$n_missing_nutrients <- ifelse(
    v, rowSums(is.na(as.matrix(m[nutrients$column]))), NA_integer_
  )
  if (!is.null(comp[["fortified"]])) {
    out$flag_fortified <- only_valid(!is.na(m$fortified) & m$fortified)
  }
  if (!is.null(review_types)) {
    out$flag_review_type <- only_valid(out$match_type %in% review_types)
  }
  if (!is.null(ranges)) {
    out$flag_outside_range <- only_valid(outside_range(m, ranges, group))
  }
  out <- add_food_grams(out, grams)
  log <- check_log(out, nutrients)
  new_hces_tbl(out, "hces_crosswalk", dplyr::bind_rows(audit_get(cw), log),
               "food_code")
}

# TRUE for validated rows whose composition food is matched by validated
# rows with more than one distinct edible portion.
portion_conflict <- function(out) {
  v <- out$validated & !is.na(out$edible_portion)
  ids <- out$composition_id[v]
  ep <- out$edible_portion[v]
  n_ep <- vapply(split(ep, ids), function(e) length(unique(e)), integer(1))
  conflict <- names(n_ep)[n_ep > 1]
  out$validated & as.character(out$composition_id) %in% conflict
}

# TRUE for validated rows whose composition food is matched by more than
# one validated food.
shared_match <- function(out) {
  ids <- out$composition_id[out$validated]
  shared <- unique(ids[duplicated(ids)])
  out$validated & out$composition_id %in% shared
}

# TRUE when a nutrient of the row is outside a range that applies to it;
# FALSE when inside or not assessable (value or group missing).
outside_range <- function(m, ranges, group) {
  out <- rep(FALSE, nrow(m))
  for (i in seq_len(nrow(ranges))) {
    applies <- if (is.null(group)) TRUE else
      !is.na(m[[group]]) & m[[group]] == ranges$group[[i]]
    x <- m[[ranges$column[[i]]]]
    low <- !is.na(ranges$min[[i]]) & !is.na(x) & x < ranges$min[[i]]
    high <- !is.na(ranges$max[[i]]) & !is.na(x) & x > ranges$max[[i]]
    out <- out | (applies & (low | high))
  }
  out
}
