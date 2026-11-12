# Design of the corrections of the v0.1 review (1, 2, 3, 8, 10; 4 accepted)

Status: **approved as recommended 2026-11-12** (decisions of section 8;
see `docs/improvements.md`). Implemented by Opus, one commit per correction.

Inputs read: `docs/review-v0.1.md` (H1–H4, M7, M8, M10, M12, L1, L2, L9) and
the maintainer's answers to its section 11; `R/intake.R`, `R/inadequacy.R`,
`R/risk-checks.R`, `R/above-ul.R`, `R/estimate.R`, `R/estimate-checks.R`,
`R/audit.R`, `R/outliers.R`, `R/vehicle-use.R`; `ref_requirements`,
`ref_iron_requirements`, `ref_who2009_flour`; P50, P60, P71, P76 of
`docs/improvements.md`; Tang et al. 2021 (*Ann NY Acad Sci* 1508:105–122,
doi:10.1111/nyas.14697), full text opened in this session.

Nothing here changes a calculation that exists: the corrections add columns,
checks and three exported functions, and rename three things.

## 1. Record loss (correction 1, H1)

`apparent_intake()` adds three columns per household, next to `n_records`
and `n_records_used` (kept):

| Column | Definition |
|---|---|
| `n_records_included` | records of the household with `include` |
| `share_records_used` | `n_records_used / n_records_included`; `NA` when the denominator is 0 |
| `share_grams_used` | purchased grams (`qty_g_d`) of the used records over those of the included records that have grams; `NA` when the denominator is 0 |

`share_grams_used` is an upper bound of what was kept: a record without
grams is in neither term. The help says so. A record left out by
`outliers = "exclude"` counts as not used: it is a loss, chosen by the
caller, and the log already separates the causes.

`apply_scenario()` carries the three columns unchanged. `inadequacy()` and
`above_ul()` return `share_records_used` in every row, next to `coverage`.

**Gate.** `inadequacy()` and `above_ul()` take a new required argument
`min_records_used`, one number in `[0, 1]`, no default; `0` accepts any loss
and says so in the log. The figure compared is overall, as for
`min_coverage`: `sum(n_records_used) / sum(n_records_included)` over the
households with at least one included record, whatever their status (a
household that lost all its records is the worst case and must count),
unweighted by survey weights, on the baseline. Below the threshold the call
aborts with `hcesfort_error_coverage`, with a field `measure`
(`"records_used"`; the existing gate sets `"composition_value"`), the
overall shares by records and by grams, and the hint to rank the causes with
`unmatched_foods()`. The log gets a note `records_used` with both shares.

