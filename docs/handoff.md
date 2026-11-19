# Handoff

- **Date:** 2026-11-19
- **Model:** Opus 5.5 (A2.8; A2 closed).
- **Branches:** `claude/jolly-cerf-eykgxd` in `hcesfort` (this handoff,
  roadmap, improvements) and in `hcesfort.engih2018` (the code), both
  pushed. The adapter is not merged into its `main`; `main` of `hcesfort`
  on GitHub is at `f7f5c99`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before lint. `renv` is installed in the container's library
  when the session that wrote the lock ran; a new container may need
  `install.packages("renv")` only to rewrite `renv.lock`.
- **Earlier handoffs:** `git show 6e8c538:docs/handoff.md` (A2.6, A2.7),
  `git show 14eedb8:docs/handoff.md` (A2.1 to A2.5).

## What was done (in `hcesfort.engih2018`)

| Commit | Content |
|---|---|
| `33c7eae` | `inst/acceptance/`: the six control files (from `main` at `7caab91`) and the 21 stage tables of A1 in `etapas/` (from `513ca4a`), byte for byte, with their `LEEME.txt`; `inst/acceptance/README.md` gives the origin of each. `data-raw/acceptance/exportar_cifras_etapas.R`: the export script of A1, unchanged (A-D2). |
| `1b27cb8` | P230: `inst/checksums.csv` (md5 and size of the 45 files of `inst/extdata/` and `inst/acceptance/`), written by `data-raw/checksums.R`; internal `check_frozen()`; `test-checksums.R`, which also checks that the registry's md5 are those of `e00_entradas`. `.gitattributes` keeps those files out of end-of-line conversion (Windows checkout). |
| `0e9f9b2` | `helper-acceptance.R` (`skip_without_microdata()`, `acceptance_survey()` cached, `read_control()`, `stage_value()`); `test-acceptance-a2.R`: verify, households (8,892, sum of weights), members (28,394, no missing age or sex, infants by sex), records kept plus non-foods dropped against `e01_registros`. `renv.lock` (explicit snapshot; `hcesfort` from GitHub `main`). README section on acceptance. |

403 tests, 3 skipped here with the message naming `ENGIH2018_DATA`;
`devtools::check()` 0/0/0; `lintr::lint_package()` clean. **The tests
that need the microdata have never run**: an error on the first run is
likely a column or a vocabulary, to be reported, not worked around.

Self-review of A2 recorded as P234 (md5 checked by tests only), P235 (the
non-food count is not per section) and P236 (lock written with R 4.3.3).

## Exact next step

**A3** (Opus): acceptance step 1, design sections 4.1 to 4.4. Suggested
split, one commit each, all in the adapter's tests with the helpers of
`helper-acceptance.R`:

1. A helper that runs the chain of hcesfort on the survey and the tables
   of the `"original"` preset (`convert_units()`, `link_composition()`,
   `flag_outliers()`, `adult_equivalents()`, `apparent_intake()`, the
   scenarios, the design), cached like `acceptance_survey()`; checked to
   run end to end on the invented sheets of `helper-sheets.R` with the
   real tables, so the code is exercised in CI.
2. Stage comparisons in order (4.3): `e01_registros`, `e03_atipicos`
   (U1, U2), `e04_afe`, `e04_gramos_por_ema`, `e05_ingesta`,
   `e06_vehiculos`, `e06_escenarios`, `e07_diseno`; tolerances of 4.1.
3. The six control files (4.2), all rows; the threshold count of 4.1.

Read first: design 4.1 to 4.4 and 3 (`grep -n "^## \|^### "
docs/design-adapter-engih.md`), the help of each hcesfort function before
calling it. Stop rule of 4.4: a figure that disagrees after the stages
agree, with no household on a threshold, goes to Fable; never widen a
tolerance.

## Open questions

1. **`renv.lock` on your machine** (P236). The lock was written here with
   R 4.3.3 and the versions of this container. Recommended: before the
   first run of A3, run `renv::snapshot()` in the adapter on the machine
   with the microdata and commit the lock it writes, because step 1
   compares to 1e-6 and the figures of A3 will be made there.
   Alternative: keep this lock and rely on the `sessionInfo()` each
   acceptance run writes.
2. **md5 of the frozen files at read time** (P234). Recommended: keep the
   check in the tests only, because checking at every read would break the
   `data-raw/` scripts between writing a table and rebuilding the
   checksums, and CI runs the tests on every push. Alternative: an
   argument of `engih2018_tables()` that runs `check_frozen()`.

**Answers of the maintainer (2026-11-19).** 1: the alternative. On the
maintainer's machine `renv::snapshot()` refuses `hcesfort` (installed from a
local clone, "unknown source"); keep the current lock and make every
acceptance run of A3 write its `sessionInfo()` next to its results. P236
stays open for later. 2: approved as recommended.

**Review point 1 done (2026-11-19, maintainer's machine: Windows, R 4.6.2,
`hcesfort` cb17629, adapter 0e9f9b2, microdata md5 as registered):**
`devtools::test(filter = "acceptance")` gave FAIL 0, WARN 0, SKIP 0,
PASS 14 in 55.6 s. The adapter reads the real files; households, members
and records match the stage figures of A1. A3 can start.

## Recommended model for the next session

**Opus** (A3).

## Maintainer review points

1. **The acceptance tests of A2 on the microdata** (expect 0 skipped, 0
   failed; report any failure as it is):

   ```r
   # in hcesfort.engih2018
   Sys.setenv(ENGIH2018_DATA = "path/to/the/microdata")
   devtools::test(filter = "acceptance")
   ```

2. **The control figures are the files of the original analysis** (all
   `TRUE`):

   ```r
   a <- "path/to/analisis_ENGIH2018/data/auditoria/cifras_control"
   f <- list.files("inst/acceptance", recursive = TRUE)
   f <- f[f != "README.md"]
   tools::md5sum(file.path("inst/acceptance", f)) ==
     tools::md5sum(file.path(a, f))  # etapas/ after checking out 513ca4a
   ```

3. **The frozen-file check catches an edit** (expect a failure of
   `test-checksums.R`, then undo):

   ```r
   cat("x\n", file = "inst/extdata/scenarios.csv", append = TRUE)
   devtools::test(filter = "checksums")
   system("git checkout inst/extdata/scenarios.csv")
   ```
