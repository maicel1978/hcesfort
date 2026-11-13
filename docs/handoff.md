# Handoff

- **Date:** 2026-11-13
- **Model:** Opus 5.5 (implementation, steps 12c.1 to 12c.8).
- **Branch:** `claude/docs-routing-handoff-4zzr3x` (the session's
  development branch; `main` is not updated by this session). Merge it
  into `main` before the next session, or continue on it.

## What was done

| Commit | Step |
|---|---|
| `6dbde6a` | Decisions of the design recorded in `docs/improvements.md` (R-D1 to R-D12); P107 and P109 resolved |
| `2c56a1a` | 12c.1 optional column `expenditure_lcu` in `acquisitions`; invented in `hces_example` (other tables identical) |
| `d95a006` | `linkage_ladder()` and the internal `record_measures()` (U3) |
| `24c498d` | `unmatched_foods(x, households, order)` as the work queue (U4); interface change in `NEWS.md` |
| `7f2e7e7` | `estimate_unlinked()` and the internal contrast (U5); agrees with `survey::svyratio()` and `survey::svycontrast()` to 1e-8 |
| `bfd8594` | 12c.5 `precision_status` in `flag_precision()` (U8) |
| `3f8cfce` | 12c.6 `read_labels()`, `label_codes()`, `read_decisions()`; schemas `labels`, `decisions` (U6, U9) |
| `408ae9c` | 12c.7 `readiness_inventory()`, `readiness_checks()` (U1, U2) |
| `04d3a4e` | 12c.8 `readiness_verdict()` (U7) |

`devtools::test()`: 1936 passed, 0 failed (1 skip: Quarto not
installed). `devtools::check()` on `04d3a4e`: 0 errors, 0 warnings, 0
notes. `lintr::lint_package()`: no lints. Coverage 99.5% overall.

No contract of sections 3 to 5 of the design had to change. Small
choices the design did not cover are P112 to P115 of
`docs/improvements.md`.

## Exact next step

**12c.9**: shared template files (`_inputs.R` with `choices`, `_chain.R`,
`_readiness.R`, `_tables.R`, `_figures.R`), `labels.csv`, `terms.csv`,
`decisions.csv`, and the readiness report in English (tests K1, K3,
K10–K13, U10). Then 12c.10 to 12c.13 as in section 10 of
`docs/design-reports-v2.md`. `inst/report/` is still the old template;
nothing in it calls the new functions yet.

## Open questions for the maintainer

1. **P112.** Records without `expenditure_lcu` are left out of the
   expenditure shares and not counted. Recommended: print their count in
   the note of the ladder table in 12c.9 (no contract change).
2. **P113.** A missing estimate with enough households has
   `precision_status = NA`. Recommended: keep `NA` (the report prints
   "—" for it, as for a suppressed cell).
3. Still pending from earlier handoffs: P99 and P103.

## Recommended model for the next session

**Opus 5.5** (12c.9 to 12c.13: template implementation of an approved
design).

## Maintainer review points

1. **The work queue on the example.** The coverage curve must start at
   the last step of the ladder and end at 1:

   ```r
   devtools::load_all()
   e <- hces_example
   g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
   x <- link_composition(g, e$crosswalk, e$composition,
                         nutrient_registry(e$nutrients))
   linkage_ladder(x, e$households)
   u <- unmatched_foods(x, e$households)
   u[c("food_code", "reasons", "units_no_grams", "share_grams",
       "cum_share_records", "cum_share_grams")]
   ```

2. **The DR5 flag against review point 2 of the previous handoff.** The
   difference for `north` must be −0.0098 with interval −0.042 to 0.023:

   ```r
   d <- as_hces_design(e$households, lonely_psu = "adjust")
   estimate_unlinked(d, x, by = "region")[
     c("region", "estimate", "rest_estimate", "difference",
       "difference_ci_low", "difference_ci_high", "differs")]
   ```

3. **The verdict when a threshold is not met.** With
   `min_records_used = 0.95` (the example uses 90.2% of its included
   records), `risk`, `scenarios` and `food_groups` must be disabled:

   ```r
   afe <- adult_equivalents(
     e$members,
     reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
     weight_kg = c(female = 55, male = 65), pal = 1.76
   )
   intake <- apparent_intake(x, afe, e$households)
   ch <- readiness_checks(intake, linkage_ladder(x, e$households),
                          c("iron", "folate", "vitamin_a"),
                          min_records_used = 0.95, min_coverage = 0.9,
                          min_linked_share = 0.9)
   ch
   inv <- readiness_inventory(e[names(e) != "nutrients"], "region")
   readiness_verdict(inv, ch, domains = "region")
   ```
