# use_report_template() and the template it copies (inst/report).

template_files <- function(lang) {
  shared <- c("_chain.R", "_figures.R", "_inputs.R", "_readiness.R",
              "_results.R", "_tables.R")
  own <- c("decisions.csv", "labels.csv", "terms.csv", "readiness.qmd",
           "results.qmd")
  c(shared, own)
}

test_that("the template is copied, in each language, never overwritten", {
  for (lang in c("en", "es")) {
    dir <- withr::local_tempdir()
    files <- use_report_template(file.path(dir, "r"), lang = lang)
    expect_setequal(basename(files), template_files(lang))
    expect_true(all(file.exists(files)))
    expect_match(paste(readLines(files[basename(files) == "readiness.qmd"]),
                       collapse = "\n"), paste0("lang: \"", lang, "\""))
    err <- expect_error(use_report_template(file.path(dir, "r"), lang),
                        class = "hcesfort_error_argument")
    expect_match(conditionMessage(err), "readiness.qmd")
  }
})

test_that("arguments are checked", {
  expect_error(use_report_template(), class = "hcesfort_error_argument")
  expect_error(use_report_template(c("a", "b")),
               class = "hcesfort_error_argument")
  expect_error(use_report_template(tempdir(), lang = "fr"),
               class = "hcesfort_error_argument")
  file <- withr::local_tempfile()
  writeLines("x", file)
  expect_error(use_report_template(file), class = "hcesfort_error_argument")
})

test_that("every hcesfort function the template calls is exported", {
  root <- system.file("report", package = "hcesfort")
  code <- c(list.files(root, "\\.R$", full.names = TRUE),
            list.files(root, "\\.qmd$", recursive = TRUE, full.names = TRUE))
  calls <- unique(unlist(lapply(code, template_calls)))
  internal <- setdiff(ls(asNamespace("hcesfort")),
                      getNamespaceExports("hcesfort"))
  expect_identical(intersect(calls, internal), character(0))
  used <- intersect(calls, getNamespaceExports("hcesfort"))
  expect_true(all(c("readiness_inventory", "readiness_verdict",
                    "linkage_ladder", "food_group_shares",
                    "estimate_difference", "above_ul") %in% used))
})

test_that("the template renders with Quarto when it is installed", {
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
})

# The R code of the chunks of a report, as its tokens without comments,
# commas and strings other than codes such as "vehicle" (the text differs
# by language, and so does how it is split into strings; the code and the
# codes must not).
chunk_tokens <- function(file) {
  lines <- readLines(file, encoding = "UTF-8", warn = FALSE)
  fence <- grepl("^```", lines)
  inside <- (cumsum(fence) %% 2 == 1) & !fence
  code <- lines[inside]
  p <- utils::getParseData(parse(text = code, keep.source = TRUE))
  text <- p$token == "STR_CONST" & !grepl("^[\"'][a-z_]+[\"']$", p$text)
  p <- p[p$terminal & !text & !p$token %in% c("COMMENT", "','"), ]
  p$text
}

test_that("the reports run the same code in every language", {
  for (report in c("readiness.qmd", "results.qmd")) {
    files <- system.file("report", c("en", "es"), report,
                         package = "hcesfort")
    expect_identical(chunk_tokens(files[2]), chunk_tokens(files[1]),
                     info = report)
  }
})
