# Hostile review v0.2: the core and the method

- **Date:** 2026-11-15. **Commit reviewed:** `929aca2`. **Model:** Fable,
  high effort. Brief: `docs/review-v0.2-brief.md`.
- **Stance:** three reviewers at once: an rOpenSci statistical software
  reviewer, a reviewer of a nutrition journal who knows HCES methods, and a
  JOSS reviewer. Hostile but fair.
- **Scope:** the core and the method. The reports are out of scope; they
  are cited only where a sentence of theirs states a claim of the method.
- **No package code was changed.** Every script of this review was run
  from a scratch directory and is not in the repository; the snippets below
  reproduce each result.

## 0. Verdict

The arithmetic of the chain is right as far as this review could push it:
an independent brute-force replication, four independent formulations with
`survey`, the reference implementation of the CDC and three published
documents all agree with the package (section 5.4). The design-based
estimators are the best-validated part of the package.

What is wrong is at the edges of the contracts and in what the method is
said to estimate.

**Must be fixed before the ENGIH validation (A2 to A4):**

1. A table with a repeated key is accepted and changes the estimates
   without a word (finding 1, blocker).
2. `estimate_households()` takes any number as a proportion (finding 2).
3. Nine of the thirteen core estimators have no expected value that does
   not come from AI-written arithmetic. Six external anchors were verified
   in this session and are ready to become tests (finding 6). Without them
   the ENGIH comparison is the only check that is not AI against AI, and it
   shares the method of the original (section 5.5).

**Must be fixed before any figure is shown outside** (the render of Q4 is
for the maintainer's reading; this applies from the first expert round):

4. The limits of the method are not written anywhere a user reads: usual
   intake (finding 3) and the share above the upper level under partial
   compliance, which the example understates by a factor of about thirty
   (finding 9). Correction 9 of the v0.1 review was never done.
5. The README says the package has no functions (finding 7).

**Must be decided before acceptance step 2 (A4), because they change
figures:** infants in the adult equivalents (finding 4), which flour is
fortifiable (finding 5), the gate on missing composition values (finding 8).

**Can wait** (v0.2 or v1.0): findings 10 to 19.

One blocker, eight major, ten minor. They are recorded in
`docs/improvements.md` as P155 to P175.

## 1. What was done

- Read: `CLAUDE.md`, every file of `docs/`, 43 of the 74 files of `R/` in
  full (every file behind an estimator, the schemas of the standard and
  user tables, the carrier), the test files of the estimators in full and
  the head of every other, `data-raw/SOURCES.md`, the reference CSVs,
  `data-raw/golden_example.R`. The validators were exercised by running
  them (finding 14), not read line by line; the audit, label, readiness
  and report-template files were not reviewed.
- Ran `devtools::test()` on the source tree: **48 files, 492 tests, 3,194
  expectations, 0 failures, 0 skipped** (R 4.3.3, survey 4.5, srvyr 1.3.1,
  dplyr 1.2.1, testthat 3.3.2). The six report files take 652 s of 750 s
  (87%). `devtools::check()` and the lint were not re-run: no code changed
  (state of the handoff: 0 errors, 0 notes, 1 warning for a missing
  `qpdf`).
- Re-ran `data-raw/golden_example.R`: the two golden files are reproduced
  byte for byte (`git status` clean), so they are the output of the base-R
  script, not of the package.
- Ran the chain on `hces_example` and cross-checked the estimators against
  forms of `survey` the tests do not use (section 5.4).
- Wrote a second, independent replication of the chain by loops in base R
  on the paths the golden chain does not exercise (section 5.4).
- Ran 30 single-line mutations of the code written since the v0.1 review
  (section 6).
- Ran the edge cases of the brief (section 4).
- Opened seven documents (section 9); every quotation below was read in
  the document in this session.

## 2. Findings

Severity: **blocker** = wrong figures without notice, to fix before the
ENGIH validation; **major** = to fix or decide before a figure is shown
outside or before acceptance step 2; **minor** = can wait. "Task" is the
roadmap step proposed; `12e` is a new step, "corrections of the v0.2
review", after the maintainer's approval.

### Finding 1 (blocker). A repeated key is accepted and changes the result

- **Where:** `R/hces-tbl.R:30-48` (`require_hces()` checks the class and
  the log, not the key); `R/design.R:104` (the values of a household are
  written into a matrix: the last row wins); `R/intake.R:88`,
  `R/scenario.R:106-107` (`match()`: the first row wins);
  `R/estimate.R:92-119` and `R/estimate-difference.R:53-88` do not call
  `audit_check_rows()`, so not even the change in the number of rows is
  logged.
- **Evidence (run):**

  ```r
  d <- as_hces_design(hces_example$households, "adjust")
  e1 <- estimate_households(d, intake, "iron_mg", statistic = "mean")
  in2 <- dplyr::bind_rows(intake, intake[1:50, ])      # 50 households twice
  in2$iron_mg[nrow(in2) - 0:49] <- 1e6
  e2 <- estimate_households(d, in2, "iron_mg", statistic = "mean")
  c(e1$estimate, e2$estimate, e1$n, e2$n)
  #> 10.45061  19644.57  1928  1928      (no error, no log row)
  ```

  Also accepted: `apparent_intake()` with three households twice in `afe`,
  `inadequacy()` with 50 households twice, `apply_scenario()` with rows of
  `use` twice.
- **Why it matters:** `CLAUDE.md` makes checked joins non-negotiable
  ("records are never dropped or duplicated silently"). The package tells
  the user that `mutate()`, `filter()` and `left_join()` keep the carrier;
  a `left_join()` that fans out (a household table joined to a table with
  two rows per household) is the ordinary way to get here. An adapter can
  do it between two calls, and a tolerance of 1e-6 at the end would say
  that something is wrong, not where.
- **Fix:** `require_hces()` aborts with `hcesfort_error_key` when
  `anyDuplicated()` of the key columns is not zero (the key is already an
  attribute); the estimators call `audit_check_rows()`. Tests: every
  exported function that takes a carrier refuses one with a repeated key.
  No interface changes. **Task 12e.1 (Opus), before A2.**

### Finding 2 (major). Any number is accepted as a proportion

- **Where:** `R/estimate-checks.R:5-23` (the value must be logical or
  numeric, nothing else); `statistic = "proportion"` is the default
  (`R/estimate.R:92`).
- **Evidence (run):** on 12 households with intakes between 2 and 12:

  | Call | Result |
  |---|---|
  | `estimate_households(d, intake, "iron_mg")` (defaults) | base R `simpleError` from `survey`: "y values must be 0 <= y <= 1" |
  | `ci_method = "mean"` | `statistic = "proportion"`, estimate 7.08, interval 3.23 to 10.93 |
  | `ci_method = "korn_graubard"` | estimate 7.08, `ci_low = 0`, `ci_high = NaN`, a base warning; `flag_presentation()` then gives `n_effective = -22.4` |

- **Fix:** for a proportion, values outside [0, 1] are an
  `hcesfort_error_value` naming `statistic`. Keep the default (question 2).
  **Task 12e.1 (Opus).**

### Finding 3 (major). The method is defined on usual intake and nothing says the package does not measure it

- **Where:** `R/inadequacy.R:1-10` and `R/above-ul.R:1-36` (the only
  caveats: households not persons; the adult UL). A search for "usual
  intake" in `R/`, `vignettes/`, `README.md` and `inst/report/` returns
  nothing. `vignettes/getting-started.Rmd:102` labels a 0/1 cut-point
  result "Probability of inadequacy (folate)".
- **Sources, read in this session:**
  - IOM 2000b, p. 73: "To accurately determine the proportion of a group
    that has a usual intake of a nutrient less than the requirement,
    information on both usual intakes and nutrient requirements for each
    individual in the group is needed."
  - IOM 2000b, p. 81, Box 4-1: the cut-point "works well when: intakes are
    accurately measured; actual prevalence in the group is neither very low
    nor very high; estimated usual intakes of individuals are independent
    of each individual's requirement; the distribution of requirements is
    approximately symmetrical; variability in intakes among individuals in
    the group is greater than the variability in requirements".
  - IOM 2000b, p. 99: "the estimate of the usual intake distribution
    obtained using one day of intake data will have the incorrect variance;
    the variance of the estimated distribution will contain an unwanted
    day-to-day variability component. Therefore, estimates of the
    prevalence of nutrient inadequacy will be biased."
  - IOM 2001, Table I-7, p. 703, footnote a: the probabilities "may be
    used … to evaluate adjusted distributions of usual intakes … Not to be
    applied in the assessment of individuals."
- **What follows:** the package applies both methods to what a household
  acquired in `period_days`, divided by its adult equivalents, with no
  adjustment. Purchase frequency and stocks add variance that usual intake
  does not have. The share below a fixed threshold then moves towards 50%:
  up when the threshold is below the median, down when it is above; the
  share above an upper level goes up. This is arithmetic, not a citation.
  The rule the ENGIH adapter keeps as default (dividing by the days with a
  record, E4) gives the widest distribution: a household with one diary day
  is a one-day observation.
- **State:** H7 of the v0.1 review asked for a "Limits of the method"
  section. Its correction 9 was given to Sonnet "with task 12"; task 12 has
  been behind 12b, 12c and 12d since, and R-D9 moved the text to a methods
  vignette that does not exist. Two generations of reports were built
  first.
- **Fix:** (a) a section "What the figures are and are not" in
  `?inadequacy`, `?above_ul`, the README and the vignette, with the four
  quotations above; (b) one audit note of `inadequacy()` and `above_ul()`
  (`apparent_intake_not_usual_intake`, with the range of `period_days` of
  the records used); (c) the vignette shows the sensitivity by number of
  days as a domain. **Task 12e.3 (Sonnet for the text, Opus for the note),
  before the first expert round;** the methods vignette stays in task 12
  (P110).

### Finding 4 (major). Infants count their whole energy requirement in the adult equivalents

- **Where:** `R/afe-energy.R:14-22`; decision 4 of task 5 for pregnancy
  and lactation. M2 of the v0.1 review was never entered in
  `docs/improvements.md`.
- **Evidence (run):** a woman of 25 years alone is 1.000 AFE; with an
  infant of two months, 1.240. The intake per AFE of that household falls
  19% although the infant eats none of the food recorded. `hces_example`
  has 128 infants.
- **Source, read in this session:** FAO/WHO/UNU 2004, section 3.4, the
  document the table comes from: "exclusive breastfeeding is strongly
  recommended during the first six months of life, followed by a
  combination of breastmilk and complementary foods throughout infancy …
  a healthy woman can produce enough milk to provide the energy required
  by a healthy, exclusively breastfed infant of up to six months of age."
  An HCES does not record breast milk.
- **Status of the assumption:** unsupported. No document opened says that
  an infant's full requirement should be charged to the household's food.
  What the published HCES work does is not known here: Table S1 of Tang et
  al. 2021 was not available (v0.1 review, section 9.1).
  `# SOURCE PENDING`.
- **Fix:** an argument for the share of an infant's energy expected from
  the household's food, by month of age, required when `members` has
  infants and with no default; 1 reproduces today's rule (acceptance step
  1). The additions for pregnancy and lactation (P57) in the same step.
  Method: Fable; code: Opus. **Before A4.**

