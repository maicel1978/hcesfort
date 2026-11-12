# Improvements: proposals and decisions

Proposals from the critical review done in roadmap task 0. Error codes
(E1…E26) refer to section 6 of `docs/analysis-map.md`. The section
"Decisions" below records what was accepted and where it was applied; the
tables keep the original wording of each proposal.

Priority: **high** = changes results or blocks a later task; **medium** =
quality or maintainability; **low** = nice to have.

## Decisions (2026-11-09)

The maintainer answered question 1 (yes), set three principles and delegated
the remaining choices:

- What is external stays external; public data stay outside the package.
- The package must connect with other packages (complex survey designs,
  `ggplot2`, the tidyverse) rather than replace them.
- It must adapt to any situation.

Applied to `CLAUDE.md`, `docs/specification.md` (now v0.2) and
`docs/roadmap.md`:

| Proposal | Status | Note |
|---|---|---|
| P1, P24 | accepted | Two-step acceptance; tolerance 1e-6 in step 1. |
| P2, P3, P4, P5, P7, P8, P9, P10, P11, P13, P14, P25 | accepted | Now part of the contracts and function list of the specification. |
| P6 | accepted | `unfortified_baseline()` is its own step. |
| P12 | accepted | Details fixed in roadmap task 11; `significant` column dropped. |
| P15 | accepted | Roadmap task 4; unverifiable values are not shipped. |
| P16 | accepted | Stays in v0.2. |
| P18, P21, P22, P27, P28, P29, P31, P32, P33 | accepted | Roadmap tasks 1 and 3; `CLAUDE.md` Quality and Size sections. |
| P19, P20 | accepted, relocated | Tasks A1 and A2 of the companion repository. |
| P23 | accepted in substance | Carrier chosen in task 2 by a test, because a tibble result serves the tidyverse principle better if the log can be made to survive. |
| P26 | changed | Decided the other way: adapters and country data live outside the package, in companion repositories. No composition table, crosswalk or national standard is shipped. |
| P30 | superseded | The adapter is not in this repository; its tests live with it. |
| P34 | moved | Applies to the companion repository. |
| P17 | closed 2026-11-12 | No issues; erratum drafted in `docs/erratum-engih2018.md`. |
| P35 | open | Branch protection; work goes straight to `main`. |

Interpretations made under the delegation, to be corrected if wrong:

- "Public data outside" is read as: composition tables, crosswalks, unit
  catalogues and standards. The small reference tables of the method (EAR, UL,
  energy requirements, WHO levels, iron distribution) are still shipped, with
  source, as replaceable defaults; without them no function runs out of the
  box. If these must also be external, task 4 becomes a companion data
  package.
- Maps leave the roadmap; plotting is shown in a vignette with the user's own
  `ggplot2` code.

Defaults adopted for the questions still unanswered (each remains an explicit
option, so the answer can change it without a redesign):

| Question | Default until answered |
|---|---|
| 3. Sec 3A reference period | 7 days; original rule kept as the legacy option. |
| 4. Dozen | Treated as an error; fixed in acceptance step 2. |
| 5. Basis of fortification levels | `# SOURCE PENDING`; level basis is a required column. |
| 7. md5 and stage-level figures | Task A1, waiting for the maintainer. |
| 8. Households without usable records | Kept in the design, outside the estimation domain, counted in the audit log. |
| 9. Review track | rOpenSci statistical software review; requirements confirmed in task 1. |
| 10. Peru survey | Unknown; contracts are written without assuming a questionnaire design. |

## Decisions (2026-11-12)

The maintainer answered the eleven questions of task 0 (numbering of the
section "Questions for the maintainer"):

| # | Answer | Applied in |
|---|---|---|
| 1 | Yes: two-step acceptance. | Specification, Validation (unchanged). |
| 2 | 1e-6, recording the versions of R and of the packages. | Specification, Validation; task A3. |
| 3 | **E4 is wrong as written.** The feasibility report (table `tbl-pm`) shows a flat median energy by number of days with a record (1 day: 2,050 kcal; 7 days: 2,189), which supports dividing by the days observed. Default: days with a record; 7 days is the option. The test is repeated with the energy of Sec 3A alone when the microdata are available. | `docs/analysis-map.md`, E4 and section 9; specification, `period_days`; P3 superseded in part. |
| 4 | The dozen is an error; its frequency is measured with the microdata. | E2 stands; acceptance step 2. |
| 5 | The basis of the levels stays `# SOURCE PENDING`; the maintainer will obtain the texts. | E8 stands; `level_basis` is a required column. |
| 6 | Adapter and country data outside the package. | Already applied (P26). |
| 7 | md5 values and stage-level control figures: yes, when the maintainer has the microdata. | Task A1. |
| 8 | Households without usable records: kept in the design, outside the estimation domain, counted in the audit log. | Tasks 8 and 11. |
| 9 | **No `srr`.** The target is the standard rOpenSci software review; decided at the end. `codemeta.json`, pkgdown and badges wait for v1.0. | P36 closed (not adopted); P37 and P41 moved to v1.0; specification, Pending decisions. |
| 10 | Peru: survey not confirmed. Contracts are written without assuming a questionnaire. | Task 2 design. |
| 11 | No issues are opened. The errors are drafted in Spanish in `docs/erratum-engih2018.md`, for the maintainer to send privately. | P17 closed. |

Also confirmed: the small reference tables are shipped inside the package,
each with its source (the interpretation of 2026-11-09 stands). The companion
repository is named `hcesfort.engih2018`; the maintainer creates it when
task A1 starts. Work goes straight to `main` (P35 stays open, low).

Consequences recorded here because they change earlier proposals:

- **P3** proposed 7 days as the ENGIH default. Superseded: the default is the
  number of days with a record. The contract keeps `period_days` as a column
  set by the adapter; its meaning is "the number of days the recorded quantity
  is divided by", and the adapter documents the rule that produced it.
- **P1** listed the reference period among the original choices to expose as
  legacy options. It is now a default with an alternative, not an error to
  correct in step 2.
- The reading of task 0 had not covered `INFORME_factibilidad.qmd`, the body of
  `INFORME_final.qmd` or the density method. They were read on 2026-11-12;
  section 9 of the analysis map lists what changed. Lesson recorded as a
  rule of work: a finding of the class "the original has no evidence for X"
  is only written after every report of the original has been read.

Residual checks on E4 that I recommend running with the microdata, because
the evidence is a median and the test mixes both sections: energy of Sec 3A
alone by days with a record; share of households above the plausibility
ceiling by days with a record; the meaning of an eighth day.

## Decisions (2026-11-12, design of task 2)

The maintainer approved the nine choices of section 10 of
`docs/design-task2.md` as recommended:

| # | Choice | Applied in |
|---|---|---|
| 1 | Carrier: tibble subclass `hces_tbl`, log in the attribute `audit`, under the three rules of section 4 (no reliance on propagation, classed error on loss, staleness recorded). | Task 2.1 |
| 2 | `validate_*()` is the single family: validator and constructor in one. | Tasks 2.2, 2.3 |
| 3 | `record_id` and `member_id` are required. | Task 2.2 |
| 4 | `stratum` and `psu` are required; a design without them passes explicit constant columns. | Task 2.2 |
| 5 | Validators reject only impossible values; plausibility is a flag with thresholds given by the caller. | Tasks 2.2, 2.3, 6, 8 |
| 6 | `sex` takes `"female"`/`"male"`; other codings are mapped by the adapter. | Task 2.2 |
| 7 | `compliance` is optional; when absent it is added as 1 with a `compliance_assumed_full` note in the log. | Task 2.3 |
| 8 | `composition$basis` must be `per_100g_edible`; other bases are converted by the adapter. | Task 2.3 |
| 9 | P42 is split: ranking (`unmatched_foods()`, task 7) and quality controls (`check_crosswalk()`, task 7b) in v0.1; candidates, seeds and the review round trip in v0.2, before the Peru adapter. | Roadmap tasks 7, 7b and v0.2 |

## Decisions (2026-11-12, task 5)

The maintainer accepted the six recommendations put in `docs/handoff.md`
after task 4. Applied in `adult_equivalents()`:

| # | Decision |
|---|---|
| 1 | Adults: BMR (`ref_bmr_equations`) at the weight given per sex (`weight_kg = c(female =, male =)`, required, no default) times `pal` (required). An optional `weight_kg` column of `members` overrides the weight of its member. |
| 2 | The reference person is one number, `reference_kcal`; the help page shows how to compute 2,290.8 kcal from `ref_bmr_equations`. |
| 3 | Infants: monthly requirement when `age_months` is known; otherwise the mean of the twelve months, counted as `infant_annual_mean`. `infants = "annual_mean"` is the rule of the original. |
| 4 | Pregnancy and lactation add no energy in v0.1; flagged members are counted (`pregnant_or_lactating_no_extra`). |
| 5 | A member without age or sex leaves the household's AFE `NA`, flagged (`missing_age_or_sex`, `household_without_afe`); exclusion is decided in task 8. `missing = "zero"` is the rule of the original (E10). |
| 6 | `meals_home_share` is used only with `meal_share = TRUE`; the argument is required when the column exists (E25). |

