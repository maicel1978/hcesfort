# Handoff

- **Date:** 2026-11-12
- **Model that worked:** Fable 5.2 (design only; no package code changed)
- **Branch:** `main`

## What was done

| Commit | Content |
|---|---|
| see `git log` | `docs/design-task9.md`: unfortified baseline, vehicle use, scenarios (level basis, enrichment subtraction, compliance). |
| same | `docs/design-task10.md`: `inadequacy()` (cut-point, probability approach with bioavailability) and `above_ul()` (added only against diet plus added). |
| same | Roadmap sub-items 9.0–9.4 and 10.0–10.4; P69–P74 in `docs/improvements.md`. |

No file under `R/`, `tests/` or `data-raw/` was touched, so the state of the
last code commit stands (`442f3b7`: `devtools::check()` 0/0/0, lint clean,
768 tests, coverage 100%). `check()` was not run again in this session.

Why the session stopped: both designs are written and need the maintainer's
approval; what follows is implementation, which `docs/model-routing.md`
assigns to Opus.

## Exact next step

1. The maintainer answers section 11 of `docs/design-task9.md` (11 choices)
   and section 9 of `docs/design-task10.md` (10 choices). "Approved as
   recommended" is enough; otherwise the numbers that change.
2. Opus records the answers in `docs/improvements.md` ("Decisions, design of
   tasks 9 and 10"), sets the status line of each design to approved, and
   implements task 9 by the commit plan of its section 10, starting with
   9.1 (contracts: `form`, `vehicle_group`, table `enrichment`, example
   data). Task 10 follows by its section 8.

If an answer changes choice 5 of task 9 (compliance: both models now) or
choice 5 of task 10 (bioavailability by source now), that part goes back to
Fable for its design before it is implemented.

## Open questions

The 21 choices of the two designs. The ones that change results or
contracts most:

- Task 9, choice 3: floor of the enrichment subtraction at
  `fraction × unenriched` instead of zero (changes the accepted P6).
- Task 9, choice 5: compliance by average content only in v0.1.
- Task 9, choices 1, 6, 7: new table `enrichment`, new columns `form` and
  `vehicle_group`.
- Task 10, choice 7: the folate upper level is in µg of folic acid; the
  shipped table gives it the unit µg DFE. To be read at IOM 1998, p. 281
  before `ul_unit` is entered.
- Task 10, choice 9: a nutrient below `min_coverage` is an error.

## Recommended model for the next session

**Opus 5.5**: implementation of task 9 from the approved design.

## Maintainer review points

1. **The level formula reproduces the constants of the original**
   (`06_escenarios_fortificacion.R:42-43`), with the factors stated one by
   one (design of task 9, section 5).

   ```r
   library(hcesfort)
   dfe <- subset(ref_conversions, from_form == "folic_acid")$factor
   c(iron_mg = 55 * 1 / 10,                 # original: 55 * 0.1
     folate_ug_dfe = 1.8 * 1000 / 10 * dfe, # original: 1.8 * 100 * 1.7
     vitamin_a_ug_rae = 10 * 1000 / 10 * 1) # original: 10 * 100, read as retinol
   ```

2. **The iron probability and its tails** (design of task 10, section 3):
   1 below P2.5, 0 above P97.5, a jump of 0.025 at each end.

   ```r
   d <- subset(ref_iron_requirements, group == "females_menstruating_adult")
   p <- function(intake, b) {
     1 - stats::approx(d$requirement_mg_d, d$percentile / 100,
                       xout = intake * b / d$bioavailability[1],
                       yleft = 0, yright = 1)$y
   }
   p(c(4, 4.42, 8.07, 18.23, 19), 0.18)  # 1, 0.975, 0.5, 0.025, 0
   p(14.526, 0.10)                       # 0.5
   ```

3. **The unit of the folate upper level in the shipped table.** It reads
   µg DFE; the original compares the UL with folic acid (added ÷ 1.7).

   ```r
   subset(ref_requirements, nutrient == "folate",
          c(nutrient, unit, ear, ul, ul_applies_to, location))
   ```
