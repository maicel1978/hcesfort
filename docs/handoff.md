# Handoff

- **Date:** 2026-11-12
- **Model that worked:** Opus 5.5
- **Branch:** `main`

## What was done

| Commit | Content |
|---|---|
| `9c09600` | `as_hces_design()`, `estimate_prevalence()`, `estimate_difference()`, `flag_precision()`; `survey` and `srvyr` in Imports; drafts removed from `docs/` (tasks 11.1–11.3) |
| this commit | `NEWS.md`, specification, roadmap, self-review P82–P84, decisions of task 11 recorded (11.4) |

Earlier in the same session: tasks 9 and 10 (see `git log`, commits
`2b2ea2f` to `b0b29f8`).

State: `devtools::check()` 0/0/0, `lintr::lint_package()` clean, all tests
pass, coverage 100% of `R/` by `covr` (the last uncovered line was
tested before this commit). Every estimator agrees with `survey` on a
hand-built design to 1e-8.

Why the session stops: task 11 is closed; task 12 (vignettes) is assigned to
Sonnet in `docs/model-routing.md`.

## Exact next step

Task 12: vignettes in English (the Spanish version of the main vignette is
added in this task too, CLAUDE.md): from the standard tables to risk by
scenario on `hces_example`, the full chain being
`convert_units()` → `unfortified_baseline()` → `link_composition()` →
`adult_equivalents()` → `apparent_intake()` → `vehicle_coverage()` →
`apply_scenario()` → `inadequacy()` / `above_ul()` → `as_hces_design()` →
`estimate_prevalence()` / `estimate_difference()`; how to write an adapter;
plotting with the user's `ggplot2` code. The examples of each help page
already run that chain and can be the starting point. P71 (mapping
`ref_who2009_flour` rows to scenarios, five lines, vitamin A form as the
user's reading) belongs in the main vignette. `knitr`, `rmarkdown` and
`ggplot2` go to Suggests.

## Open questions

None blocking. P75, P79 and P82 list the choices taken in implementation
of tasks 9–11, for the maintainer to confirm or change.

## Recommended model for the next session

**Sonnet 5.5**: task 12 (vignettes).

## Maintainer review points

1. **The upper-level units read for task 10.1** (IOM 1998, pp. 280 and 282;
   IOM 2001, pp. 127 and 143–145), read through the online reader of the
   National Academies Press.

   ```r
   library(hcesfort)
   ref_requirements[, c("nutrient", "unit", "ul", "ul_unit", "ul_applies_to")]
   ref_conversions[, c("from_form", "ul_form", "ul_form_location")]
   ```

2. **An estimate against survey, on the example.**

   ```r
   g <- convert_units(hces_example$acquisitions, hces_example$unit_factors,
                      priority = "food")
   afe <- adult_equivalents(hces_example$members, reference_kcal = 2290.8,
                            weight_kg = c(female = 55, male = 65), pal = 1.76)
   use <- vehicle_coverage(g, hces_example$vehicles, afe,
                           hces_example$households)
   d <- as_hces_design(hces_example$households, lonely_psu = "adjust")
   estimate_prevalence(d, use, "acquired", by = "region")
   ```

3. **A paired difference between scenarios** (the mean of the
   within-household difference equals the difference of the means when both
   scenarios have the same households).

   ```r
   n <- nutrient_registry(hces_example$nutrients)
   b <- unfortified_baseline(hces_example$composition,
                             hces_example$enrichment, n)
   i <- apparent_intake(link_composition(g, hces_example$crosswalk, b), afe,
                        hces_example$households)
   s <- apply_scenario(i, use, hces_example$scenarios,
                       compliance_model = "average_content")
   r <- inadequacy(s, ref_requirements, min_coverage = 0.8)
   estimate_difference(d, r, "p_inadequate", reference = "baseline")
   ```
