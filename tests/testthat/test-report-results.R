# The results report of the template (inst/report): tests K1, K2, K4 to
# K9, K13 and K16 of docs/design-reports-v2.md, section 9. Knitted on
# hces_example with knitr, as Quarto would.

skip_if_no_knit <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("knitr")
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not_installed("ggplot2")
}

# The Spanish results report is step 12c.12.
results_langs <- "en"

# Sentences the tests match, in the language of each report.
say_results <- list(
  en = list(
    exact = "Same value in every household",
    region_disabled = "Region: disabled: input absent",
    food_groups_disabled = "Contribution of each food group: disabled"
  )
)

# Labels of one type of labels.csv of `lang`.
labels_of_type <- function(lang, type) {
  file <- system.file("report", lang, "labels.csv", package = "hcesfort")
  d <- utils::read.csv(file, encoding = "UTF-8", stringsAsFactors = FALSE)
  d$label[d$type == type]
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

test_that("small cells print a dash and exact estimates a sentence (K7)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- knit_report(lang, "results")
    exact <- term_label(lang, "exact", "precision_status")
    small <- 0
    for (id in names(r$tables)) {
      d <- r$tables[[id]]
      if (is.null(d[["n"]])) next
      values <- intersect(c(percent_columns, "median_g", "difference"),
                          names(d))
      below <- d[["n"]] < 8
      small <- small + sum(below)
      for (col in values) {
        expect_true(all(is.na(d[[col]][below])), info = paste(id, col))
      }
      if (id != "food_groups") {
        expect_false(any(d$precision_status %in% exact), info = id)
      }
    }
    expect_gt(small, 0)
    for (id in names(r$figures)) {
      g <- r$figures[[id]]
      if (!is.null(g$data[["n"]])) {
        expect_true(all(g$data[["n"]] >= 8), info = id)
      }
    }
    expect_match(r$md, say_results[[lang]]$exact, fixed = TRUE)
  }
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
    append = "choices$comparator <- c(flour_and_sugar = 'flour')"
  )
  scenario <- labels_of_type("en", "scenario")
  names(scenario) <- c("baseline", "flour", "flour_and_sugar")
  for (id in c("effects_iron", "equity_iron_expenditure_group")) {
    d <- r$tables[[id]]
    rows <- d$scenario == scenario[["flour_and_sugar"]]
    expect_true(any(rows), info = id)
    expect_true(all(d$comparator[rows] == scenario[["flour"]]), info = id)
    expect_true(all(d$comparator[!rows] == scenario[["baseline"]]),
                info = id)
  }
  d <- r$tables$effects_iron
  expect_equal(d$from[d$scenario == scenario[["flour_and_sugar"]]],
               d$to[d$scenario == scenario[["flour"]]])
  expect_identical(r$figures$effects_iron$data$from, d$from)
  for (bad in c("c(flour = 'flour_and_sugar', flour_and_sugar = 'flour')",
                "c(flour = 'flour')", "c(flour = 'sugar_only')",
                "c(baseline = 'flour')", "'flour'")) {
    expect_error(knit_report("en", "results",
                             append = paste("choices$comparator <-", bad)),
                 class = "hcesfort_error_argument")
  }
})
