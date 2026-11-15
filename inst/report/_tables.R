# Display rules of both reports: percentages, points, intervals, labels
# and printing. Language-free: every word printed comes from labels.csv
# (the analyst's codes) or terms.csv (the package's vocabulary). Sourced
# after _chain.R; may be edited.
#
# Every table is stored in `tables$<id>` with code column names and
# numeric values before it is printed; print_table() turns the names into
# headers and each pair of interval columns into one column.

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
# the label table; `short` for the short labels of figures (R22).
lab <- function(code, type, parent = NULL, short = FALSE) {
  label_codes(code, labels, type, parent, short = short)
}

# Labels of the values of the domain `by`. A missing value is not a
# suppressed estimate: it carries its own label, last (V-D23).
domain_label <- function(x, by, short = FALSE) {
  out <- lab(x, "domain_value", by, short = short)
  if (!anyNA(x)) {
    return(out)
  }
  missing <- term("no_data", "format")
  factor(ifelse(is.na(x), missing, as.character(out)),
         levels = c(levels(out), missing))
}

# A label inside a sentence: its first letter in lower case ("Vitamin A"
# becomes "vitamin A").
lower_first <- function(x) {
  x <- as.character(x)
  paste0(tolower(substr(x, 1, 1)), substr(x, 2, nchar(x)))
}

# A list of labels in one string: "a, b and c" ("y" in Spanish).
collapse <- function(x) {
  n <- length(x)
  if (n < 2) {
    return(paste(x, collapse = ""))
  }
  paste(paste(x[-n], collapse = ", "), term("and", "format"), x[n])
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
# one column, a `mark` column ("†", "‡") is appended to the value column
# named by the attribute `value`, a column `n` that is the same in every
# row is dropped (the note gives it, R17), and column codes become the
# headers of terms.csv (type `header`; `{level}` is replaced by the
# confidence level) unless `headers` (code = label) gives them.
print_table <- function(d, caption = NULL, headers = NULL) {
  value <- attr(d, "value")
  d <- as.data.frame(d)
  if (length(unique(d[["n"]])) == 1) d$n <- NULL
  if (!is.null(d$mark) && !is.null(value)) {
    d[[value]] <- ifelse(is.na(d$mark), format(d[[value]], trim = TRUE),
                         paste0(format(d[[value]], trim = TRUE), d$mark))
    d[[value]][is.na(d$mark) & grepl("^NA$", d[[value]])] <- NA
  }
  d$mark <- NULL
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
  names(d) <- gsub("{level}", 100 * level, shown, fixed = TRUE)
  x <- tinytable::tt(d, caption = caption)
  x <- tinytable::format_tt(x, replace = "\u2014")
  tinytable::theme_html(x, portable = TRUE)
}

# Write a table of print_table() into the document. knit_print() wraps the
# HTML of tinytable, with its inline script, in a raw HTML block; print()
# does not, and Pandoc then reads the script as Markdown (code spans, K15).
emit_table <- function(x) {
  cat(knitr::knit_print(x), "\n\n", sep = "")
  invisible(NULL)
}

# Estimates for display (R17, R19), from a table of flag_presentation():
# `keys` are the label columns kept, `value` the name of the estimate
# column. Values are scaled by `scale` (percent by default). A suppressed
# estimate, or one flagged for review when `choices$review` is
# "suppress", keeps its row with no value ("—"); one flagged for review
# gets the mark "†", one whose complement may be unreliable "‡". A
# proportion with zero events (0 or every household) leaves the table,
# unless `drop_exact` is FALSE, for the sentence of exact_sentence(), with
# `n` and the upper limit. Columns in `extra` are copied after `n`. The
# reasons of the suppressed and of the flagged rows are kept in the
# attributes `suppressed_reasons` and `review_reasons`, for the notes.
display <- function(e, keys, value, scale = pct, unit = "%",
                    drop_exact = TRUE, extra = NULL) {
  e <- as.data.frame(e)
  review <- e$presentation %in% "review"
  hide <- e$presentation %in% "suppress" |
    (review & choices$review == "suppress")
  zero <- drop_exact & !hide & e$presentation_reason %in% "zero_events"
  out <- e[keys]
  out$n <- e[["n"]]
  out[extra] <- e[extra]
  out[[value]] <- ifelse(hide, NA, scale(e$estimate))
  out$ci_low <- ifelse(hide, NA, scale(e$ci_low))
  out$ci_high <- ifelse(hide, NA, scale(e$ci_high))
  mark <- paste0(ifelse(review, "\u2020", ""),
                 ifelse(e$complement_unreliable %in% TRUE, "\u2021", ""))
  out$mark <- ifelse(hide | !nzchar(mark), NA, mark)
  sentence <- NULL
  if (any(zero)) {
    sentence <- zero_sentence(out[zero, , drop = FALSE], keys,
                              e[zero, , drop = FALSE], scale, unit)
  }
  rownames(out) <- NULL
  reasons <- function(rows) {
    unique(stats::na.omit(e$presentation_reason[rows & !zero]))
  }
  structure(out[!zero, , drop = FALSE], exact = sentence, value = value,
            suppressed_reasons = reasons(hide),
            review_reasons = reasons(review & !hide))
}

# The sentence of the zero-event estimates (S4): each cell with its value,
# `n` and the limit of the interval away from the value.
zero_sentence <- function(out, keys, e, scale, unit) {
  cells <- vapply(seq_len(nrow(out)), function(i) {
    paste(vapply(out[i, keys, drop = FALSE], as.character, ""),
          collapse = ", ")
  }, character(1))
  limit <- ifelse(e$estimate == 0, e$ci_high, e$ci_low)
  paste0(term("exact", "sentence"), ": ",
         paste0(cells, " = ", scale(e$estimate), unit, " (n = ",
                format(e$n, big.mark = term("big_mark", "format"),
                       trim = TRUE), "; ",
                term("limit", "sentence"), " ", scale(limit), unit, ")",
                collapse = "; "), ".")
}

# The sentence of the exact estimates of a table of display(), or "".
exact_sentence <- function(d) {
  s <- attr(d, "exact")
  if (is.null(s)) "" else s
}

# Text of each row of a verdict: "enabled", or the reason and its detail.
verdict_text <- function(v) {
  detail <- v$detail
  checks <- v$reason %in% "threshold_not_met"
  detail[checks] <- term_list(v$detail[checks], "check")
  ifelse(v$enabled, term(rep("enabled", nrow(v)), "verdict"),
         paste0(term(v$reason, "verdict_reason"), " (", detail, ")"))
}
