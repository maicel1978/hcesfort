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
