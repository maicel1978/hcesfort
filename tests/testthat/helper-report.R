# Helpers of test-report-template.R.

# Names of the functions called in an R script or in the R chunks of a
# Quarto file.
template_calls <- function(file) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  if (grepl("\\.qmd$", file)) {
    inside <- cumsum(grepl("^```", lines)) %% 2 == 1
    lines <- lines[inside & !grepl("^```|^#\\|", lines)]
  }
  data <- utils::getParseData(parse(text = lines, keep.source = TRUE))
  unique(data$text[data$token == "SYMBOL_FUNCTION_CALL"])
}

# Knit the template of `lang` in a temporary folder with the params of its
# YAML header; returns the Markdown as one string.
knit_template <- function(lang) {
  dir <- withr::local_tempdir(.local_envir = parent.frame())
  use_report_template(dir, lang)
  withr::local_dir(dir)
  env <- new.env(parent = globalenv())
  env$params <- rmarkdown::yaml_front_matter("report.qmd")$params
  knitr::knit("report.qmd", "report.md", quiet = TRUE, envir = env)
  paste(readLines("report.md", encoding = "UTF-8"), collapse = "\n")
}

# The headline functions of the template, in an environment.
template_headlines <- function() {
  env <- new.env(parent = globalenv())
  sys.source(system.file("report", "_headlines.R", package = "hcesfort"),
             envir = env)
  env
}
