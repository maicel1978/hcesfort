# Design of step 12e.5: infants and lactation in the AFE, the fortifiable vehicle, missing composition values, all-or-nothing compliance

Status: **written 2026-11-15 (Fable); waiting for approval** (nine decisions,
section 7). No package code was changed. Implemented by Opus after
approval, in the steps of section 6.

Covers P158 (with P57), P159, P162 and P163 (with P69) of
`docs/improvements.md`, with the maintainer's answers of 2026-11-15
(`docs/improvements.md`, "Decisions (2026-11-15, review v0.2)").

Inputs read: findings 4, 5, 8 and 9 of `docs/review-v0.2.md`;
`R/afe.R`, `R/afe-energy.R`, `R/afe-checks.R`, `R/vehicle-use.R`,
`R/vehicle-use-log.R`, `R/scenario.R`, `R/scenario-level.R`,
`R/schema-standard.R`, `R/intake.R`, `R/intake-log.R`,
`R/composition-log.R`, `R/risk-checks.R`, `R/above-ul.R`,
`R/above-ul-log.R`, `R/unmatched.R`, `R/check-crosswalk.R`,
`R/readiness-checks.R`; section 6 of `docs/design-task9.md`. Documents
opened in this session: section 8. The figures of sections 1 and 2 were
computed in this session with the installed package (commit `d567357`).

## 0. Summary

| # | Subject | What changes | Changes figures |
|---|---|---|---|
| 1 | Infants (P158) | Two arguments of `adult_equivalents()`: `infant_food_share` and `milk_energy_cost`. **Finding 4 of the review overstated the problem**: the energy of breast milk reaches the infant through the mother's diet, so it belongs in the AFE. The value 1 stays defensible and gets its reason written. | Only when the analyst chooses another value; at most about 0.06 AFE in a household with an infant |
| 2 | Pregnancy, lactation (P57) | Two arguments, `pregnancy_kcal` and `lactation_kcal`, and a small reference table. | Surveys that flag these women; not ENGIH |
| 3 | Fortifiable vehicle (P159) | Optional column `fortifiable` in `acquisitions`; three columns in the result of `vehicle_coverage()`; `apply_scenario()` adds only to fortifiable grams. | Yes, wherever the column is set |
| 4 | Missing values (P162) | `missing_values()`, the work queue by nutrient and food; log rows; no new threshold. | No; it shows where they are wrong |
| 5 | Compliance (P163, P69) | `compliance_model = "all_or_nothing"`; the household result is a probability; `above_ul_*` become numbers in [0, 1]. | Yes, for scenarios with compliance below 1 |

## 1. Infants, lactation and pregnancy in the AFE (P158, P57)

### 1.1 What the review said, and what it missed

Finding 4: a woman of 25 years alone is 1.000 AFE; with an infant of two
months, 1.240; "The intake per AFE of that household falls 19% although the
infant eats none of the food recorded." The fix proposed was a share of the
infant's requirement "expected from the household's food", with 0 as the
natural value for a breastfed infant.

That fix alone is biased the other way. The AFE says how the household's
food is shared: in proportion to energy requirements. A breastfed infant
eats none of the food recorded, but **its mother eats for it**. The source
of the infant table says so in its chapter on lactation (FAO/WHO/UNU 2004,
section 7.2):

> "total energy requirements during lactation are equal to those of the
> pre-pregnancy period, plus the additional demands imposed by the need for
> adequate milk production and secretion."

> "For women who feed their infants exclusively with breastmilk during the
> first six months of life, the mean energy cost over the six-month period
> is: 807 g milk/day × 2.8 kJ/g/0.80 efficiency = 2.8 MJ/day (675
> kcal/day)."

With the reference woman of the examples (2,290.8 kcal per day,
`reference_energy("female", 25, 55, pal = 1.76)`):

| Rule for a woman with an exclusively breastfed infant under six months | AFE of the household |
|---|---|
| Today: the infant's own requirement (mean of months 0 to 5: 540 kcal girls, 583 boys) | 1.24 to 1.25 |
| Infant 0, lactation 505 kcal (well-nourished women) | 1.22 |
| Infant 0, lactation 675 kcal (the full cost) | 1.29 |
| Infant 0, no lactation (the reading of finding 4) | 1.00 |

