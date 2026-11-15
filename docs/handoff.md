# Handoff

- **Date:** 2026-11-15
- **Model:** Opus 5.5 (step 12e.1).
- **Branch:** `claude/compassionate-mayer-6ajmi7`, pushed.
- **Environment:** run `R CMD INSTALL .` at the start (the Quarto render
  test uses the installed package).

## What was done

- 12e.1 (P155, P156), one commit "Refuse a repeated carrier key; range
  check of a proportion (12e.1)":
  - `require_hces()` (`R/hces-tbl.R`) calls the new `check_carrier_key()`:
    missing or repeated key columns are `hcesfort_error_key`. Every
    function that takes a carrier goes through it.
  - `estimate_households()` and `estimate_difference()` call
    `audit_check_rows()`.
  - `check_proportion_values()` (`R/estimate-checks.R`): values outside
    [0, 1] with `statistic = "proportion"` are `hcesfort_error_value`.
  - Tests: `tests/testthat/test-carrier-key.R` (new) and one test in
    `test-estimate.R`. Help of `estimate_households()` and
    `?hcesfort_errors` updated; `NEWS.md`.
- The approval of the design of 12e.5 recorded as R3-D1 to R3-D9 in
  `docs/improvements.md`; roadmap 12e.1 ticked.
- Full `devtools::test()` before the commit: 0 failures (run on the tree
  before the last two edits; the files touched by them were re-run and
  pass). `devtools::check()` and `lintr::lint_package()` not run: they run
  once at the end of task 12e. Lint of the changed files: clean (one
  `object_usage_linter` warning from the installed copy being older;
  reinstall first).

## Exact next step

**12e.2 (P160, P169, P174), Opus, in a new session.** Read only: sections
"Finding 6", "Finding 15", 5.3 and 5.4 of `docs/review-v0.2.md`, and the
ids P160, P169 and P174 in `docs/improvements.md`. Anchors from sources
outside the package (FAO examples, IOM Table I-7) need the documents: the
maintainer attaches the PDFs (R2-D9); otherwise mark `# SOURCE PENDING` and
continue with the anchors that need no document (conservation, round trip,
`svycontrast`, full-design ratio, logit interval).

Then 12e.3 (Sonnet for the text, Opus for the notes), 12e.4 (Opus), and
12e.5.1 to 12e.5.8 (Opus).

## Open questions

None.

## Recommended model for the next session

**Opus** for 12e.2.

## Maintainer review points

1. **A fanning join is refused, with the rows named:**

   ```r
   library(hcesfort)
   e <- hces_example
   d <- as_hces_design(e$households, "adjust")
   n <- nutrient_registry(e$nutrients)
   g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
   afe <- adult_equivalents(e$members,
     reference_energy("female", 25, 55, pal = 1.76),
     c(female = 55, male = 65), 1.76)
   intake <- apparent_intake(link_composition(g, e$crosswalk,
     unfortified_baseline(e$composition, e$enrichment, n)), afe, e$households)
   twice <- dplyr::bind_rows(intake, intake[1:50, ])
   estimate_households(d, twice, "iron_mg", statistic = "mean")
   # hcesfort_error_key: repeated key: 50 rows (...)
   ```

2. **An intake is not accepted as a proportion:**

   ```r
   estimate_households(d, intake, "iron_mg")
   # hcesfort_error_value naming `statistic`
   ```

3. **Rows removed outside the package are logged by the estimator:**

   ```r
   few <- dplyr::filter(intake, household_id != intake$household_id[1])
   log <- audit_log(estimate_households(d, few, "iron_mg",
                                        statistic = "mean"))
   log[log$kind == "external_change", ]
   # step estimate_households, 1 record, "removed"
   ```
