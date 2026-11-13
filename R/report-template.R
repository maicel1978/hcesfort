#' Copy the country report template
#'
#' Copy the Quarto templates of the two country reports to a folder:
#'
#' * `readiness.qmd`, the **data readiness report**: can the survey
#'   support the analysis, and what is left to do before it can? Variable
#'   inventory, quality thresholds, linkage ladder, work queue of foods not
#'   linked, unlinked share by domain, plausibility of the apparent energy,
#'   decisions taken with the data and the readiness verdict.
#' * `results.qmd`, the **results report**: coverage of the vehicles,
#'   quantity among the households that acquire them, risk of inadequate
#'   intake without fortification, fortification scenarios and the
#'   contribution of each food group. Each section, nationally and by
#'   domain, is rendered only when the readiness verdict enables it;
#'   otherwise one sentence says why.
#'
#' Both reports read the same inputs: `_inputs.R` holds the standard
#' tables of the survey, the steps that take choices and one list
#' `choices` (thresholds, nutrients, domains, comparators). None has a
#' default in the package; the values shipped are those of [hces_example].
#' The analyst also edits `labels.csv` (the label of every code printed,
#' in the language of the report: nothing is printed as a code) and
#' `decisions.csv` (the decisions taken with the data and their evidence).
#' `terms.csv` labels the package vocabulary. Tables and figures are plain
#' code in `_tables.R` and `_figures.R` (`ggplot2`), meant to be edited.
#' Rendering needs Quarto and the suggested packages `ggplot2` and
#' `knitr`; copying needs neither.
#'
#' @param path Folder to copy the template to. Created if it does not
#'   exist; files already there are never overwritten.
#' @param lang `"en"` (English) or `"es"` (Spanish).
#' @returns The paths of the copied files, invisibly.
#' @seealso [readiness_verdict()], [linkage_ladder()],
#'   [estimate_households()], [estimate_difference()].
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
