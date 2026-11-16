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
  `hces_estimate` (`estimate_households()` and `estimate_difference()`;
  the other two estimators already have `variable`), or skip the key check for
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

- **Where:** `tests/testthat/test-anchors.R:11-22` (tolerance 1%).
- **Run:** the package gives 1977.6, 2343.0 and 3928.9 kcal against 1975,
  2355 and 3925 (+0.13%, -0.51%, +0.10%). With the equation of the other
  adult band the first example gives 1991.4 (+0.83%): inside the
  tolerance. The second and third (-2.2%, -3.9%) do fail.
- **Fix proposed:** round the BMR to 0.1 MJ as the report does and compare
  within 1 kcal (by hand here: 5.4 × 1.53, 5.6 × 1.76 and 7.3 × 2.25 MJ are
  1974.7, 2355.6 and 3925.7 kcal). It needs the BMR as an intermediate
  value. P203.

### V2.2 (minor). The Table I-7 anchor does not reach the bioavailability

- **Where:** `tests/testthat/test-anchors.R:42-51`: the probability is
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

## 12e.3 (commits `f38955f`, `8fed72f`): limits of the method, two audit rows

Run on `hces_example` and on `hces_fixture()`, before and after: the
tables of the chain (`convert_units()` to `above_ul()`) have the same
columns and the same values; only the logs differ, by the rows approved
(`period_days`, `apparent_intake_not_usual_intake`,
`average_content_understates_ul`, and `compliance_below_one` now one row
per scenario instead of one count). The tests of the three rows have
expected values worked out by hand from the fixtures.

### V3.1 (major). The report still prints the understated share as its safety figure; the bound at compliance 1 is not there

- **Approved:** finding 9, "the results at compliance 1 as the upper bound
  of the upper-level exhibit"; R2-D4, "the audit row and the bound at
  compliance 1 in 12e.3".
- **Done:** the flagged row, the two help pages, both figures in the
  vignette, and a sentence under the exhibit
  (`inst/report/_scenarios.R:143-168`, term `ul_average_content`): "the
  same levels at compliance 1 give its upper bound". The exhibit does not
  compute that bound. On `hces_example` the reader of the results report
  sees 0.59% and is told that a higher figure exists, not that it is
  19.7%.
- **State:** recorded as P179 (medium, task 12), which waits for the
  all-or-nothing model. That is a deferral of an approved correction of a
  major finding, decided by the working session; `docs/roadmap.md` does
  not name P179 in any step.
- **Proposed:** the maintainer approves the deferral, or the column at
  compliance 1 is added to the exhibit in 12e.5.8 (the report already has
  the scenarios table; one more call of `apply_scenario()` with
  `compliance = 1`). In any case before a report leaves the project.
  Question 1 of the handoff.

### V3.2 (minor). Fix (c) of finding 3 is not done

The vignette does not show the sensitivity by number of days as a domain;
it is P182 (medium), also absent from the roadmap. Recorded openly in
P157. Same question as V3.1: an approved part moved without a decision.

### V3.3 (minor). The period of the note is that of the run, not of the rows judged

- **Where:** `R/inadequacy-log.R` (`usual_intake_row()` reads the last
  `period_days` note of `apparent_intake()` in the log).
- **Run:** the intake of `hces_example` cut to its first 100 households
  (attributes restored) gives, in `inadequacy()`, "period_days of the
  records used: 7 to 30" with `n_households = 100`: the range of the 1964
  households of the run. With the log row removed the detail is "not
  recorded" (right).
- **Why it matters:** only when P182 is done: a domain of 7-day households
  would carry the range of all. The text of the note is true as written
  ("of the records used" by `apparent_intake()`); no change before P182.

### Not findings

- A scenario below compliance 1 is flagged whichever nutrient it adds, as
  long as one UL of the call is assessable (run: a scenario of iron alone
  at 0.5 is flagged; iron has a UL, so it is right). A scenario that adds
  only a nutrient without a UL would be flagged too; harmless.
- With every compliance at 1, no `compliance_below_one` row is written:
  the same as before the diff (run on both versions).

## 12e.4 (commits `a6d064e`, `ff3861b`, `bd97aee`, `1605a94`): intervals, effective size, bounds, parallel tests

Findings 10 to 14 and 18 are done as approved. Run on `hces_example` and
on `hces_fixture()`, before and after: the estimate, the standard error
and the limits of `estimate_households()` are identical for a proportion
(Korn-Graubard, logit, and `ci_method = "mean"` with `df = "design"`), a
mean and a median; the only changed values are the limits of the
differences without variation (9 cells of the example, 2 of the fixture:
0 to 0 became missing) and `n_effective` of `flag_presentation()`. New
columns: `n_effective`, `interval_note`.

