#' Copy the country report template
#'
#' Copy the Quarto template of the results report to a folder. The report
#' is laid out by the questions a decision-maker asks (which nutrients are
#' at risk, for whom, from which foods, how far each vehicle reaches, who
#' is left out, what each scenario would change, and what the figures
#' cannot answer), each answered by a headline with its confidence
#' interval, one exhibit and the hcesfort function behind it. The method
#' goes to annexes, mapped to the STROBE-nut checklist.
#'
#' The template renders as shipped on [hces_example]. To use it with a
#' survey, replace the block marked `ADAPTER` of `_results.R` with the
#' standard tables and choices of the survey, set the `params` of the YAML
#' header of `report.qmd` (none has a default in the package), and edit
#' `actions.csv` (each action: scenario from, scenario to) and
#' `decisions.csv` (decisions that condition the interpretation).
#'
#' Headlines are built by `_headlines.R`: each picks the wording the
#' estimates support (two overlapping intervals are not ranked) and stops
#' the render with a message when an assumption fails, so a report that
#' renders is one whose headlines hold. Figures are plain `ggplot2` code in
#' `_figures.R`. Rendering needs Quarto and the suggested packages
#' `ggplot2` and `knitr`; copying needs neither.
#'
#' @param path Folder to copy the template to. Created if it does not
#'   exist; files already there are never overwritten.
#' @param lang `"en"` (English) or `"es"` (Spanish).
#' @returns The paths of the copied files, invisibly.
#' @seealso [food_group_shares()], [estimate_households()],
#'   [estimate_difference()], [audit_summary()].
#' @examples
#' dir <- file.path(tempdir(), "report")
#' files <- use_report_template(dir, lang = "en")
#' basename(files)
#' unlink(dir, recursive = TRUE)
#' @export
use_report_template <- function(path, lang = "en") {
  check_required()
  if (!rlang::is_string(path) || is.na(path) || path == "" ||
        (file.exists(path) && !dir.exists(path))) {
    abort_hcesfort("argument", c(
      "{.arg path} must be one folder name.",
      "i" = "It may be a new folder, not an existing file."
    ), arg = "path")
  }
  langs <- c("en", "es")
  if (!rlang::is_string(lang) || !lang %in% langs) {
    abort_hcesfort("argument", "{.arg lang} must be one of {.val {langs}}.",
                   arg = "lang")
  }
  root <- system.file("report", package = "hcesfort", mustWork = TRUE)
  from <- c(list.files(root, pattern = "\\.R$", full.names = TRUE),
            list.files(file.path(root, lang), full.names = TRUE))
  to <- file.path(path, basename(from))
  there <- to[file.exists(to)]
  if (length(there) > 0) {
    abort_hcesfort("argument", c(
      "{.arg path} already holds files of the template.",
      "x" = "Existing: {.file {basename(there)}}.",
      "i" = "Choose another folder or remove them; nothing is overwritten."
    ), arg = "path")
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(from, to)
  if (!all(ok)) {
    abort_hcesfort("argument", c(
      "Could not copy the template to {.path {path}}.",
      "x" = "Not copied: {.file {basename(to[!ok])}}."
    ), arg = "path")
  }
  invisible(to)
}
