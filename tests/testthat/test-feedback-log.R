# Feedback log (Q3, docs/design-reports-v3.md, section 9.3): every round
# file has the documented columns, a valid decision and exhibit IDs that
# exist in the registry. Skipped where docs/ is absent.

feedback_dir <- function() {
  testthat::test_path("..", "..", "docs", "feedback")
}

feedback_rounds <- function(dir) {
  list.files(dir, pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}-round-[0-9]+\\.csv$",
             full.names = TRUE)
}

# Problems found in one round file, as a character vector (empty: none).
feedback_problems <- function(path, ids) {
  x <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = "")
  needed <- c("comment", "exhibit_id", "decision", "reason", "result")
  if (!identical(names(x), needed)) return("columns")
  open <- x$decision %in% c("rejected", "deferred")
  c(
    if (!all(x$decision %in% c("accepted", "rejected", "deferred")))
      "decision",
    if (!all(stats::na.omit(x$exhibit_id) %in% ids)) "exhibit_id",
    if (anyNA(x$reason[open])) "reason",
    if (anyNA(x$result[x$decision == "accepted"])) "result"
  )
}

test_that("every feedback round is well formed", {
  dir <- feedback_dir()
  skip_if_not(dir.exists(dir), "docs/feedback is not available")
  ids <- utils::read.csv(system.file("report", "exhibits.csv",
                                     package = "hcesfort"),
                         stringsAsFactors = FALSE)$id
  expect_true(length(ids) > 0)
  for (path in feedback_rounds(dir)) {
    expect_identical(feedback_problems(path, ids), character(0),
                     label = basename(path))
  }
})

test_that("the checker rejects a round with an unknown exhibit", {
  path <- withr::local_tempfile(fileext = ".csv")
  bad <- data.frame(comment = "x", exhibit_id = "Z9.9",
                    decision = "accepted", reason = NA, result = "R1")
  utils::write.csv(bad, path, row.names = FALSE)
  expect_identical(feedback_problems(path, c("R2.2", "D4")), "exhibit_id")
})
