#' Inventory of the variables and tables a survey supplies
#'
#' The first section of the data readiness report: which variables of the
#' standard tables and which user-supplied tables are present, which are
#' essential, how much of each is missing, and which sections of the
#' results report depend on them (DR1). It only looks at names and missing
#' values, so it runs on tables that fail their contract: an essential row
#' absent means that nothing else can be computed.
#'
#' Rows, in this order: one per column of the schemas of `households`,
#' `members` and `acquisitions` ([hces_schema()]); one per domain of
#' `domains` (a column of `households`); one per user-supplied table.
#' Essential: the required columns of the three schemas and the tables
#' `unit_factors`, `crosswalk` and `composition`. Optional: the other
#' columns, the domains and the tables `enrichment` (absent: no enriched
#' food is declared), `vehicles`, `scenarios` and `food_groups`. Food eaten
#' away from home is the column `meals_home_share` of `members`.
#'
#' @param tables A named list of the tables as supplied, not validated:
#'   `households`, `members`, `acquisitions`, `unit_factors`, `crosswalk`,
#'   `composition`, `enrichment`, `vehicles`, `scenarios`, `food_groups`.
#'   An absent table is `NULL` or left out.
#' @param domains `NULL` or the names of the domain columns of
#'   `households`.
#' @returns A tibble: `table`, `variable` (`NA` for a table row), `role`
#'   (`"essential"` or `"optional"`), `present` (exists and is not all
#'   missing; a table: exists and has rows), `share_missing` (of a column;
#'   `NA` for a table or an absent column) and `needed_by` (`"all"`, the
#'   sections of the results report that depend on it separated by `", "`,
#'   or `"none"`).
#' @seealso [readiness_checks()], [readiness_verdict()].
#' @examples
#' e <- hces_example
#' inv <- readiness_inventory(e[names(e) != "nutrients"],
#'                            domains = c("region", "expenditure_group"))
#' inv[!inv$present, ]
#' @export
readiness_inventory <- function(tables, domains = NULL) {
  check_required()
  check_inventory_args(tables, domains)
  standard <- c("households", "members", "acquisitions")
  rows <- lapply(standard, function(t) {
    schema <- schema_registry()[[t]]()
    column_rows(tables[[t]], t, schema$column,
                ifelse(schema$required, "essential", "optional"),
                ifelse(schema$required, "all", "none"))
  })
  dom <- column_rows(tables[["households"]], "households", domains,
                     rep("optional", length(domains)),
                     rep("all", length(domains)))
  user <- readiness_tables()
  tab <- dplyr::tibble(
    table = names(user), variable = NA_character_, role = unname(user),
    present = vapply(names(user), function(t) {
      is.data.frame(tables[[t]]) && nrow(tables[[t]]) > 0
    }, logical(1), USE.NAMES = FALSE),
    share_missing = NA_real_,
    needed_by = unname(ifelse(user == "essential", "all",
                              vapply(names(user), needed_by, character(1))))
  )
  dplyr::bind_rows(c(rows, list(dom, tab)))
}

# Inventory rows of the columns `cols` of table `x` (named `table`).
column_rows <- function(x, table, cols, role, needed) {
  has <- !is.null(x) & cols %in% names(x)
  share <- vapply(seq_along(cols), function(i) {
    if (!has[[i]] || nrow(x) == 0) NA_real_ else mean(is.na(x[[cols[[i]]]]))
  }, numeric(1))
  dplyr::tibble(
    table = rep(table, length(cols)), variable = as.character(cols),
    role = role, present = has & !is.na(share) & share < 1,
    share_missing = share, needed_by = unname(needed)
  )
}

# Abort unless `tables` is a named list of data frames (or NULL) with
# known names and `domains` is NULL or a character vector.
check_inventory_args <- function(tables, domains,
                                 call = rlang::caller_env()) {
  known <- c("households", "members", "acquisitions",
             names(readiness_tables()))
  ok <- is.list(tables) && !is.data.frame(tables) &&
    (length(tables) == 0 || (!is.null(names(tables)) &&
                               all(names(tables) %in% known))) &&
    all(vapply(tables, function(t) is.null(t) || is.data.frame(t),
               logical(1)))
  if (!ok) {
    abort_hcesfort("argument", c(
      "{.arg tables} must be a named list of data frames (or NULL).",
      "i" = "Known names: {.val {known}}."
    ), arg = "tables", call = call)
  }
  if (!is.null(domains) && (!is.character(domains) || anyNA(domains))) {
    abort_hcesfort("argument", c(
      "{.arg domains} must be NULL or the names of household columns."
    ), arg = "domains", call = call)
  }
  invisible(TRUE)
}
