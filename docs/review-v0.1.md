# Critical review of v0.1 (tasks 2 to 11)

- **Date:** 2026-11-12. **Commit reviewed:** `4260d5f` on `main`.
- **Stance:** an rOpenSci reviewer and a methodologist of household
  consumption surveys and nutrition. No package code was written.
- **How:** (1) the whole chain was run on `hces_example`, with every call
  first tried with its arguments left out; (2) all of `R/` behind the
  calculations was read (intake, AFE, units, outliers, composition, baseline,
  vehicles, scenarios, risk, upper level, design, estimation), the contracts
  through `hces_schema()`; (3) 28 single-line mutations of the calculations
  were run against the test suite; (4) the result was cross-checked with
  `docs/improvements.md` so that an item already recorded is cited by its
  number (Pnn) and not presented as new.
- **State found:** `devtools::test()` passes, `devtools::check()` is 0/0/0
  and the lint is clean (details in section 8).

Findings carry an id: **H** high, **M** medium, **L** low. "Evidence" is what
was run; "Proposal" is the smallest change that closes the finding. Line
numbers refer to the commit above.

## 1. End-to-end run on `hces_example`

### 1.1 The chain that works

```r
library(hcesfort)
ex <- hces_example

survey <- validate_survey(ex$households, ex$members, ex$acquisitions)
grams  <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
flagged <- flag_outliers(grams, by = "food_code", scale = "per_afe",
                         level = "record", probs = c(0.25, 0.75),
                         multiplier = 3, min_group = 5, afe = afe)  # optional

eq  <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
afe <- adult_equivalents(
  ex$members,
  reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
  weight_kg = c(female = 55, male = 65), pal = 1.76
)

nutrients <- nutrient_registry(ex$nutrients)
baseline  <- unfortified_baseline(ex$composition, ex$enrichment, nutrients)
content   <- link_composition(grams, ex$crosswalk, baseline)
unmatched_foods(content)
check_crosswalk(ex$crosswalk, baseline, grams = grams)

intake <- apparent_intake(content, afe, ex$households)
intake <- flag_energy_plausibility(intake, "energy_kcal", 500, 6000)
nutrient_density(intake, "energy_kcal")

use <- vehicle_coverage(grams, ex$vehicles, afe, ex$households)
s   <- apply_scenario(intake, use, ex$scenarios,
                      compliance_model = "average_content")

iron <- subset(ref_iron_requirements, group == "females_menstruating_adult")
risk <- inadequacy(s, ref_requirements, distribution = list(iron = iron),
                   bioavailability = list(iron = c(0.05, 0.10, 0.18)),
                   min_coverage = 0.8)
ul   <- above_ul(s, ref_requirements, min_coverage = 0.8)

design <- as_hces_design(ex$households, lonely_psu = "adjust")
est  <- estimate_prevalence(design, risk, "p_inadequate", by = "region")
dif  <- estimate_difference(design, risk, "p_inadequate",
                            reference = "baseline")
flag_precision(est, min_n = 10, max_half_width = 0.10)
audit_log(risk)
```

Seventeen calls and about fourteen required choices before the first
estimate. That is the design ("no hidden default") and each refusal explains
itself well; the cost is that nothing short of the vignette tells the user
the order. Until task 12 exists the only map is `docs/handoff.md`.

### 1.2 Frictions met, in the order met

