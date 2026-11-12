# The schema engine: a schema is a tibble with one row per column of a
# table, and the attributes `table` and `key`. Checks run in three stages
# (columns and types, keys, values); each stage reports all its problems in
# one classed error. Design: docs/design-task2.md, sections 1, 2 and 5.

# Types a column of a schema can have.
schema_types <- c("id", "number", "flag", "text")

# One row of a schema. `bounds` is an interval such as "[0, 1]" or
# "(0, Inf)"; `values` is the vocabulary of a text column.
schema_col <- function(column, type, description, required = TRUE,
                       na = FALSE, bounds = NA_character_, values = NULL) {
  dplyr::tibble(
    column = column, type = type, required = required, na = na,
    bounds = bounds, values = list(values), description = description
  )
}

# A schema from rows built by schema_col().
new_schema <- function(table, key, ...) {
  schema <- dplyr::bind_rows(...)
  attr(schema, "table") <- table
  attr(schema, "key") <- key
  schema
}

# Run the three stages of checks. Returns `x` invisibly.
check_schema <- function(x, schema, call = rlang::caller_env()) {
  table <- attr(schema, "table")
  if (!is.data.frame(x)) {
    abort_hcesfort("schema", c(
      "{.arg {table}} must be a data frame.",
      "x" = "It has class {.cls {class(x)}}."
    ), table = table, columns = character(0), call = call)
  }
  check_columns(x, schema, table, call)
  check_types(x, schema, table, call)
  check_key(x, schema, table, call)
  check_values(x, schema, table, call)
  invisible(x)
}

# Required columns must be present.
check_columns <- function(x, schema, table, call) {
  missing <- setdiff(schema$column[schema$required], names(x))
  if (length(missing) == 0) {
    return(invisible(x))
  }
  abort_hcesfort("schema", c(
    "{.arg {table}} lacks {length(missing)} required column{?s}.",
    "x" = "Missing: {.field {missing}}.",
    "i" = "See {.code hces_schema(\"{table}\")} for the columns it needs."
  ), table = table, columns = missing, call = call)
}

# Present columns must have the type of the schema.
check_types <- function(x, schema, table, call) {
  present <- schema[schema$column %in% names(x), ]
  ok <- mapply(type_ok, x[present$column], present$type)
  if (all(ok)) {
    return(invisible(x))
  }
  bad <- present[!ok, ]
  bullets <- mapply(type_bullet, bad$column, bad$type, x[bad$column])
  abort_hcesfort("schema", c(
    "{.arg {table}} has {nrow(bad)} column{?s} of the wrong type.",
    rlang::set_names(cli_escape(bullets), "x"),
    "i" = paste(
      "id: text or whole numbers; number: numeric; flag: logical;",
      "text: character. Convert factors with {.fn as.character}."
    )
  ), table = table, columns = bad$column, call = call)
}

# TRUE when vector `v` has schema type `type`. A column that is entirely
# a logical NA (as `data.frame(x = NA)` makes it) fits any type.
type_ok <- function(v, type) {
  if (is.factor(v)) {
    return(FALSE)
  }
  if (is.logical(v) && all(is.na(v))) {
    return(TRUE)
  }
  switch(type,
    id = is.character(v) || is.integer(v) ||
      (is.double(v) && all(is.na(v) | v == trunc(v))),
    number = is.numeric(v),
    flag = is.logical(v),
    text = is.character(v)
  )
}

# Message bullet for one column of the wrong type.
type_bullet <- function(column, type, v) {
  got <- if (is.double(v) && type == "id") "double with fractions" else
    class(v)[[1]]
  paste0("`", column, "` must be ", type, ", not ", got, ".")
}

# Key columns must be unique together, and complete except in the key
# columns whose schema accepts a missing value (in `unit_factors`, a missing
# `food_code` means "every food" and is a value of the key). Optional key
# columns absent from `x` are left out of the key.
check_key <- function(x, schema, table, call) {
  key <- intersect(attr(schema, "key"), names(x))
  strict <- intersect(key, schema$column[!schema$na])
  complete <- stats::complete.cases(x[strict])
  rows_na <- which(!complete)
  rows_dup <- which(duplicated(x[key]) & complete)
  if (length(rows_na) + length(rows_dup) == 0) {
    return(invisible(x))
  }
  bullets <- c(
    problem_bullet("missing key", rows_na),
    problem_bullet("duplicated key", rows_dup)
  )
  rows <- sort(union(rows_na, rows_dup))
  abort_hcesfort("key", c(
    "The key ({.field {key}}) of {.arg {table}} must be unique and complete.",
    rlang::set_names(cli_escape(bullets), rep("x", length(bullets))),
    "i" = "Every row needs its own key; a row number is enough."
  ), table = table, columns = key, rows = rows, n = length(rows),
  call = call)
}

# A bullet "<what>: <n> rows (rows 1, 2, 3, 4, 5, ...)", or nothing.
problem_bullet <- function(what, rows) {
  if (length(rows) == 0) {
    return(character(0))
  }
  shown <- paste(utils::head(rows, 5), collapse = ", ")
  more <- if (length(rows) > 5) ", ..." else ""
  paste0(what, ": ", length(rows), " row", if (length(rows) > 1) "s",
         " (", shown, more, ")")
}

# Double the braces of a string so cli prints it literally.
cli_escape <- function(x) {
  gsub("([{}])", "\\1\\1", x)
}