Consequences: `members` gains the optional column `weight_kg`; the schemas
`energy_requirements` and `bmr_equations` join `hces_schema()`; the schema
engine accepts `Inf` in a column whose interval is closed at infinity
(`"(0, Inf]"`).

## Decisions (2026-11-12, design of tasks 9 and 10)

The maintainer approved as recommended the eleven choices of section 11 of
`docs/design-task9.md` and the ten choices of section 9 of
`docs/design-task10.md`. In short:

| Task | # | Decision |
|---|---|---|
| 9 | 1 | New user table `enrichment`, keyed by composition row (`composition_id` + `nutrient`); the baseline no longer takes `vehicles`. |
| 9 | 2 | The amount removed is stated by reference pair (`enriched_ref_id`, `unenriched_ref_id`, `ingredient_fraction`) or by `added`. |
| 9 | 3 | Floor of the subtraction: `fraction × unenriched` for a pair row, 0 for an `added` row (changes P6, which said zero). |
| 9 | 4 | `apply_scenario()` refuses an intake whose log has no `unfortified_baseline` step (`hcesfort_error_audit`). |
| 9 | 5 | Compliance: average content in v0.1, named by the required argument `compliance_model`; all or nothing in v0.2 (P69). |
| 9 | 6 | New column `form` in `scenarios`, required when the nutrient's unit is an equivalent (DFE, RAE, NE, ATE). |
| 9 | 7 | New column `vehicle_group` in `vehicles`; a scenario names vehicles; coverage is also given by group. |
| 9 | 8 | Vehicle grams on the purchased basis, from every included record with grams (P73). |
| 9 | 9 | `vehicle_coverage()` returns household rows, not estimates; its product feeds `apply_scenario()`. |
| 9 | 10 | Households without food records have `acquired` missing; the original's denominator is an explicit step of the adapter. |
| 9 | 11 | Output of `apply_scenario()` wide, like `hces_intake`, with the baseline as a scenario named `baseline_label`. |
| 10 | 1 | `inadequacy()` and `above_ul()` return household rows (`p_inadequate`, `above_ul_*`); estimation is task 11. |
| 10 | 2 | Probability approach generic, `distribution = list(<nutrient> = table)`; no nutrient named in `R/`. |
| 10 | 3 | `bioavailability` required, no default; several values allowed. |
| 10 | 4 | Linear interpolation between percentiles; probability 1 below the lowest and 0 above the highest, documented as a convention (step table: P74). |
| 10 | 5 | One bioavailability for diet and fortificant in v0.1; by source later (P70). |
| 10 | 6 | `above_ul()` returns both comparisons (added only; diet plus added) with `ul_scope`; "added only" is a lower bound. |
| 10 | 7 | New column `ul_unit` in `ref_requirements`, entered after reading the cited pages; the folate UL is compared in µg of folic acid. |
| 10 | 8 | New column `ul_form` in `ref_conversions`, linking a form to the upper level it counts towards. |
| 10 | 9 | `min_coverage` required; a nutrient below it is `hcesfort_error_coverage`; household coverage is returned. |
| 10 | 10 | `requirements` must hold one row per nutrient (the caller selects the group). |

P6 is changed by choice 3 of task 9. P69, P70, P74 stay open for v0.2.

## Decisions (2026-11-12, task 11)

The maintainer approved as recommended the six choices for task 11 listed
in `docs/handoff.md`:

| # | Decision |
|---|---|
| 1 | `as_hces_design(lonely_psu =)` is required, no default, with the values of `survey.lonely.psu`; applied per call, the global option restored. |
| 2 | Proportions: `ci_method = "logit"` by default (`survey::svyciprop()`); `"mean"` reproduces the original's symmetric interval. |
| 3 | Degrees of freedom: `df = "domain"` by default (`degf()` of the domain subset); `"design"` or a number as options. |
| 4 | Medians: the default interval of `survey::svyquantile()` (Woodruff). |
| 5 | Precision: a separate `flag_precision(estimates, min_n, max_half_width)`, both limits required. |
| 6 | Differences between scenarios: mean of the within-household difference against a required `reference` scenario, as a domain of the full design. |

## Decisions (2026-11-12, corrections of the v0.1 review)

The maintainer approved as recommended the ten decisions of section 8 of
`docs/design-review-v0.1.md`:

| # | Decision |
|---|---|
| 1 | The gate on record loss is overall, not per household, and counts every household with at least one included record. |
| 2 | The new gate raises `hcesfort_error_coverage` with a field `measure` (`"records_used"`; the existing gate sets `"composition_value"`). |
| 3 | `<nutrient>_coverage`, `coverage` and `min_coverage` keep their names; the help and the error message are corrected. |
| 4 | `cutpoint_valid` is a required column of `requirements`; `TRUE` is shipped for the nutrients with no skewed requirement recorded. |
| 5 | `ear_bioavailability` only informs (log note, no rescaling); zinc is shipped as `NA` with `# SOURCE PENDING`. |
| 6 | Names: `estimate_households()`, `domain_from`, `audit_summary()`, `audit_record()`, `reference_energy()`, `who2009_levels()`, `min_records_used`, `lower`/`upper`, `missing_members`. |
| 7 | Audit logs are merged by whole rows with multiplicity; no call id, no `print` method. |
| 8 | `who2009_levels()` only filters the table. |
| 9 | P60 is done by the adapter's join; `min_group_count` only if acceptance step 1 needs it. |
| 10 | Sources: IOM 2000 (*Applications in Dietary Assessment*) to be opened at `nap.nationalacademies.org` if reachable, else the rows stay `pending`. **Opened** on 2026-11-12 (doi:10.17226/9956), chapter 4: the cut-point "simply requires the distribution of requirements to be symmetrical" and "does not work … with iron requirements in menstruating women where the requirement distribution is known to be highly skewed" (p. 81); "in the absence of additional information … it is implicitly assumed … that the unknown distribution is symmetrical around the median requirement" and the probability approach is recommended for iron (p. 91). Entered in `data-raw/SOURCES.md` as `IOM 2000b`. |

The maintainer approved as recommended, on 2026-11-12, the six choices of
P87 (implementation of 11b.1 to 11b.7): `ear_bioavailability` optional;
grams share read from the `apparent_intake` rows of the log;
`n_members` required in the `afe` of `vehicle_coverage()`; degenerate
proportions handled alike for every `ci_method`; outlier decision compared
as a string; no new vehicle-side note beyond `added_understated`.

Implemented as roadmap items 11b.1 to 11b.10.

On 2026-11-12 the maintainer approved as recommended the five choices of
P89 (implementation of 11b.8 to 11b.10), and decided P90: the average per
capita availability read against the WHO 2009 bands is the ratio of the
weighted totals of vehicle grams and household members
(`survey::svyratio()`), that is, weighted by persons, because that is what
WHO calls per capita. No review by Fable needed.

## Proposal P42: food-matching support module (2026-11-12)

Proposed by the maintainer; assessed here, not implemented. Status:
**accepted as split on 2026-11-12** (decision 9 above).

The proposal: a module that supports the matching of survey foods to food
composition tables, with no AI inside the package: (a) rank unmatched foods by
records or grams; (b) propose candidates ordered by text similarity
(`stringdist`), restricted by food group, without deciding; (c) reuse matches
already validated for another survey as a seed; (d) quality controls of the
matches (energy density, raw versus cooked, duplicates, edible portion);
(e) export and import of the review decisions (CSV or Excel).

**Assessment.** Worth doing. The crosswalk is the most expensive input of an
adapter and the one where the original analysis found its own errors: 9 of
148 assignments were wrong at first review, of three recurring kinds (part of
the food, state of preparation, degree of processing), and E20 lists further
rows that deserve review. The module turns that experience into checks. It
also fits the scope rule: it ships no crosswalk and decides nothing.

**What I would change.**

1. **Split it in two and bring the first half forward.** Parts (a) and (d)
   need only the tables of the contracts and no new dependency. (a) is the
   audit log of `link_composition()` seen by food, which task 7 must produce
   anyway (coverage over all records, by records and by grams). (d) is a set
   of flags on the crosswalk and composition tables. Both can live in v0.1 as
   `unmatched_foods()` (task 7) and `check_crosswalk()` (after task 7).
   Parts (b), (c) and (e) are the v0.2 module.
2. **(a) rank by grams when grams exist, by records otherwise, and say
   which.** A food without a unit factor has no grams; ranking only by grams
   hides it. Return both columns and the cause that blocks each food
   (no factor, no match, not validated, no edible portion).
3. **(b) similarity is a weak signal for food names; treat the output as a
   shortlist, never as a ranking of correctness.** The decisive differences
   are single words ("crudo", "cocido", "enriquecido", "hojas de") and local
   names with another meaning: "cereza" is acerola in the Dominican Republic,
   a difference of two orders of magnitude in vitamin C that no string
   distance sees. So: normalise text first (case, accents, stop words, word
   order through token-based distance), return the top *k* with the distance
   and the candidate's state and group, never fill `composition_id`, and never
   set `validated`. The restriction by food group needs a group on both
   sides; composition tables have one, surveys often do not, so the
   restriction must be optional and its absence visible.
