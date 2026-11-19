# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A2, first half).
- **Branches:** `claude/sleepy-pascal-xw5ubk` in `hcesfort` (this handoff
  and the roadmap) and in `hcesfort.engih2018` (the code), both pushed.
  Nothing merged into any `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first (the adapter's
  tests call `hcesfort::validate_*()`); `qpdf` with apt for the check. In
  `hcesfort.engih2018` the whole suite takes seconds; lint needs the
  package installed (`R CMD INSTALL .`), or `object_usage_linter` reports
  every internal function. The parameter files are read from
  `../analisis_ENGIH2018/data/raw` (`ENGIH2018_PARAMS` overrides).
- **Earlier sections of this file** (reviews of 12e and 12e.5, design of
  the adapter, their review points): `git show 5ecd534:docs/handoff.md`.

## What was done (in `hcesfort.engih2018`)

| Commit | Step | Content |
|---|---|---|
| `28bee09` | A2.1 | Package skeleton; `engih2018_registry()` (`inst/extdata/sources.csv`: md5 and bytes of the two microdata from `e00_entradas` of A1, parameter files of `7caab91`, md5 checked equal); `engih2018_data_dir()`, `engih2018_verify()`, `engih2018_download()`; size-limit and no-microdata tests; CI (check, lint). |
| `d576c17` | A2.2 | `read_engih_sheet()` / `check_engih_sheet()`: all text, names normalised to upper case ASCII, required columns and registered size; `build_households()` (household columns must be constant within the household), `check_counts()`, `build_members()`. |
| `84a5ff2` | A2.3 | `build_acquisitions()`: ids, prefixed codes, unit, days, origin, share, fortifiable, exhaustion rule (`stock_missing`), section rules. |
| `4073790` | A2.4 | `inst/extdata/foods.csv`, `storable_patterns.csv`, `storable.csv` (18 + 68 foods, 16 keys, as the design counts). |

128 tests pass; `devtools::check()` 0/0/0; no lints. Builders return
`list(table, log)`: the log rows are applied with `audit_record()` by
`engih2018_survey()` (A2.7), after `validate_survey()`.

Choices made inside the design:

- `days_missing` was dropped (design 1.5 allows it): A1 found no missing
  `DIA`, so a missing day is an error that asks for a decision.
- The adapter's errors use the classes of `hcesfort` (`hcesfort_error_<type>`
  + `hcesfort_error`) and add two types, `file` and `md5`, documented in
  `?engih2018_errors`. See question 1.

## Exact next step

**A2.5** (Opus): the tables of design section 1.8, read section 1.8 and
finding 7 of section 0 first, then section 4.1 (tolerances, dozen) and 4.3
(enrichment, baseline rules) as you reach them. One `data-raw/` script per
table, outputs in `inst/extdata/`, `data-raw/SOURCES.md` (composition
basis `# SOURCE PENDING`), each table passing its `hcesfort::validate_*()`.
Order: unit factors (description → code, the five rows without a code,
`no_unit` for Section 2 liquid milk), crosswalk with the two repairs,
composition and fills, enrichment, vehicles (38 matched, 75 all, maize
flour annex), food groups, scenarios, requirements. Then A2.6 to A2.8 as
in the roadmap.

## Open questions

1. **Error classes of the adapter.** `hcesfort` has no `file` or `md5`
   error type; the adapter raises `hcesfort_error_file` and
   `hcesfort_error_md5` with the common class `hcesfort_error`.
   Recommended: keep them in the adapter and add nothing to `hcesfort`.
   Why: the package has no md5 function yet (P13 lists `verify_md5()`);
   when it gets one, the type moves there.
2. **Codes in the records that are not in the food list** (observation,
   needs microdata). `e01_descripciones` of A1 counts 46 codes and 31
   descriptions in Section 2 records, 772 codes in Section 3A; the food
   list has 30 and 769. The storable table is built from the list, so a
   record whose code is not in it is never stored. Recommended: in A3,
   a local test applies the patterns to the records' own descriptions and
   compares with the codes; no change now. Why: those records have no
   composition match and no grams in the original, so the figures cannot
   move, but the test proves it.

## Recommended model for the next session

**Opus** (A2.5 to A2.8).

## Maintainer review points

1. **The adapter reads your files** (only on your machine, with the
   microdata; the column counts of Section 2, 12, and of the person file
   are from the comments of `01_import.R` and need your files to confirm):

   ```r
   # in hcesfort.engih2018, branch claude/sleepy-pascal-xw5ubk
   devtools::load_all()
   dir <- "<folder with the two xlsx>"
   engih2018_verify(dir)
   p <- read_engih_sheet(dir, "persons")
   h <- build_households(p); check_counts(h$table); h$log
   a <- build_acquisitions(read_engih_sheet(dir, "sec2"),
                           read_engih_sheet(dir, "sec3a"), engih_storable(),
                           "with_record", "survey", "both_exhaustion",
                           "no_stock")
   table(a$table$section, a$table$include)  # stored: e04_agotamiento
   ```

2. **Area by stratum label**: `h$log` above lists each `DES_ESTRATO`
   label with the area the original rule gave it ("Rural" in the label).
   Check that no metropolitan or urban label contains "Rural".

3. **The storable foods**: `read.csv(system.file("extdata",
   "storable.csv", package = "hcesfort.engih2018"))` against the
   original's list of storable foods.
