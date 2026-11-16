# Handoff

- **Date:** 2026-11-15
- **Model:** Opus 5.5 (step 12e.3, notes and text in one session).
- **Branch:** `claude/intelligent-lovelace-jj6ijo`, pushed.
- **Environment:** run `R CMD INSTALL .` at the start (the Quarto render
  test uses the installed package). The full `devtools::test()` takes
  about 13 minutes here: run it in the background, one at a time.

## What was done

12e.3 (P157, P161, P163, P164 sentences, P170), see the commit messages:

- Audit notes: `apparent_intake()` writes `period_days` (range of the
  records used); `inadequacy()` and `above_ul()` write
  `apparent_intake_not_usual_intake` with that range; `above_ul()` flags
  `average_content_understates_ul`, one row per scenario with a compliance
  below 1 under average content; the note `compliance_below_one` of
  `apply_scenario()` now has one row per scenario (detail = its name).
- Text: "What the figures are and are not" in `?inadequacy` (four IOM
  quotations), `?above_ul`, `?apply_scenario`; tail rule cited (IOM 2001,
  Table I-7, p. 703, footnote d); `?flag_presentation` and departure S2
  (en, es) corrected; README rewritten (status, chain, limits, AI
  statement); `CONTRIBUTING.md` AI statement; vignette section 5 (the
  audit note, and the folic acid share as shipped 0.59% against 19.7% at
  compliance 1); results report: note `ul_average_content` under the
  upper-level exhibit; `data-raw/SOURCES.md` new section with the quotations.
- New items: P182 (sensitivity by days observed, task 12), P183 (the limit
  of finding 3 stated in the reports, high, before the first expert round).

## Not done

- **`surveytable` anchor (R2-D7).** Installing `surveytable` from CRAN was
  refused by the session's permission classifier, so the call
  `surveytable::svyciprop_adjusted()` could not be checked, and an unrun test
  is not written (CLAUDE.md: never call a function without checking it).
  See open question 1.

## Exact next step

**12e.4 (P165 to P168, P172; the effective size of P164 under R2-D6).**
Read only those ids in `docs/improvements.md` and findings 10 to 14 and 18
of `docs/review-v0.2.md`. P183 (report note on usual intake) can go with
it. Then 12e.5.1 to 12e.5.8 (Opus). `devtools::check()` and
`lintr::lint_package()` once at the end of task 12e.

## Open questions

None. **Answer of the maintainer (2026-11-15):** `surveytable` may be installed
from CRAN in the 12e.4 session (`install.packages("surveytable", lib =
Sys.getenv("R_LIBS_USER"))`); the maintainer approves the permission prompt.
Check the call with `?surveytable::svyciprop_adjusted` and by running it, then
write the anchor test of R2-D7 (Suggests, `skip_if_not_installed()`). If the
install is still refused, record it and drop the test: the published NCHS rows
remain the reference for the Korn-Graubard interval.

**Also in 12e.4 (advisor):** try `Config/testthat/parallel: true` to shorten
the full suite. Keep it only if the parallel run gives the same counts and
no new failure or warning than the serial run; otherwise revert and record why.

## Recommended model for the next session

**Opus** (12e.4).

## Maintainer review points

1. **The two new audit notes on `hces_example`:**

   ```r
   library(hcesfort)
   example(above_ul)
   l <- audit_log(ul)
   l[l$cause %in% c("apparent_intake_not_usual_intake",
                    "average_content_understates_ul"), c("cause", "detail")]
   ```

2. **The quotations in `?inadequacy`** against IOM 2000b pp. 73, 81 (Box
   4-1), 99 and IOM 2001 p. 703 (footnotes a and d); they were read in the
   review session, not reopened in 12e.3:

   ```r
   ?hcesfort::inadequacy   # section "What the figures are and are not"
   ```

3. **The README reads as the package is** (render it and run its chain):

   ```r
   rmarkdown::render("README.md", output_dir = tempdir())
   ```
