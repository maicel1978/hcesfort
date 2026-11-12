# Design: food-group shares on the unfortified baseline

Status: **approved as recommended 2026-11-12** (section 10). Written 2026-11-12.
No package code is written by this note. Implementation: Opus.

Inputs read: E1 and row 32 of `docs/analysis-map.md`; decisions D4 and D7
of `docs/design-report-template.md` (approved 2026-11-12); P90 and P91 of
`docs/improvements.md`; `R/intake.R`, `R/scenario-log.R`,
`R/estimate.R`, `R/schema-user.R`; `scripts/08_grupos_alimentos.R` of the
original analysis.

## 1. What the original does, and what changes

`08_grupos_alimentos.R` joins a grouping file to the records, multiplies
grams per AFE and day by the content, weights by the household factor and
divides the total of each group by the total of the nutrient.

| Defect | Where | Answer of this design |
|---|---|---|
| The composition is the table as linked, with enriched rice, pasta and bread (E1) | `08:39-49` | The function refuses a content table whose log has no `unfortified_baseline` step |
| A missing nutrient value counts as zero, without a count | `08:48`, `coalesce(…, 0)` | The record rule of `apparent_intake()`; grams without a value are logged by group and nutrient |
| Records without a group are dropped when they are under 1% | `08:51-57` | They form the group `unclassified`, with its share shown |
| No design: shares are point figures | whole script | Ratio of weighted totals with its standard error (`survey::svyratio()`) |
| The grouping is tied to the survey sections and to one classification | `agrupacion_alimentos.csv` | A user table `food_groups`, keyed by `food_code`, replaceable |

`grupos_micronutrientes.csv` of the control figures is **not** reproduced
(`docs/analysis-map.md`, section 7: "E1 is fixed by design"). There is no
legacy option that computes shares on the enriched table.

## 2. Contract: new user table `food_groups`

Key `food_code`. One group per food.

| Column | Type | Rule |
|---|---|---|
| `food_code` | id | survey food code; unique |
| `food_group` | text | group name; not missing, not empty; `unclassified` is reserved |
| `source` | text | classification and edition (for example the document that defines the groups) |

`validate_food_groups()` follows the other user validators; the schema
joins `hces_schema()`. The package ships no classification: it is country
and purpose specific (the original used the ten MDD-W groups plus four
categories of its own). `hces_example` gains an invented `food_groups`.

A finer level (single foods grouped under a common name) is the same
table with other labels, passed in a second call.

## 3. Two steps

```
content (on the baseline) + food_groups + afe + households
    └─ food_group_intake() ──► household × group: amount per AFE and day
           └─ food_group_shares(design) ──► group × nutrient: share, SE, CI
```

The split follows the rest of the package: a household-level table first,
a design-based estimate after. It also gives, with no extra code, the
percentage of households that acquire each group
(`estimate_households(value = "acquired")` on the first table).

### 3.1 `food_group_intake(content, food_groups, afe, households, outliers = NULL)`

- `content`: the table returned by `link_composition()`. Refused with
  `hcesfort_error_audit` when its log has no `unfortified_baseline` step
  (`check_baseline_step()`, already used by `apply_scenario()`).
- Records enter under the same rules as `apparent_intake()`: the
  `include` flag, the outlier decision (`outliers` required when the
  column exists), household status, and a nutrient value used only when
  present. The record-level code of `R/intake.R` is reused, not copied.
- Join `content` to `food_groups` by `food_code`, many-to-one. A food of
  `content` absent from the table goes to `unclassified`; a food of the
  table absent from `content` is a note in the log.
- Result, class `hces_group_intake` (and `hces_tbl`), key `household_id` +
  `food_group`, the full grid of households and groups, in the order of
  `households`: `household_id`, `intake_status`, `afe`, `food_group`,
  `acquired` (at least one used record of the group), `n_records_used`,
  `qty_edible_g_d` and one column per nutrient, per AFE and day. Amounts
  are missing unless `intake_status` is `estimated`; a group not acquired
  by an estimated household has zeros.
- Audit log (`step = "food_group_intake"`): `input`; note
  `group_not_in_content`; flag `unclassified` (records, households,
  grams); flag `no_nutrient_value` per group and nutrient (records and
  grams of the group without a value for that nutrient).

### 3.2 `food_group_shares(design, x, by = NULL, level = 0.95, df = "domain")`

- `design`: from `as_hces_design()`. `x`: from `food_group_intake()`.
- For each nutrient *n* and group *g*, over the households with
  `intake_status == "estimated"`:

  share = Σ_h w_h a_hgn / Σ_h w_h a_hn, with a_hn = Σ_g a_hgn

  estimated as a ratio with `survey::svyratio()`, the other households
  outside the domain (subset of the design, as in
  `estimate_households()`). `by` takes domain columns of the households
  table.
- **Basis.** The amounts are per AFE and day, as in the original and in
  every other figure of the package. The share is therefore the part of
  the mean apparent intake of the reference woman that comes from the
  group. It is not the share of the national supply (household totals),
  which gives more weight to large households (decision 3).
- **Interval.** On the logit scale by the delta method,
  `logit(p) ± t × se / (p (1 − p))`, back-transformed: it stays between 0
  and 1, as the default interval of the proportions does. A share of
  exactly 0 or 1 has standard error 0 and an interval equal to the
  estimate, the rule of the degenerate proportions (11b.6).
- Result, class `hces_estimate`: `by` columns, `food_group`, `statistic`
  (`"share"`), `variable` (the nutrient), `estimate`, `se`, `ci_low`,
  `ci_high`, `conf_level`, `df`, `n` and `n_missing`. It passes through
  `flag_precision()` unchanged.