Today's rule is inside the range the source gives for lactation. It is so by
construction: the milk of exclusive breastfeeding carries 807 g × 0.67
kcal/g = 541 kcal, and section 3.4 of the same document says its infant
requirements "are consistent with the fact that a healthy woman can produce
enough milk to provide the energy required by a healthy, exclusively
breastfed infant of up to six months of age". An infant fed with formula
eats food the survey records, and counts its requirement directly.

So the hidden assumption of today's rule is not "the infant eats the
household's food". It is: **the infant's energy comes from the household's
food, directly or through its mother, and making milk costs nothing extra**.
What is wrong with it is small and has a sign: it ignores the efficiency of
milk synthesis (80%, so the cost is 1.25 times the milk energy) and the
fat stores a well-nourished mother uses (170 kcal per day in the first six
months). Removing the infant without adding lactation takes out of the AFE
about 0.24 that belongs there and overstates intake per AFE by about a
quarter in those households.

P158 is reworded accordingly. The argument without default asked by answer
3 stays: the assumption must be written in the call.

### 1.2 Model

For an infant with energy requirement `E` (kcal per day, from `energy`):

```
energy charged to the household = E × (s + (1 − s) × c)
```

- `s`, **`infant_food_share`**: share of the infant's requirement eaten from
  the household's food (formula, complementary foods). The rest, `(1 − s) E`,
  is breast milk.
- `c`, **`milk_energy_cost`**: dietary energy charged to the household per
  unit of breast-milk energy. 1: the milk at par. `1 / 0.80 = 1.25`: the
  full cost of FAO/WHO/UNU 2004. 0: the milk is not charged through the
  infant, right only when it is charged to the mother with `lactation_kcal`.

With `c = 1` the result is `E` whatever `s`: today's rule. An HCES seldom
says which woman is lactating; the AFE is a household sum, so charging the
milk through the infant's row gives the same household AFE as charging it
to the mother.

An infant whose month of age is not known (`infants = "annual_mean"`, or
`age_months` missing) gets the mean over the twelve months of
`E_m × (s_m + (1 − s_m) c)` for its sex; with one `s` this is today's mean
times the factor.

Pregnant and lactating women: `pregnancy_kcal` and `lactation_kcal` are
added to the requirement of the members flagged `pregnant` and `lactating`.

### 1.3 Interface

```r
adult_equivalents(members, reference_kcal, weight_kg, pal,
                  meal_share = NULL,
                  infant_food_share = NULL, milk_energy_cost = NULL,
                  pregnancy_kcal = NULL, lactation_kcal = NULL,
                  energy = ref_energy_requirements, bmr = ref_bmr_equations,
                  infants = c("monthly", "annual_mean"),
                  missing_members = c("na", "zero"))
```

| Argument | Value | Required when | Reproduces today |
|---|---|---|---|
| `infant_food_share` | one number in [0, 1], or a data frame `age_from`, `age_to` (months; intervals `[from, to)` that cover 0 to 12 without gap or overlap), `food_share` in [0, 1] | `members` has a member with `age_years < 1` | `1` |
| `milk_energy_cost` | one number ≥ 0 | some `food_share` is below 1 | not needed |
| `pregnancy_kcal` | one number ≥ 0, kcal per day | a member has `pregnant` `TRUE` | `0` |
| `lactation_kcal` | one number ≥ 0, kcal per day | a member has `lactating` `TRUE` | `0` |

None has a default value that enters a calculation: `NULL` where it is
required is an `hcesfort_error_argument` that names the argument, says what
1 or 0 means and points to the help. A value given where it is not required
is accepted and ignored (a subset without infants must not break a script).

**One rule against double counting.** If `lactation_kcal > 0` is applied to
at least one member and `milk_energy_cost > 0` with some `food_share` below
1, the milk would be charged twice: `hcesfort_error_argument`, "set
`milk_energy_cost = 0` (the milk is charged to the mother) or
`lactation_kcal = 0` (it is charged through the infant)". Nothing else is
forbidden: a lactating woman may be feeding a child older than one year, so
the function cannot tell more.

**Output.** `energy_kcal_d` is the sum of the energy charged to the
household after these rules (before `meal_share`, as today), so
`afe = energy_kcal_d / reference_kcal` still holds without a meal share.

