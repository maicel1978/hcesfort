# Handoff

- **Date:** 2026-11-15
- **Model:** Fable, high effort (hostile review v0.2).
- **Branch:** `claude/amazing-euler-89d57d`, pushed. Documents only: no
  file of `R/`, `tests/`, `inst/` or `data-raw/` changed.
- **Environment:** run `R CMD INSTALL .` at the start (the Quarto render
  test uses the installed package).

## What was done

- `docs/review-v0.2.md`: the review asked by `docs/review-v0.2-brief.md`.
  One blocker, eight major and ten minor findings; the classification of
  the 48 test files by the source of their expected values; external
  anchors verified in the session; a run of 30 mutations; what the ENGIH
  validation proves and does not; nine questions.
- `docs/improvements.md`: findings recorded as P155 to P175.
- `docs/roadmap.md`: step 12e (corrections), waiting for approval.
- `devtools::test()` on the source tree: 48 files, 492 tests, 3,194
  expectations, 0 failures, 0 skipped. `devtools::check()` and the lint
  were not re-run (no code changed).

## Exact next step

**Maintainer:** read section 0 (verdict) and answer the nine questions of
section 10 of `docs/review-v0.2.md`. The render of Q4 on the ENGIH 2018
microdata can go ahead meanwhile, for your reading only: finding 9 says
why its upper-level sentences must not be shown outside yet.

After approval: 12e.1 (P155, P156), then 12e.2, both Opus.

## Open questions

The nine of section 10 of the review. The three that block work:

1. Step 12e before A2? (recommended: yes)
2. `surveytable` in `Suggests` for one test? (recommended: yes)
3. P69 (all-or-nothing compliance) before A4? (recommended: yes)

## Answers of the maintainer (2026-11-15, after the review v0.2)

Approved by the maintainer; technical criterion delegated to the advisor.

1. **Step 12e before A2:** approved. **Order by decision of the maintainer: 12e.5 first (Fable, while it is available), then 12e.1, 12e.2, 12e.3, 12e.4 (Opus; Sonnet for the text of 12e.3).** 12e.5 does not depend on 12e.1 to 12e.4.
2. **`statistic` of `estimate_households()`:** keep the default `"proportion"` and add the range check. Estimates stay proportions in the code; reports and vignettes print them as percentages.
3. **Infants:** a required argument, without default, when `members` has infants; the value 1 reproduces today's rule. The sources for the values an analyst may choose are settled in the design note of 12e.5, with the PDFs the maintainer attaches to that session (never committed).
4. **Upper level and compliance:** audit row and bound at compliance 1 in 12e.3; P69 (all-or-nothing) moves from v0.2 to before A4.
5. **Fortifiable vehicle:** optional logical column `fortifiable` in `acquisitions`, set by the adapter where the survey identifies the origin (own production, gifts in kind, home processing). If present, `vehicle_coverage()` and the scenarios use it; if absent, every gram of the vehicle is treated as fortifiable and an audit row states that assumption. What the ENGIH records on origin is checked by the ENGIH adapter (A2), not assumed here.
6. **Iron presentation:** correct the two sentences in 12e.3; effective size from the variable's own variance in 12e.4.
7. **`surveytable`:** accepted in `Suggests` for one test skipped when it is absent. AI statement in the README and `CONTRIBUTING.md`: "Developed with the help of AI tools under the author's supervision; methodological decisions and validation are the author's."
8. **Review track:** deferred. The rOpenSci pre-submission enquiry waits until the repository is public, which depends on an agreement outside this repository.
9. **Documents:** the maintainer attaches the PDFs he has to the session that needs them; they are never committed. The hosts `pmc.ncbi.nlm.nih.gov`, `joss.readthedocs.io` and `devguide.ropensci.org` are requested for the environment; until then those sources stay `# SOURCE PENDING`.

Record these in `docs/improvements.md` with the first commit of the next step. CI on `main` is checked by the advisor after this merge.

## Next session

**12e.5, Fable, high effort:** one design note (`docs/design-12e5.md`) covering P158, P159, P162 and P163 with the answers above; it fixes the interfaces Opus implements. No package code. Keep it to what changes figures before A4.

## Recommended model for the next session

Opus for 12e.1 and 12e.2. Sonnet for the text of 12e.3. Fable for 12e.5
(design note), after the answers to questions 3 to 5.

## Maintainer review points

Each needs the chain of the vignette first (`intake`, `use`, `scenarios`
and `design` as in `vignettes/getting-started.Rmd`).

1. **A repeated household changes the estimate without a word (finding 1):**

   ```r
   estimate_households(design, intake, "iron_mg", statistic = "mean")$estimate
   twice <- dplyr::bind_rows(intake, intake[1:50, ])
   twice$iron_mg[nrow(twice) - 0:49] <- 1e6
   estimate_households(design, twice, "iron_mg", statistic = "mean")$estimate
   # 10.45 and 19644.57 on hces_example; the second call should be an error
   ```

2. **The upper level under partial compliance (finding 9):**

   ```r
   full <- hces_example$scenarios
   full$compliance <- 1
   for (sc in list(hces_example$scenarios, full)) {
     s <- apply_scenario(intake, use, sc,
                         compliance_model = "average_content")
     u <- above_ul(s, ref_requirements, min_coverage = 0.8,
                   min_records_used = 0.8)
     u <- u[u$nutrient == "folate" & u$scenario == "plus_rice", ]
     print(estimate_households(design, u, "above_ul_added",
                               ci_method = "korn_graubard")$estimate)
   }
   # 0.0059 as shipped; 0.1968 at compliance 1
   ```

3. **The iron probabilities against the printed table (finding 6):** open
   <https://nap.nationalacademies.org/books/10026/gif/703.gif> (IOM 2001,
   Table I-7, menstruating women not using oral contraceptives) and
   compare a few rows with:

   ```r
   d <- subset(ref_iron_requirements, group == "females_menstruating_adult")
   t <- hcesfort:::distribution_table(d, "iron", "mg", NULL)
   # middle of the bands 4.42-4.88, 8.08-8.76 and 13.06-15.49 mg:
   round(hcesfort:::p_inadequate_probability(c(4.65, 8.42, 14.275), 0.18, t), 2)
   # 0.96, 0.45 and 0.07; the table prints 0.96, 0.45 and 0.08 (0.075,
   # the middle of the band between the 90th and 95th percentiles)
   ```
