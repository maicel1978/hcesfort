# The exhibit machinery of the templates (inst/report/_exhibits.R): the
# registry, titles (R16, K20), notes and marks (R17), the order inside an
# exhibit (R19, K22), figures written to files, and the appendix (R15).
# docs/design-reports-v3.md, section 5. The builders and the estimates are
# test fixtures, worked out by hand below; no report is knitted.

# The template copied to a temporary folder, with its machinery sourced
# into an environment holding invented choices and a verdict.
exhibit_env <- function(place = NULL, survey = NULL, review = "show",
                        enabled = TRUE, envir = parent.frame()) {
  testthat::skip_if_not_installed("ggplot2")
  testthat::skip_if_not_installed("tinytable")
  dir <- withr::local_tempdir(.local_envir = envir)
  use_report_template(dir, "en")
  withr::local_dir(dir, .local_envir = envir)
  env <- new.env(parent = globalenv())
  env$choices <- list(place = place, survey = survey, review = review)
  env$level <- 0.95
  env$terms <- read_labels("terms.csv")
  env$labels <- read_labels("labels.csv")
  env$template_abort <- function(message) {
    rlang::abort(message, class = c("hcesfort_error_argument",
                                    "hcesfort_error"))
  }
  env$verdict <- data.frame(section = "coverage", domain = NA_character_,
                            enabled = enabled, reason = "missing_input",
                            detail = "vehicles")
  for (f in c("_tables.R", "_figures.R", "_exhibits.R")) sys.source(f, env)
  env$fixture_estimates <- fixture_estimates
  env$coverage_vehicle <- eval(quote(function(instance) {
    d <- display(fixture_estimates(), "vehicle", "acquired")
    list(table = d, figure = fig_interval(d, "acquired", "vehicle", "%", ""),
         note = "A line of this exhibit.")
  }), env)
  env
}

# Four vehicles judged by the presentation standard, n = 1962 each:
# rice presented, its complement unreliable (mark ‡); sugar 0 events
# (sentence); maize flour flagged for review for its degrees of freedom
# (mark †); oil suppressed for its width (dash).
fixture_estimates <- function() {
  data.frame(
    vehicle = c("rice", "sugar", "maize_flour", "oil"), n = 1962,
    estimate = c(0.9, 0, 0.4, 0.5), ci_low = c(0.88, 0, 0.35, 0.3),
    ci_high = c(0.92, 0.002, 0.45, 0.8),
    presentation = c("present", "review", "review", "suppress"),
    presentation_reason = c(NA, "zero_events", "degrees_of_freedom",
                            "absolute_width"),
    complement_unreliable = c(TRUE, FALSE, FALSE, FALSE)
  )
}

test_that("every exhibit of the registry has one row and a known kind", {
  x <- utils::read.csv(system.file("report", "exhibits.csv",
                                   package = "hcesfort"))
  expect_false(anyDuplicated(x$id) > 0)
  expect_true(all(x$body %in% c("figure", "table", "sentence")))
  expect_true(all(x$repeats %in% c("none", "domain", "nutrient",
                                   "nutrient_domain")))
  expect_true(all(x$report %in% c("readiness", "results")))
  expect_true(is.logical(x$appendix))
})

test_that("titles end with place and survey only when set (R16, K20)", {
  env <- exhibit_env()
  expect_identical(
    env$exhibit_title("R1.1"),
    paste("Figure R1.1. Households that acquire each fortification",
          "vehicle, % (95% CI)")
  )
  expect_match(env$exhibit_title("R2.2", "region"), "by Region, %",
               fixed = TRUE)
  expect_match(env$exhibit_title("R3.4", c("iron", "area")), "Iron, Area",
               fixed = TRUE)
  env$choices$place <- "Region X"
  env$choices$survey <- "Survey 2024"
  expect_match(env$exhibit_title("RT1"),
               "^Table RT1\\. .*\\. Region X, Survey 2024$")
  env$choices$place <- NULL
  expect_match(env$exhibit_title("RT1"), "used\\. Survey 2024$")
  expect_error(env$exhibit_title("R9.9"), class = "hcesfort_error_argument")
})

