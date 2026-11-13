# Design: reports v2 (data readiness report and results report)

- **Date:** 2026-11-13. **Status:** approved by the maintainer on
  2026-11-13: decisions 1–6 and 8–12 as recommended; decision 7 amended
  (section 11). No package code is written in
  this task (12c.0).
- **Input.** `docs/report-requirements-v1.md` (approved 2026-11-13):
  principles P1–P5, requirements DR1–DR8 and R1–R14, acceptance (section
  C). This note replaces `docs/design-report-template.md` where the two
  disagree.
- **Aim.** Two Quarto reports copied by `use_report_template()`: a **data
  readiness report** (decisions taken *with* the data) and a **results
  report** (decisions taken *from* the data), plus the package functions
  and the contracts they need.

## 1. Facts checked in this session

| Fact | How it was checked |
|---|---|
| `acquisitions` has no expenditure column | `R/schema-standard.R` |
| `inadequacy()` and `above_ul()` already **fail** (`hcesfort_error_coverage`) when the overall share of included records used is below `min_records_used`, or the coverage of a nutrient is below `min_coverage` | `R/inadequacy.R`, roxygen |
| `flag_precision()` flags and never removes; `low_precision` is `n < min_n` or a wide interval | `R/estimate-difference.R` |
| A proportion equal in every household of a cell has `se = 0` and no interval | `estimate_cell()`, `R/estimate.R` |
| `unmatched_foods()` is unweighted, counts records with `include = FALSE`, and gives one `match_status` per food | `R/unmatched.R` |
| In `hces_example` (40 households) every `expenditure_group` cell has 8 households, and its estimates rest on 7 or 8 of them (`n`; one household of Q1 and one of Q3 have no estimate) | run in this session |
| The difference between the unlinked share of a domain and that of the rest of the population, with its standard error, is computable with `survey::svytotal()` on four household totals followed by `survey::svycontrast(quote(n1 / d1 - n0 / d0))`; the two ratios agree with `survey::svyratio()` on each subset | run in this session on `hces_example` |
| `validate_enrichment()` accepts a table with no rows | run in this session |

## 2. Architecture

### 2.1 Files copied by `use_report_template(path, lang)`

The interface of `use_report_template()` does not change; it copies both
reports.

| File | Role | Edited by the analyst |
|---|---|---|
| `_inputs.R` | The standard tables of the survey and the list `choices` (section 2.2). The only place where a survey enters | **yes, all of it** |
| `_chain.R` | Runs the chain up to the analysis table, tolerating absent optional tables; computes inventory, ladder, checks and verdict | no |
| `_readiness.R` | Objects of the readiness report only (work queue, unlinked share by domain, plausibility) | no |
| `_results.R` | Estimates of the results report, each computed only if the verdict enables it | no |
| `_tables.R` | Display rules: percentages, points, intervals, suppression, table notes | may |
| `_figures.R` | `ggplot2` code: dot with interval, dumbbell, coverage curve | may |
| `readiness.qmd`, `results.qmd` | The two reports, in the language of `lang` | titles and free text |
| `labels.csv` | Labels of the analyst's codes (section 4) | **yes** |
| `decisions.csv` | Decisions taken with the data (DR7) | **yes** |
| `terms.csv` | Labels of the package's own vocabulary (statuses, reasons, steps, methods), in the language of `lang` | no |

Removed: `report.qmd`, `_headlines.R` (R4: no generated headline) and
`actions.csv` (decision 7).

### 2.2 One source of choices

Both reports must use the same thresholds, or the verdict printed by one
would not be the verdict applied by the other. `_inputs.R` therefore holds
one list, `choices`, and the YAML header of each report keeps only `title`
(written by the analyst, R4) and `lang`. No value of `choices` has a
default in the package.

`choices`: `nutrients`, `energy` (registry name of energy, or `NULL`),
`domains`, `equity_domains` (a subset of `domains`), `comparator`
(decision 7: a named character vector, scenario code → the code of the
scenario it is compared with, or `"baseline"`; `NULL` means every scenario
against `"baseline"`), `min_n`,
`max_half_width`, `min_coverage`, `min_records_used`, `min_linked_share`
(the X of DR5; 0.90 by O1), `iron_bioavailability`,
`iron_bioavailability_sensitivity`, `energy_lower`, `energy_upper`,
`level`, `lonely_psu`. The reference person, the unit-factor priority, the
outlier decision and the compliance model stay in `_inputs.R` as the calls
that use them, as today.

