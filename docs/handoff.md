# Handoff

- **Date:** 2026-11-20
- **Model:** Opus 5.5 (A4.2d.1: E6).
- **Branches:** `claude/jolly-allen-ks3f7q` in `hcesfort` (docs only) and
  in `hcesfort.engih2018` (E6), both pushed. They continue
  `claude/sleepy-volta-wr6ir4`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint.
- **Earlier handoffs:** `git show 9540049:docs/handoff.md` (A4.2c, S16,
  the maintainer's answers on vitamin E and E6).

## Corrections still open (design of the adapter, section 5), in order

| Row | Error | State |
|---|---|---|
| 3 | E3, E21 | thresholds stay 0; coverage of each nutrient to report. No figure moves |
| 4 | E2 | dozen as `count`: piece weights need a source (P233) |
| 5 | E18 | density by food: densities need a source (P233) |
| 15 | E8 | level basis: sensitivity, ratio of molecular weights `# SOURCE PENDING` |

Done: rows 1, 2, 6 to 14, 16, 17 (S8, S16), S2. Row 12 (E6) done in this
session, figures pending.

## What was done (adapter)

- `bc6e18b`: `enrichment = "pairs"` available. 32 rules in
  `inst/extdata/enrichment_pairs.csv` (`data-raw/enrichment_pairs.R`, md5
  registered, `SOURCES.md`): rice 70213002 against 70213004; wheat
  products against 70213039 / 70213038 at the original's fractions. No
  rule for the three whole-grain rows (answer of 2026-11-20) nor for the
  three rows named "unenriched" (question 1). New value
  `"pairs_fraction_1"`: the sensitivity run. Cells tested by hand.
- `707d3c1`: step `e6` (options `enrichment = "pairs"`, argument
  `baseline_method = "subtract"`), **appended after `s16`** so that the
  figures already in NEWS keep their meaning (question 2); its expected
  direction in `helper-step2-e6.R`; sensitivity run `e6_fraction_1`
  (`step2_e6_fraction_1.csv`); NEWS entries for E6 and the vitamin E
  decision.

**Finding P244.** The design says no baseline cell falls below its
legacy value. One does: folate of pasta 70213057 ("Pasta, unenriched,
raw", 18 µg DFE per 100 g), which the legacy rule raised to 26 (flour)
and the subtraction leaves at 18. Iron holds cell by cell, so the step
expects iron intake to rise or stay everywhere; folate is expected to
rise on the microdata, but not by construction.

## Exact next step

1. Maintainer: answers below, then one run of step 2 (S16 and E6
   together, as agreed).
2. A4.2d.2, row 3 (E3, E21): report the coverage of each nutrient
   (`hcesfort::missing_values()`, `unmatched_foods()` on the chain's
   linked content); share of Section 3A records without a validated
   match near 10.8% (design row 3). No figure moves.
3. A4.2d.3: E2, E18, E8 under the rule "cite and check, or keep the
   original value and report the sensitivity".
4. End of A4: self-review, `devtools::check()` and lint of the adapter.

## Open questions

1. **Rows named "unenriched" (70213004 rice, 70213038 flour, 70213057
   pasta).** Implemented: no rule (nothing was added to them).
   Recommended: keep it. For rice and flour it changes nothing; for the
   pasta the pair would lower iron from 1.30 to the floor 1.17 mg per
   100 g, removing enrichment the row does not have. Alternative: keep
   the design's rule for every legacy row but the whole-grain ones.
2. **Order of E6 in step 2.** Implemented: after S16, not as row 12.
   Recommended: keep it; moving it would change the "old" side of E1, E7,
   E24, S8, S2 and S16, whose figures are already in NEWS. Alternative:
   the order of the design, and a rerun of every step after it.

**Answers of the maintainer (2026-11-20, A4.4):** both approved as
recommended. 1, no rule for the unenriched rows (70213004, 70213038,
70213057). 2, E6 at the end of the sequence, after S16.

## Recommended model for the next session

**Opus** (row 3, then E2, E18, E8; implementation of the design).

## Maintainer review points

1. **The pairs table and its cells** (expected: 32 rules; bread 70214019
   iron 1.001, folate 18.2):

   ```r
   e <- read.csv(system.file("extdata", "enrichment_pairs.csv",
                             package = "hcesfort.engih2018"),
                 colClasses = "character")
   table(e$vehicle, e$enriched_ref_id)
   ```

2. **The rows left out, by name** (three whole-grain, three "unenriched"):

   ```r
   t <- hcesfort.engih2018::engih2018_tables()
   ids <- c("70213158", "70214039", "70214103",
            "70213004", "70213038", "70213057")
   t$composition[t$composition$composition_id %in% ids,
                 c("composition_id", "name", "iron_mg", "folate_ug_dfe")]
   ```

3. **Step 2 on the microdata** (fourteen steps and one sensitivity run).
   Send `step2_s16.csv`, `step2_e6.csv`, `step2_e6_fraction_1.csv` and the
   test summary:

   ```r
   # in hcesfort.engih2018, branch claude/jolly-allen-ks3f7q, with
   # hcesfort installed from the same branch name
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   moved <- function(f) {
     d <- read.csv(file.path("tests/testthat/_acceptance", f))
     d[!(d$difference %in% 0) & !(is.na(d$old) & is.na(d$new)), ]
   }
   moved("step2_s16.csv")   # expected: no rows
   moved("step2_e6.csv")    # expected: iron and folate rows only
   ```