4. **(c) a seed is a candidate source, not a match.** A match validated for
   another survey is valid for a pair (food description, composition table)
   in a country. Reused rows must arrive with `validated = FALSE`, a
   `seed_source` column and the original equivalence type, and enter the same
   review as any candidate. The join is by normalised description, because
   food codes differ between surveys; exact matches and fuzzy matches are
   reported separately.
5. **(d) each control is a flag with its rule stated, in the detect-then-decide
   pattern, with no threshold as a hidden default.** Controls I would include:
   - energy density of the matched composition row outside a range given by
     the caller per food group (catches dry versus cooked, unit errors);
   - state mismatch: purchased state versus the composition row's state,
     without a yield factor (needs a `food_state` on both sides);
   - edible portion: missing, equal to 1 for a food group that has refuse,
     below 1 for a composition row already described as edible, and one
     composition id with several edible portions (found in the original);
   - duplicates: one food code with several rows; many food codes on one
     composition id (legitimate, but worth a look when the descriptions
     differ);
   - a validated row without an equivalence type, and a validated row typed
     as needing review (both found in the original, E20);
   - composition rows with missing values for a nutrient of the registry,
     weighted by the grams they carry (E21);
   - enrichment: a match to an enriched or fortified composition row, which
     must be declared for `unfortified_baseline()` (E1, E6).
   The first control needs reference ranges. They cannot come from memory:
   either the caller supplies them or they are derived from the composition
   table itself (a row far from the median of its own group), which needs no
   external source.
6. **(e) the review file is a contract.** Fixed columns (food code,
   description, candidate id, candidate description, decision, equivalence
   type, reviewer note, date), a controlled vocabulary for the decision
   (`accept`, `reject`, `defer`), and an import that validates it like any
   other table: unknown ids, two accepted candidates for one food and edited
   keys raise classed errors. CSV only inside the package; Excel is the user's
   own `readxl`/`writexl` call, shown in the vignette. No reviewer name is
   required, and the note column is free text that the package never ships.
7. **Name the output for what it is.** The module produces a *crosswalk in
   the contract of task 2*, so everything downstream is unchanged.

**Risks.**

- Automation bias: a ranked list invites accepting the first candidate. The
  original's 6% first-pass error rate came from assisted candidates. Mitigation:
  no default acceptance, `validated` only through the imported review file,
  and the quality controls run on the result.
- False confidence from text similarity across languages and local names;
  survey in Spanish, composition table in English (FNDDS) gives distances
  that mean nothing. The module must work within one language or take a
  translation column supplied by the user.
- Scope creep towards a food-description ontology (FoodEx2, LanguaL). Out of
  scope; a column for such a code can be used for the group restriction if the
  user has it.
- Seeds carry another country's errors with an appearance of authority.
- Licences: candidate lists reproduce descriptions of the composition table;
  the package ships none, and the vignette must use the synthetic table.

**Dependencies.** `stringdist` in `Suggests`, used only by the candidate
function, with a classed error if it is missing. Checked in the build environment
(version 0.9.17): compiled, imports only base `parallel`, and its q-gram
methods (`method = "cosine"` or `"jaccard"`, `q = 2`) are insensitive to word
order, which suits food descriptions better than edit distance. Base `utils::adist()` is a fallback with
no dependency but only edit distance. No Excel dependency. No new `Imports`.

**Where it goes.** v0.1: `unmatched_foods()` with task 7; `check_crosswalk()`
as a new task after 7 (medium, Opus, small). v0.2, before the Peru adapter:
candidates, seeds and the review round trip (design by Fable, implementation
by Opus, as `docs/model-routing.md` already lists). Doing it before Peru is
right: the Peru crosswalk is its first real use, and the ENGIH crosswalk,
already validated, is its test of recall (how often the validated match is
among the top *k* candidates).

**Decision (2026-11-12):** split accepted (ranking and quality controls in
v0.1, candidates and review in v0.2).

## Open items from task 1 (2026-11-10)

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P36 | closed 2026-11-12: not adopted | **Adopt the `srr` workflow or confirm it does not apply.** rOpenSci's guide for statistical software (source read: `ropensci/statistical-software-review-book`, `pkgdev.Rmd`) requires the roclet `srr::srr_stats_roclet` in `DESCRIPTION`, a `@srrstatsTODO` tag per standard, none left at submission, and a passing `pkgcheck::pkgcheck()`; `autotest` is recommended. Its categories are general, Bayesian, EDA, machine learning, networks, probability distributions, regression, spatial, time series and unsupervised learning. Survey-based prevalence estimation fits "general" at most, so the first step is a pre-submission enquiry to the editors: statistical review, or the standard rOpenSci software review. Not done in task 1: `srr` could not be installed in the build environment (CRAN is not reachable from it). | Decides whether standards are annotated while coding (cheap) or retrofitted (expensive). | 2, before the first core function |
| P37 | low | **`codemeta.json`.** Generate with `codemetar::write_codemeta()` once the package has content; add the file to `.Rbuildignore`. | Expected by rOpenSci; not generated because `codemetar` was not available. | v1.0 |
| P38 | low | **Confirm the name on CRAN itself.** `hcesfort` is absent from the GitHub mirror of CRAN (`cran/hcesfort` does not exist, while `cran/srvyr` does), which is indirect evidence; `available::available("hcesfort")` needs a network that reaches CRAN. | The roadmap asked for the check; only the indirect one was possible. | before v1.0 |
| P39 | medium | **Maintainer e-mail.** `DESCRIPTION` uses the GitHub no-reply address already public in the commit history. CRAN needs an address that receives mail. | Avoids publishing a personal address without the maintainer's say-so. | before v1.0 |
| P40 | medium | **Dependencies enter `DESCRIPTION` when first used.** `Imports` is empty in the skeleton: listing a package that no code imports produces a check note. | Keeps `check()` at 0 notes; the list agreed in `CLAUDE.md` is the ceiling, not the starting point. | 2 onwards |
| P41 | low | **Codecov or an equivalent badge.** Coverage is computed in CI and the job fails below 90%; nothing is uploaded to an external service. | An external service needs the maintainer's account and token. | any |

## Decisions (2026-11-12, report template)

The maintainer approved as recommended the eleven decisions of section 8
of `docs/design-report-template.md`:

| # | Decision |
|---|---|
| D1 | `use_report_template(path, lang)` copies plain Quarto files; not a Quarto extension. |
| D2 | Fitness for use: one verdict line on the front page, the full answer with its conditions in Q7. |
| D3 | The reference scenario of Q1 and Q2 is a required param with no default; the unfortified baseline is always shown beside it. |
| D4 | `food_group_shares()` is brought forward to v0.1 (design `docs/design-food-group-shares.md`, then Opus). |
| D5 | The actions of Q6 are a small table written by the analyst (action, scenario from, scenario to). |
| D6 | Equity across scenarios: paired difference by quintile, with intervals; the quintile 5 to 1 ratio returns only with an interval (G3). |
| D7 | Shares are a ratio of weighted totals, not a mean of household shares; the basis is confirmed in the shares design (its decision 3). |
| D8 | Templates in English and Spanish from the first version. |
| D9 | The thresholds of Aaron et al. 2017 are shown only when the analyst passes them. |
| D10 | Amended by the maintainer: the FACT manual is not needed; the template cites Aaron et al. 2017, as such. |
| D11 | Q2 uses a dot plot with intervals, not a map. |

Gaps G1 to G7 of that design are its open items; G2 becomes roadmap
task 11c and G1 and G6 task 12b.

## Decisions (2026-11-12, food-group shares)

The maintainer approved as recommended the nine decisions of section 10
of `docs/design-food-group-shares.md`:

| # | Decision |
|---|---|
| 1 | The grouping is a new user table `food_groups`, keyed by `food_code`. |
| 2 | Two exported functions: `food_group_intake()` (household by group) and `food_group_shares()` (design-based). |
| 3 | Basis of the share: amounts per AFE and day; household totals are P97. Refines D7 of the report design. |
| 4 | Interval on the logit scale by the delta method. |
| 5 | The ratio helper stays internal in v0.1; `estimate_ratio()` is P91/P98. |
| 6 | Foods without a group form `unclassified`, shown and logged, with no threshold. |
| 7 | Missing nutrient values follow the rule of `apparent_intake()`, logged by group and nutrient; no gate in v0.1 (P96). |
| 8 | No legacy mode on the enriched table: the baseline step is always required. |
| 9 | No classification is shipped: the table is the adapter's. |

## Open items from the design of the food-group shares (2026-11-12)

