# Exhibits of both reports (docs/design-reports-v3.md, section 5): the
# registry exhibits.csv, the verdict that enables each exhibit, titles
# (R16), notes and marks (R17, R19), figures written to files and the
# appendix of tables. Language-free: every word comes from terms.csv or
# labels.csv. Sourced after _tables.R and _figures.R; may be edited.
#
# An exhibit is built by the one function of _readiness.R or _results.R
# named in its `builder` column. A builder takes the instance (NULL, a
# domain, a nutrient, or a nutrient and a domain, as `repeats` says) and
# returns a list with `table` (a table of display(), or any data frame),
# and optionally `figure` (a ggplot), `rows` (the number of rows of the
# figure, for its height), `note` (lines specific to the exhibit),
# `headers` (column headers, code = label, for codes that are not terms),
# `lead` (sentences printed before the figure or table) and `after`
# (sentences printed after the note).

exhibits <- utils::read.csv("exhibits.csv", stringsAsFactors = FALSE,
                            na.strings = "")
# The exhibits shown, in order: key = list(id, instance); and the headers
# and notes of each, for the appendix.
shown <- list()
built <- list()

# Whether the verdict enables a section, nationally (`domain = NA`) or for
# one domain, and the sentence printed when it does not.
enabled <- function(section, domain = NA) {
  v <- verdict[verdict$section == section & verdict$domain %in% domain, ]
  nrow(v) == 1 && v$enabled
}
disabled_sentence <- function(section, domain = NA) {
  v <- verdict[verdict$section == section & verdict$domain %in% domain, ]
  where <- if (is.na(domain)) {
    term(section, "section")
  } else {
    lab(domain, "domain")
  }
  paste0(where, ": ", verdict_text(v), ".")
}

# The registry row of `id`; an unknown id stops the render.
exhibit_row <- function(id) {
  x <- exhibits[exhibits$id == id, , drop = FALSE]
  if (nrow(x) != 1) {
    template_abort(paste0("Exhibit `", id, "` is not in exhibits.csv once."))
  }
  x
}

# The domain of an instance, for the verdict and the labels: the instance
# itself for `repeats = "domain"`, its second element for
# `"nutrient_domain"`, else none.
instance_domain <- function(x, instance) {
  switch(x$repeats, domain = instance[[1]],
         nutrient_domain = instance[[2]], NA_character_)
}

# The label of an instance, as printed after the exhibit ID.
instance_label <- function(x, instance) {
  switch(x$repeats,
         none = NULL,
         domain = as.character(lab(instance[[1]], "domain")),
         nutrient = as.character(lab(instance[[1]], "nutrient")),
         nutrient_domain = paste(as.character(lab(instance[[1]], "nutrient")),
                                 as.character(lab(instance[[2]], "domain")),
                                 sep = ", "))
}

# Title (R16): "<kind> <ID>. <what>, <unit> (<interval>). <place>,
# <survey>". The title term of the ID may hold `{instance}` and `{level}`;
# place and survey are appended only when set.
exhibit_title <- function(id, instance = NULL, body = NULL) {
  x <- exhibit_row(id)
  if (is.null(body)) body <- x$body
  what <- term(id, "title")
  what <- gsub("{level}", 100 * level, what, fixed = TRUE)
  what <- gsub("{instance}", paste(instance_label(x, instance), collapse = ""),
               what, fixed = TRUE)
  out <- paste0(term(body, "kind"), " ", id, ". ", what)
  where <- c(choices$place, choices$survey)
  if (length(where) > 0) out <- paste0(out, ". ", paste(where, collapse = ", "))
  out
}

# A number of households with the thousands mark of terms.csv.
format_n <- function(n) {
  format(n, big.mark = term("big_mark", "format"), trim = TRUE,
         scientific = FALSE)
}

# A sentence pattern of terms.csv with each `{name}` replaced by the
# argument of that name.
fill <- function(pattern, ...) {
  values <- list(...)
  for (k in names(values)) {
    pattern <- gsub(paste0("{", k, "}"), values[[k]], pattern, fixed = TRUE)
  }
  pattern
}

