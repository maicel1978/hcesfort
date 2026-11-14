# The results report of the template (inst/report): tests K1, K2, K4 to
# K9, K13 and K16 of docs/design-reports-v2.md, section 9. Knitted on
# hces_example with knitr, as Quarto would.

skip_if_no_knit <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("knitr")
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not_installed("ggplot2")
}

results_langs <- c("en", "es")

# Sentences the tests match, in the language of each report.
say_results <- list(
  en = list(
    exact = "In the sample, the same value in every household",
    region_disabled = "Region: disabled: input absent",
    food_groups_disabled = "Contribution of each food group: disabled"
  ),
  es = list(
    exact = "En la muestra, el mismo valor en todos los hogares",
    region_disabled = "Región: deshabilitada: falta el insumo",
    food_groups_disabled = "Aporte de cada grupo de alimentos: deshabilitada"
  )
)

# Labels of one type of labels.csv of `lang`.
labels_of_type <- function(lang, type) {
  file <- system.file("report", lang, "labels.csv", package = "hcesfort")
  d <- utils::read.csv(file, encoding = "UTF-8", stringsAsFactors = FALSE)
  rows <- d$type == type
  stats::setNames(d$label[rows], d$code[rows])
}

# Label of one code of terms.csv of `lang`.
term_label <- function(lang, code, type) {
  file <- system.file("report", lang, "terms.csv", package = "hcesfort")
  d <- utils::read.csv(file, encoding = "UTF-8", stringsAsFactors = FALSE)
  d$label[d$type == type & d$code == code]
}

# Columns of the tables holding percentages.
percent_columns <- c("acquired", "none", "inadequate", "share", "from", "to",
                     "above_ul")

test_that("the results report knits on hces_example (K1, K4, K9)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- knit_report(lang, "results")
    expect_true(file.exists(file.path(r$dir, "results-sessionInfo.txt")))
    expect_true(all(c("coverage_vehicle", "coverage_group", "quantity",
                      "no_vehicle", "risk", "risk_region", "scenarios",
                      "effects_iron", "ul_scope", "above_ul",
                      "equity_iron_expenditure_group", "food_groups",
                      "reference", "iron_sensitivity") %in% names(r$tables)))
    yaml <- rmarkdown::yaml_front_matter(file.path(r$dir, "results.qmd"))
    expect_identical(names(yaml$params), "lang")
    body <- strsplit(strip_comments(r$md), "\n")[[1]]
    expect_false(any(grepl("^\\s*\\*\\*.*\\*\\*\\s*$", body)), info = lang)
    headings <- grep("^#", body, value = TRUE)
    expect_false(any(grepl("Annex|Anexo", headings)), info = lang)
    expect_false(grepl("Analyst|Analista", strip_comments(r$md),
                       ignore.case = TRUE), info = lang)
  }
})

test_that("no code reaches the results report (K2)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- knit_report(lang, "results")
    body <- strsplit(strip_comments(r$md), "\n")[[1]]
    body <- body[!grepl("^!\\[|^title:|^  lang:", body)]
    text <- paste(body, collapse = "\n")
    expect_false(grepl("[A-Za-z_]+\\(\\)", text), info = lang)
    expect_false(grepl("`", text, fixed = TRUE), info = lang)
    codes <- unlist(lapply(c("labels.csv", "terms.csv"), function(f) {
      d <- utils::read.csv(system.file("report", lang, f,
                                       package = "hcesfort"))
      c(d$code, d$type)
    }))
    codes <- c(codes, "ci_low", "ci_high", "p_inadequate", "conf_level",
               "n_missing", "precision_status", "qty_vehicle_g_d")
    codes <- unique(codes[grepl("_", codes)])
    found <- codes[vapply(codes, function(code) {
      grepl(paste0("\\b", code, "\\b"), text)
    }, logical(1))]
    expect_identical(found, character(0), info = lang)
  }
})

test_that("every figure has axis titles, data and its table (K5)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- knit_report(lang, "results")
    expect_gt(length(r$figures), 0)
    for (id in names(r$figures)) {
      g <- r$figures[[id]]
      expect_s3_class(g, "ggplot")
      expect_true(nzchar(g$labels$x) && nzchar(g$labels$y), info = id)
      expect_gt(nrow(ggplot2::layer_data(g, 2)), 0)
      expect_true(id %in% names(r$tables), info = id)
      cols <- intersect(names(g$data), percent_columns)
      expect_true(all(cols %in% names(r$tables[[id]])), info = id)
      for (col in cols) {
        v <- stats::na.omit(r$tables[[id]][[col]])
        expect_true(all(v >= 0 & v <= 100), info = paste(id, col))
      }
    }
  }
})

test_that("an absent domain leaves one sentence per section (K6)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- knit_report(lang, "results", append = "households$region <- NULL")
    expect_false(any(grepl("region", c(names(r$tables), names(r$figures)))))
    expect_match(r$md, say_results[[lang]]$region_disabled, fixed = TRUE)
  }
})

