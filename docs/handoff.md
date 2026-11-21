# Handoff

- **Date:** 2026-11-21
- **Model:** Opus 5.5 (A4.2d.3: S25 water, E18, E8, E2).
- **Branches:** `claude/intelligent-lovelace-mtj9ik` in `hcesfort` (docs
  only) and in `hcesfort.engih2018`, both pushed. They contain the work
  of `claude/dazzling-hypatia-h9ylzl`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint. The environment now allows
  `pubchem.ncbi.nlm.nih.gov` (added this session, for E8).
- **Earlier handoffs:** `git show 1c069d0:docs/handoff.md` (row 3, the
  maintainer's answers on E2, E18, E8 and the run of row 3; notes for
  P243), `git show edb7cbf:docs/handoff.md` (E6).

## What was done (adapter)

- `f6d675e` **S25, water.** Option `water` (`"food"` original,
  `"non_food"` corrected): `S3A:594` dropped with its own log row (cause
  `water`). Step `water` after `e6` (no figure expected to move). The
  coverage is written before the step (`step2_coverage.csv`, with water,
  same expectations as before) and after the last step
  (`step2_coverage_no_water.csv`: Section 3A grams without a validated
  match below 2% and below the share with water). NEWS: figures of row 3
  from the run. The roxygen of `engih2018_survey()` wrongly listed
  purified water among the crosswalk's non-foods; fixed.
- `f77076e` **E18.** `density = "by_food"` available: nine oils at
  0.92 g/ml in the five volume units, from the FAO/INFOODS Density
  Database Version 2.0, row "Oil, other than palmoil" (DK)
  (`inst/extdata/densities.csv`, `data-raw/densities.R`, SOURCES.md).
  Step `e18` after `water`; direction in `helper-step2-units.R`.
- `9e4b241` **E8.** `levels = "sugar_palmitate"`: the sugar row of 1c as
  retinyl palmitate, retinol fraction 286.5 / 524.9 (PubChem). Sensitivity
  run `e8_palmitate` on the state after `e18`. The default stays retinol.
  The WHO/FAO guidelines (2006), opened in the session, write such levels
  as retinol (Table 5.5) and say a level in mg/kg of a micronutrient
  refers to the micronutrient (11.3.1.4): recorded in SOURCES.md.
- **E2:** kept at the original value. The FNDDS and INCAP workbooks the
  adapter uses carry no portion weights; `dozen = "count"` is still
  refused. NEWS says so.
- `hcesfort` docs: roadmap A4.2d.3 ticked; design table S25 and row 4
  amended; P247 to P249.

Adapter: `devtools::test()` FAIL 0, PASS 794, SKIP 43 (microdata);
`lintr::lint_package()` clean.

## Exact next step

1. Maintainer: one run of `acceptance-step2` (new: steps `water`, `e18`,
   sensitivity `e8_palmitate`, `step2_coverage_no_water.csv`), and
   answers to the questions below.
2. Fill the figures in NEWS.md of the adapter; then A4.3: self-review,
   `devtools::check()` of the adapter and lint, once for A4.

## Open questions

1. **E18, one value or one per oil?** Implemented: 0.92 g/ml for every oil
   (the only general vegetable-oil row from a food composition databank).
   Rows per kind exist (soya 0.927, corn 0.922, olive 0.918, ...; mostly
   from web pages; sunflower 0.96, one measurement). Recommended: keep
   one value (grams move by less than 4% either way).
2. **E2, what sensitivity?** Without a cited piece weight no sensitivity
   with real weights can be run. Recommended: leave E2 at the original
   value and list the 218 records for the unit catalogue of P243 (unit
   weights estimated from the survey's own unit values, v0.2), unless you
   open a document with piece weights (FNDDS 2017-2018 "Portions and
   Weights" is part of the same release as the FNDDS workbook; its host,
   www.ars.usda.gov, is blocked here and could be allowed).
3. **Water: also `S3A:2665` ("Agua purificada servida")?** Recommended:
   yes, same item served; `S3A:596` (flavoured water) stays a food (P249).

## Recommended model for the next session

**Opus** (figures of the run in NEWS, then the end of A4).

## Maintainer review points

1. **The oil gallon converts at 0.92 g/ml only with the food factor
   first** (P247):

   ```r
   # in hcesfort.engih2018, with devtools::load_all()
   u <- engih_unit_factors("by_food")
   a <- data.frame(record_id = "r1", household_id = "h1",
                   food_code = "S3A:293", quantity = 1, unit = "57",
                   section = "sec3a", period_days = 7, include = TRUE)
   hcesfort::convert_units(a, u, priority = "food")$qty_g     # 3482.577
   hcesfort::convert_units(a, u, priority = "generic")$qty_g  # 3785.41
   ```

2. **The sugar row of the E8 sensitivity** (expected: one row, fraction
   0.5458):

   ```r
   t <- engih2018_tables(engih2018_options("original",
                                           levels = "sugar_palmitate"))
   t$scenarios[!is.na(t$scenarios$compound), ]
   ```

3. **Coverage with and without water on the microdata:**

   ```r
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   k <- "sec3a | sin_enlace_validado"
   for (f in c("step2_coverage", "step2_coverage_no_water")) {
     r <- read.csv(file.path("tests/testthat/_acceptance", paste0(f, ".csv")))
     print(r[r$etapa == k, ])
   }
   ```