Dropped from the previous template: `country`, `survey` and `year` (R4);
`reference_scenario` (R9: the risk section shows the baseline only);
`equity_domain` (now `equity_domains`); `raw_coverage_threshold` (no
requirement asks for it; P104 stays open for v0.2).

### 2.3 How the results report reads the verdict (DR8)

Both reports source `_inputs.R` and `_chain.R`, and `_chain.R` computes
the verdict with `readiness_verdict()`. The results report reads the
verdict from the same function on the same inputs; no file passes from one
report to the other, so a stale verdict cannot be read (decision 1).

### 2.4 Exhibit registry

Every table is stored as `tables$<id>` (the display data frame) before it
is printed, and every figure as `figures$<id>` (the `ggplot` object), and
a figure is always built from the `tables` object of the same id. The
automated checks of section 9 inspect these two lists.

## 3. Contract changes

### 3.1 `acquisitions` gains the optional column `expenditure_lcu`

Type number, missing accepted, `[0, Inf)`: amount paid for the record, or
its imputed value when the survey gives one, in local currency units, for
the period of `period_days`. Needed by DR3 and DR5 ("of expenditure"):
grams are unknown for a record without a unit factor, so expenditure is
the only measure defined for every record. Derived inside the package as
`expenditure_lcu * household_share / period_days`, the rule of `qty_g_d`.
Absent column: every expenditure share is omitted and the report says so
in one sentence (P5). `hces_example` gains an invented `expenditure_lcu`.

### 3.2 `flag_precision()` gains the column `precision_status`

First rule that applies, in this order:

| Value | Rule | What the report does (R7) |
|---|---|---|
| `small_cell` | `n < min_n` | suppressed: "—" in the table, not drawn |
| `exact` | `se == 0` (every household of the cell has the same value) | one sentence under the table; not a row, not drawn |
| `wide_interval` | half-width above `max_half_width` | shown, marked, explained once in the table note |
| `ok` | otherwise | shown |

`low_precision` keeps its meaning. Detection stays in the package; the
decision (suppress, sentence, mark) is taken by `_tables.R`. Food-group
shares are the one exception of display: an `exact` share of 0 stays in
the table as "0" without an interval (R11).

### 3.3 `unmatched_foods()` becomes the work queue (DR4)

New signature `unmatched_foods(x, households, order = c("grams",
"records", "expenditure"))`. Changes:

- only included records count (`include`), as in `apparent_intake()`;
- grams and expenditure are weighted by the household weight (a checked
  many-to-one join to `households`);
- `reasons`: the distinct reasons of the food's records not linked, in a
  fixed order, separated by `"; "`: the `grams_status` of the records
  without grams and the `match_status` when it is not `matched`;
- `units_no_grams`: the units of its records without grams;
- `expenditure_lcu_d_not_linked`, `share_expenditure` (`NA` without the
  column);
- `rank`, and `cum_share_records`, `cum_share_grams`,
  `cum_share_expenditure`: the coverage reached once this food and all
  those ranked before it are resolved. They are the coverage curve of DR4.

Existing columns keep their names. The interface of an exported function
changes, before any release (decision 4).

## 4. Label table (R2)

One mechanism for every displayed code. `hces_schema("labels")`:

| Column | Type | Rule |
|---|---|---|
| `type` | text | what the code is. Used by the template: `nutrient`, `unit`, `vehicle`, `vehicle_group`, `scenario`, `domain`, `domain_value`, `food_group`, `form`, and optionally `source` |
| `parent` | text, missing accepted | the domain a `domain_value` belongs to; missing for every other type |
| `code` | text | the value as it appears in the tables (compared as text) |
| `label` | text | what is printed; not empty |

Key `type` + `parent` + `code`. A label repeated within `type` + `parent`
is an error: two codes with one label would merge two categories
silently. Row order is display order. Reserved codes are labelled like
any other: `scenario` `baseline`, `food_group` `unclassified` (shipped in
Spanish as "Sin grupo asignado", R11).

