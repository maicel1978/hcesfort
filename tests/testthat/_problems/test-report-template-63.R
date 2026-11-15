# Extracted from test-report-template.R:63

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "hcesfort", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
template_files <- function(lang) {
  shared <- c("_chain.R", "_exhibits.R", "_figures.R", "_inputs.R",
              "_readiness.R", "_results.R", "_tables.R", "_verdict.R",
              "exhibits.csv", "report.css")
  own <- c("decisions.csv", "labels.csv", "terms.csv", "readiness.qmd",
           "results.qmd")
  c(shared, own)
}

# test -------------------------------------------------------------------------
skip_on_cran()
skip_if(Sys.which("quarto") == "", "Quarto is not installed")
skip_if_not_installed("ggplot2")
for (lang in c("en", "es")) {
    dir <- withr::local_tempdir()
    use_report_template(dir, lang)
    for (report in c("readiness", "results")) {
      status <- withr::with_dir(dir, system2(
        "quarto", c("render", paste0(report, ".qmd")),
        stdout = FALSE, stderr = FALSE
      ))
      expect_identical(status, 0L, info = paste(lang, report))
      html <- file.path(dir, paste0(report, ".html"))
      expect_true(file.exists(html), info = paste(lang, report))
      # K15: no code in the results report.
      if (report == "results") {
        expect_false(any(grepl("<code>", readLines(html, warn = FALSE))),
                     info = lang)
      }
    }
  }
