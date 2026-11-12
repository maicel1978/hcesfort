# Design of roadmap task 2: data contracts, classed errors, audit log

Status: **approved by the maintainer on 2026-11-12** (the nine choices of
section 10, recorded in `docs/improvements.md`). What remains is
implementation (three commits, section 9), which `docs/model-routing.md`
assigns to Opus.

Every call to another package named here was run in the build environment
(R 4.3.3, dplyr 1.2.1, tidyr 1.3.2, rlang 1.3.0, cli 3.6.6, srvyr 1.3.1).

## 1. Principles that decide the details

1. **Keys and design fields are never missing; measurements may be.** A
   missing `household_id`, `weight` or `period_days` is a schema failure. A
   missing `quantity`, `unit`, `age_years` or nutrient value is data: the
   validator accepts it and the function that needs the value counts it in the
   audit log and applies the policy its caller chose.
2. **Validators reject the impossible, not the implausible.** A negative
   quantity or a weight of zero is an error. An adult of 110 years or a
   purchase of 400 kg is a matter for a flag (`flag_outliers()`, the
   energy-plausibility flag), with thresholds given by the caller. No
   plausibility threshold lives in a validator.
3. **Fixed English column names with the unit in the name.** The adapter
   renames; the core takes no name-mapping arguments.
4. **No questionnaire is assumed.** `section` and `origin` are free text.
   `period_days` is per record, so a diary, a recall of 7, 14 or 30 days per
   food, and a pantry inventory fit the same table. A survey that records
   grams directly declares the unit `g` with factor 1 in `unit_factors`.
   Surveys with expenditure and no quantity are out of scope.
5. **One schema object per table** drives validation, the error messages and
   the documentation, so they cannot drift apart.

## 2. Classed errors (commit 1)

One internal constructor, `abort_hcesfort(type, message, ..., call)`, wraps
`cli::cli_abort(message, class = c(paste0("hcesfort_error_", type),
"hcesfort_error"), ..., call = call)`. Extra fields travel in `...` and are
read by tests and by users (`e$table`, `e$columns`, `e$rows`).

| Class | Raised when | Fields |
|---|---|---|
| `hcesfort_error_argument` | a function argument (not a table) has the wrong type, length or value | `arg` |
| `hcesfort_error_schema` | input is not a data frame; a required column is missing; a column has the wrong type; a nutrient column of the registry is absent | `table`, `columns` |
| `hcesfort_error_key` | a key is duplicated or missing | `table`, `columns`, `rows`, `n` |
| `hcesfort_error_value` | a value is impossible, outside the vocabulary, or missing where it cannot be | `table`, `columns`, `rows`, `n` |
| `hcesfort_error_units` | a nutrient column lacks its unit suffix; the unit is not understood; two tables disagree on a unit | `table`, `columns` |
| `hcesfort_error_join` | rows of one table refer to keys absent from another; key types differ between tables; a join breaks its declared cardinality | `table`, `other`, `columns`, `n` |
| `hcesfort_error_audit` | a table that should carry an audit log does not (section 4) | `arg`, `expected` |

Later tasks add `hcesfort_error_reference` (reference value without source),
`hcesfort_error_md5` and `hcesfort_error_coverage`. All inherit from
`hcesfort_error`, so `tryCatch(hcesfort_error = )` catches any of them.

Message format, the same everywhere: first line says what failed and in which
table; `x` bullets list the offending columns or the first five rows and the
total count; an `i` bullet says how to fix it. Checks run in three stages
(schema, then keys, then values); each stage reports all of its problems in
one error, so the user does not fix them one by one.

The classes are documented in one help topic, `?hcesfort_errors`.

## 3. Audit log: format (commit 1)

A tibble, one row per fact, in chronological order:

| Column | Type | Content |
|---|---|---|
| `step` | chr | function that wrote the row (`"validate_acquisitions"`, `"convert_units"`) |
| `table` | chr | table the row refers to (`"acquisitions"`) |
| `kind` | chr | `input`, `excluded`, `flagged`, `filled`, `note`, `external_change` |
| `cause` | chr | snake_case reason from the vocabulary of the step (`all` for `input` rows) |
| `n_records` | int | records affected |
| `n_households` | int | distinct households with at least one affected record; `NA` when the table has no household |
| `qty_g` | dbl | grams affected; `NA` when grams do not exist yet at that step |
| `detail` | chr | optional qualifier (a nutrient, a unit, a section); `NA` otherwise |

