# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A3.5a).
- **Branches:** `claude/sleepy-feynman-dduxu5` in `hcesfort` (this handoff,
  roadmap, improvements, a note in design 4.2) and in `hcesfort.engih2018`
  (the test helpers), both pushed. They continue
  `claude/elegant-pasteur-da2bt2`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before lint.
- **Earlier handoffs:** `git show d6e52f0:docs/handoff.md` (A3.3, A3.4 and
  the maintainer's run: 13 of 15 control comparisons pass).

## What was done (in `hcesfort.engih2018`, tests only; `R/` unchanged)

The S22 mismatch, without the microdata. Diagnosis (P241, a hypothesis to
confirm):

- The stages agree, so the package's totals are those of 05. A share
  that rises in the package while every other falls means records that
  `08_grupos_alimentos.R` lost, here dairy: with the reported figures the
  package equals the original plus dairy records worth about 12% of the
  vitamin D total (3.5% B12, 2.8% vitamin A, 0.13% folate, 0.04% iron).
- 08 joins `agrupacion_alimentos.csv` by `(seccion, descripcion)` and
  drops the records whose text finds no row; the adapter joins by code.
  The text is one to one with the code on the records (`e01_descripciones`),
  but may differ from the table's (`LECHE LíQUIDA`, Section 2, is a
  candidate). Not checked: it needs the microdata.

| Commit | Content |
|---|---|
| `8e7c36c` | `helper-controls-groups.R`: `group_join_codes()` (per code: text of the records, text of the table, group by code and by text), `group_join_differences()`, `step1_food_groups()`. `group_shares()` takes `food_groups`; `control_groups()` leaves out `unclassified`. The S22 test uses the groups of the original's join, writes `grupos_codigos.csv`, and requires every `unclassified` code to be one the original drops. `test-acceptance-groups.R` (CI): the join on invented sheets, the two stop cases, and the shares against the weighted sums of 08 (1e-8). The smoke run caches the sheets. |

Tests: 504 pass, 22 skipped here. `lintr::lint_package()` clean;
`devtools::check()` 0/0/0 in the adapter.

## Exact next step

1. **Maintainer:** run the S22 comparison on the microdata (review point
   1) and send `grupos_codigos.csv` and, if it fails,
   `grupos_micronutrientes.csv`.
2. **If it passes:** A3 closes (all six control files). Record the new
   error (P242) in `docs/analysis-map.md` with the codes and records of
   `grupos_codigos.csv`, then A4 (P239 first).
3. **If it fails:** the codes of `grupos_codigos.csv` say whether the
   text join is the cause. If no code with composition differs, the cause
   is elsewhere: hand to Fable (stop rule of design 4.4). Never widen a
   tolerance.

## Open questions

None new.

## Recommended model for the next session

**Opus** (close A3 with the maintainer's files, or Fable if S22 still
differs with no code of `grupos_codigos.csv` to explain it).

## Maintainer review points

1. **The S22 comparison on the microdata** (expect 0 failures; about two
   minutes):

   ```r
   # in hcesfort.engih2018, branch claude/sleepy-feynman-dduxu5, with
   # hcesfort installed from the same branch name
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-controls")
   read.csv("tests/testthat/_acceptance/grupos_codigos.csv")
   ```

2. **The codes the original groups otherwise or drops**: in
   `grupos_codigos.csv`, `description` (records) against
   `table_description` (`agrupacion_alimentos.csv`). Expected: dairy codes
   whose two texts differ in a character, and the Section 2 codes without
   a description (no composition, so they change no share).

   ```r
   g <- read.csv("tests/testthat/_acceptance/grupos_codigos.csv")
   g[order(-g$records), c("food_code", "description",
                          "table_description", "group_code", "records")]
   ```

3. **The join on invented sheets** (runs without the microdata):

   ```r
   devtools::test(filter = "acceptance-groups")
   ```