# Notes of a table of display() (R17), in this order and only when they
# occur: `n` when it is the same in every row (else the table has a
# column); "—" suppressed, with the reasons; "†" flagged for review, with
# the reasons; "‡" complement may be unreliable; then `extra`.
exhibit_note <- function(d, extra = NULL) {
  out <- character(0)
  n <- unique(stats::na.omit(d[["n"]]))
  if (length(n) == 1) {
    out <- sub("{n}", format_n(n), term("n", "note"), fixed = TRUE)
  }
  why <- function(code, reasons) {
    paste0(term(code, "note"), ": ",
           paste(term(reasons, "presentation_reason"), collapse = "; "), ".")
  }
  suppressed <- attr(d, "suppressed_reasons")
  if (length(suppressed) > 0) out <- c(out, why("suppressed", suppressed))
  review <- attr(d, "review_reasons")
  if (length(review) > 0) out <- c(out, why("review", review))
  if (any(grepl("‡", d$mark))) out <- c(out, term("complement", "note"))
  c(out, extra)
}

# Write a figure to figure/<key>.png at a height that grows with its rows
# and print it as an image whose alternative text is its title.
save_figure <- function(g, key, title, rows) {
  dir.create("figure", showWarnings = FALSE)
  file <- file.path("figure", paste0(gsub("[^A-Za-z0-9_]", "_", key),
                                     ".png"))
  ggplot2::ggsave(file, g, width = 7, height = 1.2 + 0.3 * max(rows, 4),
                  dpi = 150)
  cat("![", title, "](", file, ")\n\n", sep = "")
}

# Rows of data of a figure: of the plot, or of its layers when the plot
# has none of its own (the two panels of fig_effect()).
figure_rows <- function(g) {
  if (is.data.frame(g$data)) {
    return(nrow(g$data))
  }
  sum(vapply(g$layers, function(l) {
    if (is.data.frame(l$data)) nrow(l$data) else 0L
  }, integer(1)))
}

# Show one exhibit: ask the verdict, call the builder, store the table and
# the figure under `id` (and the instance), print the title, the
# zero-event sentences (R19), the lead sentences, the figure or the table,
# the notes and the sentences after them. A
# disabled exhibit prints the verdict sentence instead. Returns whether it
# was shown, invisibly.
show_exhibit <- function(id, instance = NULL) {
  x <- exhibit_row(id)
  domain <- instance_domain(x, instance)
  if (!is.na(x$verdict_section) && !enabled(x$verdict_section, domain)) {
    cat(disabled_sentence(x$verdict_section, domain), "\n\n")
    return(invisible(FALSE))
  }
  key <- paste(c(id, instance), collapse = "_")
  # The builder is looked up, and the results stored, where the template
  # was sourced.
  home <- parent.env(environment())
  out <- get(x$builder, mode = "function", envir = home)(instance)
  home$tables[[key]] <- out$table
  home$shown[[key]] <- list(id = id, instance = instance)
  home$built[[key]] <- out[c("headers", "note")]
  title <- exhibit_title(id, instance)
  cat("**", title, "**\n\n", exact_sentence(out$table), "\n\n", sep = "")
  print_sentences(out$lead)
  if (x$body == "figure" && !is.null(out$figure) &&
        figure_rows(out$figure) > 0) {
    home$figures[[key]] <- out$figure
    save_figure(out$figure, key, title,
                if (is.null(out$rows)) figure_rows(out$figure) else out$rows)
  } else if (x$body == "table" && nrow(out$table) > 0) {
    emit_table(print_table(out$table, headers = out$headers))
  }
  print_sentences(exhibit_note(out$table, out$note), sep = "  \n")
  print_sentences(out$after)
  invisible(TRUE)
}

# Print sentences as one paragraph (or lines joined by `sep`); nothing
# when there are none.
print_sentences <- function(x, sep = " ") {
  if (length(x) > 0) cat(paste(x, collapse = sep), "\n\n")
  invisible(NULL)
}

# The appendix of tables (R15): the table of every exhibit shown whose
# registry row says `appendix`, under its ID, in the order shown, with
# the sentence of its exact estimates, its headers and its notes.
show_appendix <- function() {
  for (key in names(shown)) {
    x <- exhibit_row(shown[[key]]$id)
    d <- tables[[key]]
    if (!x$appendix || nrow(d) == 0) next
    cat("**", exhibit_title(x$id, shown[[key]]$instance, body = "table"),
        "**\n\n", exact_sentence(d), "\n\n", sep = "")
    emit_table(print_table(d, headers = built[[key]]$headers))
    print_sentences(exhibit_note(d, built[[key]]$note), sep = "  \n")
  }
  invisible(NULL)
}