test_that("notes come in the order of R17, each only when it occurs", {
  env <- exhibit_env()
  d <- env$display(fixture_estimates(), "vehicle", "acquired")
  expect_identical(env$exhibit_note(d, "Last."), c(
    "n = 1,962 households",
    "— Suppressed under the presentation standard: interval too wide.",
    "† Flagged for statistical review: too few degrees of freedom.",
    "‡ The complement of the estimate may be unreliable.",
    "Last."
  ))
  # A different n in each row: the table gives it in a column.
  d$n <- c(10, 20, 30)
  expect_false(any(grepl("^n = ", env$exhibit_note(d))))
})

test_that("display() keeps rows, marks values and moves zero events", {
  env <- exhibit_env()
  d <- env$display(fixture_estimates(), "vehicle", "acquired")
  expect_identical(d$vehicle, c("rice", "maize_flour", "oil"))
  expect_identical(d$acquired, c(90, 40, NA))
  expect_identical(d$mark, c("‡", "†", NA))
  expect_match(env$exact_sentence(d), "sugar = 0% (n = 1,962;", fixed = TRUE)
  env$choices$review <- "suppress"
  d <- env$display(fixture_estimates(), "vehicle", "acquired")
  # Flagged estimates are hidden, the zero-event one included.
  expect_identical(d$acquired, c(90, NA, NA, NA))
  expect_identical(env$exact_sentence(d), "")
})

test_that("show_exhibit() prints title, sentence, figure and notes (R19)", {
  env <- exhibit_env()
  out <- utils::capture.output(shown <- env$show_exhibit("R1.1"))
  expect_true(shown)
  text <- paste(out, collapse = "\n")
  at <- function(pattern) regexpr(pattern, text, fixed = TRUE)[[1]]
  expect_gt(at("**Figure R1.1."), 0)
  expect_gt(at("sugar = 0%"), at("**Figure R1.1."))
  expect_gt(at("![Figure R1.1."), at("sugar = 0%"))
  expect_gt(at("n = 1,962 households"), at("![Figure R1.1."))
  expect_gt(at("A line of this exhibit."), at("n = 1,962"))
  expect_true(file.exists(file.path("figure", "R1_1.png")))
  expect_s3_class(env$figures[["R1.1"]], "ggplot")
  expect_identical(nrow(env$tables[["R1.1"]]), 3L)
})

test_that("a disabled exhibit prints its verdict and nothing else", {
  env <- exhibit_env(enabled = FALSE)
  out <- utils::capture.output(shown <- env$show_exhibit("R1.1"))
  expect_false(shown)
  expect_length(env$tables, 0)
  expect_match(paste(out, collapse = " "), "^Coverage")
})

test_that("the appendix prints the table of each figure under its ID", {
  env <- exhibit_env()
  utils::capture.output(env$show_exhibit("R1.1"))
  out <- paste(utils::capture.output(env$show_appendix()), collapse = "\n")
  expect_match(out, "**Table R1.1. Households", fixed = TRUE)
  expect_match(out, "90‡", fixed = TRUE)
})

test_that("fig_effect() draws the two panels of section 6.3", {
  env <- exhibit_env()
  # Two scenarios; the third row lacks its difference and is not drawn.
  d <- data.frame(scenario = c("A", "B", "C"), from = c(60, 60, 60),
                  to = c(40, 55, NA), difference = c(-20, -5, NA),
                  ci_low = c(-25, -9, NA), ci_high = c(-15, -1, NA))
  g <- env$fig_effect(d, "scenario", "%", "", c("Level", "Change"))
  b <- ggplot2::ggplot_build(g)
  expect_identical(levels(b$layout$layout$.panel), c("Level", "Change"))
  points <- ggplot2::layer_data(g, 3)
  expect_identical(nrow(points), 2L)
  expect_identical(sort(points$x), c(40, 55))
  diff <- ggplot2::layer_data(g, 6)
  expect_identical(sort(diff$x), c(-20, -5))
  expect_identical(ggplot2::layer_data(g, 4)$xintercept, 0)
  d$band <- c("x", "y", "y")
  g <- env$fig_effect(d, "scenario", "%", "", c("Level", "Change"),
                      band = "band")
  expect_identical(nrow(ggplot2::ggplot_build(g)$layout$layout), 4L)
  # A zero line in the difference panel of every band.
  expect_identical(nrow(ggplot2::layer_data(g, 4)), 2L)
  # Nothing left to draw: an empty plot, which show_exhibit() skips.
  g <- env$fig_effect(d[3, ], "scenario", "%", "", c("Level", "Change"))
  expect_identical(env$figure_rows(g), 0L)
})