Rules:

- Every step writes one `input` row (size on entry), so a share is always
  `excluded / input` of the same step, and coverage is measured before
  anything is dropped (E3).
- Causes are **not hierarchical**: a record that lacks both a unit factor and
  a match is counted under each cause. A step that needs the overlap writes it
  as its own cause (`no_factor_and_no_match`). This is what the original's
  two counts (README and feasibility report) could not reconcile.
- `kind = "flagged"` never removes a record; only `excluded` does, and only in
  a step whose argument asked for it (detect, then decide).
- `kind = "note"` records facts that affect interpretation and exclude
  nothing: households without acquisitions, a `compliance` column added as 1.
- `kind = "external_change"` is written by the package when a table changed
  between two of its functions (section 4).

Exported: `audit_log(x)` returns the tibble. Internal: `new_audit_log()`,
`audit_row()`, `audit_add(x, ...)`, `audit_merge(x, ...)` (appends the logs of
secondary tables to the log of the primary table, first argument).

Vocabulary of causes written in task 2 (later tasks add theirs and document
them in the help page of each function):
`all`, `households_without_members`, `households_without_acquisitions`,
`food_module_nonresponse`, `missing_quantity`, `missing_unit`,
`not_included`, `missing_age`, `missing_sex`, `unmatched_food`,
`not_validated`, `missing_edible_portion`, `missing_nutrient_value`,
`compliance_assumed_full`, `rows_changed_outside_package`.

Validators count these but exclude nothing: at validation every such row has
`kind = "note"`.

## 4. Audit log: carrier, chosen by experiment (commit 1)

Two candidates: a classed list (`$data`, `$audit`), or a tibble subclass with
the log in an attribute. The experiment (script kept as the test
`test-audit-carrier.R`) attached a class and an attribute to a tibble and
passed it through 37 operations. Result with dplyr 1.2.1 and tidyr 1.3.2:

| Outcome | Operations |
|---|---|
| class and log survive | `mutate` (also with `.by` and `across`), `filter`, `arrange`, `select`, `rename`, `relocate`, `slice`, `distinct`, `count`, `left_join`/`inner_join`/`semi_join` as the left table, `bind_rows`, `bind_cols`, `replace_na`, `[` on rows or columns, `$<-`, `rbind`, `saveRDS`/`readRDS` |
| class lost, log survives | `group_by` (while grouped), `drop_na`, `as_tibble`, `as.data.frame`, `srvyr::as_survey_design()$variables` |
| both lost | `group_by` then `ungroup`, grouped `mutate`, `summarise`, `pivot_longer`, `pivot_wider`, `nest`, `rowwise`, `merge`, a join as the right table |

Reading: an attribute neither survives reliably nor is lost reliably, and
where it survives a `filter()` it becomes **stale** (the log describes rows
that are no longer there). So the design relies on neither behaviour.

**Decision: tibble subclass `hces_tbl` with the log in the attribute
`audit`**, under three rules that make it safe:

1. **The package never relies on propagation.** Every exported function reads
   the log on entry and re-attaches it explicitly on exit
   (`new_hces_tbl(data, class, audit)`), whatever verbs it used inside.
2. **Loss raises a classed error.** A function that consumes the product of
   another package function requires its class (`require_hces(x, "hces_grams")`)
   and aborts with `hcesfort_error_audit` when it is missing. The message
   names the usual cause (a `summarise`, a pivot or a grouped verb between two
   package functions) and the fix: `restore_audit(x, from = previous)`, which
   re-attaches the class and the log of `previous` after checking that the
   keys of `x` are a subset of its keys.
3. **Staleness is recorded.** The carrier stores the number of rows it had
   when the package last touched it (attribute `audit_rows`). On entry, every
   function compares it with `nrow(x)` and, if they differ, writes an
   `external_change` row (`cause = "rows_changed_outside_package"`,
   `n_records` = the difference) before doing anything else. A user's own
   filter is therefore allowed and visible in the log.