**Log** (step `adult_equivalents`, table `members`; kcal in `detail`):

| Kind | Cause | When | Detail |
|---|---|---|---|
| note | `infant_energy` | infants present | share and cost given; kcal charged and kcal of the full requirement |
| flagged | `breast_milk_energy_not_counted` | some `food_share < 1`, `milk_energy_cost = 0` and no lactation energy added | kcal of milk left out |
| note | `pregnancy_energy_added`, `lactation_energy_added` | value > 0 | kcal per day and total |
| note | `pregnant_or_lactating_no_extra` (kept) | value 0 | |

### 1.4 Values an analyst may choose

The package ships no value for `s` or `c`: `s` describes how infants are
fed in the survey's population, which no generic table knows.

| Choice | `infant_food_share` | `milk_energy_cost` | Source | Status |
|---|---|---|---|---|
| Today's rule, and that of the original analysis | 1 | — | Milk energy equals the infant's requirement: FAO/WHO/UNU 2004, section 3.4 | verified; the reason is this note's, not a published HCES convention (`# SOURCE PENDING`, section 8) |
| Exclusive breastfeeding to six months, full cost | 0 under 6 months | 1.25 | 675 kcal = 807 g × 0.67 kcal/g / 0.80: sections 7.1.2 (energy of milk), 7.1.3 (efficiency) and 7.2 | verified |
| The same, well-nourished mothers | 0 under 6 months | 0.93 (505 / 541) | "well-nourished women … should increase their food intake by 2.1 MJ/day (505 kcal/day) for the first six months of lactation": section 7.2 | 505 verified; 0.93 is a computation of this note |
| Partial breastfeeding, 6 to 11 months | `1 − 368.5 / E_m`: 0.39 to 0.52 | 1.25 | "From the age of six months onwards, when infants are partially breastfed, milk production is estimated at 550 g/day" (section 7.1.1); 460 kcal = 550 × 0.67 / 0.80 (section 7.2) | 550 g, 0.67 kcal/g and 460 kcal verified; the share is a computation of this note |
| Infants not breastfed | 1 | — | — | — |
| By the feeding practices of the population | `1 − (share breastfed) × (milk energy / E_m)` by month | 1.25 or 0.93 | a national survey of infant feeding, given by the analyst | the adapter's source |

Energy from complementary foods by age (200, 300 and 550 kcal per day in
secondary sources of the PAHO/WHO guiding principles of 2003) was **not**
read in a primary document: `# SOURCE PENDING`; not used above.

Children of 12 to 23 months who are still breastfed are not covered: their
requirement comes from the yearly table (P176).

Pregnancy and lactation, FAO/WHO/UNU 2004, all read in this session:

| Condition | Period | Group | kcal per day | Place |
|---|---|---|---|---|
| pregnancy | first trimester | all | 85 | section 6.3 |
| pregnancy | second trimester | all | 285 | section 6.3 |
| pregnancy | third trimester | all | 475 | section 6.3 |
| pregnancy | second trimester, where women seek no prenatal advice before it | all | 360 | section 6.3, recommendation |
| lactation | first six months | well-nourished, adequate gestational weight gain | 505 | section 7.2, conclusion |
| lactation | first six months | undernourished or insufficient gestational weight gain | 675 | section 7.2, conclusion |
| lactation | after six months, partial breastfeeding | all | 460 | section 7.2 |

They ship as `ref_energy_additions` (`data-raw/energy_additions.csv`:
`condition`, `period`, `group`, `energy_kcal_d`, `source`, `location`,
`status`), registered by md5 and listed in `data-raw/SOURCES.md`. The
implementing session opens chapters 6 and 7 again
(`https://www.fao.org/4/y5686e/y5686e0a.htm`, `y5686e0b.htm`) and checks
each value before entering it. The table is a list of values to choose
from; `adult_equivalents()` does not read it. A survey that does not record
the trimester needs one number: the analyst's choice, written in the call
(the mean of the three trimesters is 282 kcal; 77,000 kcal over 280 days is
275). Values by trimester per member wait for a survey that records them
(P177).

### 1.5 Tests

Hand-built households, expected values computed by hand in the test.

- `infant_food_share = 1`, `pregnancy_kcal = 0`, `lactation_kcal = 0`
  reproduce today's result exactly (the golden values do not move).
