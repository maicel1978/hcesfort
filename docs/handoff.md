# Handoff

- **Date:** 2026-11-12
- **Model that worked:** Fable 5.2 (`claude-fable-5-2`)
- **Branch:** `main`

## What was done

| Commit | Content |
|---|---|
| `08a5403` | `CLAUDE.md`: link to model routing and handoff; sections on independent references, maintainer review points and chat economy. |
| `4738510` | Maintainer's answers to the eleven questions recorded (`docs/improvements.md`, Decisions 2026-11-12). E4 withdrawn as an error after reading the feasibility report; E1, E3, E7, E10, E15, E24 amended; section 9 of the analysis map. Proposal P42 assessed. Specification and roadmap updated. `docs/erratum-engih2018.md` drafted in Spanish. |
| this commit | `docs/design-task2.md` (design of task 2, carrier chosen by experiment), this file, roadmap sub-items 2.0 to 2.3. |

No package code changed. `devtools::check()` on this commit: 0 errors,
0 warnings, 0 notes; `lintr::lint_package()`: 0 lints.

Environment notes for whoever runs the checks in the cloud container:

- The container has no `en_US.UTF-8` locale and no clock service, so a bare
  `devtools::check()` reports one warning and one note that are not the
  package's. Run it as
  `LANG=C.UTF-8 LC_ALL=C.UTF-8 _R_CHECK_SYSTEM_CLOCK_=0 Rscript -e 'devtools::check()'`.
- roxygen2 installed is 8.1.1 and `DESCRIPTION` says `RoxygenNote: 7.3.1`:
  the first `devtools::document()` will update that line; `check()` does not
  re-document until then.
- `.lintr` removes `cyclocomp_linter`, which lintr 3.4.0 no longer has among
  its defaults: it warns on load. Dropping that line is a mechanical fix for
  the next commit that touches `.lintr`.
- `stringdist` 0.9.17 is installed (relevant to P42 only).

## Exact next step

1. The maintainer approves or corrects the nine choices of section 10 of
   `docs/design-task2.md`.
2. Implement task 2 from that design, in the three commits of its section 9,
   with the tests of its section 8. Start with commit 1: `R/errors.R`,
   `R/audit.R`, `R/hces-tbl.R`, tests and `?hcesfort_errors`.
3. Add `cli`, `dplyr` and `rlang` to `Imports` in the commit that first uses
   each.

Stop and ask for Fable if the implementation needs to change a schema, a
class name or an exported signature of the design.

## Open questions

1. Approval of the nine design choices (`docs/design-task2.md`, section 10).
2. P42: accept the split (ranking and quality controls in v0.1; candidates,
   seeds and review round trip in v0.2)?

## Recommended model for the next session

**Opus 5.5**: implementation of an approved design and its tests.

## Maintainer review points

1. **The carrier experiment.** Check that the three groups of operations in
   section 4 of the design are what your installation gives:

   ```r
   library(dplyr)
   x <- tibble(household_id = c(1L, 1L, 2L), qty_g = c(1, 2, 3))
   x <- structure(x, audit = tibble(step = "start"),
                  class = c("hces_tbl", class(x)))
   has <- function(z) c(class = inherits(z, "hces_tbl"),
                        log = !is.null(attr(z, "audit")))
   has(filter(x, qty_g > 1))                         # TRUE TRUE: survives, stale
   has(summarise(x, s = sum(qty_g), .by = household_id))  # FALSE FALSE: lost
   has(ungroup(group_by(x, household_id)))           # FALSE FALSE: lost
   ```

2. **The E4 evidence.** The two figures recorded (2,050 kcal with 1 day,
   2,189 with 7) come from your compiled report; the repository holds only the
   code of table `tbl-pm`. When the microdata are at hand, the table for
   Sec 3A alone (the name of the per-section energy column is yours to fill
   in):

   ```r
   library(dplyr)
   s3d <- readr::read_csv("data/clean/data_sec3a_consumo.csv")
   ing <- readr::read_csv("data/clean/data_ingesta_micronutrientes_hogar.csv")
   s3d |>
     distinct(id_hogar_unico, dias_observados_hogar) |>
     inner_join(filter(ing, variante == "Sec 3A"), by = "id_hogar_unico") |>
     group_by(dias_observados_hogar) |>
     summarise(hogares = n(), mediana = median(energia_kcal),
               p95 = quantile(energia_kcal, 0.95),
               sobre_6000 = mean(energia_kcal > 6000))
   ```

   The label `"Sec 3A"` of `variante` is a guess from the report's
   `"Sec 2 + Sec 3A"`; check `unique(ing$variante)` first.

3. **The erratum.** Read `docs/erratum-engih2018.md` before sending it: part A
   lists seven errors with their published location; confirm that item 5
   (dozen) and item 7 (basis of the levels) are worded as you want, since both
   are still unmeasured.
