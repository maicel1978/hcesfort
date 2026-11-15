# The results report of the template (inst/report): tests K1, K2, K4, K6,
# K8, K9, K13 and K16 of docs/design-reports-v2.md, section 9, and K19 to
# K26 of docs/design-reports-v3.md, section 10. Knitted on hces_example
# with knitr, as Quarto would. Tables and figures are stored under their
# exhibit ID (exhibits.csv), with the instance where the exhibit repeats.

results_langs <- c("en", "es")

# Sentences the tests match, in the language of each report.
say_results <- list(
  en = list(
    exact = "In the sample, the same value in every household",
    ul_zero = "no household exceeds the upper level of",
    region_disabled = "Region: disabled: input absent",
    food_groups_disabled = "Contribution of each food group: disabled",
    no_data = "No data", no_content = "No zinc from: "
  ),
  es = list(
    exact = "En la muestra, el mismo valor en todos los hogares",
    ul_zero = "ningún hogar supera el nivel máximo de",
    region_disabled = "Región: deshabilitada: falta el insumo",
    food_groups_disabled = "Aporte de cada grupo de alimentos: deshabilitada",
    no_data = "Sin dato", no_content = "Sin aporte de zinc: "
  )
)

# The report of each language on the shipped inputs, knitted once for the
# tests of this file that change nothing.
shipped_results <- local({
  cache <- list()
  function(lang) {
    if (is.null(cache[[lang]])) {
      cache[[lang]] <<- knit_report(lang, "results",
                                    envir = testthat::teardown_env())
    }
    cache[[lang]]
  }
})

# Labels (or short labels) of one type of labels.csv of `lang`.
labels_of_type <- function(lang, type, short = FALSE) {
  file <- system.file("report", lang, "labels.csv", package = "hcesfort")
  d <- utils::read.csv(file, encoding = "UTF-8", stringsAsFactors = FALSE,
                       na.strings = "")
  rows <- d$type == type
  shown <- d$label[rows]
  if (short) shown <- ifelse(is.na(d$short_label[rows]), shown,
                             d$short_label[rows])
  stats::setNames(shown, d$code[rows])
}

# The word that opens a title ("Figure", "Table") in `lang`.
kind_label <- function(lang, body) {
  file <- system.file("report", lang, "terms.csv", package = "hcesfort")
  d <- utils::read.csv(file, encoding = "UTF-8", stringsAsFactors = FALSE)
  d$label[d$type == "kind" & d$code == body]
}

# Lines of the Markdown that are titles of exhibits.
title_lines <- function(md) {
  lines <- strsplit(md, "\n")[[1]]
  grep("^\\*\\*(Figure|Table|Figura|Cuadro) [A-Z]+[0-9.]*\\. ", lines,
       value = TRUE)
}

# Columns of the tables holding percentages.
percent_columns <- c("acquired", "none", "inadequate", "share", "from", "to",
                     "above_ul")

test_that("the results report knits on hces_example (K1, K4, K9)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- shipped_results(lang)
    expect_true(file.exists(file.path(r$dir, "results-sessionInfo.txt")))
    expect_true(all(c(
      "R0", "R1.1", "R1.2", "R1.3", "R1.4_region", "R1.4_expenditure_group",
      "R2.1", "R2.2_region", "R3.1", "R3.2_iron", "R3.3",
      "R3.4_iron_expenditure_group", "R4.1", "RT1", "RT2", "RT3"
    ) %in% names(r$tables)), info = lang)
    expect_false(any(c("R3.2_energy", "R3.4_iron_region") %in%
                       names(r$tables)))
    yaml <- rmarkdown::yaml_front_matter(file.path(r$dir, "results.qmd"))
    expect_identical(names(yaml$params), "lang")
    expect_false(grepl("Analyst|Analista", strip_comments(r$md),
                       ignore.case = TRUE), info = lang)
  }
})

test_that("no code reaches the results report (K2)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- shipped_results(lang)
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
               "n_missing", "presentation", "qty_vehicle_g_d")
    codes <- unique(codes[grepl("_", codes)])
    found <- codes[vapply(codes, function(code) {
      grepl(paste0("\\b", code, "\\b"), text)
    }, logical(1))]
    expect_identical(found, character(0), info = lang)
  }
})

test_that("each figure has its table, its interval and the appendix (K19)", {
  skip_if_no_knit()
  registry <- utils::read.csv(system.file("report", "exhibits.csv",
                                          package = "hcesfort"))
  for (lang in results_langs) {
    r <- shipped_results(lang)
    expect_gt(length(r$figures), 0)
    titles <- title_lines(r$md)
    for (key in names(r$figures)) {
      id <- sub("_.*$", "", key)
      g <- r$figures[[key]]
      expect_true(registry$appendix[registry$id == id], info = key)
      expect_true(key %in% names(r$tables), info = key)
      expect_true(nzchar(g$labels$x) && nzchar(g$labels$y), info = key)
      geoms <- vapply(g$layers, function(l) class(l$geom)[1], "")
      dumbbell <- id %in% c("R3.2", "R3.4") && "GeomSegment" %in% geoms
      expect_true("GeomLinerange" %in% geoms || dumbbell, info = key)
      # In the body as a figure, in the appendix as a table.
      for (body in c("figure", "table")) {
        start <- paste0("**", kind_label(lang, body), " ", id, ". ")
        expect_true(any(startsWith(titles, start)), info = paste(key, body))
      }
      for (col in intersect(names(r$tables[[key]]), percent_columns)) {
        v <- stats::na.omit(r$tables[[key]][[col]])
        expect_true(all(v >= 0 & v <= 100), info = paste(key, col))
      }
    }
  }
})