Mutations run on a copy of `1605a94` (files `test-estimate-intervals.R`,
`test-estimate.R`, `test-flag-presentation.R`, `test-golden-example.R`);
**all nine are caught**: `survey.adjust.domain.lonely` set to `TRUE`, or
not set; the divisor of the variance `sum(w) - 1`; the cap at `n`
removed; an unweighted variance; the `no_variation` rule removed;
`df < 0` instead of `df <= 0`; `flag_presentation()` ignoring the
`n_effective` column; `exact` decided on `se == 0`.

### Question 3. The effective size

- **A proportion (0/1 outcome).** NCHS 2017, p. 3 (as quoted in finding
  10 and in `R/estimate-korn-graubard.R`): the effective size is `n` over
  the design effect, `p(1 - p) / se²`. `effective_n()`
  (`R/estimate.R:200-209`) computes `s² / se²` with `s²` the weighted
  variance of the values, divisor the sum of the weights; for a 0/1 value
  that is `p(1 - p)` exactly. Run: 400 households, weights 1 and 20, a
  0/1 outcome: `n_effective` 220.7892, `p(1 - p) / se²` 220.7892. **As
  the standard defines it.**
- **A mean (a probability).** The standard defines nothing for a mean;
  the package extends it with the same ratio, which is `n` over the
  design effect of `survey`: in five cells (the clustered example of
  finding 10; iron at 10% on `hces_example`, national and three regions)
  `n_effective` equals `n / deff` of
  `survey::svymean(deff = "replace")` times `(n - 1) / n` to the seven
  digits printed (9.000 against 9.045 × 0.995; 1242.627 against
  1243.272 × 1927/1928; 419.5243, 430.5032, 403.2276). The factor is the
  divisor: `survey` divides the variance by `n - 1`, the package by the
  sum of the weights, which is what makes the 0/1 case equal to the
  standard. Coherent; the help says "weighted variance of the values".
- **The golden values follow.** `n_effective_iron_b010_baseline` of
  `golden-example.csv` (1928 to 1242.627) is reproduced above from
  `survey` alone. In `golden-fixture.csv` the size falls from 36 (the
  cap) to 15.04, below 30, so the status goes from review (1) to
  suppress (2): the criterion of the standard, now applied.

### V4.1 (minor). The effective size is checked against itself

- **Where:** `R/estimate.R:200-209`; `data-raw/golden_example.R:62-66`;
  `tests/testthat/test-estimate-intervals.R:129-150`.
- The three hold the same expression, with the same names
  (`sum(w * (y - sum(w * y) / sum(w))^2) / sum(w)`): the golden value and
  the "by hand" test repeat the formula of the package, the case of
  section 5 of the review v0.2. The second expectation of that test takes
  `estimate`, `se` and `n` from the package's own output
  (`test-estimate-intervals.R:144-146`): **the one test of the key
  checks whose expected value comes from the package.** It is an
  identity (the 0/1 case equals the formula of the standard) and it does
  fail under the mutation of the divisor.
- **Fix proposed:** one anchor test against
  `n / survey::deff(survey::svymean(~y, d, deff = "replace")) * (n - 1) / n`,
  which agreed here in five cells. P205.

### V4.2 (minor). Without degrees of freedom the rule depends on the argument `df`

- **Where:** `R/estimate.R:183` (`if (dfv <= 0)`, with `dfv` the value
  of the argument, `R/estimate.R:152-153`).
- **Failing input (run):** the ten households of the first PSU of
  `hces_example` as the domain, values 0.1 to 1.0:

  | `df` | `se` | Limits | `df` | `interval_note` | `flag_precision()` |
  |---|---|---|---|---|---|
  | `"domain"` | 4.2e-17 | missing | 0 | `no_degrees_of_freedom` | `ok` |
  | `"design"` | 4.2e-17 | 0.55 to 0.55 | 194 | missing | `ok` |
  | `30` | 4.2e-17 | 0.55 to 0.55 | 30 | missing | `ok` |

  With `df = "design"`, the option of the ENGIH acceptance, a domain
  inside one PSU is still an interval of width zero presented as
  certainty (findings 11 and 12 of the review v0.2), without a log row.
- **Fix proposed:** decide `no_degrees_of_freedom` on the degrees of
  freedom of the domain (`survey::degf(sub) <= 0`) whatever `df` says;
  `df` then only chooses the quantile. P204.

### V4.3 (minor). `flag_precision()` says `ok` for a cell without an interval

- **Where:** `R/estimate-difference.R:170-176` (`precision_status()`: a
  missing half-width is never `wide_interval`).
- **Failing input (run):** the first row of the table above, `min_n = 5`,
  `max_half_width = 0.1`: `low_precision = FALSE`,
  `precision_status = "ok"`, `n_effective = 10` (equal to `n`). The same
  for a median with `undefined_quantile_interval`. Finding 12 described
  this cell as "neither `exact` nor flagged by `flag_precision()`"; it is
  now not `exact`, and still not flagged. P184 of the self-review covers
  `flag_presentation()` only.
- **Fix proposed:** a status `no_interval` (low precision) for
  `no_degrees_of_freedom` and `undefined_quantile_interval`, and a missing
  `n_effective` where the standard error cannot be estimated. P204.

