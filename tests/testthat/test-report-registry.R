# Registry tests of the templates (Q2, docs/design-reports-v3.md, section
# 9.2): every ID of exhibits.csv has a title in terms.csv of each language
# and a builder that exists; every figure of the results body has an
# appendix table (R15); every exhibit printed is in the registry, and
# every exhibit of the registry is called by its report.

registry <- function() {
  utils::read.csv(system.file("report", "exhibits.csv", package = "hcesfort"),
                  stringsAsFactors = FALSE)
}

template_file <- function(...) {
  system.file("report", ..., package = "hcesfort")
}

# Names of the functions defined at the top level of a template script.
defined_functions <- function(file) {
  exprs <- parse(file, keep.source = FALSE)
  is_def <- vapply(exprs, function(e) {
    is.call(e) && as.character(e[[1]]) %in% c("<-", "=") &&
      is.name(e[[2]]) && is.call(e[[3]]) &&
      identical(e[[3]][[1]], as.name("function"))
  }, logical(1))
  vapply(exprs[is_def], function(e) as.character(e[[2]]), character(1))
}

# String constants of an R script or of the R chunks of a Quarto file.
string_constants <- function(file) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  if (grepl("\\.qmd$", file)) {
    inside <- cumsum(grepl("^```", lines)) %% 2 == 1
    lines <- lines[inside & !grepl("^```|^#\\|", lines)]
  }
  data <- utils::getParseData(parse(text = lines, keep.source = TRUE))
  gsub("^[\"']|[\"']$", "", data$text[data$token == "STR_CONST"])
}

# The template scripts a report of `lang` sources.
report_scripts <- function(report, lang = "en") {
  s <- string_constants(template_file(lang, paste0(report, ".qmd")))
  grep("^_.*\\.R$", s, value = TRUE)
}

test_that("every exhibit has a title in terms.csv of each language", {
  x <- registry()
  for (lang in c("en", "es")) {
    terms <- utils::read.csv(template_file(lang, "terms.csv"),
                             encoding = "UTF-8", stringsAsFactors = FALSE)
    titles <- terms$code[terms$type == "title"]
    expect_identical(setdiff(x$id, titles), character(0), info = lang)
    expect_identical(setdiff(titles, x$id), character(0), info = lang)
  }
})

test_that("every builder exists in the script of its report", {
  x <- registry()
  for (report in c("readiness", "results")) {
    defined <- unlist(lapply(report_scripts(report), function(f) {
      defined_functions(template_file(f))
    }))
    builders <- x$builder[x$report == report]
    expect_identical(setdiff(builders, defined), character(0), info = report)
  }
  expect_false(anyDuplicated(x$builder) > 0)
})

test_that("every figure of the results body has its appendix table (R15)", {
  x <- registry()
  figures <- x$report == "results" & x$body == "figure"
  expect_true(all(x$appendix[figures]))
  expect_false(any(x$appendix[x$report == "readiness"]))
})

test_that("every exhibit is called by its report, and only those", {
  x <- registry()
  for (report in c("readiness", "results")) {
    for (lang in c("en", "es")) {
      own <- setdiff(report_scripts(report, lang),
                     report_scripts(setdiff(c("readiness", "results"),
                                            report), lang))
      files <- c(template_file(lang, paste0(report, ".qmd")),
                 template_file(own))
      called <- unlist(lapply(files, string_constants))
      ids <- x$id[x$report == report]
      expect_identical(setdiff(ids, called), character(0),
                       info = paste(report, lang))
      other <- x$id[x$report != report]
      expect_identical(intersect(other, called), character(0),
                       info = paste(report, lang))
    }
  }
})

test_that("every exhibit printed on hces_example is in the registry", {
  skip_if_no_knit()
  x <- registry()
  for (report in c("readiness", "results")) {
    r <- knit_report("en", report)
    shown <- unique(sub("_.*$", "", names(r$tables)))
    expect_identical(setdiff(shown, x$id[x$report == report]), character(0),
                     info = report)
    # On the example every section is enabled: each exhibit is shown, but
    # D8, shown only where a domain differs from the national figure.
    expect_identical(setdiff(x$id[x$report == report], c(shown, "D8")),
                     character(0), info = report)
  }
})
