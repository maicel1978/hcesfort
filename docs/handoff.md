# Handoff

- **Date:** 2026-11-20
- **Model:** Opus 5.5 (A4.2, high effort).
- **Branches:** `claude/zen-hamilton-ndnwr3` in `hcesfort` (docs only)
  and in `hcesfort.engih2018` (tests and `NEWS.md`), both pushed. They
  continue `claude/sleepy-albattani-s7uctu`; nothing is merged into
  `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before lint.
- **Earlier handoff:** `git show 0b063f0:docs/handoff.md` (A4.1).

## What was done

Re-reading of E10, E11, E29 (`ca27a0d`, `935bd18`, `b8d1b57`) against
design section 5, as requested. All three match their rows. One note, now
in the comment of `expect_step2_share()` and in `NEWS.md`: the direction of
E29 is **not guaranteed by construction**. `convert_units()` applies the
share before `flag_outliers()`, so the outlier bounds move with it and a
record flagged before can be kept after. On the ENGIH 2018 the net effect
is a fall everywhere (the maintainer's run). Nothing else to change.

Adapter commits (each with its root-cause class in the message):

| Commit | Step | Class | Direction checked |
|---|---|---|---|
| `67f6cff` | NEWS: rows 1, 2; figures of E10, E11, E29 | — | — |
| `b6d8abe` | E27 `vehicles = "all"` | silent filter | scenario 0 and groups fixed; coverage, grams, intake of fortifying scenarios rise or stay |
| `06cab8a` | E5/E28 consumer = `acquired` (state field `consumer`) | missing value read as zero | only coverage and mean grams move, rising or staying; medians fixed |
| `54cf5b1` | P159 `fortifiable = "use"` | silent assumption | scenario 0, vehicles, groups fixed; intake of fortifying scenarios falls or stays |
| `9e533ef` | E30 groups by code (state `groups = "code"`) | text join | only group shares; dairy rises, others fall (microdata only) |
| `7b43143` | E1 `group_shares = "baseline"` | wrong reference basis | only iron and folate shares; cereals fall (microdata only) |
| `c2f16ea` | E7 upper level on the total of the form (state field `ul`, `risk_inputs(ul =)`) | lower bound reported as an estimate | only the shares above the UL, rising or staying |

The invented survey gained three Section 3A records (butter bread, code
5: own production in 12_1; without a unit in 11_1), so E27, E5/E28 and
P159 move figures in CI. E7 moves none in CI (no household above a UL);
a test checks the column choice instead. Tests of the adapter: 573 pass,
32 skipped here; lint of the changed files clean. `devtools::check()` not
run (once at the end of A4).

## Exact next step

A4.2b (Opus), after the answers below:

1. E24: add the interval limits to the step 2 figures (`*_low`, `*_upp`
   columns of the controls), keep the expectations of the other steps on
   the point estimates only, then the step with the chosen `ci_method`
   and `df`. Direction (row 16): every point estimate identical; limits
   inside 0 to 100; medians and UL shares gain an interval.
2. S8/S16: `energy = "package"`, `requirements = "package"` (row 17:
   nothing visible from S8; vitamin E gains the package's UL).
3. S2: `priority = "food"` (no figure: no record has both factors).

Then the maintainer runs step 2 (A4.3).

## Open questions

1. **E24, interval method for proportions.** Recommended:
   `ci_method = "korn_graubard"`, the method of the presentation standard
   (V-D16): it stays in 0 to 100 and gives limits at 0% and 100%.
   `"logit"` (the package default) has no limits for a cell at 0 or 1.
2. **E24, degrees of freedom.** Recommended: `df = "domain"`, the package
   default (improvements, decision 3): a province or quintile interval
   uses the degrees of freedom of its own PSUs; the original used 925 for
   all (P188).
3. **E24 in the harness.** The step 2 figures are point estimates only,
   so E24 would move nothing there. Recommended: add the limits as
   figures (as in point 1 of the next step), so the change of intervals
   is recorded in `step2_e24.csv`.

## Recommended model for the next session

**Opus** (A4.2b: implementing approved corrections).

## Maintainer review points

1. **Step 2 on the microdata** (now nine steps; a few minutes). Send the
   `step2_*.csv` files and the test summary:

   ```r
   # in hcesfort.engih2018, branch claude/zen-hamilton-ndnwr3, with
   # hcesfort installed from the same branch name
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   list.files("tests/testthat/_acceptance", "^step2_")
   ```

   Expected: every step passes its direction; E27 and P159 move only
   fortifying scenarios and vehicles; E30 and E1 only group shares.

2. **E5/E28, coverage of rice** (design: 85.5% to at most 86.6%, plus
   the 187 households with a record and no grams):

   ```r
   d <- read.csv("tests/testthat/_acceptance/step2_e5.csv")
   d[d$bloque == "vehiculos", c("etapa", "medida", "old", "new")]
   ```

3. **E1, cereal shares against the design's approximation**
   `1 - (1 - s) * T_e / T_b`:

   ```r
   d <- read.csv("tests/testthat/_acceptance/step2_e1.csv")
   d[d$bloque == "grupos" & startsWith(d$etapa, "01 "), ]
   ```
