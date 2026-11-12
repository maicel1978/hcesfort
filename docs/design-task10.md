# Design of roadmap task 10: `inadequacy()` and `above_ul()`

Status: **approved 2026-11-12** (all choices of section 9 as
recommended; see `docs/improvements.md`). Implemented by Opus.

Inputs read: P7, P11, P51, P55, P56 of `docs/improvements.md`; E5, E7, E13,
E14, E21 of `docs/analysis-map.md`; `ref_requirements`,
`ref_iron_requirements`, `ref_conversions` and `data-raw/SOURCES.md`;
`scripts/07_riesgo_inadecuacion.R:48-115` and `valores_referencia.csv`,
`hierro_requerimiento.csv` of the original analysis.

`stats::approx()` was run with the shipped iron table; the figures of
section 3 come from that run.

## 1. What the two functions are, and are not

Both take intake per adult female equivalent (AFE) per day, one value per
household, and compare it with a reference value of the reference person.
They return **one row per household, scenario and nutrient**, with a number
between 0 and 1. They estimate nothing: proportions, intervals and paired
differences are task 11, on the full design.

What the numbers mean, stated in the help pages: the share of households
whose apparent intake per AFE is below a requirement (or above an upper
level). They are not prevalences of deficiency or of excess in persons: the
intake is apparent, weekly, and shared within the household in proportion to
energy requirements; nutrient requirements do not scale with energy.

The requirement used is that of the reference person of the AFE. The caller
passes a `requirements` table with **one row per nutrient**; several rows
for a nutrient are `hcesfort_error_key` (the caller filters the group).
`ref_requirements` holds one group today (P51).

## 2. `inadequacy()`

```r
inadequacy(x, requirements, distribution = NULL, bioavailability = NULL,
           min_coverage)
```

`x`: `hces_scenario_intake` or `hces_intake` (then `scenario` is missing in
the result). Returns `hces_inadequacy`, long (the exception of P55: the unit
is in the column `unit`), key `scenario` + `household_id` + `nutrient` +
`bioavailability`.

| Column | Content |
|---|---|
| `scenario`, `household_id`, `intake_status` | from `x` |
| `nutrient`, `unit` | registry name and unit |
| `intake`, `added` | total and added amount per AFE per day (`added` is 0 for `hces_intake`) |
| `coverage` | share of the household's edible grams with a value for the nutrient (baseline) |
| `method` | `ear_cutpoint` or `probability` |
| `ear` | the requirement compared (cut-point rows) |
| `bioavailability` | value used (probability rows; missing otherwise) |
| `p_inadequate` | 1 or 0 for the cut-point; a probability for the probability approach; missing when the household is not `estimated` |

Nutrients assessed: those of the registry with a row in `requirements` and a
non-missing `ear`. Registry nutrients without a requirement and requirement
rows without a registry nutrient are notes. The unit of each requirement row
must equal the registry unit, otherwise `hcesfort_error_units` (P55).

### Cut-point

`p_inadequate = as.numeric(intake < ear)`, strict, as in the original
(`07:99`). Nutrients named in `distribution` do not get a cut-point row: for
them the method is not valid, which is why the distribution is given.

### Coverage (P11, E21)

`min_coverage` is required, a number in [0, 1] (0 accepts everything and
says so). For each nutrient the function computes the overall coverage: the
share of the edible grams of the estimated households that carry a value
(`Σ coverage × qty_edible_g_d × afe / Σ qty_edible_g_d × afe`, unweighted,
on the baseline). A nutrient below `min_coverage` raises
`hcesfort_error_coverage`, listing every nutrient below it with its
coverage and the two ways out: `fill_composition()`, or leaving the nutrient
out of `requirements`. The per-household coverage stays in the result, so a
domain can be defined on it in task 11. Nothing is excluded here.

