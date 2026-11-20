# Handoff

- **Date:** 2026-11-20
- **Model:** Opus 5.5 (A4.2d.2: row 3; the guard of the installed hcesfort).
- **Branches:** `claude/dazzling-hypatia-h9ylzl` in `hcesfort` (docs only)
  and in `hcesfort.engih2018`, both pushed. They contain the work of
  `claude/jolly-allen-ks3f7q`; nothing is merged into `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint.
- **Earlier handoffs:** `git show edb7cbf:docs/handoff.md` (E6, the
  maintainer's runs of A4.4), `git show 9540049:docs/handoff.md` (A4.2c).

## What was done (adapter)

- `3665542`: the acceptance tests check, once per run and before reading
  the microdata, that the installed `hcesfort` has every feature the
  adapter relies on (`hcesfort_features` in `helper-acceptance.R`: the
  subtract baseline, `f283284`; the vitamin D row, `af8bc2e`); otherwise
  they stop naming the missing features and the commit to install. Add a
  row there whenever the adapter starts to rely on a new feature of
  `hcesfort`. `step2_compare()` adds a column `change` (`same`,
  `changed`, `now_missing`, `now_present`): a summary counts what goes
  missing. README says to reinstall `hcesfort` before a run.
- `46bce0e`: NEWS figures of S16 and E6 (and its sensitivity) from the
  maintainer's repeated run.
- `87d604b`: row 3 (E3, E21). No option moves, thresholds stay 0. A test
  of `test-acceptance-step2.R` writes, for the state after every step,
  `step2_coverage.csv` (block `enlace`: linkage ladder and records without
  a validated match by section, with their grams as acquired; block
  `cobertura`: per nutrient, records and grams as acquired with a value
  over all included records, edible grams with a value over the linked
  ones), `step2_missing_values.csv` and `step2_unmatched_foods.csv`.
  Expected: Section 3A without a validated match within 1 point of 10.8%;
  vitamins D and E lowest coverage of the original's nutrients; energy
  complete. Tested without microdata (`test-step2-coverage.R`).
- `hcesfort` docs: roadmap A4.2d.2 ticked; P246 (a `nutrient_coverage()`
  in the core, low).

Adapter: `devtools::test()` FAIL 0, PASS 702, SKIP 39 (microdata); lint
clean on the changed files.

## Exact next step

1. Maintainer: one run of `acceptance-step2` (now also row 3),
   and answers to the questions below.
2. A4.2d.3: E2, E18, E8 with the values the maintainer gives (each with
   its document, `data-raw/SOURCES.md`), or, where none is given, the
   original value kept and the records affected reported.
3. End of A4: self-review, `devtools::check()` and lint of the adapter.

## Open questions (A4.2d.3 needs sourced values; none from memory)

1. **E2, dozen (13 records: 12 in Section 3A, 1 in Section 2).** The
   original converts a dozen as 12 g (`unit_factors.csv`, unit 52,
   "Requiere peso unidad"). `dozen = "count"` needs the weight of one
   piece of each food sold by the dozen, with a source. Recommended: if
   you have a document (a national or INCAP table of piece weights),
   open it in the session and I enter each value with its page; if not,
   keep the original and report only the 13 records (the design expects
   no national figure to move by 0.01 point).
2. **E18, density (oil: 3,369 Section 2 rows in gallons, 634 in Section
   3A).** `density = "by_food"` needs the density of oil (and of any other
   food recorded by volume that you want corrected), with a source.
   Recommended: correct oil only, with a value from a document you open
   in the session (for instance the FAO/INFOODS density database); water
   for the rest. Without a document: keep water and report oil's grams.
3. **E8, basis of the vitamin A level of sugar (NORDOM 602, numeral 5).**
   Needs the text of the standard (is 10 mg/kg retinol or retinyl
   palmitate?) and the molecular weights of retinol and retinyl
   palmitate from a document. Recommended: run both readings as a
   sensitivity run (as `e6_fraction_1`) once the ratio is cited; the
   default stays the original's reading until the text is read.
4. **Row 3, the band of the 10.8%.** Implemented: within 1 point is
   expected; farther is a finding. Recommended: keep it (the 36,840 of
   A1 count records before the non-foods are dropped, so the share on
   the chain's records need not be exactly 10.77%).

**Answers of the maintainer (2026-11-20, A4.2d).**

0. **Correction:** the dozen (E2) covers **218 records in 22 foods**
   (P231, from A1's `e_e2_docenas`), not the 13 of the design. Rewrite the
   expected direction of E2 with that count before running it; the
   "at most 0.01 point" expectation may not hold.
1. E2 piece weights: the maintainer has no document. Look for portion
   weights in the FNDDS tables the adapter already uses (citable); if they
   are not there, keep the original value and run a sensitivity, starting
   with the foods that carry most records (passion fruit 108, sour lime 28,
   orange 22).
2. E18 density: correct oil only, from a citable density table opened in
   the session (for example FAO/INFOODS); if none can be opened, keep water
   and report the grams of oil.
3. E8 NORDOM 602: run both readings (10 mg/kg as retinol or as retinyl
   palmitate) as a sensitivity, with molecular weights from a document
   opened in the session. The text of the standard is not in
   `analisis_ENGIH2018`; `data/raw/parametros_normativos.csv` says
   "palmitato de retinol; 10-25 mg/kg; NORDOM 602 (2004), numeral 5;
   verificado", which names the compound but not the basis. The maintainer
   will look for the PDF; if it appears, choose the reading it gives.
4. Coverage margin of plus or minus 1 point around 10.8%: approved.

**Run of the maintainer (2026-11-20, A4.5, adapter 87d604b):**
`acceptance-step2` FAIL 0, PASS 37 in 1,069 s. Coverage (`step2_coverage.csv`):
of the grams with a composition link, 86% to 100% have a value for each
nutrient (iron 97.4, folate 94.3, vitamin A 93.3, zinc 97.1, B12 97.1,
vitamin D 91.2, vitamin E 86.1). Section 3A: unlinked records are 10.4% of
records but 56.2% of grams. **Finding (adviser, from
`step2_unmatched_foods.csv`):** one code explains it: `S3A:594 Agua`
(7,775 records, 4,571 households) carries 47.2% of all grams, about 98% of
the unlinked grams; without it the unlinked grams are about 0.75%. Water
is not among the 11 non-food codes dropped by the adapter. No nutrient
figure is affected (unlinked records add no nutrient), but the coverage in
grams is misleading. **Request:** in the corrected preset treat
`S3A:594 Agua` as a non-food (dropped with a count, like the purified
water), and report coverage in grams with and without water; record it in
`NEWS.md` and as a lesson (a coverage figure must exclude non-nutritive
items or say so). Also listed: `S3A:569 Caldo concentrado`, 18,087 records,
unmatched: check whether INCAP or FNDDS has a match (task for the
food-matching module, P243). Separately, 363 matched foods lose records to
units without a gram factor (`no_factor`), for example `S3A:393` (1,616
records): list them for the unit catalogue (P243).

## Recommended model for the next session

**Opus** (A4.2d.3 once the values or the decision to keep the original
are given; then the end of A4).

## Maintainer review points

1. **The guard stops a run against an old hcesfort** (expected: the
   message names `af8bc2e`):

   ```r
   # in hcesfort.engih2018, with devtools::load_all()
   testthat::source_test_helpers("tests/testthat", env = globalenv())
   f <- hcesfort_features
   f[[2]]$check <- function() FALSE
   check_hcesfort_features(f)
   ```

2. **Step 2 on the microdata, row 3 included.** Send
   `step2_coverage.csv` and the test summary:

   ```r
   # hcesfort installed from branch claude/dazzling-hypatia-h9ylzl
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance-step2")
   r <- read.csv("tests/testthat/_acceptance/step2_coverage.csv")
   r[r$etapa == "sec3a | sin_enlace_validado", ]
   r[r$bloque == "cobertura" &
       r$medida == "pct_gramos_comestibles_con_valor", ]
   ```

3. **What went missing in a step** (expected: no `now_missing` or
   `now_present` in any file):

   ```r
   for (f in list.files("tests/testthat/_acceptance", "^step2_.*\\.csv$",
                        full.names = TRUE)) {
     d <- read.csv(f)
     if ("change" %in% names(d)) print(table(basename(f), d$change))
   }
   ```
