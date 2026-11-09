# Roadmap

Work only on the first open task. Each task ends with a clean `devtools::check()`, commit and push.

## v0.1: core validated against ENGIH 2018
- [ ] 0. **Read the whole analysis** (`analisis_ENGIH2018`: README, scripts 00–09 and annexes, parameter CSVs in `data/raw/`, `data/auditoria/cifras_control/LEEME.txt`). Write `docs/analysis-map.md` with:
  - each step of the analysis and the package function that will cover it;
  - each methodological decision and threshold, with script and line;
  - what is ENGIH-specific (adapter) and what is generic (core);
  - errors or inconsistencies found.
  No package code in this task. Maintainer review before continuing.
- [ ] 1. Skeleton: `DESCRIPTION`, MIT licence, testthat 3, roxygen2 markdown, `NEWS.md`, `.gitignore` with `data-raw/private/`, GitHub Actions (R CMD check on three OS, test coverage, lint). Confirm the name is available on CRAN.
- [ ] 2. Data contracts: schemas of the standard tables, validation function, classed errors, audit-log format.
- [ ] 3. Reference data with sources in `data-raw/` (EAR, UL, reference energy, WHO 2009 levels, iron requirement distribution).
- [ ] 4. `compute_afe()`.
- [ ] 5. `convert_units()` and `link_composition()`, with audit log.
- [ ] 6. `apparent_intake()`, with the section-combination rule as an adapter option.
- [ ] 7. `apply_scenario()`, including replacement of enriched foods.
- [ ] 8. `inadequacy()` and `above_ul()`.
- [ ] 9. `estimate()` and `paired_difference()` on a complex design.
- [ ] 10. ENGIH 2018 adapter and local acceptance test against the control figures (needs the microdata).
- [ ] 11. Vignette in English and Spanish: from survey files to risk by scenario. pkgdown site.

## v0.2: Peru and the article's open criticisms
- [ ] Peru survey adapter.
- [ ] Retention factors and partial compliance.
- [ ] H-AR.
- [ ] Prevalence by persons.
- [ ] Food groups and maps.

## v1.0
- [ ] rOpenSci review or CRAN submission; software paper (JOSS).
