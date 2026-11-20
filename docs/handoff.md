# Handoff

- **Date:** 2026-11-20
- **Model:** Opus 5.5 (A4.2b).
- **Branches:** `claude/adoring-mayer-s0mm5x` in `hcesfort` (docs only)
  and in `hcesfort.engih2018` (tests and `NEWS.md`), both pushed. They
  continue `claude/zen-hamilton-ndnwr3`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before lint.
- **Earlier handoff:** `git show 7ce3fb9:docs/handoff.md` (A4.2, with the
  maintainer's answers on E24 and the figures of the run).

## What was done

Adapter commits:

| Commit | Step | Class | Direction checked |
|---|---|---|---|
| `2c42abb` | E24: intervals as figures; `ci_method = "korn_graubard"`, `df = "domain"` (state `args$intervals`) | interval method that leaves the parameter space | every point estimate fixed; share limits inside 0 to 100 (present on the microdata); median limits fixed |
| `97add90` | S8 `energy = "package"` (infant rows 649.42 / 600.42 kcal, not 649 / 600) | rounded reference value | intake and vehicle grams per AFE fall or stay; coverage and density of all households fixed; on the microdata no share moves by more than 0.1 point, no other figure by more than 0.1% |
| `2e29595` | S2 `priority = "food"` (P59) | silent assumption | no figure moves (microdata only) |
| `f5b06c4` | NEWS: figures of E27, E5/E28, P159, E30, E1, E7 from the maintainer's run | — | — |

Notes on E24:

- The step 2 figures now carry the limits of the 95% intervals
  (`*_low`, `*_upp`) of the share below the EAR, above the UL, median
  density, median and mean intake, coverage and median among consumers.
  Group shares, mean grams per AFE and the folic-acid UL share (the folate
  row of the UL share) have none. The other steps are checked on the
  point estimates only (`step2_check()`).
- The interval choices are threaded through `control_est()`,
  `risk_block()`, `control_summary()`, `control_vehicles()` and
  `group_shares()`, with the step 1 values as defaults: step 1 does not
  change. Medians use `df = "domain"` in every state (srvyr's
  `survey_median()`); the summary and density medians were on
  `df = "design"` before, which changed no compared figure (the original
  reported no interval for them).
- On the invented survey a cell whose households lie in one PSU per
  stratum has no degrees of freedom with `df = "domain"`, so "limits
  present" is checked on the microdata only.

Tests of the adapter: all pass here, 33 skipped (microdata); lint of
`tests/testthat` clean. `devtools::check()` not run (once at the end of
A4).

## Exact next step

A4.2c (Opus), S16 `requirements = "package"`, after the answers below.
Found while preparing it: the step cannot run as the design has it.

1. `engih2018_tables(requirements = "package")` passes the whole
   `ref_iron_requirements` (14 groups, 182 rows), and `inadequacy()`
   refuses it (`hcesfort_error_key`: "must describe one group").
2. `ref_requirements` has no vitamin D row: it is pending in
   `data-raw/SOURCES.md` of hcesfort (`ul_applies_to = total` not found
   in IOM 2011). With the package's table, every vitamin D figure of
   inadequacy and UL would disappear.
3. The other rows match the original's (EAR and UL of iron, zinc,
   folate, vitamin A, B12), except vitamin E, which gains the UL of 1,000
   mg of supplemental alpha-tocopherol (`ul_applies_to =
   supplemental_alpha_tocopherol`), and the iron row's
   `ear_bioavailability` (0.18 against missing; iron uses the probability
   approach, so no figure should depend on it).

Then the maintainer runs step 2 (A4.3).

## Open questions

1. **S16, iron group.** The original's distribution (13 percentiles,
   women 19 to 30, 18%) is identical, value by value, to the package's
   group `females_menstruating_adult` (IOM 2001, Appendix Table I-4,
   p. 700). Recommended: the adapter's `requirements = "package"` keeps
   that group only (the reference woman is 25 years old and
   menstruating), so S16 does not move iron. Alternative:
   `females_adult_mixed` (17% oral contraceptive users), a methodological
   change that would lower iron inadequacy; it belongs to a separate
   decision, not to S16.
2. **S16, vitamin D.** Recommended: (a) wait for S16 until the package
   ships the vitamin D row (one reading of IOM 2011 for the intake the UL
   refers to; P-item to open in `improvements.md`), and run step 2 now
   without S16. Alternatives: (b) append the original's vitamin D row
   (EAR 10 µg, UL 100 µg, both verified) to the package table in the
   adapter, its `ul_applies_to` marked pending; (c) let the vitamin D
   figures drop from step 2 and record it in `NEWS.md`.
3. **S16, vitamin E.** With the package's row, vitamin E's UL applies to
   supplemental alpha-tocopherol only; no scenario adds vitamin E, so its
   share above the UL would be 0% in every scenario (it was missing).
   Recommended: accept it as the design's "vitamin E gains the package's
   upper level", and say in `NEWS.md` that the 0% is by construction
   (food is outside the scope of that UL).

**Answers of the maintainer (2026-11-20, A4.2b, S16):** all approved as
recommended. 1, iron: the adapter uses only `females_menstruating_adult`
(the AFE unit), so S16 does not move iron. 2, vitamin D: postpone S16 and
run step 2 without it; new small task in `hcesfort`, before S16: verify the
vitamin D row of `ref_requirements` (EAR, UL and `ul_applies_to`) against a
document opened in the session, with its source in `data-raw/SOURCES.md`;
never from memory. 3, vitamin E: accept 0% above the UL in every scenario
(the UL applies to supplements and fortificants only) and explain it in
`NEWS.md`.

**Run of the maintainer (2026-11-20, A4.2b on the microdata, adapter
f5b06c4):** `acceptance-step2` FAIL 0, PASS 28 in 1,261 s (twelve steps).
For `NEWS.md`:

- E24: point estimates unchanged; interval limits change in 374 of 1,018
  risk rows and 6 of 21 vehicle rows, largest 0.085 points (upper limit of
  percent above the UL of vitamin A, 2b, plausible energy, 0.517 to 0.603;
  vitamin D at baseline 0.086 to 0.161).
- S8: negligible: largest 0.12 on a median limit (folate, scenario 3,
  857.99 to 857.87); group shares at most 4e-5; risk at most 2e-4.
- S2: no figure moves.

## Recommended model for the next session

**Opus** (A4.2c: implementing S16 once answered).

## Maintainer review points

1. **Step 2 on the microdata** (now twelve steps; about 25 minutes).
   Send the new `step2_*.csv` files and the test summary:

   ```r
   # in hcesfort.engih2018, branch claude/adoring-mayer-s0mm5x, with
   # hcesfort installed from the same branch name
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   list.files("tests/testthat/_acceptance", "^step2_")
   ```

   Expected: every step passes its direction; e24 moves only limits; s8
   nothing beyond 0.1; s2 nothing.

2. **E24, the shares that gain an interval or had a limit outside 0 to
   100:**

   ```r
   d <- read.csv("tests/testthat/_acceptance/step2_e24.csv")
   lim <- d[grepl("^pct_.*_(low|upp)$", d$medida), ]
   lim[is.na(lim$old) | lim$old < 0 | lim$old > 100,
       c("etapa", "medida", "old", "new")]
   ```

3. **S8, the largest changes** (expected: nothing visible):

   ```r
   d <- read.csv("tests/testthat/_acceptance/step2_s8.csv")
   head(d[order(-abs(d$difference)), c("bloque", "etapa", "medida",
                                       "old", "new")], 10)
   ```
