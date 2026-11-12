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

## Proposal P42: food-matching support module (2026-11-12)

Proposed by the maintainer; assessed here, not implemented. Status: **open,
proposed for v0.2 before the Peru adapter.**

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
function, with a classed error if it is missing. It is not installed in the build
environment today, so its interface and its own dependencies are still to be
checked. Base `utils::adist()` is a fallback with
no dependency but only edit distance. No Excel dependency. No new `Imports`.

**Where it goes.** v0.1: `unmatched_foods()` with task 7; `check_crosswalk()`
as a new task after 7 (medium, Opus, small). v0.2, before the Peru adapter:
candidates, seeds and the review round trip (design by Fable, implementation
by Opus, as `docs/model-routing.md` already lists). Doing it before Peru is
right: the Peru crosswalk is its first real use, and the ENGIH crosswalk,
already validated, is its test of recall (how often the validated match is
among the top *k* candidates).

**Decision needed from the maintainer:** accept the split (quality controls
and ranking in v0.1, candidates and review in v0.2)? Recommended: yes.

## Open items from task 1 (2026-11-10)

| ID | Priority | Item | Rationale | Roadmap task |
|---|---|---|---|---|
| P36 | closed 2026-11-12: not adopted | **Adopt the `srr` workflow or confirm it does not apply.** rOpenSci's guide for statistical software (source read: `ropensci/statistical-software-review-book`, `pkgdev.Rmd`) requires the roclet `srr::srr_stats_roclet` in `DESCRIPTION`, a `@srrstatsTODO` tag per standard, none left at submission, and a passing `pkgcheck::pkgcheck()`; `autotest` is recommended. Its categories are general, Bayesian, EDA, machine learning, networks, probability distributions, regression, spatial, time series and unsupervised learning. Survey-based prevalence estimation fits "general" at most, so the first step is a pre-submission enquiry to the editors: statistical review, or the standard rOpenSci software review. Not done in task 1: `srr` could not be installed in the build environment (CRAN is not reachable from it). | Decides whether standards are annotated while coding (cheap) or retrofitted (expensive). | 2, before the first core function |
| P37 | low | **`codemeta.json`.** Generate with `codemetar::write_codemeta()` once the package has content; add the file to `.Rbuildignore`. | Expected by rOpenSci; not generated because `codemetar` was not available. | v1.0 |
| P38 | low | **Confirm the name on CRAN itself.** `hcesfort` is absent from the GitHub mirror of CRAN (`cran/hcesfort` does not exist, while `cran/srvyr` does), which is indirect evidence; `available::available("hcesfort")` needs a network that reaches CRAN. | The roadmap asked for the check; only the indirect one was possible. | before v1.0 |
| P39 | medium | **Maintainer e-mail.** `DESCRIPTION` uses the GitHub no-reply address already public in the commit history. CRAN needs an address that receives mail. | Avoids publishing a personal address without the maintainer's say-so. | before v1.0 |
| P40 | medium | **Dependencies enter `DESCRIPTION` when first used.** `Imports` is empty in the skeleton: listing a package that no code imports produces a check note. | Keeps `check()` at 0 notes; the list agreed in `CLAUDE.md` is the ceiling, not the starting point. | 2 onwards |
| P41 | low | **Codecov or an equivalent badge.** Coverage is computed in CI and the job fails below 90%; nothing is uploaded to an external service. | An external service needs the maintainer's account and token. | any |

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