- With `milk_energy_cost = 1` the AFE does not depend on
  `infant_food_share` (number or table).
- A woman of 25 years and a girl of 2 months (550 kcal, Table 3.2), share
  0, cost 1.25: 687.5 kcal charged; AFE = 1 + 687.5 / reference.
- The table form: gap, overlap, a share outside [0, 1], intervals beyond
  12: `hcesfort_error_argument`. Month unknown: the mean of the twelve
  products.
- The AFE never decreases when `milk_energy_cost`, `pregnancy_kcal` or
  `lactation_kcal` increase; the reference woman is exactly 1 AFE.
- Each required argument missing: classed error; the double-counting rule;
  the flagged row `breast_milk_energy_not_counted`.
- Anchor outside the package: `807 * 0.67 / 0.80` is 675.9 (the source
  prints 675) and `550 * 0.67 / 0.80` is 460.6 (460).

### 1.6 ENGIH 2018

Acceptance step 1: `infant_food_share = 1` (the survey flags neither
pregnancy nor lactation; analysis map, section 3). Step 2: recommended to
keep 1 as the main analysis, with the reason of section 1.1 in the
adapter's documentation, and to report one sensitivity run (`food_share`
from a national source of infant feeding, `milk_energy_cost = 1.25`). The
infant rule is then not an erroneous default to correct in A4; it is an
assumption that was never written.

## 2. The fortifiable vehicle (P159)

### 2.1 Contract

`acquisitions` gains one optional column:

| Column | Type | Missing | Meaning |
|---|---|---|---|
| `fortifiable` | flag | allowed | `TRUE`: the vehicle in this record could have been fortified (processed industrially). `FALSE`: it could not (own production, home or small-scale processing). Set by the adapter from the origin, the food code or the place of purchase, with its rule documented. The value is not read for records of foods that are not in `vehicles`. |

The definition is that of the coverage literature the reports cite, read in
this session (Aaron et al. 2017, "Indicators of coverage"): "consumption of
the fortifiable vehicle—the food vehicle used by the household is processed
industrially and hence is well suited to large-scale fortification". WHO
2009, p. 1, sets its levels on "'fortifiable' flour" (finding 5).

The column travels untouched through `convert_units()` and
`link_composition()` (checked in this session: extra columns are kept).

### 2.2 `vehicle_coverage()`

```r
vehicle_coverage(grams, vehicles, afe, households,
                 outliers = NULL, fortifiable = NULL, combine = NULL)
```

`fortifiable`: required when `grams` has the column, `"use"` or
`"ignore"`; must be `NULL` otherwise (the rule of `outliers`).

Three columns are added, **always**:

| Column | Definition |
|---|---|
| `acquired_fortifiable` | the household has an included record of the vehicle that counts as fortifiable; missing where `acquired` is missing; for `combined` rows, at least one of the set |
| `qty_fortifiable_g_d` | grams of vehicle per AFE per day from the records that count as fortifiable; missing as `qty_vehicle_g_d` |
| `qty_fortifiable_g_d_pc` | the same per member |

A record counts as fortifiable when the column is absent, or
`fortifiable = "ignore"`, or its value is `TRUE` **or missing**. A missing
value counted as fortifiable follows the rule of `outlier` (a record not
assessed is kept) and is flagged. `acquired`, `qty_vehicle_g_d` and
`qty_vehicle_g_d_pc` keep their meaning: the vehicle in any form. The two
coverages of the literature are `acquired` and `acquired_fortifiable`; the
third, the fortified vehicle, is `compliance` in a scenario.

Log (step `vehicle_coverage`):

| Kind | Cause | When |
|---|---|---|
| note | `all_vehicle_assumed_fortifiable` | column absent |
| note | `fortifiable_ignored` | `"ignore"` |
| note | `not_fortifiable`, one row per vehicle | `"use"`: records, households and grams with `FALSE` |
| flagged | `fortifiable_unknown`, one row per vehicle | `"use"`: records, households and grams with a missing value, counted as fortifiable |
| flagged | `acquired_not_fortifiable`, one row per vehicle | households with `acquired` and not `acquired_fortifiable` |

### 2.3 `apply_scenario()` and `who2009_levels()`