Entry tables are different from products: a plain data frame is accepted
wherever a standard or user-supplied table is expected, and the function
validates it first (which starts its log). Only products of package functions
are required to carry the class.

Why not the list: every result would need `$data` before any tidyverse verb,
against the principle "tidy tibbles in and out"; and a list protects the log
only from accidents, since the user still filters `$data` unseen. Rule 3
gives the subclass a guarantee the list does not have.

Known limit, stated in the documentation: a change of values with the same
number of rows (a `mutate()` on `quantity`) is not detected. A content hash
would detect it at a cost per call that grows with the data; recorded in
`docs/improvements.md` as a low-priority option.

Implementation notes: no `tibble` import is needed (`dplyr::tibble()`,
`dplyr::as_tibble()` and base `class<-`/`attr<-`; `tibble::new_tibble()` was
checked and would do the same). No `dplyr_reconstruct()` method is defined:
the default already behaves as the table above, and the rules do not depend
on it. A `print` method is not added; `audit_log()` is the accessor.

Classes: `hces_households`, `hces_members`, `hces_acquisitions`,
`hces_unit_factors`, `hces_crosswalk`, `hces_composition`, `hces_vehicles`,
`hces_scenarios`, each also `hces_tbl`. Products of later tasks add theirs
(`hces_grams`, `hces_nutrient_content`, `hces_intake`; renamed from
`hces_nutrients`, which is the registry, decision P43 of 2026-11-12).

## 5. Schemas of the standard tables (commit 2)

Types: **id** = character or whole number (integer, or double without
fraction); a factor is rejected with the fix `as.character()`. **number** =
double or integer, finite. **flag** = logical. **text** = character.
"NA" = whether a missing value is accepted. Columns marked * are optional.
Any other column is kept untouched (domains, labels).

### `households`: key `household_id`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `household_id` | id | no | unique | household identifier |
| `weight` | number | no | > 0 | sampling (expansion) weight |
| `stratum` | id | no | | design stratum; a survey without strata passes a constant column |
| `psu` | id | no | | primary sampling unit; a survey without clusters passes `household_id` |
| `food_module_response`* | flag | no | | `FALSE` when the household did not answer the food module |

Domains (region, area, quintile…) are ordinary extra columns; they are named
and checked when a design is declared (task 11). `stratum` and `psu` are
required so that the absence of a design feature is a visible choice of the
adapter and not a default of the core.

### `members`: key `household_id` + `member_id`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `household_id` | id | no | | |
| `member_id` | id | no | unique within household | member identifier (a row number is enough) |
| `age_years` | number | yes | ≥ 0 | age in completed or fractional years |
| `sex` | text | yes | `"female"`, `"male"` | |
| `age_months`* | number | yes | ≥ 0 | for infants, when the requirement table is monthly |
| `pregnant`* | flag | yes | | |
| `lactating`* | flag | yes | | |
| `meals_home_share`* | number | yes | in [0, 1] | share of meals taken at home (E25) |

Missing age or sex is accepted here and counted (`missing_age`,
`missing_sex`); `adult_equivalents()` (task 5) applies the policy its caller
chooses (E10).

### `acquisitions`: key `record_id`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `record_id` | id | no | unique | record identifier (a row number is enough) |
| `household_id` | id | no | | |
| `food_code` | id | no | | survey food code |
| `quantity` | number | yes | ≥ 0 | quantity in the unit of `unit` |
| `unit` | id | yes | | unit code or name, matched to `unit_factors` |
| `section` | text | no | | questionnaire module or source of the record |
| `period_days` | number | no | > 0 | days the quantity is divided by; rule documented by the adapter (E4) |
| `include` | flag | no | | `FALSE` when the adapter's section-combination rule leaves the record out |
| `origin`* | text | yes | | purchase, own production, gift… free text |
| `household_share`* | number | yes | in [0, 1] | share of the acquisition destined to the household |

`record_id` is required because it is what makes "no record is dropped or
duplicated silently" checkable after every join.