test_that("figure_rows() counts the data of a plot or of its layers", {
  env <- exhibit_env()
  d <- data.frame(scenario = c("A", "B"), from = 60, to = c(40, 55),
                  difference = c(-20, -5), ci_low = c(-25, -9),
                  ci_high = c(-15, -1))
  g <- env$fig_effect(d, "scenario", "%", "", c("Level", "Change"))
  # Two rows in each of the five layers with data, one in the zero line.
  expect_identical(env$figure_rows(g), 11L)
  e <- env$display(fixture_estimates(), "vehicle", "acquired")
  # Sugar (zero events) left for the sentence, oil (suppressed) not drawn.
  expect_identical(env$figure_rows(env$fig_interval(e, "acquired",
                                                    "vehicle", "%", "")),
                   2L)
})

test_that("labels in sentences and missing domain values (V-D23)", {
  env <- exhibit_env()
  expect_identical(env$lower_first(c("Vitamin A", "Iron", "")),
                   c("vitamin A", "iron", ""))
  expect_identical(env$collapse(c("a", "b", "c")), "a, b and c")
  expect_identical(env$collapse("a"), "a")
  file <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("type,parent,code,label,short_label",
               "domain_value,area,urban,Urban area,Urban",
               "domain_value,area,rural,Rural area,"), file)
  env$labels <- read_labels(file)
  x <- env$domain_label(c("rural", NA, "urban"), "area")
  expect_identical(as.character(x), c("Rural area", "No data", "Urban area"))
  expect_identical(levels(x), c("Urban area", "Rural area", "No data"))
  expect_identical(as.character(env$domain_label("urban", "area", TRUE)),
                   "Urban")
})

test_that("print_table() drops an n that is the same in every row (R17)", {
  env <- exhibit_env()
  d <- env$display(fixture_estimates(), "vehicle", "acquired")
  expect_false("n" %in% names(env$print_table(d)))
  d$n <- c(10, 20, 30)
  expect_true("n" %in% names(env$print_table(d)))
})

test_that("axes print the thousands mark of the text (V-D25)", {
  env <- exhibit_env()
  d <- data.frame(kcal = c(1000, 2000, 5000), w = 1)
  g <- env$fig_histogram(d, "kcal", "w", c(500, 6000), 2300, "kcal", "n",
                         bins = 3)
  x <- ggplot2::ggplot_build(g)$layout$panel_params[[1]]$x$get_labels()
  expect_true(any(grepl("^[0-9],[0-9]{3}$", x)))
  # A reference line per panel, at the values of a column.
  e <- env$display(fixture_estimates(), "vehicle", "acquired")
  e$national <- 50
  g <- env$fig_interval(e, "acquired", "vehicle", "%", "", ref = "national")
  expect_identical(ggplot2::layer_data(g, 4)$xintercept, c(50, 50))
})

test_that("fig_histogram() weights the counts; percent axes run to 100", {
  env <- exhibit_env()
  d <- data.frame(kcal = c(1000, 1000, 3000), w = c(1, 2, 5))
  g <- env$fig_histogram(d, "kcal", "w", c(500, 6000), 2300, "kcal", "n",
                         bins = 2)
  expect_identical(sum(ggplot2::layer_data(g, 1)$count), 8)
  e <- env$display(fixture_estimates(), "vehicle", "acquired")
  g <- env$fig_interval(e, "acquired", "vehicle", "%", "", percent = TRUE)
  limits <- ggplot2::ggplot_build(g)$layout$panel_params[[1]]$x$limits
  expect_identical(limits, c(0, 100))
})