- `read_labels(file, needed = NULL)` reads the CSV as UTF-8 text and
  validates it. `needed` is a named list, type → codes (for
  `domain_value`, a named list domain → values); every needed code without
  a label is reported **in one error**, class `hcesfort_error_join`
  (`table = "labels"`, field `missing`: a tibble of type, parent, code),
  with the lines to add. A missing file is `hcesfort_error_argument`; a
  malformed one `hcesfort_error_schema`, `_key` or `_value`.
- `label_codes(x, labels, type, parent = NULL)` returns a factor with the
  labels of the codes present, in table order. A code without a label is
  the same error. There is no fallback to the code.
- `terms.csv` has the same contract and is read by the same function. It
  holds the package's vocabulary, which the analyst does not own; a test
  checks that it is complete in each language.
- `source` labels are optional: a citation is free text, printed as
  written unless it has a label. When every scenario has the same source
  it is printed once, in the table note (R10a).

## 5. New exported functions

Each validates its inputs first and raises classed errors. Names are for
approval (decision 10).

### 5.1 `linkage_ladder(x, households)` (DR3)

`x` from `link_composition()`. One row per step, each a subset of the one
before, on the included records:

| `step` | Records that |
|---|---|
| `records` | are included by the adapter's rule |
| `with_quantity` | have a quantity and a unit |
| `with_grams` | were converted to grams |
| `matched` | belong to a food with a composition match, validated or not |
| `validated` | are linked: validated match with an edible portion |

Columns: `step`, `n_records`, `n_households`, `share_records` (unweighted,
of the first step: the measure `min_records_used` uses), `share_grams`
(weighted grams per day over the weighted grams of the records with
grams; missing for the first two steps, where grams are unknown) and
`share_expenditure` (weighted; missing without the column). The number of
records not included is given in the table note.

### 5.2 `estimate_unlinked(design, x, by = NULL, measure = "grams", level = 0.95, df = "domain")` (DR5)

Share of the included records not linked, by `measure` (`"grams"`,
`"records"` or `"expenditure"`), as a ratio of weighted household totals
(`survey::svyratio()`, through the internal `ratio_cell()`), with the
logit interval of `food_group_shares()`. With `by`, one row per domain
value and four more columns: `rest_estimate`, `difference` (domain minus
the rest of the population), its interval (delta method, section 1; design
degrees of freedom) and `differs`: `TRUE` when that interval excludes
zero (decision 5). Returns an `hces_estimate`, so `flag_precision()`
applies. Nationally, for grams and for expenditure, `1 - estimate` equals
the last step of the ladder (both are weighted; `share_records` of the
ladder is not).

### 5.3 `readiness_inventory(tables, domains = NULL)` (DR1)

`tables`: a named list of the tables as supplied, not validated; an absent
optional table is `NULL` or left out. One row per column of the schemas of
`households`, `members` and `acquisitions`, one per domain named, and one
per user-supplied table. Columns: `table`, `variable` (missing for a table
row), `role` (`essential` when the contract requires it, else `optional`),
`present` (exists and is not all missing), `share_missing` and `needed_by`
(the results sections that depend on it: `all`, a list, or `none`).

It only looks at names and missing values, so it runs on tables that fail
their contract. When an essential row is absent, the readiness report
prints the inventory, one sentence, and stops there; nothing else can be
computed.

Essential tables: `unit_factors`, `crosswalk`, `composition`. Optional:
`enrichment` (absent means no enriched food is declared), `vehicles`,
`scenarios`, `food_groups`. "Food eaten away from home" of DR1 is the
contract variable `meals_home_share`; a survey variable outside the
contract cannot be inventoried.

### 5.4 `readiness_checks(intake, ladder, nutrients, min_records_used, min_coverage, min_linked_share)` (DR2)

One tidy table: `check`, `detail`, `n`, `value`, `threshold`, `met`.

| `check` | `detail` | Threshold |
|---|---|---|
| `household_status` | each `intake_status` (non-response, no records, all records lost, no AFE, estimated) | none |
| `records_without_quantity`, `records_without_grams` | | none |
| `records_used` | | `min_records_used` |
| `composition_value` | each nutrient of `nutrients` (registry names) | `min_coverage` |
| `linked_grams`, `linked_expenditure` | | `min_linked_share` |

