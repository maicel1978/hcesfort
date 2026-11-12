# Design of roadmap task 9: unfortified baseline, vehicle use, scenarios

Status: **proposed, waiting for the maintainer's approval** of the choices of
section 11. Nothing here is implemented. After approval the implementation
goes to Opus (`docs/model-routing.md`).

Inputs read: P5, P6, P32, P45, P52 of `docs/improvements.md`; E1, E5, E6, E7,
E8, E12, E23 of `docs/analysis-map.md`; `R/schema-user.R`; the reference
tables of task 4; `scripts/06_escenarios_fortificacion.R` and the parameter
files `escenarios_fortificacion.csv`, `vehiculos_escenarios.csv` and
`parametros_normativos.csv` of the original analysis.

## 1. What the original does, and what changes

The original (`06:69-197`) does three things in one script: it rewrites the
iron and folate of rice, flour and wheat products with unenriched values, it
measures the use of each vehicle, and it adds `level × grams of vehicle` per
scenario. Five defects come from that arrangement:

| Defect | Where | Answer of this design |
|---|---|---|
| The baseline exists only inside script 06, so script 08 used the enriched table (E1) | `08:39-49` | The baseline is a composition table (section 3); `apply_scenario()` refuses an intake that was not built on one |
| Derived products keep only the flour's nutrients (E6) | `06:80-90` | Subtract what enrichment added; the original rule is a named legacy method |
| A level in mg/kg is read as mass of nutrient, and the conversion to DFE or RAE is a constant in the code (E8, P52) | `06:42-43` | Three explicit factors per scenario row: compound → form → unit of the nutrient (section 5) |
| Full compliance is assumed and not stated (P32) | whole script | `compliance` enters the calculation under a named model (section 6) |
| The vehicle is defined twice, by regular expressions (E12) | `_comun.R`, `06:58-67` | One `vehicles` table; scenarios are computed from the product of `vehicle_coverage()` |

The order of the pipeline becomes:

```
composition ── unfortified_baseline(enrichment) ──► baseline composition
grams ── link_composition(baseline) ── apparent_intake() ──► baseline intake
grams ── vehicle_coverage(vehicles, afe, households) ──► vehicle use per household
baseline intake + vehicle use + scenarios ── apply_scenario() ──► intake per household and scenario
```

**The baseline is a counterfactual without the fortification named in the
rules. The present situation of a country is a scenario**, as in the original
(scenario "1a"). The package cannot know which standard is enforced (E23,
maize flour): that is a row of `scenarios` with its `compliance`.

## 2. Changes to the contracts of task 2

| Table | Change | Why |
|---|---|---|
| `scenarios` | new optional column `form` (text) | the form of the nutrient that the level is a mass of (`folic_acid`, `retinol`); joins `conversions$from_form` (section 5) |
| `scenarios` | `nutrient_fraction` must be missing when `level_basis` is `"nutrient"` | today a row with both is accepted and the fraction is ignored: an ambiguous row (checked by running `validate_scenarios()`) |
| `vehicles` | new optional column `vehicle_group` (text) | several vehicles that share one substance (flour, bread, pasta → wheat flour), for coverage in flour equivalents (section 4) |
| new user table `enrichment` | key `composition_id` + `nutrient` | what enrichment added to a composition row (section 3) |
| `hces_example` | `form` in `scenarios`; an `enrichment` table; one enriched-flour composition row | so the examples run the whole chain |

The specification's row "Baseline: composition + vehicles → baseline
composition" becomes "composition + enrichment". The vehicle table cannot
drive the baseline: it is keyed by survey food on the purchased basis, while
the baseline is keyed by composition row in the state of that row (a dry
pasta matched to a cooked row has two different flour fractions).

## 3. `unfortified_baseline()`

```r
unfortified_baseline(composition, enrichment, nutrients = NULL,
                     method = "subtract", conversions = ref_conversions)
```

Returns a validated composition table (class `hces_composition`), with the
same rows, columns and registry, the corrected values, a new column
`baseline_status` and its audit log. It is passed to `link_composition()` in
place of the original table. `enrichment` is required; a table with no rows
is the explicit statement "this composition has nothing to remove".

