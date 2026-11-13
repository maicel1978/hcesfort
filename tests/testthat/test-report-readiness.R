# The data readiness report of the template (inst/report): tests U10, K1,
# K3 and K10 to K13 of docs/design-reports-v2.md, section 9. Knitted on
# hces_example with knitr, as Quarto would.

skip_if_no_knit <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("knitr")
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not_installed("ggplot2")
}

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
  checks <- readiness_checks(intake, ladder, "iron", 0.8, 0.8, 0.9)
  vocabulary <- list(
    step = ladder$step, check = checks$check,
    household_status = checks$detail[checks$check == "household_status"],
    reason = hcesfort:::not_linked_reasons,
    section = names(hcesfort:::readiness_sections()),
    verdict = "enabled",
    verdict_reason = c("missing_input", "threshold_not_met"),
    role = c("essential", "optional"), needed_by = c("all", "none"),
    flag = c("TRUE", "FALSE"),
    measure = c("records", "grams", "expenditure"),
    precision_status = c("small_cell", "exact", "wide_interval", "ok"),
    method = c("ear_cutpoint", "probability"),
    ul_scope = c("total_intake", "form_added_only", "form_diet_and_added",
                 "not_assessable"),
    sentence = "exact"
  )
  vocabulary$ul_bias <- vocabulary$ul_scope
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
    expect_setequal(names(r$tables), c(
      "inventory", "checks", "ladder", "queue", "unlinked", "unlinked_region",
      "unlinked_expenditure_group", "energy", "energy_region",
      "energy_expenditure_group", "decisions", "verdict"
    ))
    expect_false(grepl("Analyst|Analista", strip_comments(r$md),
                       ignore.case = TRUE), info = lang)
    expect_false(grepl("Error|```", r$md), info = lang)
    ladder <- r$tables$ladder
    for (col in c("n_records", "n_households", "share_records",
                  "share_grams", "share_expenditure")) {
      v <- stats::na.omit(ladder[[col]])
      expect_true(all(diff(v) <= 0), info = paste(lang, col))
    }
    expect_true(all(r$tables$verdict$national == say[[lang]]$enabled))
  }
})

test_that("every figure has axis titles, data and its table (K5)", {
  skip_if_no_knit()
  for (lang in report_langs) {
    r <- knit_report(lang, "readiness")
    expect_setequal(names(r$figures),
                    c("queue", "energy_region", "energy_expenditure_group"))
    for (id in names(r$figures)) {
      g <- r$figures[[id]]
      expect_s3_class(g, "ggplot")
      expect_true(nzchar(g$labels$x) && nzchar(g$labels$y),
                  info = paste(lang, id))
      expect_gt(nrow(ggplot2::layer_data(g, 2)), 0)
      expect_true(id %in% names(r$tables))
    }
    q <- r$tables$queue
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
    ch <- r$tables$checks
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
                             append = "choices$level <- NULL"),
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
    expect_identical(names(r$tables), "inventory")
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
    expect_null(r$tables$ladder$share_expenditure)
    expect_null(r$tables$energy)
    expect_identical(unique(r$tables$unlinked$measure), say[[lang]]$grams)
    v <- r$tables$verdict
    expect_true(all(grepl(say[[lang]]$absent_input, v$region)), info = lang)
    expect_true(all(v$national == say[[lang]]$enabled), info = lang)
  }
})

test_that("energy must be a registry nutrient in kcal", {
  skip_if_no_knit()
  for (lang in report_langs) {
    expect_error(knit_report(lang, "readiness",
                             append = "choices$energy <- 'iron'"),
                 class = "hcesfort_error_argument")
  }
})
