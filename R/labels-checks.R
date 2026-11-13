# Schemas and checks of the label table and the decisions table.
# Design: docs/design-reports-v2.md, sections 4 and 5.6.

schema_labels <- function() {
  new_schema(
    "labels", c("type", "parent", "code"),
    schema_col("type", "text", "what the code is (nutrient, scenario...)"),
    schema_col("parent", "text", paste(
      "the domain a `domain_value` belongs to; missing for other types"
    ), na = TRUE),
    schema_col("code", "text", "the value as it appears in the tables"),
    schema_col("label", "text", "what is printed; not empty")
  )
}

schema_decisions <- function() {
  new_schema(
    "decisions", "decision",
    schema_col("decision", "text", "what was decided; unique"),
    schema_col("choice", "text", "the option chosen"),
    schema_col("evidence", "text", "the data that support the choice")
  )
}

# A CSV file read as UTF-8 text: every column character, empty cells
# missing, nothing else converted.
read_text_table <- function(file, call = rlang::caller_env()) {
  if (!rlang::is_string(file) || !file.exists(file)) {
    abort_hcesfort("argument", c(
      "{.arg file} must be the path of an existing CSV file.",
      "x" = "Not found: {.file {as.character(file)[1]}}."
    ), arg = "file", call = call)
  }
  x <- utils::read.csv(file, colClasses = "character", na.strings = "",
                       fileEncoding = "UTF-8", check.names = FALSE,
                       strip.white = TRUE)
  dplyr::as_tibble(x)
}

# `x` checked against the label schema and its two cross-row rules.
check_labels <- function(x, call = rlang::caller_env()) {
  check_schema(x, schema_labels(), call = call)
  x <- dplyr::as_tibble(x)[c("type", "parent", "code", "label")]
  x$parent <- as.character(x$parent)
  bad_parent <- which((x$type == "domain_value") == is.na(x$parent))
  group <- paste(x$type, x$parent, sep = "\r")
  repeated <- which(duplicated(paste(group, x$label, sep = "\r")))
  empty <- which(!nzchar(trimws(x$label)))
  rows <- sort(unique(c(bad_parent, repeated, empty)))
  if (length(rows) > 0) {
    bullets <- c(
      problem_bullet("`parent` set or missing against `type`", bad_parent),
      problem_bullet("label repeated within `type` and `parent`", repeated),
      problem_bullet("empty label", empty)
    )
    abort_hcesfort("value", c(
      "{.arg labels} has impossible values.",
      rlang::set_names(cli_escape(bullets), rep("x", length(bullets))),
      "i" = "`parent` is the domain of a `domain_value` and missing
      otherwise; each code needs its own label."
    ), table = "labels", columns = c("parent", "label"), rows = rows,
    n = length(rows), call = call)
  }
  x
}

# Abort with `hcesfort_error_join` listing every code of `needed` without
# a label, with the lines to add to the file.
check_needed_labels <- function(labels, needed, call = rlang::caller_env()) {
  want <- needed_table(needed, call)
  have <- paste(labels$type, labels$parent, labels$code, sep = "\r")
  missing <- want[!paste(want$type, want$parent, want$code, sep = "\r") %in%
                    have, ]
  if (nrow(missing) == 0) {
    return(invisible(TRUE))
  }
  lines <- paste0(missing$type, ",", ifelse(is.na(missing$parent), "",
                                            missing$parent),
                  ",", missing$code, ",<label>")
  n <- nrow(missing)
  abort_hcesfort("join", c(
    "{n} code{?s} {?has/have} no label.",
    "i" = "Add {cli::qty(n)}{?this line/these lines} to the label file:",
    rlang::set_names(cli_escape(lines), rep(" ", n))
  ), table = "labels", other = "needed", columns = "code", n = n,
  missing = missing, call = call)
}

# The codes of `needed` as a tibble (type, parent, code).
needed_table <- function(needed, call) {
  if (!is.list(needed) || is.null(names(needed)) || any(names(needed) == "")) {
    abort_hcesfort("argument", c(
      "{.arg needed} must be a named list, type to codes."
    ), arg = "needed", call = call)
  }
  rows <- lapply(names(needed), function(type) {
    v <- needed[[type]]
    if (type == "domain_value" && is.list(v)) {
      return(dplyr::bind_rows(lapply(names(v), function(d) {
        dplyr::tibble(type = type, parent = d,
                      code = unique(as.character(v[[d]])))
      })))
    }
    dplyr::tibble(type = type, parent = NA_character_,
                  code = unique(as.character(v)))
  })
  out <- dplyr::bind_rows(dplyr::tibble(type = character(),
                                        parent = character(),
                                        code = character()), rows)
  out[!is.na(out$code), ]
}

#' Read the decisions taken with the data
#'
#' The data readiness report lists the decisions the analyst took with the
#' data (an outlier rule, a unit factor, a threshold), each with the option
#' chosen and the evidence. `read_decisions()` reads and checks the file.
#'
#' @param file Path of a CSV file in UTF-8 with the columns `decision`,
#'   `choice` and `evidence` ([hces_schema()]`("decisions")`): text, no
#'   empty cell, at least one row, `decision` unique.
#' @returns The table as a tibble of text columns.
#' @seealso [read_labels()].
#' @examples
#' f <- tempfile(fileext = ".csv")
#' writeLines(c(
#'   "decision,choice,evidence",
#'   "Outliers,Kept,Fewer than 1% of records above the 99th percentile"
#' ), f)
#' read_decisions(f)
#' @export
read_decisions <- function(file) {
  check_required()
  x <- read_text_table(file)
  check_schema(x, schema_decisions())
  if (nrow(x) == 0) {
    abort_hcesfort("value", c(
      "{.arg decisions} has no rows.",
      "i" = "Write at least one decision taken with the data."
    ), table = "decisions", columns = "decision", rows = integer(0),
    n = 0L)
  }
  x[c("decision", "choice", "evidence")]
}
