# Handoff

- **Date:** 2026-11-12
- **Model that worked:** Opus 5.5
- **Branch:** `main`

## What was done

| Commit | Content |
|---|---|
| `2b2ea2f` | Approval of the designs of tasks 9 and 10 recorded; contracts `form`, `vehicle_group`, `enrichment` (9.1) |
| `b583de8` | `unfortified_baseline()` (9.2) |
| `a3053c8` | `vehicle_coverage()` (9.3) |
| `768c3a9`, `1096235` | `apply_scenario()`; close task 9 (9.4) |
| `c9af011` | `ul_unit`, `ul_form` in the reference tables (10.1) |
| `dd770a1`, `b0c0059` | `inadequacy()` (10.2, 10.3); `survey` in Suggests |
| `b0b29f8` | `above_ul()`; close task 10 (10.4) |
| this commit | Handoff; drafts of task 11 kept outside the package |

State: `devtools::check()` 0/0/0, `lintr::lint_package()` clean, all tests
pass, coverage near 100% (checked with `covr` during the session).
Tasks 9 and 10 are closed. Self-review items: P75–P81 in
`docs/improvements.md`.

Why the session stopped: the maintainer asked to stop. Task 11 had just
started; its two draft files (`as_hces_design()` and
`estimate_prevalence()`, untested, missing helpers) were moved out of `R/`
to `docs/drafts-task11/` so the package stays green.

## Exact next step

1. The maintainer answers the questions below (task 11).
2. Implement task 11 by sub-items 11.1–11.4 of the roadmap, starting from the
   drafts: missing helpers are `check_value_column()`,
   `check_estimate_args()`, `by_cells()`, `estimate_log()`, then
   `estimate_difference()` and `flag_precision()`. Add `survey` and `srvyr`
   to Imports. Test every estimator against `survey::svyciprop()`,
   `svymean()`, `svyquantile()` on a hand-built design (1e-8).

## Open questions (task 11), each with the recommendation

1. **Strata with a single PSU.** `as_hces_design(lonely_psu =)` required, no
   default, values of `survey.lonely.psu`; applied per call and the global
   option restored. *Recommended* (P12 asks for an explicit choice).
2. **Interval for proportions.** Default `ci_method = "logit"`
   (`survey::svyciprop()` default, stays in [0, 1]); `"mean"` reproduces the
   original's symmetric interval in acceptance step 1. *Recommended.*
3. **Degrees of freedom.** Default `df = "domain"` (`degf()` of the domain
   subset, what the original's report states and what `survey` does on a
   subset); options `"design"` or a number. *Recommended.*
4. **Median interval.** `survey::svyquantile()` default (Woodruff,
   `interval.type = "mean"`, `qrule = "math"`). *Recommended*; the original
   gave no interval for medians.
5. **Precision rule.** A separate `flag_precision(estimates, min_n,
   max_half_width)` with both limits required (the original's n < 50 and
   10 pp have no source), not built into the estimators. *Recommended:*
   detect, then decide.
6. **Paired differences.** Mean of the within-household difference between a
   scenario and a reference scenario (`reference` required), on households
   estimated in both, as a domain of the full design. *Recommended* (the
   original's method, `07:213-226`).

## Recommended model for the next session

**Opus 5.5**: implementation of task 11 once the questions are answered.

## Maintainer review points

1. **The upper-level units read for task 10.1** (IOM 1998, pp. 280 and 282;
   IOM 2001, pp. 127 and 143–145). They were read through the online reader
   of the National Academies Press; check the places.

   ```r
   library(hcesfort)
   ref_requirements[, c("nutrient", "unit", "ul", "ul_unit", "ul_applies_to")]
   ref_conversions[, c("from_form", "ul_form", "ul_form_location")]
   ```

2. **The baseline of the example: what enrichment removed** (pasta C04:
   iron 3.3 → 1.5, folate 400 → 136).

   ```r
   n <- nutrient_registry(hces_example$nutrients)
   b <- unfortified_baseline(hces_example$composition,
                             hces_example$enrichment, n)
   b[b$composition_id %in% c("C02", "C04", "C13"),
     c("composition_id", "iron_mg", "folate_ug_dfe", "baseline_status")]
   ```

3. **The iron probability on the shipped table** (design of task 10,
   section 3): 1, 0.975, 0.5, 0.025, 0 and 0.5.

   ```r
   d <- subset(ref_iron_requirements, group == "females_menstruating_adult")
   t <- hcesfort:::distribution_table(d, "iron", "mg", NULL)
   hcesfort:::p_inadequate_probability(c(4, 4.42, 8.07, 18.23, 19), 0.18, t)
   hcesfort:::p_inadequate_probability(14.526, 0.10, t)
   ```
