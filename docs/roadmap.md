# Roadmap

Work only on the first open task. Each task ends with a clean `devtools::check()`, commit and push.

## v0.1: generic core, validated against ENGIH 2018
- [x] 0. **Read the whole analysis** and write `docs/analysis-map.md`. Review recorded in `docs/improvements.md`.
- [x] 1. Skeleton: `DESCRIPTION`, MIT licence, testthat 3, roxygen2 markdown, `NEWS.md`, `README`, `.gitignore` with `data-raw/private/` and without `docs/`, `.Rbuildignore`, GitHub Actions (R CMD check on three OS, test coverage, lint), `CITATION`, contributing guide, code of conduct, and a test that enforces the size limits. Left open, see `docs/improvements.md` (P36–P38): `srr` annotation workflow, `codemeta.json`, name check on CRAN itself.
- [x] 2. Data contracts: schemas of the standard and user-supplied tables, constructors and validators, classed errors, nutrient registry, audit-log carrier (chosen by test) and its format (counts of records, households and grams by cause). Design: `docs/design-task2.md`.
  - [x] 2.0 Design written (carrier chosen by experiment); approved 2026-11-12.
  - [x] 2.1 Classed errors and audit-log format and carrier.
  - [x] 2.2 Validators of `households`, `members`, `acquisitions` and their cross-table check.
  - [x] 2.3 Validators of the user-supplied tables and nutrient registry.
- [x] 3. Synthetic example dataset in the standard schema (invented households, composition, vehicles, one scenario), documented as synthetic.
- [x] 4. Reference data with sources in `data-raw/` (EAR, UL and the form it applies to, energy requirements, WHO 2009 levels, iron requirement distribution, DFE and RAE factors). Unverifiable values stay `# SOURCE PENDING` and are not shipped.
- [x] 5. `adult_equivalents()`.
- [x] 6. `convert_units()` (typed factors) and `flag_outliers()`.
- [x] 7. `link_composition()` and `fill_composition()`, with coverage over all records; `unmatched_foods()` (P42, part a).
- [x] 7b. `check_crosswalk()`: quality controls of the crosswalk as flags, thresholds given by the caller (P42, part d).
- [x] 8. `apparent_intake()` with the `include` flag, household status and energy-plausibility flag; `nutrient_density()`.
- [x] 9. `unfortified_baseline()`, `apply_scenario()` (level basis, compliance) and `vehicle_coverage()`. Design: `docs/design-task9.md`.
  - [x] 9.0 Design written (2026-11-12); approved as recommended 2026-11-12.
  - [x] 9.1 Contracts: `form`, `vehicle_group`, table `enrichment`, example data.
  - [x] 9.2 `unfortified_baseline()`.
  - [x] 9.3 `vehicle_coverage()`.
  - [x] 9.4 `apply_scenario()`; specification, `NEWS.md`, self-review.
- [x] 10. `inadequacy()` and `above_ul()`. Design: `docs/design-task10.md`.
  - [x] 10.0 Design written (2026-11-12); approved as recommended 2026-11-12.
  - [x] 10.1 Reference tables: `ul_unit`, `ul_form`.
  - [x] 10.2 `inadequacy()`: cut-point and coverage rule.
  - [x] 10.3 Probability approach.
  - [x] 10.4 `above_ul()`; `NEWS.md`, self-review.
- [x] 11. `as_hces_design()`, `estimate_prevalence()` and `estimate_difference()` on a complex design, subsets as domains.
  - [x] 11.0 Choices approved as recommended 2026-11-12 (`docs/improvements.md`).
  - [x] 11.1 `as_hces_design()`; `survey` and `srvyr` to Imports.
  - [x] 11.2 `estimate_prevalence()` (proportion, mean, median), tested against `survey` to 1e-8.
  - [x] 11.3 `estimate_difference()` (paired, within household); `flag_precision()`.
  - [x] 11.4 `NEWS.md` (E5 domains, E24), specification, self-review.
- [x] 11b. Corrections of the v0.1 review (`docs/review-v0.1.md`, section 10), before task 12.
  - [x] 11b.0 Design note `docs/design-review-v0.1.md` (corrections 1, 2, 3, 8, 10; 4 accepted); its ten decisions approved as recommended 2026-11-12.
  - [x] 11b.1 Record loss: columns and `min_records_used` (H1).
  - [x] 11b.2 `cutpoint_valid`, `ear_bioavailability` (H2, L9).
  - [x] 11b.3 `domain_from` (H3).
  - [x] 11b.4 `apply_scenario()` checks AFE and outlier decision (H4, P76).
  - [x] 11b.5 Recalibrate `hces_example`; full-chain golden test (H6, M11).
  - [x] 11b.6 Degenerate proportions, lonely PSU, surviving mutations (M5, M6, P84, T1–T4).
  - [x] 11b.7 Classed errors for missing arguments; unclear messages (M9, L3).
  - [x] 11b.8 Audit log: merge without repeats, `audit_summary()`, `audit_record()` (M7, P50).
  - [x] 11b.9 Renames (L1, L2).
  - [x] 11b.10 `reference_energy()`, `qty_vehicle_g_d_pc`, `who2009_levels()` (M10, M8, P71).
