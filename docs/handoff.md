# Handoff

- **Date:** 2026-11-15
- **Model:** Opus 5.5 (step 12e.2).
- **Branch:** `claude/peaceful-davinci-yjsc14`, pushed.
- **Environment:** run `R CMD INSTALL .` at the start (the Quarto render
  test uses the installed package). The full `devtools::test()` takes
  about 13 minutes here: run it in the background, one at a time.

## What was done

12e.2 (P160, P169, P174), three commits, no package code changed:

- "Tests for the five mutations that survived the review v0.2": S1 to S5
  in `test-estimate.R`, `test-adult-equivalents.R`, `test-above-ul.R`,
  `test-apparent-intake.R`. Each mutation was re-applied to `R/` and its
  test fails on it.
- "Anchor tests from sources outside the package": `test-anchors.R`.
  Sources opened this session: FAO/WHO/UNU 2004, examples under Table 5.1
  (`fao.org/4/y5686e/y5686e07.htm`); IOM 2001 Table I-7, p. 703
  (`nap.nationalacademies.org/books/10026/gif/703.gif`, non-OC column
  typed from the page; largest difference at the middle of a band
  0.0054). Plus conservation of nutrients, `svycontrast()`, `svyratio()`
  on the full design, `svyciprop(method = "logit")`. `surveytable` was
  left out (not a dependency; recorded in P160).
- "Golden chain on the fixture with the optional columns":
  `hces_fixture(optional = TRUE)` (built by `fixtures/hces_fixture.R`,
  file `hces-fixture-optional.rds`; the plain fixture is byte-identical),
  `data-raw/golden_example.R` handles `household_share`, `yield_factor`,
  `age_months`, `meals_home_share`, member `weight_kg`;
  `golden-optional.csv`; the two existing golden files did not change.
  `NEWS.md`, roadmap (12e.2 ticked), P160/P169/P174 marked done.

Full `devtools::test()` and lint of the changed files: see the last
commit message. `devtools::check()` and `lintr::lint_package()` run once
at the end of task 12e.

## Exact next step

**12e.3 (P157, P161, P163, P164, P170).** The roadmap splits it: the audit
notes on usual intake and on compliance with the upper level are code
(Opus); the sentences in help pages, README and vignette are text
(Sonnet). Read only the ids above in `docs/improvements.md` and findings
3, 7, 9, 10 and 16 of `docs/review-v0.2.md`. Then 12e.4 (Opus) and
12e.5.1 to 12e.5.8 (Opus).

**Decision of the advisor (2026-11-15):** 12e.3 is done whole in one Opus
session (notes and text), to save a session start. Add to it the
`surveytable` anchor left out in 12e.2: R2-D7 approved `surveytable` in
`Suggests` for one test of the Korn-Graubard interval against
`surveytable::svyciprop_adjusted()`, skipped when the package is absent.
It is the only external reference for that interval; justify the new
suggested package in the commit message. Also the AI statement of R2-D7 in
the README and `CONTRIBUTING.md`.

## Open questions

None.

## Recommended model for the next session

**Opus** for the notes of 12e.3, then 12e.4; **Sonnet** may do the text
of 12e.3 in its own session.

## Maintainer review points

1. **The FAO examples** (Table 5.1, 1,975 / 2,355 / 3,925 kcal):

   ```r
   library(hcesfort)
   c(reference_energy("female", 40, 55, pal = 1.53),
     reference_energy("female", 22, 57, pal = 1.76),
     reference_energy("male", 22, 70, pal = 2.25))
   # 1977.6 2343.0 3928.9
   ```

2. **Table I-7 of IOM 2001 (p. 703), non-OC users**, at 18% bioavailability:
   compare with the page, e.g. 7.17 mg should be near 0.65, 11.94 near 0.15.

   ```r
   d <- subset(ref_iron_requirements, group == "females_menstruating_adult")
   1 - approx(d$requirement_mg_d, d$percentile / 100,
              xout = c(4.65, 7.17, 11.94, 16.865))$y
   # 0.9625 0.6492 0.1498 0.0375
   ```

3. **The optional fixture changes the chain** (run from the package root):

   ```r
   g <- read.csv("tests/testthat/fixtures/golden-fixture.csv")
   o <- read.csv("tests/testthat/fixtures/golden-optional.csv")
   merge(g, o, by = "name", suffixes = c("_plain", "_optional"))
   ```
