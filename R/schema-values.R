# Value checks of the schema engine: missing values where they cannot be,
# numbers outside their interval or not finite, text outside its
# vocabulary. Only impossible values are rejected (design section 1).

# All present columns must satisfy their rules.
check_values <- function(x, schema, table, call) {
  present <- schema[schema$column %in% names(x), ]
  problems <- lapply(seq_len(nrow(present)), function(i) {
    column_problems(x[[present$column[[i]]]], present[i, ])
  })
  problems <- dplyr::bind_rows(problems)
  if (nrow(problems) == 0) {
    return(invisible(x))
  }
  bullets <- mapply(function(col, what, rows) {
    problem_bullet(paste0("`", col, "` ", what), rows)
  }, problems$column, problems$what, problems$rows)
  rows <- sort(unique(unlist(problems$rows)))
  abort_hcesfort("value", c(
    "{.arg {table}} has impossible or missing values.",
    rlang::set_names(cli_escape(bullets), rep("x", length(bullets))),
    "i" = "See {.code hces_schema(\"{table}\")} for the rule of each column."
  ), table = table, columns = unique(problems$column), rows = rows,
  n = length(rows), call = call)
}

# Problems of one column as a tibble (column, what, rows), one row each.
column_problems <- function(v, spec) {
  found <- list(
    "is missing" = if (!spec$na) which(is.na(v)),
    "is not finite" = if (spec$type == "number") which(is.infinite(v)),
    "is outside its interval" = if (!is.na(spec$bounds)) {
      which(!in_bounds(v, spec$bounds))
    },
    "is outside its vocabulary" = if (!is.null(spec$values[[1]])) {
      which(!is.na(v) & !v %in% spec$values[[1]])
    }
  )
  found <- found[lengths(found) > 0]
  what <- names(found)
  ruled <- what %in% c("is outside its interval", "is outside its vocabulary")
  what[ruled] <- paste(what[ruled], rule_text(spec))
  dplyr::tibble(
    column = rep(spec$column, length(found)), what = what,
    rows = unname(found)
  )
}

# Parse an interval such as "[0, 1]" or "(0, Inf)".
parse_bounds <- function(bounds) {
  parts <- strsplit(gsub("[][() ]", "", bounds), ",", fixed = TRUE)[[1]]
  list(
    lower = as.numeric(parts[[1]]), upper = as.numeric(parts[[2]]),
    lower_closed = startsWith(bounds, "["),
    upper_closed = endsWith(bounds, "]")
  )
}

# TRUE where `v` lies in the interval; NA and infinite values are TRUE
# (they are reported by their own checks).
in_bounds <- function(v, bounds) {
  b <- parse_bounds(bounds)
  above <- if (b$lower_closed) v >= b$lower else v > b$lower
  below <- if (b$upper_closed) v <= b$upper else v < b$upper
  is.na(v) | is.infinite(v) | (above & below)
}

# Human-readable rule of one schema row, used in messages and in
# hces_schema(): "(> 0)", "(in [0, 1])", "(female, male)".
rule_text <- function(spec) {
  if (!is.null(spec$values[[1]])) {
    return(paste0("(", paste(spec$values[[1]], collapse = ", "), ")"))
  }
  if (is.na(spec$bounds)) {
    return("")
  }
  b <- parse_bounds(spec$bounds)
  if (is.infinite(b$upper)) {
    return(paste0("(", if (b$lower_closed) ">= " else "> ", b$lower, ")"))
  }
  paste0("(in ", spec$bounds, ")")
}
