#' Read and apply a label table
#'
#' Reports print labels, never codes. A label table gives the label of
#' every code a report shows (nutrients, units, vehicles, scenarios, domains
#' and their values, food groups, forms), in the order the report shows
#' them. `read_labels()` reads and checks one; `label_codes()` turns codes
#' into labels.
#'
#' The table ([hces_schema()]`("labels")`) has the columns `type` (what the
#' code is: `nutrient`, `unit`, `vehicle`, `vehicle_group`, `scenario`,
#' `domain`, `domain_value`, `food_group`, `form`, `compound`, `source`,
#' or any other
#' word), `parent` (the domain a `domain_value` belongs to; missing for
#' every other type), `code` (compared as text), `label` and, optionally,
#' `short_label`: what a figure prints where the label is too long (an
#' abbreviation of a scenario, for example); missing means the label. Type
#' `compound` labels the fortificant compounds a scenario names. The key is
#' `type` + `parent` + `code`. A label repeated within one `type` +
#' `parent` is an error, and so is a short label (or the label where it is
#' missing): two codes with one label would merge two categories
#' silently. Row order is display order. There is no fallback to
#' the code: a code without a label is an error that lists every missing
#' code with the lines to add.
#'
#' @param file Path of a CSV file in UTF-8 with the four columns and,
#'   optionally, `short_label`.
#' @param needed `NULL` or a named list, type to the codes that must have a
#'   label; for `domain_value`, a named list, domain to its values.
#' @returns `read_labels()`: the table as a tibble of five text columns
#'   (`short_label` missing throughout when the file has no such column).
#'   `label_codes()`: a factor with the labels of `x` (missing where `x` is
#'   missing), whose levels are the labels of the codes present in `x`, in
#'   table order.
#' @seealso [read_decisions()], [use_report_template()].
#' @examples
#' f <- tempfile(fileext = ".csv")
#' writeLines(c(
#'   "type,parent,code,label",
#'   "nutrient,,iron,Iron",
#'   "domain,,region,Region",
#'   "domain_value,region,south,South",
#'   "domain_value,region,north,North",
#'   "scenario,,wheat_iron,Wheat flour with iron"
#' ), f)
#' labels <- read_labels(f, needed = list(
#'   nutrient = "iron", domain_value = list(region = c("north", "south"))
#' ))
#' label_codes(c("north", "south", "north"), labels, "domain_value",
#'             parent = "region")
#'
#' # A short label for figures; the label is used where it is missing.
#' g <- tempfile(fileext = ".csv")
#' writeLines(c(
#'   "type,parent,code,label,short_label",
#'   "scenario,,wheat_iron,Wheat flour with iron and folic acid,Wheat",
#'   "scenario,,baseline,No fortification,"
#' ), g)
#' label_codes(c("baseline", "wheat_iron"), read_labels(g), "scenario",
#'             short = TRUE)
#' @export
read_labels <- function(file, needed = NULL) {
  check_required()
  x <- read_text_table(file)
  x <- check_labels(x)
  if (!is.null(needed)) check_needed_labels(x, needed)
  x
}

#' @rdname read_labels
#' @param x Codes to label (any atomic vector; compared as text).
#' @param labels Table returned by `read_labels()`.
#' @param type One type of the table.
#' @param parent For `domain_value`, the domain; otherwise `NULL`.
#' @param short `TRUE` for the short labels (the label where a code has
#'   none), `FALSE` (default) for the labels.
#' @export
label_codes <- function(x, labels, type, parent = NULL, short = FALSE) {
  check_required()
  labels <- check_labels(labels)
  if (!rlang::is_string(type) ||
        !(is.null(parent) || rlang::is_string(parent))) {
    abort_hcesfort("argument", c(
      "{.arg type} must be one string and {.arg parent} one string or NULL."
    ), arg = "type")
  }
  if (!rlang::is_bool(short)) {
    abort_hcesfort("argument", "{.arg short} must be TRUE or FALSE.",
                   arg = "short")
  }
  codes <- as.character(x)
  present <- unique(codes[!is.na(codes)])
  needed <- if (type == "domain_value") {
    rlang::list2(domain_value = stats::setNames(list(present), parent))
  } else {
    stats::setNames(list(present), type)
  }
  check_needed_labels(labels, needed)
  rows <- labels_of(labels, type, parent)
  rows <- rows[rows$code %in% present, ]
  shown <- rows$label
  if (short) shown <- dplyr::coalesce(rows$short_label, shown)
  factor(shown[match(codes, rows$code)], levels = shown)
}

# Rows of `labels` of one type (and parent).
labels_of <- function(labels, type, parent) {
  f <- labels$type == type &
    if (is.null(parent)) is.na(labels$parent) else labels$parent %in% parent
  labels[f, ]
}
