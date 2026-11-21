# Handoff

- **Date:** 2026-11-21
- **Model:** Opus 5.5 (A4.3b: the three expectations of the maintainer's
  run on `9e4b241` settled).
- **Branches:** `claude/stoic-knuth-rd4hlb` in `hcesfort` (docs only) and
  in `hcesfort.engih2018`, both pushed. They contain the work of
  `claude/ecstatic-hypatia-eq0k2m`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint (without the adapter installed,
  `lintr::lint_package()` reports object-usage lints in the tests).
- **Earlier handoffs:** `git show 4407c1f:docs/handoff.md` (the run on
  `9e4b241` and the maintainer's answers), `git show df0f53b:docs/handoff.md`.

## What was done (adapter `10f77c2`)

1. **S25, water-only households.** Hypothesis verified in the code of
   `hcesfort`: a household whose records are all water has a missing
   intake before (`all_records_lost`: water has no composition match)
   and after (`no_food_records`), so intake does not move; in
   `vehicle_coverage()`, which counts every record with grams, it moves
   from a non-consumer (`estimated`) to `no_food_records`, outside the
   denominator since E5. In the original (step 1) such a household was a
   non-consumer, inside it.
   - `drop_non_foods()` writes a note `water_only_households` (records
     and households) in `engih2018::non_foods`.
   - New expectation: only coverage and grams per AFE among all move, by
     one common ratio per measure (at least 1).
   - New acceptance test on the microdata: the households left without
     records are exactly the water-only ones; their intake status goes
     `all_records_lost` → `no_food_records`; both logs count them; the
     ratio equals the ratio of the weighted denominators (1e-9). Writes
     `step2_water_households.csv`.
2. **E18.** The INCAP rows of the oils carry iron (0.02–0.56 mg/100 g)
   and zinc (0.01–0.02): they join vitamin E as nutrients that fall or
   stay (`step2_oil_nutrients`, checked in CI against the composition
   shipped). The 0.5-point margin is replaced by the direction of
   vitamin E among households of plausible energy.
3. **NEWS** of the adapter: figures of water, E18 and `e8_palmitate`
   from the run on `9e4b241`.
4. Adapter: `devtools::test()` FAIL 0, PASS 779, SKIP 43 (all need the
   microdata); `lintr::lint_package()` clean; `devtools::check()` 0
   errors, 0 warnings, 0 notes.
5. `hcesfort` docs: roadmap A4.3b ticked, A4.3c open; P251 to P253.

## Exact next step

1. Maintainer: one run of `acceptance-step2` on `10f77c2` (installed
   `hcesfort` at this branch), and send the summary of the steps `water`,
   `e18`, the test "water (S25): the households left without food
   records", `step2_water_households.csv` and both coverage files.
2. Next session (Opus): the count, the ratios and the coverage figures in
   `NEWS.md` of the adapter (S25, "pending the next run"); the step files
   in `inst/acceptance/steps/` (the directory does not exist yet: create
   it with the `step2_*.csv` of the run, or ask); tick A4.3c and A4. If a
   figure moves outside its expectation, stop and report.
3. Then task 12c (maintainer's answer of 2026-11-21).

## Open questions

1. E18, plausible energy: only vitamin E has a direction now (P252).
   Add "iron and zinc inadequacy rises or stays" there too? Recommended:
   no; the set of households moves and the traces are tiny, so a
   direction would be a guess.
2. P251: note also the households left without records by the 11
   non-foods? Recommended: yes, with P243 (preprocessing module), not now.

## Recommended model for the next session

**Opus** (figures of the run in NEWS, close A4).

## Maintainer review points

1. **The note of water-only households** (fixture, no microdata):

   ```r
   # in hcesfort.engih2018, with devtools::load_all()
   a <- data.frame(record_id = 1:4, household_id = c("h1", "h1", "h2", "h2"),
                   food_code = c("S3A:594", "S3A:2665", "S3A:594", "S3A:596"))
   drop_non_foods(a, engih_crosswalk()$table, "non_food")$log
   # row water_only_households: 2 records, 1 household (h1)
   ```

2. **The households left by water on the microdata:**

   ```r
   s <- engih2018_survey(options = engih2018_options("corrected"))
   l <- hcesfort::audit_log(s$acquisitions)
   l[l$cause %in% c("water", "water_only_households"), ]
   ```

3. **The nutrients of the oils in the composition shipped:**

   ```r
   cw <- engih_crosswalk()$table
   oils <- read.csv(system.file("extdata", "densities.csv",
                                package = "hcesfort.engih2018"))
   ids <- cw$composition_id[cw$food_code %in% oils$food_code & cw$validated]
   comp <- engih_composition()
   comp[comp$composition_id %in% ids,
        c("name", "iron_mg", "zinc_mg", "vitamin_e_mg")]
   ```

## Maintainer's answers on A4.3b (21-11, 10:41)

1. E18 under plausible energy: no direction for iron and zinc; vitamin E
   only.
2. Households left without records by the crosswalk's non-foods (P251):
   yes, counted in the log, but with P243, not now.
3. `inst/acceptance/steps/`: yes, create it with the `step2_*.csv` of the
   next run. Only aggregated figures go there (estimates, ratios, counts,
   food codes); never a file with household or person identifiers.
   Check each file's columns before committing it.
