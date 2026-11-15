# The data readiness report of the template (inst/report): tests U10, K1,
# K3 and K10 to K13 of docs/design-reports-v2.md, section 9, and K17, K18
# and U15 of docs/design-reports-v3.md, section 10. Knitted on
# hces_example with knitr, as Quarto would. Tables and figures are stored
# under their exhibit ID (exhibits.csv), with the instance for D8.

report_langs <- c("en", "es")

# Sentences and labels the tests match, in the language of each report.
say <- list(
  en = list(
    yes_no = c("yes", "no"), enabled = "enabled",
    absent_input = "^disabled: input absent", grams = "Grams",
    rule = "link at least 95% of the included",
    essential = "An essential input is absent (acquisitions$unit)",
    records_heading = "enough usable records",
    region_absent = "Region: the variable is absent",
    no_expenditure = "has no expenditure",
    no_energy = "Energy is not assessed"
  ),
  es = list(
    yes_no = c("sí", "no"), enabled = "habilitada",
    absent_input = "^deshabilitada: falta el insumo", grams = "Gramos",
    rule = "vincular al menos el 95% de los",
    essential = "Falta un insumo esencial (acquisitions$unit)",
    records_heading = "suficientes registros utilizables",
    region_absent = "Región: la variable no está",
    no_expenditure = "no tiene gasto",
    no_energy = "La energía no se evalúa"
  )
)

test_that("terms.csv labels the whole vocabulary the reports print (U10)", {
  e <- hces_example
  nutrients <- nutrient_registry(e$nutrients)
  grams <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
  content <- link_composition(grams, e$crosswalk, e$composition, nutrients)
  afe <- adult_equivalents(
    e$members, reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
    weight_kg = c(female = 55, male = 65), pal = 1.76
  )
  intake <- apparent_intake(content, afe, e$households)
  ladder <- linkage_ladder(content, e$households)
  checks <- rc(intake, ladder, "iron", 0.8, 0.8, 0.9)
  vocabulary <- list(
    step = ladder$step, check = c(checks$check, "domain_cells"),
    household_status = checks$detail[checks$check == "household_status"],
    reason = hcesfort:::not_linked_reasons,
    section = names(hcesfort:::readiness_sections()),
    verdict = "enabled",
    verdict_reason = c("missing_input", "threshold_not_met"),
    role = c("essential", "optional"),
    needed_by = c("all", "domain", unname(hcesfort:::readiness_needs())),
    flag = c("TRUE", "FALSE"),
    measure = c("records", "grams", "expenditure"),
    presentation_reason = c("sample_size", "effective_sample_size",
                            "absolute_width", "relative_width",
                            "zero_events", "degrees_of_freedom"),
    method = c("ear_cutpoint", "probability"),
    sentence = c(
      "exact", "limit", "supported", "supported_none", "supported_domains",
      "unsupported", "unsupported_none", "left", "left_inputs",
      "left_foods", "left_expenditure", "left_checks", "left_none",
      "not_ready", "not_included", "no_expenditure_records",
      "no_expenditure", "queue_empty", "rule", "rule_expenditure", "met",
      "not_met", "no_domain_differs", "domain_absent", "energy", "no_energy"
    ),
    axis = c("queue_x", "queue_y", "energy_x", "energy_y"),
    kind = c("figure", "table"),
    title = utils::read.csv(system.file("report", "exhibits.csv",
                                        package = "hcesfort"))$id,
    note = c("n", "suppressed", "empty", "cumulative", "review",
             "complement", "inventory",
             "queue", "differs", "energy_lines"),
    format = "big_mark"
  )
  for (lang in report_langs) {
    file <- system.file("report", lang, "terms.csv", package = "hcesfort")
    expect_s3_class(read_labels(file, needed = vocabulary), "tbl_df")
  }
})

test_that("labels.csv and terms.csv hold the same codes in each language", {
  codes <- function(lang, file) {
    d <- utils::read.csv(system.file("report", lang, file,
                                     package = "hcesfort"),
                         encoding = "UTF-8", stringsAsFactors = FALSE)
    paste(d$type, d$parent, d$code)
  }
  for (file in c("labels.csv", "terms.csv")) {
    expect_identical(codes("es", file), codes("en", file), info = file)
  }
  d <- lapply(report_langs, function(lang) {
    names(utils::read.csv(system.file("report", lang, "decisions.csv",
                                      package = "hcesfort")))
  })
  expect_identical(d[[2]], d[[1]])
})

