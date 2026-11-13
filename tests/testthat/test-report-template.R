# use_report_template() and the template it copies (inst/report).

template_files <- function(lang) {
  shared <- c("_chain.R", "_figures.R", "_headlines.R", "_inputs.R",
              "_readiness.R", "_results.R", "_tables.R")
  own <- c("actions.csv", "decisions.csv", "report.qmd", "labels.csv",
           "terms.csv", "readiness.qmd")
  c(shared, own)
}

test_that("the template is copied, in each language, never overwritten", {
  for (lang in c("en", "es")) {
    dir <- withr::local_tempdir()
    files <- use_report_template(file.path(dir, "r"), lang = lang)
    expect_setequal(basename(files), template_files(lang))
    expect_true(all(file.exists(files)))
    expect_match(paste(readLines(files[basename(files) == "report.qmd"]),
                       collapse = "\n"), paste0("lang: \"", lang, "\""))
    err <- expect_error(use_report_template(file.path(dir, "r"), lang),
                        class = "hcesfort_error_argument")
    expect_match(conditionMessage(err), "report.qmd")
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
  expect_true(all(c("food_group_shares", "estimate_difference",
                    "audit_summary") %in% used))
})

test_that("the template knits on hces_example in both languages", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("ggplot2")
  for (lang in c("en", "es")) {
    md <- knit_template(lang)
    expect_match(md, "flour", fixed = TRUE)
    expect_false(any(grepl("Headline guard|Error", md)))
  }
})

test_that("the template renders with Quarto when it is installed", {
  skip_on_cran()
  skip_if(Sys.which("quarto") == "", "Quarto is not installed")
  skip_if_not_installed("ggplot2")
  dir <- withr::local_tempdir()
  use_report_template(dir, "en")
  status <- withr::with_dir(dir, system2("quarto", c("render", "report.qmd"),
                                         stdout = FALSE, stderr = FALSE))
  expect_identical(status, 0L)
  expect_true(file.exists(file.path(dir, "report.html")))
})

test_that("headlines pick the wording the estimates support", {
  h <- template_headlines()
  est <- function(nutrient, e, lo, hi, scenario = "s") {
    data.frame(scenario = scenario, nutrient = nutrient, estimate = e,
               ci_low = lo, ci_high = hi)
  }
  apart <- rbind(est("iron", 0.6, 0.5, 0.7), est("zinc", 0.3, 0.2, 0.4))
  expect_match(h$headline_q1(apart, "s", 0.95, "en"),
               "greatest risk .* iron: 60% of households \\(95% CI 50%")
  overlap <- rbind(est("iron", 0.6, 0.4, 0.7), est("zinc", 0.5, 0.3, 0.65))
  expect_match(h$headline_q1(overlap, "s", 0.95, "en"), "cannot be ranked")
  expect_match(h$headline_q1(overlap, "s", 0.9, "es"), "IC 90%")
  expect_error(h$headline_q1(apart, "other", 0.95, "en"), "Headline guard")
})

test_that("headline guards stop when the sentence would not hold", {
  h <- template_headlines()
  shares <- data.frame(variable = "iron_mg", food_group = c("a", "b"),
                       estimate = c(0.7, 0.2), ci_low = NA, ci_high = NA)
  expect_error(h$headline_q3(shares, "iron_mg", "iron", 0.95, "en"),
               "do not add up")
  shares$estimate[2] <- 0.3
  expect_match(h$headline_q3(shares, "iron_mg", "iron", 0.95, "en"),
               "a supply 70% \\(exact in the sample")
  d <- data.frame(action = "a", nutrient = "iron", estimate = 0.1,
                  se = 0.01, ci_low = 0.05, ci_high = 0.15)
  expect_error(h$headline_q6(d, 0.95, "en"), "no action lowers")
  d <- rbind(d, data.frame(action = "b", nutrient = "zinc", estimate = -0.2,
                           se = 0.05, ci_low = -0.3, ci_high = -0.1))
  d$ci_low[1] <- -0.05
  expect_match(h$headline_q6(d, 0.95, "en"),
               "'b' would lower .* 20 points \\(95% CI 10–30\\); 'a'")
  q2 <- data.frame(domain = "r", nutrient = "iron", domain_value = "x",
                   estimate = 0.5, low_precision = FALSE)
  expect_error(h$headline_q2(q2, "iron", "r", "en"), "fewer than two")
  q5 <- data.frame(domain = c("all", "r", "r"),
                   domain_value = c("all", "x", "y"),
                   none = c(0.1, 0.05, 0.2), ci_low = c(0.05, NA, NA),
                   ci_high = c(0.2, NA, NA))
  expect_match(h$headline_q5(q5, 0.95, "en"), "ranges from 5% to 20%")
  q5$none <- 0
  expect_match(h$headline_q5(q5, 0.95, "es"), "al menos un veh")
  q4 <- data.frame(level = character(0), vehicle = character(0),
                   estimate = numeric(0))
  expect_error(h$headline_q4(q4, 0.95, "en"), "no vehicle coverage")
})