test_that("titles end with place and survey only when set (K20)", {
  skip_if_no_knit()
  r <- knit_report("en", "results", append = c(
    "choices$place <- 'Region X'", "choices$survey <- 'Survey 2024'"
  ))
  titles <- title_lines(r$md)
  expect_gt(length(titles), 20)
  expect_true(all(endsWith(titles, ". Region X, Survey 2024**")))
  titles <- title_lines(shipped_results("en")$md)
  expect_false(any(grepl("[.,;:]\\s*\\*\\*$", titles)))
})

test_that("no precision column; n in a note or a column (K21, R17)", {
  skip_if_no_knit()
  reference <- c("R3.1", "RT1", "RT2")
  for (lang in results_langs) {
    r <- shipped_results(lang)
    for (key in names(r$tables)) {
      d <- r$tables[[key]]
      expect_false(any(c("precision", "precision_status", "presentation") %in%
                         names(d)), info = key)
      if (!sub("_.*$", "", key) %in% reference) {
        expect_true("n" %in% names(d), info = key)
      }
    }
    expect_match(r$md, "n = 1,928", fixed = TRUE)
  }
})

test_that("a zero-event sentence follows the title of its exhibit (K22)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    lines <- strsplit(shipped_results(lang)$md, "\n")[[1]]
    lines <- lines[nzchar(trimws(lines))]
    at <- which(startsWith(lines, say_results[[lang]]$exact))
    expect_gt(length(at), 0)
    expect_true(all(grepl("^\\*\\*(Figure|Table|Figura|Cuadro) ",
                          lines[at - 1])), info = lang)
  }
})

test_that("a group without content is in the note, not in a row (K23)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- shipped_results(lang)
    d <- r$tables$R4.1
    unclassified <- labels_of_type(lang, "food_group")[["unclassified"]]
    expect_false(unclassified %in% d$food_group)
    note <- regmatches(r$md, regexpr(paste0(say_results[[lang]]$no_content,
                                            "[^.\n]+"), r$md))
    expect_length(note, 1)
    zinc <- labels_of_type(lang, "nutrient")[["zinc"]]
    groups <- labels_of_type(lang, "food_group")
    in_note <- groups[vapply(groups, function(g) {
      grepl(tolower(g), tolower(note), fixed = TRUE)
    }, logical(1))]
    expect_gt(length(in_note), 0)
    expect_false(any(in_note %in% d$food_group[d$nutrient == zinc]))
  }
})

test_that("the upper-level zeros are one sentence, not points (K24)", {
  skip_if_no_knit()
  # Independent count: households with an estimated intake above the UL
  # of each nutrient, under the scenarios that add it.
  e <- hces_example
  n <- nutrient_registry(e$nutrients)
  g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
  b <- unfortified_baseline(e$composition, e$enrichment, n)
  afe <- adult_equivalents(
    e$members, reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
    weight_kg = c(female = 55, male = 65), pal = 1.76
  )
  intake <- apparent_intake(link_composition(g, e$crosswalk, b, n), afe,
                            e$households)
  use <- vehicle_coverage(g, e$vehicles, afe, e$households)
  s <- apply_scenario(intake, use, e$scenarios,
                      compliance_model = "average_content")
  ul <- above_ul(s, ref_requirements, min_coverage = 0.8,
                 min_records_used = 0.8)
  pairs <- paste(e$scenarios$scenario, e$scenarios$nutrient)
  ul <- ul[paste(ul$scenario, ul$nutrient) %in% pairs, ]
  above <- dplyr::coalesce(ul$above_ul_total, ul$above_ul_added)
  any_above <- tapply(above %in% TRUE, ul$nutrient, any)
  none <- names(any_above)[!any_above]
  expect_identical(none, "zinc")
  for (lang in results_langs) {
    r <- shipped_results(lang)
    nutrient <- labels_of_type(lang, "nutrient")
    sentence <- regmatches(r$md, regexpr(paste0(say_results[[lang]]$ul_zero,
                                                "[^(]+"), r$md))
    expect_length(sentence, 1)
    named <- names(nutrient)[vapply(nutrient, function(x) {
      grepl(paste0("\\b", tolower(x), "\\b"), tolower(sentence))
    }, logical(1))]
    expect_identical(named, none, info = lang)
    expect_false(nutrient[["zinc"]] %in% r$tables$R3.3$nutrient)
    expect_true(all(r$figures$R3.3$data$above_ul > 0))
  }
})

