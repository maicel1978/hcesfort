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

A3 step 1 passed on the microdata (15/15; see the runs below). Now:

1. Record P242 in `docs/analysis-map.md` as a new E error of the original
   (code `S2:13 LECHE LÍQUIDA`, 1,913 records dropped by the text join of
   `08_grupos_alimentos.R`; only the group shares move), and in
   `docs/improvements.md`.
2. **A4, acceptance step 2** (Opus, high effort): correct each erroneous
   default of the original, **one per commit**, P239 first, then the order
   of the design. For each: the option in `engih2018_options()`, a test,
   and old and new figures in `NEWS.md` of the adapter. Values without a
   checkable source follow the maintainer's rule above (never invent; keep
   the original and show the sensitivity).
3. The maintainer runs the acceptance on the microdata after each group of
   corrections; write in the handoff exactly what to run and what to send.
   Stop and hand off near 50% of context; never widen a tolerance.

## Open questions

None new.

**Run of the maintainer (2026-11-19, A3.5, adapter 8e7c36c):**
`devtools::test(filter = "acceptance-controls")` gave FAIL 0, PASS 15.
`grupos_codigos.csv` has one row: `S2:13 LECHE LÍQUIDA`, 1,913 records,
grouped `04 Lácteos` by code but dropped by the text join of
`08_grupos_alimentos.R` (the table writes `LECHE LíQUIDA`). **Acceptance
step 1 is closed.** Record the error of the original as P242 (a new E
error, corrected in A4 together with E1 in the group shares).

**Maintainer request for the roadmap (2026-11-19):** after A4, a module of
the package that makes the preprocessing of a new survey more human and less
error-prone: text keys normalised before any join (case, accents,
spaces), joins by code with the unmatched listed, and a report of every
description that a table spells differently. Record it as an item with
priority high, for v0.2, next to the food-matching support module.

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
