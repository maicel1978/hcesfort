# Handoff

- **Date:** 2026-11-14
- **Model:** Opus (steps 12d.7 to 12d.10).
- **Branch:** `claude/read-routing-docs-ypdlx6` (starts from `639fb9b`, the
  previous handoff; `main` is not updated by this session). Merge it into
  `main` before the next session, or continue on it.
- **Environment:** `hcesfort`. `tinytable` installed by hand again at the
  start (P126 stays open until the setup script is edited; `tinytable` is
  now in Suggests and the knit tests skip without it).

## What was done

| Commit | Step |
|---|---|
| `8e4fba9` | 12d.7: the 40-household dataset becomes the test fixture `hces_fixture()` (identical tables); P131 recorded as resolved |
| `32711d5` | 12d.7: `data-raw/example_foods.csv` (46 invented foods, zinc added per V-D8); households and members of the generating script |
| `a87d618` | 12d.8: acquisitions, planted defects, expenditure quintiles, user tables in the script; calibration |
| `8cebb8c` | 12d.8: the realistic `hces_example` shipped (2,000 households); documentation, NEWS, template labels; K27 test |
| `811a6d0` | Roadmap; P133–P135 |
| `46ed02b` | 12d.9: golden values on both datasets, with Korn-Graubard limits and presentation status |
| `d2c37d7` | 12d.10, part 1: `presentation_standard` and the new `choices` in the template |
| `d9bd083` | 12d.10, part 2: `exhibits.csv`, `_exhibits.R` (`show_exhibit()`, titles, notes, appendix), `tinytable` |
| `2256576` | 12d.10, part 3: `fig_effect()`, `fig_histogram()`, stylesheet; P136–P139 |
| last commit | Handoff |

`devtools::check()` after the last code commit: 0 errors, 0 warnings, 0
notes (6.8 minutes, was 4.3; P135). `lintr::lint_package()`: no lints.
One skip (Quarto not installed).

Facts found on the way:

- **Calibration of the example** (checked by `test-example-data.R`):
  median energy 2,390 kcal per AFE (reference 2,291); baseline inadequacy
  folate 33%, iron 78%, vitamin A 74%, zinc 34%, each falling from Q1 to
  Q5; among households with energy 500–6,000 kcal only folic acid passes
  its upper level (9 households, from `plus_rice` on). To get there the
  scenario levels were tuned (rice carries no zinc) and the planted
  extreme quantities are ten times too large, not a hundred.
- **Golden script bug, fixed in the script:** a first draft capped the
  effective sample size at `n` before the degrees-of-freedom factor; C2
  caps after, as the package does. The package agreed with C2.
- `wheat_flour` is both a vehicle and a vehicle group (P134); the rows are
  told apart by `level`.
- The reports still print through `show_legacy()`; the 26 builders named
  in `exhibits.csv` are written in 12d.11 and 12d.13 (P137).

## Open questions

1. **P133. Expenditure quintile of non-respondents.** Implemented: missing
   for the 31 households that did not answer the food module (their food
   expenditure is unknown), so they form one more cell (P131).
   *Recommended: keep.* Alternative: a quintile from a total-expenditure
   variable known for every household.
2. **P136. No household without a vehicle.** R1.4 shows only its
   zero-event sentence. *Recommended: lower `p_acquire` of rice, oil and
   sugar slightly in 12d.11* and re-check the calibration bands.
3. **P138. Thousands mark in Spanish.** Shipped as "," in both languages
   (one line of `terms.csv`). *Recommended: keep.*

## Exact next step

**12d.11** (Opus): readiness report in English on the registry — builders
of D1 to D10 and DA1 in `_readiness.R`, `en/readiness.qmd` reduced to
headings, free text and `show_exhibit()` calls; K17 and K18 (section 4.1
of `docs/design-reports-v3.md`). Then 12d.12 (Spanish).

## Answers of the maintainer (2026-11-14, after 12d.10)

1. **P133:** accepted as recommended (non-respondent households form the missing-value cell of the expenditure group, labelled from `terms.csv`).
2. **P136:** accepted as recommended: lower the purchase probability of rice, oil and sugar in 12d.11 so that exhibit R1.4 has a nonzero estimate, and re-check the calibration test.
3. **P138:** accepted as recommended: decimal point and comma as thousands mark in both languages (Dominican usage), from `terms.csv`.

Record these in `docs/improvements.md` with the first commit of 12d.11.

## Recommended model for the next session

**Opus** (12d.11 onwards). This session stops near half of its context,
at the end of 12d.10, before the reports are rewritten.

## Maintainer review points

1. **The realistic example reads like a survey:**

   ```r
   devtools::load_all()
   e <- hces_example
   n <- nutrient_registry(e$nutrients)
   g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
   b <- unfortified_baseline(e$composition, e$enrichment, n)
   afe <- adult_equivalents(e$members,
     reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
     weight_kg = c(female = 55, male = 65), pal = 1.76)
   intake <- apparent_intake(link_composition(g, e$crosswalk, b), afe,
                             e$households)
   table(intake$intake_status)
   d <- as_hces_design(e$households, lonely_psu = "adjust")
   x <- intake[intake$intake_status == "estimated", ]
   estimate_households(d, x, "energy_kcal", statistic = "median",
                       by = "region")
   ```

2. **Korn-Graubard and the presentation status on both datasets** (the
   fixture is suppressed for folate and flagged for review for iron; the
   example presents both):

   ```r
   read.csv("tests/testthat/fixtures/golden-fixture.csv")[12:25, ]
   read.csv("tests/testthat/fixtures/golden-example.csv")[13:26, ]
   ```

3. **Render the results report with Quarto** and look at the marks, the
   zero-event sentences and the Word export of a `tinytable` table
   (condition of V-D1):

   ```r
   dir <- file.path(tempdir(), "report")
   use_report_template(dir, "en")
   quarto::quarto_render(file.path(dir, "results.qmd"),
                         output_format = "docx")
   ```
