# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A2.5).
- **Branches:** `claude/affectionate-volta-a1nbds` in `hcesfort` (this
  handoff, roadmap, improvements) and in `hcesfort.engih2018` (the code),
  both pushed. Nothing merged into any `main`. The earlier work of A2.1 to
  A2.4 is on this branch too.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first (the adapter's
  tests call `hcesfort::validate_*()`), then `R CMD INSTALL .` of the
  adapter before lint. The `data-raw/` scripts read the parameter files
  from `../analisis_ENGIH2018/data/raw` (`ENGIH2018_PARAMS` overrides) and
  check their md5; tests need only `inst/extdata`.
- **Earlier handoffs:** `git show d813a72:docs/handoff.md` (A2.1 to A2.4,
  open questions 1 and 2 still open), `git show 5ecd534:docs/handoff.md`.

## What was done (in `hcesfort.engih2018`)

| Commit | Content |
|---|---|
| `42aa2ac` | `unit_factors.csv`: 11 generic + 84 + 626 food factors; Section 3A resolved by description (the five rows without code included); dozen `mass_g` 12, volume density 1 (S3, S4). |
| `428ca6c` | `crosswalk.csv` with edible portion; `engih_crosswalk()` applies the two repairs with a log (114 `not_recorded`, 13 unvalidated). |
| `7deeef8` | `composition.csv` (1,466 INCAP + 7,083 FNDDS, ten nutrients with `retinol_ug`, `folic_acid_ug`), `composition_fills.csv` (9 + 269). |
| `1b4904f` | `vehicle_patterns.csv`, `vehicles.csv` (75 + 2; `engih_vehicles("matched")` 38 + 2), `enrichment.csv` (44 rules, equal to design 4.3). |
| `36d67e4` | `food_groups.csv`, `scenarios.csv` (105), `requirements.csv`, `iron_requirements.csv`. |
| `16d8f20` | `engih_tables(vehicles, enrichment)`: all of them with the log. |

240 tests pass; `devtools::check()` 0/0/0; `lintr::lint_package()` clean.
Every source and every pending value is in `data-raw/SOURCES.md` of the
adapter. Invariants of finding 8 are tests (unique Section 2 ids, one
vehicle per composition row, edible portion 1 for matched vehicles, no
food factor on a generic unit).

Choices made inside the design (say if you disagree):

- English vehicle names (`wheat_flour`, `bread`, …, `maize_flour`) with
  `vehicle_group = "wheat"` for the six wheat vehicles; the original names
  are kept in `vehicle_patterns.csv`. Scenario names stay as the original
  ("1a. Norma nacional: harina y pan"), since the control files use them.
- The legacy enrichment rules give each row as its own `enriched_ref_id`
  (not read by `replace_by_ingredient`). They are not for `"subtract"`.
- FNDDS edition is `SOURCE PENDING` in `source`: the design says
  2017-2018, but no file states it.
- `engih_tables()` is internal; the exported `engih2018_tables(options)`
  of the design comes with the options in A2.6.

## Exact next step

**A2.6** (Opus): `engih2018_options()` with presets `"original"` and
`"corrected"` (design, section 3), printed; unknown option an error. Read
section 3 of the design. The options that change tables call
`engih_tables()` and transform its output: `dozen` (S3: `count` with piece
weight by food in the corrected preset; the piece weights need a source,
so the corrected value may have to be `SOURCE PENDING` or wait for A4),
`density` (S4), `vehicles` (S12), `enrichment` (S11, S22). Also build the
S8 energy table there: `hcesfort::ref_energy_requirements` with the 24
infant rows replaced by 649 (boys) and 600 (girls) (design, finding 6).
Then A2.7 and A2.8 as in the roadmap.

## Open questions

1. **Garlic powder** (P226): `food_factors.xlsx` gives code 537 (garlic
   powder) the edible portion 0.87 of fresh garlic. Recommended: keep it in
   step 1 and correct it in A4 as a new E error (edible 1.00). Why: step 1
   reproduces the original; the correction is one commit of step 2.
2. **Finding 7, liquid milk** (P227): the factor 1,000 is on unit 31
   (*Cartón*), not on a missing unit. Recommended: nothing in the code; fix
   the sentence of the design in task 12. Why: the adapter already matches
   the original (no factor for `no_unit`); A1's `sin_unidad_con_fc` should
   be 0 and confirms it.
3. Questions 1 and 2 of the previous handoff (error classes `file`/`md5`
   kept in the adapter; codes in the records outside the food list) are
   still open.

**Answers of the maintainer (2026-11-19):** all approved as recommended.
1, garlic powder: kept in step 1, corrected in A4 as a new E error. 2, liquid
milk: fix the sentence of the design in task 12. 3, error classes `file` and
`md5` stay in the adapter until P13; codes outside the food list: a local
test in A3 shows they move no figure. Note for later: before the companion
repository is made public, confirm that the INCAP table may be redistributed
in `inst/extdata/composition.csv`; if not, download it from the source.

## Recommended model for the next session

**Opus** (A2.6 to A2.8).

## Maintainer review points

1. **Personal names removed from the unit notes.** Five notes of
   `Cuest. B Sec 2` named the person who validated the factor; they now say
   "el responsable":

   ```r
   # in hcesfort.engih2018
   devtools::load_all()
   u <- engih_unit_factors()
   u[grepl("responsable", u$note), c("unit", "food_code", "factor", "note")]
   ```

2. **The pending sources**: read the notes of `data-raw/SOURCES.md` in
   the adapter (composition basis and INCAP units, the two INCAP rows with
   ids 99211088 and 99211110 that the original added, provisional flour
   fractions, scenario levels, requirements).

   ```r
   x <- engih_composition()
   x[startsWith(x$composition_id, "99"), c("composition_id", "name", "source")]
   ```

3. **Vehicles against the original's patterns**: the 38 matched foods and
   the 37 left out (E27).

   ```r
   a <- engih_vehicles("all"); m <- engih_vehicles("matched")
   foods <- read.csv(system.file("extdata", "foods.csv",
                                 package = "hcesfort.engih2018"))
   merge(a[!a$food_code %in% m$food_code, 1:2], foods)
   ```
