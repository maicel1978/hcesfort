# Handoff

- **Date:** 2026-11-12
- **Model that worked:** Opus 5.5
- **Branch:** `main`

## What was done

| Commit | Content |
|---|---|
| `9407338` … `381d6dd` | Task 2 complete (contracts, classed errors, audit log, validators, nutrient registry); see `git log` and `NEWS.md`. |
| `eb27adc` | Maintainer's decisions P43 (later product named `hces_nutrient_content`) and P44 (`validate_crosswalk()` rejects a validated row without `composition_id`); same-model rule in `docs/model-routing.md`. |
| `ccdb956` | Task 3: `hces_example`, synthetic dataset built by `data-raw/hces_example.R` (deterministic, md5 `b41b24c39dbeefccfb045c59d81125b3`), tests that it passes every validator with the planted notes. |

On `ccdb956`: `devtools::check()` 0/0/0; `lintr::lint_package()` clean.

Environment notes: run checks as
`LANG=C.UTF-8 LC_ALL=C.UTF-8 _R_CHECK_SYSTEM_CLOCK_=0 Rscript -e 'devtools::check()'`;
run `devtools::document()` with the same `LANG`/`LC_ALL` (otherwise the
author's accents are escaped in `man/hcesfort-package.Rd`); `lintr` needs
`R CMD INSTALL .` first.

Why the session stopped: the context used was estimated near 50%, the
threshold of the same-model rule. Task 4 needs much reading.

## Exact next step

Task 4: reference data with sources in `data-raw/` (EAR, UL and the form it
applies to, energy requirements, WHO 2009 levels, iron requirement
distribution, DFE and RAE factors).

1. Attach `maicel1978/analisis_ENGIH2018` (branch `main`) with the
   `add_repo` tool, read access, and list `data/raw/`. Values come only from
   its parameter files or from a document opened in the session
   (`CLAUDE.md`, Verification).
2. One CSV per table in `data-raw/`, with a `source` column; `data-raw/SOURCES.md`
   lists each value with document, table or page, and status (`verified`
   or `pending`). Pending values are `# SOURCE PENDING` and are not shipped.
3. Shipped tables go to `R/sysdata.rda` or `data/` (decide by whether
   users call them directly; each replaceable by argument), with md5 of
   each `data-raw/` file checked by a test.

## Open questions

None.

## Recommended model for the next session

**Opus 5.5**: task 4.

## Maintainer review points

1. **The synthetic data look invented, not real.** Read the composition
   and scenario values and check that nobody could take them for a real
   table or standard:

   ```r
   library(hcesfort)
   hces_example$composition
   hces_example$scenarios
   ```

2. **The planted cases are where the documentation says.**

   ```r
   s <- validate_survey(hces_example$households, hces_example$members,
                        hces_example$acquisitions)
   lapply(s, audit_log)
   ```

3. **P44 in action**: a validated row without a match is now an error.

   ```r
   cw <- hces_example$crosswalk
   cw$composition_id[1] <- NA
   try(validate_crosswalk(cw))
   ```
