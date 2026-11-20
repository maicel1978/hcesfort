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
| P99 | resolved (2026-11-13: confirmed as written, points 1 to 5) | **Choices taken in implementation, to confirm.** (1) A share of exactly 0 or 1 has `se = 0` and **no interval** (`ci_low`, `ci_high` missing), the rule of the degenerate proportions of 11b.6; the design note said "an interval equal to the estimate" while citing that rule. (2) `acquired` is `NA` unless the household is `estimated`, so `estimate_households(value = "acquired")` gives the share among estimated households. (3) `validate_food_groups()` raises `hcesfort_error_key` for a duplicated food and `hcesfort_error_value` for a missing, empty or reserved group (the design's test list said `hcesfort_error_schema` for all), as every other validator. (4) Groups are in the order of first appearance in `food_groups`, `unclassified` last and only when a food of `content` has no group. (5) The rows `unclassified` and `no_nutrient_value` count the used records of estimated households; the log cause for foods of the grouping absent from `content` keeps the design's name `group_not_in_content`. | CLAUDE.md: no interpretation chosen silently. | 12b |
| P100 | low | **`food_group_shares()` calls `svyratio()` once per nutrient, group and domain**, each on an updated copy of the design. On a national survey (8,000 households, 15 groups, 4 nutrients, 10 domains) that is 600 calls; one call per nutrient and domain with every group as numerator would do. | Performance. | v0.2 |
| P101 | low | **No domain argument in `food_group_shares()`** (only `by`); a logical `domain` or `domain_from`, as in `estimate_households()`, would allow shares among, for example, households with plausible energy. | Consistency of the estimators. | v0.2 |

## Open items from task 12b (2026-11-12)

Self-review of 12b as an rOpenSci reviewer would. Fixed in the task:
`estimate_households()` failed on a table keyed by household only (the
energy figure of annex D found it); the Q1 headline named a "greatest"
risk while its interval overlapped the second (it now says the two
cannot be ranked); Q6 named as "not changed" a nutrient the action does
not touch (rows with `se = 0` are now left out); the paired change by
the equity domain (D6) was missing; full article titles typed from
memory in the references were removed (only the details recorded in the
design remain).

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P102 | high | **The template was never rendered with Quarto in this session.** Quarto is not installed here and installing it was refused; the tests knit every chunk with `knitr` on `hces_example` in both languages, and a Quarto test runs (and is skipped otherwise) where Quarto exists. The maintainer should render `report.qmd` once (review point of `docs/handoff.md`) and CI could install Quarto (`quarto-dev/quarto-actions/setup`). | Never claim something works without running it. | 12 |
| P103 | resolved (2026-11-13: points 1, 2 and 4 void, headlines and `equity_domain` removed by reports v2; points 3 and 5 confirmed; point 6 amended: `actions.csv` no longer exists, the column names of `decisions.csv` stay in English in the file and the readiness report prints its headers through `terms.csv`, in the language of the report) | **Choices taken in implementation, to confirm.** (1) Headlines adapt their wording to the intervals (overlap: no ranking; all households reached: a sentence without a figure) and stop only when an assumption fails (reference scenario absent, shares not adding to 1, no action lowering any risk), instead of stopping whenever the example wording does not hold. (2) Q2 headline uses the first domain of `domains` and the nutrient of highest risk; Q3 the same nutrient. (3) Above the UL is read from `above_ul_total` where the diet part is known, else `above_ul_added`. (4) New param `equity_domain` for the paired change by group (D6). (5) The `line_length_linter` is switched off for the two `report.qmd` files (captions and YAML), not for the R files. (6) Column names of `actions.csv` and `decisions.csv` stay in English in both languages; their content is translated. | CLAUDE.md: no interpretation chosen silently. | 12 |
| P104 | low | **Met need and the other thresholds of Aaron et al. 2017 (D9)** are not wired: only `raw_coverage_threshold` draws a line in Q4. | D9 asks to show them when passed. | v0.2 |
| P105 | low | **Annex G asks for the md5 of the input files in prose**; `_results.R` could compute it when the ADAPTER block names files. | Reproducibility. | v0.2 |
| P106 | low | **Labels are codes** (`vitamin_a`, `wheat_flour`, domain names) in headlines and figures; a small label table in the ADAPTER block would print names. | Readability for decision-makers. | 12 |

## Decisions (2026-11-13, reports v2)

The maintainer approved section 11 of `docs/design-reports-v2.md` on
2026-11-13: decisions 1–6 and 8–12 as recommended; decision 7 amended.

| # | Decision |
|---|---|
| R-D1 | Both reports compute the verdict with `readiness_verdict()` from the same `_inputs.R`; no file passes between them. |
| R-D2 | One list `choices` in `_inputs.R`; the YAML keeps `title` and `lang`. |
| R-D3 | Optional column `expenditure_lcu` in `acquisitions` (contract change). |
| R-D4 | `unmatched_foods()` is extended into the work queue and takes `households`. |
| R-D5 | A domain is flagged when the 95% interval of the difference between its unlinked share and that of the rest of the population excludes zero; not adjusted for multiple comparisons, and the note says so. |
| R-D6 | A threshold not met disables the sections that depend on it; no "render anyway" switch. |
| R-D7 | Amended: `actions.csv` is removed, but a scenario may be compared with another scenario through `choices$comparator` (default `"baseline"`); no package contract changes; test K16. |
| R-D8 | The readiness report prints variable, food and unit codes as codes; R2 applies in full to the results report, R3 to both. |
| R-D9 | Methods, bias directions and the STROBE-nut mapping go to a methods vignette in task 12. |
| R-D10 | Names as proposed: `linkage_ladder()`, `estimate_unlinked()`, `readiness_inventory()`, `readiness_checks()`, `readiness_verdict()`, `read_labels()`, `label_codes()`, `read_decisions()`; columns `precision_status`, `expenditure_lcu`. |
| R-D11 | `min_n = 8` in the example, said so in `_inputs.R`. |
| R-D12 | Equity exhibits only for the domains of `equity_domains`. |

P107 is resolved by these decisions. P109 is resolved by R-D7 (the
comparison between two scenarios stays, as a template choice).

## Decisions (2026-11-14, reports v3)

The maintainer approved section 13 of `docs/design-reports-v3.md` on
2026-11-14: all sixteen decisions as recommended, with conditions on 1, 2,
5, 8 and 13.

| # | Decision |
|---|---|
| V-D1 | Tables with `tinytable`, in Suggests and used only by the template, called from one function. Condition: check that a Word export of a rendered report through Quarto keeps the tables readable. |
| V-D2 | Korn-Graubard interval by the formula of C2 on the estimate and variance of `survey`, with the NCHS cap at `n`. Condition: accepted only with its tests against `survey`, `binom.test()` and the published NCHS examples (Parker et al. 2017, pp. 8–9) to the stated tolerance; a golden test. |
| V-D3 | `choices$review = "show"` in the shipped template; `"suppress"` is the other value. |
| V-D4 | Estimators other than proportions (S1): sample size and degrees of freedom only; the interval is always shown. |
| V-D5 | Opening of the results report: figure R0 and a slot for the analyst's findings. Condition: the slot is omitted from the render when the analyst writes nothing; no placeholder text is ever printed (v1 R3). |
| V-D6 | Effect of a scenario: the two panels of 6.3 (levels; paired difference with its interval). |
| V-D7 | `hces_example` is replaced; the present dataset becomes a test fixture. |
| V-D8 | Structure of the example as in 7.1 (3 regions, 6 strata, 200 PSUs of 10 households, five scenarios). Amended: add zinc, which the ENGIH 2018 analysis included, so five nutrients: iron, zinc, folate, vitamin A and energy. Zinc levels and requirements need a verified source, or `# SOURCE PENDING`. |
| V-D9 | Thresholds as the shipped reference table `ref_presentation_standard`, replaceable in `_inputs.R`. |
| V-D10 | DR11: `max_small_cells = 0.5`, cells counted on the households with an estimated intake against the `min_n` of the standard. |
| V-D11 | Unlinked share by domain: the table of a domain variable is printed with all its values when at least one differs. |
| V-D12 | Visible exhibit IDs ("Figure R2.2", "Table D4"). |
| V-D13 | Upper-level sentence with "in the sample", `n` and the upper limit; the sentence names the upper limit as the upper limit of the 95% interval and gives the interval method. |
| V-D14 | P124: page citations corrected in 12d.1, each after reading the scanned page. Done (2026-11-14). |
| V-D15 | Getting-started vignette in 12d.16, in English; its Spanish version with task 12. |
| V-D16 | Names as proposed: `flag_presentation()`, `ref_presentation_standard`, `ci_method = "korn_graubard"`, columns `presentation`, `presentation_reason`, `n_effective`, `ci_width`, `ci_relative_width`, `complement_unreliable`, `short_label`; check `domain_cells`; choices `place`, `survey`, `vehicles`, `review`, `max_small_cells`. |

P125 is resolved by these decisions.

Answers of the maintainer after 12d.10 (2026-11-14), recorded with the
first commit of 12d.11:

| # | Decision |
|---|---|
| V-D17 | P133: households that did not answer the food module form the missing-value cell of the expenditure group, labelled from `terms.csv`. |
| V-D18 | P136: lower the purchase probability of rice, oil and sugar so that exhibit R1.4 has a nonzero estimate, and re-check the calibration test. Not applied in 12d.11: as stated it cannot reach its aim (P140). |
| V-D19 | P138: decimal point and comma as thousands mark in both languages (Dominican usage), from `terms.csv`. |
| V-D20 | P140 (2026-11-14): option (a). About 1% of the households of `hces_example` get a short food list with no staple purchases, so that R1.4 has a small nonzero estimate; the calibration test is re-checked and the golden values are regenerated from the independent script. |
| V-D21 | D9 (2026-11-14): the histogram shows the plausible range used by the readiness checks; households above the upper bound are not drawn but counted in the note ("n households above <bound> kcal, not shown"). Nothing is dropped from the data. |
| V-D22 | Lint warnings in untouched test files (2026-11-14): confirm on CI after the merge, and fix them if CI reports them. CI reported them; fixed in `18be1f1` (exclusion in `.lintr`). |

Answers of the maintainer after 12d.12 (2026-11-14), recorded with the
first commit of 12d.13:

| # | Decision |
|---|---|
| V-D23 | P141: a missing domain value must not look like a suppressed estimate. It carries its own label from `terms.csv` ("Sin dato" / "No data"), as answered in P131; "—" stays reserved for suppressed or undefined estimates. |
| V-D24 | P142: accepted as recommended (a header such as "Domain" / "Dominio", in the wording pass of 12d.14). |
| V-D25 | P143: fixed in 12d.13. Figure axes use the thousands mark of the text, from `terms.csv`, through `scales` (already a dependency of `ggplot2`; no new Imports). |
| V-D26 | P148: accepted as recommended. `energy_action` (`"keep"` or `"exclude"`, no default) in `_inputs.R`; the shipped template sets `"exclude"` and records it, with its reason, in `decisions.csv`; the readiness report states how many households it removes and the results report says so in its population note. The flag stays in the readiness checks; the action lives only in the template choice. Code: Opus, 12d.15. A change to a package function contract stops the work for the maintainer. |
| V-D27 | P144: accepted. R3.1 stays as entered, with a note that cumulative scenarios repeat the vehicles of the previous one. |
| V-D28 | P146: accepted. Cells with n = 0 have their own note line, not the suppression reason (done in 12d.14). |
| V-D29 | 12d.15, open question 1 (2026-11-15): accepted as recommended. The population sentence stays at the start of the technical note, outside the analyst's findings slot. |
| V-D30 | 12d.15, open question 2 (2026-11-15): accepted as recommended. `energy_action` applies to every result, coverage included, so the results report speaks of one population with one n. The readiness report keeps all households and states how many the results report excludes. |
| V-D20, applied | 12d.13: the households with a short food list are drawn from a random stream of their own and their other records are removed after the defects are planted, so every other household keeps its records. A first attempt that drew them from the main stream moved the planted ×10 quantity onto wheat flour, and one household then passed the iron upper level (the calibration test failed). 26 households of `hces_example` acquire no vehicle. |

## Open items from the design of the reports v2 (2026-11-13)

Design `docs/design-reports-v2.md` (task 12c.0), from the approved
`docs/report-requirements-v1.md`. Its twelve decisions (section 11) await
the maintainer; they are recorded here once answered.

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P107 | resolved | **Approve the twelve decisions of section 11 of the design**, among them three that change a contract or an exported interface: the optional column `expenditure_lcu` (decision 3), `unmatched_foods()` taking `households` (decision 4) and eight new exported functions (decision 10). | Implementation cannot start without them. | 12c |
| P108 | medium | **The contrast of `estimate_unlinked()` (a domain against the rest of the population) is internal.** The public contrast between two domains with its interval (G3: coverage ratio, gap between quintiles) can be built on it. | G3 of `docs/design-report-template.md` stays open. | v0.2 |
| P109 | resolved (R-D7) | **Comparisons between two scenarios are removed from the report** (every scenario is compared with the unfortified baseline; `actions.csv` goes). A country may need "proposed against current". | Decision 7 of the design; R9 and R10f. | v0.2 |
| P110 | medium | **Methods vignette**: methods, the direction of each bias and the STROBE-nut mapping of the old annex H, which leave the results report (R12). | Decision 9 of the design. | 12 |
| P111 | low | **Each report runs the whole chain.** A cache shared by the two reports would halve the time on a national survey. | Performance. | v0.2 |

Resolved by the design: P106 (labels instead of codes: section 4). Moved:
P102 (Quarto in CI) to step 12c.13. P103 loses its points on headlines,
which no longer exist (R4).

## Open items from the implementation of 12c.1 to 12c.8 (2026-11-13)

Self-review of steps 12c.1 to 12c.8 (Opus). Coverage of the new files:
100% except `R/estimate-unlinked-helpers.R` (98.5%).

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P112 | resolved (2026-11-13) | **A record with a missing `expenditure_lcu` counts in neither the numerator nor the denominator of the expenditure shares** (`linkage_ladder()`, `unmatched_foods()`, `estimate_unlinked()`); it is documented but not counted anywhere. The ladder could add `n_no_expenditure`, or the readiness report could print the count in the table note. | Nothing silent. Accepted as recommended: the note of the ladder table of the readiness report gives the number of records without `expenditure_lcu`. | 12c.9 |
| P113 | resolved (2026-11-13) | **`precision_status` is `NA` for a missing estimate with `n >= min_n`** (a zero total, for instance). The design lists four statuses and does not cover it; `NA` was chosen so that no missing estimate reads as `ok`. | Accepted as recommended: `precision_status` stays `NA` and the report prints "—". | 12c.9 |
| P114 | low | **`linkage_ladder()`, `unmatched_foods()` and the readiness functions return plain tibbles**: a change in the number of rows of `x` made outside the package is not recorded, as it is by the estimators (`audit_check_rows()`). | Consistency of the audit log. | v0.2 |
| P115 | low | **`readiness_verdict()` treats a domain absent from the inventory as absent from `households`** (`missing_input`). The template passes the same `domains` to both functions, so this only matters for direct use. | Clearer error for direct use. | v0.2 |

## Open items from step 12c.9 (2026-11-13)

Self-review of the shared template files and the English readiness
report (Opus).

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P116 | done (12c.13: `NA` for `se`, `ci_low` and `ci_high`; audit row `undefined_quantile_interval`) | **`estimate_households(statistic = "median")` returns `se = NaN` and `ci_high = NaN` for a cell where the quantile interval is undefined** (region `north` of `hces_example`, energy per AFE), without a log row. The report prints "—" for that interval. The estimator could return `NA` and count the cell in the audit log. | Nothing silent. | 12c.13 |
| P117 | resolved (2026-11-13: points 1 to 6 accepted; on point 3, the readiness report is a diagnostic and the flag of DR5 already rests on the interval of the difference, so `n` is shown without suppression) | **Choices taken in implementation of 12c.9, to confirm.** (1) The reference person and the unit conversion are functions in `_inputs.R` (`make_afe()`, `make_grams()`), called by `_chain.R` only when every essential input is present, so a survey that fails its contract still gets its inventory. (2) `choices$energy` must name a registry nutrient in kcal, since it is compared with the energy of the reference person; otherwise the render stops with `hcesfort_error_argument`. (3) The unlinked share by domain (DR5) is shown with its `n`, without suppressing small cells: R7 is a rule of the results report. (4) The coverage curve of the work queue draws grams and expenditure (the measures of the stopping rule), not records. (5) An absent essential input prints the inventory and one sentence, without the verdict. (6) Intervals are printed as "[low, high]" in one column; the registry `tables` keeps the two limits as numbers. | CLAUDE.md: no interpretation chosen silently. | 12c.10 |
| P118 | low | **`object_usage_linter` is off for `inst/report/_tables.R`, `_readiness.R`, `_figures.R` and `_results.R`**: they are scripts sourced into the environment of a report and use objects of the other scripts. | Lint clean without false positives. | — |

## Open items from step 12c.10 (2026-11-13)

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P119 | resolved (2026-11-13: points 1, 2, 3 and 5 accepted; on point 4, `ok` is "adecuada", read as "precisión adecuada"; the decimal point is the usage of the Dominican Republic) | **Translation choices of the Spanish readiness report, to confirm.** (1) Adult female equivalent is "equivalente de mujer adulta (EMA)", as in the Spanish results report. (2) Units: `ug_dfe` is "µg EFD"; `ug_rae` stays "µg RAE", since "EAR" would clash with the estimated average requirement. (3) Numbers keep the decimal point and intervals "[low, high]", as in English. (4) `precision_status` `ok` is "correcto". (5) The YAML header sets `lang: es`, so Quarto prints its own labels (table of contents) in Spanish. | CLAUDE.md: no interpretation chosen silently. | 12c.12 |

## Open items from the self-review of task 12c (2026-11-13)

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P121 | low | **The code of `readiness.qmd` and `results.qmd` is written twice, once per language.** A test now compares the tokens of the chunks of both languages (strings other than codes, comments and commas left out), so a change made in one language only fails. Inline expressions (`` `r ...` ``) of `readiness.qmd` are not compared. Alternative: one report per kind, with every sentence in `terms.csv`; heavier for the analyst who edits the text. | Duplication; the test makes it safe for now. | v0.2 |
| P122 | low | **The 8-household fixture of `test-estimate.R` gives an undefined median interval at levels 0.9 and 0.95**; the median tests against `survey` run at level 0.5. A fixture with more PSUs would test the median at the usual level. | Tests at the level users choose. | 11 (revisit) |
| P123 | medium | **K15 (Quarto render of both reports in both languages) has not run yet**: Quarto could not be installed in the session's container. The first run of the R-CMD-check workflow on the ubuntu release runner (on `main` or a pull request) is its verification. | Never claim it works without running it. | 12c.13 (CI) |

## Open items from the design of the reports v3 (2026-11-14)

Design: `docs/design-reports-v3.md` (task 12d.0). Its sixteen decisions
(section 13) wait for the maintainer.

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P124 | resolved (2026-11-14, 12d.1: every IOM page citation in `data-raw/` re-read on the scanned page and corrected, also those of IOM 2000 and 2011; the table of changes is in `data-raw/SOURCES.md`) | **Page citations of the IOM reports in `data-raw/requirements.csv` and `data-raw/SOURCES.md` are one page too high.** Read on the scanned pages: the vitamin A UL for women 19–50 years is on p. 142 (cited 143) and "applies to chronic intake of preformed vitamin A from food, fortified food, and/or supplements" on p. 126 (cited 127). By the page anchors of the online text the same shift affects the vitamin A EAR (116 → 115), the iron EAR (345 → 344) and UL (376 → 375), the zinc EAR (476 → 475) and UL (487 → 486), the folate EAR (229 → 228) and the 18% iron absorption (316–317 → 315). No value changes. Re-read each citation on the scanned page (`https://nap.nationalacademies.org/books/<id>/gif/<page>.gif`), correct it, update the md5. | Peer-review standard (P6): a wrong page is a wrong citation. | 12d.1 |
| P125 | resolved (2026-11-14: section "Decisions (2026-11-14, reports v3)") | **Approve the sixteen decisions of section 13 of the design.** They change contracts or exported interfaces: `ref_presentation_standard`, `ci_method = "korn_graubard"` and the column `ci_method`, `flag_presentation()`, `short_label` in the label table, `needed_by` and `domain_cells` in the readiness functions, and the replacement of `hces_example`. | Implementation cannot start without them. | 12d |
| P126 | resolved (2026-11-15: the setup script of `hcesfort` installs `tinytable` and Quarto 1.11.9 from PyPI, without blocking startup if pip fails; unproven until a fresh container is built) (2026-11-14: the setup script of the `hcesfort` environment already installs `ggplot2`; only `tinytable` is missing, needed from 12d.10; installed by hand in the session of 12d.1–12d.2; maintainer, 2026-11-14: the environment script is not edited for now, each session is opened with "Al empezar, instala tinytable si falta"; close when the script is edited) | **The setup script of the cloud environment does not install `ggplot2`**, so in a fresh container the knit tests of the report template are skipped and nobody sees it. `tinytable` (if decision 1 is approved) has the same problem. Quarto is not installed either (K15 runs in CI only). | Never claim it works without running it. | 12d.1 |
| P127 | medium | **Time of the knit tests on the realistic example.** One knit of the results report takes about 8 s on 2,000 households; the tests knit many variants. Tests that only check structure can run on a subsample appended to `_inputs.R` (a few PSUs per stratum); snapshot tests need the full example. Budget: the test suite under 5 minutes in CI. | Test time. | 12d.15 |
| P128 | resolved (12d.3: documented in `?estimate_households`) | **`ci_method = "beta"` of `estimate_households()` stays the uncapped interval of `survey::svyciprop()`**, beside the new `"korn_graubard"`. Its documentation should say how the two differ (the cap at the sample size; the interval of a 0 or 1 proportion). | Two near-identical options need a clear difference. | 12d.3 |
| P129 | low | **Food-group shares, unlinked shares and medians have no published presentation thresholds** (departure S1 of the design). NCHS published standards for rates and counts after 2017; a later version could look for a published rule for ratios and quantiles. | P6: no invented thresholds where a standard exists. | v0.2 |
| P130 | resolved (2026-11-14: accepted by the maintainer) | **Choices of `flag_presentation()` to confirm** (12d.4): (1) a missing estimate with `n` at least `min_n` has no status (`NA`, logged as `presentation_undefined`); (2) the invariant of section 3.4 is tested as "a stricter standard never moves a status towards present", since lowering a `min_*` threshold can present more; (3) comparisons with the thresholds are exact, without tolerance. Recommended: keep all three. **Accepted by the maintainer (2026-11-14), all three as recommended.** | CLAUDE.md: no interpretation chosen silently. | 12d.4 |
| P131 | resolved (2026-11-14: accepted as recommended, (b); in the reports that cell carries the label of a missing value from `terms.csv`, never `NA`) | **A missing value of a domain in `domain_cells`** (12d.6, C5). Implemented: the missing value is one more value of the domain (one more cell), as in `estimate_households()`, whose `by` cells include a missing value as a level (checked in the session: `by_cells()` on the example with 3 households of `region` set to `NA` gives the cells north, south and `NA`). Alternatives: (a) leave those households out of every cell (the inventory already gives `share_missing` of the domain); (c) stop with an error. *Recommended: keep (b)*, so the readiness check counts the same cells the results report estimates. | CLAUDE.md: no interpretation chosen silently. | 12d.6 |
| P132 | resolved (12d.6: the version of `R/outliers.R` is renamed `group_index()`; the estimators use the string key of `R/design.R`; test of `by_cells()` with mixed-case and missing values; golden values unchanged) | **Two internal functions named `group_id()`** (`R/design.R` and `R/outliers.R`). The second one wins by collation order: it returns `dplyr::group_indices()` (groups sorted in the C locale), not the string key that the comment in `R/design.R` describes. `by_cells()` matches these indices against `levels` sorted by base `order()`, which follows the session's collation locale; in a locale where it differs from C (e.g. `es_ES.UTF-8`, with mixed-case domain values) the masks could be paired with the wrong labels. Not reproduced here: this container has only C locales, where both orders agree. Fix: one `group_id()` returning the string key (the `R/design.R` version), and a test with mixed-case values under `withr::local_collate()`. | Found in 12d.6 while checking how `estimate_households()` treats a missing domain value. | next Opus step (before 12d.7) |
| P133 | resolved (2026-11-14: accepted as recommended, V-D17) | **Expenditure quintile of households that did not answer the food module** (12d.8). Implemented: `expenditure_group` is missing for the 31 non-respondents, because the quintiles are of food expenditure (section 7.1) and theirs is unknown; by P131 they form one more cell of the domain, with no estimated intake. Alternatives: (a) a quintile from a separate total-expenditure variable known for every household, as real surveys usually have; (b) leave them in the lowest quintile. *Recommended: keep*, the honest reading of section 7.1, and it exercises the missing-value label of P131 in the reports. | CLAUDE.md: no interpretation chosen silently. | 12d.8 |
| P134 | low | **`wheat_flour` is both a vehicle and a vehicle group in `hces_example`** (12d.8). `vehicle_coverage()` keeps them apart by `level`, the labels by `type`, and the tests pass; a reader of `use$vehicle == "wheat_flour"` gets both rows. A vehicle code such as `wheat_flour_bag` would remove the ambiguity. *Recommended: keep*, as a realistic case the package already handles, and say so in the data documentation. | Clarity of the example. | 12d.16 |
| P135 | medium | **Test time after the realistic example** (12d.8). `devtools::check()` went from 4.3 to 6.5 minutes; the knit tests and the calibration test run the chain on 2,000 households. See P127. | Test time. | 12d.15 |
| P136 | accepted (V-D18), not applied: see P140 | **No household of `hces_example` acquires no vehicle** (12d.10). Rice, oil and sugar each reach 95% or more of households, so exhibit R1.4 prints only its zero-event sentence. Lowering `p_acquire` of those foods in `example_foods.csv` would give R1.4 a figure; the zero path stays exercised by the upper-level zeros. *Recommended:* lower them slightly in 12d.11 and re-check the calibration test. | The example should show every exhibit. | 12d.11 |
| P137 | done (12d.15: `test-report-registry.R` checks titles, builders, appendix and the exhibits called and printed) | **The registry names builders that do not exist yet** (12d.10). `exhibits.csv` lists the 26 builders of sections 4.1 and 6.1; the reports still use `show_legacy()` until 12d.11 to 12d.13 write the builders. The registry test of Q2 (12d.15) must check that every builder exists and every exhibit is shown or disabled. | Q2. | 12d.11–12d.15 |
| P138 | resolved (2026-11-14: accepted as recommended, V-D19) | **Thousands mark of the Spanish report** (12d.10). `terms.csv` sets `format,,big_mark` to "," in both languages ("n = 1,962"); the Spanish style guides recommend a space and some countries use a point. It is one line of `terms.csv`, editable per report. *Recommended:* keep "," in the shipped template, as the decimal mark stays "." (R's default), and say so in the getting-started vignette. | Maintainer's choice of style. | 12d.12 |
| P139 | low | **Long zero-event sentences** (12d.10). One sentence lists every zero cell of an exhibit (for the upper level, every nutrient and scenario). Section 6.4 replaces it for R3.3 by one sentence naming the nutrients; other exhibits rarely have more than a few zero cells. | Readability. | 12d.13 |
| P140 | resolved (2026-11-14: option (a), V-D20) | **P136 cannot be met by lowering rice, oil and sugar slightly** (12d.11). `hces_example` has eight vehicle foods (rice, wheat flour, bread, pasta, maize flour, biscuit, oil, sugar); every one of the 1,969 households with food records acquires at least two of them, and the product of the probabilities of not acquiring each one, ignoring the wealth and PSU effects, is about 1 in 700,000 (checked on the shipped data: no household acquires fewer than two). Lowering rice, oil and sugar to 0.85 raises it only to about 1 in 70,000, so R1.4 keeps printing only its zero-event sentence. Options: (a) *recommended:* add to the generating script a small group of households (about 1%) with a short food list (no staples bought: e.g. households that eat out or receive food baskets), drawn before the food loop, so that R1.4 has a small, realistic nonzero estimate; calibration test re-checked; (b) lower the probabilities of all eight vehicle foods strongly, which distorts the coverage figures of R1.1; (c) keep the example as it is and let R1.4 show its zero-event path (P139). | V-D18. | 12d.13 |

## Open items from step 12d.12 (2026-11-15)

Reading of the rendered Spanish readiness report against section 8 of
`docs/design-reports-v3.md`. Settled in 12d.12: "vincular" throughout
("Escalera de vinculación", "proporción vinculada / no vinculada"), no
longer "enlace" or "enlazada"; "resto de los hogares" (en "other
households") instead of "resto de la población"; "Riesgo de ingesta
aparente inadecuada" (en "Risk of inadequate apparent intake"); "rango
plausible" instead of "intervalo plausible" (an interval is a CI); lists
end in "y" / "and"; the note of D8 says "sin ajuste por comparaciones
múltiples".

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P141 | accepted (V-D23) | **A missing domain value is printed "—" in D8** (12d.12). Households without an expenditure quintile (31 in `hces_example`) form a row whose label is "—", the same mark as a suppressed estimate. *Recommended:* label it with a term ("sin dato" / "missing") in the domain column. | One mark, one meaning (R17). | 12d.13 |
| P142 | resolved (12d.13: R1.4 is by domain only, the national row and the header `population` are gone) | **"Population" names households in the results report** (12d.12). The header `population` ("Population" / "Población") heads the label column of R1.4, whose only value is "National"; section 8 does not use "population" for households. *Recommended:* a header such as "Domain" / "Dominio", in the wording pass. | Section 8. | 12d.14 |
| P143 | accepted (V-D25) | **Axis labels of the figures have no thousands mark** (12d.12). D9 prints "2000" on the axis and "2,000" in its sentence. *Recommended:* `scales::label_number(big.mark = term("big_mark", "format"))` on numeric axes in `_figures.R` (`scales` comes with `ggplot2`). | One number format per report (V-D19). | 12d.13 |

## Open items from 12d.13 (2026-11-15)

Self-review of the results report v3, done as an rOpenSci reviewer
would. Fixed in the task: the zero line of R3.4 was drawn only in its
first band; a figure of one row was cut (minimum height); `n` in the
zero-event sentences had no thousands mark; "vitamin a" in notes
(`lower_first()` instead of `tolower()`); the shares above the UL print
two decimals, as a share of 0.03% printed "0.0". The rest:

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P144 | accepted (V-D27); the note is added in 12d.14 | **Table R3.1 repeats the rows of cumulative scenarios.** The five scenarios of `hces_example` each restate the vehicles of the one before, so the table has 60 rows, 45 of them repeated. *Recommended:* keep one row per scenario, vehicle and nutrient (the scenarios table as entered, which is what the analyst checks), and add to the note that a scenario lists every vehicle it fortifies. Alternative: print, for each scenario, only the rows that differ from the scenario it is compared with. | Legibility of the one table of the body. | maintainer |
| P145 | resolved (12d.14: lower case after "by", R3.4 as "of {nutrient}, by {domain}") | **Titles of repeated exhibits.** The instance is printed as its label in mid-sentence: "by Region", "…by domain value, Iron, Expenditure quintile". *Recommended:* `lower_first()` on domain labels inside titles, and the title of R3.4 as "Effect of each scenario on inadequate apparent intake of {nutrient}, by {domain}". | Wording (R24). | 12d.14 |
| P146 | resolved (12d.14, V-D28) | **Cells with no household.** Households that did not answer the food module have no expenditure quintile and no intake, so R2.2, R3.4 and R1.4 by expenditure quintile print a row "No data", n = 0, "—", with the note "fewer households than the minimum". The row is honest but reads as a small cell. *Recommended:* keep the row (nothing silent) and give cells with n = 0 their own note line ("No data: no household with an estimate"), instead of the suppression reason. | One mark, one meaning (R17). | 12d.14 |
| P147 | resolved (12d.14: `ul_scope`, `ul_bias` removed) | **Terms no longer used.** `ul_scope`, `ul_bias` and the headers `ul_compared`, `ul_bias` were used only by the v2 table of the upper level, now replaced by the statements of R3.3. *Recommended:* remove them from `terms.csv` and from the vocabulary test (U10) in the wording pass. | Dead vocabulary. | 12d.14 |
| P148 | done (12d.15: `choices$energy_action` checked in `_chain.R`, which now computes the energy flag for both reports; "exclude" leaves the flagged households out of every per-household table of the results with an audit row, so they stay in the design outside each domain; sentence at the head of the technical note, note under D9, row in `decisions.csv`; shipped as "exclude" per V-D26) | **The results use households with implausible energy.** The readiness report flags apparent energy outside the plausible range (D9), but nothing acts on the flag: R3.3 shows iron above the UL in 0.2% of households, all of them households outside the plausible energy range (the calibration test, which leaves those out, finds none above the iron UL). CLAUDE.md: "detect, then decide", with no hidden default. *Recommended:* a choice `energy_action` in `_inputs.R` (`"keep"` or `"exclude"`, no default), recorded in `decisions.csv`, applied once in `_chain.R` before the results and counted in the notes; the template ships `"keep"` with the reason. Changes the choices of the template, so it needs the maintainer. | Method; an implausible household can drive an upper-level estimate. | maintainer |
| P149 | low | **Left panel of R3.2 and R3.4 on a free axis.** Section 5.5 asks for percentages on a 0-100 axis; the dumbbell panel uses the range of its points, so that small changes stay visible. *Recommended:* keep the free axis and say so in section 5.5 of the design. | Design text against implementation. | 12d.16 |

## Open items from step 12c.11 (2026-11-13)

| Id | Priority | Proposal | Why | Task |
|---|---|---|---|---|
| P120 | resolved (2026-11-13: points 1 to 9 accepted; on point 5 the sentence says why there is no interval: "No variation in the sample, so no interval: <cells> = <value>"; in Spanish "Sin variación en la muestra, por lo que no hay intervalo: <celdas> = <valor>") | **Choices taken in implementation of the results report, to confirm.** (1) The effects (3.2) are one table per nutrient, each followed by its dumbbell (3.3), so that every figure has its table (K5). (2) Exhibit 1.3 (quantity) is gated by the verdict section `quantity` and shows vehicles, not groups. (3) By-domain exhibits exist only where section 7 of the design lists them: households without any vehicle (1.4), risk (2.2) and equity (3.5); none for quantity or food groups. (4) The upper level (3.4) is two tables: one row per nutrient with the intake compared and the direction of its bias (wording taken from the documentation of `above_ul()`), then the share above the UL for every scenario, the baseline included. (5) Exact estimates leave the table for one sentence, "Same value in every household, without interval: <cells> = <value>", also in the iron sensitivity table; food-group shares keep their exact zeros in the table (R11). (6) A wide interval is named in a "Precision" column and drawn hollow; a small cell keeps its row with "—" and leaves the figure. (7) The EAR and UL table prints the `source` of the requirements table as it is, a citation, not through `labels.csv`. (8) A domain disabled by the verdict prints its sentence once in each section. (9) If an essential input is absent, the results report prints one sentence pointing to the readiness report. | CLAUDE.md: no interpretation chosen silently. | 12c.12 |

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
| P57 | medium | **Energy for pregnancy and lactation.** FAO/WHO/UNU 2004 gives additions per trimester and for lactation; they enter `ref_energy_requirements` and `adult_equivalents()` once read in the document, with an explicit option. | Decision 4 of task 5 leaves them out in v0.1. | 12e.5.2 if decision 3 of `docs/design-12e5.md` is approved; else v0.2. **Done 2026-11-16**: `pregnancy_kcal`, `lactation_kcal`, the rule against charging milk twice, `ref_energy_additions` (seven values re-read in sections 6.3 and 7.2). |
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
| P69 | high | **All-or-nothing compliance model.** A share `compliance` of each vehicle carries the full level and the rest none; the household result is a probability (with one vehicle, `c × indicator(full) + (1 − c) × indicator(baseline)`; with several, over the combinations of vehicles, assumed independent). v0.1 implements the average-content model only, named by a required argument. | The two models give the same mean and different shares below the EAR and above the UL; average content understates the share above the UL when few households are near it. | moved before A4 (R2-D4, 2026-11-15); design: `docs/design-12e5.md`, section 4; 12e.5.6, 12e.5.7 |
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

## Open items from the self-review of 12d.16 (2026-11-15)

| # | Status | Item | Priority | Task |
|---|---|---|---|---|
| P152 | open | The chain of the vignette repeats that of `tests/testthat/test-golden-example.R` and of `inst/report/_chain.R`. A single exported wrapper would remove the duplication, but it changes the public interface: needs a design (Fable). | medium | 13 |
| P153 | open | `docs/feedback/` has no round yet; the test passes with none. The first round should come from the maintainer's expert comments. | low | after Q4 |
| P154 | open | The vignette has no Spanish version (planned with task 12). | low | 12 |

## Open items from the review v0.2 (2026-11-15)

Findings of `docs/review-v0.2.md` (Fable; brief
`docs/review-v0.2-brief.md`). Evidence, sources and the proposed fix of
each are there, under the finding number given. Step 12e of the roadmap
was approved on 2026-11-15 (section "Decisions (2026-11-15, review v0.2)"
below). M2 and M3 of the v0.1 review had never been entered here; they are
P158 and P171.

| Id | Priority | Finding | Item | Task |
|---|---|---|---|---|
| P155 | high (blocker) | 1 | **A carrier with a repeated key is accepted and changes the estimates silently** (mean iron 10.45 to 19,644.6 with 50 households twice; `n` unchanged, no log row). `require_hces()` must check the key; the estimators must call `audit_check_rows()`. | 12e.1, before A2 |
| P156 | high | 2 | **`estimate_households()` accepts any number as a proportion** (the default statistic): unclassed error of `survey`, or an estimate of 7.08 labelled a proportion, or a negative effective sample size. Range check, `hcesfort_error_value`. | 12e.1 |
| P157 | high | 3 | **The limits of the method are written nowhere a user reads.** The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73, 81, 99; IOM 2001, p. 703); the package applies them to acquisitions over `period_days`. Correction 9 of the v0.1 review (H5, H7) was never done. Help pages, README, vignette, one audit note. | 12e.3, before the first expert round; P110 stays in 12. **Done 2026-11-15** (a, b): the section "What the figures are and are not" in `?inadequacy` (the four quotations), `?above_ul`, the README and the vignette (section 5); the note `apparent_intake_not_usual_intake` of `inadequacy()` and `above_ul()`, with the range of `period_days` of the records used (new note `period_days` of `apparent_intake()`). (c), the sensitivity by number of days as a domain, is P182; the statement in the reports is P183. |
| P158 | medium (was high; reworded 2026-11-15 by `docs/design-12e5.md`, section 1.1) | 4 | **The rule for infants in the AFE is an unwritten assumption.** Finding 4 overstated it: a breastfed infant eats none of the food recorded, but its mother eats for it (FAO/WHO/UNU 2004, section 7.2: 505 to 675 kcal per day in the first six months), so today's AFE of a woman with an infant (1.24) is inside the range of the source (1.22 to 1.29); removing the infant without adding lactation would understate the AFE by about 0.24. Arguments without default `infant_food_share` and `milk_energy_cost`; P57 (`pregnancy_kcal`, `lactation_kcal`) with them. M2 of the v0.1 review. | 12e.5.1, 12e.5.2 (after approval of the design). **12e.5.1 done 2026-11-16**: both arguments, the table form, the log rows `infant_energy` and `breast_milk_energy_not_counted` (the condition on lactation energy enters with `lactation_kcal` in 12e.5.2); every call of the package gains `infant_food_share = 1`. |
| P159 | high | 5 | **Every gram of a vehicle is fortified whatever its origin**; `origin` is in the contract and no function reads it. WHO 2009, p. 1, defines the levels on "fortifiable" flour of industrial roller mills. A logical column `fortifiable` set by the adapter. Contract change. | design: `docs/design-12e5.md`, section 2; 12e.5.3, 12e.5.4. **12e.5.3 done 2026-11-16**: the column in the contract, the argument and three columns of `vehicle_coverage()`, its log; `apply_scenario()` still reads `qty_vehicle_g_d` until 12e.5.4. **12e.5.4 done 2026-11-16**: scenarios on the fortifiable grams, `fortifiable_share` note, `fortifiable` in `hces_example` and the optional fixture, golden values regenerated (figures in `NEWS.md`). The coverage exhibit with both coverages is 12e.5.8. |
| P160 | high | 6 | **Nine of thirteen core estimators have expected values only from AI-written arithmetic.** Anchors verified on 2026-11-15, ready to become tests: the FAO examples under Table 5.1, IOM 2001 Table I-7, the conservation identity, `svycontrast()`, a ratio on the full design, `svyciprop(method = "logit")`, `surveytable::svyciprop_adjusted()`. | 12e.2, before A3. **Done 2026-11-15** (`test-anchors.R`): FAO examples (1%), Table I-7 (0.01 at the middle of each band, both tails), conservation, `svycontrast()`, `svyratio()` on the full design, `svyciprop(method = "logit")`. `surveytable` left out: it is not a dependency and the published NCHS rows already anchor the interval (`helper-nchs.R`). |
| P161 | high | 7 | **The README says the package has no functions** (H5 of the v0.1 review, open); version `0.0.0.9000`. | 12e.3. **Done 2026-11-15**: status paragraph, the chain on `hces_example` (run), the limits, the statement on AI tools (R2-D7). The version `0.1.0` waits for task 12. |
| P162 | high | 8 | **The coverage gate counts grams, not the nutrient**: with the only source of a nutrient lacking a value the gate passes at 0.976 and every household is inadequate. List the foods without a value in the log; say what the gate misses; a readiness check by food. Related to P96. | design: `docs/design-12e5.md`, section 3; 12e.5.5. **Done 2026-11-16**: `missing_values()`; log row `foods_without_value` in `apparent_intake()`; the `coverage` note and the error of the gate name `missing_values()`; readiness Table D3.1 (after D3, numbered so that D4 to D10 keep their ids). |
| P163 | high | 9 | **Under average-content compliance below 1 the share above the upper level is understated and nothing says so**: on `hces_example`, folic acid, 0.59% as shipped against 19.68% at compliance 1. H7.3 of the v0.1 review, open. A flagged audit row, the sentence in two help pages, the figure at compliance 1 as a bound. P69 (all-or-nothing) to move before A4 (question 4). | 12e.3; P69 in 12e.5.6, 12e.5.7. **Done 2026-11-15**: flagged row `average_content_understates_ul` of `above_ul()`, one per scenario with a compliance below 1 under average content (the note `compliance_below_one` of `apply_scenario()` now lists the scenarios); the sentence in `?above_ul` and `?apply_scenario`; the vignette shows both figures (0.59% and 19.7%); the results report adds the note `ul_average_content` under the upper-level exhibit. The exhibit with both models is P179. |
| P164 | medium | 10 | **The presentation standard is not conservative for a mean of probabilities**: `p(1 - p) / se²` overstates the effective sample size (127.8 against 9.0 in the example of the review); departure S2 of the report and `?flag_presentation` say the opposite. | 12e.3 (sentences), 12e.4 or v0.2 (effective size). **Sentences done 2026-11-15** (`?flag_presentation`, departure S2 in English and Spanish): the width criteria are conservative, the effective-size criterion is in effect not applied. The effective size from the variable's own variance stays in 12e.4 (R2-D6). **Effective size done 2026-11-16 (12e.4, R2-D6)**: `n_effective` of `estimate_households()`, `n` over the design effect from the variance of the values; `flag_presentation()` uses it; departure S2 rewritten (en, es). |
| P165 | medium | 11 | **An interval of width zero is presented as certainty** by `estimate_difference()` and by a mean or median without variation (0, 0, 0, 0, `present`). Apply the rule of the degenerate proportion. | 12e.4 **Done 2026-11-16**: `no_variation` (value, `se = 0`, no interval, log row) for every statistic; column `interval_note`. |
| P166 | medium | 12 | **`df = 0`: `NaN` limits and base warnings; `precision_status = "exact"` when `se == 0` comes from `lonely_psu = "certainty"` or `"remove"`.** Missing limits, a log row; `exact` decided on the values. | 12e.4 **Done 2026-11-16**: `df <= 0` gives no interval, no warning, log row `no_degrees_of_freedom`; `exact` of `flag_precision()` read from `interval_note`. |
| P167 | low | 13 | **`options(survey.adjust.domain.lonely)` changes the standard errors** (0.13440 to 0.13627): `with_lonely_psu()` sets one option of two. | 12e.4 **Done 2026-11-16**: `with_lonely_psu()` fixes `survey.adjust.domain.lonely = FALSE`; note `adjust_domain_lonely`. |
| P168 | low | 14 | **Impossible or inconsistent values accepted by the validators**: `level_mg_kg` above 1e6; a mass above 100 g per 100 g; `age_months` that contradicts `age_years` (silently the annual mean); a PSU code in two strata under `nest = TRUE`. | 12e.4 **Done 2026-11-16**: `level_mg_kg` in [0, 1e6]; mass columns at most 100 g per 100 g (g, mg, ug); `age_months` against `age_years` (`hcesfort_error_value`); note `psu_in_several_strata` in the estimators. Energy per 100 g has no bound (no identity; a physical bound would need a source). |
| P169 | medium | 15 | **The golden chain does not reach `household_share`, `yield_factor`, `age_months`, `meals_home_share`, member `weight_kg`.** Add them to `hces_fixture()` and to the golden script. | 12e.2. **Done 2026-11-15**: `hces_fixture(optional = TRUE)` (same households, the five columns and a single-PSU stratum), `golden-optional.csv`; the plain fixture is unchanged so the hand values of the unit tests stand. |
| P170 | low | 16 | **The tail rule of the iron probability is the source's own** (IOM 2001, Table I-7, p. 703, footnote d); the help calls it a convention without source. P74 can cite the page. | 12e.3. **Done 2026-11-15**: the quotation of footnote d in `?inadequacy` and in `data-raw/SOURCES.md` (new section of task 12e.3). |
| P171 | low | 17 | **Households without an estimate leave the domain as if missing at random**; `n_missing` is unweighted. M3 of the v0.1 review. | v0.2 |
| P172 | low | 18 | **A household with only zero quantities is `estimated` with intake 0** and `p_inadequate = 1`, without a log row. | 12e.4 **Done 2026-11-16**: flagged row `zero_intake` of `apparent_intake()`; the status stays `estimated`. |
| P173 | low | 19 | **The probability approach on intake per AFE is the package's own extension to HCES**; say so in `?inadequacy` and the methods vignette. | 12 |
| P174 | medium | section 6 | **Five mutations survive**: the reference scenario of `estimate_difference()` with a second grouping key (no test has one), `n_missing` with `by`, a member of exactly one year, the coverage of two forms in `above_ul()`, `NaN` against `NA` in a coverage. The code is right in the five; five tests. | 12e.2. **Done 2026-11-15**: one test each in `test-estimate.R` (S1, S2), `test-adult-equivalents.R` (S3), `test-above-ul.R` (S4), `test-apparent-intake.R` (S5); each mutation re-applied and killed. |
| P175 | low | section 7 | **Before a submission:** the JOSS criteria and the rOpenSci scope policy were not reachable (`# SOURCE PENDING`); a pre-submission enquiry to rOpenSci; a statement on AI assistance; a statement of need against existing software. | 12, v1.0 |

## Decisions (2026-11-15, review v0.2)

The maintainer's answers to the nine questions of section 10 of
`docs/review-v0.2.md`; technical criterion delegated to the advisor.

| # | Decision |
|---|---|
| R2-D1 | **Step 12e before A2:** approved. Order: 12e.5 first (the design note, Fable), then 12e.1, 12e.2, 12e.3, 12e.4 (Opus; Sonnet for the text of 12e.3). |
| R2-D2 | **`statistic` of `estimate_households()`:** the default `"proportion"` stays; the range check is added. Estimates stay proportions in the code; reports and vignettes print percentages. |
| R2-D3 | **Infants:** a required argument, without default, when `members` has infants; the value 1 reproduces today's rule. The values an analyst may choose are settled in the design note of 12e.5. |
| R2-D4 | **Upper level and compliance:** the audit row and the bound at compliance 1 in 12e.3; P69 (all or nothing) moves from v0.2 to before A4. |
| R2-D5 | **Fortifiable vehicle:** an optional logical column `fortifiable` in `acquisitions`, set by the adapter where the survey identifies the origin. If present, `vehicle_coverage()` and the scenarios use it; if absent, every gram is treated as fortifiable and an audit row says so. What the ENGIH records on origin is checked by its adapter (A2). |
| R2-D6 | **Iron presentation:** the two sentences corrected in 12e.3; the effective size from the variable's own variance in 12e.4. |
| R2-D7 | **`surveytable`** in `Suggests` for one test, skipped when absent. Statement on AI assistance in the README and `CONTRIBUTING.md`: "Developed with the help of AI tools under the author's supervision; methodological decisions and validation are the author's." **2026-11-16:** the install of `surveytable` from CRAN was refused again by the session's permission classifier; as the maintainer decided (2026-11-15), the anchor test is dropped and the published NCHS rows (`helper-nchs.R`) remain the reference for the Korn-Graubard interval. |
| R2-D8 | **Review track:** deferred; the rOpenSci pre-submission enquiry waits until the repository is public. |
| R2-D9 | **Documents:** the maintainer attaches the PDFs to the session that needs them; they are never committed. Until the hosts are reachable, those sources stay `# SOURCE PENDING`. |

`docs/design-12e5.md` (2026-11-15) proposed two amendments, in its section
7: R2-D3 needs a second argument (`milk_energy_cost`) when the share is
below 1 (decision 1 of the design), and R2-D5 is used only when the call
says so, `fortifiable = "use"` or `"ignore"` (decision 4). Both approved:
see R3-D1 to R3-D9.

## Decisions (2026-11-15, design of 12e.5)

The maintainer approved the nine decisions of section 7 of
`docs/design-12e5.md`, all as recommended.

| # | Decision |
|---|---|
| R3-D1 | **Infants:** the milk's energy belongs in the AFE; `infant_food_share` with `milk_energy_cost`. Amends R2-D3: a share below 1 needs the second number. |
| R3-D2 | **ENGIH keeps `infant_food_share = 1`** as its main analysis, with one sensitivity run. |
| R3-D3 | **Pregnancy and lactation now** (12e.5.2), with `ref_energy_additions` (P57). |
| R3-D4 | **`fortifiable` is used only when the call says so** (`"use"` or `"ignore"`); a missing value counts as fortifiable, flagged. Amends R2-D5. |
| R3-D5 | **`hces_example` gains an invented `fortifiable` column** (false for own production); golden values and snapshots change, recorded in `NEWS.md`. |
| R3-D6 | **Missing composition values:** the list (`missing_values()`), no new threshold. |
| R3-D7 | **All or nothing by `compliance_model`**, the states table, and numeric `above_ul_*` for every input. |
| R3-D8 | **When:** 12e.1 to 12e.4, then 12e.5.1 to 12e.5.8, then A2. |
| R3-D9 | **Documents, not blocking:** the sources listed in decision 9 of the design stay `# SOURCE PENDING` until attached (P181). |

## Open items from the design of 12e.5 (2026-11-15)

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P176 | low | **Children of 12 to 23 months who are still breastfed** count their whole yearly requirement; `infant_food_share` stops at 12 months. | The same reasoning as for infants; the effect is smaller. | v0.2 |
| P177 | low | **Energy of pregnancy by trimester and of lactation by semester per member**, from an optional column, instead of one number for all flagged women. | FAO/WHO/UNU 2004 gives 85, 285 and 475 kcal by trimester; few surveys record it. | v0.2, with a survey that records it |
| P178 | medium | **Gate on key sources declared by the analyst**: a list of foods per nutrient that must have a value, checked by the readiness functions. | The gate by grams cannot see a nutrient concentrated in few foods (P162); `missing_values()` shows the list but nothing fails. | v0.2 |
| P179 | medium | **The results report shows the upper-level exhibit under both compliance models**, as the range between blended and all-or-nothing product. | The truth lies between them; one model alone reads as a point answer. | 12 |
| P180 | medium | **Compliance as two quantities**: the share of the fortifiable vehicle that is fortified at all, and the content of the fortified product relative to the level (an optional column of `scenarios`), instead of one number read by a model. | Market monitoring reports both (Tang et al. 2021, limitations: "some samples were not fortified at all"); `compliance_model` covers only the two extremes. | v0.2 |
| P181 | medium | **What published HCES analyses do with infants, pregnancy and lactation in the adult equivalents is not known from any document opened** (`# SOURCE PENDING`): the supplement of Tang et al. 2021, Weisell and Dop 2012 and Coates et al. 2017 were not obtained. | Row 1 of section 1.4 of the design rests on the FAO document and on this project's reasoning, not on a published convention. | when the maintainer attaches the documents |
| P182 | medium | **Sensitivity of the shares to the number of days observed**, shown as a domain (households by the `period_days` of their records, or by the number of diary days where the adapter records it). Fix (c) of finding 3 of the review v0.2. | The extra variance of apparent intake grows as the period shrinks; a domain makes its direction visible. `hces_example` has 7- and 30-day records in every household, so it needs a survey or an example with households observed over different periods. | 12 (methods vignette, P110) |
| P183 | high | **The reports do not state the limit of finding 3**: the results report labels the shares "inadequate apparent intake" but no note says they are not prevalences of inadequacy on usual intake. A note under the risk exhibits (R0, R2, R3), in English and Spanish, from the same text as `?inadequacy`. | Experts of the first round will read the reports, not the help pages. | 12e.4 or 12e.5.8, before the first expert round **Done 2026-11-16 (12e.4)**: note `usual_intake` under R0, the section 2 exhibits and R3.2/R3.4, in English and Spanish. |

## Open items from the self-review of 12e.4 (2026-11-16)

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P184 | low | **`flag_presentation()` presents a mean or a difference without an interval** (`interval_note` `no_variation` or `no_degrees_of_freedom`) as `present`; only a proportion of 0 or 1 is sent to review (`zero_events`), and only `df < min_df` catches the second case. A review reason `no_interval` for non-proportions. | A report prints an estimate with no interval and no mark. | 12 or v0.2 |
| P185 | low | **The Korn-Graubard interval of a mean of probabilities** still uses `p(1 - p) / se^2` as its effective size, while the presentation criterion now uses `n` over the design effect. Finding 10 found the interval not too narrow (0.397 to 0.603, close to the *t* interval); whether the interval should use the same size is a methodological question. | Two effective sizes for the same cell. | v0.2 (Fable) |
| P186 | low | **Energy per 100 g has no upper bound** in the composition contract (finding 14 cited 2000 kcal per 100 g). An identity bound needs the largest energy factor of a food component, with its source. | `check_crosswalk()` with ranges of the caller is the only check. | v0.2, with a source |
| P187 | low | **`food_group_shares()` and `estimate_unlinked()`** run under the same fixed `survey.adjust.domain.lonely = FALSE` (they use `with_lonely_psu()`), but their logs do not write the note `adjust_domain_lonely` nor count `psu_in_several_strata`, and their tables have no `interval_note` (`flag_precision()` falls back to `se == 0` for them, which there means a share of 0 or 1). | One log rule for every estimator. | 12 |

## Decisions (2026-11-16, design of the ENGIH adapter)

The maintainer answered the eight decisions of section 9 of
`docs/design-adapter-engih.md`: all as recommended, except decision 2.

| # | Decision |
|---|---|
| A-D1 | The companion repository is an R package. |
| A-D2 | A1 is run now by the maintainer. The branch of the export script is **not** merged into `main` of `analisis_ENGIH2018` (the delivered consultancy work stays as delivered): the maintainer runs it from `claude/intelligent-cori-3aev98` and pushes the aggregated tables of `etapas/` to that branch. The script moves to the companion repository when it is created. |
| A-D3 | Download addresses: the maintainer copies them once into the registry. |
| A-D4 | `fortifiable` is `FALSE` only for own production (`QUIEN_PAGO1` = 2). |
| A-D5 | `PORCENTAJE_HOGAR` is used in the corrected analysis (step 2), old and new figures in `NEWS.md`. |
| A-D6 | Non-food codes are dropped by the adapter, with a count. |
| A-D7 | The original outlier rule is kept; a sensitivity run is reported. |
| A-D8 | Vehicle coverage in the corrected analysis is `acquired`; both figures in `NEWS.md`. |

## Open items from the design of the ENGIH adapter (2026-11-16)

Design: `docs/design-adapter-engih.md`. Its eight decisions (section 9)
were answered on 2026-11-16 (section above). New errors of the original analysis are E27 to E29 of
`docs/analysis-map.md`, section 10.

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P188 | high, done 2026-11-19 (help of `estimate_households()` corrected) | **The help of `estimate_households()` says `df = "domain"` is what the original analysis did. It is not**: the 800 rows of `riesgo_inadecuacion.csv` use the degrees of freedom of the whole design (925 = 933 PSUs − 8 strata), provinces and the energy-plausible subset included, because `srvyr` takes them from the design, not from the group. Correct the sentence (and E24 of the analysis map, done); acceptance step 1 uses `df = "design"`. | Under the default, step 1 would fail on every interval of a domain (difference of 7e-4 on `hces_example`). | before A3 (Sonnet) |
| P189 | medium | **`flag_outliers()` assesses purchased grams; the original assessed edible grams.** The rule is relative, so the flags agree in every group with one edible portion; one composition row (70211088, pigeon peas, 1,349 records) has two. Decide after the export of A1 (`atipicos_guandu`): nothing, or an argument naming the value assessed. | A change of interface for a handful of records must rest on a count. | A3, after A1 (Fable if it bites) |
| P190 | medium | **`min_group` counts values with grams; the original counted rows of the group.** Decide after A1 (`atipicos_en_grupos_con_menos_de_20_valores`). | The same. | A3, after A1 |
| P191 | high | **E27: vehicle foods without a composition match are left out of coverage and scenarios by the original** (37 of 75 foods; 1,284 of 36,352 records of wheat products; half of the pastry records). Step 1 reproduces it with a vehicles table of matched foods; step 2 uses all, old and new figures in `NEWS.md`. | Coverage and the nutrient added by every wheat scenario are understated. | A4 |
| P192 | medium | **E28: consumer of a vehicle by grams above zero** in the original; `acquired` in the package. Both figures in `NEWS.md` (decision 8 of the design). | A record without unit factor or with quantity zero is counted as non-consumption. | A4 |
| P193 | medium | **E29: the household's share, the destination and who paid** are recorded by Section 3A and discarded by the chain. The adapter maps them to `household_share`, `origin` and `fortifiable` (decisions 4 and 5). | The manual of the original declares the omission; the analysis map did not list it. | A2, A4 |
| P194 | low | **The crosswalk contract meets the real table**: 114 validated rows without equivalence type and 13 validated rows without composition id. The adapter repairs both with a count (`match_type = "not_recorded"`, `validated = FALSE`). Whether `match_type` should be required at all is open. | First contract rule that a real table breaks. | A2 |
| P195 | low | **Purchases whose unit is missing** are converted by the original through a missing key (Section 2 liquid milk, factor 1,000). The adapter gives the missing unit the code `no_unit`. The vignette on writing an adapter should say that a missing unit can carry meaning. | A silent behaviour of `dplyr` joins that a port by the contracts would lose. | A2; task 12 |
| P196 | medium | **A loose end-to-end anchor outside the project**: Kalimbira et al. 2025 (*Nutrients* 17(15):2485), Malawi IHS5, 183 households, published medians, coverage and shares; public data, no code. Needs an IHS5 adapter and the authors' food matches; tolerance in percent, set in advance. | No published example with data, code and results was found (design, section 8); the ENGIH validation proves the arithmetic, not the method. | v0.2, with the second adapter |
| P197 | low | **`expenditure_lcu` for ENGIH** from `MONTO_TOTAL`, with the codes of `MONEDA`. | The readiness report by expenditure needs it; A1 to A4 do not. | after A3 |
| P198 | medium | **E19, the package content declared in each record**, is not used; the food factor is its median. A1 counts the records converted by a food factor that carry a declared content. | The declared content is the survey's own measurement; using it needs a rule for implausible values. | v0.2 (Fable) |
| P199 | low | **Densities of liquids** (E18) need a cited table before the corrected analysis leaves water's density: `# SOURCE PENDING`. | Oil is declared by volume in most of its Section 2 rows. | A4, with a source |
| P200 | low | **The export script of A1 has run only on invented stand-ins.** Its first run on the microdata is by the maintainer; an error there is most likely a column name. | It could not be run here. | A1 |


## Open items from the review of 12e.1 to 12e.4 (2026-11-16)

Review: `docs/review-12e.md` (findings `V<step>.<n>`). Two approved parts
were deferred by the working sessions and wait for a decision of the
maintainer: the bound at compliance 1 in the report (V3.1; P179) and the
sensitivity by days (V3.2; P182). See the questions in `docs/handoff.md`.

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P201 | high | **Stacked estimate tables are refused by `flag_presentation()` and `flag_precision()`** (V1.1): the key of an `hces_estimate` is the group columns and `by`, without `variable` and `statistic`, and since 12e.1 `require_hces()` checks it. `dplyr::bind_rows()` of the estimates of two variables or two statistics is an `hcesfort_error_key`; before 12e.1 it worked. Add `variable` and `statistic` to the key in `estimate_households()` and `estimate_difference()` (the keys of `estimate_unlinked()` and `food_group_shares()` already hold `variable`), with a test. | A change of behaviour that no approval covers; an adapter builds one table of results this way. | before A2 (Opus, one small commit). **Done 2026-11-16**: `statistic` and `variable` in the key of both estimators; test in `test-carrier-key.R` (two variables, two statistics, two differences, and a true repeat still refused). |
| P202 | low | **The range check of a proportion reads the rows outside `domain`** (V1.2): check the aligned values, not the whole column. | An error for rows that are not estimated. | 12 |
| P203 | low | **Test gaps of 12e.1 and 12e.2** (V2.1 and the tests of 12e.1): the key test through `dplyr::bind_rows()` and a fanning `left_join()`, not only the helper that copies attributes; the 11 call sites of `require_hces()` not in the chain test; the FAO examples with the BMR rounded to 0.1 MJ, within 1 kcal (the 1% tolerance does not separate the two adult bands in the first example); `shipped_results()` leaves the working directory in the knit folder for the rest of `test-report-results.R`. | Each is a way for a later change to pass unseen. | 12 |
| P204 | medium | **Cells without degrees of freedom** (V4.2, V4.3): `no_degrees_of_freedom` is decided on the argument `df`, so with `df = "design"` or a number a domain inside one PSU returns an interval of width zero and no note; decide it on `survey::degf()` of the domain. `flag_precision()` returns `ok` for a cell without an interval (`no_degrees_of_freedom`, `undefined_quantile_interval`): a status `no_interval`, low precision; `n_effective` missing where the standard error cannot be estimated. | Findings 11 and 12 of the review v0.2 remain open under the option the ENGIH acceptance uses. | before A3 (Opus), with P201 or P184. **Done 2026-11-16**: decided on `survey::degf()` of the domain whatever `df` says; such a cell reports the `df` of the domain (0) so that `flag_presentation()` sends it to review (`degrees_of_freedom`) under any `df`; `n_effective` missing; `flag_precision()` status `no_interval`, low precision, logged. Tests in `test-estimate-intervals.R`. P184 (a mean without variation is `present`) stays open. |
| P205 | low | **An anchor for the effective size** (V4.1): `n / survey::deff(survey::svymean(~y, d, deff = "replace")) * (n - 1) / n`, which agreed in five cells in the review. Today the package, the golden script and the "by hand" test hold the same expression. | The only estimator of 12e.4 without a reference outside the project. | 12 |
| P206 | low | **The contract of `age_months`** (V4.4): the schema says "age in months, for infants"; since 12e.4 the validator requires the total months since birth for every member (`age_years = 3` with `age_months = 5` is an error). Say so in `hces_schema("members")` and in `?validate_members`. | An adapter with "years and remaining months" meets the rule only as an error. | 12e.5.1 (the step touches `age_months`) or 12. **Done 2026-11-16** (with 12e.5.1). |

## Open items from 12e.5.1 to 12e.5.4 (2026-11-16)

Self-review of the infant, pregnancy and lactation energy in
`adult_equivalents()` and of the fortifiable vehicle.

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P207 | low | **The rule against charging milk twice is household-blind**: it fires when any member is lactating with `lactation_kcal > 0` and any `food_share` is below 1 with `milk_energy_cost > 0`, even if no infant falls in the months of that share or the lactating woman lives in another household. The design asks for this simple rule (section 1.3); a finer one would check, per household, an infant whose share is below 1. | A spurious error, never a wrong figure. | v0.2, if an adapter meets it |
| P208 | low | **An infant whose month is unknown takes the share at the first month of each row of `energy`.** With the shipped table (rows of one month) this is exact; with a user table of wider rows and share intervals that cut them, it is an approximation the help states. | Only for user tables. | 12 (a sentence in the vignette on adapters) |
| P209 | low | **`pregnant` and `lactating` are not checked against sex and age**: a man or a girl of 5 years flagged pregnant gets `pregnancy_kcal`. A validator rule (flag only for women of reproductive age, with the bounds an argument) would be a contract change. | No silent error today: the energy added is noted in the log with its count. | 12 or v0.2 (Fable: the bounds) |
| P210 | low | **The scenario exhibits of the results report do not say that own production gets nothing.** The log has `fortifiable_share` per vehicle; a note under the scenario exhibits (en, es) with that share would let a reader see why a vehicle adds less than its grams suggest. | The figures moved in 12e.5.4 for this reason only. | 12e.5.8, with the coverage exhibit **Done 2026-11-17** (12e.5.8): the note `fortifiable_share` under R1.1 and R3.1 (weighted share of the grams of each vehicle), and the column and hollow point of the fortifiable vehicle in R1.1. |

## Open items from 12e.5.5 (2026-11-16)

Self-review of `missing_values()`, its log row and Table D3.1.

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P211 | low | **Table D3.1 lists every food without a value.** With a large survey and many nutrients it can run to hundreds of rows. A cap (the foods up to a cumulative share, or the first ten per nutrient) with a sentence giving the rest, and the full list in the appendix. | On `hces_example` it is one row; ENGIH will say whether it is needed. | 12 |
| P212 | low | **Two grams for the same records.** The log row `foods_without_value` of `apparent_intake()` gives grams per day as acquired, unweighted (the convention of every row of the step); `missing_values()` ranks by edible grams weighted by the survey weight. One sentence in `?missing_values` would say that the two do not agree and why. | A reader comparing the log with the queue sees two numbers. | 12 |


## Open items from 12e.5.6 (2026-11-16)

Self-review of the states table of `apply_scenario()` (12e.5.6) and of its
collapse in `inadequacy()` and `above_ul()` (12e.5.7), under
`compliance_model = "all_or_nothing"`.

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P213 | medium | **No bound on the number of states.** A scenario with `k` vehicles of partial compliance gives `2^k` copies of the households; with 15 vehicles and 10 000 households that is 330 million rows. A check before the rows are built (households times the sum of `2^k` above a stated limit, or `k` above a limit) with an error that names the scenarios and suggests average content or splitting the scenario. No threshold without a decision of the maintainer. | Real scenarios have one to four vehicles; a typo in `compliance` (0.99 for 1) over many vehicles would exhaust memory with no message. | 12e.5.8 or 12 **Done 2026-11-17** (12e.5.8) as P219. |
| P214 | low | **Each state recomputes the vehicle lookup.** `states_rows()` calls `scenario_rows()` once per state, which rebuilds the match of households to vehicle grams each time. Computing the added amount per vehicle once and summing the vehicles of each state would be linear in vehicles, not in states. | Only matters with many states (P213). | 12 |
| P215 | low | **Counts of the logs of `inadequacy()` and `above_ul()` on the table of states are in state rows.** The rows `all`, `method`, `coverage`, `tails_fixed` and `ear_assumes_bioavailability` count the rows of `x`, which under all or nothing are households times states; the households are right (`n_households`). Counting one row per scenario and household (the first state) would make the logs of both models comparable. | The note `states_collapsed` says the input was a table of states, so the numbers are not wrong, only larger. | 12 |
| P216 | low | **The gates read the first scenario of `x`.** `check_records_used()` and `check_coverage()` take the rows of `x$scenario[1]`; `apply_scenario()` puts the baseline first, with one state. A table reordered by the user with a scenario of several states first gives the same shares (every household repeated the same number of times) but log counts multiplied by the states. Selecting the baseline by `baseline_label` (recorded in the log) would remove the dependence on order. | Older than 12e.5.7; the states make it visible. | 12 |

## Open items from the review of the all-or-nothing model (2026-11-17)

From `docs/review-12e5-states.md` (findings S2.3, S3.1, S4.1, S5.2).
P219 is the recommendation on P213 the maintainer asked for.

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P217 | medium | **`above_ul_total` and `amount_total` on the states table are not tested.** The states tests use a UL on folic acid with the added part only; a collapse that leaves `above_ul_total` or `amount_total` as the value of the first state passes every test (mutations M6 and M7 of the review). Add a test with the fixture `two_vehicles()` and a UL on total iron of 6 mg: household 1 has `amount_total` 5.35 and `above_ul_total` 0.5 by hand; and one with a form that has a diet part (`form_diet_and_added`). | The report exhibit R3.3 under all or nothing shows `above_ul_total` for iron and zinc with no test behind it. | 12e.5.8 **Done 2026-11-17** (12e.5.8): tests "a UL on total iron" and "a form with a diet part" in `test-risk-states.R`; the understates flag has its own test (S3.3). |
| P218 | low | **Average content is not a lower bound of all or nothing.** A household with `c × A > UL` counts 1 under average content and `c` under all or nothing; on `hces_example`, `plus_sugar` vitamin A `above_ul_added` is 0.000468 under average content and 0.000328 under all or nothing, and `p_inadequate` is not ordered either. `?above_ul` ("no household ever receives the full dose, so the share is understated") and the report note `ul_average_content` state an ordering that does not hold. Say instead: the two models give the same mean and are not ordered in the shares; the figure at compliance 1 bounds both. | The column at compliance 1 of 12e.5.8 is the bound; the average-content column is not a floor, and the text should not say it is. | 12e.5.8 **Done 2026-11-17** (12e.5.8): `?above_ul`, `?apply_scenario`, the vignette and the report note `ul_average_content` (en, es) say that the two models are not ordered and that compliance 1 bounds both. |
| P219 | medium | **Recommendation on P213: a visible, optional limit before the rows are built, and the cost in the log.** (1) `apply_scenario()` gains `max_states` (largest `2^k` per scenario; `NULL`, the default, means no limit and the help says so); above it, `hcesfort_error_value` names the scenarios, their `k` and the rows the table would have, and suggests `"average_content"`, a higher limit or a split; the report template sets it in `_inputs.R` next to `compliance_model`. (2) The log row `states` adds the rows and the approximate size in MB per scenario. Measured: `hces_example` (2,000 households, up to 7 partial vehicles) gives 498,000 rows, 99 MB, 830 MB of peak memory for `apply_scenario()` + `above_ul()` + `inadequacy()` (128 MB under average content), 11 s; at 9,000 households about 3.7 GB of peak memory; 10 partial vehicles in one scenario would not fit a workstation. | The log alone is written after the memory is spent; the typo case of P213 kills the session before any log is readable. Building only the states each household can distinguish (31% of the rows on the example) changes the design (probabilities per household) and belongs with P214 in task 12. | 12e.5.8 (decision), 12 **Done 2026-11-17** (12e.5.8): `max_states` in `apply_scenario()` and in `_inputs.R`; the rows and MB in the log row `states`. Distinguishable states stay in task 12. |
| P220 | low | **A vehicle name with `+` makes the state label ambiguous.** Vehicles `a`, `b` and `a+b` in one scenario at compliance 0.5 give two states labelled `a+b` with different added amounts; `apply_scenario()` returns the repeated key without failing and `inadequacy()` aborts with `hcesfort_error_key` blaming a join. Refuse `+` in vehicle names under all or nothing in `check_vehicle_compliance()`, or use a separator the schema forbids. | A wrong error message for a legal input. | 12 |


## Open items from 12e.5.8 (2026-11-17)

Self-review of 12e.5 (rOpenSci reviewer view).

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P221 | low | **The column at compliance 1 has no interval and no review mark.** `with_ul_bound()` and the fortifiable column of R1.1 print the point estimate of a second table of `flag_presentation()`, missing where it is suppressed, but a figure flagged for review shows no "†", and the upper limit of its interval (the conservative figure for safety) is not printed. Add the mark, and consider the upper limit, with P179. | A bound reported as a safety figure should carry its own precision. | 12 |
| P222 | low | **R3.3 keeps the rows of zero events of a nutrient whose bound is above zero.** With the bound, a nutrient with any scenario above zero at compliance 1 keeps every scenario row, including rows that are 0 in both columns (iron under the wheat flour scenarios on `hces_example`). Dropping the rows zero in both into the sentence of exact values would shorten the table. | Readability; the figures are right. | 12 |
| P223 | low | **The log cause `average_content_understates_ul` keeps its name.** After P218 the text says the figure is below the bound at compliance 1, not below the truth; the name reads as the old claim. Renaming it changes the log vocabulary that the report template and users read. | Wording; the detail says "rerun at compliance 1 for the upper bound". | 12 |
| P224 | low | **The fortifiable share of the notes has no interval.** `fortifiable_note()` of the report prints a weighted ratio of grams per vehicle; the log of `apply_scenario()` prints the unweighted one. Both are descriptive; the note says "weighted". An estimate with `food_group_shares()`-style ratio and interval would make it a figure of the report. | Two different numbers for one idea in the log and the report. | 12 |
| P225 | low | **`max_states` is not read under average content.** It is documented, and under average content every scenario has one state, so no call is ever above a limit of at least 1; a user who sets it and changes the model gets no message. | Consistent with "one state"; recorded so it is a decision, not an accident. | 12 |

## Open items from A2.5 (2026-11-19)

Self-review of the tables of the ENGIH adapter (`hcesfort.engih2018`,
commits `42aa2ac` to `16d8f20`). Details in its `data-raw/SOURCES.md`.

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P226 | medium | **Garlic powder takes the edible portion of fresh garlic.** In `food_factors.xlsx` the Section 3A row of code 537 (garlic powder) carries composition id 70211006 (fresh garlic) and edible 0.87; the crosswalk maps it to 70222001. The original joins the edible portion by food code, so garlic powder loses 13% of its grams. Code 376 (shelled pigeon peas) has the same mismatch with no effect (1.00 either way). | A candidate error of the original (an E number for the map); small grams, but a wrong number. Step 1 reproduces it. | A4 (one correction commit, if the maintainer confirms) |
| P227 | low | **Finding 7 of the adapter design is half wrong.** The 1,000 of Section 2 liquid milk is on unit 31 (*Cartón*, name left empty in the sheet), not on a missing unit. The adapter gives `no_unit` no factor, as the original. A1's `sin_unidad_con_fc` should be 0. | The design text misleads the next reader. | 12 (fix the sentence of `docs/design-adapter-engih.md`) |
| P228 | low | **U2 may not bite.** The crosswalk maps shelled pigeon peas (376) to 99211088, a row the original added to the INCAP workbook, and peas in the pod (374) to 70211088: two composition ids, so the outlier group of 1,349 records with two edible portions (U2) does not exist at 7caab91. | One reproduction risk less; A1 (`atipicos_guandu`) confirms. | A3 |
| P229 | low | **Non-foods differ between crosswalk and groups.** Ice is a non-food in the crosswalk only; pipe tobacco in the groups only. Neither has a composition match, so no figure moves; the survey builder (A-D6) drops the crosswalk's 11. | Two lists of the same thing. | A2.7 (say which list drops records) **Done 2026-11-19** (A2.7, `103b5d5` in the adapter): the crosswalk's list drops the records; the log row `non_food` says so in `detail`. |
| P230 | low | **The frozen CSVs of the adapter have no md5 of their own.** The scripts check the md5 of the source files, and the tests check counts and invariants, but an edit of `inst/extdata/*.csv` by hand is caught only by those tests. | Reproducibility rule of `CLAUDE.md` (files registered by an adapter are verified by md5). | A2.8 **Done 2026-11-19** (`1b27cb8` in the adapter): `inst/checksums.csv` with the md5 of every file of `inst/extdata/` and `inst/acceptance/`, checked by `test-checksums.R`. |
| P231 | medium | **The dozen covers 218 records in 22 foods, not 13.** `e_e2_docenas` of A1: passion fruit 108, sour lime 28, orange 22, crab 20, ...; one Section 2 row (oil, 0.25 dozen). Design section 5, row 4, expects 13 records and no move of 0.01 point. Each of the 22 foods needs the weight of one piece with a source; `dozen = "count"` is refused until then. | E2 is larger than the design says; the expected direction of the correction must be rewritten before it runs. | A4 (E2) |
| P232 | medium | **Records without a validated match share one outlier group per section.** `outlier_group` is missing for them, and `flag_outliers()` makes the missing value a group. The original never judged them (they were dropped first). Nothing of step 1 moves; with `vehicles = "all"` (E27) the 37 unmatched vehicle foods are judged against every other unmatched food. | The group decides which records are outliers. | A4 (E27): group them by food code, or exclude them from the rule, decided with the maintainer |
| P233 | low | **The corrected preset builds no tables yet.** `dozen = "count"`, `density = "by_food"`, `enrichment = "pairs"` and `levels = "standard"` need data without a source (piece weights, densities by food, reference pairs with the whole-grain rows identified, the basis of each standard); `engih2018_tables()` refuses each with a message naming the data. | Step 2 moves one row at a time from the original preset, so nothing is blocked before A4. | A4 (E2, E18, E6, E8) |
| P234 | low | **The md5 of the frozen files are checked by the tests only.** `check_frozen()` is internal and runs in `test-checksums.R`; `engih2018_tables()` does not call it, so an installed copy edited by hand is caught only when the tests run. | Checking at every read would make the `data-raw/` scripts fail between writing a table and rebuilding `inst/checksums.csv`. | A3, if the maintainer wants the check at read time (for example in `engih2018_tables()` with an argument) |
| P235 | low | **The non-food drop is counted for both sections together.** The log row `engih2018::non_foods` has one count, so the acceptance test of A2 checks kept plus dropped records against the total of A1, not per section; two errors of opposite sign in the two sections would pass. | A per-section count makes the test exact (47,837 and 342,046). | A3 **Done 2026-11-19** (`d34f30e` in the adapter): the A2 test counts the dropped records per section from all the records before the drop (`acceptance_records()`); the log is unchanged. |
| P236 | low | **`renv.lock` was written in the container, with R 4.3.3.** The original chain ran with R 4.6.1 and 4.6.2 on Windows. The lock pins the package versions, not R. | Step 1 compares figures to 1e-6; a version of `survey` or `dplyr` could move a quantile. | A3: the maintainer runs `renv::snapshot()` in the adapter on the machine of the acceptance run and commits the lock it writes |

## Open items from A3.3 (2026-11-19)

Self-review of the control-file comparisons (`hcesfort.engih2018`,
commits `cd61a3a` and `38a3185`).

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P237 | medium | **Design 4.2 gave `df = "design"` to every estimate; the medians with an interval of the original used the degrees of freedom of the domain.** `srvyr::survey_median()` passes `df = NULL`, so `survey::svyquantile()` takes `degf()` of the group after its own `na.rm` subset (the consumers of the area or quintile); `survey_mean()` takes `degf(cur_svy_full())`. Checked on a small design with srvyr 1.3.1 and survey 4.5. | Under `df = "design"` the limits of the medians among consumers by area and quintile would differ from the original. | A3.3 **Done 2026-11-19**: the comparisons use `df = "domain"` for those medians, `test-acceptance-intervals.R` checks both choices against srvyr in CI, and design 4.2 has a note. |
| P238 | low | **The households near a threshold are reported, not tested.** `umbrales.csv` counts the households within a relative 1e-9 of each EAR, upper level and energy bound (design 4.1); no expectation reads it, because a household on a threshold is not a failure. | It is what decides whether a failed percentage can be rounding of the original's intermediate files. | A3: read it first when a control comparison fails |
| P239 | low | **The control comparisons cannot run in CI on the invented survey.** Its stratum 2 has one PSU, so `lonely_psu = "fail"` (S21) stops the estimates; the smoke run replaces the design with `lonely_psu = "adjust"`. A fixture with two PSUs per stratum would let the control tests run end to end in CI. | Today the control helpers are exercised in CI only by `test-acceptance-intervals.R` (on `hces_example`) and by hand with the smoke run. | A4 **Done 2026-11-19** (adapter): `helper-fixture-design.R` (household 12_1, two PSUs per stratum) and `test-acceptance-controls-ci.R`; the smoke run no longer replaces the design. |
| P240 | low | **The folate columns of `escenarios_resumen` are compared on all 35 rows**, not once per scenario as design 4.2 says: the package value is repeated on every nutrient row, as the original repeats it (E13). | Stricter than the design; equal if the original's repeats are equal. | none |

## Open items from A3.5 (2026-11-19)

The S22 mismatch of the maintainer's run (`grupos_micronutrientes`, 100 of
112 shares; `hcesfort.engih2018`, test helpers only).

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P241 | high | **Hypothesis for the S22 mismatch: the original groups the records by description text and drops those whose text finds no row.** `08_grupos_alimentos.R:42-56` joins `agrupacion_alimentos.csv` by `(seccion, descripcion)` and keeps `!is.na(grupo_mddw)` (under 1% of the records, by its own guard); the adapter joins by code. The stages agree (e05: the totals of 05 are reproduced), so a group whose share rises in the package while every other falls has records that 08 lost: dairy. With the figures of the run, the package equals the original plus dairy records worth about 12% of the original's vitamin D total, 3.5% of B12, 2.8% of vitamin A, 0.13% of folate and 0.04% of iron, which gives the reported fall of the other groups (up to 11%). The text is one to one with the code on the records (`e01_descripciones`), but not necessarily equal to the table's (`LECHE LíQUIDA` of Section 2 is a candidate). Step 1 now takes, per code, the group of the original's join (`group_join_codes()`, `step1_food_groups()`) and drops `unclassified` from the shares (`control_groups()`); the codes grouped otherwise or dropped are written to `grupos_codigos.csv`. | Not confirmed: needs the microdata. If the comparison still fails, `grupos_codigos.csv` and the comparison go to Fable (stop rule of design 4.4). | A3.5 **Confirmed 2026-11-19** (maintainer's run, adapter `8e7c36c`): 15 of 15 pass; `grupos_codigos.csv` has one row, `S2:13 LECHE LÍQUIDA` (1,913 records), which the table spells `LECHE LíQUIDA`. |
| P242 | medium | **New error of the original, E30 (`docs/analysis-map.md`, section 11; P241 confirmed): records whose description does not match the table are dropped from the food-group shares without a count.** The package's join by code, with `unclassified` shown, is the correction; old and new figures in `NEWS.md`. | Step 2 corrects each erroneous default. | A4 |
| P243 | high | **A preprocessing module for new surveys (maintainer's request, 2026-11-19).** Text keys normalised before any join (case, accents, spaces); joins by code with the unmatched listed; a report of every description that a table spells differently from the records. | E30: one accented letter (`LECHE LíQUIDA` against `LECHE LÍQUIDA`) dropped 1,913 records from the food-group shares without a count. A new survey (Peru) will bring the same class of error. Next to the food-matching support module (P42, v0.2); Fable designs, Opus implements. | v0.2 |


## A4.2d, E6 (2026-11-20, Opus)

Implementation of row 12 of the design of the adapter
(`hcesfort.engih2018` `bc6e18b`, `707d3c1`).

| Id | Priority | Item | Why | Task |
|---|---|---|---|---|
| P244 | medium | **The direction of E6 in the design (section 5, row 12) is not true cell by cell.** It says "every baseline cell is at least its legacy value (the floor of `"subtract"` is the legacy value)". `unfortified_baseline()` keeps a cell at `v` when `v < f × U` (no cell increases), while the legacy rule set it to `f × U`. On ENGIH 2018 one cell: folate of pasta 70213057 ("unenriched", 18 µg DFE per 100 g; legacy 26). Correct statement: every cell is at least `min(v, legacy)`. Iron holds cell by cell; folate intake is expected, not guaranteed, to rise. | Found by `test-tables-enrichment.R` before the run; the step's expectation was written accordingly (`helper-step2-e6.R`). Amend the design table when the figures come back. | A4.3 |
| P245 | low | **`engih2018_tables()` returns the enrichment rules without the method they are meant for.** `"legacy"` rules go with `method = "replace_by_ingredient"`, `"pairs"` with `"subtract"`; the chain takes the method from `step1_args`. A user who mixes them gets no error (pairs under replace give `f × U`, nearly the legacy values). Option: return `baseline_method` with the tables, or a note in the log. | Coupling now stated only in `?engih2018_options`. | A4.3 |