### V4.4 (minor). `age_months` is now total months for every member, and the contract does not say so

- **Where:** `R/validate-standard.R:64-80`; `R/schema-standard.R:35`
  ("age in months, for infants").
- **Failing input (run):** a child with `age_years = 3` and
  `age_months = 5` (the "years and remaining months" form of many
  questionnaires) is an `hcesfort_error_value`; `age_months = 41` passes.
  The rule is the approved one and the message states it; the schema
  sentence should say "months since birth". The ENGIH design does not
  map `age_months`, so A2 is not affected. P206.

### Not new

- The difference exhibit of the report prints `NA` for the two limits of
  a cell without variation, with no word (`inst/report/` does not read
  `interval_note`): it is P184.
- The two effective sizes of one cell (interval and criterion): P185.

### Question 4. Parallel tests

No shared state found. Checked in `tests/testthat/`:

- **Files:** every written file is a `withr::local_tempfile()` or a
  `withr::local_tempdir()`; the fixtures, `R/`, `data-raw/` and
  `docs/feedback/` are only read.
- **Snapshots:** one file uses `expect_snapshot()`
  (`test-report-snapshots.R`), so one process writes
  `_snaps/report-snapshots.md`.
- **Options:** set only through `withr` (`test-estimate.R:321`,
  `test-estimate-intervals.R:91,104`, `helper-report.R:39`) or by
  `with_lonely_psu()`, which restores them; the test of P167 checks the
  restoration.
- **Objects across files:** the functions used by more than one test file
  (`es_*`, `as_*`, `pick_est()`, `ref_design()`, `fixture_carrier()`,
  `no_rules()`) are all in `helper-*.R`; there is no `setup-*.R`.
- **CI:** the coverage workflow passed on `1605a94` (run 84, the 90%
  gate) with the parallel setting.

One dependence on order inside a file, older than the diff and not
caused by the parallel setting: `shipped_results()`
(`test-report-results.R:29-38`) defers the `withr::local_dir()` of
`knit_report()` to `teardown_env()`, so from its first call to the end
of the file the working directory is the temporary folder of the knit. A
later test of that file that used `test_path()` would fail by position.
None does today. P203.

### Question 5. Blockers for the ENGIH acceptance (A3)

None found in the diff.

- `ci_method = "mean"` with `df = "design"`: estimate, standard error
  and limits identical before and after on both datasets (run).
- The original (`scripts/07_riesgo_inadecuacion.R:117-125`, `:262-265`)
  sets no option of `survey`; `survey.adjust.domain.lonely = FALSE` is
  the default of `survey`, so fixing it changes nothing there.
- The range check: the original takes `survey_mean()` of probabilities,
  of logical values and of a difference; the means of intake go through
  `statistic = "mean"`.
- Cells without variation now have no limits, where the original printed
  the estimate twice. The control figures have none: 0 of 800 rows of
  `riesgo_inadecuacion.csv` with a half-width of 0, 0 of 336 rows of
  `diferencias_escenarios.csv` with a difference of 0 (run on
  `data/auditoria/cifras_control/`).
- To watch, not blockers: V1.1 (judge each estimate table before
  stacking, until P201); V4.2 (with `df = "design"` a domain inside one
  PSU gets a zero-width interval; no ENGIH domain should be that small).

## Summary

| Question | Answer |
|---|---|
| 1. Done as approved, nothing else changed? | Yes for the figures: the tables of the chain and the estimates are unchanged outside the approved rules. One unapproved change of behaviour: V1.1 (stacked estimate tables refused). Two approved parts deferred without a decision: V3.1 (the bound at compliance 1 in the report), V3.2 (sensitivity by days). |
| 2. Can the new tests fail? | Yes: 17 mutations run, 15 caught by the tests of the step; the other two are an equivalent mutation (V2.3) and one caught only by an older test (V2.2). One expected value from the package's output, and one formula repeated three times (V4.1). |
| 3. Effective size | As the standard defines it for a proportion; for a mean it is `n` over the design effect of `survey` up to `(n - 1) / n`. The golden changes follow. |
| 4. Parallel | No shared state found. |
| 5. Blockers for A3 | None. |

| Finding | Severity | Item |
|---|---|---|
| V1.1 stacked estimates refused by the key check | major | P201 |
| V3.1 the bound at compliance 1 is not in the report | major | P179, question 1 |
| V1.2 range check reads rows outside the domain | minor | P202 |
| V1.3 a quantity in [0, 1] passes as a proportion | minor | none |
| V2.1, tests of 12e.1, `shipped_results()` | minor | P203 |
| V2.2, V2.3 | minor | none |
| V3.2 sensitivity by days not done | minor | P182, question 1 |
| V3.3 period of the note | minor | with P182 |
| V4.1 effective size checked against itself | minor | P205 |
| V4.2, V4.3 no degrees of freedom | minor | P204 |
| V4.4 `age_months` contract sentence | minor | P206 |