| # | Friction | Where | Finding |
|---|---|---|---|
| F1 | `README.md` says "The package has no user-facing functions yet" and lists what it "will do". A newcomer stops there. | `README.md:12-20` | H5 |
| F2 | `adult_equivalents(members)` fails with base R's `argument "reference_kcal" is missing, with no default` (class `simpleError`), where every other required argument gives an `hcesfort_error_argument` with a hint. Same for `check_crosswalk(crosswalk)` without `composition` and `inadequacy(x, min_coverage = )` without `requirements`. | `R/afe.R:67-75`, `R/check-crosswalk.R:54-57`, `R/inadequacy.R:82-88` | M9 |
| F3 | The reference energy must be computed by hand from `ref_bmr_equations` (three lines, copied in eight help pages). Nothing ties `reference_kcal` to `weight_kg["female"]` and `pal`: the invariant "the reference woman is 1 AFE" holds only if the user repeats the same numbers twice. | `R/afe.R:57-63` | M10 |
| F4 | `flag_outliers()` needs six required arguments and `afe`; the first error only names `scale`. Fixing one argument reveals the next: six round trips. | `R/outliers.R:57-64` | L3 |
| F5 | Milk never becomes grams: its 19 records are `no_density`; 32% of the included records (65 of 203) do not reach the intake; the median household uses 67% of its records. Every `_coverage` column is still 1 and `min_coverage = 0.8` passes. | `R/intake.R:111-130`, `R/risk-checks.R:60-69` | **H1** |
| F6 | Median energy of the example is 518 kcal per AFE per day; 16 of 36 estimated households are below 500 kcal; every prevalence is between 0.74 and 1; no household is above any UL. The vignette of task 12 would show absurd figures. | `data-raw/hces_example.R` | H6 |
| F7 | `inadequacy(s, ref_requirements, min_coverage = 0.8)`, the call of the handoff, assesses iron by the EAR cut-point without a word; the log only says `iron: ear_cutpoint`. | `R/inadequacy.R:90-96` | **H2** |
| F8 | `flag_energy_plausibility()` adds `energy_plausible`, and the help of `estimate_prevalence()` offers `domain = "energy_plausible"`, but `inadequacy()` and `above_ul()` drop the column: `estimate_prevalence(design, risk, "p_inadequate", domain = "energy_plausible")` is an `hcesfort_error_argument`. The sensitivity analysis the original reported cannot be done inside the package. | `R/inadequacy.R:113-127`, `R/above-ul.R:119-128`, `R/estimate.R:31-33`, `R/estimate-checks.R:66-73` | **H3** |
| F9 | `apparent_intake(..., outliers = "exclude")` combined with a `vehicle_coverage()` built from the unflagged grams is accepted: the scenario adds fortificant from records the baseline left out. | `R/scenario-log.R:58-84` | H4 |
| F10 | The audit log of `risk` has 111 rows, 21 of them exact duplicates (`validate_acquisitions`, `convert_units`, `validate_members`, `adult_equivalents`, `validate_households` appear once per branch: intake and vehicle use). There is no print or summary method. | `R/intake.R:89`, `R/vehicle-use.R:96`, `R/scenario.R:95` | M7 |
| F11 | A proportion that is 0 in the sample is returned as `7.65e-12` with interval `[6.2e-12, 9.4e-12]` (`ci_method = "logit"`), as `0` with `NaN` limits (`"beta"`); a proportion of 1 as `1.000 [1.000, 1.000]`. With 36 households this reads as certainty. | `R/estimate.R:103-107` | M5 |
| F12 | The design returned by `as_hces_design(lonely_psu = "adjust")` is advertised as "usable with the functions of `survey` and `srvyr`", but the choice lives in an attribute: `survey::svymean()` on it with a single-PSU stratum fails with `Stratum (urban) has only one PSU at stage 1`, or silently uses whatever the global option is. | `R/design.R:24-26`, `R/design.R:45-50`, `R/estimate.R:125-129` | M6 |
| F13 | `dplyr::filter(intake, intake_status == "estimated")` followed by `apply_scenario()` fails with "Households estimated in `intake` without use estimated: 0". The real cause (the two tables no longer hold the same households) is not said. | `R/scenario-log.R:70-82` | M9 |
| F14 | `estimate_prevalence(design, ul, "above_ul_added")` returns three rows for iron with `n = 0`, `n_missing = 40` and everything `NA` (the comparison does not exist for a `total` UL). Noise in every table. | `R/above-ul.R:126`, `R/estimate.R:96-100` | L4 |
| F15 | `check_crosswalk()` takes `(crosswalk, composition, grams =)`, `unmatched_foods()` takes the linked table. Passing the linked table to `check_crosswalk()` answers "`crosswalk` lacks 2 required columns: match_type and validated". | `R/check-crosswalk.R:54-56` | L5 |
| F16 | `vehicle_coverage()` gives grams per AFE; `ref_who2009_flour` chooses the level by availability per capita. The user cannot pick the WHO row from the package's output. | `R/vehicle-use.R:164-165` | M8 |
| F17 | Wide and long results mix: `apply_scenario()` is wide (one column per nutrient), `inadequacy()` long. Means of intake need one `estimate_prevalence()` call per nutrient column. | `R/scenario.R:47-52`, `R/estimate.R:59-61` | L6 |

What worked well and should not be lost: every refusal met was specific and
said how to fix it; a plain tibble is refused with the `restore_audit()`
hint; `mutate()`, `filter()` and `left_join()` keep the carrier; the
unfortified-baseline guard of `apply_scenario()`; the group error of the iron
distribution; estimates equal to `survey` on direct comparison
(`svymean` on the same design gave the same 0.94534, SE 0.0323).

## 2. High priority

### H1. The coverage gate does not see the records that were lost
- **Where:** `R/intake.R:111-130` (`household_sums()`), `R/intake.R:133-143`
  (`intake_status()`), `R/risk-checks.R:60-69` (`check_coverage()`),
  documentation `R/inadequacy.R:32-39`.
- **What:** `<nutrient>_coverage` is the share of the *edible grams used*
  that have a composition value. Records left out before (no grams, food not
  in the crosswalk, match not validated, edible portion missing, not
  included) are in neither numerator nor denominator. A household keeps the
  status `estimated` as long as one record survives.
- **Evidence:** on the example, 203 included records, 138 linked, 43 with
  grams but not linked (1,397 g/day against 58,791 linked), 22 without grams
  (all 19 milk records). Share of records used per estimated household:
  minimum 0.33, median 0.67. All coverages equal 1 and
  `inadequacy(min_coverage = 0.8)` passes. The counts are in the audit log
  (`not_linked 65`), but nothing acts on them, and the error message of the
  gate ("share of grams with a value") suggests it does.
- **Why it matters:** this is the dominant error of apparent-intake work
  (unconverted units and unmatched foods), it biases intake downwards and
  inadequacy upwards, and E3/E21 of the original analysis were this kind of
  silent loss. In ENGIH the loss by food is very uneven (liquids, counts).
- **Proposal:** (a) `apparent_intake()` returns per household
  `n_records_included`, `share_records_used` and, where grams exist,
  `share_grams_used` (grams of used records over grams of included records
  with grams); (b) `inadequacy()` and `above_ul()` take a second required
  threshold on that loss (for example `min_records_used`), with the overall
  figure in the log, same pattern as `min_coverage`; (c) rename or document
  `_coverage` as "composition-value coverage" so the two are not confused;
  (d) `unmatched_foods()` already ranks the causes: cite it in the error.
  Changes a contract: design by Fable.

### H2. Iron (or any nutrient with a skewed requirement) is assessed by the cut-point without warning
- **Where:** `R/inadequacy.R:90-96`, `R/inadequacy.R:130-138`; reference
  table `ref_requirements` (iron EAR 8.1 mg, IOM 2001 p. 345);
  `docs/handoff.md` review point 3 uses exactly this call.
- **What:** the help states that for the nutrients in `distribution` "the
  cut-point is not valid", but the function applies the cut-point to every
  nutrient with an `ear` that is not in `distribution`. With
  `ref_requirements` as shipped, leaving `distribution` out gives an iron
  prevalence by cut-point. The core cannot know which nutrient is iron, but
  the reference table can say it.