- A nutrient whose total is zero in a domain gives a missing share and a
  log note, never a division by zero.

The ratio computation sits in one internal helper, so that P91
(`estimate_ratio()`) and G3 of the report design can later export it
without a second implementation (decision 5).

## 4. What is out of scope

- Shares under a fortification scenario. `apply_scenario()` adds the
  fortificant per vehicle and household, not per record; the optional
  exhibit of Q6 in the report design waits (open item).
- A gate on value coverage per group (open item); the log and the report
  show it.
- Diet diversity indicators. The original counted the groups acquired per
  household and warned that it is not the MDD-W; not ported.

## 5. Independent reference and invariants

Reference: on a hand-built design of six households in two strata, the
estimate and standard error equal `survey::svyratio()` called directly, to
1e-8; the interval equals the formula of section 3.2 computed in the test.

Invariants:

1. The shares of a nutrient sum to 1 over the groups, in every domain.
2. For every household and nutrient, the sum over groups of
   `food_group_intake()` equals `apparent_intake()` on the same inputs
   (1e-8).
3. Multiplying every quantity by k leaves the shares unchanged.
4. Merging two groups gives the sum of their shares.
5. Row order of any input does not change the result.
6. E1, on `hces_example`: the share of the group that holds the enriched
   food is lower on the baseline than on the composition as linked (the
   second computed by hand in the test, since the function refuses it).

## 6. Tests (agreed list)

- `validate_food_groups()`: valid table; duplicated `food_code`; missing
  or empty group; reserved name (`hcesfort_error_schema`).
- `food_group_intake()`: hand-computed fixture of three households and
  three groups; content without the baseline step
  (`hcesfort_error_audit`); food without group goes to `unclassified` and
  is logged; group absent from content is noted; household not estimated
  has missing amounts; outlier decision required and applied; record
  without a nutrient value is logged and not counted as zero in the log.
- `food_group_shares()`: reference and invariants of section 5; `by`
  domain; zero total; degenerate share; missing arguments (classed).
- Golden chain on `hces_example` extended with the two steps.

## 7. Files and commit plan

Each commit under 300 lines of code; functions under 40 lines, files under
300.

| # | Commit | Files |
|---|---|---|
| 1 | Contract `food_groups`, validator, example data, schema test | `R/schema-user.R`, `R/validate-user.R`, `data-raw/`, `R/data.R` |
| 2 | `food_group_intake()` with its log | `R/food-group-intake.R`, `R/food-group-log.R` |
| 3 | `food_group_shares()` and the ratio helper | `R/food-group-shares.R`, `R/estimate-ratio.R` |
| 4 | Golden chain, `NEWS.md` (E1 corrected, with the two example figures), specification, self-review | tests, docs |

No new dependency.

## 8. Maintainer review points (to be filled at the end of the task)

1. The E1 effect on the example: shares of the enriched group before and
   after the baseline.
2. The estimate against `survey::svyratio()` typed by hand.
3. The `unclassified` share and the `no_nutrient_value` rows of the log.

## 9. Open items (to `docs/improvements.md`)

| Id | Priority | Item | Task |
|---|---|---|---|
| P95 | medium | Shares under a scenario need the added amount attributed to food records, which `apply_scenario()` does not keep | v0.2 |
| P96 | medium | A required minimum of value coverage per group and nutrient, mirroring `min_coverage` of `inadequacy()` | after A3 |
| P97 | low | Share of the national supply (household totals) as a second basis | v0.2 |
| P98 | medium | Export the ratio helper as `estimate_ratio()` (P91) and add the contrast between domains (G3) | v0.2 |

## 10. Decisions to approve

Recommended option first.

1. **Where the grouping lives.** A new user table `food_groups` keyed by
   `food_code`, *recommended*: it is replaceable without touching the
   crosswalk and mirrors `vehicles`. Alternative: a `food_group` column in
   the crosswalk, which ties one classification to the composition match.
2. **Two exported functions** (`food_group_intake()`,
   `food_group_shares()`), *recommended*, against one function that does
   both: the household table is testable against `apparent_intake()` and
   gives the households acquiring each group for free.
3. **Basis of the share.** Amounts per AFE and day, *recommended*: it is
   the original's basis and matches the risk figures, so the share reads
   as "of the apparent intake of the reference woman". This refines D7 of
   the report design, whose wording ("the population's supply") suggested
   household totals; those are P97. Alternative: household totals now.
4. **Interval.** Logit scale by the delta method, *recommended*, against
   the plain Wald interval of `svyratio()`, which can leave the range 0
   to 1 for small groups.
5. **Ratio helper kept internal in v0.1**, *recommended*: the public
   `estimate_ratio()` is P91, with its own design. Alternative: export it
   now and close P91 here (a larger task).
6. **Foods without a group form `unclassified`**, shown and logged, with
   no threshold, *recommended*. Alternative: a required `max_unclassified`
   that stops the function, as the original's 1%.
7. **Missing nutrient values**: the rule of `apparent_intake()`, logged by
   group and nutrient, no gate in v0.1 (P96), *recommended*. Alternative:
   a required `min_coverage` now.
8. **No legacy mode on the enriched table**, *recommended*: the function
   always requires the baseline step, and `grupos_micronutrientes.csv`
   stays out of the acceptance test.
9. **No classification is shipped**, *recommended*: the table is the
   adapter's. Alternative: ship the group names of one published
   classification as reference data, with its source to be opened first.