### Table `enrichment`: key `composition_id` + `nutrient`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `composition_id` | id | no | in `composition` | row to correct |
| `nutrient` | text | no | in the registry | |
| `enriched_ref_id` | id | yes | in `composition` | row of the enriched ingredient (enriched flour); may be the row itself |
| `unenriched_ref_id` | id | yes | in `composition` | row of the same ingredient without enrichment |
| `ingredient_fraction` | number | yes | in (0, 1] | grams of the ingredient per gram of the food, in the state of the composition row |
| `added`* | number | yes | ≥ 0 | amount that enrichment added per 100 g, in the registry unit; alternative to the pair |
| `source` | text | no | | where the pair, the fraction or the amount comes from; `SOURCE PENDING` is counted |

A row states the amount in exactly one of two ways, otherwise
`hcesfort_error_value`: by reference pair (`enriched_ref_id`,
`unenriched_ref_id`, `ingredient_fraction`) or by `added`. A reference row
without a value for the nutrient is `hcesfort_error_value` (the rule cannot be
applied; nothing is guessed). An id absent from `composition` is
`hcesfort_error_join`.

### Rule

With `E` and `U` the values of the enriched and unenriched reference rows,
`f` the ingredient fraction and `v` the value of the row:

- `method = "subtract"` (default): removed = `f × max(E − U, 0)` or `added`;
  baseline = `v − removed`, never below the floor. Floor: `f × U` for a pair
  row (the food holds at least what its unenriched ingredient brings), 0 for
  an `added` row.
- `method = "replace_by_ingredient"`: baseline = `f × U`. This is the rule of
  the original (`06:74-91`), kept only for acceptance step 1; it deletes the
  nutrients of every other ingredient (E6). Rows given by `added` are an
  error under this method.

Hand example (invented values, iron in mg per 100 g): bread 3.0, enriched
flour 4.4, unenriched flour 1.2, fraction 0.6. Subtract: 3.0 − 0.6 × 3.2 =
1.08. Replace: 0.6 × 1.2 = 0.72; the 0.36 mg of the other ingredients are
lost. A bread recorded with 1.5: 1.5 − 1.92 is below the floor 0.72, so the
baseline is 0.72 and the cell is flagged: the row is probably not made with
that flour at that fraction.

When the row is its own enriched reference and `f = 1` (enriched rice against
plain rice), both methods give `U`: replacing is the special case of
subtracting.

A missing value stays missing (never zero, E21). Cells without a rule are
unchanged. `baseline_status` per row: `enrichment_removed`,
`fortified_no_rule` (the optional `fortified` flag is `TRUE` and no rule
names the row) or `unchanged`. A fortified row without a rule is kept as it
is and counted: whether voluntary fortification (a breakfast cereal) belongs
to the baseline is the user's decision, taken by writing or not writing the
rule.

Forms. When the registry holds a form of a nutrient (`folic_acid_ug` next to
`folate_ug_dfe`), the form needs its own rule: the pair gives it directly.
A row with a rule for a nutrient and none for a form of it present in the
registry is flagged (`form_without_rule`). A registry nutrient is a form
when its name is a `from_form` of `conversions`; its parent is the registry
nutrient whose unit is the `to_unit` of that row (section 5).

### Audit log (`step = "unfortified_baseline"`, `table = "composition"`)

`input` (`all`); `note`: `enrichment_removed` (cells, `detail` = nutrient
column), `no_enrichment_rules` (empty table), `difference_not_positive`
(`E ≤ U`, nothing removed), `rule_not_needed` (value missing),
`source_pending`, `method_replace_by_ingredient`; `flagged`:
`floored` (per nutrient), `fortified_no_rule`, `form_without_rule`.
`n_households` and `qty_g` are `NA`: the table has no households.
The grams that rest on flagged rows are seen later with `check_crosswalk()`
and the `fortified` column of `hces_nutrient_content`.

## 4. `vehicle_coverage()`

```r
vehicle_coverage(grams, vehicles, afe, households, outliers = NULL,
                 combine = NULL)
```

`grams` is `hces_grams` or `hces_nutrient_content` (both carry `qty_g_d`,
`include` and, if flagged, `outlier`); `outliers` follows the rule of
`apparent_intake()`. Returns `hces_vehicle_use`: one row per household of
`households` and per vehicle, key `household_id` + `level` + `vehicle`.

