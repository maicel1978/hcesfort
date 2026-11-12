# Handoff

- **Date:** 2026-11-12
- **Session:** implementation of roadmap items 11b.1 to 11b.7 (corrections
  of the v0.1 review). Model: Opus 5.5 (see the commit trailers).
- **Branch:** `main`. Stopped at the maintainer's request (context size).

## What was done

| Commit | Content |
|---|---|
| `538b168` | 11b.1 Record loss: `n_records_included`, `share_records_used`, `share_grams_used`; required `min_records_used` gate. Ten decisions of `docs/design-review-v0.1.md` recorded as approved (`docs/improvements.md`); IOM 2000 opened |
| `ff7bc44` | 11b.2 `cutpoint_valid`, `ear_bioavailability`; `ref_requirements`, `SOURCES.md` (IOM 2000b, pp. 81 and 91), md5 |
| `913a68a` | 11b.3 `domain_from` in `estimate_prevalence()` / `estimate_difference()`; internal `audit_union()` |
| `80fdfd0` | 11b.4 `vehicle_coverage()` returns `afe`, `n_members`; attribute `outlier_decision`; `apply_scenario()` checks both (P76 closed) |
| `8567660` | 11b.5 `hces_example` recalibrated; `data-raw/golden_example.R` (no package code) and `test-golden-example.R`: 17 figures at 1e-8 |
| `8db1500` | 11b.6 Degenerate proportions; classed lonely-PSU error (P84 closed); tests T1–T4; both surviving mutations now killed |
| this commit | 11b.7 `check_required()` in every exported function; clearer messages in `apply_scenario()`, the distribution check, `flag_energy_plausibility()`, `flag_precision()`; P87, P88; this handoff |

State: `devtools::check()` 0 errors, 0 warnings, 0 notes;
`lintr::lint_package()` clean; all tests pass.

## Exact next step

**Opus** continues with roadmap items, one commit each, following
`docs/design-review-v0.1.md`:

1. **11b.8** Audit log: route every merge of two logs through
   `audit_union()` (already in `R/audit.R`, tested) — at least
   `R/intake.R` (`apparent_intake`), `R/vehicle-use.R`, `R/scenario.R`,
   `R/above-ul.R`, `R/inadequacy.R`; then export `audit_summary()` and
   `audit_record()` (section 5 of the design note).
2. **11b.9** Renames: `estimate_prevalence()` → `estimate_households()`;
   `flag_energy_plausibility(intake, column, min, max)` →
   `(intake, energy, lower, upper)`; `adult_equivalents(missing =)` →
   `missing_members =`. No deprecation layer. Update tests, examples,
   NEWS, specification.
3. **11b.10** `reference_energy()`, `qty_vehicle_g_d_pc` in
   `vehicle_coverage()` (the WHO 2009 basis quoted with the document
   open), `who2009_levels()`. Then use `reference_energy()` in examples
   and in the "reference woman is 1 AFE" test; regenerate nothing in the
   golden test unless a figure changes (it should not).
4. Close task 11b: specification, self-review, `docs/handoff.md`.

## Open questions

- P87 (choices taken in implementation, six items) for the maintainer to
  confirm.
- Zinc `ear_bioavailability` stays `# SOURCE PENDING` (IOM 2001,
  chapter 12, not read).

## Recommended model for the next session

**Opus 5.5** (implementation of the approved design).

## Maintainer review points

1. **The IOM 2000 quotations behind `cutpoint_valid`.**

   ```r
   # Open https://nap.nationalacademies.org/read/9956/chapter/10
   # p. 81: "the method does not work ... with iron requirements in
   # menstruating women"; p. 91: symmetry assumed by default.
   hcesfort::ref_requirements[, c("nutrient", "cutpoint_valid",
                                  "ear_bioavailability")]
   ```

2. **The recalibrated example reads plausibly.**

   ```r
   devtools::load_all()
   source("tests/testthat/test-golden-example.R", local = TRUE)  # defines golden_chain()
   ch <- golden_chain()
   summary(ch$intake[ch$intake$intake_status == "estimated",
                     c("energy_kcal", "iron_mg", "folate_ug_dfe",
                       "vitamin_a_ug_rae", "share_records_used")])
   ```

3. **The golden values are independent of the package.**

   ```r
   # data-raw/golden_example.R must not call any hcesfort function:
   grep("hcesfort::|library\\(hcesfort", readLines("data-raw/golden_example.R"))
   source("data-raw/golden_example.R")  # rewrites the fixture; git diff should be empty
   ```
