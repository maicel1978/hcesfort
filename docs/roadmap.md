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
- [ ] 4. Reference data with sources in `data-raw/` (EAR, UL and the form it applies to, energy requirements, WHO 2009 levels, iron requirement distribution, DFE and RAE factors). Unverifiable values stay `# SOURCE PENDING` and are not shipped.
- [ ] 5. `adult_equivalents()`.
- [ ] 6. `convert_units()` (typed factors) and `flag_outliers()`.
- [ ] 7. `link_composition()` and `fill_composition()`, with coverage over all records; `unmatched_foods()` (P42, part a).
- [ ] 7b. `check_crosswalk()`: quality controls of the crosswalk as flags, thresholds given by the caller (P42, part d).
- [ ] 8. `apparent_intake()` with the `include` flag, household status and energy-plausibility flag; `nutrient_density()`.
- [ ] 9. `unfortified_baseline()`, `apply_scenario()` (level basis, compliance) and `vehicle_coverage()`.
- [ ] 10. `inadequacy()` and `above_ul()`.
- [ ] 11. `as_hces_design()`, `estimate_prevalence()` and `estimate_difference()` on a complex design, subsets as domains.
- [ ] 12. Vignettes in English and Spanish: from standard tables to risk by scenario (synthetic data); how to write an adapter; plotting results with `ggplot2`. The pkgdown site waits for v1.0.

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
- [ ] Food-group shares, on the baseline composition and with the design.

## v1.0
- [ ] `codemeta.json`, pkgdown site, badges.
- [ ] rOpenSci review (standard software review), then CRAN; software paper (JOSS).
