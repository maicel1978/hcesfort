# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A2.6, A2.7).
- **Branches:** `claude/gracious-sagan-vjl3h5` in `hcesfort` (this
  handoff, roadmap, improvements) and in `hcesfort.engih2018` (the code),
  both pushed. Nothing merged into any `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first (the adapter now
  imports it), then `R CMD INSTALL .` of the adapter before lint. A1's
  stage tables are on branch `claude/intelligent-cori-3aev98` of
  `analisis_ENGIH2018` (`git fetch origin claude/intelligent-cori-3aev98`,
  then `git show FETCH_HEAD:data/auditoria/cifras_control/etapas/<file>`).
- **Earlier handoffs:** `git show 14eedb8:docs/handoff.md` (A2.5 and the
  answers of the maintainer), `git show d813a72:docs/handoff.md`.

## What was done (in `hcesfort.engih2018`)

| Commit | Content |
|---|---|
| `0d3a4c7` | `engih2018_options(preset, ...)`: 12 options (S1, S3, S4, S5, S8, S10 ×2, S11, S12, S15, S16, S22), presets `"original"` and `"corrected"`, print with changed options marked, unknown option or value an `hcesfort_error_argument`. `engih2018_tables(options)`: the tables of 1.8, the S8 energy table (24 infant rows at 649 and 600), package requirements, `enrichment_shares` (S22), one log note per option. `hcesfort` moved to Imports. |
| `103b5d5` | `engih2018_survey(dir, options)`: verify, read, build, drop the 11 crosswalk non-foods with a count, `outlier_group`, `hcesfort::validate_survey()`, the adapter's log into each table's audit log with `audit_record()`. Tested on the invented sheets through `survey_from_sheets()`. |

382 tests pass; `devtools::check()` 0/0/0; `lintr::lint_package()` clean.

Choices made inside the design (say if you disagree):

- Only the choices whose "Where" is the adapter are options (design,
  section 3); the arguments of hcesfort functions (S2, S6, S7, S9, S13,
  S14, S17 to S21, S23, S24) are passed by the chain, as in the design.
- `days_missing` is not an option: A1 found no missing day, and a missing
  day is an error (A2.3).
- S22 is the option `group_shares`; the tables give `enrichment_shares`
  (no rows for `"composition"`), to build the baseline of the food-group
  shares apart from the baseline of the scenarios.
- The table log notes the options with `n_records = 0` and the value in
  `detail`.

## Exact next step

**A2.8** (Opus): move the export script of A1
(`scripts/exportar_cifras_etapas.R` on branch
`claude/intelligent-cori-3aev98` of `analisis_ENGIH2018`) to the companion
repository (A-D2); acceptance tests skipped with a message without
`ENGIH2018_DATA`; `renv.lock`; P230 (md5 of the frozen CSVs) if small;
`devtools::check()` and lint once for A2. Then A3.

## Open questions

1. **Corrected values without data** (P233): `dozen = "count"`,
   `density = "by_food"`, `enrichment = "pairs"` and `levels = "standard"`
   are refused by `engih2018_tables()` until their data are entered with a
   source, so `engih2018_tables(engih2018_options("corrected"))` is an
   error today. Recommended: keep it so, and enter each data set in its
   commit of A4 (E2, E18, E6, E8). Why: a wrong value (12 g per dozen
   oranges, density 1 for oil) or a silent loss of grams would be worse
   than a clear refusal, and step 2 moves one row at a time from the
   original preset. Alternative: convert nothing for those records and
   count them (`no_piece_weight`, `no_density`), which would remove all oil
   from the corrected figures.
2. **The dozen is larger than the design says** (P231): A1's
   `e_e2_docenas` gives 218 records in 22 foods (passion fruit 108, sour
   lime 28, orange 22, ...), not 13. Recommended: in A4, before E2 runs,
   rewrite its expected direction and find piece weights with a source
   for the 22 foods (or for the few that carry most records). Do you have
   a source for piece weights in the Dominican Republic?
3. **Outlier group of unmatched records** (P232): they share one group per
   section (missing `outlier_group`). Nothing of step 1 moves. Recommended:
   decide in A4, at E27, between grouping them by food code and leaving
   them out of the rule.

## Recommended model for the next session

**Opus** (A2.8, then A3).

## Maintainer review points

1. **The two presets, side by side:**

   ```r
   # in hcesfort.engih2018
   devtools::load_all()
   engih2018_options("original")
   engih2018_options("corrected")
   engih2018_options("original", vehicles = "all")  # one row of step 2
   ```

2. **The S8 energy table** (649 and 600 kcal in the 24 monthly rows,
   every yearly row as the package):

   ```r
   t <- engih2018_tables()
   e <- t$energy
   e[e$age_unit == "month", c("sex", "age_from", "energy_kcal_d")]
   all.equal(e[e$age_unit == "year", ],
             hcesfort::ref_energy_requirements[
               hcesfort::ref_energy_requirements$age_unit == "year", ])
   ```

3. **The survey on the real files** (needs the microdata): counts of 1.1
   and 1.2, non-foods dropped (purified water alone has 5,937 records) and
   the log.

   ```r
   s <- engih2018_survey(options = engih2018_options("original"))
   sapply(s, nrow)
   l <- hcesfort::audit_log(s$acquisitions)
   l[grepl("^engih2018::", l$step), ]
   ```
