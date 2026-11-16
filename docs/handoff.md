# Handoff

- **Date:** 2026-11-16
- **Model:** Opus 5.5 (step 12e.4).
- **Branch:** `claude/docs-routing-handoff-9dlnd0`, pushed.
- **Environment:** run `R CMD INSTALL .` at the start (the report tests use
  the installed package). The full `devtools::test()` now runs in
  parallel (`Config/testthat/parallel: true`), about 5.5 minutes here:
  run it in the background, one at a time.

## What was done

12e.4 (P164 effective size under R2-D6, P165 to P168, P172, P183), see the
commit messages and `NEWS.md`:

- Estimators: a cell without variation has no interval (`no_variation`);
  a cell without degrees of freedom has no interval and no warning
  (`no_degrees_of_freedom`); new columns `interval_note` and
  `n_effective` (`n` over the design effect, from the variance of the
  values); `flag_precision()` decides `exact` on the values;
  `flag_presentation()` uses `n_effective`; `survey.adjust.domain.lonely`
  fixed at `FALSE` and logged; note `psu_in_several_strata`.
- Validators: `level_mg_kg <= 1e6`; mass per 100 g at most 100 g;
  `age_months` against `age_years`. The optional fixture's adult month
  (30) became 450, consistent with the age (it is still ignored).
- `apparent_intake()`: flagged row `zero_intake`.
- Report: note `usual_intake` under the risk exhibits (en, es); departure
  S2 rewritten. Golden values regenerated (iron `n_effective`; the fixture
  iron estimate now suppressed); report snapshots accepted (zinc cells of
  zero prevalence lose their interval; the new note).
- New items P184 to P187 (self-review).
- Parallel tests kept: `Config/testthat/parallel: true` in `DESCRIPTION`.
  Serial and parallel runs of the same tree gave the same counts (52
  files, 529 tests, 3415 expectations, 0 failures, 0 warnings, 0 skips)
  in 10 min 45 s and 5 min 29 s.

## Not done

- **`surveytable` anchor (R2-D7):** the install was refused again by the
  session's permission classifier. As decided on 2026-11-15, the test is
  dropped; recorded under R2-D7 in `docs/improvements.md`.

## Exact next step

**12e.5.1** (`infant_food_share`, `milk_energy_cost` in
`adult_equivalents()`), from `docs/design-12e5.md` (read its sections for
12e.5.1 and decisions R3-D1 to R3-D9 in `docs/improvements.md`). Then
12e.5.2 to 12e.5.8 (Opus). `devtools::check()` and `lintr::lint_package()`
once at the end of task 12e.

## Open questions

None.

## Recommended model for the next session

**Opus** (12e.5.1).

## Maintainer review points

1. **The effective size of the iron estimate** (`n` over the design effect,
   no longer the number of households):

   ```r
   library(hcesfort)
   example(flag_presentation)  # builds the chain objects
   e <- estimate_households(design, use, "acquired", by = "region",
                            ci_method = "korn_graubard")
   e[c("region", "estimate", "se", "n", "n_effective", "interval_note")]
   ```

2. **A cell without degrees of freedom** has no interval and no warning:

   ```r
   d <- as_hces_design(hces_example$households, lonely_psu = "adjust")
   h <- hces_example$households
   one <- h$psu == h$psu[[1]] & h$stratum == h$stratum[[1]]
   x <- hcesfort:::new_hces_tbl(
     data.frame(household_id = h$household_id,
                y = ifelse(one, seq_along(one), NA)),
     "hces_intake", key = "household_id")
   estimate_households(d, x, "y", statistic = "mean")
   ```

3. **The new report note** reads well in both languages:

   ```r
   read.csv(system.file("report/es/terms.csv", package = "hcesfort"))[
     c(159, 217), "label"]
   ```