`apply_scenario()` reads `qty_fortifiable_g_d` where it read
`qty_vehicle_g_d`. A `use` table without the column (built by an older
version) is an `hcesfort_error_schema` that says to build it again. Its log
gains, per vehicle of the scenarios, a note `fortifiable_share`: the
fortifiable grams over the vehicle grams of the estimated households
(unweighted by survey weights, as the coverage of `inadequacy()`).

`compliance` now means one thing: the share of the fortifiable vehicle that
is fortified (or its content relative to the level, under average content).
The help of `apply_scenario()`, `vehicle_coverage()` and
`hces_schema("scenarios")` says so.

The help and the example of `who2009_levels()` use
`qty_fortifiable_g_d_pc`: the document asks for the consumption of
fortifiable flour.

### 2.4 Example data and reports

`hces_example$acquisitions` gains an invented `fortifiable`: `FALSE` where
`origin` is `own_production`, `TRUE` otherwise. In the example 5.2% to 7.0%
of the grams of each vehicle are own production, and 3.9% to 6.4% of the
households that acquire a vehicle have it only from own production. The
examples, the vignette and the report templates call
`vehicle_coverage(..., fortifiable = "use")`. The scenario columns of the
golden values and the snapshots of the scenario exhibits change; the
baseline does not. The coverage exhibit of the results report shows both
coverages. `hces_fixture()` gets the column with step 12e.2 (P169) or here,
whichever comes first.

### 2.5 Tests

- Column absent, all `TRUE`, and `"ignore"`: the same table (the log
  differs).
- All `FALSE`: `acquired` unchanged, `acquired_fortifiable` `FALSE`, every
  scenario equals the baseline.
- `qty_fortifiable_g_d <= qty_vehicle_g_d` in every row;
  `acquired_fortifiable` implies `acquired`.
- Turning one record from `TRUE` to `FALSE` never raises an added amount.
- A missing value: counted as fortifiable, and in the flagged row with its
  grams.
- Hand-built: a household with 300 g of bought flour and 200 g of its own:
  500 and 300 g per day before the AFE; added amount from 300.
- `fortifiable` missing with the column present, or given without it:
  `hcesfort_error_argument`.

## 3. Missing composition values (P162)

### 3.1 What a gate can and cannot do

A linked record without a value for a nutrient adds zero. The sign of the
error is known: intake is understated, so the share below a requirement is
overstated and the share above an upper level understated. Its size is not:
`min_coverage` measures grams, and for a nutrient concentrated in few foods
(vitamin A, vitamin B12) the grams say little (finding 8: the gate passes
at 0.976 with the only source missing).

No statistic computed from the data at hand sees that concentration: the
missing amount is exactly what is unknown. A second threshold, by food or
by households, would be blind in the same way. What can be done is to make
the list impossible to overlook, so that a person who knows the foods reads
"liver: no vitamin A" before any figure, and fills it with
`fill_composition()`. That is the design: no new threshold.

### 3.2 `missing_values()`

The twin of `unmatched_foods()` for values.

```r
missing_values(x, households, nutrients = NULL)
```

- `x`: the table of `link_composition()` or `fill_composition()`.
- `households`: for the weights, as in `unmatched_foods()`.
- `nutrients`: registry names; `NULL` for all.

Records counted: included and linked (the outlier decision is not applied,
as in `unmatched_foods()`). One row per nutrient and survey food with at
least one such record without a value, ranked within the nutrient by
weighted edible grams:

| Column | Definition |
|---|---|
| `nutrient`, `column` | registry name and column |
| `food_code` | survey food |
| `composition_id` | its composition rows, distinct, separated by `"; "` |
| `n_records`, `n_households` | records without the value; households with one |
| `qty_edible_g_d` | their weighted edible grams per day |
| `share_grams` | over the weighted edible grams of all included linked records |
| `rank`, `cum_share_grams` | rank within the nutrient; share of grams with a value once this food and those before it are filled (ends at 1) |

No rows, with the same columns, when nothing is missing. The weighted
shares rank the work; the gate of `inadequacy()` stays as it is (overall,
weighted by AFE, unweighted by survey weights). The help says that the two
differ and why.

### 3.3 Log and messages