| Column | Content |
|---|---|
| `household_id`, `use_status` | status in the vocabulary of `apparent_intake()`: `food_module_nonresponse`, `no_food_records`, `no_afe`, `estimated` |
| `level` | `vehicle`, `group` (rows per `vehicle_group`) or `combined` (rows per element of `combine`) |
| `vehicle` | vehicle, group or combination name |
| `acquired` | at least one included record of a food of the vehicle; `NA` for non-response and for households without any food record |
| `n_records`, `n_records_no_grams` | records of the vehicle's foods, and those without grams |
| `qty_vehicle_g_d` | grams of vehicle per AFE per day: `Σ qty_g_d × vehicle_fraction / afe` over the records with grams; `NA` without AFE or for `combined` rows |

Decisions built in:

- **Purchased basis.** `vehicle_fraction` is a fraction of the food as
  purchased, so the grams are `qty_g_d`, without edible portion or yield
  factor. The original used edible grams; the two agree when the vehicle
  foods have edible portion 1 (to be confirmed in A3, P73).
- **All records with grams count, linked to the composition or not.** A bread
  without a composition match still carries flour. The original counted only
  the records that survived the drops of E3.
- **Same denominator as risk (E5).** Every household of the frame is
  returned; who enters the estimate is decided in task 11 from `use_status`.
  The original kept the households without records as non-consumers;
  acceptance step 1 does that explicitly (`acquired` missing → `FALSE`).
- **Unknown amount is not zero.** A household whose vehicle records all lack
  grams has `acquired = TRUE` and is counted (`acquired_without_grams`).
- `combine = list(any_staple = c("wheat_flour", "rice", "sugar"))` adds the
  reach of "at least one of" as rows of level `combined`, on vehicles or
  groups.
- One food may hold two vehicles (key `food_code` + `vehicle`), but at most
  one vehicle of each group, otherwise `hcesfort_error_key`: its grams would
  be counted twice in the group.

Coverage, mean among all, median among consumers and combined reach are
estimates: task 11 computes them on this table with the design. The function
exports no estimate, in line with "variance through `survey`/`srvyr`".

Checks: `food_code` types between `grams` and `vehicles` (P45);
`household_id` between `grams`, `afe` and `households`. Join of records to
vehicles: `many-to-many` declared (a food with two vehicles), records without
vehicle dropped by design and counted in the `input` row.

Audit log (`step = "vehicle_coverage"`): `input`; `note`:
`vehicle_food_not_acquired` (foods of the table absent from the survey),
`fraction_source_pending`, `records_of_vehicle_foods` (per vehicle, with
grams); `excluded`: `not_included`, `outlier_excluded`; `flagged`:
`vehicle_record_without_grams`, `acquired_without_grams`, and the statuses.

## 5. Level basis: compound, form, unit

A level in mg/kg becomes an amount of the registry nutrient per 100 g of
vehicle through three factors, each stated in the scenario row or in a table
with its source:

```
per_100g = level_mg_kg
           × nutrient_fraction      # compound → form; 1 when level_basis is "nutrient"
           × (mg → base unit) / 10  # mg per kg → base unit per 100 g
           × equivalent_factor      # form → unit of the nutrient (conversions)
```

1. **`level_basis`.** `"nutrient"`: the level is a mass of the nutrient in
   the form named in `form` (elemental iron, folic acid, retinol).
   `"compound"`: it is a mass of `compound` (ferrous fumarate, retinyl
   palmitate) and `nutrient_fraction`, supplied by the user with its source,
   turns it into the form. The package ships no table of compound fractions:
   none was read in a document (retinyl palmitate is pending in
   `data-raw/SOURCES.md`).
2. **Base unit.** From the registry: mg × 1, µg × 1000, g × 0.001. A scenario
   for an energy nutrient is `hcesfort_error_units`.
3. **`form` and the equivalent factor.** When the unit of the nutrient has an
   equivalent tag (`ug_dfe`, `ug_rae`, `mg_ne`, `mg_ate`), `form` is
   required and must be a `from_form` of `conversions` with that `to_unit`
   and a mass `from_unit`; the factor is read there (`ref_conversions`:
   folic acid 1.7, retinol 1). A missing `form` for a tagged unit is
   `hcesfort_error_units`: a mass cannot become an equivalent without saying
   of what. For an untagged unit `form` may be missing and the factor is 1.