### Cross-table check: `validate_survey(households, members, acquisitions)`

Validates the three tables and then:

- key types must be the same class in the three tables, otherwise
  `hcesfort_error_join` (an integer id against a character id fails every
  later join);
- members or acquisitions whose `household_id` is absent from `households`:
  `hcesfort_error_join`, with the count and the first ids;
- households without members, households without acquisitions and households
  with `food_module_response = FALSE`: allowed, counted as `note` rows in the
  log of the table concerned. They stay in the design (decision 8 of
  2026-11-12) and get their status in task 8.

Returns a list of class `hces_survey` with the three validated tables.

## 6. Schemas of the user-supplied tables (commit 3)

### `unit_factors`: key `unit` + `food_code`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `unit` | id | no | | unit code or name |
| `food_code`* | id | yes | | `NA` = factor valid for every food |
| `factor` | number | no | > 0 | per one unit: grams (`mass_g`), millilitres (`volume_ml`) or pieces (`count`) |
| `factor_type` | text | no | `mass_g`, `volume_ml`, `count` | what `factor` means |
| `density_g_ml`* | number | yes | > 0 | needed by `volume_ml` rows |
| `piece_weight_g`* | number | yes | > 0 | needed by `count` rows |
| `source` | text | no | | where the factor comes from |

A `volume_ml` row without density and a `count` row without piece weight are
valid rows of the table and are **not** converted: `convert_units()` (task 6)
counts their records as `no_density` or `no_piece_weight` unless the caller
supplies a value explicitly. This is the typed table of P4 (E2, E18). The
priority between a food-specific and a generic factor is an argument of
`convert_units()`, not part of the contract.

### `crosswalk`: key `food_code`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `food_code` | id | no | unique | survey food code |
| `composition_id` | id | yes | | `NA` = no match |
| `match_type` | text | yes | not `NA` when `validated` is `TRUE` | kind of equivalence (exact, similar, proxy…), free text |
| `validated` | flag | no | | only validated rows enter the calculation |
| `edible_portion` | number | yes | in (0, 1] | edible fraction of the food as purchased, keyed by survey food |
| `yield_factor`* | number | yes | > 0 | grams of the composition food per gram purchased, for a raw purchase matched to a cooked food |

A validated row without `match_type` is an `hcesfort_error_value` (E20);
so is a validated row without `composition_id` (decision P44 of 2026-11-12).
Unmatched, unvalidated and portion-less rows are counted as notes.

### Nutrient registry: `nutrient_registry()`

`nutrient_registry(c(energy = "kcal", iron = "mg", folate = "ug_dfe"))`
returns a tibble of class `hces_nutrients` with columns `nutrient`, `unit` and
`column` (`<nutrient>_<unit>`: `iron_mg`, `folate_ug_dfe`). Rules:

- nutrient names are snake_case and unique;
- a unit is a base (`g`, `mg`, `ug`, `kcal`, `kj`) optionally followed by an
  equivalent tag (`ug_dfe`, `ug_rae`, `mg_ne`, `mg_ate`): the base is parsed,
  the tag is kept as text. An unknown base is `hcesfort_error_units`;
- the package ships no default registry: the set of nutrients is the user's.

Scenario conversions (mg/kg of vehicle to the unit per 100 g) use the parsed
base; conversions between a compound and an equivalent (folic acid to DFE)
come from a reference table with its source (task 4), never from the
registry.

### `composition`: key `composition_id`; `validate_composition(x, nutrients)`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `composition_id` | id | no | unique | |
| one column per registry row | number | yes | ≥ 0 | content per 100 g edible portion |
| `basis` | text | no | must be `per_100g_edible` | the only basis the core computes with |
| `food_state` | text | no | `raw`, `cooked`, `as_consumed`, `unknown` | state the values refer to |
| `source` | text | no | | table and edition |
| `fortified`* | flag | yes | | row describes an enriched or fortified food (E1, E6) |

A registry column absent from the table is `hcesfort_error_schema`; a column
named like a nutrient with another unit (`iron_ug` for `iron = "mg"`) is
`hcesfort_error_units`. Missing nutrient values are accepted and counted per
nutrient (`missing_nutrient_value`, `detail` = the column), never read as zero
(E21). The registry is stored on the validated table (attribute `nutrients`)
and travels with the products.

