# Handoff

- **Date:** 2026-11-12
- **Session:** roadmap items 11b.8 to 11b.10 and the closing of task 11b
  (corrections of the v0.1 review). Model: Opus 5.5 (see the commit
  trailers).
- **Branch:** `main`. Stopped because task 12 is for Sonnet
  (`docs/model-routing.md`).

## What was done

| Commit | Content |
|---|---|
| `1a24f31` | P87 recorded as approved |
| `3456435` | 11b.8 Logs merged without repeated branches; `audit_summary()`, `audit_record()` |
| `9ee1d77` | 11b.9 `estimate_households()`; `flag_energy_plausibility(intake, energy, lower, upper)`; `adult_equivalents(missing_members =)` |
| `5013ab1` | 11b.10 `reference_energy()`; `qty_vehicle_g_d_pc`; `who2009_levels()` |
| `1e8b5ef` | P89 approved; P90 decided: the per capita availability is the ratio of weighted totals of grams and members (`survey::svyratio()`), shown in the help of `who2009_levels()` and tested at 1e-8; specification updated |
| `7b8be62` | Close 11b: self-review fixes (silent drop in `who2009_levels()`, `get()` in `reference_energy()`, missing test); P91–P94 |
| this commit | This handoff |

State: `devtools::check()` 0 errors, 0 warnings, 0 notes;
`lintr::lint_package()` clean; 1,482 tests pass; coverage 99.5%.

## Exact next step

**Sonnet** starts task 12 (`docs/roadmap.md`): vignettes in English
(Spanish version of the main one), from standard tables to risk by
scenario on `hces_example`; how to write an adapter (`audit_record()`,
`restore_audit()`); plotting results with `ggplot2`. The main vignette
must:

- use `reference_energy()` for `reference_kcal`;
- compute the flour availability per person as in the example of
  `?who2009_levels` (ratio of totals, P90), then call `who2009_levels()`;
- show `audit_summary()` at the end of the chain.

## Parallel design track (Fable, 2026-11-12)

Does not change the next step above. Two design notes were added:

- `docs/design-report-template.md`: country report template by decision
  questions. **Approved** (roadmap 12b). Not to be implemented before 11c.
- `docs/design-food-group-shares.md`: `food_group_intake()` and
  `food_group_shares()` on the unfortified baseline (roadmap 11c).
  **Waits for the approval of its nine decisions**; then Opus implements
  it by its commit plan (section 7).

The vignette on the template (task 12) waits for 12b.

## Open questions

None for the maintainer. Open items for later: P91 (a helper for the
ratio, v0.2), P92–P94 (low). Zinc `ear_bioavailability` stays
`# SOURCE PENDING`.

## Recommended model for the next session

**Sonnet 5.5** (task 12, vignettes).

## Maintainer review points

1. **The WHO 2009 boundary rule.**

   ```r
   sapply(c(74.9, 75, 149.5, 150, 300, 300.1), function(a)
     unique(hcesfort::who2009_levels(a, "low")$availability_g_d))
   ```

2. **The per person availability of the example.**

   ```r
   example(who2009_levels, package = "hcesfort")
   coef(r)   # about 77 g per person per day on hces_example
   ```

3. **The merged audit log reads well.**

   ```r
   devtools::load_all()
   source("tests/testthat/test-golden-example.R", local = TRUE)
   ch <- golden_chain()
   anyDuplicated(audit_log(ch$s))   # 0
   audit_summary(ch$s)
   ```
