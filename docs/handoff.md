# Handoff

- **Date:** 2026-11-21
- **Model:** Opus 5.5 (A4.3a: water served, self-review, check of A4).
- **Branches:** `claude/ecstatic-hypatia-eq0k2m` in `hcesfort` (docs
  only) and in `hcesfort.engih2018`, both pushed. They contain the work
  of `claude/intelligent-lovelace-mtj9ik`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint.
- **Earlier handoffs:** `git show df0f53b:docs/handoff.md` (A4.2d.3: S25,
  E18, E8, E2 and the maintainer's answers on A4.6),
  `git show 1c069d0:docs/handoff.md` (row 3; notes for P243).

## What was done

- Adapter `2aa5602` **S25, water served.** `S3A:2665` ("Agua purificada
  servida") joins `S3A:594` in `engih_water_codes`: dropped under
  `water = "non_food"`, counted in the same log row (cause `water`).
  `S3A:596` (flavoured water) stays a food. The test fixture carries the
  three codes and checks that both water codes are foods of the shipped
  crosswalk, never its non-foods. NEWS (S25) and roxygen updated. The
  snapshot of the printed options gains the S25 row (it had not been
  updated in `f6d675e`).
- **Coverage with and without water:** cannot be re-run here (microdata).
  `S3A:2665` has no validated match either, so dropping it can only lower
  the grams without a validated match: the expectation of
  `step2_coverage_no_water.csv` (below 2% and below the share with
  water) still holds by construction.
- **Self-review of A4** (diff of `R/` since `ca27a0d~1`): one finding,
  P250 (low). P249 marked done.
- Adapter: `devtools::test()` FAIL 0, PASS 755, SKIP 42 (all skips are
  acceptance files that need the microdata); `devtools::check()` 0
  errors, 0 warnings, 0 notes; `lintr::lint_package()` clean.
- `hcesfort` docs: roadmap A4.2d ticked, A4.3 split (A4.3a done, A4.3b
  open); improvements P249, P250.

## Exact next step

1. Maintainer: merge both branches, then one run of `acceptance-step2`
   on the microdata, and send the summary of the steps `water`, `e18` and
   the sensitivity run `e8_palmitate`, and both coverage files.
2. Next session: put those figures in `NEWS.md` of the adapter (S25,
   E18, E8) and `inst/acceptance/steps/`, tick A4.3b and A4. If a figure
   moves where `expect_step2_unchanged()` says none should, stop and ask.
3. After A4, the first open tasks of the roadmap are 12c and 12d (reports)
   and 12 (vignettes); the maintainer decides the order (12d says it
   comes "before the ENGIH adapter work resumes").

## Open questions

1. After A4, which task: 12c/12d (reports, Fable-designed requirements
   already approved, so Opus implements) or the v0.2 preprocessing module
   (P243, Fable designs)? Recommended: 12c, as the roadmap orders it.

## Recommended model for the next session

**Opus** (figures of the run in NEWS, close A4).

## Maintainer review points

1. **Both water codes dropped, flavoured water kept:**

   ```r
   # in hcesfort.engih2018, with devtools::load_all()
   a <- data.frame(record_id = 1:3, household_id = "h1",
                   food_code = c("S3A:594", "S3A:2665", "S3A:596"))
   r <- drop_non_foods(a, engih_crosswalk()$table, "non_food")
   r$table$food_code   # "S3A:596"
   r$log               # row "water": 2 records, 1 household
   ```

2. **The log row of water on the microdata** (after the run):

   ```r
   s <- engih2018_survey(options = engih2018_options("corrected"))
   l <- hcesfort::audit_log(s$acquisitions)
   l[l$cause == "water", ]   # records of S3A:594 plus S3A:2665
   ```

3. **Coverage with and without water** (as in the previous handoff):

   ```r
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   k <- "sec3a | sin_enlace_validado"
   for (f in c("step2_coverage", "step2_coverage_no_water")) {
     r <- read.csv(file.path("tests/testthat/_acceptance", paste0(f, ".csv")))
     print(r[r$etapa == k, ])
   }
   ```

## Maintainer's run of acceptance-step2 on 9e4b241 (21-11, before 2aa5602)

42 pass, 3 fail. All earlier steps (e10 … e6, both sensitivities, row 3)
pass. The three failures are expectations, not yet judged as errors:

1. **water (S25), "every figure unchanged"**: 6 vehicle figures move.
   `pct_hogares` and `media_todos` rise for rice (88.3105 → 88.5005;
   215.6030 → 216.0668), sugar (78.9262 → 79.0960; 55.3145 → 55.4335)
   and wheat (94.0376 → 94.2399; 46.8570 → 46.9578). All ratios are about
   1.0021, so the vehicle denominator lost about 0.2 % of households.
   The intake blocks (`resumen`, `riesgo`, `grupos`) do not move.
   Hypothesis to verify: households whose only records were water now
   have no acquisition and leave the vehicle denominator. To do:
   - count them;
   - check that the audit log reports them;
   - say whether households with no food records are already outside
     that denominator in the original.
   The expectation is then rewritten to the verified effect. **Question
   for the maintainer** before rewriting it (see the advisor's
   recommendation in chat).
2. **e18 (S4), "other nutrients and vehicles unchanged"**: iron and zinc
   means fall by about 1e-3 mg (for example 11.155501 → 11.154456), and
   the iron risk rows move by under 0.005 points. Likely cause: the oil
   rows of the composition carry traces of iron and zinc; check it.
   If confirmed, the expectation becomes "does not increase" for every
   nutrient present in oil, not "unchanged".
3. **e18 (S4), "plausible energy, within 0.5 point"**: vitamin E
   inadequacy rises 86.9548 → 88.3796 (+1.42) under plausible energy and
   82.9473 → 84.5422 (+1.59) for all. The direction is right (less oil,
   less vitamin E). The 0.5-point margin was a guess without a source.
   Replace it with the direction only, and record the size in NEWS.

**Sensitivity e8_palmitate (passes)**: vitamin A inadequacy in scenario
1c, cut-point method, rises 35.6232 → 49.1172 under plausible energy and
35.5341 → 48.0538 for all. The reading of the sugar level (retinol
vs retinyl palmitate) moves the 1c conclusion by about 13 points: NEWS
and the report must show both readings until NORDOM 602 is checked.

The coverage files (`step2_coverage*.csv`) were not sent in this run;
the next run after 2aa5602 reports them.

## Maintainer's answers (21-11, 10:19)

1. **Water-only households**: they leave the vehicle denominator, like
   households with no food records, and are **counted in the audit log**
   (rows and households). Verify the hypothesis first; if the cause is
   different, stop and report it.
2. **After A4**: task 12c (report redesign), as proposed. P243 is
   designed with the maintainer after `docs/lessons.md`.

Next session (Opus): settle the three expectations above, write the
figures of water, e18 and e8_palmitate in `NEWS.md`, and leave A4 ready
to close with one more maintainer run (with the coverage files).