Why an error and not a flag: a share below the requirement computed with a
third of the grams missing is a different quantity, not a noisier one (the
original's 95.8% for vitamin D).

## 3. Probability approach (iron)

The approach is generic: any nutrient for which the caller supplies the
percentiles of its requirement distribution. Iron is the case that needs it,
because the requirement of menstruating women is skewed.

```r
iron <- subset(ref_iron_requirements, group == "females_menstruating_adult")
inadequacy(x, ref_requirements, distribution = list(iron = iron),
           bioavailability = list(iron = c(0.10, 0.18)), min_coverage = 0.8)
```

- `distribution`: a named list, the name is the registry nutrient; each
  element a table with `percentile`, a requirement column carrying the
  registry unit per day (`requirement_mg_d`) and `bioavailability`, for
  **one group** (`group` constant, otherwise `hcesfort_error_key`).
  Percentiles strictly increasing, requirements non-decreasing, one
  bioavailability (`hcesfort_error_value`). The name "iron" appears only in
  the caller's code and in the shipped table, not in `R/`.
- `bioavailability`: a named list with one or more values in (0, 1] per
  nutrient of `distribution`. **Required, no default**: the 10% of the
  original has no source (analysis map, section 3), and the table's own
  assumption (18%) is a column of the table. Several values give several
  rows per household, distinguished by the column `bioavailability`.

### Calculation

The tabulated requirement is dietary iron at the bioavailability `b0` of the
table (absorbed requirement ÷ `b0`). For a diet of bioavailability `b` the
comparison is made on absorbed iron:

```
intake_equivalent = intake × b / b0
p_inadequate = 1 − F(intake_equivalent)
```

`F` is the distribution function of the tabulated requirement. This equals
the original's scaling of the requirement by `b0 / b` (`07:111-115`) and
keeps the table untouched. `F` between tabulated percentiles: linear
interpolation (`stats::approx()` with `yleft = 0`, `yright = 1`). Outside
them: probability 1 below the lowest percentile and 0 above the highest.

Checked on the shipped table (women, menstruating, `b0 = 0.18`):

| Intake, mg | `b` | `p_inadequate` | Why |
|---|---|---|---|
| 4.00 | 0.18 | 1 | below P2.5 (4.42) |
| 4.42 | 0.18 | 0.975 | at P2.5 |
| 8.07 | 0.18 | 0.5 | at P50 |
| 18.23 | 0.18 | 0.025 | at P97.5 |
| 19.00 | 0.18 | 0 | above P97.5 |
| 14.526 | 0.10 | 0.5 | 14.526 × 0.10 / 0.18 = 8.07 |

Two properties to document, not to hide:

- **The tails are a convention.** The table ends at P2.5 and P97.5, so the
  probability jumps from 0.975 to 1 and from 0.025 to 0. The original did
  the same without saying so. The jump is the price of not extrapolating a
  distribution the source does not tabulate.
- **Linear interpolation is this package's reading.** IOM (2001, Appendix I)
  also tabulates the probability by ranges of intake, which is a step
  function; those tables were not opened in the session, so the step method
  is not offered (P74) and no figure of them is written here.

### Bioavailability of what is added

One value of `b` applies to the whole intake, baseline and added, as in the
original. Fortificant compounds are not absorbed alike (WHO 2009 gives
different levels per compound for that reason, see the notes of
`ref_who2009_flour`), so a scenario with a poorly absorbed compound is
overstated and one with a well absorbed compound understated. The product of
task 9 keeps `added` apart, so a value per source
(`b_diet × baseline + b_added × added`) is an additive change, recorded as
P70 and not built in v0.1: it needs absorption values per compound and diet
with a verifiable source, and none was read.

## 4. `above_ul()`

```r
above_ul(x, requirements, conversions = ref_conversions, min_coverage)
```

Returns `hces_above_ul`, long, key `scenario` + `household_id` + `nutrient`,
for the nutrients of the registry with a non-missing `ul`.

| Column | Content |
|---|---|
| `scenario`, `household_id`, `intake_status`, `nutrient` | as in `inadequacy()` |
| `ul`, `ul_unit`, `ul_applies_to` | from `requirements` |
| `amount_added` | amount added by the scenario, in the form and unit the UL applies to |
| `amount_total` | diet plus added in that form; missing when the diet part is unknown |
| `ul_scope` | what could be compared: `total_intake`, `form_diet_and_added`, `form_added_only`, `not_assessable` |
| `above_ul_added` | `amount_added > ul`; missing for `total_intake` |
| `above_ul_total` | `amount_total > ul`; missing when `amount_total` is |
| `coverage` | coverage of the diet part |

### What is compared with the upper level (E7)

An upper level applies to an intake named by `ul_applies_to`. Two cases:

1. **`total`** (iron, zinc): the nutrient's total intake of the scenario
   against the UL. `ul_scope = "total_intake"`.
2. **A form** (`folic_acid`, `preformed_vitamin_a`,
   `supplemental_alpha_tocopherol`): only that form counts.
   - *Added part.* The scenario rows whose `form` belongs to the category:
     the columns `<form>_<unit>_added` of task 9, already in the form's mass
     unit (µg of folic acid, not DFE).
   - *Diet part.* The baseline intake of the registry nutrients that are
     forms of the category (`folic_acid_ug`, `retinol_ug`), when the
     composition has them. It holds the preformed retinol of liver, dairy
     and eggs, and the folic acid of foods left fortified in the baseline.
   - With both parts: `ul_scope = "form_diet_and_added"`, and both
     `above_ul_added` and `above_ul_total` are returned.
   - Without the diet part: `ul_scope = "form_added_only"`,
     `above_ul_total` is missing and `above_ul_added` is a **lower bound** of
     the share above the UL (the diet part is ignored, so the amount is
     understated). The original called this figure an upper bound.
   - Neither part (a UL on supplements, which a survey of food acquisitions
     does not record): `ul_scope = "not_assessable"`, counted as a note.

Which form belongs to which category is read from a new column of
`conversions`, `ul_form`: `folic_acid` → `folic_acid`; `retinol` and
`retinol_iu` → `preformed_vitamin_a`; missing for food folate and the
carotenoids. A registry nutrient is a form when its name is a `from_form` of
`conversions`. So `form` (scenarios), the registry names of the forms and
`ul_applies_to` (requirements) meet in one table with its source.

### Unit of the upper level

`ref_requirements$unit` is documented as the unit of both `ear` and `ul`.
For folate that is wrong as it stands: the EAR is in µg DFE, and the original
compares the UL with the added amount divided by 1.7 (`06:44`, `07:103`),
that is, with µg of folic acid. A new column `ul_unit` states the unit of
each UL; `above_ul()` requires it to equal the unit of what it compares
(the registry unit for `total`, the form's mass unit otherwise), else
`hcesfort_error_units`. The value for folate (and that the vitamin A UL is in
µg of preformed vitamin A) is entered only after reading the place already
cited in `data-raw/SOURCES.md` (IOM 1998, p. 281; IOM 2001, p. 143); until
then the row is `pending` and not shipped with a UL.

### Other rules

- Strict comparison (`>`), as in the original.
- The UL is the adults' one, applied to intake per AFE. Children have lower
  upper levels and are the group most exposed to excess from fortified
  staples; a household figure per AFE says nothing about them. Stated in the
  help page; other life stages wait for P51 and prevalence by persons
  (v0.2).
- `min_coverage`: as in `inadequacy()`, applied to the diet part of each
  comparison; for an upper level low coverage understates the share.
- Under the baseline scenario `amount_added` is 0 and `above_ul_added` is
  `FALSE`: the row is kept, so scenarios compare as pairs.
- E13 and E14 disappear by construction: one row per nutrient, and the UL is
  read from one table.

## 5. Changes to shipped tables and contracts

| Object | Change |
|---|---|
| `ref_requirements` | new column `ul_unit`; `unit` documented as the unit of `ear` |
| `ref_conversions` | new column `ul_form` (the category of upper level a form belongs to), with its source and place per row |
| `data-raw/SOURCES.md`, `data-raw/MD5` | updated in the same commit; rows not read stay `pending` |
| errors | new class `hcesfort_error_coverage` (announced in the design of task 2) |
| requirement-distribution table | documented schema (`percentile`, `requirement_<unit>_d`, `bioavailability`, one group); `ref_iron_requirements` already satisfies it per group |

## 6. Audit log

`inadequacy()` (`step = "inadequacy"`): `input` (households × scenarios);
`note`: `nutrient_without_requirement`, `requirement_without_nutrient`,
`method` (per nutrient, `detail` = method and bioavailability),
`coverage` (per nutrient, `detail` = the overall coverage and
`min_coverage`), `tails_fixed` (households whose probability is exactly 0 or
1 by the tail rule, per nutrient); `flagged`: `not_estimated` (households
without a result, by status).

`above_ul()` (`step = "above_ul"`): `input`; `note`: `ul_scope` (per
nutrient), `not_assessable`, `added_only_lower_bound`, `coverage`;
`flagged`: `not_estimated`.

## 7. Reproducing the original (acceptance step 1, task A3)

| Original choice | With the package |
|---|---|
| EAR cut-point for six nutrients, probability for iron (`valores_referencia.csv`, column `metodo`) | `distribution = list(iron = …)`, the other nutrients by cut-point |
| Bioavailability 10% and 18% | `bioavailability = list(iron = c(0.10, 0.18))` |
| Linear interpolation, tails 1 and 0 | the only method |
| Folate and vitamin A above the UL on the added amount only | `above_ul_added` |
| Iron, zinc, vitamin D above the UL on total intake | `above_ul_total` with `ul_scope = "total_intake"` |
| No coverage requirement | `min_coverage = 0` |
| Households of the 8,778 with intake | domain `intake_status == "estimated"` in task 11 |

Step 2 then reports `above_ul_total` where the composition has the form, and
sets `min_coverage`.

## 8. Tests and commit plan

Fixtures hand-built; expected values computed by hand in the test.

`inadequacy()`
- Normal: cut-point by hand for two nutrients and two scenarios; the six
  probabilities of the table of section 3; two bioavailabilities give two
  rows.
- Edge: intake exactly at the EAR (not inadequate); intake 0; household not
  estimated (missing result, counted); `hces_intake` as input; a registry
  nutrient without requirement; `min_coverage = 0`.
- Errors: two requirement rows for a nutrient (`key`); unit mismatch
  (`units`); distribution with two groups (`key`), non-increasing
  percentiles or two bioavailabilities (`value`); distribution without
  `bioavailability` argument, or a value outside (0, 1] (`argument`);
  coverage below `min_coverage` (`coverage`); missing `min_coverage`
  (`argument`); input without class (`audit`).
- Against an independent computation: the weighted share below the EAR and
  the mean probability from `survey::svymean()` on a hand-built design
  agree to 1e-8 with the same statistic computed from the result (this
  anchors the definition of `p_inadequate` for task 11).
- Invariants: `p_inadequate` in [0, 1]; it never increases when intake
  increases, when the requirement decreases, or when bioavailability
  increases; at `b = b0` the scaling is the identity; a scenario never has a
  higher `p_inadequate` than the baseline for the same household; scaling
  intake and requirement by k changes nothing; row order.

`above_ul()`
- Normal: `total` by hand; a form with both parts; a form with the added
  part only; the baseline rows.
- Edge: amount exactly at the UL (not above); nutrient without UL (no row);
  `not_assessable`.
- Errors: `ul_unit` different from the unit compared (`units`); `ul_form`
  column absent from `conversions` (`schema`); coverage (`coverage`).
- Invariants: `above_ul_total` is never `FALSE` where `above_ul_added` is
  `TRUE`; it never decreases when the level or the compliance of a scenario
  increases; it never increases when the UL increases; row order.

Commits:

1. Reference tables: `ul_unit`, `ul_form`, `SOURCES.md`, md5; the values
   read in the documents, the rest pending.
2. `inadequacy()` with the cut-point and the coverage rule
   (`R/inadequacy.R`, `R/inadequacy-log.R`).
3. Probability approach (`R/inadequacy-probability.R`).
4. `above_ul()` (`R/above-ul.R`, `R/above-ul-log.R`).
5. `NEWS.md` (E7 wording, E13, E14, E21), roadmap, self-review, handoff.

## 9. Choices that need the maintainer's approval

Each with the recommended option, which is the one written above.

1. **The functions return household rows with `p_inadequate` and
   `above_ul_*`; estimation is task 11.** Recommended: one place for the
   design, and a probability and an indicator are averaged the same way.
2. **Probability approach generic, given by `distribution = list(<nutrient>
   = table)`; iron is not named in the code.** Recommended: the core has no
   fixed nutrients. Alternative: an `iron_probability` method as the
   specification words it.
3. **`bioavailability` required, no default; several values allowed.**
   Recommended: 10% has no source in the original; the result must show the
   value used.
4. **Linear interpolation between percentiles, probability 1 and 0 beyond
   P2.5 and P97.5, documented as a convention.** Recommended: it is the
   original's rule and needs no table that was not read. Alternative: also
   offer the step table of IOM (2001, Appendix I) once it is opened (P74).
5. **One bioavailability for diet and fortificant in v0.1; by source later
   (P70).** Recommended: no sourced absorption values per compound are at
   hand. Alternative: accept `c(diet = , added = )` now, values supplied by
   the user.
6. **`above_ul()` returns both comparisons, added only and diet plus added,
   with `ul_scope` saying what was possible; "added only" is described as a
   lower bound.** Recommended: it is E7 fixed, and the original's figure
   stays reproducible.
7. **New column `ul_unit` in `ref_requirements`, entered after reading the
   cited pages; the folate UL is compared in µg of folic acid.** Recommended:
   the table today gives the folate UL the unit µg DFE, which the original's
   own code contradicts.
8. **New column `ul_form` in `ref_conversions`, linking a form to the upper
   level it counts towards.** Recommended: one sourced table instead of a
   `case_when` on nutrient names. Alternative: an argument of `above_ul()`
   written by the user.
9. **Coverage: `min_coverage` required; a nutrient below it is an error
   (`hcesfort_error_coverage`), not a flag; household coverage is returned.**
   Recommended (P11). Alternative: a flag per household and exclusion as a
   domain; it hides that the whole nutrient is unreliable.
10. **`requirements` must hold one row per nutrient (the caller selects the
    group).** Recommended until other life stages are entered (P51).