### Finding 5 (major). Every gram of the vehicle is fortified, whatever its origin

- **Where:** `R/vehicle-use.R:11-17` (every included record with grams
  counts); `origin` is an optional column of `acquisitions`
  (`R/schema-standard.R:70`) that no function reads; `compliance` is the
  only reduction.
- **Source, read in this session (WHO 2009, p. 1, md5 of the registry):**
  the guidance is for flours "milled in industrial roller mills (i.e. >20
  metric tons/day milling capacity)", and the amounts to add should be
  based on "the usual consumption profile of 'fortifiable' flour (i.e. the
  total estimated amount of flour milled by industrial roller mills,
  produced domestically or imported, which could in principle be
  fortified)".
- **What follows:** own production, gifts in kind and the product of small
  mills receive the level. `who2009_levels()` is read with an availability
  that includes them (its example uses the vehicle group, flour in bread
  and pasta included). `compliance` means two things at once: the share of
  the vehicle that could be fortified, and the share of that which is.
  Coverage of "the vehicle in any form" and of "the fortifiable vehicle"
  are different indicators in the coverage literature the report design
  cites (Aaron et al. 2017; not opened: `# SOURCE PENDING`).
- **Fix:** an optional logical column `fortifiable` in `acquisitions`, set
  by the adapter from `origin`, the food code or the place of purchase;
  `vehicle_coverage()` requires an argument that says whether to use it
  when the column exists (the pattern of `meal_share`), returns both
  coverages and feeds the scenarios with the fortifiable grams. Contract
  change: Fable designs. **Before A4.**