- `apparent_intake()`: per nutrient with a used record without a value, a
  flagged row `foods_without_value` (records, households, grams;
  `detail` = `"<column>: <k> foods"`).
- `inadequacy()` and `above_ul()`: the note `coverage` adds, for a nutrient
  below 1, "foods without a value: see `missing_values()`" (the count stays
  in the row of `apparent_intake()`; no function parses a `detail`). The
  error of the coverage gate names `missing_values()` next to
  `fill_composition()`.
- `?inadequacy`, `?above_ul`, `?apparent_intake`: one paragraph, the first
  of section 3.1, with the example of finding 8.
- Readiness report: one exhibit after the composition coverage, the rows of
  `missing_values()` for the nutrients assessed, in rank order.
  `readiness_checks()` and `readiness_verdict()` do not change.

### 3.4 Tests

- The example of finding 8: one row, vitamin A, the liver, 10 g of 410 g.
- A food with two composition rows; a nutrient with nothing missing; the
  empty table.
- The sum of `share_grams` of a nutrient equals 1 minus its weighted
  coverage by grams, computed by hand.
- Scaling the weights by k leaves the shares unchanged; row order does not
  matter.
- The log row and the sentence of the note.

Not designed here: a gate on key sources declared by the analyst (P178).

## 4. Compliance and the upper level: all or nothing (P163, P69)

Step 12e.3 adds the flagged row `average_content_understates_ul` and the
figure at compliance 1 as a bound. This section is P69, moved before A4 by
answer 4.

### 4.1 Model

Under average content every gram carries `compliance × level`; no household
ever receives the full dose. Under all or nothing a share `c` of each
vehicle carries the full level and the rest none, and a household has one
or the other for the whole period. The two are the extremes of how much
fortified and unfortified product mix within a household; they give the
same mean added intake and different shares below a requirement or above an
upper level. The limitation is stated in the literature (Tang et al. 2021,
limitations, read in this session): "our status quo scenario assumed that
all oil, sugar, and wheat flour consumed by households is equally
fortified. Market data … indicated that some samples were not fortified at
all".

A scenario with `k` vehicles whose compliance is strictly between 0 and 1
has `2^k` states: each subset of those vehicles fortified at the full
level. Vehicles with compliance 1 are always on, with 0 always off. With
independence between vehicles, the probability of a state is the product of
`c` over its vehicles on and `1 − c` over those off. The household result
is the expectation over states:

```
p_inadequate = Σ_states P(state) × p_inadequate(intake in that state)
above_ul     = Σ_states P(state) × [amount in that state > UL]
```

The probabilities are the same for every household, so the national share
is the same combination of the shares of the states; computing it per
household gives the standard error with the design, as for the iron
probability.

### 4.2 Interface

`apply_scenario(..., compliance_model = "all_or_nothing")`:

- Every vehicle of a scenario must have one compliance (all its rows
  equal); otherwise `hcesfort_error_value` naming the rows: a compliance
  that differs by nutrient within a vehicle is under-dosing, which is
  average content.
- Returns a table of class **`hces_scenario_states`** (and `hces_tbl`), key
  `scenario` + `state` + `household_id`: the columns of
  `hces_scenario_intake` for each state (totals and `_added` with the
  vehicles of the state at the full level), plus `state` (the vehicles on,
  sorted and joined by `"+"`; `"none"`) and `state_probability`. The
  baseline has one state, `"none"`, with probability 1. The class does not
  inherit from `hces_scenario_intake`.
- Log: `compliance_model` with `all_or_nothing`; per scenario a note
  `states` (`"<scenario>: <k> vehicles with partial compliance, <2^k>
  states"`); a note `vehicles_assumed_independent` when some `k > 1`. The
  number of rows is households times the sum of `2^k`; the help says so.

`inadequacy()` and `above_ul()` accept `hces_scenario_states`. They compute
each state as today and collapse to their usual key with the weights
`state_probability`: `p_inadequate`, `above_ul_added` and `above_ul_total`
are the expectations; `intake`, `amount_added` and `amount_total` are the
expected amounts (equal to those of average content). The gates work on the
baseline, unchanged. Their classes and keys do not change.

**`above_ul_added` and `above_ul_total` become numbers in [0, 1] for every
input** (0 or 1 under average content), as `p_inadequate` already is and as
section 1 of `docs/design-task10.md` said. A column that is logical under
one model and a number under the other would break code that reads it.

