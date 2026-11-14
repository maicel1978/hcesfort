# Handoff

- **Date:** 2026-11-14
- **Model:** Opus (steps 12d.3 and 12d.4).
- **Branch:** `claude/funny-wright-niihlw` (starts from the previous
  handoff, `d232e3e`; `main` is not updated by this session). Merge it
  into `main` before the next session, or continue on it.
- **Environment:** `hcesfort`. `tinytable` was installed by hand at the
  start (P126 still open: add it to the setup script).

## What was done

| Commit | Step |
|---|---|
| `e2968f5` | 12d.3: `estimate_households(ci_method = "korn_graubard")` (C2) and the column `ci_method` in every `hces_estimate`; P128 resolved in `?estimate_households` |
| `d214063` | 12d.4: `flag_presentation()` (C3) |
| last commit | Handoff |

`devtools::check()` after 12d.4: 0 errors, 0 warnings, 0 notes.
`lintr::lint_package()`: no lints. Tests: no failures; one skip (Quarto
not installed).

Facts found on the way, in the commit messages:

- The cap at `n` is applied **after** the degrees-of-freedom adjustment,
  as C2 says. That order reproduces the published limits of Tables I and
  II within 0.10 point; capping first misses by up to 2.3 points.
- The NCHS tables are on pp. 8 (Table I) and 9 (Table II). Table I has 8
  rows (4 groups and their complements) and Table II 8: the tests type all
  16 (`tests/testthat/helper-nchs.R`), not twelve.
- `binom.test()` (section 3.4 of the design): on a design of equal weights
  without clusters, `survey` estimates the variance as p(1 − p) / (n − 1),
  so the effective size is n − 1 and the interval is not exactly the
  binomial one. The exact check is made on the internal function with
  variance p(1 − p) / n (every x of 12) and, through
  `estimate_households()`, for 0 and n events.
- The decisions test uses the published limits: with the rounded estimate
  and SE, the non-Hispanic Asian "elevated" row has a recomputed width of
  0.0498, below the 0.05 boundary, against 0.051 published.

## Choices taken in implementation, to confirm (P130)

1. An estimate that is missing although `n` reaches `min_n` (a share
   whose total is zero) gets `presentation = NA`, counted in the log as
   `presentation_undefined`. *Recommended: keep* (the standard says
   nothing; suppressing would hide a data problem).
2. Invariant of section 3.4, "lowering a threshold never turns suppress
   into present", holds only for the upper limits; it is tested as "a
   stricter standard (higher `min_*`, lower widths) never moves a status
   towards present". *Recommended: keep.*
3. Comparisons with the thresholds are exact (no tolerance). *Recommended:
   keep*; the standard states the thresholds as exact numbers.

## Exact next step

**12d.5** (Opus): `short_label` and label type `compound` (C6 of
`docs/design-reports-v3.md`). Then 12d.6 onwards.

## Answers of the maintainer (2026-11-14, after 12d.4)

1. **P130:** the three implementation decisions are accepted as recommended: an undefined estimate with n ≥ 30 gets `NA` plus `presentation_undefined` in the audit log; the invariant is tested as "a stricter standard never moves a status towards present"; threshold comparisons are exact.
2. **P126:** the environment script is not edited for now. Each session is opened with "Al empezar, instala tinytable si falta." Close P126 when the script is edited.

Record these in `docs/improvements.md` with the first commit of 12d.5.

## Recommended model for the next session

**Opus** (12d.5 onwards). This session stops at about half of its
context.

## Maintainer review points

1. **The Korn-Graubard limits against Table II of the report** (p. 9):

   ```r
   devtools::load_all()
   t <- read.csv(text = "p,se,n,df
   0.478,0.0479,74,7
   0.250,0.0416,82,7")
   round(100 * t(mapply(korn_graubard_interval, t$p, t$se, t$n, t$df,
                        0.95)), 1)
   # published: 36.0-59.7 and 15.8-36.2
   ```

2. **`"korn_graubard"` against `"beta"`** on the example (wider or equal,
   never narrower):

   ```r
   library(hcesfort)
   grams <- convert_units(hces_example$acquisitions,
                          hces_example$unit_factors, priority = "food")
   afe <- adult_equivalents(hces_example$members,
     reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
     weight_kg = c(female = 55, male = 65), pal = 1.76)
   use <- vehicle_coverage(grams, hces_example$vehicles, afe,
                           hces_example$households)
   d <- as_hces_design(hces_example$households, lonely_psu = "adjust")
   kg <- estimate_households(d, use, "acquired", by = "region",
                             ci_method = "korn_graubard")
   be <- estimate_households(d, use, "acquired", by = "region",
                             ci_method = "beta")
   cbind(kg[c("ci_low", "ci_high")], be[c("ci_low", "ci_high")])
   ```

3. **`flag_presentation()` on the same estimates:**

   ```r
   flag_presentation(kg)[c("vehicle", "region", "n", "n_effective",
                           "ci_width", "presentation",
                           "presentation_reason")]
   ```