- [ ] 12. Vignettes in English and Spanish: from standard tables to risk by scenario (synthetic data); how to write an adapter; plotting results with `ggplot2`. The pkgdown site waits for v1.0. Waits for 12c (maintainer decision 2026-11-13): do 12c first.
- [x] 11c. `food_group_intake()` and `food_group_shares()` on the unfortified baseline (E1), brought forward from v0.2. Design: `docs/design-food-group-shares.md`.
  - [x] 11c.0 Design written (2026-11-12); its nine decisions approved as recommended 2026-11-12.
  - [x] 11c.1 Contract `food_groups`, validator, example data.
  - [x] 11c.2 `food_group_intake()` with its log.
  - [x] 11c.3 `food_group_shares()` and the internal ratio helper.
  - [x] 11c.4 Golden chain, `NEWS.md` (E1), specification, self-review.
- [x] 12b. Country results report template (`use_report_template()`), organised by decision questions, in English and Spanish; invented socioeconomic domain in `hces_example`. Needs 11c for Q3. Design: `docs/design-report-template.md`.
  - [x] 12b.0 Design written (2026-11-12); its eleven decisions approved as recommended 2026-11-12 (D10 amended).
  - [x] 12b.1 Invented `expenditure_group` in `hces_example` (G6).
  - [x] 12b.2 `use_report_template()`, template files in English and Spanish, tests (knit on `hces_example`, headline guards, exported functions); fix of `estimate_households()` on a table keyed by household only.
- [ ] 12c. Redesign of the reports after the maintainer's review of the rendered template: a data readiness report and a restructured results report. Requirements: `docs/report-requirements-v1.md` (approved 2026-11-13). Comes before task 12 (vignettes), which will show the new reports.
  - [x] 12c.0 Design (`docs/design-reports-v2.md`): structure of both reports, label table contract, new exported functions, contract changes and the automated checks. Written 2026-11-13 (Fable); approved 2026-11-13, decision 7 amended (comparator kept as a template choice).
  - Implementation (Opus), after approval; each step at most 300 lines of code, split if larger. Detail in section 10 of the design.
  - [x] 12c.1 Optional column `expenditure_lcu` in `acquisitions`; invented column in `hces_example`.
  - [x] 12c.2 `linkage_ladder()` (DR3).
  - [x] 12c.3 `unmatched_foods()` as the work queue (DR4).
  - [x] 12c.4 `estimate_unlinked()` (DR5).
  - [x] 12c.5 `precision_status` in `flag_precision()` (R7).
  - [ ] 12c.6 Label table and decisions table: schemas, `read_labels()`, `label_codes()`, `read_decisions()` (R2, DR7).
  - [ ] 12c.7 `readiness_inventory()`, `readiness_checks()` (DR1, DR2).
  - [ ] 12c.8 `readiness_verdict()` (DR8).
  - [ ] 12c.9 Shared template files; readiness report in English.
  - [ ] 12c.10 Readiness report in Spanish.
  - [ ] 12c.11 Results report in English, with `choices$comparator`; old template files removed.
  - [ ] 12c.12 Results report in Spanish.
  - [ ] 12c.13 Quarto in CI; specification, `NEWS.md`, self-review; handoff for the maintainer's render on ENGIH 2018 (acceptance C2).

## v0.1, companion repository `hcesfort.engih2018`: ENGIH 2018 adapter (needs the microdata)
- [ ] A1. Stage-level control figures exported from the original pipeline (record counts by section and drop cause, grams by section, AFE distribution, median intake per nutrient), md5 of the microdata, and the three checks left open on E4 (energy of Sec 3A alone by days with a record, upper tail by days, the eighth day) plus the number of records in dozens (E2). Run by the maintainer when the microdata are at hand.
- [ ] A2. Thin adapter: ENGIH files → standard tables that pass the contracts of task 2. Start right after task 2 so the contracts meet a real survey early.
- [ ] A3. Acceptance step 1: reproduce the control figures with the original choices as explicit options (tolerance 1e-6).
- [ ] A4. Acceptance step 2: correct each erroneous default, one per commit, old and new figures in `NEWS.md`.

## v0.2: Peru and the article's open criticisms
- [ ] Food-matching support module (P42, parts b, c, e): candidates by text similarity, seeds from validated crosswalks, review round trip. Before the Peru adapter.
- [ ] Peru survey adapter (companion repository).
- [ ] Retention factors.
- [ ] H-AR reference table.
- [ ] Prevalence by persons.

## v1.0
- [ ] `codemeta.json`, pkgdown site, badges.
- [ ] rOpenSci review (standard software review), then CRAN; software paper (JOSS).
