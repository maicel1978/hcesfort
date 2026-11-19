# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A3 closed; A4.0 and A4.1).
- **Branches:** `claude/sleepy-albattani-s7uctu` in `hcesfort` (docs only)
  and in `hcesfort.engih2018` (tests and `NEWS.md`), both pushed. They
  continue `claude/sleepy-feynman-dduxu5`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before lint.
- **Earlier handoff:** `git show 4c3ad0e:docs/handoff.md` (A3.5).

## What was done

| Repo | Commit | Content |
|---|---|---|
| hcesfort | `6662cbb` | E30 in `docs/analysis-map.md` (section 11); P241 confirmed, P242 updated; P243 (preprocessing module, high, v0.2) in `docs/improvements.md` and the roadmap; A3 ticked. |
| adapter | `25f8c97` | P239: `helper-fixture-design.R` (household 12_1, two PSUs per stratum) and `test-acceptance-controls-ci.R`; the smoke run no longer replaces the design. |
| adapter | `ca27a0d` | Step 2 harness: `helper-step2.R` (the steps in order, each with options, chain arguments and expected direction; states accumulate), `helper-step2-figures.R` (national figures of a state: risk, summary, vehicles, group shares; comparison old/new; direction checks), `test-acceptance-step2.R` (microdata; writes `step2_<id>.csv`), `test-step2-ci.R` (every step on the invented survey; the `everywhere` directions). First step E10 (`missing_members = "na"`). `control_groups(drop =)`. |
| adapter | `935bd18` | E11: `stock_missing = "known"`. `days_missing` not added (no record lacks its day). |
| adapter | `b8d1b57` | E29: `share = "survey"`. |

Tests of the adapter: 545 pass, 26 skipped here. `lintr::lint_package()`
clean. `devtools::check()` not run (once at the end of A4).

Order: the design puts rows 1 to 5 first. Rows 1 and 2 move no figure
(NEWS entries still to write); row 3 waits for the maintainer (question
1); rows 4 and 5 wait for their sources (P233). So E10 is the first step
with code.

## Exact next step

A4.2 (Opus), one commit per step, each added to `step2_steps` in
`helper-step2.R` with its direction (design section 5) and a `NEWS.md`
entry "figures pending":

1. NEWS entries for rows 1 and 2 (E16, E26; E12 to E15, E17, E22): no
   figure, corrected by construction.
2. E27: `vehicles = "all"`. Direction: vehicle coverage and grams rise or
   stay; scenario 0 unchanged; shares below the EAR of scenarios 1a to 3
   fall or stay (`everywhere`).
3. E5/E28: consumer of a vehicle = `acquired`, households without records
   out of the denominator: needs a measure option in `control_vehicles()`
   (`consumer_table()`, helper-controls-other.R) carried by the state.
4. P159: `fortifiable = "use"` (a `step1_args` change). Scenario 0
   unchanged; added amounts fall or stay.
5. E30 (`groups = "code"` in the state), then E1 (`group_shares =
   "baseline"`; only iron and folate move).
6. E7, E24, then S8/S16 and S2 (`priority = "food"`).

Then the maintainer runs step 2 (review point 1). Stop near 50% of
context.

## Open questions

1. **Row 3 of design section 5 (E3, E21): which gates?** Step 1 uses
   `min_coverage = 0` and `min_records_used = 0` in `inadequacy()` and
   `above_ul()`. Recommended: keep 0 for the national figures of step 2
   and report the coverage of each nutrient (vitamins D and E flagged), so
   that no figure disappears before you choose a threshold; give the
   threshold when you want it applied, and it becomes its own step.

**Answers of the maintainer (2026-11-19, A4.1).** Thresholds of E3/E21
(`min_coverage`, `min_records_used`): approved as recommended, 0 in step 2
and the coverage of each nutrient reported; the maintainer chooses the
thresholds later, as a step of its own.

**Two requests for every remaining correction of A4:**

1. Each correction commit states in one line the *class* of the root cause
   (for example: text join, unit conversion, silent filter, reference value
   without source, degrees of freedom, missing value read as zero). They feed
   `docs/lessons.md` after A4.
2. A4.1 ran at medium effort by mistake. The next session (high effort)
   starts by re-reading the diffs of E10, E11 and E29 (`ca27a0d`,
   `935bd18`, `b8d1b57`) against design section 5 before adding new
   corrections, and reports anything it would change.

## Recommended model for the next session

**Opus** (A4.2: implementing the corrections of an approved design).

## Maintainer review points

1. **Step 2 on the microdata** (E10, E11, E29; about three minutes). Send
   the three `step2_*.csv` and the test summary:

   ```r
   # in hcesfort.engih2018, branch claude/sleepy-albattani-s7uctu, with
   # hcesfort installed from the same branch name
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   list.files("tests/testthat/_acceptance", "^step2_")
   ```

   Expected: E10 and E11 move no figure; E29 lowers intake, the national
   rows `n` do not move.

2. **The size of E29** (the share below the EAR at scenario 0, before and
   after):

   ```r
   d <- read.csv("tests/testthat/_acceptance/step2_e29.csv")
   d[d$bloque == "riesgo" & d$medida == "pct_inadecuado" &
       grepl("^0\\. .*\\| Todos \\|", d$etapa), c("etapa", "old", "new")]
   ```

3. **The control comparisons in CI** (runs without the microdata):

   ```r
   devtools::test(filter = "controls-ci|step2-ci")
   ```
