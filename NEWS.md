# hcesfort 0.0.0.9000

* Package skeleton: licence, tests (testthat 3), roxygen2 with markdown,
  continuous integration on Linux, macOS and Windows, lint, and a test that
  enforces the size limits of `CLAUDE.md` (functions of at most 40 lines of
  body, files in `R/` of at most 300 lines).
* Classed errors: every error of the package has the class
  `hcesfort_error` and one specific class (`?hcesfort_errors`).
* Audit log: tables returned by the package carry a log of what each step
  received, excluded, flagged or filled (`audit_log()`). A change in the
  number of rows made outside the package is recorded at the next step;
  `restore_audit()` re-attaches the log after a verb that drops it.
* Data contracts of the standard tables `households`, `members` and
  `acquisitions` (`hces_schema()`), checked by `validate_households()`,
  `validate_members()`, `validate_acquisitions()` and, across the three
  tables, `validate_survey()`. Missing measurements are counted in the audit
  log; impossible values are classed errors.
* Nutrient registry (`nutrient_registry()`): the user declares the nutrients
  and their units; column names carry the unit (`iron_mg`).
* Data contracts of the user-supplied tables, checked by
  `validate_unit_factors()`, `validate_crosswalk()`, `validate_vehicles()`,
  `validate_composition()` and `validate_scenarios()`. Missing nutrient
  values are counted per nutrient, never read as zero; a scenario without
  `compliance` gets 1 and the assumption is written in the audit log.
* Corrections to the original ENGIH 2018 analysis will be recorded in this
  file, with the figures before and after, as each function is written.
  Errors of the original analysis are not ported; the list of those found is
  in `docs/analysis-map.md` (E1 to E26).