### Finding 6 (major). Nine of thirteen core estimators are validated only by AI-written arithmetic

Section 5. **Task 12e.2 (Opus), before A3.**

### Finding 7 (major). The README describes a package that does not exist

- **Where:** `README.md:12-20` ("The package has no user-facing functions
  yet"; "What it will do"). `DESCRIPTION`: version `0.0.0.9000`, a
  no-reply e-mail (P39). `NEWS.md` has one heading for everything.
- **State:** H5 of the v0.1 review, still open; the package now exports 50
  functions and has a vignette.
- **Fix:** the status paragraph, the chain in ten lines, the limits of
  finding 3, the version `0.1.0` when task 12 closes. **Task 12e.3
  (Sonnet).**

### Finding 8 (major). The coverage gate counts grams, not the nutrient

- **Where:** `R/risk-checks.R:196-205` (share of edible grams with a
  value); `R/intake.R:142-147` (a missing value adds nothing).
- **Evidence (run):** three households, each with 400 g of rice a day
  (vitamin A 0) and 10 g of liver whose vitamin A is missing in the
  composition table:

  ```r
  inadequacy(intake, req_vitamin_a, min_coverage = 0.95, min_records_used = 0.95)
  #> intake 0, coverage 0.9756, p_inadequate 1 for every household
  #> log: "vitamin_a: 0.9756 (min_coverage 0.95)"
  ```

  The gate passes and every household is inadequate because the only
  source has no value.
- **Why it matters:** for nutrients concentrated in few foods (vitamin A,
  vitamin B12) grams say little. E21 of the original analysis is this
  defect; the gate was written against it.
- **Fix:** the gate cannot know the missing amount. What it can do: (a)
  `inadequacy()` and `above_ul()` list in the log, per nutrient, the foods
  with a missing value and their grams (the data are in `content`); (b)
  the help says that the gate is by grams and what that misses; (c)
  `check_crosswalk()` already counts missing values by food: the readiness
  checks could require that no food above a share of grams given by the
  caller lacks a value. Method: Fable (one paragraph); code: Opus.
  **Before A4;** related to P96.

### Finding 9 (major). Under partial compliance the share above the upper level is understated, and nothing says so

- **Where:** `R/scenario-log.R:102-139` and `R/above-ul-log.R:53-74` (no
  row about compliance); `?above_ul` and `?apply_scenario` (no sentence).
- **Evidence (run on `hces_example`):** share of households above the
  folic acid upper level, added part, Korn-Graubard interval:

  | Scenario | As shipped (average content, compliance 0.5 to 0.9) | Same levels, compliance 1 |
  |---|---|---|
  | `plus_rice` | 0.59% (0.30 to 1.05) | 19.68% (17.76 to 21.72) |
  | `plus_sugar` | 0.59% (0.30 to 1.05) | 19.68% (17.76 to 21.72) |
  | `plus_oil` | 0.59% (0.30 to 1.05) | 19.68% (17.76 to 21.72) |

  The right-hand column is what a household that buys a fully fortified
  product receives. If a share `c` of the product is fortified at the full
  level and the rest is not, the share above the upper level is near `c`
  times the right-hand column, not the left-hand one. The results report
  prints the left-hand column as its safety statement.
- **State:** H7.3 of the v0.1 review (an audit note at least), not done;
  P69 (the all-or-nothing model, high) is in v0.2. Tang et al. 2021 state
  this limit of their own average-content scenario (p. 119; v0.1 review,
  section 9.1).
- **Fix now:** a flagged audit row of `above_ul()` when any scenario has a
  compliance below 1 (`average_content_understates_ul`), the sentence in
  both help pages, and the results at compliance 1 as the upper bound of
  the upper-level exhibit. **Task 12e.3 (Opus for the row).** P69 moves
  before A4 (question 4).

### Finding 10 (minor). The presentation standard is not conservative for a mean of probabilities

- **Where:** `R/flag-presentation.R:20-23`; the same claim is departure S2
  of the report (`inst/report/en/terms.csv:159`).
- **Evidence (run):** 200 households in 10 PSUs, the probability of each
  household equal to its PSU mean (0.30 to 0.70):

  | | Value |
  |---|---|
  | `n_effective` of the package, `p(1 - p) / se²` capped at `n` | 127.8 |
  | `n` divided by the design effect of that variable | 9.0 |
  | Status | `present` |

  The standard defines the effective sample size as "the sample size, n,
  divided by the design effect" (NCHS 2017, p. 3) and suppresses below 30.
  For a variable that is not 0/1, `p(1 - p)` is not its variance, so the
  formula overstates the effective size. On `hces_example`, iron at 10%
  bioavailability, `n_effective` equals `n` in all 15 cells of region by
  expenditure group, while `n` divided by the design effect is 68 to 219.
  The interval itself is not too narrow (0.397 to 0.603, close to the *t*
  interval).
- **Fix:** compute the effective size of a non-binary value from its own
  variance (`estimate_households()` returns the design effect, or
  `n_effective`), or keep the formula and correct the two sentences: the
  width criteria are conservative, the effective-size criterion is not
  applied. **Task 12e.4 or v0.2** (question 6).

### Finding 11 (minor). An interval of width zero is presented as certainty

- **Where:** `R/estimate.R:162-166` (mean), `R/estimate-difference.R:53-88`.
- **Evidence (run):** a scenario with level 0 on `hces_example`:
  `estimate_difference()` returns `estimate 0, se 0, ci_low 0, ci_high 0,
  n 1928`, no log row, and `flag_presentation()` says `present`. A mean
  or a median without variation gives the same (3, 0, 3, 3). A degenerate
  proportion has no interval, by decision (M5 of the v0.1 review); the
  other statistics do not follow it.
- **Fix:** the rule of the degenerate proportion for every statistic: no
  interval, a log row (`no_variation`). **Task 12e.4 (Opus).**

### Finding 12 (minor). No degrees of freedom: `NaN` limits, base warnings, and `exact` where nothing is exact

- **Where:** `R/estimate.R:149-174`; `R/estimate-difference.R:164-172`.
- **Evidence (run):** (a) a domain inside one PSU: `df = 0`, limits `NaN`
  with the base warning "NaNs produced", `se = 1.4e-17` (the linearised
  residuals of one PSU add to zero), so the cell is neither `exact` nor
  flagged by `flag_precision()`; (b) every stratum with one PSU under
  `lonely_psu = "certainty"`: `se = 0`, and `flag_precision()` reports
  `precision_status = "exact"`, documented as "every household of the cell
  has the same value", which is false here.
- **Fix:** `df <= 0` gives missing limits and a log row
  (`no_degrees_of_freedom`), as P116 did for the median; `exact` is
  decided on the values, not on `se == 0`. **Task 12e.4 (Opus).**

### Finding 13 (minor). A second global option of `survey` changes the standard errors

- **Where:** `R/estimate.R:218-234` sets `survey.lonely.psu` and nothing
  else.
- **Evidence (run):** two strata of two PSUs, a region present in one PSU
  of a stratum, `lonely_psu = "adjust"`: the standard error of the other
  region is 0.13440 with `options(survey.adjust.domain.lonely = FALSE)`
  and 0.13627 with `TRUE`, with a warning of `survey`.
- **Fix:** `with_lonely_psu()` sets both options; the second one is an
  argument of `as_hces_design()` or fixed at `FALSE`, and written in the
  log. **Task 12e.4 (Opus).**

### Finding 14 (minor). Impossible or inconsistent values that the validators accept

Run, each accepted without a note:

| Input | Consequence |
|---|---|
| `scenarios$level_mg_kg = 2e6` | more than one kilogram of fortificant per kilogram of vehicle |
| `composition$energy_kcal = 2000` per 100 g; a nutrient mass above 100 g per 100 g | only `check_crosswalk()` with ranges given by the caller sees it |
| `age_months = 14` with `age_years = 0.5` | the month is dropped and the infant gets the annual mean, counted as `infant_annual_mean` like an unknown month (`R/afe-energy.R:38-40`) |
| a PSU code in two strata | `nest = TRUE` (`R/design.R:59-61`) treats it as two PSUs; right for codes that restart in each stratum, silent for a household filed in the wrong stratum |
| `members$age_years = 150`; a pregnant boy of three years | not used in a calculation today |

- **Fix:** bounds that are identities (`level_mg_kg <= 1e6`; a mass per
  100 g at most 100 g); an `hcesfort_error_value` for a month that
  contradicts the age; a note `psu_in_several_strata` with the count.
  **Task 12e.4 (Opus).**

### Finding 15 (minor). The golden chain does not reach the optional columns

`hces_example` and `hces_fixture()` have no `household_share`,
`yield_factor`, `age_months`, `meals_home_share` or member `weight_kg`,
and no single-PSU stratum. Those paths rest on the hand-computed unit
tests alone. The replication of section 5.4 covered them and agreed.
**Fix:** add the columns to `hces_fixture()` and to the golden script.
**Task 12e.2 (Opus).**

### Finding 16 (minor). The tail rule of the iron probability has a source, and the help says it has none

`R/inadequacy.R:37-40` calls probability 1 below the lowest percentile and
0 above the highest "a convention, since the source does not tabulate the
tails". The source does assign them: IOM 2001, Table I-7, p. 703, footnote
d (read in this session): "a probability of 1 has been assigned to all
usual intakes falling below the two and one-half percentile of requirement
and a probability of 0 has been assigned to all usual intakes falling above
the ninety-seven and one-half percentile". **Fix:** the citation in the
help and in `data-raw/SOURCES.md`; P74 (the step table) can now cite its
page. **Task 12e.3 (Sonnet).**

### Finding 17 (minor). Households without an estimate leave the domain as if missing at random

`n_missing` is returned unweighted and nothing says what the estimate
assumes. M3 of the v0.1 review was never entered in
`docs/improvements.md`. In `hces_example` 72 of 2,000 households have no
estimate (36 `no_afe`, 31 `food_module_nonresponse`, 5
`no_food_records`). **Fix:** the weighted share missing per cell and one
sentence in the help. **v0.2.**

### Finding 18 (minor). A household with only zero quantities is estimated as intake zero

Run: status `estimated`, energy 0, `p_inadequate = 1`, `share_grams_used`
missing, no log row. Only `flag_energy_plausibility()` sees it, if it is
run. **Fix:** a flagged row `zero_intake` in `apparent_intake()`.
**Task 12e.4.**

### Finding 19 (minor). The probability approach for iron is the package's own extension to HCES

The only HCES paper opened so far states that iron inadequacy "cannot be
defined" by the cut-point and reports no iron figure (Tang et al. 2021,
pp. 112-113; v0.1 review, section 9.1). Applying the requirement
distribution of menstruating women to intake per adult equivalent, with
one bioavailability chosen by the analyst, follows the original analysis,
not a published HCES method. It is defensible; it should be said.
**Fix:** one sentence in `?inadequacy` and in the methods vignette.
**Task 12.**

