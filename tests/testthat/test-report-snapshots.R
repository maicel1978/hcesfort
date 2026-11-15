# Snapshot tests of the report templates (Q1, docs/design-reports-v3.md,
# section 9.1): every exhibit shown on hces_example, in each report and
# language, printed as plain text (key, title, sentences, table, notes)
# by exhibit_text() of _exhibits.R. The snapshot is of the exhibit, not of
# HTML, so a new renderer changes no snapshot, while a changed word or
# number is a diff to review (testthat::snapshot_review()).

for (report in c("readiness", "results")) {
  for (lang in c("en", "es")) {
    test_that(paste("exhibits of the", report, "report,", lang, "(Q1)"), {
      skip_if_no_knit()
      r <- knit_report(lang, report)
      expect_gt(length(r$env$shown), 0)
      for (key in names(r$env$shown)) {
        expect_snapshot(cat(r$env$exhibit_text(key), sep = "\n"))
      }
    })
  }
}
