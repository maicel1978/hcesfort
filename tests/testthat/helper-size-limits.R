# Helpers that measure the size limits of CLAUDE.md on source files.
# They live in the test suite because they are development checks, not part
# of the package.

# Lines of code in `lines`: neither blank nor comment-only.
count_code_lines <- function(lines) {
  sum(!grepl("^\\s*(#.*)?$", lines))
}

# TRUE when a top-level expression assigns a function to a name.
is_function_definition <- function(expr) {
  is.call(expr) &&
    as.character(expr[[1]]) %in% c("<-", "=") &&
    is.call(expr[[3]]) &&
    identical(expr[[3]][[1]], as.name("function"))
}

# Body length of every top-level function of one file, in lines of code.
# The lines holding the opening and closing braces are not counted.
function_body_lengths <- function(path) {
  exprs <- parse(path, keep.source = TRUE)
  src <- readLines(path, warn = FALSE)
  refs <- attr(exprs, "srcref")
  out <- integer(0)
  for (i in seq_along(exprs)) {
    if (!is_function_definition(exprs[[i]])) next
    body_ref <- attr(exprs[[i]][[3]], "srcref")[[2]]
    if (is.null(body_ref)) body_ref <- refs[[i]]
    span <- src[seq(body_ref[1], body_ref[3])]
    inner <- if (length(span) > 2) span[-c(1, length(span))] else character(0)
    out[[as.character(exprs[[i]][[2]])]] <- count_code_lines(inner)
  }
  out
}

# Source files of the package, or NULL when they are not reachable (as in
# R CMD check, which tests the installed package).
package_r_files <- function() {
  dir_r <- testthat::test_path("..", "..", "R")
  if (!dir.exists(dir_r)) {
    return(NULL)
  }
  list.files(dir_r, pattern = "\\.[Rr]$", full.names = TRUE)
}
