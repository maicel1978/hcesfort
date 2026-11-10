# Fixtures: small source files written to a temporary directory, with the
# expected counts worked out by hand in each test.

write_fixture <- function(lines) {
  path <- tempfile(fileext = ".R")
  writeLines(lines, path)
  path
}

test_that("count_code_lines ignores blank and comment-only lines", {
  # 2 code lines; 1 blank, 1 indented comment, 1 whitespace-only.
  lines <- c("x <- 1", "", "  # a comment", "   ", "y <- 2 # trailing")
  expect_identical(count_code_lines(lines), 2L)
  expect_identical(count_code_lines(character(0)), 0L)
})

test_that("function_body_lengths counts the lines inside the braces", {
  path <- write_fixture(c(
    "f <- function(x) {",   # brace line: not counted
    "  # comment",          # not counted
    "  y <- x + 1",         # 1
    "",                     # not counted
    "  y * 2",              # 2
    "}",
    "g = function() {",
    "  1",                  # 1
    "}",
    "constant <- 3"         # not a function
  ))
  expect_identical(function_body_lengths(path), c(f = 2L, g = 1L))
})

test_that("function_body_lengths handles one-line functions and empty files", {
  one_line <- write_fixture("h <- function(x) x + 1")
  expect_identical(function_body_lengths(one_line), c(h = 0L))
  empty <- write_fixture("# only a comment")
  expect_length(function_body_lengths(empty), 0L)
})

test_that("a function one line over the limit is measured as 41", {
  # 41 code lines between the braces.
  long <- write_fixture(c("f <- function() {", rep("  1", 41), "}"))
  expect_identical(function_body_lengths(long), c(f = 41L))
})

test_that("function_body_lengths fails on a file that does not parse", {
  broken <- write_fixture("f <- function( {")
  expect_error(function_body_lengths(broken))
})

test_that("functions in R/ have at most 40 lines of body", {
  files <- package_r_files()
  skip_if(is.null(files), "Package sources not available (installed package).")
  lengths <- unlist(lapply(unname(files), function_body_lengths))
  too_long <- lengths[lengths > 40L]
  expect_identical(as.character(names(too_long)), character(0))
})

test_that("files in R/ have at most 300 lines", {
  files <- package_r_files()
  skip_if(is.null(files), "Package sources not available (installed package).")
  n_lines <- vapply(files, function(f) length(readLines(f, warn = FALSE)), 1L)
  too_long <- basename(files)[n_lines > 300L]
  expect_identical(too_long, character(0))
})