Optional forms for the upper level (`retinol_ug`, `folic_acid_ug`) are
ordinary registry entries.

### `vehicles`: key `food_code` + `vehicle`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `food_code` | id | no | | |
| `vehicle` | text | no | | vehicle name |
| `vehicle_fraction` | number | no | in (0, 1] | fraction of the food that is the vehicle |
| `source` | text | no | | origin of the fraction; `SOURCE PENDING` is accepted and counted as a note |

The key includes `vehicle` because one food can contain two (a biscuit holds
flour and sugar).

### `scenarios`: key `scenario` + `vehicle` + `nutrient`; `validate_scenarios(x, nutrients)`

| Column | Type | NA | Rule | Content |
|---|---|---|---|---|
| `scenario` | text | no | | |
| `vehicle` | text | no | | |
| `nutrient` | text | no | in the registry | |
| `level_mg_kg` | number | no | ≥ 0 | level added, mg per kg of vehicle |
| `level_basis` | text | no | `nutrient`, `compound` | what the level measures (E8) |
| `compound`* | text | yes | | name of the compound |
| `nutrient_fraction`* | number | yes | in (0, 1]; not `NA` when `level_basis` is `compound` | mass of nutrient per mass of compound |
| `compliance`* | number | no | in [0, 1] | share of the vehicle actually fortified |
| `source` | text | no | | standard or document |

When `compliance` is absent the validator adds it as 1 and writes a note
(`compliance_assumed_full`): full compliance is then a recorded assumption,
not a hidden one. Vehicles named in `scenarios` and absent from `vehicles`
are checked where the two meet (`apply_scenario()`, task 9).

## 7. Exported functions of task 2

| Function | Returns |
|---|---|
| `validate_households(x)`, `validate_members(x)`, `validate_acquisitions(x)` | the validated table, classed, with its log started |
| `validate_survey(households, members, acquisitions)` | list `hces_survey` of the three |
| `validate_unit_factors(x)`, `validate_crosswalk(x)`, `validate_vehicles(x)` | validated table |
| `nutrient_registry(units)` | registry |
| `validate_composition(x, nutrients)`, `validate_scenarios(x, nutrients)` | validated table |
| `hces_schema(table)` | the schema of one table as a tibble (column, type, required, NA, rule, description) |
| `audit_log(x)` | the audit log |
| `restore_audit(x, from)` | `x` with the class and log of `from` |

`validate_*()` is the only family: it is both the validator and the
constructor (it returns the classed table). Validating an already validated
table is allowed and cheap; it adds no rows to the log.

Internal: `abort_hcesfort()`; `new_hces_tbl()`, `require_hces()`,
`audit_check_rows()`; the schema engine `check_schema(x, schema, table)` built
from small checks (`check_columns()`, `check_types()`, `check_key()`,
`check_values()`); one `schema_<table>()` function per table returning the
schema tibble that `hces_schema()` exposes.

Files (each under 300 lines): `errors.R`, `audit.R`, `hces-tbl.R`,
`schema-engine.R`, `schema-standard.R`, `validate-standard.R`,
`validate-survey.R`, `nutrients.R`, `schema-user.R`, `validate-user.R`.

`DESCRIPTION` gains `Imports: cli, dplyr, rlang` as they are first used (P40);
`tidyr`, `survey` and `srvyr` wait for the task that uses them.

## 8. Tests (agreed list)

Fixtures are hand-built tables of two or three households, defined in
`tests/testthat/helper-fixtures.R` and documented there as invented.

Commit 1
- `abort_hcesfort()`: class vector, fields, message bullets.
- Audit log: empty log has the eight columns and their types; `audit_add()`
  appends in order; `audit_merge()` keeps the primary log first.
- Carrier: the three groups of operations of section 4, each asserted (this
  is the experiment, kept as a regression test: a change in dplyr shows here).
- `require_hces()` raises `hcesfort_error_audit` after `summarise()`;
  `restore_audit()` repairs it and rejects a table with foreign keys.