- **Second issue, same place:** the IOM iron EAR assumes the bioavailability
  of `ref_iron_requirements` (0.18, column `bioavailability`). The
  cut-point path has no bioavailability argument, so a diet of low
  bioavailability is compared with a requirement for 18%; only the
  probability path rescales. The example gives 0.94 by cut-point and 0.99
  at 10%.
- **Proposal:** add to the requirements contract a column such as
  `cutpoint_valid` (logical, with its source) and, for requirements that
  assume an absorption, `bioavailability`; `inadequacy()` aborts
  (`hcesfort_error_value`) when a nutrient with `cutpoint_valid = FALSE` has
  no distribution, unless the caller names it in an explicit argument (the
  option needed to reproduce a legacy figure). Source to open and cite for
  the rule: IOM 2000, *Dietary Reference Intakes: Applications in Dietary
  Assessment* (the conditions of the cut-point method), `# SOURCE PENDING`
  until read. Contract change: Fable.

### H3. A household flag cannot become a domain of the risk estimates
- **Where:** `R/inadequacy.R:113-127` (`risk_base()` builds the rows from
  scratch), `R/above-ul.R:119-128`, `R/estimate-checks.R:66-73`
  (`domain_place()`), help text `R/estimate.R:31-33`.
- **Evidence:** F8. The only way today is to join the flag into the
  households table by hand before `as_hces_design()`, outside the audit log.
- **Why it matters:** "all households and energy-plausible" is one of the
  control figures of `riesgo_inadecuacion.csv` (`docs/analysis-map.md:398`),
  so acceptance step 1 needs it; and coverage-based domains are what the
  help of `inadequacy()` promises ("so a domain can be defined on it").
- **Proposal (one of):** (a) `inadequacy()` and `above_ul()` carry over the
  logical columns of `x` that are constant within household; or (b)
  `estimate_prevalence(domain = )` also accepts a carrier keyed by
  `household_id` with one logical column (the table returned by
  `flag_energy_plausibility()`), joined with a checked one-to-one
  relationship. (b) is cleaner and also serves domains defined on
  `vehicle_coverage()` ("among consumers of flour"). Interface change:
  Fable decides, Opus implements.

### H4. `apply_scenario()` accepts an intake and a vehicle use built on different records or AFE
- **Where:** `R/scenario-log.R:58-84` (`check_scenario_use()`).
- **What:** it checks that both tables hold the same households and that
  estimated households are estimated in both. It does not check that both
  come from the same grams, the same outlier decision or the same AFE
  (the AFE part is P76, medium). Evidence: F9, accepted silently.
- **Proposal:** raise P76 to high and widen it: `hces_vehicle_use` keeps
  `afe`; both carriers record the outlier decision in an attribute (or the
  log is compared: same `flag_outliers` rule and same `outliers` choice);
  `apply_scenario()` aborts with `hcesfort_error_join` on a mismatch. Opus,
  after Fable accepts the added column.

### H5. The README describes a package that does not exist yet
- **Where:** `README.md:12-20`.
- **Proposal:** replace the status paragraph and "What it will do" by what
  v0.1 does, the chain of section 1.1 in short form, and the limits of
  section 5 (H7). Sonnet, with task 12.

### H6. The example dataset cannot carry a credible vignette
- **Where:** `data-raw/hces_example.R` (quantities and planted cases).
- **Evidence:** F6: median 518 kcal per AFE per day (10th percentile 164),
  prevalences near 1 in every scenario, nothing above a UL, one whole food
  (milk) lost for want of a density. The planted defects are valuable for
  tests; their sum makes the dataset useless to show a result.
- **Proposal:** rescale quantities so that the median energy per AFE is in a
  plausible range and iron, folate and vitamin A straddle their EAR; keep
  each planted defect in a few records (one milk record without density, not
  all); make one scenario push a few households above a UL so that
  `above_ul()` shows both outcomes. Regenerate, update the planted-case
  tests. Opus. Do it **before** task 12.

### H7. The interpretation limits of the method are not written anywhere the user reads
- **Where:** `R/inadequacy.R:1-10` (the only caveat, on households versus
  persons), `R/above-ul.R:29-34`; nothing in `README.md` or
  `docs/specification.md`. A search of `R/` and `docs/` for "usual intake"
  returns nothing.
- **What is missing**, in order of weight:
  1. **Acquisition over a short window is not usual intake.** The EAR
     cut-point and the probability approach are defined on the distribution
     of usual intake. A household's acquisitions in one or two weeks carry
     purchase-frequency and stock variance that usual intake does not, and
     the excess variance moves the share below a fixed threshold (upwards
     when the mean is above the threshold, downwards when below). The
     systematic review of Tang et al. (2022) reports that HCES-based
     estimates generally overestimate intake compared with individual
     dietary assessment, with sizeable discrepancies in several studies.
     The package's figures should be named what they are (households whose
     apparent intake per AFE is below the requirement) and never
     "prevalence of inadequacy" unqualified.
  2. **Households, not persons** (said in the help; out of scope until
     v0.2). Published HCES work reports population shares; the two differ
     when household size correlates with intake, which it does.
  3. **Average-content compliance and the UL.** `above_ul()` on a scenario
     with `compliance < 1` under `"average_content"` understates the share
     above the UL by construction (P69 says so; the help of `above_ul()` and
     the audit log do not). At least a log note
     `compliance_average_content_understates_ul` whenever both occur.
  4. **One bioavailability for diet and fortificant** (P70): WHO 2009 sets
     different levels per iron compound because absorption differs; with
     `level_basis = "nutrient"` a scenario at the higher level of a poorly
     absorbed compound looks better than the well-absorbed one. A sentence
     in `apply_scenario()` and a log note when two scenarios differ only in
     `compound`.
  5. **Food away from home, guests, waste and feeding of animals** are not
     in the model; `meals_home_share` covers one of them when the survey has
     it.
