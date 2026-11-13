# Display rules of both reports: percentages, points, intervals, labels
# and printing. Language-free: every word printed comes from labels.csv
# (the analyst's codes) or terms.csv (the package's vocabulary). Sourced
# after _chain.R; may be edited.
#
# Every table is stored in `tables$<id>` with code column names and
# numeric values before it is printed; print_table() turns the names into
# headers and each pair of interval columns into one column.

options(knitr.kable.NA = "—")
tables <- list()
figures <- list()

# Proportions as percentages; differences of proportions as points.
pct <- function(x, digits = 1) {
  round(100 * x, digits)
}

# Labels of the package vocabulary (terms.csv), as text, in the order of
# `code`. A code without a label stops the render.
term <- function(code, type) {
  as.character(label_codes(code, terms, type))
}

# Labels of the analyst's codes (labels.csv), as a factor in the order of
# the label table.
lab <- function(code, type, parent = NULL) {
  label_codes(code, labels, type, parent)
}

# Lists of codes in one string ("a, b"), each code replaced by its term.
term_list <- function(x, type, sep = ", ") {
  vapply(x, function(s) {
    if (is.na(s)) {
      return(NA_character_)
    }
    paste(term(strsplit(s, sep, fixed = TRUE)[[1]], type), collapse = sep)
  }, character(1), USE.NAMES = FALSE)
}

# An interval as text, the limits of a column with the same decimals;
# missing when either limit is.
ci_text <- function(low, high) {
  f <- format(c(low, high), trim = TRUE)
  n <- length(low)
  ifelse(is.na(low) | is.na(high), NA_character_,
         paste0("[", f[seq_len(n)], ", ", f[n + seq_len(n)], "]"))
}

# Print a table of `tables`: interval pairs (`*ci_low`, `*ci_high`) become
# one column, column codes become the headers of terms.csv (type
# `header`; `{level}` is replaced by the confidence level) unless
# `headers` (code = label) gives them.
print_table <- function(d, caption = NULL, headers = NULL) {
  d <- as.data.frame(d)
  for (low in grep("ci_low$", names(d), value = TRUE)) {
    high <- sub("ci_low$", "ci_high", low)
    d[[low]] <- ci_text(d[[low]], d[[high]])
    names(d)[names(d) == low] <- sub("_low$", "", low)
    d[[high]] <- NULL
  }
  codes <- names(d)
  own <- codes %in% names(headers)
  shown <- character(length(codes))
  shown[own] <- headers[codes[own]]
  shown[!own] <- term(codes[!own], "header")
  shown <- gsub("{level}", 100 * choices$level, shown, fixed = TRUE)
  knitr::kable(d, col.names = shown, caption = caption, row.names = FALSE)
}
