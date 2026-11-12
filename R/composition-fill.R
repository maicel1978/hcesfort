#' Fill gaps of a food composition table
#'
#' Fill missing nutrient values of a composition table with values given
#' by the user, each with its source. Only missing values are filled: a
#' value given for a cell that already has one is not used and is counted
#' (`fill_not_needed`). Every filled cell is counted per nutrient in the
#' audit log, so the share of intake that rests on filled values can be
#' traced.
#'
#' The package has no rule of its own. Rules used by the original ENGIH
#' 2018 analysis are expressed as rows of `fills`: a value borrowed from
#' another food, or zero for vitamin B12 and vitamin D in unprocessed plant
#' foods (one row per food, with that rule as `source`).
#'
#' @param composition Composition table, validated by
#'   [validate_composition()] or not.
#' @param fills Values to fill ([hces_schema()]`("composition_fills")`):
#'   `composition_id`, `nutrient` (a nutrient of the registry), `value` (per
#'   100 g edible portion, in the unit of the registry) and `source`.
#' @param nutrients Registry built by [nutrient_registry()]; needed when
#'   `composition` is not validated, otherwise taken from it.
#' @returns `composition` as a validated table of class `hces_composition`
#'   with the gaps filled; its audit log adds, per nutrient, the cells
#'   filled (`filled_from_table`) and the fills not used
#'   (`fill_not_needed`), with the column in `detail`.
#' @seealso [link_composition()], [validate_composition()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' fills <- data.frame(
#'   composition_id = "C12", nutrient = "folate", value = 30,
#'   source = "invented: borrowed from another biscuit"
#' )
#' filled <- fill_composition(hces_example$composition, fills, nutrients)
#' subset(audit_log(filled), step == "fill_composition")
#' @export
fill_composition <- function(composition, fills, nutrients = NULL) {
  nutrients <- composition_registry(composition, nutrients)
  comp <- validate_composition(composition, nutrients)
  comp <- audit_check_rows(comp, "fill_composition")
  f <- validate_table(fills, schema_composition_fills(nutrients),
                      "validate_composition_fills", function(x) list(),
                      call = rlang::current_env())
  check_fill_ids(comp, f)
  out <- dplyr::as_tibble(comp)
  row <- match(f$composition_id, out$composition_id)
  column <- nutrients$column[match(f$nutrient, nutrients$nutrient)]
  current <- mapply(function(r, col) out[[col]][[r]], row, column)
  gap <- is.na(current)
  for (i in which(gap)) out[[column[i]]][row[i]] <- f$value[i]
  log <- fill_log(column, gap, nrow(out))
  log <- dplyr::bind_rows(audit_get(comp), audit_get(f), log)
  new_hces_tbl(out, "hces_composition", log, "composition_id", nutrients)
}

# Abort when a fill names a composition food absent from the table, or
# its id has another type.
check_fill_ids <- function(comp, f, call = rlang::caller_env()) {
  if (nrow(f) > 0 && !same_id_type(f$composition_id, comp$composition_id)) {
    abort_hcesfort("join", c(
      "{.field composition_id} differs in type between {.arg fills} and
      {.arg composition}."
    ), table = "fills", other = "composition", columns = "composition_id",
    n = NA_integer_, call = call)
  }
  absent <- unique(f$composition_id[!f$composition_id %in%
                                      comp$composition_id])
  if (length(absent) > 0) {
    n <- length(absent)
    abort_hcesfort("join", c(
      "{n} composition id{?s} of {.arg fills} {?is/are} not in
      {.arg composition}.",
      "x" = "Id{?s}: {.val {utils::head(absent, 5)}}."
    ), table = "fills", other = "composition", columns = "composition_id",
    n = n, call = call)
  }
  invisible(TRUE)
}

# Audit rows of fill_composition(): per nutrient column, the cells filled
# and the fills not needed.
fill_log <- function(column, gap, n) {
  step <- "fill_composition"
  rows <- function(kind, cause, f) {
    if (!any(f)) return(NULL)
    counts <- table(column[f])
    audit_row(step, "composition", kind, cause, as.integer(counts),
              detail = names(counts))
  }
  dplyr::bind_rows(
    audit_row(step, "composition", "input", "all", n),
    rows("filled", "filled_from_table", gap),
    rows("note", "fill_not_needed", !gap)
  )
}