- **Proposal:** a "Limits of the method" section in the main vignette and in
  `?inadequacy`, with the sources read and cited; items 3 and 4 also as
  audit notes (Opus, small). Text: Sonnet from this section, sources checked
  before they are cited (section 9).

## 3. Medium priority

### M1. Excluding an outlier sets that food to zero
- `R/intake.R:95-106`. `outliers = "exclude"` removes the record, so the
  household's consumption of that food becomes zero and intake is biased
  down; "keep" leaves an impossible quantity. P68 (winsorise, low) is the
  missing third choice. Replacing by the group median or capping at the
  fence is the common practice in HCES nutrient work (to verify in the
  methods of the MIMI papers before citing). Raise P68 to medium;
  `flag_outliers()` returns the fences, `apparent_intake(outliers = "cap")`
  uses them and logs grams removed. Needed before acceptance step 2, not
  step 1.

### M2. Adult equivalents: infants and pregnancy
- `R/afe-energy.R:14-22`, `R/afe.R:22-23`. Infants under one year count
  their full energy requirement although most of it comes from breast milk,
  which no HCES records: the household AFE is inflated and intake per AFE
  deflated in households with infants. Pregnancy and lactation add nothing
  (P57, medium). Both are choices the user cannot change today.
- Proposal: an argument for the share of infants' energy expected from the
  household's foods (required when infants are present, no default, 1
  reproduces today's rule) and P57's additions as an option; both with
  sources in `data-raw/SOURCES.md`. Fable (method), Opus.

### M3. Households without an estimate leave the domain silently in the tables
- `R/estimate.R:87-99`. `n_missing` is returned (good) but unweighted, and
  nothing tells the reader that the estimate describes responding,
  estimable households only, as if they were missing completely at random.
  Proposal: add the weighted share of the `by` cell that is missing
  (`share_missing`), a log note when it exceeds zero, and one paragraph in
  the help on what a household-level non-response adjustment would need
  (out of scope).

### M4. `p_inadequate` versus `intake` at the edges of the probability table
- `R/inadequacy-probability.R:105-115`. Correct as designed (decision 10.4)
  and well tested. Two documentation gaps: the lowest and highest
  percentiles of the shipped table bound a jump whose size is the tail
  share, and `tails_fixed` counts rows, not households (P79.6). With low
  bioavailability most households sit in the lower tail (example at 5%:
  1.000), where the figure is the convention, not the data. State in the
  help that results dominated by `tails_fixed` should be reported as "at or
  above 97.5%"-type statements; add the share of estimated rows in the
  tails to the log detail.

### M5. Degenerate proportions
- `R/estimate.R:103-107`. Evidence F11. Proposal: when every value in the
  domain is 0 (or 1), return the exact estimate, `se = 0`, limits `NA`, and
  an audit row `degenerate_proportion`; document that `"beta"` gives a
  usable one-sided limit only through `survey`'s effective sample size (to
  check by running it). Add the two cases to the tests.

### M6. The lonely-PSU choice does not travel with the design
- `R/design.R:45-50`. Evidence F12. The help invites the user to compute
  "any further estimate" with `survey`/`srvyr`, which then ignores the
  choice. Proposal: say so in `?as_hces_design` with the two lines that
  apply it (`withr::local_options(survey.lonely.psu = attr(design,
  "hces_lonely_psu"))`), or export the internal `with_lonely_psu()`.
  Also P84 (classed error under `"fail"`).

### M7. The audit log is the product and is hard to read
- Duplicated branches (F10): `R/intake.R:89`, `R/vehicle-use.R:96`,
  `R/scenario.R:95`, `R/above-ul.R:95`. No `print`, `summary` or `format`
  method (P50, low). Adapters cannot write to it: `audit_add()` and
  `audit_row()` are internal, so the section-combination rule, an
  imputation or any exclusion made by the adapter (layer 1 of the
  specification) is outside the log the package promises to be complete.
- Proposal: (a) merge logs without repeating rows that come from the same
  upstream call (an id per call, kept in the log, is the robust way; exact
  duplicate removal is the cheap one and can hide a step run twice); (b)
  `summary()` of a carrier: exclusions and flags by step, one line each; (c)
  an exported `audit_note(x, cause, n_records, ...)` for adapters, with
  `step` set to the adapter's name. Exported API: Fable decides; Opus
  implements. Raise P50 to medium.

### M8. Vehicle use per capita and the WHO 2009 table
- `R/vehicle-use.R:164-165`. Evidence F16. `ref_who2009_flour` is indexed by
  availability in grams per capita per day; the package returns grams per
  AFE. Proposal: add `qty_vehicle_g_d_pc` (divided by `n_members` of the
  AFE table), estimate its mean with the design, and build P71's helper on
  it. The basis of the WHO categories (national availability per capita) to
  be quoted from the document, already opened for task 4.

### M9. Error messages that miss the cause
- Missing required arguments reach base R (F2): give every required
  argument the same `hcesfort_error_argument` (a shared `check_required()`).
- `R/scenario-log.R:74-82`: split the two conditions; when the household
  sets differ, say how many are only in `intake` and only in `use`, and
  that a filter between the two calls is the usual cause.
- `R/inadequacy-probability.R:75-87`: "is not usable" lists five rules
  without saying which one failed; test them one by one.
- `R/intake-derived.R:43-50` and `R/estimate-difference.R:135-141`: one
  message for several arguments (`min`/`max`, `min_n`/`max_half_width`)
  with `arg` set to the first; name the one that failed.