test_that("the readiness report knits on hces_example (K1, K3, K10)", {
  skip_if_no_knit()
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness")
    expect_true(file.exists(file.path(r$dir, "readiness-sessionInfo.txt")))
    # Area and expenditure quintile differ from the rest in the unlinked
    # share; region does not (D8 only for the first two, DR10).
    expect_identical(names(r$tables), c(
      "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8_area",
      "D8_expenditure_group", "D9", "D10", "DA1"
    ))
    expect_false(grepl("Analyst|Analista", strip_comments(r$md),
                       ignore.case = TRUE), info = lang)
    expect_false(grepl("Error|```", r$md), info = lang)
    ladder <- r$tables$D4
    for (col in c("n_records", "n_households", "share_records",
                  "share_grams", "share_expenditure")) {
      v <- stats::na.omit(ladder[[col]])
      expect_true(all(diff(v) <= 0), info = paste(lang, col))
    }
    expect_true(all(r$tables$D1$national == say[[lang]]$enabled))
  }
})

test_that("every figure has axis titles, data and its table (K5)", {
  skip_if_no_knit()
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness")
    expect_identical(names(r$figures), c("D6", "D9"))
    for (id in names(r$figures)) {
      g <- r$figures[[id]]
      expect_s3_class(g, "ggplot")
      expect_true(nzchar(g$labels$x) && nzchar(g$labels$y),
                  info = paste(lang, id))
      expect_gt(nrow(ggplot2::layer_data(g, 1)), 0)
      expect_true(id %in% names(r$tables))
      expect_match(r$md, paste0("](figure/", id, ".png)"), fixed = TRUE)
    }
    q <- r$tables$D5
    expect_true(all(q$cum_share_grams >= 0 & q$cum_share_grams <= 100))
  }
})

test_that("each threshold appears with its status (K11)", {
  skip_if_no_knit()
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness", append = c(
      "choices$min_records_used <- 0.85", "choices$min_coverage <- 0.75",
      "choices$min_linked_share <- 0.95"
    ))
    ch <- r$tables$D3
    for (threshold in c(85, 75, 95)) {
      rows <- ch[ch$threshold %in% threshold, ]
      expect_gt(nrow(rows), 0)
      expect_true(all(rows$met %in% say[[lang]]$yes_no),
                  info = paste(lang, threshold))
    }
    expect_match(r$md, say[[lang]]$rule, fixed = TRUE)
  }
})

test_that("decisions.csv and every choice are required (K12)", {
  skip_if_no_knit()
  for (lang in report_langs) {
    expect_error(knit_report(lang, "readiness", remove = "decisions.csv"),
                 class = "hcesfort_error_argument")
    expect_error(knit_report(lang, "readiness",
                             append = "choices$review <- NULL"),
                 class = "hcesfort_error_argument")
    expect_error(knit_report(lang, "readiness",
                             append = "choices$review <- 'hide'"),
                 class = "hcesfort_error_argument")
    expect_error(
      knit_report(lang, "readiness",
                  append = "choices$equity_domains <- 'province'"),
      class = "hcesfort_error_argument"
    )
  }
})

test_that("an absent essential input stops after the inventory (K13)", {
  skip_if_no_knit()
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness", append = "acquisitions$unit <- NULL")
    expect_identical(names(r$tables), c("D1", "D2"))
    expect_match(r$md, say[[lang]]$essential, fixed = TRUE)
    expect_false(grepl(say[[lang]]$records_heading, r$md), info = lang)
  }
})

test_that("absent optional inputs leave one sentence each (P5)", {
  skip_if_no_knit()
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness", append = c(
      "households$region <- NULL", "enrichment <- NULL",
      "acquisitions$expenditure_lcu <- NULL",
      "choices['energy'] <- list(NULL)"
    ))
    expect_false(any(grepl("region", names(r$tables))), info = lang)
    expect_match(r$md, say[[lang]]$region_absent, fixed = TRUE)
    expect_match(r$md, say[[lang]]$no_expenditure, fixed = TRUE)
    expect_match(r$md, say[[lang]]$no_energy, fixed = TRUE)
    expect_null(r$tables$D4$share_expenditure)
    expect_null(r$tables$D9)
    expect_identical(unique(r$tables$D7$measure), say[[lang]]$grams)
    v <- r$tables$D1
    expect_true(all(grepl(say[[lang]]$absent_input, v$region)), info = lang)
    expect_true(all(v$national == say[[lang]]$enabled), info = lang)
  }
})