`records_used` and `composition_value` are computed by the internal
functions `inadequacy()` uses, so `met` predicts exactly whether
`inadequacy()` would fail. Rows without a threshold have `met` missing.

### 5.5 `readiness_verdict(inventory, checks, domains = NULL)` (DR8)

One row per results section and per domain (missing = national):
`section`, `domain`, `enabled`, `reason` (`missing_input`,
`threshold_not_met`), `detail` (the absent inputs or the checks not met).

| Section | Needs | Gated by |
|---|---|---|
| `coverage`, `quantity` | `vehicles` | — |
| `risk` | — | `records_used`, `linked_grams`, `linked_expenditure`, at least one nutrient meeting `composition_value` |
| `scenarios` | `vehicles`, `scenarios` | as `risk` |
| `food_groups` | `food_groups` | as `risk` |

A domain row is disabled when its column is absent from `households` or
its national row is disabled. An absent essential input disables
everything (`checks` may then be `NULL`). This map is one internal
constant, used also for `needed_by` of the inventory. A nutrient that
fails `min_coverage` is left out of the results and named in one sentence;
the verdict stays by section (decision 6).

### 5.6 `read_decisions(file)` (DR7)

Columns `decision`, `choice`, `evidence`: text, not empty, at least one
row, `decision` unique. Errors as in `read_labels()`.

## 6. Data readiness report

Question: *can this survey support the analysis, and what is left to do?*
Sections in the order of the requirements; each is a table, with a figure
only where named.

| # | Section | Content | Source |
|---|---|---|---|
| 1 | Variable inventory (DR1) | the inventory table | `readiness_inventory()` |
| 2 | Minimum quantity and quality (DR2) | the checks, each threshold with its value and "met / not met" | `readiness_checks()` |
| 3 | Linkage ladder (DR3) | the five steps by records, grams and expenditure | `linkage_ladder()` |
| 4 | Work queue (DR4) | pending foods with reasons and units; figure: coverage reached against foods resolved, with the line of `min_linked_share` | `unmatched_foods()` |
| 5 | Stopping rule and its cost (DR5) | the rule and its status; per domain variable, the unlinked share with interval, the difference from the rest, the flag | `estimate_unlinked()` |
| 6 | Plausibility (DR6) | median energy per AFE nationally and per domain variable against the reference energy; share of households outside `energy_lower`–`energy_upper`; one figure per domain variable | `estimate_households()`, `flag_energy_plausibility()` |
| 7 | Decisions taken with the data (DR7) | `decisions.csv` | `read_decisions()` |
| 8 | Readiness verdict (DR8) | sections by rows, national and each domain by columns, reason where disabled | `readiness_verdict()` |

The readiness report shows variable names, food codes and unit codes as
codes: they are what the analyst edits. Everything else goes through
`labels.csv` and `terms.csv` (decision 8).

## 7. Results report

Headings are questions (R4 allows it). Every exhibit is a table, then its
figure (R5). Table titles state measure, population, unit and scenario;
values are percentages and differences are percentage points. Every
by-domain exhibit is one table and one figure per domain variable (R6),
rendered only when the verdict enables it; otherwise one sentence.

| # | Section | Exhibits |
|---|---|---|
| 1 | Coverage of the vehicles (R8) | 1.1 vehicles: % of households acquiring each. 1.2 vehicle groups and "any vehicle", with a note built from `vehicles`: "wheat flour (any form) = flour, bread or pasta". 1.3 quantity among acquirers: median g per AFE per day, interval, n (O4). 1.4 households acquiring no vehicle, national and per domain variable; omitted when `exact` |
| 2 | Risk of inadequate intake (R9) | Baseline without fortification only. 2.1 one estimate per nutrient; the note gives the method per nutrient and the iron bioavailability. 2.2 per domain variable, panels by nutrient |
| 3 | Fortification scenarios (R10) | 3.1 scenario table: labels, level as mg of nutrient per kg (`level_mg_kg` times `nutrient_fraction` on compound rows), compliance, source. 3.2 effects: baseline %, scenario %, paired difference in points with interval, only for the scenario and nutrient pairs present in `scenarios`. 3.3 one dumbbell per nutrient (baseline point, scenario point, one row per scenario); its note says the interval of the difference is in table 3.2. 3.4 above the upper level, beside the effects: %, the form compared and the direction of the bias, from `ul_scope`. 3.5 equity: per nutrient and domain of `equity_domains`, a table and a dumbbell with one row per domain value and one panel per scenario |
| 4 | Contribution of each food group (R11) | 4.1 shares on the baseline without fortification; the unclassified share in the note; a share of 0 as "0" |
| — | Technical note (R14) | EAR and UL used with source; iron bioavailability and its sensitivity table; link to the readiness report |