- P84: the lonely-PSU error of `survey` under `"fail"` is unclassed.

### M10. A helper for the reference energy
- `R/afe.R:57-63`. Evidence F3. Proposal: export
  `reference_energy(sex, age_years, weight_kg, pal, bmr = ref_bmr_equations)`
  (four lines) and use it in the examples. The test "the reference woman has
  exactly 1 AFE" then guards a function, not a recipe. API addition: Fable
  approves, Opus implements.

### M11. Tests on `hces_example` stub the AFE
- `tests/testthat/test-apply-scenario.R:194-216`,
  `tests/testthat/test-estimate.R:237-251`,
  `tests/testthat/test-vehicle-coverage.R:171-188` build
  `afe = 1` for every household. No test runs the real chain
  `adult_equivalents()` → … → `estimate_difference()` on the example; it
  runs only inside roxygen examples, which assert nothing. Proposal: one
  golden-value test of the full chain (a dozen numbers computed once by an
  independent script kept in `data-raw/`, compared at 1e-8), which is also
  the regression net for H1–H4 and the template of the acceptance test.

### M12. Acceptance against ENGIH: what the core still lacks
See section 6.

## 4. Low priority

- **L1. Names.** `vehicle_coverage()` returns use, not coverage (class
  `hces_vehicle_use`, column `use_status`); `estimate_prevalence(statistic =
  "mean" | "median")` estimates things that are not prevalences
  (`estimate_statistic()` or `estimate_households()` would be honest);
  `inadequacy()` and `above_ul()` are nouns among verbs; the energy column
  is `column` in `flag_energy_plausibility()` and `energy` in
  `nutrient_density()` (`R/intake-derived.R:39`, `:107`); the main table
  argument is `x`, `intake`, `content`, `grams` or `estimates` by function.
  Decide once before v0.1 is announced; renames are cheap now.
- **L2. Arguments that shadow base R:** `missing` (`R/afe.R:72`), `min`,
  `max` (`R/intake-derived.R:39`). They work; `missing_members`,
  `min_kcal`/`max_kcal` (or `range`) read better and survive `missing()`.
- **L3. `flag_outliers()` reports one bad argument per call** (F4):
  collect and report all missing required arguments at once.
- **L4. Rows that cannot hold a value** (F14): `above_ul_added` for a
  `total` UL. Either drop all-`NA` groups in the estimators with a log note,
  or document the filter.
- **L5. `check_crosswalk()` and `unmatched_foods()` take different first
  arguments** (F15): accept the linked table in both, or cross-reference
  the two help pages.
- **L6. Wide and long results** (F17): a `value = c("iron_mg", ...)` vector
  in `estimate_prevalence()` or a documented `tidyr::pivot_longer()` recipe
  followed by `restore_audit()` (which today refuses a pivoted table whose
  key changed: check before documenting).
- **L7. `estimate_prevalence()` has no `cv` column** although the control
  figures have one (`docs/analysis-map.md:398`): add `cv = se / estimate`
  or leave it to the adapter, explicitly.
- **L8. `hces_example$nutrients` is a named character vector** among nine
  tibbles; a two-column tibble accepted by `nutrient_registry()` would be
  consistent.
- **L9. Zinc.** `ref_requirements` carries the IOM zinc EAR, which assumes a
  given absorption; diets based on unrefined cereals have lower absorption.
  Same remedy as H2 (`bioavailability` or a note column) and the H-AR table
  of v0.2.
- **L10. Performance** (P83): 0.17 s for 18 cells on 40 households; with
  ENGIH's size and the full grid of cells this is minutes, not hours. No
  action before acceptance.
- **L11. `DESCRIPTION`** still `0.0.0.9000`; set `0.1.0` when task 12
  closes. `tidyr` is listed in `CLAUDE.md` as an import and is not used:
  fine, but say so in `CLAUDE.md` or drop it from the list.

## 5. Tests that pass without testing

Twenty-eight mutations of the calculation code, each run against the test
files of its function.

| Result | Mutations |
|---|---|
| **Killed (26)** | cut-point `<` → `<=`; UL `>` → `>=` (total and added); vehicle use not divided by AFE; compliance ignored; probability tails swapped; lonely-PSU option not applied; baseline floor removed; meal share ignored; `household_share` ignored; coverage gate unweighted by AFE; low-outlier rule flagging zeros; `x` domain ignored; edible portion ignored; yield factor ignored; not-included records used (intake; vehicle use); infant mean replaced by maximum; bioavailability rescale dropped; DFE factor dropped; outlier exclusion ignored; food-factor priority ignored; sign of the difference; non-response status dropped; own body weight ignored; `nutrient_fraction` ignored |
| **Survived (2)** | `df = "design"` computed as the domain's (`R/estimate.R:94-95`); `flag_precision()` `n < min_n` → `n <= min_n` (`R/estimate-difference.R:144`) |

The suite is strong: the calculations are pinned by hand-computed values,
not by the code's own output. The weak spots found by reading:

| Id | Test | Why it proves little | Proposal |
|---|---|---|---|
| T1 | `test-estimate.R:70-81` (`df = "design"`) | In the fixture the domain loses one household of a PSU that keeps others, so `degf(sub) == degf(design)`: the two options cannot be told apart (mutation survived). | A domain that empties a whole PSU, so the two df differ; assert both. |
| T2 | `test-estimate.R:202-214` (`flag_precision()`) | The expectation is the implementation's own expression (`e$n < 4 \| half > 0.4`); no value at the limit (mutation survived). | Literal expected vector; one row with `n == min_n` and one with the half-width equal to the limit. |
| T3 | `test-estimate.R:129-142` (lonely PSU) | `expect_error()` without class or message; "adjust" only checks that the SE is not `NA`, not its value. | Compare the SE with `survey` under `options(survey.lonely.psu = "adjust")` at 1e-8; P84 for the class. |
| T4 | `test-estimate.R:70-91` | SE of the mean and of the median never compared with `survey` (only estimate and interval). | Add the two assertions. |
| T5 | `test-estimate.R:27-35` (`ref_design()`) | The reference builds the domain the same way as the code (zero-filled `y`, `d[inside, ]`). It is `survey`, so it is legitimate, but a second, independent form would rule out a shared misreading: `svyby()` or the ratio `svyratio(~I(y*in), ~in)`. | One test with the ratio form. |
| T6 | Tests on `hces_example` | AFE stubbed to 1 (M11). | Full-chain golden test. |
| T7 | No test of a proportion of exactly 0 or 1 | F11 went unnoticed. | With M5. |
| T8 | `test-reference-data.R:8`, `test-size-limits.R:53,61` | Skipped on the installed package, so skipped in `R CMD check` and CI (P54 for the md5). The size limits are therefore enforced only by `devtools::test()`. | Run `devtools::test()` (source tree) as a CI step next to the check. |

## 6. What is missing

### For v0.1 of the core
1. H1 to H4: without them the headline figure can be wrong or the planned
   analyses impossible.
2. H5, H6, H7 and task 12 (vignettes): without them nobody can use it.
3. M5, M6, M9: an analyst meets them in the first hour.
4. A `summary()` of the audit log (M7b).
5. Version number, `NEWS.md` header for 0.1.0 (L11).

### For the acceptance against ENGIH 2018 (tasks A1 to A4)
Nothing of the companion repository could be inspected from this session
(access is limited to `maicel1978/hcesfort`), so this list is from the
core's side only.

| Need | State in the core | Action |
|---|---|---|
| Control figures by stage (A1) | Not available here | Maintainer, with the microdata |
| "All households" and "energy-plausible" figures | Blocked by H3 | H3 |
| Original outlier rule: grouped by composition id, on edible grams, group size counting records without grams | `flag_outliers()` accepts only `hces_grams`, before the link; P60 proposes adding `composition_id` by hand and a `min_group_count = "all"` option | Decide P60 before A3: either `flag_outliers()` accepts `hces_nutrient_content` with a `value` column argument, or the adapter does the join. Fable (one paragraph), Opus |
| Vehicle grams on edible grams of surviving records | Purchased grams of every included record (P73b) | Measure in A3; option only if it differs |
| Baseline rows picked by description (P73a) | By composition id | Measure in A3 |
| Members without age or sex as zero AFE (E10) | `missing = "zero"` exists | Ready |
| Infants by annual mean | `infants = "annual_mean"` exists | Ready |
| Baseline by replacement (E1/E6) | `method = "replace_by_ingredient"` exists | Ready |
| Symmetric interval (E24) | `ci_method = "mean"` exists | Ready |
| Subset design instead of domain (E5) | No option; the adapter can build the design on the filtered households | Write it in the adapter guide as the legacy recipe |
| Households without records counted as non-consumers | Adapter sets `acquired` to `FALSE` (documented) | Needs a sanctioned way to edit a carrier and log it: M7c |
| Iron by cut-point where the original did so | Blocked on purpose by H2 once fixed | H2's explicit legacy argument |
| CV of each estimate | Not returned (L7) | L7 |
| Versions of R and packages next to the figures | Adapter side | A3 |
| Period of reference by days with a record (E4, kept as default) | Adapter sets `period_days` | The acceptance report should show the figures under the design length too; a household with one diary day is divided by 1 |

## 7. Integration with other packages

The core keeps its imports (cli, dplyr, rlang, srvyr, stats, survey). A
package enters `Suggests` only if a vignette chunk or a test runs it; an
article that is not built with the package (a pkgdown article, v1.0) can show
any package without touching `DESCRIPTION`. None of the six packages was
installed in this session, so their current dependency lists were not
checked: run `tools::package_dependencies(pkg, recursive = TRUE)` before
acting on the two "weight" remarks below.

| Package | Verdict | Why |
|---|---|---|
| **ggplot2** | **Suggests + vignette** (already planned for task 12) | The estimates are tidy with `estimate`, `ci_low`, `ci_high` and the group columns: a scenario comparison with `geom_pointrange()` is five lines and is the one figure every report needs. Keep it in the user's code; no `autoplot()` method, as the specification says. |
| **gtsummary** | **Example in an article, not Suggests** | `tbl_svysummary()` takes the design of `as_hces_design()` and gives the descriptive table of households by domain that every report opens with. Two cautions make it an article and not a built vignette: it computes its own intervals with its own defaults, so the same quantity could appear with two different intervals; and it calls `survey` directly, so the lonely-PSU choice is not applied (M6). Show it for descriptives only, never for the package's estimates. |
| **flextable** | **Example in an article, not Suggests** | Deliverables to ministries are Word documents; `flextable::flextable(estimates)` on an `hces_estimate` is the path of least resistance and works because the result is a plain tibble. One chunk with `eval = FALSE` in the reporting article is enough. One table package only, to keep the article short; flextable over the alternatives because of Word. |
| **janitor** | **Mention in the adapter guide (not evaluated); use in the companion repository** | `clean_names()` and `get_dupes()` are adapter tools: raw survey files have messy headers and duplicated keys. They belong to `hcesfort.engih2018`, whose dependencies are free. In the core's adapter vignette, one sentence and an `eval = FALSE` line. Caution to state: `clean_names()` is a starting point, the contract names are set by an explicit `rename()`; and `get_dupes()` duplicates what the key check of the validators already reports with row numbers. |
| **dlookr** | **Nothing** | Its diagnostics (missing values, outliers, normality) are unweighted and overlap with what the validators, `flag_outliers()` and the audit log already do under the package's rules; presenting a second, different outlier rule next to `flag_outliers()` invites exactly the hidden threshold the package forbids. It is also a heavy dependency for an exploratory step. An analyst who likes it can run it on the microdata before the adapter; the package has nothing to add. |
| **missRanger** | **Nothing in the core; a warning in the adapter guide** | Three places could tempt: (a) missing age or sex of members: few cases, and the package already offers explicit choices; a model-based fill is defensible but belongs to the adapter, with each filled member counted in the log (needs M7c). (b) Missing quantities or units: imputing consumption changes the estimand and its variance; single imputation followed by design-based variance understates uncertainty. (c) Missing composition values: not a statistical imputation problem. Food composition practice fills a gap from the same food in another table or from a similar food, with the source recorded, which is what `fill_composition()` enforces; a random-forest value has no source and breaks the "every value has a source" rule. State (c) in the guide so nobody tries. |

