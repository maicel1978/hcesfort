# Handoff

- **Date:** 2026-11-12
- **Session:** critical review of v0.1 (tasks 2 to 11); no package code
  written. Model: see the trailer of the commit.
- **Branch:** `main`

## What was done

| Commit | Content |
|---|---|
| this commit | `docs/review-v0.1.md`: end-to-end run on `hces_example` with its frictions, findings by priority (file, line, proposal), mutation check of the tests, gaps for v0.1 and for the ENGIH acceptance, integration with six packages, the ten corrections in order with the model for each |

State: `devtools::test()` passes, `devtools::check()` 0/0/0,
`lintr::lint_package()` clean with the package installed (536 false
`object_usage_linter` lints without it: review, section 8).

Task 11 stays closed. Task 12 (vignettes) is **not** the next step any more:
the review found four high-priority defects (H1 to H4) and an example
dataset that cannot carry a vignette (H6).

## Exact next step

1. The maintainer answers the five questions of section 11 of
   `docs/review-v0.1.md`.
2. One **Fable** session writes a single short design note for corrections
   1, 2, 3, 8 and 10 of section 10 (record-loss threshold, `cutpoint_valid`,
   household flags as domains, audit API for adapters, `reference_energy()`
   and per-capita vehicle grams, P60), and accepts correction 4.
3. **Opus** implements corrections 1 to 8 and 10 in that order, one commit
   each, then recalibrates `hces_example` (correction 5).
4. **Sonnet** does correction 9 (limits of the method, README) with task 12.

## Open questions

Section 11 of `docs/review-v0.1.md` (five questions, each with the
recommended option). None was decided in this session.

Sources not opened in this session (network limit): the full text of Tang
et al. 2022, the MIMI papers and IOM 2000 (*Applications in Dietary
Assessment*). Section 9 of the review marks what was checked.

## Recommended model for the next session

**Fable**: the design note of step 2 (contracts and exported interfaces).

## Maintainer review points

1. **The coverage gate does not see lost records (H1).** A third of the
   included records never reach the intake and every coverage is 1.

   ```r
   library(hcesfort)
   ex <- hces_example
   g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
   afe <- adult_equivalents(ex$members, reference_kcal = 2290.8,
                            weight_kg = c(female = 55, male = 65), pal = 1.76)
   n <- nutrient_registry(ex$nutrients)
   b <- unfortified_baseline(ex$composition, ex$enrichment, n)
   l <- link_composition(g, ex$crosswalk, b)
   i <- apparent_intake(l, afe, ex$households)
   table(l$food_code[l$include], l$composition_status[l$include])
   ok <- i$intake_status == "estimated"
   summary((i$n_records_used / i$n_records)[ok])
   range(i$iron_mg_coverage[ok])
   ```

2. **Iron by cut-point without warning (H2), and the domain that cannot be
   used (H3).**

   ```r
   use <- vehicle_coverage(g, ex$vehicles, afe, ex$households)
   s <- apply_scenario(i, use, ex$scenarios,
                       compliance_model = "average_content")
   r <- inadequacy(s, ref_requirements, min_coverage = 0.8)
   unique(r[c("nutrient", "method", "ear")])
   d <- as_hces_design(ex$households, lonely_psu = "adjust")
   fe <- flag_energy_plausibility(s, "energy_kcal", 500, 6000)
   r2 <- inadequacy(fe, ref_requirements, min_coverage = 0.8)
   try(estimate_prevalence(d, r2, "p_inadequate",
                           domain = "energy_plausible"))
   ```

3. **A proportion of zero, and the realism of the example (M5, H6).**

   ```r
   u <- above_ul(s, ref_requirements, min_coverage = 0.8)
   estimate_prevalence(d, u[u$nutrient == "folate", ], "above_ul_added")
   quantile(i$energy_kcal, c(0.1, 0.5, 0.9), na.rm = TRUE)
   ```
