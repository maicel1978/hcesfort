# Handoff

- **Date:** 2026-11-14
- **Model:** Opus (step 12d.11).
- **Branch:** `claude/sharp-ride-scd9cp` (starts from `30d8933`, the
  previous handoff). Merge it into `main` before the next session, or
  continue on it.
- **Environment:** `hcesfort`. `tinytable` installed by hand at the start
  (P126 stays open until the setup script is edited).

## What was done

| Commit | Step |
|---|---|
| `9bfc76f` | 12d.11, part 1: `show_exhibit()` takes `headers`, `lead`, `after`; `fill()`; `_verdict.R` (D1 and its three-sentence summary); terms of the readiness exhibits (en, es); integer breaks on the queue curve; maintainer answers recorded (V-D17 to V-D19); P140 |
| `98a3d34` | 12d.11, part 2: builders D2 to D10 and DA1 in `_readiness.R`; `readiness.qmd` (en and es) reduced to headings and `show_exhibit()`; tests with exhibit IDs; K17, K18 |
| last commit | Spanish note says "Cuadro DA1"; roadmap; handoff |

`devtools::test()`: 0 failures, 1 skip (Quarto not installed).
`devtools::check()` after `98a3d34`: 0 errors, 0 warnings, 0 notes (8.4
minutes with the lint; P135). `lintr::lint_package()`: the changed files
are clean; 13 `object_usage_linter` warnings in test files this step did
not touch (`helper-linkage.R`, `test-example-data.R`,
`test-golden-example.R`: `hces_fixture`, `hces_example`, `expect_equal`
"not visible"). They depend on how the package is installed in the
session (after a plain `R CMD INSTALL`); the previous session reported
none. Check them in CI before taking them as real.

Facts found on the way:

- **The Spanish readiness report is done in code.** The test "the reports
  run the same code in every language" forces both `.qmd` files to change
  together, so 12d.11 wrote both; every word is in `terms.csv`. 12d.12 is
  left with reading the Spanish render and its wording.
- **Tables are stored under their exhibit ID** (`tables$D1`,
  `tables$D8_area`, …), no longer under names such as `tables$verdict`.
- **In `hces_example` the unlinked share differs from the rest for area
  and for expenditure quintile**, so D8 is printed for those two and the
  sentence names region. K18 tests the no-difference case with
  `choices$domains <- "region"`.
- The D9 histogram reaches about 13,000 kcal: a planted extreme
  quantity. It is left visible on purpose (a data-quality figure).
- The domain label in a title keeps its capital ("by Area"), as the
  exhibit test of 12d.10 expects; settle it in the wording pass (12d.14).

## Open questions

1. **P140. R1.4 cannot get a nonzero estimate as P136 was accepted.**
   Every household with food records acquires at least two of the eight
   vehicle foods; lowering rice, oil and sugar to 0.85 raises the chance
   of acquiring none only to about 1 in 70,000. *Recommended: (a) add to
   the generating script about 1% of households with a short food list
   (no staple bought), drawn before the food loop,* and re-check the
   calibration test and the golden values. Alternatives: (b) lower all
   eight vehicle foods strongly (distorts R1.1); (c) keep R1.4 on its
   zero-event path. Needed before 12d.13.

## Exact next step

**12d.12** (Opus or Sonnet: wording only): render the Spanish readiness
report, read it, settle its wording against section 8 of
`docs/design-reports-v3.md`. Then **12d.13** (Opus): results report in
English, builders R0 to RT3 in `_results.R` (K19 to K26), with P140
applied as the maintainer decides.

## Answers of the maintainer (2026-11-14, after 12d.11)

1. **P140:** option (a): about 1% of households with a short food list and no staple purchases, so that R1.4 has a small nonzero estimate. Re-check the calibration test and regenerate the golden values from the independent script.
2. **D9 long tail:** the histogram shows the plausible range used by the readiness checks; households above the upper bound are not drawn but counted in the note ("n households above <bound> kcal, not shown"). Nothing is dropped from the data.
3. **Lint warnings in untouched tests:** confirm on CI after the merge into `main`. If CI also reports them, fix them in the first commit of the next step.

Record these in `docs/improvements.md` with the first commit of the next step.

## Recommended model for the next session

**Opus** (12d.12 is short; 12d.13 is implementation). This session stops
near half of its context.

## Maintainer review points

1. **Read the new readiness report** (verdict first, summary paragraph,
   D8 only for area and expenditure quintile, energy national only):

   ```r
   dir <- file.path(tempdir(), "readiness")
   use_report_template(dir, "en")
   quarto::quarto_render(file.path(dir, "readiness.qmd"))
   ```

2. **The summary of D1 when something is disabled** (one section absent,
   one domain with small cells):

   ```r
   dir <- file.path(tempdir(), "readiness-off")
   use_report_template(dir, "es")
   cat("food_groups <- NULL",
       "presentation_standard$value[presentation_standard$criterion == 'min_n'] <- 450",
       file = file.path(dir, "_inputs.R"), sep = "\n", append = TRUE)
   quarto::quarto_render(file.path(dir, "readiness.qmd"))
   ```

3. **The energy histogram (D9)**: does the long right tail, a planted
   extreme quantity, read as intended, or should the axis stop at a
   multiple of the upper bound (a choice to write in `decisions.csv`)?
   Open `figure/D9.png` in the folder of point 1.