Hand checks against the constants of the original (`06:42-43`): iron
55 mg/kg → 5.5 mg per 100 g; folic acid 1.8 mg/kg → 180 µg of folic acid →
306 µg DFE per 100 g (the original's `100 × 1.7 × 1.8`); a compound at
10 mg/kg with an invented fraction of 0.5 and form retinol → 500 µg RAE.

Consequences:

- **E8 is answered by the contract, not by a default.** A vitamin A row must
  say `level_basis`, and `form`; if the standard was not read, the adapter
  writes its reading and `SOURCE PENDING` in `source`, and every result built
  on the row carries the note `scenario_source_pending` in its log.
- **P52, WHO 2009.** A row of `ref_who2009_flour` maps to a scenario row as:
  `nutrient` = the registry nutrient (`folic_acid` → `folate`),
  `level_basis = "nutrient"`, `form` = `folic_acid`; for vitamin A the table
  does not state the form, so `form = "retinol"` is the user's declared
  reading. No helper builds these rows in v0.1 (P71): the mapping is five
  lines in the vignette, and a helper would hide the reading of vitamin A.
- **The form of what is added is kept.** `apply_scenario()` returns the
  amount added in the form's own mass unit as well (`folic_acid_ug_added`),
  because the upper level applies to the form (task 10). If the form is
  itself a registry nutrient, the scenario adds to it too, so its total stays
  coherent.
- A level in IU per kg is converted to mg/kg by the adapter with
  `ref_conversions` (`retinol_iu`).
- Not covered in v0.1: losses in storage and cooking (roadmap v0.2), and the
  different absorption of iron compounds (design of task 10, P70).

## 6. Compliance

`compliance` is the share of the vehicle that is actually fortified. Two
models put it into a household's intake, and they are the two extremes of how
much fortified and unfortified product mix within a household:

- **Average content** (`"average_content"`): every gram of vehicle carries
  `compliance × level`. Exact if households consume a blend, or if compliance
  means under-dosing.
- **All or nothing** (`"all_or_nothing"`): a share `compliance` of the
  vehicle carries the full level and the rest none; a household gets one or
  the other. The household's result is then a probability: with one vehicle,
  `compliance × indicator(full) + (1 − compliance) × indicator(baseline)`.

They give the same mean added intake and different shares below a
requirement or above an upper level. Hand example (folate, µg DFE): baseline
250, added at full level 100, EAR 320, compliance 0.5. Average content:
300 < 320, inadequate. All or nothing: 0.5 × 0 + 0.5 × 1 = 0.5. For the
upper level the average-content model never gives any household the full
dose, so with few households near the limit it understates the share above
it.

Design for v0.1 (recommended, choice 5): `apply_scenario()` implements
average content, and the argument `compliance_model` has no default: it must
be given whenever a compliance differs from 1, so the model is written in
the call and in the log (`compliance_model`, `detail` = the model). All or
nothing is recorded as P69 for v0.2; it changes no contract, because its
result is a household probability, the same kind of number as the iron
probability of task 10. Until then, for one vehicle, the all-or-nothing share
can be computed by the user from the full-compliance scenario and the
baseline with the formula above.

When `compliance` is absent the validator already adds 1 with the note
`compliance_assumed_full` (task 2); that note reaches the result.

## 7. `apply_scenario()`

```r
apply_scenario(intake, use, scenarios, conversions = ref_conversions,
               compliance_model = NULL, baseline_label = "baseline")
```

`intake`: `hces_intake`, built on a baseline composition. `use`:
`hces_vehicle_use`. Steps:

1. `require_hces()` on both; `validate_scenarios()`; the registry is the one
   stored on `intake`.
2. **Baseline guard (E1).** The log of `intake` must hold the step
   `unfortified_baseline`; otherwise `hcesfort_error_audit`, with the fix
   (call `unfortified_baseline()`, with an empty `enrichment` if the table
   has nothing to remove).
3. Checks where the tables meet: every `vehicle` of `scenarios` is a vehicle
   of `use` (`hcesfort_error_join`); the same households in `intake` and
   `use` (`hcesfort_error_join`); `form` and units as in section 5;
   `compliance_model` as in section 6 (`hcesfort_error_argument`).
4. `per_100g` per scenario row (section 5) × `compliance`.
5. Added per household, scenario and nutrient:
   `Σ over vehicles qty_vehicle_g_d × per_100g / 100`. Join of scenario rows
   to use rows by `vehicle`: `many-to-many` declared, `unmatched = "error"`
   on the scenario side.
6. Total = baseline + added, for every registry nutrient (added is 0 where
   the scenario does not touch the nutrient).

Returns `hces_scenario_intake`, wide like `hces_intake`, key `scenario` +
`household_id`: the columns of `intake` (status, AFE, `iron_mg` now meaning
the total, `iron_mg_coverage` of the baseline) plus `scenario` and one
`<column>_added` per nutrient or form touched by any scenario. The baseline
is `total − added`; it is also returned as the rows of the scenario named
`baseline_label` (added 0), so that every later table compares scenarios
with the baseline without a second input. `nutrient_density()` and
`flag_energy_plausibility()` accept the new class.

Rules:

- A household that is not `estimated` in `intake` has missing totals in every
  scenario. A household that is estimated but has no AFE-based use cannot
  occur (same AFE table); the check of step 3 enforces it.
- A household that acquired the vehicle with unknown grams gets what its
  records with grams give, and is counted (`added_understated`).
- A scenario named like `baseline_label` is `hcesfort_error_value`.
- A scenario vehicle that no household acquired is a note.

Audit log (`step = "apply_scenario"`): `input` (households, scenarios);
`note`: `compliance_model`, `compliance_below_one` (rows),
`scenario_source_pending`, `vehicle_not_acquired`, `no_losses_applied`,
`households_with_added` (per scenario and nutrient); `flagged`:
`added_understated`.

## 8. Reproducing the original (acceptance step 1, task A3)

| Original choice | With the package |
|---|---|
| Baseline by replacement (`06:74-91`) | `method = "replace_by_ingredient"`; `enrichment` lists the composition ids of the rice, flour and wheat-product foods, iron and folate |
| Vehicle = product class with a flour fraction | `vehicles$vehicle` = product class, `vehicle_group` = wheat |
| Scenario rows per product class | as they are (105 rows) |
| Levels read as nutrient; folic acid × 1.7; vitamin A as retinol | `level_basis = "nutrient"`, `form` = `folic_acid`, `retinol` |
| Full compliance | `compliance = 1` |
| Households without records as non-consumers | `acquired` missing → `FALSE`, written in the adapter |

Two points may prevent an exact match and are measured in A3 (P73): the
original chose the baseline rows by the food's description, the package by
composition id (they differ if one id serves a vehicle food and another
food); and the original's vehicle grams are edible grams of the records that
survived E3.

## 9. Tests (agreed list)

Fixtures: hand-built, two or three households, expected values computed by
hand in the test.

`unfortified_baseline()`
- Normal: pair rule, `added` rule, both methods, the hand example of
  section 3; a row that is its own reference with fraction 1 equals `U`.
- Edge: empty `enrichment` (table unchanged, note); missing value stays
  missing; `E ≤ U`; floor reached (flag, value `f × U`); zero-row
  composition.
- Errors: unknown id (`join`); nutrient outside the registry (`value`); both
  or neither way of stating the amount (`value`); reference without value
  (`value`); `added` under the legacy method (`value`); duplicated key
  (`key`); bad `method` (`argument`).
- Invariants: no cell increases; cells without a rule are identical; with
  `"subtract"` every cell is ≥ the `"replace_by_ingredient"` result; row
  order does not matter; applying the function to its own output with the
  same rules is rejected or changes nothing (decide in implementation and
  test it).

`vehicle_coverage()`
- Normal: grams per AFE by hand; a food with two vehicles; group rows equal
  the sum of their vehicles; `combine`.
- Edge: household without records, without AFE, non-response; vehicle record
  without grams; vehicle food absent from the survey; `outliers = "exclude"`.
- Errors: `food_code` of another type (`join`); two vehicles of one group for
  a food (`key`); unknown name in `combine` (`argument`); input without
  class (`audit`).
- Invariants: one row per household and vehicle whatever the data; scaling
  every quantity by k scales `qty_vehicle_g_d` by k and leaves `acquired`
  unchanged; row order.

`apply_scenario()`
- Normal: the three hand checks of section 5; two vehicles in one scenario;
  compliance 0.8 under average content; baseline rows.
- Edge: scenario touching no nutrient of a household; vehicle nobody
  acquired; level 0; household not estimated.
- Errors: intake without the baseline step (`audit`); vehicle absent from
  `use` (`join`); tagged unit without `form` (`units`); form absent from
  `conversions` (`units`); energy nutrient (`units`); compliance below 1
  without `compliance_model` (`argument`); `nutrient_fraction` with basis
  `"nutrient"` (`value`); scenario named as the baseline (`value`).
- Invariants: adding a fortificant never lowers intake; total = baseline +
  added exactly; added is linear in the level and in compliance; compliance
  0 equals the baseline; a compound level `L` with fraction `f` equals a
  nutrient level `L × f`; nutrients not named by the scenario are unchanged;
  row order of every input.
- End to end on `hces_example`.

## 10. Commit plan

1. Contracts: `form`, `vehicle_group`, the `nutrient_fraction` rule,
   `validate_enrichment()`, `hces_example` (data-raw script and md5).
2. `unfortified_baseline()` (`R/baseline.R`, `R/baseline-log.R`).
3. `vehicle_coverage()` (`R/vehicle-use.R`, `R/vehicle-use-log.R`).
4. `apply_scenario()` (`R/scenario.R`, `R/scenario-level.R`,
   `R/scenario-log.R`).
5. Specification (function table, contracts), `NEWS.md` (E1, E6, E8, E12
   fixed by design), roadmap, self-review, handoff.

Each commit under 300 lines of code, functions under 40 lines; before each
push `devtools::check()` with 0/0/0 and `lintr::lint_package()` clean.

## 11. Choices that need the maintainer's approval

Each with the recommended option, which is the one written above.

1. **New table `enrichment`, keyed by composition row; the baseline no
   longer takes `vehicles`.** Recommended: the flour fraction of a
   composition row (in its state) is not the vehicle fraction of a purchased
   food. Alternative: derive the baseline from `vehicles`, which fails when
   two foods share a composition row or the row is cooked.
2. **The amount removed is stated by reference pair or by `added`.**
   Recommended: both; a pair when the table holds the two rows, `added` when
   only a label or a standard is known. Alternative: pair only (simpler,
   less flexible).
3. **Floor of the subtraction: `fraction × unenriched` instead of zero**
   (changes P6, which said zero). Recommended: a food cannot hold less than
   its unenriched ingredient brings; the corrected rule is then never below
   the original's. Alternative: zero, as P6.
4. **`apply_scenario()` refuses an intake whose log has no
   `unfortified_baseline` step.** Recommended: it makes E1 impossible; a
   table with nothing to remove costs one call with an empty `enrichment`.
   Alternative: a note in the log instead of an error.
5. **Compliance: average content in v0.1, named by a required argument; all
   or nothing in v0.2 (P69).** Recommended: ENGIH's acceptance needs only
   full compliance, and the argument keeps the model visible. Alternative:
   both models now (one more commit here and the handling of household
   probabilities in `inadequacy()` and `above_ul()`); choose it if reports
   with partial compliance are planned before v0.2.
6. **New column `form` in `scenarios`, required when the nutrient's unit is
   an equivalent (DFE, RAE).** Recommended: it removes the constant 1.7 and
   the "vitamin A read as retinol" from the code, and tells the upper level
   what was added.
7. **New column `vehicle_group` in `vehicles`; a scenario names vehicles,
   coverage is also given by group.** Recommended: it expresses "standard
   applied to flour and bread only" without a new key. Alternative: one
   vehicle per substance and a `product` restriction in `scenarios`, which
   changes the key of that table.
8. **Vehicle grams on the purchased basis, from every included record with
   grams.** Recommended: it is what `vehicle_fraction` means, and a food
   without a composition match still carries the vehicle. Differs from the
   original where the edible portion of a vehicle food is not 1 or its
   records were lost (P73).
9. **`vehicle_coverage()` returns household rows, not estimates; the product
   feeds `apply_scenario()`.** Recommended: one definition of the vehicle for
   coverage and scenarios (E12), estimates with the design in task 11.
10. **Households without food records have `acquired` missing** (same domain
    as risk, decision 8 of 2026-11-12); the original's denominator is an
    explicit step of the adapter. Recommended.
11. **Output of `apply_scenario()` wide, like `hces_intake`, with the
    baseline as a scenario named `baseline_label`.** Recommended: unit in
    the column name, and the existing functions work on it. Alternative: a
    long table (scenario × household × nutrient), which is the shape task 10
    returns anyway.
