# Handoff

- **Date:** 2026-11-12
- **Model that worked:** Opus 5.5
- **Branch:** `main` (the maintainer merged `claude/happy-euler-048spl`;
  from now on every commit goes to `main`)

## What was done

| Commit | Content |
|---|---|
| `807fc96` | Task 4: reference tables with verified sources (`?reference_tables`, `data-raw/SOURCES.md`). |
| `c9ef887` | Questions for task 5; the maintainer accepted the six recommendations. |
| see `git log` | Task 5: `adult_equivalents()`; schemas `energy_requirements` and `bmr_equations`; optional `weight_kg` in `members`; decisions in `docs/improvements.md`, "Decisions (2026-11-12, task 5)". |

On the last commit: `devtools::check()` 0/0/0; `lintr::lint_package()`
clean; coverage 100%.

Environment notes: run checks as
`LANG=C.UTF-8 LC_ALL=C.UTF-8 _R_CHECK_SYSTEM_CLOCK_=0 Rscript -e 'devtools::check()'`;
run `devtools::document()` with the same `LANG`/`LC_ALL`; `lintr` needs
`R CMD INSTALL .` first. Reference data: `Rscript data-raw/reference.R`
(refuses to run if an md5 differs). The environment allows fao.org, WHO
and National Academies hosts for checking sources.

Why the session stopped: context above 50% (same-model rule).

## Exact next step

Task 6: `convert_units()` (typed factors: `mass_g`, `volume_ml` with
density, `count` with piece weight; contract in `R/schema-user.R`) and
`flag_outliers()` (P2, E9, analysis map rows 14 and the household-level
check of section 9; thresholds given by the caller, no hidden default).
Read `docs/design-task2.md` sections 3-4 for the audit log first.

## Open questions

None.

## Recommended model for the next session

**Opus 5.5**: task 6.

## Maintainer review points

1. **The reference woman is one AFE, and the original figure is
   reproduced.**

   ```r
   library(hcesfort)
   eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
   ref <- (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76   # 2290.8
   w <- data.frame(household_id = 1, member_id = 1, age_years = 25, sex = "female")
   adult_equivalents(w, ref, c(female = 55, male = 65), pal = 1.76)
   ```

2. **E10 in action: a member without age leaves the household flagged,
   not counted as zero.**

   ```r
   a <- adult_equivalents(hces_example$members, ref, c(female = 55, male = 65), 1.76)
   subset(a, is.na(afe)); audit_log(a)
   b <- adult_equivalents(hces_example$members, ref, c(female = 55, male = 65), 1.76,
                          missing = "zero")
   subset(b, household_id %in% subset(a, is.na(afe))$household_id)
   ```

3. **Task 4 (still open for you): spot-check reference values and the two
   pending ones** (`data-raw/SOURCES.md`, "Pending values").

   ```r
   ref_requirements[, c("nutrient", "ear", "ul", "ul_applies_to", "location")]
   read.csv("data-raw/requirements.csv")[, c("nutrient", "status")]
   ```