No other function takes the states table. Those that require
`hces_scenario_intake` refuse it by class. `estimate_households()` and
`estimate_difference()` take any carrier, so they refuse it explicitly
(`hcesfort_error_audit`, "pass it to `inadequacy()` or `above_ul()`
first"). Means of intake by scenario are those of average content; the
help says so. Percentiles of intake under all or nothing are not offered.

The report template choice `compliance_model` accepts both values and the
upper-level exhibit names the model. Showing both models side by side is
left to task 12 (P179). A scenario that gives the share fortified and the
content of the fortified product as two numbers, which covers what lies
between the two models, is not designed here (P180).

### 4.3 Tests

- The hand example of `docs/design-task9.md`, section 6: baseline 250,
  full dose 100, EAR 320, compliance 0.5: 1 under average content, 0.5
  under all or nothing.
- Two vehicles with compliances 0.5 and 0.8: four states with probabilities
  0.4, 0.1, 0.4 and 0.1, the expected results by hand.
- Compliance 1 everywhere: both models give the same table of
  `inadequacy()` and `above_ul()`.
- The expected added amount equals that of average content (1e-12).
- `state_probability` sums to 1 per scenario and household.
- One vehicle: `above_ul = c × [full] + (1 − c) × [baseline]` per
  household; and with the design, the estimate equals the same combination
  of two `survey::svymean()` (1e-8), the anchor outside the package.
- Compliance that differs within a vehicle: classed error. The estimators
  refuse the states table. Row order does not matter.

## 5. What does not change

- No calculation moves when the new arguments take the values that
  reproduce today (`infant_food_share = 1`, `pregnancy_kcal = 0`,
  `lactation_kcal = 0`, no `fortifiable` column or `"ignore"`,
  `compliance_model = "average_content"`), except the type of
  `above_ul_added` and `above_ul_total`.
- Acceptance step 1 of ENGIH needs exactly those values.
- `min_coverage`, `min_records_used`, `readiness_checks()` and
  `readiness_verdict()` keep their interface.

## 6. Steps for Opus

After approval. Each step at most 300 lines of code, with `document()`,
tests and lint before its commit; split if larger.

| Step | Content |
|---|---|
| 12e.5.1 | `infant_food_share`, `milk_energy_cost`: checks, energy, log; every call of the package, the vignette and the templates gains `infant_food_share = 1` |
| 12e.5.2 | `pregnancy_kcal`, `lactation_kcal`, the double-counting rule; `ref_energy_additions` with `SOURCES.md` and md5; the calls on `hces_example` (which flags 77 pregnant and 64 lactating women) gain `pregnancy_kcal = 0, lactation_kcal = 0`, so the golden values do not move |
| 12e.5.3 | Column `fortifiable`; argument and three columns of `vehicle_coverage()`; its log |
| 12e.5.4 | `apply_scenario()` on fortifiable grams; `who2009_levels()` help; `fortifiable` in `hces_example` and the fixture; golden values and snapshots |
| 12e.5.5 | `missing_values()`; log row, note and messages; readiness exhibit |
| 12e.5.6 | `compliance_model = "all_or_nothing"`: states in `apply_scenario()` |
| 12e.5.7 | Collapse in `inadequacy()` and `above_ul()`; numeric `above_ul_*`; the estimators refuse the states table; template choice |
| 12e.5.8 | Specification, `NEWS.md`, coverage exhibit with both coverages, self-review |

The helper files are near the size limit in places (`R/vehicle-use.R` has
210 lines, `R/risk-checks.R` 205): new code goes in new files
(`R/afe-infants.R`, `R/vehicle-fortifiable.R`, `R/missing-values.R`,
`R/scenario-states.R`).

## 7. Decisions for the maintainer

The recommended option first.

1. **Infants: the reading of section 1.1 and the two arguments.**
   Recommended: accept that the milk's energy belongs in the AFE, and
   `infant_food_share` with `milk_energy_cost`. It amends answer 3 in one
   point: a share below 1 needs a second number. Alternative: the share
   alone, as finding 4 proposed; it lowers the AFE of every household with
   a breastfed infant by about 0.24 with no support in the source.
2. **ENGIH keeps `infant_food_share = 1` as its main analysis** (section
   1.6), with one sensitivity run. Recommended: the rule is inside the
   range of the source. Alternative: a main analysis by feeding practices,
   which needs a national source by month of age.
3. **Pregnancy and lactation now** (step 12e.5.2), with
   `ref_energy_additions`. Recommended: forty lines, and the rule against
   double counting needs `lactation_kcal`. No ENGIH figure changes.
   Alternative: leave P57 in v0.2.
4. **`fortifiable` is used only when the call says so**
   (`fortifiable = "use"` or `"ignore"`), and a missing value counts as
   fortifiable, flagged. Recommended: acceptance step 1 needs `"ignore"`
   without deleting the column, and it is the pattern of `outliers` and
   `meal_share`. It amends answer 5 ("if present, … use it").
   Alternative: always used when present.
5. **`hces_example` gains an invented `fortifiable`** (section 2.4); golden
   values and snapshots of the scenarios change. Recommended: otherwise no
   example or report exercises the column. Alternative: only the test
   fixture has it.
6. **Missing values: the list, no new threshold** (section 3).
   Recommended. Alternative: a readiness threshold on the share of grams of
   the largest food without a value, which fails in the case of finding 8
   only if set near zero.
7. **All or nothing by `compliance_model`, the states table, and numeric
   `above_ul_*` for every input** (section 4.2). Recommended. Alternative
   for the type: `p_above_ul_*` columns only under all or nothing, which
   makes the columns depend on the model.
8. **When:** steps 12e.5.1 to 12e.5.8 right after 12e.4 and before A2.
   Recommended: the adapter is written once against the final contract
   (`fortifiable`, the required arguments). Alternative: A2 and A3 first,
   12e.5 just before A4.
9. **Documents, not blocking:** the supplement of Tang et al. 2021 (its
   Table S3, "Base parameters defining daily dietary micronutrient and
   energy requirements"; the text cites Table S1 for the AFE factors, whose
   caption is about composition); Weisell and Dop 2012 (*Food and Nutrition
   Bulletin* 33, S157–S162); Coates et al. 2017 (*Food Policy* 72, 27–42);
   the PAHO/WHO guiding principles for complementary feeding (2003); and
   the national source of infant feeding for the Dominican Republic. They
   would say what published HCES work does with infants (row 1 of section
   1.4) and give the values of the sensitivity run.

## 8. Sources

Opened in this session:

| Document | Where | What was read |
|---|---|---|
| FAO/WHO/UNU 2004 | `fao.org/4/y5686e/y5686e05.htm` (md5 `a6a58c50d911b91890d5a891ecaeba0e`), `y5686e0a.htm` (`5eed1eba7a8e463958ec023ad71a3e80`), `y5686e0b.htm` (`5ebff65f41d7c87ade093d6042fc52a9`) | section 3.4; section 6.3 (text after Table 6.3); chapter 7: introduction, sections 7.1.1 to 7.1.4 and 7.2 |
| Aaron et al. 2017, *J Nutr* 147(5):984S–994S, doi:10.3945/jn.116.245753 | `pmc.ncbi.nlm.nih.gov/articles/PMC5404213/` | "Indicators of coverage"; footnote 4 of the performance table ("'Fortifiable' refers to a food vehicle that is processed industrially") |
| Tang et al. 2021, *Ann NY Acad Sci* 1508:105–122, doi:10.1111/nyas.14697 | `pmc.ncbi.nlm.nih.gov/articles/PMC9291765/` | data analysis (AFE: shared "proportionally according to the energy requirements of each household member"); limitations; captions of the supporting tables. The article text says nothing on infants or lactation in the AFE |

Not obtained, so nothing above rests on them (`# SOURCE PENDING`):

- The supplement of Tang et al. 2021: the server answers the download with
  a browser check; `ebi.ac.uk` is outside the environment's network.
- The PAHO/WHO guiding principles of 2003 and the WHO model chapter on
  infant feeding: `iris.paho.org` is outside the network;
  `ncbi.nlm.nih.gov/books` and the file on `iris.who.int` answer with a
  browser check.
- Weisell and Dop 2012; Coates et al. 2017: not open access from here.
- What published HCES analyses do with infants in the adult equivalents:
  not known from any document opened (P181).
