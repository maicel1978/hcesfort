# Review of steps 12e.1 to 12e.4

- **Date:** 2026-11-16. **Model:** Fable. **Brief:** `docs/review-12e-brief.md`.
- **Scope:** the diff `491eeb4..1605a94` of `R/`, `tests/`, `inst/report/`
  and `DESCRIPTION`, against findings 1, 2, 3, 6, 9, 10 to 15 and 18 and
  section 8 of `docs/review-v0.2.md`, and decisions R2-D1 to R2-D9 and
  R3-D1 to R3-D9.
- **Method:** every "run" below was run in this session on the installed
  package at `1605a94`; "before" is the package at `491eeb4`, installed in
  a separate library. No package code was changed.
- Findings are numbered `V<step>.<n>`. Severity as in the review v0.2:
  **blocker**, **major**, **minor**. Findings only; what is right is not
  listed.

## 12e.1 (commit `86731d8`): key check, range of a proportion

Findings 1 and 2 are done as approved: `require_hces()` refuses a repeated
or absent key (`R/hces-tbl.R:56-81`), the two estimators call
`audit_check_rows()`, and a proportion outside [0, 1] is an
`hcesfort_error_value`. Run with the real verbs, not only the test helper:
`dplyr::bind_rows(use, use[1:5, ])`, a fanning `dplyr::left_join()` and
base `rbind()` all keep the class and the key attribute and are refused.

### V1.1 (major). Stacked estimate tables are now refused by `flag_presentation()` and `flag_precision()`

- **Where:** `R/hces-tbl.R:35` (the key check runs for every carrier);
  `R/estimate.R:140`, `R/estimate-difference.R:88-89` (the key of an
  `hces_estimate` is the group columns and `by`; it has neither `variable`
  nor `statistic`); `R/flag-presentation.R:80`,
  `R/estimate-difference.R:152`.
- **Failing input (run):**

  ```r
  ea <- estimate_households(design, use, "acquired",
                            ci_method = "korn_graubard")
  use$acq2 <- use$acquired
  eb <- estimate_households(design, use, "acq2",
                            ci_method = "korn_graubard")
  flag_presentation(dplyr::bind_rows(ea, eb))
  #> Error (hcesfort_error_key): The key (level and vehicle) of
  #> `estimates` is repeated.
  ec <- estimate_households(design, use, "acquired", statistic = "mean")
  flag_precision(dplyr::bind_rows(ea, ec), min_n = 30,
                 max_half_width = 0.1)       # same error
  ```

  Before (`491eeb4`): both calls return 16 rows.
- **Why it matters:** this is a change of behaviour that no approval
  covers. Finding 1 is about tables matched by household; an estimate
  table is not matched by key by any function (`flag_*` work row by row).
  Stacking the estimates of two variables, two statistics or two `by`
  before judging them is the ordinary way to build one table of results;
  an adapter will do it. The message blames "a join or a `bind_rows()`
  between two hcesfort functions", which is here the intended use.
- **Fix proposed:** add `variable` and `statistic` to the key of an
  `hces_estimate` (three constructors), or skip the key check for
  `hces_estimate`. A test: `flag_presentation()` of two bound estimates of
  different variables. P201.

### V1.2 (minor). The range check reads the rows outside the domain

- **Where:** `R/estimate.R:123` (`check_proportion_values(x, value, …)`
  on the whole column, after `align_values()` has already set the rows
  outside `domain` to missing).
- **Failing input (run):** `it$ok <- it$iron_mg <= 1` on the intake of
  `hces_example` (10 households); `estimate_households(design, it,
  "iron_mg", domain = "ok")` aborts for the 1918 rows that are not
  estimated. Harmless (an error, not a wrong figure); the check on
  `a$values` would be exact. P202.

### V1.3 (minor, a limit of the approved fix, no change proposed)

A quantity whose values all lie in [0, 1] still passes as a proportion
with the default `statistic`: the iron intake of `hces_example` divided
by 100 (the scale of thiamin, riboflavin or copper in mg) returns
`statistic = "proportion"`, 0.1045 (0.1020 to 0.1071, logit). R2-D2 keeps
the default; the help says what a proportion needs. Recorded so that the
adapter and the vignette always name `statistic` for an intake.

### Tests of 12e.1 (question 2)

`tests/testthat/test-carrier-key.R` and the new block of
`test-estimate.R:486-509`: every expected value (rows `4:5`, `17L`, 13
rows, `n_records` 2) is worked out from the fixture, none from the
package's output. Two gaps, both minor:

- `repeat_rows()` (`test-carrier-key.R:9-13`) copies the attributes by
  hand; no test passes through `dplyr::bind_rows()` or a `left_join()`,
  the verbs the error message names. They do keep the attributes today
  (run above); a change in `dplyr` would not be seen. P203.
- The test "the functions of the chain refuse a repeated key" covers 9 of
  the 20 call sites of `require_hces()`. Not covered: `link_composition()`,
  `flag_outliers()`, `vehicle_coverage()`, `food_group_intake()`,
  `food_group_shares()`, `estimate_unlinked()`, `linkage_ladder()`,
  `unmatched_foods()`, `readiness_checks()`, `check_crosswalk(grams =)`,
  `flag_precision()`, `flag_presentation()`. The check lives in
  `require_hces()` itself, so the risk is only a call site that stops
  calling it. P203.