- Each scenario is compared with its comparator from `choices$comparator`
  (decision 7): the unfortified baseline by default, or another scenario,
  such as the current standard, to answer "what does this action add to
  the current standard". Exhibits 3.2, 3.3 and 3.5 use the comparator in
  place of the baseline: the dumbbell joins the comparator point to the
  scenario point, and the effects table shows comparator %, scenario %
  and their paired difference. A scenario has one label, from
  `labels.csv`, used everywhere (R10b).
- `_results.R` checks `choices$comparator` before any estimate: every name
  and value is a scenario code of `scenarios` or `"baseline"`, no scenario
  is its own comparator, and every chain of comparators ends at
  `"baseline"` (no cycles). A failure is `hcesfort_error_argument` naming
  the offending entries. The differences come from the existing
  `estimate_difference(reference = )`, called once per distinct
  comparator; no package function changes.
- Where fortification already exists, section 2 is a counterfactual; its
  table title says "without fortification", as R9 requires.
- Session information goes to `results-sessionInfo.txt` and
  `readiness-sessionInfo.txt`, one per report (R12 names one file; two
  reports need two).
- Methods, the direction of each bias and the STROBE-nut mapping of the
  old annex H go to a methods vignette in task 12 (decision 9).

## 8. Traceability

| Requirement | Where |
|---|---|
| P1 | 2.1 (two reports) |
| P2, P4 | 7 (one exhibit per question; no summary page, no annexes) |
| P3 | 2.1 (`_headlines.R` removed) |
| P5 | 5.5, 7 (verdict gates each section; one sentence when disabled) |
| DR1 | 5.3, 6 row 1 |
| DR2 | 5.4, 6 row 2 |
| DR3 | 3.1, 5.1, 6 row 3 |
| DR4 | 3.3, 6 row 4 |
| DR5 | 5.2, 6 row 5 |
| DR6 | 6 row 6 |
| DR7 | 5.6, 6 row 7 |
| DR8 | 2.3, 5.5, 6 row 8 |
| R1 | 7 (order; summary table removed) |
| R2 | 4, 9 (K2) |
| R3 | 9 (K3) |
| R4 | 2.2, 9 (K4) |
| R5 | 2.4, 7, 9 (K5) |
| R6 | 7, 9 (K6) |
| R7 | 3.2, 9 (U8, K7) |
| R8 | 7 row 1 |
| R9 | 7 row 2 |
| R10 | 7 row 3, 9 (K8) |
| R11 | 3.2, 7 row 4 |
| R12 | 7 (notes), 9 (K9) |
| R13 | maintainer's print preview; 9 (K5: no empty figure) |
| R14 | 7 (technical note) |

## 9. Automated checks (test specifications)

**Unit tests of the package** (always run; hand-built fixtures; expected
values computed by hand in the test).

