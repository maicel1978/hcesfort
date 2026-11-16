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

## 12e.2 (commits `9d12d3b`, `c6fbcc7`, `5887473`): anchors, optional columns

Tests only, no package code: nothing to compare with an approval except
the list of section 8 of the review v0.2, which is covered (FAO examples,
IOM Table I-7, conservation, `svycontrast`, full-design ratio, logit
interval, optional columns; the round trip of the review's list is the
conservation test). The `surveytable` anchor was dropped as R2-D7 records.

**No expected value of the anchors comes from the package's output.** The
published values are typed in the test; the three reference tests build
their own `survey::svydesign()`; `golden-optional.csv` is written by
`data-raw/golden_example.R` in base R and `survey`.

Mutations run in this session on a copy of `1605a94` (file filter
`golden`, tolerance of the test 1e-8):

| Mutation | Result |
|---|---|
| `household_share` ignored (`R/units.R:87`) | the optional golden test fails |
| `yield_factor` ignored (`R/composition.R:68`) | fails |
| `age_months` ignored (`R/afe-energy.R:35`) | fails |
| `meals_home_share` ignored (`R/afe.R:85`) | fails |
| own `weight_kg` of a member ignored (`R/afe-energy.R:69`) | fails |
| single-PSU stratum treated as `certainty` (`R/design.R:122`) | fails |
| bioavailability ignored in the iron probability (`R/inadequacy-probability.R:124`) | `test-anchors.R` passes; `test-inadequacy.R` fails (3 tests) |

### V2.1 (minor). The first FAO example cannot tell the two adult bands apart

- **Where:** `tests/testthat/test-anchors.R:11-23` (tolerance 1%).
- **Run:** the package gives 1977.6, 2343.0 and 3928.9 kcal against 1975,
  2355 and 3925 (+0.13%, -0.51%, +0.10%). With the equation of the other
  adult band the first example gives 1991.4 (+0.83%): inside the
  tolerance. The second and third (-2.2%, -3.9%) do fail.
- **Fix proposed:** round the BMR to 0.1 MJ as the report does and compare
  within 1 kcal (by hand here: 5.4 × 1.53, 5.6 × 1.76 and 7.3 × 2.25 MJ are
  1974.7, 2355.6 and 3925.7 kcal). It needs the BMR as an intermediate
  value. P203.

### V2.2 (minor). The Table I-7 anchor does not reach the bioavailability

- **Where:** `tests/testthat/test-anchors.R:44-53`: the probability is
  asked at 0.18, the bioavailability of the table itself, so the factor
  `b / b0` is 1. The band limits typed in the test are the percentiles of
  Table I-4 that the package ships (`ref_iron_requirements`: 4.42, 4.88,
  5.45, …); what the test adds is the 12 probabilities and the two tails.
- **Run:** the mutation of the last row of the table above.
- No change proposed: the published table has one bioavailability, and
  the hand tests of `test-inadequacy.R` catch the mutation. Recorded so
  that the comment of the test is not read as an anchor of the scaling.

### V2.3 (minor). The adult `age_months` of the optional fixture tests nothing

- **Where:** `tests/testthat/fixtures/hces_fixture.R` (household 1, member
  2, `age_months = 450`, "which must be ignored").
- **Run:** with `months >= 12` no longer discarded
  (`R/afe-energy.R:39`), the golden tests pass: the monthly table is
  looked up only for an age below 1, so the value never reaches a result.
  The fixture row documents a rule that no golden value can break.
  No change needed; the validator of 12e.4 (V4.x) is the real guard.