## 3. Assumptions against the literature

"Verified" = read in the document, in this session unless a date is given.
"Unsupported" = no document opened supports it; it may still be right.

| # | Assumption of the package | Status | Source or reason |
|---|---|---|---|
| 1 | Food is shared within the household in proportion to energy requirements; intake per AFE is compared with the requirement of the reference woman | verified as practice (2026-11-12) | Tang et al. 2021, p. 109; stated there as a limitation, p. 118 |
| 2 | Adult energy = BMR (Schofield) × PAL | verified | FAO/WHO/UNU 2004, Table 5.2 and the examples under Table 5.1 |
| 3 | PAL 1.76 is "active or moderately active" | verified | FAO/WHO/UNU 2004, Table 5.1 ("42.2/24 = 1.76") |
| 4 | Infants count their full requirement | **unsupported**; the source of the table points the other way | Finding 4 |
| 5 | Pregnancy and lactation add no energy | unsupported; a stated choice | Decision 4 of task 5; P57 |
| 6 | One body weight per sex for every adult | unsupported; caller's value, no default | Analysis map, section 3 |
| 7 | The EAR cut-point needs a symmetric requirement; not valid for iron in menstruating women | verified | IOM 2000b, p. 81, Box 4-1 |
| 8 | The cut-point and the probability approach apply to acquisitions over `period_days` | **unsupported**; both are defined on usual intake | Finding 3 |
| 9 | Dividing by the days with a record (adapter default, E4) | unsupported outside the original's own test | Analysis map, E4 |
| 10 | Iron: probability 1 below P2.5 and 0 above P97.5 | verified | IOM 2001, Table I-7, p. 703, footnote d |
| 11 | Iron: linear interpolation between percentiles | supported to rounding | IOM 2001, Table I-7 gives one probability per band; the interpolation equals it at the middle of each band within 0.0055 (section 5.3) |
| 12 | Iron: intake rescaled by `b / b0` | verified as arithmetic | The percentiles are of dietary iron at 18% (IOM 2001, pp. 315-316, 343; registry) |
| 13 | Iron bioavailability of 10% as the main value | unsupported; caller's value, no default | Analysis map, section 3 |
| 14 | The probability approach on intake per AFE | **unsupported** in the HCES literature opened | Finding 19 |
| 15 | One bioavailability for diet and fortificant | unsupported | P70 |
| 16 | The adult UL applied to intake per AFE | unsupported for children; said in `?above_ul` | — |
| 17 | The folate UL compared in µg of folic acid; vitamin A in µg of preformed vitamin A | verified (2026-11-12, 2026-11-14) | IOM 1998, pp. 280, 282; IOM 2001, pp. 126, 142 (registry) |
| 18 | "Added only" is a lower bound of the share above the UL | follows from the definition | `?above_ul`; E7 |
| 19 | Average-content compliance | verified as a stated limitation (2026-11-12) | Tang et al. 2021, p. 119; finding 9 |
| 20 | Every gram of the vehicle can be fortified | **unsupported**; the source of the levels says otherwise | Finding 5; WHO 2009, p. 1 |
| 21 | WHO 2009 bands read with household acquisitions per person | verified | WHO 2009, p. 1: ranges "based on available data from the Food Balance Sheets of FAO and … Household Income and Expenditure Surveys" |
| 22 | WHO 2009 levels assume wheat flour is the only vehicle | verified | WHO 2009, Table 1, footnote 1: with other vehicles the levels "may need to be adjusted downwards" |
| 23 | No losses in storage and cooking | unsupported; logged (`no_losses_applied`) | Roadmap v0.2 |
| 24 | A missing composition value adds zero, gated by grams | unsupported | Finding 8 |
| 25 | Korn-Graubard interval and the NCHS thresholds | verified for 0/1 outcomes | NCHS 2017, pp. 2-4, 8-9; section 5.3 |
| 26 | The same standard for a mean of probabilities | **unsupported**; the claim of caution is wrong for one criterion | Finding 10 |
| 27 | Degrees of freedom of the domain | verified (2026-11-14) | NCHS 2017, p. 4 (registry); same rule in `surveytable` |
| 28 | Shares as a ratio of weighted totals with a logit interval | no citation; the interval equals `svyciprop(method = "logit")` on a 0/1 value | Section 5.4 |
| 29 | Outlier rule, energy range, precision limits | unsupported; no defaults, said so in each help page | — |
| 30 | HCES overstate intake against individual methods | **not verified**: abstract only | Tang et al. 2022; not reachable (section 9) |

