# The verdict of the readiness report (D1, docs/design-reports-v3.md,
# section 4.1): the matrix and its paragraph of three sentences, built
# from the verdict and the checks. Sourced by readiness.qmd after
# _readiness.R; do not edit. The sentence patterns live in terms.csv
# (type `sentence`); they state counts and statuses, never a judgement.

verdict_matrix <- function(instance) {
  list(table = verdict_table(verdict),
       headers = domain_headers(choices$domains),
       after = c(supported_sentence(), unsupported_sentence(),
                 left_sentence()))
}

# Sections by rows, national and each domain by columns.
verdict_table <- function(v) {
  cell <- verdict_text(v)
  where <- ifelse(is.na(v$domain), "national", v$domain)
  out <- data.frame(section = term(unique(v$section), "section"))
  for (w in unique(where)) out[[w]] <- cell[where == w]
  out
}

# Headers of the domain columns of the verdict: the domain labels.
domain_headers <- function(d) {
  stats::setNames(as.character(lab(d, "domain")), d)
}

# What the data support: the sections enabled nationally, and the domains
# in which each of them is enabled.
supported_sentence <- function() {
  national <- verdict[is.na(verdict$domain), ]
  on <- national$section[national$enabled]
  if (length(on) == 0) {
    return(term("supported_none", "sentence"))
  }
  out <- fill(term("supported", "sentence"),
              sections = collapse(term(on, "section")))
  full <- Filter(function(d) {
    all(verdict$enabled[verdict$domain %in% d & verdict$section %in% on])
  }, choices$domains)
  if (length(full) == 0) {
    return(out)
  }
  c(out, fill(term("supported_domains", "sentence"),
              domains = collapse(tolower(lab(full, "domain")))))
}

# What they do not support: each section disabled nationally, and each
# domain with a section enabled nationally but not in the domain, with
# the reasons.
unsupported_sentence <- function() {
  text <- verdict_text(verdict)
  national <- is.na(verdict$domain)
  off <- national & !verdict$enabled
  items <- character(0)
  if (any(off)) {
    items <- paste0(term(verdict$section[off], "section"), ", ", text[off])
  }
  on <- verdict$section[national & verdict$enabled]
  for (d in choices$domains) {
    rows <- verdict$domain %in% d & verdict$section %in% on
    by <- paste(term("domain", "needed_by"), tolower(lab(d, "domain")))
    for (t in unique(text[rows & !verdict$enabled])) {
      sections <- verdict$section[rows & text == t]
      if (length(sections) < sum(rows)) {
        by_t <- paste0(by, " (", collapse(term(sections, "section")), ")")
      } else {
        by_t <- by
      }
      items <- c(items, paste0(by_t, ", ", t))
    }
  }
  if (length(items) == 0) {
    return(term("unsupported_none", "sentence"))
  }
  fill(term("unsupported", "sentence"), items = paste(items, collapse = "; "))
}

# What is left: the essential inputs absent; or the foods pending with the
# share of grams and expenditure not linked, and the thresholds not met.
left_sentence <- function() {
  if (!ready) {
    return(fill(term("left_inputs", "sentence"), inputs = collapse(absent)))
  }
  items <- character(0)
  if (nrow(queue) > 0) {
    unlinked <- function(check) pct(1 - checks$value[checks$check == check])
    items <- fill(term("left_foods", "sentence"), n = nrow(queue),
                  grams = unlinked("linked_grams"))
    if (has_expenditure) {
      items <- paste(items, fill(term("left_expenditure", "sentence"),
                                 expenditure = unlinked("linked_expenditure")))
    }
  }
  ct <- format_checks(checks)[checks$met %in% FALSE, ]
  if (nrow(ct) > 0) {
    unmet <- ifelse(is.na(ct$detail), ct$check,
                    paste0(ct$check, " (", ct$detail, ")"))
    items <- c(items, fill(term("left_checks", "sentence"),
                           checks = collapse(unmet)))
  }
  if (length(items) == 0) {
    return(term("left_none", "sentence"))
  }
  fill(term("left", "sentence"), items = paste(items, collapse = "; "))
}