| Id | Req. | Test |
|---|---|---|
| U1 | DR1 | The inventory has exactly one row per column of the three schemas, one per domain and one per user table; removing a column turns `present` to `FALSE` for that row only |
| U2 | DR2 | Every threshold given appears with `met`. Invariant: `met` is `FALSE` for `records_used` (or a nutrient) exactly when `inadequacy()` raises `hcesfort_error_coverage` for that measure |
| U3 | DR3 | Counts by hand on the fixture of `test-unmatched-foods.R`; `n_records` and every share non-increasing; equal weights give the unweighted shares; scaling the weights or the quantities by k changes no share; row order does not matter |
| U4 | DR4 | New columns by hand; cumulative shares non-decreasing and ending at 1; by records and by grams, the first cumulative share minus the food's own share equals the last step of the ladder |
| U5 | DR5 | Estimate and standard error equal `survey::svyratio()`, and the difference `survey::svycontrast()`, to 1e-8 on a small design; `differs` is `TRUE` on a fixture built to differ and `FALSE` on one built not to; missing for the national row |
| U6 | DR7 | Missing file, missing column, empty cell and repeated decision give their classed errors |
| U7 | DR8 | All enabled on the example; removing `region` disables only the rows of `region`; removing `food_groups`, `vehicles` or `scenarios` disables exactly the sections of 5.5; a threshold not met disables `risk`, `scenarios` and `food_groups` with `threshold_not_met` |
| U8 | R7 | `precision_status` by hand for each rule and for a cell that meets two |
| U9 | R2 | A missing label fails with every missing code listed; repeated key and repeated label fail; `label_codes()` follows table order and never returns a code |
| U10 | R2 | `terms.csv` of each language has a label for every value of the package vocabulary the reports print |

**Tests on the knitted reports** (`knitr` on `hces_example`, both
languages; skipped without `knitr`, `rmarkdown` or `ggplot2`). The helper
copies the template, may append lines to `_inputs.R`, knits, and returns
the Markdown with `tables` and `figures`.

| Id | Req. | Test |
|---|---|---|
| K1 | C1 | Both reports knit; the two session files exist |
| K2 | R2 | Results report: no `name()` pattern, no code span, no column name of an estimate table, no code of `labels.csv` or `terms.csv` as a whole word (Spanish: every code; English: codes with an underscore, since `flour` is also a word) |
| K3 | R3 | Neither report contains "Analista" or "Analyst" |
| K4 | R4 | The YAML of the results report has no `params` but `lang`; no line of the body is a bold sentence |
| K5 | R5, R13 | Every element of `figures` is a `ggplot` with non-empty x and y titles and at least one row of data; every figure has a table of the same id printed before it; a percentage table has values in 0–100 and its figure plots the same columns |
| K6 | R6 | With `households$region <- NULL` appended, no table or figure id of `region` exists, one sentence names its label, and the render does not fail |
| K7 | R7 | With `min_n = 8`, cells with `n` = 7 print "—" and are absent from the figure data; an `exact` estimate appears in a sentence and in no table row |
| K8 | R10b | The scenario values of every table and figure are labels of type `scenario`; each scenario has one |
| K9 | R12 | No heading matches "Anexo" or "Annex" |
| K10 | DR3 | `tables$ladder` is non-increasing |
| K11 | DR2 | `min_records_used`, `min_coverage` and `min_linked_share` each appear in `tables$checks` with a status |
| K12 | DR7 | Without `decisions.csv` the readiness report fails with `hcesfort_error_argument` |
| K13 | DR8, P5 | With `food_groups <- NULL` the results report knits and section 4 is one sentence; with an essential column removed the readiness report knits up to the inventory |
| K14 | — | Every hcesfort function the template calls is exported (existing test) |
| K15 | R2, R13 | Where Quarto is installed: both render to HTML and the results HTML has no `<code>` element |
| K16 | R10 | Decision 7 as amended: a comparator other than the baseline is used in 3.2, 3.3 and 3.5; a cycle or an unknown code fails with `hcesfort_error_argument` |

CI installs Quarto on one runner so that K15 runs (P102).

## 10. Commit plan (12c.1 onwards, Opus)

Each commit at most 300 lines of code, with its tests, `devtools::test()`
green and lint clean; `NEWS.md` updated with each exported change.

| Step | Content |
|---|---|
| 12c.1 | `expenditure_lcu` in the schema of `acquisitions`; invented column in `hces_example`; md5 |
| 12c.2 | `linkage_ladder()` and the internal record measures (U3) |
| 12c.3 | `unmatched_foods()` as the work queue (U4) |
| 12c.4 | `estimate_unlinked()` and the internal contrast (U5) |
| 12c.5 | `precision_status` in `flag_precision()` (U8) |
| 12c.6 | Schemas `labels` and `decisions`; `read_labels()`, `label_codes()`, `read_decisions()` (U6, U9) |
| 12c.7 | `readiness_inventory()`, `readiness_checks()` (U1, U2) |
| 12c.8 | `readiness_verdict()` (U7) |
| 12c.9 | Shared template files, `labels.csv`, `terms.csv`, `decisions.csv`; readiness report in English (K1, K3, K10–K13, U10) |
| 12c.10 | Readiness report in Spanish |
| 12c.11 | Results report in English, with `choices$comparator`; old `report.qmd`, `_headlines.R` and `actions.csv` removed; `use_report_template()` documentation (K2, K4–K9, K14, K16) |
| 12c.12 | Results report in Spanish |
| 12c.13 | Quarto in CI (K15); specification, `NEWS.md`, self-review, handoff with the maintainer's render of both reports on ENGIH 2018 (acceptance C2) |

