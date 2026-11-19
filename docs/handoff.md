# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A3.3 and A3.4).
- **Branches:** `claude/elegant-pasteur-da2bt2` in `hcesfort` (this handoff,
  roadmap, improvements, a note in design 4.2) and in `hcesfort.engih2018`
  (the tests), both pushed. Nothing is merged into `main` of either
  repository.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before lint.
- **Earlier handoffs:** `git show 0257950:docs/handoff.md` (A3.1, A3.2 and
  the maintainer's run of the stages: 40/40, 649 rows, 0 failures).

## What was done (in `hcesfort.engih2018`, tests only; `R/` unchanged)

| Commit | Content |
|---|---|
| `cd61a3a` | `helper-controls.R` (riesgo_inadecuacion, diferencias_escenarios), `helper-controls-other.R` (escenarios_resumen, consumo de vehículos, anexo de harina de maíz, grupos, households near a threshold), `compare_control()` and the tolerance of each control column in `helper-compare.R`; `test-acceptance-intervals.R` (runs in CI); `srvyr` in Suggests. |
| `38a3185` | `test-acceptance-controls.R`: the six files, all rows (800 + 336 + 35 + 3 + 8 + 16), U3 (130 zero differences) and `umbrales.csv`. |

Tests: 470 pass, 22 skipped here (they need `ENGIH2018_DATA`).
`devtools::check()` 0/0/0 and `lintr::lint_package()` clean in the adapter.
The smoke run (`data-raw/acceptance/smoke_acceptance.R`) runs every
comparison to the end on the invented survey.

**One finding changes design 4.2 (P237).** In the original, `survey_mean()`
takes the degrees of freedom of the whole design (P188), but
`survey_median()` passes none and `survey::svyquantile()` then takes those
of the households of the group with a value. The medians among consumers
by area and quintile (vehicles, maize flour) are therefore compared with
`df = "domain"`; every other interval with `df = "design"`.
`test-acceptance-intervals.R` checks both against `srvyr` on
`hces_example` and shows that `df = "design"` would give other limits.

Choices of the comparisons, each in a comment of the helpers:

- Cells without variation: limits filled with the estimate (U3), only
  where `interval_note` is `no_variation` or `degenerate_proportion`.
- `pct_sobre_ul`: `above_ul_added` for folate and vitamin A, `above_ul_total`
  for iron, zinc and vitamin D (S18).
- Groups: the group "No alimento" of the adapter is absent from the
  original; the test requires its share to be 0 and leaves it out.
- The folate columns of `escenarios_resumen` are compared on all 35 rows
  (P240).

## Exact next step

1. **Maintainer:** run the control comparisons on the microdata (review
   point 1) and send the CSV of each comparison that fails, with
   `umbrales.csv`.
2. **A3.5** (Opus): fix each failure. A cause in the test (a column or a
   label mapped wrongly) is fixed in the helpers; a figure that differs
   with no household on a threshold, after the stages agree, goes to
   Fable (stop rule of design 4.4). Never widen a tolerance.
3. **A4** once A3 passes: step 2, one correction per commit (design
   section 5). P239 (an invented survey with two PSUs per stratum, so the
   control tests run in CI) fits before it.

## Open questions

None new. Question 1 of the previous handoff (where results are written)
stays as it is: `tests/testthat/_acceptance/` or `ENGIH2018_RESULTS`.

**Run of the maintainer (2026-11-19, A3.3, adapter 38a3185, `hcesfort`
f4cd983):** `devtools::test(filter = "acceptance-controls")` gave FAIL 2,
PASS 13 in 136 s. Passed: `riesgo_inadecuacion` (800 rows),
`diferencias_escenarios` (336, U3), `escenarios_resumen` (35),
`escenarios_consumo_vehiculos`, `anexo_harina_maiz`, households near a
threshold. Failed, both in `grupos_micronutrientes` (S22):

1. `"unclassified" %in% sh$food_group` is TRUE: some records reach
   `food_group_shares()` without a group.
2. 100 of 112 shares differ. Pattern, the same for every nutrient: every
   group is slightly lower in the package (relative 0.04% to 11%) except
   `04 Lácteos`, which is higher (iron 0.425 to 0.467; folate 0.731 to
   0.857; vitamin A 15.76 to 18.04; vitamin B12 17.94 to 20.71; vitamin D
   40.56 to 46.89). Read as a hypothesis to test, not a finding: some
   records are grouped differently (more go to dairy) and some get no
   group, so the join of the records to `food_groups.csv` or the
   composition used in S22 (legacy E1: enriched rice and pasta of the
   crosswalk) does not match `scripts/08_grupos_alimentos.R`. Compare the
   record-level group of the package with the original's before changing
   anything.

Next: A3.5, the S22 mismatch (Opus). The figures of the PMA report other
than the group shares are reproduced.

## Recommended model for the next session

**Opus** (A3.5 with the maintainer's CSV files; Fable only if a failure
has no obvious cause).

## Maintainer review points

1. **The control comparisons on the microdata** (expect 0 failed; the
   first run of the risk file takes a few minutes):

   ```r
   # in hcesfort.engih2018, branch claude/elegant-pasteur-da2bt2, with
   # hcesfort installed from the same branch name or main
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-controls")
   list.files("tests/testthat/_acceptance")
   read.csv("tests/testthat/_acceptance/umbrales.csv")
   ```

2. **The degrees of freedom of a median with an interval** (P237): the
   test that compares with `srvyr` runs without the microdata.

   ```r
   devtools::test(filter = "acceptance-intervals")
   ```

3. **One control figure by hand**: the national share of households
   below the folate EAR, scenario 0, all households (73.0821326803750 in
   `riesgo_inadecuacion.csv`):

   ```r
   devtools::load_all()
   for (f in list.files("tests/testthat", "^helper", full.names = TRUE)) {
     source(f)
   }
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   r <- acceptance_risk()$inad
   i <- r[r$scenario == "0. Sin fortificación" & r$nutrient == "folate", ]
   h <- acceptance_survey("original")$households
   w <- h$weight[match(i$household_id, h$household_id)]
   ok <- !is.na(i$p_inadequate)
   100 * sum(w[ok] * i$p_inadequate[ok]) / sum(w[ok])
   ```
