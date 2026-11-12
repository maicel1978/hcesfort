# Handoff

- **Date:** 2026-11-12
- **Model that worked:** Opus 5.5
- **Branch:** `claude/happy-euler-048spl` (the session's development branch;
  `main` has not been touched)

## What was done

| Commit | Content |
|---|---|
| see `git log` | Task 4: reference tables with sources. Six CSV files in `data-raw/`, their sources in `data-raw/SOURCES.md`, md5 registry `data-raw/MD5`, build script `data-raw/reference.R`, six exported datasets (`?reference_tables`), tests in `tests/testthat/test-reference-data.R`. |

`devtools::check()` 0/0/0; `lintr::lint_package()` clean.

Every value was read in the document itself, opened in the session: FAO/WHO/UNU
2004 (fao.org), IOM DRI reports 1998, 2000, 2001 and 2011
(nap.nationalacademies.org) and WHO 2009 (iris.who.int). To open them the
session's environment ("Default") gained these allowed hosts, approved by
the maintainer: `www.fao.org`, `www.ncbi.nlm.nih.gov` (blocked by a
reCAPTCHA, not used), `iris.who.int`, `www.who.int`, `apps.who.int`,
`nap.nationalacademies.org`, `www.nap.edu`, `www.nationalacademies.org`.

Result: every value used by `analisis_ENGIH2018` agrees with its document.
Pending (not shipped): the intake the vitamin D UL applies to, and a factor
from retinyl palmitate to RAE (E8).

Environment notes: run checks as
`LANG=C.UTF-8 LC_ALL=C.UTF-8 _R_CHECK_SYSTEM_CLOCK_=0 Rscript -e 'devtools::check()'`;
run `devtools::document()` with the same `LANG`/`LC_ALL`; `lintr` needs
`R CMD INSTALL .` first. Rebuild the reference data with
`Rscript data-raw/reference.R` (it refuses to run if an md5 differs).

## Exact next step

Task 5: `adult_equivalents()`, once the maintainer answers the questions
below (they decide its interface). Context: `docs/improvements.md` P53;
`docs/analysis-map.md` rows 12-13, E10, E25; members contract in
`R/schema-standard.R`.

## Open questions (task 5)

1. **Adult energy requirement.** Body weight and physical activity level
   (PAL) as required arguments without default (`weight_kg = c(female =,
   male =)`, `pal =`), with an optional per-member `weight_kg` column that
   overrides them? *Recommended: yes;* no hidden default, and the ENGIH
   adapter passes 55/65 kg and PAL 1.76 explicitly.
2. **Reference person.** Given as a number of kcal/day (`reference_kcal`),
   with a documented example that computes 2,290.8 from `ref_bmr_equations`,
   rather than as sex, age, weight and PAL? *Recommended: kcal;* one number,
   visible in the call, and any convention can produce it.
3. **Infants.** Use the monthly FAO table when `age_months` is present, and
   the mean of the twelve months (the original rule) otherwise, counting
   those infants in the audit log? *Recommended: yes;* the mean stays as the
   legacy option for acceptance step 1.
4. **Pregnancy and lactation.** No extra energy in v0.1: the flags are not
   used, and flagged members are counted in the audit log? *Recommended:
   yes;* the FAO additions per trimester were not opened in this session
   and the original did not apply them.
5. **Members without age or sex (E10).** The household's AFE is `NA` and the
   household is flagged (counted in the log), and the decision to exclude it
   is taken in task 8? The original rule (zero AFE) is a legacy option.
   *Recommended: yes;* "detect, then decide".
6. **Meals at home (E25).** When `meals_home_share` is present, multiply
   each member's AFE by it only if the caller says so (`meal_share =
   TRUE/FALSE`, required when the column exists)? *Recommended: yes;* no
   silent use of an optional column, and no hidden default.

## Recommended model for the next session

**Opus 5.5**: task 5.

## Maintainer review points

1. **Spot-check three values against the documents.** Pick any rows and
   open the page given in `location`:

   ```r
   library(hcesfort)
   ref_requirements[, c("nutrient", "ear", "ul", "ul_applies_to", "location")]
   subset(ref_iron_requirements, group == "females_menstruating_adult")
   ref_who2009_flour[ref_who2009_flour$availability_g_d == "<75",
                     c("nutrient", "compound", "level_mg_kg")]
   ```

2. **The two pending values.** Read the pending table in
   `data-raw/SOURCES.md`; if you find the IOM 2011 statement on the intake
   the vitamin D UL applies to, change `status` to `verified` in
   `data-raw/requirements.csv`, update `data-raw/MD5` and rebuild:

   ```r
   read.csv("data-raw/requirements.csv")[, c("nutrient", "ul_applies_to", "status")]
   read.csv("data-raw/nutrient_conversions.csv")[, c("from_form", "factor", "status")]
   ```

3. **A changed value is caught.** Edit any number in a CSV and run the
   tests from the source tree; the md5 test fails:

   ```r
   devtools::test(filter = "reference")
   ```