A step that would pass 300 lines is split. Stop and return to Fable if a
contract of sections 3 to 5 has to change.

## 11. Decisions for the maintainer

Recommended option first.

1. **How the results report reads the verdict.** *Recommended:* both
   reports compute it with `readiness_verdict()` from the same
   `_inputs.R`. Alternative: the readiness report writes a file the results
   report reads; it can be stale.
2. **Where the choices live.** *Recommended:* one list `choices` in
   `_inputs.R` for both reports; the YAML keeps `title` and `lang`.
   Alternative: YAML `params` in each report, which can disagree.
3. **Expenditure.** *Recommended:* optional column `expenditure_lcu` in
   `acquisitions` (a contract change). Without it DR3 and DR5 report grams
   and records only.
4. **Work queue.** *Recommended:* extend `unmatched_foods()` (it now needs
   `households`). Alternative: a second function beside it, with most of
   its content repeated.
5. **Flag of DR5.** *Recommended:* a domain is flagged when the 95%
   interval of the difference between its unlinked share and that of the
   rest of the population excludes zero; the table shows the difference in
   points and the note says the flags are not adjusted for the number of
   comparisons. Alternatives: the domain's interval excludes the national
   point estimate (simpler, ignores the uncertainty of the national figure
   and that the domain is part of it); a fixed gap in points set by the
   analyst (no uncertainty: small cells would be flagged by noise).
6. **What a threshold not met does.** *Recommended:* it disables the
   sections that depend on it, as `inadequacy()` already fails below
   `min_records_used` and `min_coverage`. To go on, the analyst changes
   the threshold, and the readiness report prints it. No "render anyway"
   switch and no new threshold on the share of households with an
   estimate.
7. **Comparator.** *Recommended:* every scenario against the unfortified
   baseline (R9, R10f); `actions.csv` and the comparisons between two
   scenarios are removed. They can return in v0.2 if a country needs
   "proposed against current".
   **Amended by the maintainer (2026-11-13):** `actions.csv` is removed,
   but the comparison against another scenario stays, through
   `choices$comparator` (sections 2.2 and 7), with `"baseline"` as the
   default. Reason: where a standard already exists (wheat flour in the
   Dominican Republic), the policy question is what each additional
   action adds to the current standard, not only to no fortification.
   No contract of the package changes. Test K16 (added): with
   `comparator = c(<scenario> = <other scenario>)` appended to
   `_inputs.R`, table 3.2 shows that pair and no baseline row for that
   scenario; a cycle fails with `hcesfort_error_argument`.
8. **Codes in the readiness report.** *Recommended:* variable names, food
   codes and unit codes are printed as codes there; R2 applies in full to
   the results report, R3 to both.
9. **Technical manual of R12.** *Recommended:* a methods vignette in task
   12 (methods, direction of each bias, STROBE-nut mapping). Nothing of it
   is written in 12c.
10. **Names.** `linkage_ladder()`, `estimate_unlinked()`,
    `readiness_inventory()`, `readiness_checks()`, `readiness_verdict()`,
    `read_labels()`, `label_codes()`, `read_decisions()`; column
    `precision_status`; column `expenditure_lcu`.
11. **`min_n` of the example.** *Recommended:* 8, so the shipped render
    shows both a suppressed cell (`n` = 7) and a shown one (`n` = 8). It is
    an example value, said so in `_inputs.R`. With 10 every
    `expenditure_group` cell of the example is suppressed.
12. **Equity exhibits.** *Recommended:* only for the domains of
    `equity_domains`, since each adds a table and a figure per nutrient.
    Alternative: every domain.
