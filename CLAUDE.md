# CLAUDE.md

`hcesfort` is an R package to estimate apparent micronutrient intake and model food fortification scenarios from Household Consumption and Expenditure Surveys (HCES). First case: ENGIH 2018 (Dominican Republic). Next: Peru.

## Read before working
- `docs/specification.md`: purpose, architecture, principles.
- `docs/analysis-map.md`: mapping from the ENGIH 2018 analysis to the package, with the errors found (E1–E26).
- `docs/roadmap.md`: tasks in order; work only on the first open task.
- `docs/improvements.md`: proposals, their status and the decisions taken.

## Scope of the package
- The core is survey-agnostic: no survey, country, food list or fixed set of nutrients in `R/`. It must adapt to any HCES through tables that satisfy the contracts.
- What is external stays external: no microdata, composition tables, crosswalks, unit catalogues or national standards in this repository. Survey adapters and their data live in companion repositories. The package ships only small generic reference tables with their source, each replaceable by argument, and a synthetic example dataset.
- The package plugs into the ecosystem: tidy tibbles in and out, variance through `survey`/`srvyr`, results ready for `ggplot2`. No plotting or mapping functions are exported.

## Language
Code, identifiers, roxygen documentation, tests, commit messages and docs/ in English. A Spanish version of the main vignette is added in task 12. Talk to the maintainer in Spanish.

## Source of the method
The repository `maicel1978/analisis_ENGIH2018` (branch `main`) is the origin of the method and the validation reference. Its code may be reused. When porting a function: generalise it (no ENGIH variable names or codes in the core), add tests, and state the source script and function in the commit message (`Ported from scripts/05_ingesta_micronutrientes.R::estimar()`).

Known errors of the original analysis are not ported: they are fixed and recorded in `NEWS.md`. Example: the food-group shares were computed with the composition of enriched foods (US-style enriched rice and pasta), not with the unfortified baseline.

## Defensive programming (mandatory)
- **Data contracts.** The standard tables (`households`, `members`, `acquisitions`, composition, scenarios) have a documented schema. Every core function validates its input first: columns, types, units, unique keys, plausible ranges.
- **Classed errors.** `rlang::abort()` (or `cli::cli_abort()`) with a package class (`hcesfort_error_schema`, `hcesfort_error_join`, `hcesfort_error_units`, …) and a message stating what failed, where, and how to fix it.
- **Checked joins.** Every join declares its expected cardinality and fails otherwise (`dplyr::join_by()` with `relationship =` and `unmatched =`, or an explicit check). Records are never dropped or duplicated silently.
- **Nothing silent.** No implicit `na.rm = TRUE`, no unreported filters. Every exclusion (records without composition, outliers, households without intake) is counted in an audit log returned with the result.
- **Explicit units.** Column names carry the unit (`iron_mg`, `folate_ug_dfe`, `qty_g`). No implicit conversions.
- **Reproducibility.** Files registered by the package or by an adapter (microdata, reference tables in `data-raw/`) are verified by md5; the check is available, and optional, for the user's own files. Reference values carry their source.
- **Detect, then decide.** Flags (outliers, implausible energy, stored purchases) are computed by one step and acted on by another, explicit one. No threshold is a hidden default.

## Size and verification (against hallucination)
- Functions of at most 40 lines of body (roxygen and blank lines not counted); files in `R/` of at most 300. Split anything larger. The limits are enforced by a linter or a test, not by eye.
- A commit changes at most 300 lines of code (tests, docs, generated files and reference tables entered in `data-raw/` excluded). Large tasks are split into several commits.
- Never claim something works without running it: every claim is backed by a test or by the output of `devtools::test()` / `devtools::check()`.
- Never call a function from another package without checking that it exists and how it is called (`?pkg::fun`, or by running it).
- Every reference value or citation has a verifiable source. If it cannot be verified, write `# SOURCE PENDING` and say so. Never invent it.

## Questions
On any doubt about method, data or scope: stop and ask. Ask all questions at once, numbered, each with the recommended option and why. Never choose an interpretation silently. While waiting, continue with work that does not depend on the answer.

## Self-review at the end of each task
Before the last commit of a task, review the work as an rOpenSci reviewer would: correctness, edge cases, error messages, naming, duplication, dependencies, performance. Fix what is in scope. Record the rest in `docs/improvements.md` with a priority (high, medium, low) and the roadmap task where it would fit.

## Quality
- Standard package layout: `R/`, `tests/testthat/` (edition 3), roxygen2 with markdown, `data-raw/`, `vignettes/`.
- Minimal dependencies. Imports: dplyr, tidyr, rlang, cli, survey, srvyr (plus base `stats`, `tools`, `utils`). Suggests: testthat, knitr, rmarkdown, withr, ggplot2 (vignettes only). Justify any other in the commit message.
- Tests: each function with normal, edge and error cases (assert the error class). Coverage ≥ 90%.
- Before each commit: `devtools::document()`, `devtools::test()` and lint of the changed files. Before each push and at the end of each task: `devtools::check()` with 0 errors, 0 warnings, 0 notes, and `lintr::lint_package()` clean. CI on Windows, macOS and Linux enforces the same.
- Style: tidyverse style guide; `snake_case`; exported functions prefixed only when needed to avoid clashes.

## Non-negotiable rules
- No microdata in the repository: not in tests, examples or vignettes. `data-raw/private/` is in `.gitignore`.
- Tests use minimal hand-built households, documented as test fixtures, with the expected result computed by hand inside the test.
- The acceptance test lives in the companion repository of the ENGIH 2018 adapter and runs only locally, with the microdata. Step 1 reproduces `data/auditoria/cifras_control/` of `analisis_ENGIH2018` with the original choices as explicit options (tolerance 1e-6); step 2 corrects each erroneous default and records old and new figures in `NEWS.md`.
- No figure, regulatory level or requirement from memory.
- No personal names in code or documentation, except the authors in `DESCRIPTION`.