A household-level gate (households below the threshold become "not
estimated") was rejected: it selects households by the quality of their
food list, which correlates with what they eat. The per-household column is
there for a domain (section 3) as a sensitivity analysis.

**Names.** `<nutrient>_coverage`, `coverage` and `min_coverage` keep their
names; the help and the error message say "share of the edible grams *used*
that have a composition value" and point to `min_records_used` for the
records that never got there.

Not in this correction: `vehicle_coverage()` has the same loss
(`n_records_no_grams`: the vehicle is acquired but adds no grams, so the
scenario adds too little). `apply_scenario()` writes a log note with the
count; a gate is recorded as a proposal (P85, medium, after acceptance
step 1).

## 2. Where the cut-point is not valid (correction 2, H2, L9)

The requirements contract of `inadequacy()` gains two columns:

| Column | Type | Meaning |
|---|---|---|
| `cutpoint_valid` | logical, no `NA` where `ear` has a value | `FALSE`: the requirement is known to be skewed, so the EAR cut-point does not apply |
| `ear_bioavailability` | number in (0, 1] or `NA` | absorption the EAR assumes, when the source states one |

A `requirements` table without `cutpoint_valid` is an
`hcesfort_error_schema` that says how to add it. `above_ul()` does not need
either column.

**Rule.** A nutrient with an `ear`, `cutpoint_valid = FALSE` and no entry in
`distribution` aborts with `hcesfort_error_value`: the message names the
nutrient and gives the two ways out (pass its requirement distribution, as
`ref_iron_requirements` does for iron, or leave the nutrient out of
`requirements`). There is no argument to force the cut-point: the original
analysis reported iron only by the probability approach, at 10% and 18%
(maintainer, 2026-11-12), so no legacy figure needs it.

**`ear_bioavailability` informs, it does not rescale.** For a cut-point
nutrient with a value, the log gets a note `ear_assumes_bioavailability`
with the value. Rescaling a cut-point by a ratio of absorptions is a method
no source opened so far supports; a diet of lower absorption is handled by
passing a requirements table derived for it, which is what Tang et al. 2021
do for zinc (harmonised average requirements "assum[ing] low bioavailability
because of a diet high in unrefined grains", notes of Figures 1 and 2). That
table is the H-AR item of v0.2.

**Values and sources for `ref_requirements`.**

| Nutrient | `cutpoint_valid` | `ear_bioavailability` | Source and status |
|---|---|---|---|
| iron | `FALSE` | 0.18 | Not valid: Tang et al. 2021, notes of Figures 1 and 2, pp. 112–113 ("iron inadequacy cannot be defined using the … cut-point method due to the nonnormal distribution of iron requirements"), **verified**. Primary source IOM 2000 (*Applications in Dietary Assessment*), **pending**. 0.18: IOM 2001, chapter 9, pp. 316–317 and 343, already in `SOURCES.md` |
| zinc | `TRUE` | `NA` | The absorption the IOM zinc EAR assumes was not read: `# SOURCE PENDING` (IOM 2001, chapter 12) |
| the others | `TRUE` | `NA` | `TRUE` means "no skewed requirement recorded", not a positive finding; the conditions of the method are in IOM 2000, **pending** |

Opus enters these rows in `data-raw/requirements.csv` and `SOURCES.md` with
exactly these statuses, and adds Tang et al. 2021 to the documents list.

## 3. Household flags as domains (correction 3, H3)

`estimate_prevalence()` (renamed, section 7) and `estimate_difference()`
gain one argument:

```r
estimate_households(design, risk, "p_inadequate",
                    domain = "energy_plausible", domain_from = intake_flagged)
```

- `domain` stays the name of a logical column. With `domain_from = NULL` it
  is looked up in `x`, then in the design, as today.
- `domain_from` is a table returned by the package (`hces_tbl`) with
  `household_id` and the column named by `domain`. It must have exactly one
  row per household (`hcesfort_error_key` otherwise: filter one vehicle or
  one scenario first) and cover every household of the design
  (`hcesfort_error_join` otherwise, with the count). The join is
  one-to-one and checked.
- A household whose flag is `NA` is outside the domain; the log counts them
  (`domain_flag_missing`).
- The log of the estimate records the domain and its origin, and takes in
  the log rows of `domain_from` that it does not have yet (section 5), so
  the thresholds behind the flag are in the log of the figure.

This serves `flag_energy_plausibility()`, a domain on
`share_records_used`, and "among households that acquired the vehicle"
(`vehicle_coverage()` filtered to one vehicle). The alternative, carrying
the logical columns of `x` through `inadequacy()` and `above_ul()`, was
rejected: which columns travel would depend on what the table happens to
hold.

## 4. Intake and vehicle use on the same footing (correction 4, accepted)

Accepted as the review proposes, with these contract additions:

- `hces_vehicle_use` gains `afe` and `n_members` (per household, repeated
  on its rows).
- `hces_intake` and `hces_vehicle_use` keep the outlier decision they were
  built with (the rule written by `flag_outliers()`, or none, and
  `"exclude"`, `"keep"` or none) in an attribute that travels like
  `nutrients`.
- `apply_scenario()` aborts with `hcesfort_error_join` when the AFE of a
  household differs between the two tables or the outlier decisions differ,
  stating which. P76 is closed by this.

## 5. Audit log (correction 8, M7, P50)

**No repeated branches.** Every merge of two logs goes through one internal
function that appends the rows of the second log that the first does not
already hold, compared as whole rows *with multiplicity* (a row present
twice in both is kept twice; a step run twice in one branch stays twice).
The log format of `docs/design-task2.md` does not change. A call id per row
was rejected: it needs a ninth column and either a random value (the log
stops being reproducible) or a session counter (the log depends on the
order of unrelated calls).

**`audit_summary(x)`**, exported. One row per step, kind and cause for the
kinds `excluded`, `flagged`, `filled` and `external_change`, in log order:
`step`, `kind`, `cause`, `detail`, `n_records`, `share_records` (of the
`input` row of the same step and table, `NA` without one), `n_households`,
`qty_g`. A plain tibble. A function and not a `summary()` method, so that
`summary()` of a result stays the data-frame summary. No `print` method: a
header line needs `pillar`, a new import.

**`audit_record(x, step, kind, cause, n_records, n_households = NA,
qty_g = NA, detail = NA, table = NULL)`**, exported, for adapters. It
returns `x` with one row appended to its log.

- `x`: a table carrying a log (the adapter validates first, then records
  what it did before or after).
- `step`: required; the adapter's own name for the step, for example
  `"engih2018::combine_sections"`. The name of an hcesfort function is an
  `hcesfort_error_argument`, so the package's rows and the adapter's can
  never be confused.
- `kind`: `"excluded"`, `"flagged"`, `"filled"` or `"note"`. `"input"` and
  `"external_change"` stay reserved to the package.
- `cause`: snake case; `n_records`: a count; `table`: defaults to the table
  of `x`.

This is the sanctioned way to log an edit of a carrier (the section rule,
an imputed age, `acquired` set to `FALSE`): `dplyr::mutate()` keeps the
carrier, `audit_record()` states what was done.

## 6. Small additions (correction 10, M10, M8, M12)

**`reference_energy(sex, age_years, weight_kg, pal,
bmr = hcesfort::ref_bmr_equations)`**, exported. Returns
`(slope_kcal_kg * weight_kg + intercept_kcal) * pal` for the row of `bmr`
with that sex and age; scalars only; `hcesfort_error_value` when no row
covers the age. `adult_equivalents()` keeps `reference_kcal` as a number.
The examples and the vignette use the helper, and the invariant test "the
reference woman has exactly 1 AFE" calls it.

**Vehicle grams per capita.** `vehicle_coverage()` adds
`qty_vehicle_g_d_pc`: the household's grams per day divided by `n_members`,
under the same status rule as `qty_vehicle_g_d`. Its design-based mean is
the figure the availability bands of `ref_who2009_flour` are read with. The
basis of those bands is quoted from WHO 2009 in the help by whoever
implements, with the document open; not from this note.

**`who2009_levels(availability_g_d, extraction, table =
hcesfort::ref_who2009_flour)`**, exported (P71). Returns the rows of the
table whose band contains the number, for that extraction: a filter with
checked arguments, nothing more. Choosing the compound, the form of
vitamin A, the vehicle name and the compliance, and binding the rows into a
scenarios table, stays in the user's code and is shown in the vignette. A
function that built scenario rows would have to default those choices.

**P60, the original outlier rule.** The adapter does the join:
`composition_id` is added to the grams table with a checked many-to-one
join, logged with `audit_record()`, and `flag_outliers(by =
"composition_id")` is called on it. `flag_outliers()` keeps taking only
`hces_grams`: flags computed after the link would not reach
`vehicle_coverage()`, and section 4 would then refuse the pair. If
acceptance step 1 does not reproduce the flag counts, the smallest change
is an option `min_group_count = "all"`, decided then with the counts in
hand.

## 7. Renames (L1, L2), before the vignettes

Approved in principle by the maintainer (answer 3); the names are decision 6.

| Now | Proposed | Why |
|---|---|---|
| `estimate_prevalence()` | `estimate_households()` | it estimates means and medians too, and the unit of every figure is the household |
| `flag_energy_plausibility(intake, column, min, max)` | `(intake, energy, lower, upper)` | same argument name as `nutrient_density(intake, energy)`; `min`, `max` shadow base R |
| `adult_equivalents(missing = )` | `missing_members = ` | `missing` shadows `base::missing()` |

No deprecation layer: the package has no release. `vehicle_coverage()`,
`inadequacy()` and `above_ul()` keep their names.

## 8. Decisions to approve

Each with the recommended option; "as recommended" approves all.

1. **Gate on record loss is overall, not per household**, and counts every
   household with an included record. Recommended: yes (section 1).
2. **Error class of the new gate:** `hcesfort_error_coverage` with a
   `measure` field, or a new class. Recommended: the existing class.
3. **`_coverage` and `min_coverage` keep their names**, with corrected
   help. Recommended: keep.
4. **`cutpoint_valid` is required in `requirements`** (a user's table
   without it fails) and `TRUE` is shipped for the nutrients with no skew
   recorded, with IOM 2000 pending. Recommended: yes. Alternative: optional
   column, missing read as `TRUE` (silent, not recommended).
5. **`ear_bioavailability` only informs** (log note, no rescaling of the
   cut-point); zinc is shipped as `NA` with `# SOURCE PENDING`.
   Recommended: yes.
6. **Names:** `estimate_households()`, `domain_from`, `audit_summary()`,
   `audit_record()`, `reference_energy()`, `who2009_levels()`,
   `min_records_used`, `lower`/`upper`, `missing_members`. Recommended: as
   listed.
7. **Audit merge by rows with multiplicity**, no call id, no `print`
   method. Recommended: yes.
8. **`who2009_levels()` only filters the table.** Recommended: yes.
9. **P60 by the adapter's join**, `min_group_count` only if step 1 needs
   it. Recommended: yes.
10. **Sources.** IOM 2000 (*Applications in Dietary Assessment*) is still
    not opened. Either the maintainer sends it (as with Tang et al.), or
    the rows stay `pending` in v0.1. Recommended: send it, or allow
    `nap.nationalacademies.org`, before correction 2 is implemented.
