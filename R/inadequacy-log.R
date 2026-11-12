# Audit rows of inadequacy().

inadequacy_log <- function(x, req, dist, bioavailability, cov, out,
                           nutrients, min_coverage) {
  step <- "inadequacy"
  row <- function(kind, cause, n, detail = NA_character_, hh = NA) {
    if (length(n) == 0) return(NULL)
    audit_row(step, "inadequacy", kind, cause, n, hh, detail = detail)
  }
  n_hh <- length(unique(x$household_id))
  assessed <- names(cov)
  missing <- setdiff(nutrients$nutrient, assessed)
  outside <- attr(req, "outside", exact = TRUE)
  methods <- unique(out[c("nutrient", "method", "bioavailability")])
  tails <- lapply(names(dist), function(n) {
    col <- nutrients$column[nutrients$nutrient == n]
    vapply(bioavailability[[n]], function(b) {
      n_tails(x[[col]], b, dist[[n]])
    }, integer(1))
  })
  dplyr::bind_rows(
    audit_row(step, "inadequacy", "input", "all", nrow(x), n_hh),
    row("note", "nutrient_without_requirement", rep(nrow(x), length(missing)),
        missing),
    row("note", "requirement_without_nutrient", rep(1L, length(outside)),
        outside),
    row("note", "method", rep(nrow(x), nrow(methods)),
        paste0(methods$nutrient, ": ", methods$method,
               ifelse(is.na(methods$bioavailability), "",
                      paste0(", b = ", methods$bioavailability)))),
    row("note", "coverage", rep(sum(x$intake_status == "estimated"),
                                length(cov)),
        paste0(assessed, ": ", format(round(cov, 4)), " (min_coverage ",
               min_coverage, ")")),
    row("note", "tails_fixed", unlist(tails),
        unlist(lapply(names(dist), function(n) {
          paste0(n, ", b = ", bioavailability[[n]])
        }))),
    not_estimated_rows(step, "inadequacy", x)
  )
}

# Flagged rows: households without a result, by status.
not_estimated_rows <- function(step, table, x) {
  hh <- unique(x[c("household_id", "intake_status")])
  status <- hh$intake_status[hh$intake_status != "estimated"]
  lapply(sort(unique(status)), function(s) {
    n <- sum(status == s)
    audit_row(step, table, "flagged", "not_estimated", n, n, detail = s)
  })
}