test_that("a domain with too many small cells is disabled (U15, DR11)", {
  skip_if_no_knit()
  # Each expenditure quintile has fewer than 450 households with an
  # estimated intake; every region and area has more.
  r <- knit_report("en", "readiness", append = paste(
    "presentation_standard$value[presentation_standard$criterion ==",
    "'min_n'] <- 450"
  ))
  v <- r$tables$D1
  small <- "Values of the domain with few households"
  expect_identical(sum(r$tables$D3$check == small), 3L)
  expect_true(all(grepl(small, v$expenditure_group, fixed = TRUE)))
  expect_identical(v$region, v$national)
  expect_identical(v$area, v$national)
})

test_that("energy must be a registry nutrient in kcal", {
  skip_if_no_knit()
  for (lang in report_langs) {
    expect_error(knit_report(lang, "readiness",
                             append = "choices$energy <- 'iron'"),
                 class = "hcesfort_error_argument")
  }
})

test_that("the report opens with the verdict and its summary (K17, DR9)", {
  skip_if_no_knit()
  summary <- list(
    en = c("The data support these sections", "Left to do: link 44 foods"),
    es = c("Los datos permiten estas secciones", "Falta por hacer: vincular 44")
  )
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness")
    md <- strip_comments(r$md)
    first <- regmatches(md, regexpr("\\*\\*[^ ]+ [A-Z0-9.]+\\. ", md))
    expect_match(first, " D1\\. $", info = lang)
    expect_identical(names(r$tables)[1], "D1")
    # The summary follows the matrix, before the next section.
    d1 <- substr(md, regexpr("D1\\. ", md), regexpr("## 2\\. ", md))
    for (s in summary[[lang]]) expect_match(d1, s, fixed = TRUE)
  }
})

test_that("a disabled section and a domain are named in the summary (DR9)", {
  skip_if_no_knit()
  r <- knit_report("en", "readiness", append = c(
    "food_groups <- NULL",
    "presentation_standard$value[presentation_standard$criterion ==",
    "  'min_n'] <- 450"
  ))
  md <- strip_comments(r$md)
  expect_match(md, paste0(
    "Not supported: Contribution of each food group, disabled: input ",
    "absent \\(food_groups\\); analysis by expenditure quintile, disabled: ",
    "threshold not met \\(Values of the domain with few households\\)\\."
  ))
  expect_match(md, "Each of them can also be reported by region and area.")
})

test_that("energy is national only, and D8 only where a domain differs (K18)", {
  skip_if_no_knit()
  domain_says <- list(
    en = paste("no value of these domain variables differs from the other",
               "households: region."),
    es = paste("ningún valor de estas variables de dominio difiere del",
               "resto de los hogares: región.")
  )
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness", append = c(
      "choices$domains <- 'region'", "choices$equity_domains <- 'region'"
    ))
    expect_false(any(grepl("^D8|^D9_", names(r$tables))), info = lang)
    expect_identical(names(r$figures), c("D6", "D9"))
    expect_match(strip_comments(r$md), domain_says[[lang]], fixed = TRUE)
    expect_identical(lengths(regmatches(r$md, gregexpr("\\*\\*Figur[ea] D9\\.",
                                                       r$md))), 1L)
  }
})

test_that("D9 draws up to the upper bound and counts the rest (V-D21)", {
  skip_if_no_knit()
  hidden <- "([0-9,]+) households above 6,000 kcal, not shown\\."
  r <- knit_report("en", "readiness")
  g <- r$figures$D9
  x <- rlang::eval_tidy(g$mapping$x, g$data)
  expect_true(all(x <= 6000))
  # Drawn plus counted are every household with an estimated energy.
  n_hidden <- as.numeric(gsub(",", "", regmatches(
    r$md, regexec(hidden, r$md)
  )[[1]][2]))
  expect_gt(n_hidden, 0)
  expect_identical(length(x) + n_hidden, as.numeric(unique(r$tables$D9$n)))
  wide <- knit_report("en", "readiness",
                      append = "choices$energy_upper <- 1e6")
  expect_false(grepl("households above", wide$md, fixed = TRUE))
  expect_identical(nrow(wide$figures$D9$data),
                   as.integer(unique(wide$tables$D9$n)))
})