test_that("the presentation standard marks every estimate (R17, R19)", {
  skip_if_no_knit()
  # Each expenditure quintile has fewer than 450 households: those cells
  # are suppressed for their sample size; every region and area has more.
  # max_small_cells = 1 keeps the quintiles as a domain.
  big_n <- c(paste(
    "presentation_standard$value[presentation_standard$criterion ==",
    "'min_n'] <- 450"
  ), "choices$max_small_cells <- 1")
  for (lang in results_langs) {
    r <- knit_report(lang, "results", append = big_n)
    small <- 0
    for (id in names(r$tables)) {
      d <- r$tables[[id]]
      expect_false("precision_status" %in% names(d), info = id)
      if (is.null(d[["n"]])) next
      values <- intersect(c(percent_columns, "median_g", "difference"),
                          names(d))
      below <- d[["n"]] < 450
      small <- small + sum(below)
      for (col in values) {
        expect_true(all(is.na(d[[col]][below])), info = paste(id, col))
      }
    }
    expect_gt(small, 0)
    for (id in names(r$figures)) {
      g <- r$figures[[id]]
      if (!is.null(g$data[["n"]])) {
        expect_true(all(g$data[["n"]] >= 450), info = id)
      }
    }
    # Upper-level shares of 0 are zero-event estimates: one sentence.
    expect_match(r$md, say_results[[lang]]$exact, fixed = TRUE)
  }
})

test_that("choices$review = 'suppress' hides the flagged estimates (S3)", {
  skip_if_no_knit()
  r <- knit_report("en", "results", append = "choices$review <- 'suppress'")
  expect_false(grepl(say_results$en$exact, r$md, fixed = TRUE))
  for (id in names(r$tables)) {
    expect_true(all(is.na(r$tables[[id]]$mark)), info = id)
  }
})

test_that("choices$vehicles restricts the vehicles (K26)", {
  skip_if_no_knit()
  r <- knit_report("en", "results", append = c(
    "scenarios <- scenarios[scenarios$scenario == 'wheat_flour', ]",
    "choices$vehicles <- c('wheat_flour', 'bread', 'pasta')"
  ))
  shown <- labels_of_type("en", "vehicle")
  kept <- shown[c("wheat_flour", "bread", "pasta")]
  for (id in grep("^coverage_vehicle", names(r$tables), value = TRUE)) {
    expect_setequal(as.character(unique(r$tables[[id]]$vehicle)), kept)
  }
  expect_error(knit_report("en", "results",
                           append = "choices$vehicles <- 'rice'"),
               class = "hcesfort_error_argument")
})

test_that("every scenario is printed by its one label (K8)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- knit_report(lang, "results")
    allowed <- labels_of_type(lang, "scenario")
    objects <- c(r$tables, lapply(r$figures, function(g) g$data))
    for (id in names(objects)) {
      cols <- intersect(c("scenario", "comparator"), names(objects[[id]]))
      for (col in cols) {
        v <- as.character(objects[[id]][[col]])
        expect_true(all(v %in% allowed), info = paste(id, col))
      }
    }
  }
})

test_that("without food groups, section 4 is one sentence (K13)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- knit_report(lang, "results", append = "food_groups <- NULL")
    expect_null(r$tables$food_groups)
    expect_match(r$md, say_results[[lang]]$food_groups_disabled,
                 fixed = TRUE)
    expect_true("risk" %in% names(r$tables))
  }
})

test_that("a scenario may be compared with another scenario (K16)", {
  skip_if_no_knit()
  r <- knit_report(
    "en", "results",
    append = "choices$comparator <- c(plus_maize = 'wheat_flour')"
  )
  scenario <- labels_of_type("en", "scenario")
  for (id in c("effects_iron", "equity_iron_expenditure_group")) {
    d <- r$tables[[id]]
    rows <- d$scenario == scenario[["plus_maize"]]
    expect_true(any(rows), info = id)
    expect_true(all(d$comparator[rows] == scenario[["wheat_flour"]]),
                info = id)
    expect_true(all(d$comparator[!rows] == scenario[["baseline"]]),
                info = id)
  }
  d <- r$tables$effects_iron
  expect_equal(d$from[d$scenario == scenario[["plus_maize"]]],
               d$to[d$scenario == scenario[["wheat_flour"]]])
  expect_identical(r$figures$effects_iron$data$from, d$from)
  for (bad in c("c(plus_maize = 'plus_rice', plus_rice = 'plus_maize')",
                "c(plus_maize = 'plus_maize')",
                "c(plus_maize = 'sugar_only')",
                "c(baseline = 'wheat_flour')", "'wheat_flour'")) {
    expect_error(knit_report("en", "results",
                             append = paste("choices$comparator <-", bad)),
                 class = "hcesfort_error_argument")
  }
})
