# Handoff

- **Date:** 2026-11-21
- **Model:** Opus 5.5 (A4 closed; 12c.14 started).
- **Branches:** `claude/awesome-fermi-oxv0vv` in `hcesfort` (docs only)
  and in `hcesfort.engih2018`, both pushed, both started from `main`
  (earlier branches are merged).
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint.
- **Earlier handoffs:** `git show 3be3299:docs/handoff.md`,
  `git show 3803b9e:docs/handoff.md`.

## What was done

1. **A4 closed.** Adapter `f86e4b2`: S25 figures of the run on `10f77c2`
   in `NEWS.md`. The 23 result files of the maintainer's commit
   `c8fcd78` raised a NOTE in `check()` (installed size 6.7 Mb,
   `acceptance` 4.5 Mb) and broke `test-checksums.R` (not registered).
   Moved to `acceptance-results/step2/` in the root, in `.Rbuildignore`
   (`d8a8637`), with a README: they are a record of a run, read by no
   code or test; `inst/` stays the installed, md5-frozen content (keeping
   them in `inst/` but build-ignored would make the source tree and the
   installed package differ inside a frozen folder).
   `test-no-microdata.R` still checks them. Adapter `check()` 0/0/0;
   `devtools::test()` FAIL 0, PASS 779, SKIP 43; lint clean. P254
   (small cells and the INCAP licence before going public).
2. **12c.14a.** Adapter `64d6491`: `inst/report/{es,en}/labels.csv`,
   69 rows each, every code of the original, corrected and all-vehicles
   tables, tested (`test-report-labels.R`, 11 expectations).

## Findings that shape 12c.14

- `engih2018_options("corrected")` cannot build tables: `dozen = "count"`
  and `levels = "standard"` are refused until their data have a source.
  The state after the last step of step 2 is `corrected` with
  `dozen = "mass"`, `levels = "nutrient"` (checked: the only two
  differences).
- The template's chain (`_chain.R`, `_results.R`) fixes the corrected
  method for: intervals (Korn-Graubard, E24), consumers of a vehicle
  (`vehicle_coverage()`, E5), the amount compared with the UL
  (`above_ul()`, E7) and the food-group shares (by code, on the
  baseline; E30, E1). The original's versions exist only in the
  adapter's test helpers. `_inputs.R` can set: tables (so the baseline
  of `replace_by_ingredient`, pre-computed, with an empty enrichment
  table), `make_afe()` (S7, S9), `make_grams()` (S2, S6: outliers as
  `include = FALSE`, checked on `hces_example`), `fortifiable_choice`
  (S13), `compliance_model`, and `choices`.
- `GRUPO_REGION` is coded in the invented sheets ("1", "2"); the real
  coding is unknown here. The original's outputs say "Este", "Gran Santo
  Domingo", "Norte o Cibao", "Sur"; no script of `analisis_ENGIH2018`
  maps codes to names.
- With water as a food (original), 56% of the Section 3A grams are
  unlinked: any `min_linked_share` above about 0.44 disables the
  results of the original report.

## Open questions (asked in chat, 2026-11-21)

1. Original report: data options and settable chain choices of the
   original; intervals, consumers, UL amount and group shares follow
   the template (corrected), stated in `decisions.csv`. Recommended: yes;
   reproducing those errors would put them back in the core.
2. Corrected report = state after the last step of step 2 (`dozen =
   "mass"`, `levels = "nutrient"`); no render of the E8 sensitivity.
   Recommended: yes.
3. Thresholds: `min_coverage = 0`, `min_records_used = 0` (step 2
   decision) in both; `min_linked_share` the same in both, value yours
   (template example 0.9, no source). With 0.9 the original report
   disables its results (water). Recommended: same values in both.
4. Energy 500 to 6000 kcal (original, no source), `energy_action =
   "exclude"` in both. Recommended: yes.
5. Domains region, area, quintile; equity domain quintile; province out
   (32 cells). Quintile of what (income or expenditure per capita)?
6. Nutrients: the seven of the original; iron bioavailability 0.10, with
   0.18 as sensitivity (the original's two values). Recommended: yes.
7. Region names: is `GRUPO_REGION` text or a code in the microdata? If a
   code, which document gives the names?
8. Output: exported `engih2018_report(dir, preset, lang)` prepares the
   folder; the maintainer renders with `quarto render`. Both languages.
   Recommended: yes.

## Exact next step

12c.14b with the answers: `inst/report/_inputs.R` of the adapter, then
12c.14c and 12c.14d (roadmap).

## Recommended model for the next session

**Opus.**

## Maintainer review points

1. **Step 2 results out of the build:**

   ```r
   # in hcesfort.engih2018
   devtools::check()   # 0 errors, 0 warnings, 0 notes
   list.files("acceptance-results/step2")
   ```

2. **The labels of the reports, read by hcesfort:**

   ```r
   x <- hcesfort::read_labels("inst/report/es/labels.csv")
   x[x$type %in% c("scenario", "source"), c("code", "label", "short_label")]
   ```
