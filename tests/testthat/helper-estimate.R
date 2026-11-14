# Fixtures of the estimator tests (test-estimate.R, test-korn-graubard.R):
# an invented design of 8 households in 2 strata of 2 PSUs each, and a
# result table with two scenarios.
es_households <- function() {
  data.frame(household_id = 1:8, weight = c(1, 2, 1, 3, 2, 1, 1, 2),
             stratum = rep(1:2, each = 4), psu = rep(c(1, 1, 2, 2), 2),
             region = rep(c("a", "b"), 4),
             urban = c(TRUE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, FALSE))
}

# Household 5 has no estimate (NA) in both scenarios.
es_result <- function() {
  data <- data.frame(
    scenario = rep(c("base", "fort"), each = 8), household_id = rep(1:8, 2),
    p = c(1, 0, 1, 0.5, NA, 0, 1, 1, 0, 0, 1, 0.25, NA, 0, 0.5, 1),
    ok = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE),
    intake = c(3, 5, 2, 8, NA, 6, 1, 4, 4, 6, 2, 9, NA, 7, 2, 5)
  )
  new_hces_tbl(data, "hces_inadequacy", key = c("scenario", "household_id"))
}

es_design <- function(lonely = "adjust") {
  as_hces_design(es_households(), lonely_psu = lonely)
}

# The reference: survey on a design built by hand, the domain as a subset.
ref_design <- function(y, keep) {
  h <- es_households()
  inside_ref <- keep & !is.na(y)
  h$y <- ifelse(is.na(y), 0, y)
  d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         nest = TRUE, data = h)
  d[inside_ref, ]
}

pick_est <- function(e, scenario) e[e$scenario == scenario, ]