test_that("figures print short labels, tables labels (K25, K8)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- shipped_results(lang)
    long <- labels_of_type(lang, "scenario")
    short <- labels_of_type(lang, "scenario", short = TRUE)
    for (key in names(r$tables)) {
      for (col in intersect(c("scenario", "comparator"),
                            names(r$tables[[key]]))) {
        v <- as.character(r$tables[[key]][[col]])
        expect_true(all(v %in% long), info = paste(lang, key, col))
      }
    }
    for (key in names(r$figures)) {
      g <- r$figures[[key]]
      data <- if (is.data.frame(g$data)) g$data else g$layers[[1]]$data
      if (!is.null(data$scenario)) {
        v <- as.character(data$scenario)
        expect_true(all(v %in% short), info = paste(lang, key))
      }
    }
    sc <- r$tables$R3.1
    codes <- as.character(hces_example$scenarios$scenario)
    expect_identical(as.character(sc$abbreviation), unname(short[codes]))
    iron <- sc$nutrient == labels_of_type(lang, "nutrient")[["iron"]]
    expect_false(anyNA(sc$compound_form[iron]))
    expect_false(any(sc$compound_form %in% c("—", "")))
  }
})

test_that("choices$vehicles restricts section 1 (K26)", {
  skip_if_no_knit()
  r <- knit_report("en", "results", append = c(
    "scenarios <- scenarios[scenarios$scenario == 'wheat_flour', ]",
    "choices$vehicles <- c('wheat_flour', 'bread', 'pasta')"
  ))
  kept <- labels_of_type("en", "vehicle")[c("wheat_flour", "bread", "pasta")]
  expect_setequal(as.character(r$tables$R1.1$vehicle), kept)
  expect_error(knit_report("en", "results",
                           append = "choices$vehicles <- 'rice'"),
               class = "hcesfort_error_argument")
})

test_that("a missing domain value has its own label (V-D23)", {
  skip_if_no_knit()
  for (lang in results_langs) {
    r <- shipped_results(lang)
    for (key in grep("expenditure_group$", names(r$tables), value = TRUE)) {
      v <- r$tables[[key]]$domain_value
      expect_false(anyNA(v), info = key)
    }
    expect_true(say_results[[lang]]$no_data %in%
                  r$tables$R2.2_expenditure_group$domain_value)
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
  r <- knit_report("en", "results", append = big_n)
  small <- 0
  for (key in names(r$tables)) {
    d <- r$tables[[key]]
    if (is.null(d[["n"]])) next
    values <- intersect(c(percent_columns, "median_g", "difference"),
                        names(d))
    below <- d[["n"]] < 450
    small <- small + sum(below)
    for (col in values) {
      expect_true(all(is.na(d[[col]][below])), info = paste(key, col))
    }
  }
  expect_gt(small, 0)
  for (key in names(r$figures)) {
    g <- r$figures[[key]]
    if (is.data.frame(g$data) && !is.null(g$data[["n"]])) {
      expect_true(all(g$data[["n"]] >= 450), info = key)
    }
  }
  expect_match(r$md, say_results$en$exact, fixed = TRUE)
})

test_that("choices$review = 'suppress' hides the flagged estimates (S3)", {
  skip_if_no_knit()
  r <- knit_report("en", "results", append = "choices$review <- 'suppress'")
  expect_false(grepl(say_results$en$exact, r$md, fixed = TRUE))
  expect_false(grepl(say_results$en$ul_zero, r$md, fixed = TRUE))
  for (key in names(r$tables)) {
    expect_true(all(is.na(r$tables[[key]]$mark)), info = key)
  }
})

test_that("without food groups, section 4 is one sentence (K13)", {
  skip_if_no_knit()
  r <- knit_report("es", "results", append = "food_groups <- NULL")
  expect_null(r$tables$R4.1)
  expect_match(r$md, say_results$es$food_groups_disabled, fixed = TRUE)
  expect_true("R2.1" %in% names(r$tables))
})

test_that("a scenario may be compared with another scenario (K16)", {
  skip_if_no_knit()
  r <- knit_report(
    "en", "results",
    append = "choices$comparator <- c(plus_maize = 'wheat_flour')"
  )
  scenario <- labels_of_type("en", "scenario")
  for (key in c("R3.2_iron", "R3.4_iron_expenditure_group")) {
    d <- r$tables[[key]]
    rows <- d$scenario == scenario[["plus_maize"]]
    expect_true(any(rows), info = key)
    expect_true(all(d$comparator[rows] == scenario[["wheat_flour"]]),
                info = key)
    expect_true(all(d$comparator[!rows] == scenario[["baseline"]]),
                info = key)
  }
  d <- r$tables$R3.2_iron
  expect_equal(d$from[d$scenario == scenario[["plus_maize"]]],
               d$to[d$scenario == scenario[["wheat_flour"]]])
  for (bad in c("c(plus_maize = 'plus_rice', plus_rice = 'plus_maize')",
                "c(plus_maize = 'plus_maize')",
                "c(plus_maize = 'sugar_only')",
                "c(baseline = 'wheat_flour')", "'wheat_flour'")) {
    expect_error(knit_report("en", "results",
                             append = paste("choices$comparator <-", bad)),
                 class = "hcesfort_error_argument")
  }
})