The nine decisions of section 10 of `docs/design-food-group-shares.md`
were approved as recommended (see above). Implemented in task 11c.

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P95 | medium | **Shares under a scenario.** They need the added amount attributed to food records, which `apply_scenario()` does not keep. | Optional exhibit of Q6 of the report. | v0.2 |
| P96 | medium | **Gate on value coverage per group and nutrient**, mirroring `min_coverage` of `inadequacy()`. In v0.1 the grams without a value are logged, not gated. | A group with poor composition coverage is understated. | after A3 |
| P97 | low | **Share of the national supply** (household totals) as a second basis next to amounts per AFE. | Large households weigh more in the supply. | v0.2 |
| P98 | medium | **Export the ratio helper** as `estimate_ratio()` (P91) and add the contrast between two domains (G3 of the report design). | One way to estimate. | v0.2 |

## Open items from task 11c (2026-11-12)

Self-review of 11c as an rOpenSci reviewer would. Fixed in the task: a
domain without degrees of freedom gave `NaN` warnings in the interval
(now no interval); the `used` row of the new log counts only records of
estimated households, now documented.

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P99 | high | **Choices taken in implementation, to confirm.** (1) A share of exactly 0 or 1 has `se = 0` and **no interval** (`ci_low`, `ci_high` missing), the rule of the degenerate proportions of 11b.6; the design note said "an interval equal to the estimate" while citing that rule. (2) `acquired` is `NA` unless the household is `estimated`, so `estimate_households(value = "acquired")` gives the share among estimated households. (3) `validate_food_groups()` raises `hcesfort_error_key` for a duplicated food and `hcesfort_error_value` for a missing, empty or reserved group (the design's test list said `hcesfort_error_schema` for all), as every other validator. (4) Groups are in the order of first appearance in `food_groups`, `unclassified` last and only when a food of `content` has no group. (5) The rows `unclassified` and `no_nutrient_value` count the used records of estimated households; the log cause for foods of the grouping absent from `content` keeps the design's name `group_not_in_content`. | CLAUDE.md: no interpretation chosen silently. | 12b |
| P100 | low | **`food_group_shares()` calls `svyratio()` once per nutrient, group and domain**, each on an updated copy of the design. On a national survey (8,000 households, 15 groups, 4 nutrients, 10 domains) that is 600 calls; one call per nutrient and domain with every group as numerator would do. | Performance. | v0.2 |
| P101 | low | **No domain argument in `food_group_shares()`** (only `by`); a logical `domain` or `domain_from`, as in `estimate_households()`, would allow shares among, for example, households with plausible energy. | Consistency of the estimators. | v0.2 |

## Open items from task 2 (2026-11-12)

Self-review of task 2, done as an rOpenSci reviewer would. Items in scope
were fixed in the task (an all-`NA` logical column was rejected by type;
the key check did not allow the generic `food_code = NA` of
`unit_factors`). The rest:

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P43 | closed 2026-11-12: adopted | **Class name `hces_nutrients` is used twice in the design.** Section 6 gives it to the registry (implemented); section 4 lists it among the products of later tasks (`hces_grams`, `hces_nutrients`, `hces_intake`). The product needs another name, for example `hces_nutrient_content`. **Decision: the product is `hces_nutrient_content`.** | Two meanings of one class would make `require_hces()` accept the wrong table. | 7 or 8, before the product is written |
| P44 | closed 2026-11-12: adopted | **Validated crosswalk row without `composition_id`.** The design rejects a validated row without `match_type` but says nothing of a validated row without a match; it is accepted and counted as `unmatched_food`. **Decision: rejected as `hcesfort_error_value`; applied in `validate_crosswalk()`.** | A row saying "validated: no match" may be a legitimate decision or an error; the design does not say which. | 2 (small change) or 7 |
| P45 | medium | **Food-code types across user tables.** `food_code` must have a compatible type in `acquisitions`, `unit_factors`, `crosswalk` and `vehicles`; checked where the tables meet, as `validate_survey()` does for `household_id`. | An integer code against a character code makes every later join fail. | 6, 7, 9 |
| P46 | medium | **Carrier regression test without tidyr and srvyr verbs.** The experiment of the design also covered `pivot_*`, `nest`, `drop_na`, `replace_na` and `as_survey_design()`; they are added to `test-audit-carrier.R` when tidyr and srvyr enter `Imports`. | Keeps the record of section 4 of the design complete. | 6 (tidyr), 11 (srvyr) |
| P47 | low | **Content hash of a carrier.** A `mutate()` that changes values without changing the number of rows is not detected (documented limit, design section 4). A hash per call would detect it at a cost that grows with the data. | Recorded as the design asked. | after v0.1 |
| P48 | low | **`validate_survey()` on validated tables does not refresh its notes.** It writes its notes once; after a user filter the counts of households without members or acquisitions are stale (the filter itself is recorded as `external_change`). | Rare; the step that uses the status (task 8) recomputes it. | 8 |
| P49 | low | **Error messages name the table, not the argument.** `validate_composition(x, ...)` says "`composition` has...", while the argument is `x`. Consistent across validators and clearer for the user, but differs from the tidyverse habit of naming the argument. | Style. | 12 |
| P50 | low | **No `print()` method for `hces_survey` and `hces_tbl`.** Printing a validated table shows a plain tibble; the log is reached with `audit_log()` (design section 4). | Discoverability. | 12 |

## Open items from task 4 (2026-11-12)

Every reference value was read in the source document during the session
(FAO, IOM and WHO texts opened online; places in `data-raw/SOURCES.md`).
All values used by the original analysis agree with the documents. Two
values stay pending and are not shipped (vitamin D: the intake its UL
applies to; retinyl palmitate to RAE). Self-review, as an rOpenSci reviewer
would:

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P51 | medium | **`ref_requirements` covers one group (women 19–30 years).** Other life stages (children, men, pregnancy, lactation) are entered from the same IOM summary tables when a function needs them. | The method uses the reference woman; a per-person analysis (prevalence by persons, v0.2) needs every life stage. | 10 or v0.2 |
| P52 | medium | **Nutrient names differ between WHO 2009 and the registry.** WHO gives folic acid (a compound) where the requirement is folate in DFE; vitamin A is given "as nutrient" without its form. The mapping from a WHO row to a scenario row (`level_basis`, `compound`, conversion through `ref_conversions`) belongs to the scenario design. | E8; the scenario contract already has `level_basis` and `compound`. | 9 (Fable design) |
| P53 | closed 2026-11-12: decisions 1-3 of task 5 | **Adults' energy needs weight and PAL from the user.** `ref_bmr_equations` ships the equations only; body weight and physical activity level are arguments without default (the 55/65 kg and PAL 1.76 of the original come from the ENGIH methodology and belong to the adapter). Infants are monthly; averaging the twelve months, as the original did, is an explicit option. | No hidden default (CLAUDE.md). | 5 |
| P54 | low | **The md5 test of `data-raw/` runs only from the source tree.** `R CMD check` (and so CI) tests the installed package, where `data-raw/` is absent, and the test is skipped. A CI step running `devtools::test()` from the checkout would enforce it. | The check exists and runs locally before every commit. | 12 or v1.0 |
| P55 | low | **Long tables carry the unit in a `unit` column.** `ref_requirements` holds several nutrients, so `ear` and `ul` cannot carry a unit suffix; the unit is a column written as in `nutrient_registry()`. Functions that use it must check the unit against the registry. | A deliberate exception to "column names carry the unit". | 10 |
| P56 | low | **`sex = "both"` in `ref_iron_requirements`.** Young children's percentiles are pooled for both sexes; the members contract uses `female`/`male`. The function that picks a group must accept `both`. | Join rule to state in task 10. | 10 |
| P57 | medium | **Energy for pregnancy and lactation.** FAO/WHO/UNU 2004 gives additions per trimester and for lactation; they enter `ref_energy_requirements` and `adult_equivalents()` once read in the document, with an explicit option. | Decision 4 of task 5 leaves them out in v0.1. | v0.2 |
| P58 | low | **Member-level requirements are not returned.** `adult_equivalents()` returns households only; prevalence by persons (v0.2) needs each member's requirement and AFE. A `level = "member"` option or a second function. | Not needed by v0.1. | v0.2 |

## Part A. From the review of the original analysis

| ID | Priority | Proposal | Rationale | Roadmap task |
|---|---|---|---|---|
| P1 | high | **Two-step acceptance test.** Step 1: reproduce `cifras_control/` exactly, with each questionable choice of the original exposed as an explicit, documented option of the adapter or of a core function (reference period, dozen factor, zero AFE for incomplete members, household subset). Step 2: switch each option that is an error to the corrected default, one per commit, and record old and new figures in `NEWS.md`. | The control figures embed E1, E2, E4, E5 and E10. A package that fixes them cannot match the figures, and a package that matches them without saying how has ported the errors. The two steps separate "the port is faithful" from "the method is right". | 10; specification, section Validation |
| P2 | high | **Audit log by cause at every stage, and coverage measured before anything is dropped.** Each core function returns counts of records, households and, where grams exist, grams lost, by cause: no unit factor, no crosswalk, crosswalk not validated, no edible portion, missing quantity, no AFE, outlier. `link_composition()` reports coverage as a share of records and of grams over all food records, including those it could not convert. | E3: about 18% of Sec 3A records disappear before coverage is computed, so the reported coverage is near 100% by construction and "intake is a floor" has no measured size. | 2 (format), 5, 6 |
| P3 | high | **Reference period as an explicit contract column.** `acquisitions$period_days` is supplied by the adapter and documented as the length of the observation window, not the number of days with records. ENGIH adapter: 7 days by default; the original rule kept as the legacy option of P1. A household-level diary-completeness variable, if the survey has one, is the only reason to depart from the design length. | E4: dividing by days with purchases overstates the daily acquisition of households that shop on few days. | 2, 6, 10 |
| P4 | high | **Typed unit-conversion table.** Columns: `unit`, optional `food`, `factor`, `factor_type` (`mass_g`, `volume_ml`, `count`), optional `density_g_ml`, `source`. A `count` unit (dozen) multiplies a per-unit weight and is never read as grams; a `volume_ml` unit needs a density and fails without one unless the caller sets a default explicitly. | E2 (a dozen = 12 g) and E18 (every liquid at the density of water) are the same defect: a factor column whose meaning varies by row. | 2, 5 |
| P5 | high | **Scenario contract with the basis of each level.** Scenario table columns: `scenario`, `vehicle`, `nutrient`, `level_mg_kg`, `level_basis` (`nutrient` or `compound`), `compound`, `nutrient_fraction`, `compliance` (default 1), `source`. Conversions to the composition unit (DFE, RAE) come from a reference table with its citation. Vehicles and flour fractions are assigned in a food-level table keyed by food code, with a source per fraction. | E8: the vitamin A level is read as retinol without evidence; the nutrient is labelled `folato_mcg_dfe` while the level is folic acid in mg/kg. Regular expressions on descriptions (E12) cannot be validated by a contract. A `compliance` column costs nothing now and removes the largest known overstatement (full compliance) from the list of things that need a redesign later. | 3, 7 |
| P6 | high | **The unfortified baseline is a composition table, built once and used everywhere.** `apply_scenario()` first produces the baseline composition; intake, food-group shares and every scenario start from it. For derived products, replace only the enrichment: baseline = table value − flour fraction × (enriched flour − unenriched flour), floored at zero, instead of flour fraction × unenriched flour. Whole-grain foods are not vehicles of refined-flour enrichment unless the vehicle table says so. | E1 exists because the baseline lives inside one script. E6: the current rule deletes the iron and folate of every non-flour ingredient. Design note for the maintainer: "subtract what enrichment added" keeps the food's own nutrients; "replace by flour" throws them away. | 7; fixes E1 in v0.2 food groups |
| P7 | high | **UL evaluated on a named form, with the form present in the composition.** Reference table gains `ul_applies_to` (`total`, `added`, `preformed_retinol`, `synthetic_folic_acid`). Composition schema accepts optional `retinol_ug` and `folic_acid_ug`. `above_ul()` reports the added-only share and, when the form is available, the share for diet plus added; the output states which one it is. Wording "upper bound" is dropped. | E7: for vitamin A the current figure is a lower bound, and the reports say the opposite. | 3, 8 |
| P8 | high | **Explicit policy for households without usable food records, and domain estimation instead of subsetting.** `apparent_intake()` returns every household of the `households` table with a status (`estimated`, `no_food_records`, `all_records_lost`). `estimate()` always declares the design on the full sample and treats subsets (energy-plausible, with intake) as domains. | E5: 114 households vanish from the risk denominator and stay in the coverage denominator; subsetting before declaring the design can also understate variance. | 6, 9 |
| P9 | medium | **`compute_afe()` fails on members without age or sex unless the caller chooses a policy** (`error`, `drop_household`, `impute_reference`), and counts them in the audit log. Optional member columns `pregnant`, `lactating`, `present_share`. The reference person is an argument, so adult male equivalents are a parameter and not another function. | E10. Peru's survey may record pregnancy or meals taken at home; the contract should not need a redesign to use them (E25). | 2, 4 |
| P10 | medium | **Add `flag_outliers()` to the specification**, with the scale (household grams, per capita, per AFE), grouping, quantiles, multiplier and minimum group size as arguments, no defaults taken as truth, and the decision (exclude, winsorise, keep) as a separate argument of `apparent_intake()`. | The step exists in the original (`03`, `04`) and is missing from the specification. E9: the original detects on household totals. Its thresholds have no source, so they cannot be package defaults without saying so. | 5 or 6; specification |
| P11 | medium | **Missing composition values are never summed as zero silently.** `apparent_intake()` reports, per nutrient, the share of grams with a value; `inadequacy()` refuses (classed error) or warns below a coverage threshold chosen by the caller. | E21: vitamin D and E results of the original are partly an artefact of missing values. | 5, 6, 8 |
| P12 | medium | **Estimation details fixed in one place.** Interval method for proportions that respects [0, 1] (logit or beta; check `survey::svyciprop()` and its `srvyr` interface when implementing), intervals for medians and for the share above the UL, an explicit and documented choice for strata with a single PSU, and no `significant` column (report the interval; multiplicity is the reader's decision). | E24. | 9 |
| P13 | medium | **Functions missing from the specification:** `vehicle_coverage()` (coverage, consumption among consumers, combined reach), `nutrient_density()` (per 1,000 kcal, with the critical density EAR ÷ reference energy), an energy-plausibility flag, `fill_composition()` (documented gap filling), `verify_md5()`. | All are used by the original reports; coverage and consumption of vehicles is the first deliverable of the analysis and has no function in the specification. | specification; 5–9 |
| P14 | medium | **Composition contract with metadata.** Per table: basis (per 100 g edible portion), unit per nutrient, edition, state of the food (raw, cooked, as consumed), licence. The crosswalk records the equivalence type, and a raw purchase matched to a cooked food requires a yield factor or an explicit waiver. Edible portion is keyed by survey food, not by composition id. | The original assumes the basis and four units without verification (author's own notes), mixes a raw-food table with an as-consumed one (E20), and found that one composition id has two edible portions. | 2, 5 |
| P15 | medium | **Verification list for task 3.** Every reference value enters `data-raw/` with document, table and page; anything that cannot be opened and checked is written `# SOURCE PENDING`. Known gaps: adult body weights, flour fractions, iron bioavailability of 10%, outlier and plausibility thresholds, precision rule, iron requirement table number, WHO 2009 B12 and vitamin A rows, the text of RTD 616, FNDDS edition. | The original cites editions but not tables or pages, and marks several values as unconfirmed. | 3 |
| P16 | low | **Food-group shares with the design and a stated denominator** (share of national supply versus share of per-AFE intake), on the baseline composition. | E1, E22. | v0.2 |
| P17 | low | **Report the findings upstream.** Open issues in `analisis_ENGIH2018` for E1–E5, E7 and the stale documentation (E15), so the reports can carry an erratum. Not done: needs the maintainer's go-ahead. | The published reports contain the affected figures. | outside the roadmap |

## Part B. From the review of CLAUDE.md, the specification and the roadmap

| ID | Priority | Proposal | Rationale | Where |
|---|---|---|---|---|
| P18 | high | **`.gitignore` ignores `docs/`.** Remove that line, keep the design documents where they are, and publish pkgdown from a `gh-pages` branch (or move the design documents to `dev/` and add it to `.Rbuildignore`). | New files under `docs/` are untracked unless forced, which is how a document gets lost; the two files of this task had to be added with `git add -f`. pkgdown writes to `docs/` by default and would mix the site with the design documents. | roadmap task 1 |
| P19 | high | **Generate intermediate control figures from the original pipeline before porting.** One aggregated file per stage: record counts by section and by drop cause, total grams by section, distribution of household AFE, weighted median intake per nutrient before scenarios. Add them to `cifras_control/`. | The roadmap validates only at task 10. With six files of final results, a mismatch at the end cannot be located. Stage-level figures let each of tasks 4 to 9 be accepted on its own. Needs the microdata, so the maintainer runs it. | new task 0.5 (before 4) |
| P20 | high | **A thin ENGIH adapter early.** Move the reading and standard-table part of task 10 to just after task 2; keep the acceptance test at 10. | The data contracts of task 2 are designed blind until a real survey is pushed through them. The adapter is where the contracts meet ENGIH's oddities (two id columns, presentation versus base unit, two sections). | roadmap order |
| P21 | high | **A synthetic example dataset shipped with the package.** A few dozen invented households in the standard schema, with composition and one scenario, documented as synthetic. | With no microdata allowed, examples, vignettes, CI and coverage have nothing to run on. rOpenSci expects runnable examples. | new task after 2 |
| P22 | high | **Decide the review track now, not at v1.0.** If rOpenSci statistical software review is the goal, its standards are annotated in the code while it is written (the `srr` workflow) and are expensive to retrofit. Requirements to confirm on rOpenSci's guide before task 1. Add to task 1: `README`, `CITATION`, `codemeta.json`, contributing guide, code of conduct, `pkgcheck` in CI. | "rOpenSci quality" is the stated goal; the specification leaves the decision pending and the roadmap puts it last. | specification, Pending decisions; roadmap 1 |
| P23 | high | **Audit log as a list element of a classed result, not an attribute.** Result = object of class `hcesfort_result` with `$data` and `$audit`; the audit accumulates when one result is piped into the next function. | The specification leaves "attribute or list element" open. Attributes are dropped by many `dplyr` verbs and by joins, which would lose the log silently: the opposite of the rule it serves. | specification, Principles; roadmap 2 |
| P24 | high | **Acceptance tolerance far below 0.05 percentage points for step 1 of P1.** Same data and same method should agree to floating-point error: absolute 1e-6 on percentages and medians. Step 2 has no tolerance: it records differences. | A tolerance of 0.05 pp passes a port that loses a handful of households. Of 8,778 households, one household is about 0.01 pp. | specification, Validation |
| P25 | medium | **Complete the standard schemas.** `acquisitions`: `period_days`, `section`, `include` flag set by the adapter's combination rule, optional `source` (purchase, own production, gift), optional `share_household`. `households`: optional food-module response flag. `members`: optional `pregnant`, `lactating`, `present_share`. Nutrients are handled through a registry (name, unit, column) so the core is not tied to the eight nutrients of ENGIH. | The specification's tables cannot express the exhaustion rule, the destination variables the original ignores (declared assumption in the manual), or a nutrient the original did not study. | specification, layer 1; roadmap 2 |
| P26 | medium | **Decide where adapters and country data live** (see question 6). Recommended for v0.1: inside the package but isolated (`R/adapter_engih2018_*.R`, `inst/extdata/engih2018/`), composition tables only if their licence allows redistribution, split into a companion package when Peru arrives. | The INCAP and FNDDS workbooks and the crosswalk are large and country-specific; shipping them makes the package a Dominican dataset with functions attached. Their redistribution terms are not recorded in the original repository. | specification, Architecture |
| P27 | medium | **Imports versus Suggests, stated.** Imports: `dplyr`, `tidyr`, `rlang`, `cli`, `survey`, `srvyr` as listed. Suggests, already justified: `readxl` (adapter), `testthat`, `knitr`, `rmarkdown`, `withr`. Base packages `stats` and `tools` are not "other dependencies". | The rule "justify any other in the commit message" will otherwise fire on every adapter and test commit. | CLAUDE.md, Quality |
| P28 | medium | **Scale the pre-commit rule.** Before each commit: `document()`, `test()`, lint of changed files. Before each push and at the end of each task: `check()` with 0/0/0 and full lint. CI enforces the same on three systems. | With commits capped at 300 lines, a task is many commits; a full `check()` on each adds minutes without catching more than `test()` plus CI. The guarantee (nothing unverified reaches the remote) is unchanged. | CLAUDE.md, Quality |
| P29 | medium | **Make the size limits measurable.** State how lines are counted (function body, excluding roxygen and blank lines), exempt generated files and `data-raw/` scripts from the 300-line commit cap, and enforce the limits with a linter or a small test rather than by eye (check which `lintr` linter covers function length when configuring task 1). | A limit nobody measures is either ignored or argued about. Reference tables entered in `data-raw/` can exceed 300 lines in one legitimate commit. | CLAUDE.md, Size and verification; roadmap 1 |
| P30 | medium | **Coverage rule that survives the no-microdata rule.** The ENGIH adapter is tested in CI against a tiny hand-built file in the ENGIH layout (a few rows per sheet); only the acceptance test is skipped. | Otherwise the adapter is the least tested code (it only runs locally) and drags coverage below 90%. | CLAUDE.md, Non-negotiable rules; roadmap 10 |
| P31 | medium | **md5 rule made precise.** Mandatory for files the package registers (microdata of an adapter, reference tables in `data-raw/`); available but optional for user-supplied files. The ENGIH registry needs the two md5 values from the maintainer (E16). | As written the rule cannot be applied to a user's own survey, and for ENGIH the values do not exist yet. | CLAUDE.md, Defensive programming; roadmap 10 |
| P32 | medium | **Full compliance is a parameter in v0.1** (the `compliance` column of P5); retention factors stay in v0.2. | The roadmap defers both. Compliance is one multiplication and addresses the main criticism of the scenario results; retention needs a table of factors and belongs later. | roadmap 7 and v0.2 |
| P33 | low | **Function names.** `estimate()` is too generic for an exported function; prefer names that say what is estimated (`estimate_prevalence()`, `estimate_difference()`), and `adult_equivalents()` if P9 makes the reference person an argument. | Avoids clashes without a package prefix, in line with the style rule of `CLAUDE.md`. | specification, layer 2 |
| P34 | low | **Personal names in ported data.** The crosswalk's free-text notes mention people; strip the notes column or rewrite it when the file enters `data-raw/`. | `CLAUDE.md` forbids personal names in code and documentation. | roadmap 10 |
| P35 | low | **Branch protection for `main`.** Work goes straight to `main`; require the CI check to pass on `main` and consider short-lived branches from task 1 on. | Once CI exists, a direct push that breaks the three-system check is found after the fact. | roadmap 1 |

Rules reviewed and kept as they are: classed errors, checked joins with
declared cardinality, explicit units in column names, hand-computed expected
values in tests, no microdata in the repository, "ask, do not choose
silently". They cost little and each maps to a defect found in the original
(E3, E17, E8, E2).

## Open items from task 6 (2026-11-12)

Self-review of `convert_units()` and `flag_outliers()`, done as an rOpenSci
reviewer would. Fixed in the task: an empty table gave columns of the
wrong type and an error in `flag_outliers()`; a divisor of zero AFE gave an
infinite value. The rest:

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P59 | closed 2026-11-12: accepted | **Choices of task 6 taken under delegation.** **Decision: the five are accepted. In acceptance step 1 (A3) `priority = "generic"` reproduces the original; in step 2 the corrected call uses `priority = "food"`.** (1) `priority` (food or generic factor first) is required, no default. (2) `household_share` is applied in `qty_g_d`; a missing share leaves the record without daily grams (`missing_household_share`). (3) The edible portion is not applied in `convert_units()`: it is a column of the crosswalk and the composition step applies it. (4) `flag_outliers()` counts only values with grams towards `min_group` and leaves small groups `NA` (not assessed), not `FALSE`. (5) At household level the records without grams are left out of the household's sum. | CLAUDE.md: no interpretation chosen silently. Each is one line to change. | 6 |
| P60 | medium | **Reproducing the original outlier rule (task A3).** The original grouped by composition id (records without one formed one group), on edible grams per day, and counted every record of the group, with or without grams, towards the minimum of 20. With the package: add `composition_id` to the grams table before the call and group by it; the edible portion is a constant per food, so it changes the flags only where one composition id has foods with different portions; the count towards `min_group` differs where a group has records without grams. If step 1 does not reproduce the counts, a `min_group_count = "all"` option is the smallest change. | Acceptance step 1 needs the original choices as options. | A3 |
| P61 | medium | **Weighted quantiles in `flag_outliers()`.** Quantiles are unweighted, as in the original (E9). A weighted option (household weights) makes the fences describe the population rather than the sample. Needs `households` as an argument. | Methodological; not needed to reproduce the original. | 11 or v0.2 (Fable) |
| P62 | low, still open after task 8 | **Calling `flag_outliers()` twice overwrites `outlier`.** Both runs are in the log, with their rules; a second rule (for example per AFE after per household) needs its own column name. An argument `name = "outlier"` would allow several flags side by side. | Sensitivity analyses compare rules. | 8 |
| P45 | medium, in part | `food_code` and `unit` types are now checked between `acquisitions` and `unit_factors` (task 6) and between grams and the crosswalk, and `composition_id` between crosswalk, composition and fills (task 7); vehicles remain. | | 9 |

## Open items from task 7 (2026-11-12)

Self-review of `link_composition()`, `fill_composition()` and
`unmatched_foods()`, as an rOpenSci reviewer would. Fixed in the task: the
first draft lost the difference between an unmatched and a not-validated
food (the composition id was blanked before the reasons were computed);
empty tables kept their column types.

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P63 | closed 2026-11-12: accepted with a change | **Choices of task 7 taken under delegation.** **Decision: accepted; the linked records whose missing `yield_factor` is taken as 1 are counted in the audit log as a note (`yield_factor_assumed_one`), as `compliance` is.** (1) A missing or absent `yield_factor` counts as 1 (no change of state). (2) Nutrient columns of `hces_nutrient_content` keep the registry names (`iron_mg`) and mean amount per day for the household; the time basis is a property of the table, as in `qty_g_d` it is in the name. (3) A validated crosswalk match whose composition id is absent from the composition table is an `hcesfort_error_join`, not a record left unlinked. (4) New user table `composition_fills` (key `composition_id` + `nutrient`; `value`, `source`); a fill for a cell that has a value is not used and is counted (`fill_not_needed`). (5) `missing_nutrient_value` in `link_composition()` is `flagged` (a record carries a missing nutrient), while the validator counts it as a `note` (a cell of the table). | CLAUDE.md: no interpretation chosen silently. | 7 |
| P64 | low | **Filled cells are traced in the log, not per row.** The share of a household's intake that rests on filled values needs to know which cells were filled; a logical column per nutrient (`iron_mg_filled`) or a long table of filled cells returned as an attribute would allow it. | E21: the weight of gaps in vitamins D and E. | 8 or v0.2 |
| P66 | closed 2026-11-12: accepted | **Choices of task 7b taken under delegation.** (1) `check_crosswalk()` checks validated rows only; other rows get `NA`. (2) The flags are columns added to the crosswalk (prefix `flag_`, plus `n_missing_nutrients`), so the checked table still passes to `link_composition()`. (3) The state control uses the composition's `food_state` (cooked or as consumed) and the absence of a yield factor, because the crosswalk has no purchase state; a `purchase_state` column would make it exact. (4) Ranges are given by the user per nutrient column, optionally by a group column of the composition; deriving ranges from the composition table itself (distance to the group median) is left out. (5) The energy-density control is the general range control applied to the energy column. | CLAUDE.md: no interpretation chosen silently. | 7b |
| P67 | closed 2026-11-12: accepted | **Choices of task 8 taken under delegation.** (1) A linked record without a value for a nutrient adds nothing to it, and each nutrient has a `_coverage` column (share of edible grams used with a value); the alternative, `NA` for the household, would leave most households without vitamin E in a table like INCAP. (2) Household status, in order: `food_module_nonresponse`, `no_food_records`, `all_records_lost`, `no_afe` (missing or zero AFE), `estimated`. (3) An outlier not assessed (`NA`) is kept under `outliers = "exclude"`. (4) Winsorising is not offered: the fences are not stored by `flag_outliers()`; it needs them as columns. (5) The plausibility flag is its own function, `flag_energy_plausibility()`, with both limits required; `nutrient_density()` has `per = 1000` as a visible default (a convention of expression, not a threshold). (6) Nutrient columns of `hces_intake` keep the registry names and mean amount per AFE per day. | CLAUDE.md: no interpretation chosen silently. | 8 |
| P68 | low | **Winsorising flagged records.** `flag_outliers()` could return the fences (`outlier_low_g_d`, `outlier_high_g_d`) so that `apparent_intake(outliers = "winsorise")` replaces a flagged value by its fence. | P10 listed winsorising as one of the decisions. | after v0.1 |
| P65 | low | **`share_grams` of `unmatched_foods()` is `NaN` when no record has grams.** Harmless (nothing to rank by grams), but a classed warning or `NA` would be clearer. | Edge case. | 12 |


## Open items from the design of tasks 9 and 10 (2026-11-12)

Designs: `docs/design-task9.md` and `docs/design-task10.md`, approved
2026-11-12. Items left out of v0.1 on purpose, or to be measured later:

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P69 | high | **All-or-nothing compliance model.** A share `compliance` of each vehicle carries the full level and the rest none; the household result is a probability (with one vehicle, `c × indicator(full) + (1 − c) × indicator(baseline)`; with several, over the combinations of vehicles, assumed independent). v0.1 implements the average-content model only, named by a required argument. | The two models give the same mean and different shares below the EAR and above the UL; average content understates the share above the UL when few households are near it. | v0.2 (Fable designs), or task 9 if choice 5 of the design goes the other way |
| P70 | medium | **Iron bioavailability by source.** `absorbed = b_diet × baseline + b_added × added`, instead of one value for the whole intake. Needs absorption values per compound and diet with a verifiable source. | WHO 2009 sets different levels per iron compound because absorption differs; one value overstates scenarios with poorly absorbed compounds. | v0.2 |
| P71 | low | **Helper from `ref_who2009_flour` rows to scenario rows.** Must make the reading of vitamin A (`form`) an argument without default. | The mapping is short, but repeated by every user of the WHO table. | 12 (vignette first) |
| P72 | low | **Compare `vehicles$vehicle_fraction` with `enrichment$ingredient_fraction`.** Two fractions describe the flour of one food on two bases (purchased food, composition row); a check that lists pairs that disagree beyond a tolerance given by the caller. | Same kind of duplication as E12. | 9 or v0.2 |
| P73 | medium | **Two points where acceptance step 1 may not match exactly.** (a) The original picked the rows of the baseline by the food's description, the package by composition id. (b) The original's vehicle grams are edible grams of the records that survived E3; the package uses purchased grams of every included record. Measure both with the microdata; add an option only if a difference appears. | Acceptance step 1 needs the original choices as explicit options. | A3 |
| P74 | low | **Step function for the iron probability.** IOM (2001, Appendix I) tabulates the probability of inadequacy by ranges of intake; offer it as `interpolation = "step"` once the tables are opened and entered in `data-raw/` with their place. | Fidelity to the cited source; the difference from linear interpolation is small. | v0.2 |

## Open items from task 9 (2026-11-12)

Self-review of `unfortified_baseline()`, `vehicle_coverage()` and
`apply_scenario()`, as an rOpenSci reviewer would. Fixed in the task: a
households table without `food_module_response` gave `vehicle_coverage()`
statuses of length zero; a scenarios table without rows failed on column
types (it now returns the baseline only); a cell below the floor of the
subtraction would have been raised to the floor (it is now kept, so no
cell increases, and flagged). Decisions taken in implementation, within
the approved design:

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P75 | medium | **Choices of task 9 taken in implementation.** (1) `unfortified_baseline()` rejects a table that already has `baseline_status` (applying the rules twice would remove the enrichment twice); the design left "reject or no change" open. (2) A cell whose value is already below the floor `f × U` is kept, not raised, and flagged `floored`; so "no cell increases" holds and "subtract ≥ replace" holds only where `v ≥ f × U`. (3) `n_records` of `vehicle_coverage()` counts included records (after the outlier decision), not every record of the food. (4) A household without the food module or without records has `qty_vehicle_g_d` missing, like `acquired`. (5) The pending sources of `vehicles` and `enrichment` are counted once, by their validators (`source_pending`), whose rows travel in the log; `apply_scenario()` adds `scenario_source_pending` in its own step, as the design asked. (6) `SOURCE PENDING` is recognised as a prefix, so a source can carry the adapter's reading after it. (7) `added` is missing, not 0, for households whose intake is not estimated. | CLAUDE.md: no interpretation chosen silently. | 9 |
| P76 | closed (11b.4) | **`apply_scenario()` checks statuses, not AFE values.** It requires that every household estimated in `intake` is estimated in `use`, but not that both were divided by the same AFE. A check that the AFE of each household agrees (`use` does not keep it today) would close the gap; adding `afe` to `hces_vehicle_use` is enough. | Two AFE tables give silently inconsistent totals. | 11 |
| P77 | low | **A `form` given for a nutrient in a plain mass unit is not used.** For iron (`mg`), `form = "ferrous_fumarate"` is accepted and ignored: the factor is 1 and no form column is returned. A note in the log would make that visible. | Nothing silent. | 10 or 12 |
| P78 | low | **`hces_example` has no md5 entry.** `data-raw/MD5` registers the reference CSVs; the example is rebuilt deterministically by its script. Register `data/hces_example.rda` if the build is to be checked like the reference tables. | Reproducibility rule of CLAUDE.md. | 12 |

## Open items from task 10 (2026-11-12)

Self-review of `inadequacy()` and `above_ul()`, as an rOpenSci reviewer
would. Fixed in the task: the factor from mg per kg to µg per 100 g was
computed as `1e-3 / 1e-6 / 10`, which is not exact in floating point and
made an amount equal to the UL compare as above it (now `1000 / 10`); a
requirements table without any EAR or UL failed on column types (it now
returns no rows). Choices taken in implementation, within the approved
design:

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P79 | medium | **Choices of task 10 taken in implementation.** (1) A nutrient named in `distribution` needs no row in `requirements`. (2) The overall coverage is computed on the rows of the first scenario (the coverage columns are those of the baseline in every scenario); when no estimated household has grams it is `NA`, not an error, and the log says so. (3) With several forms of one UL category in the registry, the coverage of the diet part is the smallest of their coverages. (4) A form category with a diet part but no scenario adding the form is `form_diet_and_added` with nothing added. (5) For `not_assessable` rows both comparisons and `amount_added` are missing. (6) `tails_fixed` counts rows (household × scenario), not households. (7) The UL tables were read through the online reader of the National Academies Press on 2026-11-12; the places are in `data-raw/SOURCES.md` and are a review point of the handoff. | CLAUDE.md: no interpretation chosen silently. | 10 |
| P80 | low | **The probability approach ignores a requirement whose percentiles tie.** `stats::approx()` collapses tied requirements by their mean percentile; the shipped tables have none. A tie could instead be an error. | Edge case. | v0.2 |
| P81 | low | **`above_ul()` cannot compare a UL given in IU.** `retinol_iu` belongs to `preformed_vitamin_a`, but no scenario adds IU (levels are in mg per kg), so it never appears; a composition column in IU would have to be converted by the adapter. | Units explicit. | v0.2 |

## Open items from task 11 (2026-11-12)

Self-review of `as_hces_design()`, `estimate_prevalence()`,
`estimate_difference()` and `flag_precision()`, as an rOpenSci reviewer
would. Fixed in the task: the confidence level column was named `level`,
which clashed with the column `level` of `hces_vehicle_use` (now
`conf_level`); a helper named `check_reference()` overwrote the check of
the reference tables of the same name (renamed). Choices taken in
implementation:

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P82 | medium | **Choices of task 11 taken in implementation.** (1) The groups of an estimate are the key columns of the result table other than `household_id`. (2) `by` takes domain columns of the households table only; a household with a missing `by` value forms its own cell (`NA`). (3) `n_missing` counts the households of the `by` cell outside the domain: value missing or `domain` not `TRUE`. (4) A probability (`p_inadequate`) is estimated as a proportion by `svyciprop()`; its logit interval comes from a quasi-binomial fit, valid for values between 0 and 1. (5) Errors raised by `survey` (a lonely PSU under `"fail"`) are passed on unclassed. | CLAUDE.md: no interpretation chosen silently. | 11 |
| P83 | medium | **Speed of the estimators.** Each cell (group × domain) updates and subsets the design once; with ENGIH's 8,892 households, 3 scenarios, 7 nutrients, 2 bioavailabilities and 30 provinces this is about 1,000 subsets. If too slow in A3, compute all groups of one domain with one `svyby()` call. | Measured only with the microdata. | A3 |
| P84 | closed (11b.6) | **Classed error for a lonely PSU.** Catch the error of `survey` under `lonely_psu = "fail"` and re-raise it as `hcesfort_error_value` with the strata concerned. | Messages state what failed and how to fix it. | 12 |

## Open items from the design of the v0.1 corrections (2026-11-12)

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P85 | medium | **Gate on vehicle records without grams.** `vehicle_coverage()` counts them (`n_records_no_grams`) and the scenario adds nothing for them; `apply_scenario()` writes a log note (correction 1), but no threshold acts on it. A required `min_records_used` on the vehicle side would mirror the intake gate. | The added amount is understated where the vehicle is bought in units without a conversion. | after A3 |
| P86 | medium | **Replacing a flagged quantity by the food's median.** Tang et al. 2021 (p. 107) replace outlying quantities with the median of the food item over the whole population. A third choice for `apparent_intake(outliers = )` next to P68 (capping at the fence), with the grams changed in the log. The paper does not give the rule that identifies an outlier. | M1 of the review: exclusion sets the food to zero. | before A4 |

## Open items from the implementation of 11b.1 to 11b.7 (2026-11-12)

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P87 | closed (approved 2026-11-12) | **Choices taken in implementation, to confirm.** (1) `ear_bioavailability` is an optional column of `requirements` (absent = not stated); only `cutpoint_valid` is required. (2) The grams share reported by the record-loss gate is read from the `apparent_intake` rows of the log (all minus not included, and used), because `hces_intake` keeps only per-household shares. (3) `vehicle_coverage()` requires `n_members` in `afe` (`hcesfort_error_schema`). (4) A degenerate proportion is handled the same way for every `ci_method`, `"beta"` included. (5) The outlier decision compared by `apply_scenario()` is a string: the `outliers` choice and the rule of the last `flag_outliers()` in the log. (6) The vehicle-side note of correction 1 already existed as `added_understated` (households); no new row was added. | CLAUDE.md: no interpretation chosen silently. | 12 |
| P88 | low | **`check_required()` reads the caller's formals.** It uses `sys.function(-1)`; a wrapper that forwards arguments would be checked against its own formals. A test checks every exported function. | Robustness. | v0.2 |

## Open items from the implementation of 11b.8 to 11b.10 (2026-11-12)

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P89 | closed (approved 2026-11-12) | **Choices taken in implementation, to confirm.** (1) `audit_summary()` gives one row per log row (a step run twice gives two rows, never a sum); the share is taken from the closest earlier `input` row of the same step and table. (2) `audit_record()` refuses a `step` equal to any object of the hcesfort namespace, with or without the `hcesfort::` prefix; `n_households`, `qty_g` and `detail` accept `NA` of any type. (3) The log causes of `flag_energy_plausibility()` were renamed with the arguments (`energy_below_lower`, `energy_above_upper`). (4) `who2009_levels()` boundary rule: the band with the highest lower bound reached, a `>` bound exclusive, so 75 and 149.5 are `75-149` and 300 is `150-300`. WHO 2009 prints `75-149` in Table 1 and "75-150 g/day" in the text; the rule follows the symbols `<` and `>`. (5) `reference_energy()` uses the BMR equation for every age, children included, while `adult_equivalents()` uses the energy table below 18 years; it is meant for an adult reference person. | CLAUDE.md: no interpretation chosen silently. | 12 |
| P90 | closed (decided 2026-11-12, see Decisions) | **Per capita availability: households or persons.** WHO 2009 bands are an "estimated average per capita wheat flour availability", proposed from FAO Food Balance Sheets and household surveys. The design-based mean of `qty_vehicle_g_d_pc` weights households; a per-person average is the ratio of the weighted totals of grams and members (`survey::svyratio`). The two differ when household size and flour use are related. *Recommended:* document both in the vignette and offer the ratio as the default figure for `who2009_levels()`; a methodological choice for Fable. | The band chosen, hence the level, may change. | 12 |

## Open items from the self-review of task 11b (2026-11-12)

Self-review of 11b.1 to 11b.10, as an rOpenSci reviewer would. Fixed in
the task: `who2009_levels()` dropped silently a nutrient and compound whose
lowest band of a user table started above the availability (now
`hcesfort_error_value`); `reference_energy()` checked its numbers through
`get()` (now a plain helper); a missing `n_members` in `afe` had no test.
Coverage 99.5% (`covr::package_coverage()`).

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P91 | medium | **No helper for the per person availability.** The ratio of totals (P90) is computed with `survey::svyratio()` directly, as in the example of `who2009_levels()`; the user must join the vehicle rows to the households and apply the lonely-PSU choice by hand. An `estimate_ratio()` (or `statistic = "ratio"` in `estimate_households()`) would keep domains, groups and the log as for the other estimates. | One way to estimate; nothing silent. | v0.2 |
| P92 | low | **`audit_summary()` is quadratic in the log length.** It looks back for the input row of each reported row; logs have tens to a few hundred rows. | Performance, only for very long chains. | v0.2 |
| P93 | low | **Defensive branches without a test.** Six short error branches (`R/estimate.R`, `R/risk-checks.R`, `R/scenario-log.R`) are not reached by any test; together 0.5% of the code. | Coverage of error paths. | 12 |
| P94 | low | **`who2009_levels()` does not check that the printed band and its bounds agree** (`availability_g_d` against `availability_from_g_d`) in a user table. | Replaced reference tables. | v0.2 |

## Questions for the maintainer

Answered on 2026-11-12: see "Decisions (2026-11-12)" above. Kept for the
numbering. Each question gives the recommended option first.

1. **Acceptance strategy (P1).** Reproduce the original figures first with the
   original choices as explicit options, then correct the defaults and record
   the shift? *Recommended: yes.* It is the only way to tell a porting mistake
   from a deliberate correction. Alternative: regenerate the control figures
   from a corrected original and validate only against those.
2. **Tolerance (P24).** *Recommended: 1e-6 absolute for step 1.* Is there a
   reason to expect larger differences (other package versions, another
   operating system)?
3. **Sec 3A reference period (E4, P3).** Does the ENGIH have a variable that
   says how many days each household kept the diary, or a completeness flag?
   *Recommended if not: 7 days for every household.* With the microdata, the
   distribution of `dias_observados_hogar` and the meaning of day 8 would
   settle how much this matters.
4. **Dozen (E2).** Do you confirm that unit 52 with factor 12 is an error and
   not handled elsewhere? How many records use it? *Recommended: treat as an
   error and fix in step 2 of P1.*
5. **Basis of the fortification levels (E8, P5).** In NORDOM 602 is 10 mg/kg
   retinol or retinyl palmitate? In RTD 616 is 55 mg/kg elemental iron? Can
   you obtain the text of both standards? *Recommended: mark both
   `# SOURCE PENDING` until the text is read; I cannot verify them.*
6. **Home of the ENGIH adapter and the composition tables (P26).** *Recommended:
   inside the package for v0.1, isolated, and split out when Peru is added.*
   Do you know the redistribution terms of the INCAP table and of the
   harmonised workbook you used? Without them the tables cannot be shipped.
7. **Microdata registry and stage-level control figures (P19, P31).** Can you
   record the md5 of the two microdata files and run a short script (I will
   write it) on the original pipeline to export aggregated figures per stage?
   *Recommended: yes, before task 4.*
8. **Households without usable food records (E5, P8).** The 114 households:
   module non-response or true zero? *Recommended: keep them in the design,
   outside the estimation domain, counted in the audit log,* and use the same
   denominator for coverage and risk.
9. **Review track (P22).** *Recommended: aim at rOpenSci statistical software
   review and adopt its annotation workflow from task 1;* CRAN afterwards.
   Decide before the skeleton is built.
10. **Peru.** Which survey and which food modules (the specification says
    "to confirm")? *Recommended: tell me now even though the adapter is v0.2,*
    so the contracts of task 2 are checked against a second questionnaire
    design before they are frozen.
11. **Upstream (P17).** May I draft issues for the original repository with
    the errors that affect published figures? *Recommended: yes, drafted here
    for you to post.*
