# Handoff

- **Date:** 2026-11-21
- **Model:** Opus 5.5 (A4.3c: figures of the run on `10f77c2` in NEWS).
- **Branches:** `claude/awesome-fermi-oxv0vv` in `hcesfort` (docs only)
  and in `hcesfort.engih2018`, both pushed; nothing merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint.
- **Earlier handoffs:** `git show 3803b9e:docs/handoff.md` (the run on
  `10f77c2` and the answers on A4.3b), `git show 4407c1f:docs/handoff.md`.

## What was done

1. Adapter `f86e4b2`: `NEWS.md`, S25, with the figures of the run on
   `10f77c2` (53 of 53): 19 water-only households; ratio 1.002151 for the
   share of households with consumers and for grams per AFE among all;
   Section 3A without a validated match, with water 35,275 records
   (10.43%), 56.19% of the grams; without water 27,499 records (8.32%),
   1.91% of the grams. NEWS only, no code: no test run needed.
2. Columns of every file the step 2 run writes, read in the test code:
   none carries a household or person identifier. `step2_<id>.csv`
   (national figures by block and measure), `step2_water_households.csv`
   (count and two ratios), `step2_coverage*.csv` (by section and
   nutrient), `step2_missing_values.csv` (`missing_values()`: nutrient,
   food code, composition ids, counts, grams, shares) and
   `step2_unmatched_foods.csv` (`unmatched_foods()`: food code, status,
   reasons, units, counts, grams, expenditure). All may go to
   `inst/acceptance/steps/` under the maintainer's rule of 2026-11-21.
3. Roadmap: A4.3c annotated (figures done, step files pending).

## Exact next step

1. Maintainer: send the `step2_*.csv` of the run on `10f77c2` (upload
   to the session, or commit them to `inst/acceptance/steps/` of the
   adapter yourself).
2. Next session (Opus): put them in `inst/acceptance/steps/` with a
   short `README.md` (run, commit, one line per file); check columns
   again on the real files; add the directory to the md5 list if the
   adapter registers `inst/acceptance` files (check
   `inst/checksums.csv`); tick A4.3c, A4.3 and A4.
3. Then task 12c, scope per the answer to question 1 below.

## Open questions

1. **What is left of 12c?** Every subtask of 12c (12c.0–12c.13) and of
   12d (12d.0–12d.16) is ticked; the parents stay open for the
   maintainer's render on ENGIH 2018 (acceptance C2 of the v2 design, Q4
   of the v3 design). The adapter has nothing for the reports yet (no
   label table, decisions table or render script). Recommended: the next
   piece of 12c is that render, in the adapter: a script that builds the
   report inputs from `engih2018_survey()` (labels of the food groups,
   domains and vehicles; decisions table) and calls
   `use_report_template()`, run by the maintainer with the microdata.
   Opus implements, since the report contracts are fixed. Confirm, or
   name the part of 12c you meant.
2. Small cells in `step2_missing_values.csv` and
   `step2_unmatched_foods.csv` (rows with `n_households` of 1 or 2):
   publish as they are? Recommended: yes; they are counts by food at
   national level, with no identifier, as the rule of 2026-11-21 allows.

## Recommended model for the next session

**Opus** (step files, close A4, then 12c per question 1).

## Maintainer review points

1. **The S25 figures in NEWS against the run files:**

   ```r
   # in hcesfort.engih2018, with the results directory of the run
   d <- Sys.getenv("ENGIH2018_RESULTS")
   read.csv(file.path(d, "step2_water_households.csv"))
   # 19, 1.002151, 1.002151
   ```

2. **No identifier in the step files before they are committed:**

   ```r
   f <- list.files(d, "^step2_.*\\.csv$", full.names = TRUE)
   cols <- lapply(f, function(x) names(read.csv(x, nrows = 1)))
   names(cols) <- basename(f)
   Filter(function(n) any(grepl("household_id|person_id|member_id|record_id", n)),
          cols)   # expected: empty list
   ```
