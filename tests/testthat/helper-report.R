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

# Knit `report` ("readiness" or "results") of `lang` on hces_example in a
# temporary folder, as Quarto would (no echo, errors stop the knit), after
# appending `append` (lines of R) to _inputs.R and removing the files
# named in `remove`. Returns the Markdown as one string, the exhibit
# registry (`tables`, `figures`) and the folder.
knit_report <- function(lang, report, append = NULL, remove = NULL,
                        envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = envir)
  use_report_template(dir, lang)
  if (!is.null(append)) {
    cat(append, file = file.path(dir, "_inputs.R"), sep = "\n", append = TRUE)
  }
  unlink(file.path(dir, remove))
  withr::local_dir(dir)
  withr::local_options(knitr.kable.NA = NULL)
  old <- knitr::opts_chunk$get()
  withr::defer(knitr::opts_chunk$restore(old))
  knitr::opts_chunk$set(echo = FALSE, error = FALSE, warning = FALSE,
                        fig.path = file.path(dir, "figure", ""))
  env <- new.env(parent = globalenv())
  qmd <- paste0(report, ".qmd")
  env$params <- rmarkdown::yaml_front_matter(qmd)$params
  md <- paste0(report, ".md")
  knitr::knit(qmd, md, quiet = TRUE, envir = env)
  list(md = paste(readLines(md, encoding = "UTF-8"), collapse = "\n"),
       tables = env$tables, figures = env$figures, dir = dir)
}

# Text of a Markdown string without its HTML comments.
strip_comments <- function(md) {
  gsub("<!--.*?-->", "", md)
}
