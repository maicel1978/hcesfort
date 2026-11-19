# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A3.1 and A3.2). Stopped above half the context,
  by the same-model rule of `docs/model-routing.md`.
- **Branches:** `claude/adoring-fermi-kj5m7d` in `hcesfort` (this handoff,
  roadmap, improvements) and in `hcesfort.engih2018` (the code), both
  pushed. Nothing is merged into `main` of either repository.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before lint.
- **Earlier handoffs:** `git show c0aa058:docs/handoff.md` (A2.8 and the
  maintainer's answers on P234 and P236).

## What was done (in `hcesfort.engih2018`, tests only; `R/` unchanged)

| Commit | Content |
|---|---|
| `f938fe5` | `helper-chain.R`: `step1_args` (the hcesfort arguments of S2, S6 to S9, S11, S13, S21, S24), `run_chain(survey, tables)` returning every stage, `acceptance_chain(options)` cached per set of options. `test-acceptance-chain.R` runs it in CI on the invented sheets with the real tables. |
| `d34f30e` | `helper-stages.R` (package side of e01, e03, e04_afe, e04_gramos_por_ema, e04_agotamiento, e07, with the names of the export script); `helper-compare.R` (`compare_stage()`, tolerances of design 4.1 by kind of measure, `expect_comparison()`, results of the run); `records_chain()` / `acceptance_records()`: all records before the non-food drop, as stage 01 saw them. P235 closed in the A2 test. |
| `678661f` | `helper-stages-intake.R`: e05_ingesta (four section variants, intake on the composition as it is), e05_cobertura, e06_vehiculos (the 75 + 2 vehicle foods), e06_escenarios. `acceptance_sheets()`: the sheets verified and read once; every set of options is built from them, and a test checks that `engih2018_survey()` gives the same survey. |

Tests: 453 pass, 15 skipped here (they need `ENGIH2018_DATA`). Lint clean.
`devtools::check()` not run (once at the end of A3).

**The stage comparisons have never met the microdata.** They were run
here with the cache filled by the invented survey: every comparison ran to
the end, every measure of the ten stage tables found its package
counterpart by name (no measure missing on either side), and the figures
differ, as expected. The script of that smoke run is
`data-raw/acceptance/smoke_acceptance.R` of the adapter; run it after any
change of the comparisons.

Choices made in the comparisons, each written in a comment of the helper:

- Outlier counts take only records with an outlier group (the original
  never judged a record without a match, P232). A test checks that the
  flags of the chain equal those of all the records.
- e01, e03, e04_gramos_por_ema, e05_cobertura and e06_vehiculos are
  computed on all the records, non-foods included (the original's files
  hold them); e05_ingesta, e06_escenarios and e07 on the chain.
- e03: groups are counted by rows and by values, so U1 and U2 are
  compared. e04_afe: `sin_ema` is the members without age or sex (the
  package has no AFE per person); the four `*_no_constante` are 0 by
  construction of the household table.

## Exact next step

1. **Maintainer:** run the stage comparisons on the microdata (review
   point 1) and give the next session the CSV files of the comparisons
   that fail.
2. **A3.3** (Opus): the six control files (design 4.2), all rows, with the
   threshold count of 4.1; one commit per file or two, in a new
   `test-acceptance-controls.R` with the helpers above
   (`compare_stage()` takes a wide table and its keys; `read_control()`
   reads the six files). Read first: design 4.1, 4.2 and 4.4, and the help
   of `inadequacy()`, `above_ul()`, `estimate_households()`,
   `estimate_difference()`, `nutrient_density()`, `food_group_shares()`,
   `flag_precision()` before calling them. If a stage of review point 1
   fails, fix that first: a cause in the test (a measure mapped wrongly)
   is fixed here; a cause in the package or the adapter with no obvious
   reason goes to Fable (stop rule of 4.4). Never widen a tolerance.
3. **A3.4**: self-review of A3, `devtools::check()` and lint once.

## Open questions

1. **Where each acceptance run writes its results.** Done as
   `tests/testthat/_acceptance/` (ignored by git and by the build), or the
   directory named by `ENGIH2018_RESULTS`: one CSV per comparison and
   `sessionInfo.txt` with the versions of `hcesfort` and the adapter.
   Recommended: keep it, because the files sit next to the tests that
   wrote them and need no setting. Alternative: a dated subdirectory per
   run, to keep the history of runs.

**Run of the maintainer (2026-11-19, A3.1 and A3.2):** on the microdata,
`devtools::test(filter = "acceptance")` with the adapter at 1aefc22 and
`hcesfort` at 14b3cf9 gave FAIL 0, WARN 0, SKIP 0, PASS 40 in 279 s
(acceptance-a2 15, acceptance-chain 14, acceptance-stages 11: e01, e03,
e04 afe, gramos_por_ema and agotamiento, e05 ingesta and cobertura, e06
vehiculos and escenarios, e07 diseno). Result files written in
`tests/testthat/_acceptance/` (one CSV per comparison and `sessionInfo.txt`).
Next: A3.3, the six control files.

## Recommended model for the next session

**Opus** (A3.3; the stage failures of review point 1, if any, unless the
cause is not obvious).

## Maintainer review points

1. **The stage comparisons on the microdata** (expect 0 failed; a failure
   lists the figures that differ; send the CSV of each failing
   comparison):

   ```r
   # in hcesfort.engih2018, with hcesfort installed from its branch
   # claude/adoring-fermi-kj5m7d or main
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance")
   list.files("tests/testthat/_acceptance")
   ```

2. **The tolerances of design 4.1 as the comparisons apply them** (one
   row per measure of each stage table, with its kind):

   ```r
   x <- read.csv("tests/testthat/_acceptance/e05_ingesta.csv")
   table(x$medida, x$kind)
   ```

3. **One stage figure by hand**: the purchased grams per day of Section 3A
   (e01, `suma_g_dia_comprado`, 51,354,042.95 in the original) against
   the chain:

   ```r
   devtools::load_all()
   for (f in list.files("tests/testthat", "^helper", full.names = TRUE)) {
     source(f)
   }
   r <- acceptance_records()$records  # non-foods included, as in A1
   sum(r$qty_g_d[r$section == "sec3a"], na.rm = TRUE)
   ```