- A `filter()` between two package steps yields one `external_change` row
  with the hand-counted difference.
- Invariant: the log of a table does not depend on row order.

Commit 2
- Each validator: a valid fixture passes and returns the class; extra columns
  are kept; validating twice equals validating once.
- Each rule of each schema fails with its class: missing column and wrong
  type (`schema`); duplicated and missing key (`key`); weight ≤ 0, negative
  quantity, `period_days` ≤ 0, age < 0, sex outside the vocabulary, share
  outside [0, 1], factor column as id (`value` or `schema`).
- Edge cases: zero-row table with the right columns passes; whole doubles are
  accepted as ids, 1.5 is not; all-`NA` optional column passes.
- Counts in the log computed by hand: records with missing quantity, members
  with missing age.
- `validate_survey()`: orphan members and orphan acquisitions (`join`); id of
  different type between tables (`join`); households without members and
  without acquisitions counted, not rejected.
- Invariant: results do not depend on row or column order.

Commit 3
- `nutrient_registry()`: normal case; duplicated nutrient, bad name
  (`argument`), unknown base unit (`units`); equivalent tags parsed.
- `validate_composition()`: missing registry column (`schema`), wrong unit
  suffix (`units`), wrong basis and state (`value`), negative content
  (`value`), missing values counted per nutrient by hand.
- `validate_unit_factors()`: each `factor_type`; duplicated `unit` +
  `food_code` including two generic rows for one unit (`key`); a `volume_ml`
  row without density passes.
- `validate_crosswalk()`: validated row without `match_type` (`value`);
  edible portion 0 and 1.2 (`value`); unmatched and unvalidated counted.
- `validate_vehicles()`: one food with two vehicles passes; fraction 0 fails.
- `validate_scenarios()`: nutrient outside the registry (`value`); compound
  basis without fraction (`value`); compliance absent is added as 1 with its
  note; compliance 1.2 fails.
- `hces_schema()`: every table name; unknown name (`argument`); the columns
  listed equal the columns the validator requires.

## 9. Commit plan

1. **Classed errors, audit-log format and carrier**: `errors.R`, `audit.R`,
   `hces-tbl.R`, their tests, `?hcesfort_errors`.
2. **Standard tables**: schema engine, schemas and validators of
   `households`, `members`, `acquisitions`, `validate_survey()`,
   `hces_schema()`.
3. **User tables and registry**: `nutrient_registry()`, validators of
   `unit_factors`, `crosswalk`, `composition`, `vehicles`, `scenarios`.

Each commit: at most 300 lines of code, `document()`, `test()`, lint; before
each push `check()` with 0/0/0. The task ends with the self-review of
`CLAUDE.md`, `NEWS.md`, the roadmap tick and the review points in
`docs/handoff.md`.

## 10. Choices that need the maintainer's approval

Each with the recommended option, which is the one written above.

1. **Carrier: tibble subclass with the three rules of section 4.**
   Recommended over the classed list: keeps tibbles in and out, and records a
   user's filter instead of ignoring it.
2. **`validate_*()` as the single family** (validator and constructor in
   one). Recommended: one name to learn, no `as_*()` twin.
3. **`record_id` and `member_id` required.** Recommended: without a record key
   a duplicated or dropped record cannot be proved absent; a row number
   satisfies it.
4. **`stratum` and `psu` required, with explicit constant columns when the
   design has none.** Recommended: the absence of a design feature is the
   adapter's visible choice.
5. **Validators reject only impossible values; plausibility is a flag.**
   Recommended: no hidden threshold.
6. **`sex` as `"female"`/`"male"`; other codings are mapped by the adapter.**
   Recommended.
7. **`compliance` optional, added as 1 with a note in the log.** Alternative:
   required column. Recommended: optional with the note, as the specification
   says "default 1" and the note keeps it visible.
8. **`composition$basis` must be `per_100g_edible`.** Other bases are
   converted by the adapter. Recommended: one basis in the core.
9. **Proposal P42 split** (see `docs/improvements.md`): ranking and quality
   controls in v0.1, candidates and review in v0.2. Recommended: yes.