Net effect on `DESCRIPTION`: `Suggests` gains `knitr`, `rmarkdown`,
`ggplot2` (as planned) and nothing else.

## 8. Verification done for this review

- `devtools::test()`: all tests pass (run at the start of the session).
- `devtools::check()` and `lintr::lint_package()`: see the note appended at
  the end of this section.
- End-to-end runs and the mutation runs: scripts were kept outside the
  repository; every figure quoted in sections 1, 2 and 5 comes from their
  output on `hces_example` with the arguments shown in section 1.1
  (`reference_kcal = 2290.8`, `weight_kg = c(female = 55, male = 65)`,
  `pal = 1.76`, `priority = "food"`, `lonely_psu = "adjust"`).
- Versions: R 4.3.3, survey 4.5, srvyr 1.3.1, dplyr 1.2.1.

Results of the re-run:

- `devtools::check()`: 0 errors, 0 warnings, 0 notes (1 min 22 s).
- `lintr::lint_package()`: 0 lints **with the package installed**, as the CI
  job does (`local::.`). Without it installed, lintr 3.4.0 reports 536
  `object_usage_linter` lints ("no visible global function definition" for
  the package's own internals). `CLAUDE.md` asks for the lint before each
  push; say in `CONTRIBUTING.md` that the package must be installed first
  (`devtools::install()` or `R CMD INSTALL .`), or a contributor will read
  536 false alarms (**L12**, Sonnet).

## 9. Literature: what was checked and what was not

`CLAUDE.md` forbids figures and citations from memory. Status of each
reference used above:

| Reference | Used for | Status |
|---|---|---|
| Tang K, Adams KP, Ferguson EL, et al. (2022). Systematic review of metrics used to characterise dietary nutrient supply from household consumption and expenditure surveys. *Public Health Nutrition* 25(5). doi:10.1017/S1368980022000118 | H7.1: three household metrics; HCES estimates generally overestimate intake against individual-level methods | **Abstract only** (web search of 2026-11-12, PubMed 35022103). Still not opened: the article supplied by the maintainer is the Malawi paper of the next row, not this review. Cite no more than the abstract |
| Tang K, Adams KP, Ferguson EL, et al. (2021). Modeling food fortification contributions to micronutrient requirements in Malawi using Household Consumption and Expenditure Surveys. *Ann NY Acad Sci* 1508:105–122. doi:10.1111/nyas.14697 (open access, CC BY) | H2, L9, M1, M2, H7 | **Full text opened** on 2026-11-12, second session (PDF from the history of `analisis_ENGIH2018`, commit `2dad5b1`, md5 `4eec227b1dd276d1ee847035c2551ca6`; not copied into this repository). The supplementary material (Tables S1–S5) was not available. Findings in section 9.1 |
| IOM 2000, *Dietary Reference Intakes: Applications in Dietary Assessment* | H2 (conditions of the EAR cut-point; iron), H7.1 (usual intake) | **Not opened in this session.** `# SOURCE PENDING` as the primary source of the conditions of the cut-point; the iron statement itself is now backed by Tang et al. 2021 (section 9.1) |
| IOM 1998, 2001; FAO/WHO/UNU 2004; WHO 2009 | Reference tables | Taken from the package's tables and `data-raw/SOURCES.md` as they stand; not re-verified here (handoff review point 1 is still open for the maintainer) |
| Allen et al. 2020 (H-AR) | L9 | Named in the specification as v0.2; not opened |

### 9.1 What the Malawi paper (Tang et al. 2021) says, and what it does not

| Finding | In the paper | Status |
|---|---|---|
| H2: iron and the cut-point | "Iron inadequacy cannot be defined using the critical nutrient density cut-point method due to the nonnormal distribution of iron requirements" (notes of Figures 1 and 2, pp. 112–113). The paper gives no iron inadequacy figure | **Verified.** Supports the refusal; the primary source (IOM 2000) stays pending |
| L9: zinc | "Zinc inadequacy thresholds assume low bioavailability because of a diet high in unrefined grains" (same notes). Thresholds are harmonised average requirements (H-AR), listed in Table S3 | **Verified** as practice: a different requirement table, not a rescaled cut-point. Values not seen (supplement) |
| M1: outliers | "The outlying values of consumption quantity for each food item (likely due to foods acquired in bulk or recall error) were identified and replaced with the food item's median consumption quantity from the entire population" (p. 107) | **Verified:** replacement by the food's median, not exclusion and not capping at a fence (P86). The rule that identifies an outlier is not in the main text |
| M2: infants, pregnancy, lactation in the AFE | Reference person: a nonpregnant, nonlactating woman of 18–29 years; food shared in proportion to energy requirements (p. 109). "The data and assumptions necessary to calculate the AFE factors are presented in Table S1" | **Not verifiable** from the main text. M2 stays "to verify" |
| Inadequacy by apparent intake | Apparent intake per AFE below the H-AR of an adult woman (p. 109); vitamin A also against a harmonised upper limit (p. 117, Table S5) | **Verified.** Same construction as `inadequacy()` and `above_ul()`, with H-AR in place of the IOM EAR |
| Vehicle coverage and quantity | Coverage: share of households "apparently consuming any quantity" of the vehicle; quantity in grams per day per AFE, median among consumers (p. 109, Table 3) | **Verified.** Matches `vehicle_coverage()`; the paper has no per-capita quantity (M8 rests on WHO 2009 only) |
| H7.3: average content | "our status quo scenario assumed that all oil, sugar, and wheat flour consumed by households is equally fortified", although some market samples "were not fortified at all" (p. 119) | **Verified** as a stated limitation of the average-content model |
| H7.2 and H7.5: households, food away from home | Intrahousehold distribution unknown, individual estimates rest on the energy-proportional assumption (p. 118); "recall error, micronutrient loss during cooking, foods consumed away from home, fixed-food item lists" (p. 119); composition assumed constant across households (pp. 118–119) | **Verified.** Citable in the "Limits of the method" section |
| H7.1: a short window is not usual intake | The survey is a 7-day recall of consumption (p. 107); the paper does not discuss usual intake and does not say that HCES overestimate intake | **Not in this paper.** H7.1 rests on the abstract of the systematic review and on IOM 2000, both unopened |
| H7.5: guests, waste, stocks | Bulk acquisition is named only as a cause of outliers (p. 107) | **Not in this paper** as assumptions; "no guests, waste, stocks" must not be attributed to it |

## 10. The ten most important corrections, in order

| # | Correction | Findings | Model |
|---|---|---|---|
| 1 | Record-loss measure per household and a required threshold in `inadequacy()` / `above_ul()`; rename or document `_coverage` | H1 | **Fable** designs (contract of `hces_intake`, new required argument); **Opus** implements |
| 2 | `cutpoint_valid` (and the absorption an EAR assumes) in the requirements contract; `inadequacy()` refuses the cut-point where it is not valid unless asked explicitly | H2, L9 | **Fable** designs; **Opus** implements; the IOM page read and entered in `SOURCES.md` first |
| 3 | Household flags as domains of the risk estimates (`domain` accepts a household-keyed carrier) | H3 | **Fable** decides the interface (same design note as 1 and 2); **Opus** implements |
| 4 | `apply_scenario()` checks that intake and vehicle use share grams, outlier decision and AFE | H4, P76 | **Opus** (Fable accepts the added `afe` column in the same note) |
| 5 | Recalibrate `hces_example`; add the full-chain golden test | H6, M11 | **Opus** |
| 6 | Degenerate proportions; lonely-PSU choice documented or exported; classed lonely-PSU error; the two surviving mutations and T3, T4 | M5, M6, P84, T1–T4 | **Opus** |
| 7 | Classed errors for every missing required argument; the four unclear messages | M9, L3 | **Opus** |
| 8 | Audit log: no duplicated branches, `summary()`, exported `audit_note()` for adapters | M7, P50 | **Fable** decides the exported API (short); **Opus** implements |
| 9 | Limits of the method in `?inadequacy`, `?above_ul`, `?apply_scenario`, README and the main vignette; audit notes for average-content with a UL and for scenarios that differ only in compound; new README | H5, H7 | **Sonnet** writes from section 2 (H7) once the sources of section 9 are read; **Opus** for the two audit notes |
| 10 | `reference_energy()` helper; vehicle grams per capita and the WHO 2009 helper (P71); decide P60 for the acceptance | M10, M8, M12 | **Fable** approves the two additions and P60 (one paragraph each); **Opus** implements |

Order of work proposed: one Fable session writes a single short design note
for 1, 2, 3, 8 and 10 (and accepts 4); Opus implements 1–8 and 10 in that
order; Sonnet does 9 together with task 12. M1 (capping outliers), M2
(infants, pregnancy), M3 and M4 follow, before acceptance step 2. Names
(L1, L2) are decided by the maintainer once, before the vignettes are
written, because the vignettes freeze them.

## 11. Questions for the maintainer

1. **H1, threshold on record loss.** Records or grams? Recommended: both
   returned, the required threshold on records (grams are unknown exactly
   for the records that matter most, those without a conversion).
2. **H2, legacy iron by cut-point.** Was iron by cut-point one of the
   original's reported figures? If not, no legacy argument is needed and the
   function simply refuses. Recommended: refuse, add the argument only if A3
   needs it.
3. **L1, renames before the vignettes.** Recommended: rename
   `estimate_prevalence()` (it estimates means and medians too) and unify
   the energy-column argument; leave `vehicle_coverage()`, `inadequacy()`
   and `above_ul()` as they are (known from the design documents and the
   original analysis).
4. **H6, example data.** Is a recalibrated example acceptable even though it
   changes the planted-case counts recorded in tests and `NEWS.md`?
   Recommended: yes, before task 12.
5. **Network.** To check the MIMI methods and Tang et al. in full, allow
   `pmc.ncbi.nlm.nih.gov` in the environment, or send the PDFs.

### Answers (maintainer, 2026-11-12)

1. Both shares returned; the threshold is on records.
2. The original reported iron only by the probability approach (10% and
   18%), never by cut-point: `inadequacy()` refuses, no legacy argument.
3. Renames approved, before the vignettes.
4. `hces_example` is recalibrated before task 12.
5. Tang et al. supplied from the history of `analisis_ENGIH2018`: it is the
   2021 Malawi paper (section 9.1). The 2022 systematic review and IOM 2000
   remain unopened.

The design that follows from these answers is `docs/design-review-v0.1.md`.