## 4. Edge cases

| Case | What happens (run) | Verdict |
|---|---|---|
| One-person household, the reference woman | 1.000 AFE exactly | right |
| A household of infants only | AFE 0.55 for two infants; intake per AFE scaled up | consistent; finding 4 |
| A woman and an infant of two months | 1.240 AFE | finding 4 |
| A month of age that contradicts the age | annual mean, logged as an unknown month | finding 14 |
| Zero intake (quantities 0) | `estimated`, intake 0, `p_inadequate = 1`, density `NA` with `zero_energy` | finding 18 |
| A household without records, or without an AFE | status, outside the domain, counted | right |
| Every stratum with one PSU | `fail`: classed error; `adjust`: SE, no interval (`df = 0`); `remove`, `certainty`: `se = 0`; `average`: `se = NaN` | finding 12 |
| A domain inside one PSU of a stratum with two | `df = 0`, `NaN` limits, base warning | finding 12 |
| `survey.adjust.domain.lonely = TRUE` set by the user | standard errors change | finding 13 |
| Empty domain | missing estimate, `n = 0`, row `empty_domain` | right |
| A vehicle nobody acquires | coverage 0 as a degenerate proportion; the scenario adds 0; note `vehicle_not_acquired` | right |
| A scenario that changes nothing | difference 0, interval 0 to 0, `present` | finding 11 |
| A proportion outside [0, 1] | unclassed error, or a number | finding 2 |
| A repeated household in a carrier | accepted | finding 1 |
| The only source of a nutrient without a value | gate passes | finding 8 |

## 5. Circular validation

The code, the tests, the example data and the golden values were all
produced with AI assistance. The question is which expected values would
still be right if the AI had misread a rule.

### 5.1 Classes

- **(a) independent and external:** `survey`, `stats::binom.test()`,
  published tables, values typed from a document.
- **(b1) independent of the code but AI-written:** hand arithmetic on an
  invented fixture, written in the test.
- **(b2) independent of the code but AI-written:** the golden base-R
  script (`data-raw/golden_example.R`).
- **(c) self-referential:** snapshots; an expectation that repeats the
  expression of the code.
- **contract:** error classes, schemas, structure; no numeric value.

No test file holds a number copied from the package's output (no literal
with more than five decimals in `tests/testthat/`).

### 5.2 Every test file

| Test file | Class | Source of the expected values |
|---|---|---|
| `test-estimate.R` | **a**; one test c | `survey::svyciprop()`, `svymean()`, `svyquantile()` on a design built by hand; `flag_precision() by hand` repeats the code's expression (a literal test was added beside it) |
| `test-korn-graubard.R` | **a** | `svyciprop(method = "beta")`, `binom.test()`, 16 published rows of NCHS 2017 |
| `test-flag-presentation.R` | **a**, b1 | the published decisions of NCHS 2017, Tables I and II; hand rows at each boundary |
| `test-estimate-unlinked.R` | **a**, b1 | `svyratio()`, `svycontrast()`; hand counts |
| `test-food-group-shares.R` | **a**, b1; one test c | `svyratio()`; one hand value (60 / 275); the interval test repeats the code's formula |
| `test-reference-data.R` | **a** for the values, c for the test | the values were typed from the documents; the test checks md5 and internal consistency, not the values |
| `test-reference-helpers.R` | b1, a | hand boundaries on the WHO table as typed; one `svyratio()` |
| `test-golden-example.R` | **b2** | the base-R script; variances by `survey` inside it |
| `test-adult-equivalents.R` | b1 | invented requirement tables with round numbers; 2,290.8 kcal is the arithmetic of the equation |
| `test-convert-units.R` | b1 | hand grams |
| `test-flag-outliers.R` | b1 | hand quantiles (type 7) |
| `test-link-composition.R`, `test-fill-composition.R` | b1 | hand values |
| `test-apparent-intake.R` | b1 | hand values |
| `test-unfortified-baseline.R` | b1 | the hand example of the design note |
| `test-vehicle-coverage.R` | b1 | hand values |
| `test-apply-scenario.R` | b1 | hand values |
| `test-inadequacy.R` | b1 | invented requirements and an invented distribution; six points of the shipped iron table at its own percentiles |
| `test-above-ul.R` | b1 | invented upper levels |
| `test-food-group-intake.R` | b1 | hand values |
| `test-linkage-ladder.R`, `test-unmatched-foods.R`, `test-check-crosswalk.R` | b1 | hand counts |
| `test-readiness.R` | b1, contract | hand tables |
| `test-audit.R`, `test-audit-summary.R` | b1, contract | hand logs |
| `test-example-data.R`, `test-fixture-data.R` | c | broad bands and planted cases of data the AI generated |
| `test-report-snapshots.R` | **c** | snapshot of every exhibit on `hces_example` |
| `test-report-results.R`, `test-report-readiness.R`, `test-report-exhibits.R`, `test-report-registry.R`, `test-report-template.R` | c, contract | structure of the knitted reports; out of scope |
| `test-audit-carrier.R`, `test-errors.R`, `test-hces-schema.R`, `test-hces-tbl.R`, `test-schema-engine.R`, `test-nutrients.R`, `test-labels.R`, `test-size-limits.R`, `test-feedback-log.R`, `test-validate-*.R` (five files) | contract | — |

