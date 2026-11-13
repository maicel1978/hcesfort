# The data readiness report of the template (inst/report): tests U10, K1,
# K3 and K10 to K13 of docs/design-reports-v2.md, section 9. Knitted on
# hces_example with knitr, as Quarto would.

skip_if_no_knit <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("knitr")
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not_installed("ggplot2")
}

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
    precision_status = c("small_cell", "exact", "wide_interval", "ok")
  )
  # The Spanish terms are step 12c.10.
  for (lang in "en") {
    file <- system.file("report", lang, "terms.csv", package = "hcesfort")
    expect_s3_class(read_labels(file, needed = vocabulary), "tbl_df")
  }
})

test_that("the readiness report knits on hces_example (K1, K3, K10)", {
  skip_if_no_knit()
  r <- knit_report("en", "readiness")
  expect_true(file.exists(file.path(r$dir, "readiness-sessionInfo.txt")))
  expect_setequal(names(r$tables), c(
    "inventory", "checks", "ladder", "queue", "unlinked", "unlinked_region",
    "unlinked_expenditure_group", "energy", "energy_region",
    "energy_expenditure_group", "decisions", "verdict"
  ))
  expect_false(grepl("Analyst|Analista", strip_comments(r$md),
                     ignore.case = TRUE))
  expect_false(grepl("Error|```", r$md))
  ladder <- r$tables$ladder
  for (col in c("n_records", "n_households", "share_records",
                "share_grams", "share_expenditure")) {
    v <- stats::na.omit(ladder[[col]])
    expect_true(all(diff(v) <= 0), info = col)
  }
  expect_true(all(r$tables$verdict$national == "enabled"))
})

test_that("every figure has axis titles, data and its table (K5)", {
  skip_if_no_knit()
  r <- knit_report("en", "readiness")
  expect_setequal(names(r$figures),
                  c("queue", "energy_region", "energy_expenditure_group"))
  for (id in names(r$figures)) {
    g <- r$figures[[id]]
    expect_s3_class(g, "ggplot")
    expect_true(nzchar(g$labels$x) && nzchar(g$labels$y), info = id)
    expect_gt(nrow(ggplot2::layer_data(g, 2)), 0)
    expect_true(id %in% names(r$tables))
  }
  q <- r$tables$queue
  expect_true(all(q$cum_share_grams >= 0 & q$cum_share_grams <= 100))
})

test_that("each threshold appears with its status (K11)", {
  skip_if_no_knit()
  r <- knit_report("en", "readiness", append = c(
    "choices$min_records_used <- 0.85", "choices$min_coverage <- 0.75",
    "choices$min_linked_share <- 0.95"
  ))
  ch <- r$tables$checks
  for (threshold in c(85, 75, 95)) {
    rows <- ch[ch$threshold %in% threshold, ]
    expect_gt(nrow(rows), 0)
    expect_true(all(rows$met %in% c("yes", "no")), info = threshold)
  }
  expect_match(r$md, "link at least 95% of the included", fixed = TRUE)
})

test_that("decisions.csv and every choice are required (K12)", {
  skip_if_no_knit()
  expect_error(knit_report("en", "readiness", remove = "decisions.csv"),
               class = "hcesfort_error_argument")
  expect_error(knit_report("en", "readiness", append = "choices$level <- NULL"),
               class = "hcesfort_error_argument")
  expect_error(
    knit_report("en", "readiness",
                append = "choices$equity_domains <- 'province'"),
    class = "hcesfort_error_argument"
  )
})

test_that("an absent essential input stops after the inventory (K13)", {
  skip_if_no_knit()
  r <- knit_report("en", "readiness", append = "acquisitions$unit <- NULL")
  expect_identical(names(r$tables), "inventory")
  expect_match(r$md, "An essential input is absent (acquisitions$unit)",
               fixed = TRUE)
  expect_false(grepl("enough usable records", r$md))
})

test_that("absent optional inputs leave one sentence each (P5)", {
  skip_if_no_knit()
  r <- knit_report("en", "readiness", append = c(
    "households$region <- NULL", "enrichment <- NULL",
    "acquisitions$expenditure_lcu <- NULL", "choices['energy'] <- list(NULL)"
  ))
  expect_false(any(grepl("region", names(r$tables))))
  expect_match(r$md, "Region: the variable is absent", fixed = TRUE)
  expect_match(r$md, "has no expenditure", fixed = TRUE)
  expect_match(r$md, "Energy is not assessed", fixed = TRUE)
  expect_null(r$tables$ladder$share_expenditure)
  expect_null(r$tables$energy)
  expect_identical(unique(r$tables$unlinked$measure), "Grams")
  v <- r$tables$verdict
  expect_true(all(grepl("^disabled: input absent", v$region)))
  expect_true(all(v$national == "enabled"))
})

test_that("energy must be a registry nutrient in kcal", {
  skip_if_no_knit()
  expect_error(knit_report("en", "readiness",
                           append = "choices$energy <- 'iron'"),
               class = "hcesfort_error_argument")
})
