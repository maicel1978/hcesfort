# Handoff

- **Date:** 2026-11-20
- **Model:** Opus 5.5 (A4.3, first part: A4.2c).
- **Branches:** `claude/sleepy-volta-wr6ir4` in `hcesfort` (vitamin D row,
  docs) and in `hcesfort.engih2018` (S16, NEWS), both pushed. They continue
  `claude/adoring-mayer-s0mm5x`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint.
- **Earlier handoffs:** `git show 0a4f236:docs/handoff.md` (A4.2b, the
  maintainer's answers on S16 and the figures of E24, S8, S2).

## Corrections still open (design of the adapter, section 5), in order

| Row | Error | State |
|---|---|---|
| 3 | E3, E21 | thresholds stay 0 (answer of the maintainer); coverage of each nutrient to report. No figure moves |
| 4 | E2 | dozen as `count`: piece weights need a source (P233) |
| 5 | E18 | density by food: densities need a source (P233) |
| 12 | E6 | `"subtract"` with pairs: questions 2 and 3 below |
| 15 | E8 | level basis: sensitivity, ratio of molecular weights `# SOURCE PENDING` |
| 17 | S16 | done in this session (figures pending) |

Done: rows 1, 2, 6 to 11, 13, 14, 16, S8, S2, S16.

## What was done

`hcesfort`:

- Vitamin D row of `ref_requirements` verified and shipped. Read in IOM
  2011, opened in this session (`nap.nationalacademies.org/read/13050`):
  Summary Tables, Tolerable Upper Intake Levels, Vitamins, p. 1112, NOTE
  ("Unless otherwise specified, the UL represents total intake from food,
  water, and supplements"; vitamin D has no footnote); chapter 8, p. 498.
  EAR (Table 5-3, p. 363; p. 389) and UL (Table 6-4, p. 441; pp. 443–445)
  re-read: unchanged. `data-raw/requirements.csv`, `MD5`, `SOURCES.md`,
  `?ref_requirements`, NEWS, test.

Adapter:

- S16: `requirements = "package"` takes `ref_requirements` and, for iron,
  only the group `females_menstruating_adult` (`engih_iron_package()`);
  a test shows the package's tables equal the original's value by value,
  except the vitamin E upper level (blank in the original).
- Step `s16` of step 2: expected direction, **no figure moves**.
- NEWS: figures of E24, S8 and S2 from the maintainer's run; S16 entry.

**Finding on S16, vitamin E.** The approved answer expected 0% above the
UL in every scenario. The package gives a missing share instead:
`above_ul()` sets `ul_scope = "not_assessable"` when no scenario adds the
form and the diet has none (`R/above-ul-log.R`, `ul_parts()`). So vitamin
E stays missing, as in the original. See question 1.

## Exact next step

1. Maintainer's answers to the questions below.
2. E6 (row 12) with the answers: the enrichment table of `"pairs"` in the
   adapter (`inst/extdata/`, from INCAP rows already registered), its
   option made available, step `e6` with the direction of the design.
3. Row 3 (E3, E21): report the coverage of each nutrient; no figure moves.
4. E2, E18, E8 under the rule "cite and check, or keep the original
   value and report the sensitivity".
5. At the end of A4: `devtools::check()` and lint of the adapter, and the
   step 2 command for the maintainer.

## Open questions

1. **Vitamin E above the UL.** The package reports it missing
   (`not_assessable`), not 0%. Recommended: keep it missing; 0% would
   state a comparison the data cannot make (no supplement is recorded),
   and changing it would change `above_ul()` (Fable). Alternative: report
   0% by construction in the adapter's tables only.
2. **E6, whole-grain rows without a rule.** The design says "no rule for
   the three whole-grain rows" without naming them. By the INCAP names in
   `composition.csv`: `70213158` Whole wheat flour, `70214039` Whole
   wheat bread, roll type, `70214103` Whole grain cookies with honey.
   Recommended: these three. (Oat bread `70214121` keeps its rule.)
3. **E6, ingredient fractions.** The fractions (bread 0.7, crackers 0.85,
   biscuits 0.6, pastry 0.4) are provisional in the original (`SOURCE
   PENDING`). Recommended: keep them under `"pairs"` (the maintainer's
   rule: keep the original value and report the sensitivity), with a run
   at fraction 1 as sensitivity. Pairs: rice 70213002 against 70213004;
   flour 70213039 (enriched) against 70213038.

## Recommended model for the next session

**Opus** (E6 and row 3 once answered; implementation of the design).

## Maintainer review points

1. **The vitamin D row** (expected: EAR 10, UL 100, `total`):

   ```r
   subset(hcesfort::ref_requirements, nutrient == "vitamin_d",
          c(ear, ul, ul_unit, ul_applies_to, location))
   ```

   And open IOM 2011, p. 1112 (`/read/13050/chapter/24`), the NOTE under
   the vitamins UL table.

2. **Step 2 on the microdata** (thirteen steps; about 27 minutes). Send
   `step2_s16.csv` and the test summary:

   ```r
   # in hcesfort.engih2018, branch claude/sleepy-volta-wr6ir4, with
   # hcesfort installed from the same branch name
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   d <- read.csv("tests/testthat/_acceptance/step2_s16.csv")
   d[!(d$difference %in% 0) & !(is.na(d$old) & is.na(d$new)), ]
   ```

   Expected: every step passes; the last line returns no rows.

3. **The scope of vitamin E's upper level** (question 1):

   ```r
   t <- hcesfort.engih2018::engih2018_tables(
     hcesfort.engih2018::engih2018_options(requirements = "package"))
   t$requirements[t$requirements$nutrient == "vitamin_e",
                  c("ul", "ul_applies_to")]
   ```