### 5.3 The core estimators

| # | Estimator | Expected values today | Only (b) or (c)? |
|---|---|---|---|
| 1 | Adult female equivalents | b1 | **yes** |
| 2 | Unit conversion | b1 | **yes** |
| 3 | Composition linkage | b1 | **yes** |
| 4 | Apparent intake | b1, b2 | **yes** |
| 5 | Unfortified baseline | b1, b2 | **yes** |
| 6 | Scenarios | b1, b2 | **yes** |
| 7 | Inadequacy, cut-point | b1, b2 | **yes** |
| 8 | Inadequacy, iron probability | b1, b2 | **yes** |
| 9 | Upper-level comparison | b1, b2 | **yes** |
| 10 | Design-based estimation | a | no |
| 11 | Paired differences | a | no |
| 12 | Korn-Graubard interval | a | no |
| 13 | Presentation standard | a | no |

**Nine of thirteen (69%) are covered only by (b).** None is covered only
by (c). The four with an external reference are the four that delegate to
`survey` or reproduce a published table.

External anchors, one or more per estimator. "Verified" = the source was
opened and the comparison run in this session.

| # | Estimator | Anchor | Status |
|---|---|---|---|
| 1 | Adult equivalents | The three examples under Table 5.1 of FAO/WHO/UNU 2004: woman 30-50 y, 55 kg, PAL 1.53: 1,975 kcal; woman 20-25 y, 57 kg, PAL 1.76: 2,355 kcal; man 20-25 y, 70 kg, PAL 2.25: 3,925 kcal. `reference_energy()` gives 1,977.6, 2,343.0 and 3,928.9: +0.13%, −0.51%, +0.10% (the report rounds the BMR; its 5.60 MJ for the second woman is not the equation's 5.57 MJ). A test at 1%. The twelve equations of `ref_bmr_equations` were re-read against Table 5.2: equal. | **verified** |
| 2 | Unit conversion | An identity by hand: a dozen pieces of 50 g is 600 g. A definition has no published example; the human check is a review point of the handoff. | identity |
| 3 | Composition linkage | Identity: grams × edible portion × content / 100. A worked example of a food-matching guide (FAO/INFOODS) was not opened. | identity; `# SOURCE PENDING` |
| 4 | Apparent intake | Conservation: the sum over households of AFE × intake equals the sum of the nutrients of the records used. On `hces_example`: energy 15,878,983.78 on both sides, relative difference 0 (also iron and folate). Not a test today. | **verified** (run) |
| 5 | Unfortified baseline | Round trip: a scenario that adds back exactly what a rule removed, on the food itself, restores the intake on the enriched table. Not run. | proposed |
| 6 | Scenarios | Identity by hand (100 g a day at 55 mg/kg is 5.5 mg). A published worked example was not opened (the supplement of Tang et al. 2021; the WHO/FAO 2006 guidelines). | identity; `# SOURCE PENDING` |
| 7 | Cut-point | The definition: "the proportion of individuals with usual intakes below … the EAR" (IOM 2000b, p. 82). | **verified** (definition) |
| 8 | Iron probability | IOM 2001, Table I-7, p. 703, menstruating women not using oral contraceptives: 12 bands with their probability. `ref_iron_requirements` equals Table I-4 (p. 700) for that group, all 13 values. At the middle of each band the package differs from the table by at most 0.0055; anywhere in a band by at most 0.05 (the table is a step function); below 4.42 mg it gives 1 and above 18.23 mg 0, as footnote d. A test with the 12 rows typed from the page. | **verified** |
| 9 | Upper level | Unit and form of each UL (registry, pages re-read 2026-11-14); the comparison itself is a definition. | identity |
| 10 | Estimation | Already (a). Added here: `svyby()` on the subset and a ratio of totals on the **full** design, no subsetting. Folate by region on `hces_example`: estimates equal, standard errors within 3.5e-18. Median by region against `svyby(svyquantile)`: equal. | **verified** |
| 11 | Paired difference | Already (a). Added here: `svycontrast()` of two means on the domain: estimate within 2.8e-17, standard error equal. | **verified** |
| 12 | Korn-Graubard | Already (a). Added here: `surveytable::svyciprop_adjusted(adj = "NCHS")` (CDC, CRAN 0.10.0), the reference implementation of the standard: 15 cells of region by expenditure group, largest difference 2.2e-16. The 16 published rows were re-read in the PDF (md5 of the registry); the largest deviation is 0.098 percentage point, so the "within 0.1" of `NEWS.md` holds. | **verified** |
| 13 | Presentation standard | Already (a). A comparison of the flags with `surveytable::tab()` was not run. | proposed |
| — | Logit interval of the shares | On a 0/1 value the internal `logit_interval()` equals `svyciprop(method = "logit")` within 3.6e-14. | **verified** |

### 5.4 Checks of this review that are not in the test suite

- **Brute-force replication.** 400 households of `hces_example` with
  invented `household_share` (190 missing), `yield_factor`, `age_months`,
  `meals_home_share` and member `weight_kg`, an outlier rule with
  exclusion, and the last scenario (levels on the compound basis, forms,
  compliance). Loops in base R written from the help pages. AFE, grams per
  day, the five nutrients per AFE, vehicle grams and the amounts added for
  four nutrients: the pattern of missing values is identical and the
  largest difference is 1.8e-15. This is class (b): AI-written, by another
  session than the one that wrote the code.
- **The golden script** reproduces its files exactly.
- The comparisons of the table above.

### 5.5 What the ENGIH validation will prove, and what it will not

Tasks A1 to A4 compare the package with `data/auditoria/cifras_control/`
of the original analysis, at 1e-6, with the original choices as options.

**It will prove:**

- that the package's arithmetic, on a real survey of 8,892 households,
  gives the numbers of an implementation written independently of this
  code base, stage by stage if A1 exports the stage figures;
- that the contracts hold a real questionnaire (two sections, presentation
  units, 933 PSUs);
- that the domain estimates through `survey` match those of the original
  once its subset design is reproduced.

**It will not prove:**

- **That the method is right.** The original is the origin of the method.
  Agreement at 1e-6 means the same rule was applied twice. Findings 3, 4,
  5, 8 and 9 hold in both.
- **That the corrections are right.** Step 2 has no reference: it records
  old and new figures. Each corrected default (E1, E2, E5, E7, E10) rests
  on the unit tests of class (b) and on the anchors of section 5.3.
- **Anything about the code the ENGIH does not run:** `household_share`,
  `meals_home_share`, `yield_factor`, member weights, monthly infants,
  `added` enrichment rules, the Korn-Graubard interval and the
  presentation standard (not in the original), the food-group shares (E1
  differs by design), `estimate_unlinked()`, single-PSU strata (the ENGIH
  has 8 strata and 933 PSUs), degenerate cells.
- **That the reference values are right.** Both sides use the same EAR,
  UL and iron table. Their check is the document (`data-raw/SOURCES.md`),
  not the comparison.
- **That the two sides are independent in their reading of the sources.**
  The control figures embed E2, E5 and E10; a misreading shared by the
  original and the package (a unit of the composition table, a questionnaire
  rule) passes. The stage figures of A1 reduce compensating errors; they do
  not remove a shared one.
- **External validity.** Nothing in it compares HCES figures with
  individual intake.

Until A1 exists there is no figure to compare: its files need the
microdata.

## 6. Mutation run

Thirty single-line mutations of the code added since the v0.1 review,
each run against the test files of its function plus the golden chain,
the readiness tests and the example tests. The report tests (snapshots)
were left out on purpose: they would kill almost anything numerical, and
they are class (c).

| Result | Mutations |
|---|---|
| **Killed (24)** | Korn-Graubard: cap at `n` removed; degrees-of-freedom adjustment removed; Clopper-Pearson lower limit off by one; interval of a degenerate proportion dropped. Estimation: missing values counted inside the domain as zero. Presentation: `n < min_n` to `<=`; width `>=` large to `>`; width `>` small to `>=`; effective size not capped; `df < min_df` to `<=`. Shares: delta-method divisor of the logit interval dropped. Record loss: share over all records instead of the included ones; gate as a mean of household shares. Unlinked share: numerator not matched instead of not validated; normal instead of *t* in the contrast. Scenario: mg/kg to an amount per 100 g off by ten. Baseline: a cell below the floor raised to it. Vehicle grams per member divided by the AFE. WHO bands: open lower bound made inclusive. Food groups: acquired without a record. Ladder: matched step counting records without grams. Outliers: low rule flagging zeros. Precision: `exact` when the standard error is missing. Iron probability: tails swapped |
| **Survived (5)** | see below |
| **Equivalent (1)** | shares: the domain defined on the group's amount instead of the total (both are missing for the same households) |

The five survivors were run again against every test file except the
report files (42 files): all five survive.

| # | Mutation that survived | Where | What is not tested | Is the code right? |
|---|---|---|---|---|
| S1 | `estimate_difference()`: the reference scenario taken from the first group for every group | `R/estimate-difference.R:68` | No test has a second key besides `scenario` (two nutrients, two bioavailabilities); the golden test filters one nutrient first | Yes: on `hces_example` the differences of all nutrients in one call equal those computed one nutrient at a time (run, difference 0). The most serious gap: a fault here would subtract the baseline of one nutrient from the scenario of another |
| S2 | `n_missing` counted over the whole design, not the `by` cell | `R/estimate.R:137` | `n_missing` is asserted only without `by` | Yes, by reading |
| S3 | A member of exactly one year treated as an infant | `R/afe-energy.R:14` | No fixture has a member aged exactly 1 (or exactly the first adult year) | Yes, by reading; the brute-force replication used the same boundary |
| S4 | `above_ul()`: coverage of the diet part as the largest of its forms, not the smallest | `R/above-ul.R:121` | No fixture has two registry forms of one UL category | Yes, by reading (P79.3) |
| S5 | Coverage of a household whose records weigh zero grams: `NaN` instead of `NA` | `R/intake.R:146` | The tests use `is.na()`, true for both | Yes |

The suite is strong where it was strong in the v0.1 review: boundaries of
the presentation standard and the interval are pinned by published rows
and by `binom.test()`. The weak spots are a second grouping key in the
estimators and the age boundaries. **Fix:** five tests, with 12e.2.

## 7. What a JOSS or an rOpenSci reviewer would reject

The review criteria of JOSS and the scope policy of rOpenSci could not be
opened in this session (`joss.readthedocs.io` and `devguide.ropensci.org`
are not reachable): `# SOURCE PENDING` for both. What follows is what the
repository shows, with the reason; the wording of each criterion is to be
checked before submission.

| # | A reviewer would stop at | Why | Finding or item |
|---|---|---|---|
| 1 | The README | It says there are no functions | 7 |
| 2 | Scope (rOpenSci) | P36 recorded, from the statistical software book, that survey estimation fits "general" at most; the standard review takes data and workflow packages. A package that implements estimators may be sent to the statistical review, which needs the `srr` annotations the project chose not to adopt. A pre-submission enquiry answers this in days | question 8 |
| 3 | "Prevalence of inadequacy" from a seven-day acquisition | Finding 3; a nutrition reviewer asks for it in the first paragraph | 3 |
| 4 | No statement of need against existing tools | There is no comparison with other software for HCES nutrient analysis; none was opened here | task 12; `# SOURCE PENDING` |
| 5 | One vignette, no methods vignette, no adapter guide | Task 12 is open | task 12 |
| 6 | Seventeen calls before the first estimate (v0.1 review, section 1.1); the chain repeated in the examples of 17 functions, the vignette, the golden test and the template | P152 | P152 |
| 7 | A reporting system inside an estimation package | The six report test files are 87% of the test time; the template is about 1,750 lines of R in `inst/report/` that a statistical reviewer must read or ignore | P127, P135 |
| 8 | Validation | "Tested against `survey`" holds for four estimators of thirteen | 6 |
| 9 | AI assistance | Code, tests, data and golden values were produced with AI assistance. Both venues are likely to ask for a statement; `CONTRIBUTING.md` and the README have none | question 7 |
| 10 | A silent wrong answer found in an hour | Findings 1 and 2 are the first things a reviewer tries | 1, 2 |
| 11 | Version `0.0.0.9000`, a no-reply e-mail, no `codemeta.json` | P37, P39 | v1.0 |

What a reviewer would praise, and should be kept: no hidden default;
classed errors that say how to fix; the audit log; the reference tables
with page and md5; `survey` for every variance; the size limits enforced
by a test.

## 8. Order of work proposed

New roadmap step **12e**, after approval, before A2. Each sub-step is at
most 300 lines of code.

| Step | Content | Findings | Model |
|---|---|---|---|
| 12e.1 | Key check in `require_hces()`; `audit_check_rows()` in the estimators; range check of a proportion | 1, 2 | Opus |
| 12e.2 | Anchor tests: FAO examples, IOM Table I-7, conservation, round trip, `svycontrast`, full-design ratio, logit interval; optional columns in `hces_fixture()` and the golden script | 6, 15 | Opus |
| 12e.3 | Limits of the method in the help pages, the README and the vignette; the tail citation; the two audit notes (usual intake; compliance and the UL); new README | 3, 7, 9, 16 | Sonnet (text), Opus (notes) |
| 12e.4 | Zero-width intervals, `df = 0`, `exact`, the second option of `survey`, validator bounds, `zero_intake`, effective size of a non-binary value | 10 to 14, 18 | Opus |
| 12e.5 | Design note: infants and pregnancy in the AFE; the fortifiable vehicle; the gate on missing values; whether P69 moves before A4 | 4, 5, 8, 9 | Fable, one note; then Opus, before A4 |

## 9. Sources

Opened in this session:

| Document | Where | What was read |
|---|---|---|
| IOM 2000b, *Applications in Dietary Assessment* | `nap.nationalacademies.org/books/9956/gif/<page>.gif` | pp. 73, 81, 82, 99 |
| IOM 2001 | `nap.nationalacademies.org/books/10026/gif/<page>.gif` | Table I-4, p. 700; Table I-7, p. 703 |
| FAO/WHO/UNU 2004 | `fao.org/4/y5686e/y5686e05.htm`, `y5686e07.htm` | section 3.4; Tables 5.1 (examples) and 5.2 |
| NCHS 2017 | `cdc.gov/nchs/data/series/sr_02/sr02_175.pdf`, md5 `2ae6002af069bb55f555e2e271f1908d` (that of the registry) | p. 3; Tables I and II |
| WHO 2009 | `iris.who.int/handle/10665/111837`, md5 `9cf668a20a2cf32a8c35b676bb9993d4` (that of the registry) | p. 1; Table 1 footnotes |
| `surveytable` 0.10.0 (CDC) | CRAN, installed in a scratch library | `svyciprop_adjusted()`, source and output |
| `survey` 4.5 | installed | `?svyquantile` (the default interval is Woodruff's) |

Not opened, so nothing above rests on them: Tang et al. 2022 (systematic
review; `doi.org`, `pmc.ncbi.nlm.nih.gov` and `cambridge.org` are not
reachable); the supplement of Tang et al. 2021; the MIMI methods papers;
Aaron et al. 2017; any paper on adult equivalent scales for HCES; the JOSS
criteria and the rOpenSci policies. The repository of the original
analysis is outside the access of this session; what is said of it comes
from `docs/analysis-map.md`.

## 10. Questions for the maintainer

Each with the recommended option first.

1. **Step 12e before A2.** *Recommended: yes*, 12e.1 to 12e.3 before the
   adapter work resumes; 12e.4 can follow. The Q4 render can go ahead
   meanwhile: it is for your reading.
2. **`statistic` of `estimate_households()`.** *Recommended: keep the
   default `"proportion"` and add the range check* (no interface change).
   Alternative: no default, which breaks every call that relies on it.
3. **Infants (finding 4).** *Recommended: a required argument with no
   default when `members` has infants; 1 reproduces today's rule.* It
   needs a source for the values an analyst may choose; do you have the
   supplement of Tang et al. 2021 (Table S1) or another reference on
   infants in adult equivalent scales?
4. **Upper level and compliance (finding 9).** *Recommended: the audit row
   and the bound at compliance 1 now (12e.3), and P69 (all-or-nothing)
   moved from v0.2 to before A4*, because the safety statement of the
   report depends on it. Alternative: keep P69 in v0.2 and print the bound
   only.
5. **Fortifiable vehicle (finding 5).** *Recommended: a logical column
   `fortifiable` in `acquisitions`, set by the adapter, and a required
   argument in `vehicle_coverage()` when it exists.* Does the ENGIH say
   where a food was bought or produced, beyond own production?
6. **Presentation of the iron estimates (finding 10).** *Recommended:
   correct the two sentences now (12e.3) and compute the effective size
   from the variable's own variance in 12e.4.* Alternative: only the
   sentences.
7. **`surveytable` as a test reference.** It is the CDC's implementation
   of the standard. *Recommended: add it to `Suggests` for one test that
   is skipped when it is absent*; `CLAUDE.md` asks for your approval of a
   new suggested package. Alternative: keep the comparison as a script in
   `data-raw/` with its output recorded. Also: do you want a statement on
   AI assistance in the README and `CONTRIBUTING.md` now? *Recommended:
   yes, two sentences.*
8. **Review track.** *Recommended: send the rOpenSci pre-submission
   enquiry now*, before task 12 fixes the documentation: if the answer is
   the statistical review, the `srr` annotations cost less now than at
   v1.0.
9. **Documents.** To close the pending sources: can you supply the PDFs of
   Tang et al. 2022, the supplement of Tang et al. 2021 and Aaron et al.
   2017, or allow `pmc.ncbi.nlm.nih.gov`, `joss.readthedocs.io` and
   `devguide.ropensci.org` in the environment?
