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
#' `domain`, `domain_value`, `food_group`, `form`, `source`, or any other
#' word), `parent` (the domain a `domain_value` belongs to; missing for
#' every other type), `code` (compared as text) and `label`. The key is
#' `type` + `parent` + `code`. A label repeated within one `type` +
#' `parent` is an error: two codes with one label would merge two
#' categories silently. Row order is display order. There is no fallback to
#' the code: a code without a label is an error that lists every missing
#' code with the lines to add.
#'
#' @param file Path of a CSV file in UTF-8 with the four columns.
#' @param needed `NULL` or a named list, type to the codes that must have a
#'   label; for `domain_value`, a named list, domain to its values.
#' @returns `read_labels()`: the table as a tibble of text columns.
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
#'   "domain_value,region,north,North"
#' ), f)
#' labels <- read_labels(f, needed = list(
#'   nutrient = "iron", domain_value = list(region = c("north", "south"))
#' ))
#' label_codes(c("north", "south", "north"), labels, "domain_value",
#'             parent = "region")
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
#' @export
label_codes <- function(x, labels, type, parent = NULL) {
  check_required()
  labels <- check_labels(labels)
  if (!rlang::is_string(type) ||
        !(is.null(parent) || rlang::is_string(parent))) {
    abort_hcesfort("argument", c(
      "{.arg type} must be one string and {.arg parent} one string or NULL."
    ), arg = "type")
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
  factor(rows$label[match(codes, rows$code)], levels = rows$label)
}

# Rows of `labels` of one type (and parent).
labels_of <- function(labels, type, parent) {
  f <- labels$type == type &
    if (is.null(parent)) is.na(labels$parent) else labels$parent %in% parent
  labels[f, ]
}
