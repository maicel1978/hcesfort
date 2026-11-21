# Handoff

- **Date:** 2026-11-21
- **Model:** Opus 5.5 (A4 closed; 12c.14a and 12c.14b done).
- **Branches:** `claude/awesome-fermi-oxv0vv` in `hcesfort` (docs only)
  and in `hcesfort.engih2018`, both pushed, both from `main`.
- **Environment:** `R CMD INSTALL .` of `hcesfort` first, then of the
  adapter, before its tests and lint.
- **Earlier handoffs:** `git show 363ec93:docs/handoff.md` (the eight
  questions and the findings on the template), `git show
  3be3299:docs/handoff.md`.

## Maintainer's answers of 2026-11-21 (on the eight questions)

1. No hybrid "original" report: only the corrected one is rendered. The
   comparison with the delivered report comes later as an errata table
   from `acceptance-results/step2/` (roadmap 12c.15).
2. Corrected = the state after the last step of step 2; the E8
   sensitivity as a note in the report, no second render.
3. `min_coverage`, `min_records_used`, `min_linked_share` = 0 (0.9 has
   no source); the coverage shown explicitly (1.91% of the grams without
   a link, without water), said in `decisions.csv`.
4. 500 to 6000 kcal, the original's choice without a published source,
   recorded as such.
5. Region, area and quintile; no province. **The quintile is of
   "______" (income / expenditure) per capita: the blank was not
   filled.**
6. Yes (seven nutrients; iron bioavailability 0.10, sensitivity 0.18).
7. **`GRUPO_REGION` comes as "______": the blank was not filled.**
8. Yes (`engih2018_report()` prepares the folder; Quarto renders).

## What was done (adapter)

1. `64d6491`: label tables `inst/report/{es,en}/labels.csv`.
2. `2ff2591`: `engih2018_report(path, lang)`: the hcesfort template
   with the adapter's `_inputs.R`, `labels.csv`, `decisions.csv` (14
   decisions, both languages) and a note on the E8 sensitivity inserted
   before the appendix of `results.qmd` (fixed figures of
   `step2_e8_palmitate.csv`: 35.6% [34.1, 37.2] to 49.1% [47.5, 50.7]).
   `engih2018_exclude_outliers()`: the template acts on an outlier rule
   through `include`; this sets it for the flagged records, drops
   `outlier` and counts them in the audit log.
   - Choice I made, to confirm: `max_small_cells = 1` (no domain is
     disabled for small cells), by the same rule as answer 3 (the
     template's 0.5 has no source); the presentation standard still
     marks each small cell.
   - Tests: folder, note anchor, outlier exclusion by hand, the intake of
     the report equal to `run_chain()` on the last state of step 2 on the
     invented survey (1e-12), and both reports knit in both languages.
   - Suggests: ggplot2, knitr, rmarkdown, tinytable (only that knit
     test). `check()` 0/0/0; `test()` FAIL 0, PASS 816, SKIP 43; lint
     clean.

## After the answers on 5, 7 and max_small_cells (2026-11-21)

Adapter `ff797b0`: region values as their text (Este, Gran Santo
Domingo, Norte o Cibao, Sur), labels equal to it; "Quintil de gasto" /
"Expenditure quintile", per capita pending the documentation of the ONE
(`decisions.csv`, `data-raw/SOURCES.md`); `max_small_cells = 1`
confirmed. `check()` 0/0/0; `test()` FAIL 0, PASS 822, SKIP 43; lint
clean. Both reports rendered with Quarto (installed in the container)
on the invented survey, with `_inputs.R` patched in a scratch copy only:
`readiness.html` and `results.html` created, the E8 note and the
expenditure quintile in them.

## Exact next step

1. Maintainer: render both reports with the microdata (review point 1),
   and send what fails or reads wrong.
2. Next session (Opus): fix what the render shows; tick 12c.14c and
   12c.14; then 12c.15 (errata table from `acceptance-results/step2/`).

## Recommended model for the next session

**Opus.**

## Maintainer review points

1. **Render both reports with the microdata** (Spanish first):

   ```r
   Sys.setenv(ENGIH2018_DATA = "<folder of the microdata>")
   hcesfort.engih2018::engih2018_report("informe-engih2018", "es")
   # then, in a shell, from informe-engih2018/:
   #   quarto render readiness.qmd
   #   quarto render results.qmd
   ```

2. **The decisions table as the report prints it:**

   ```r
   hcesfort::read_decisions(system.file("report", "es", "decisions.csv",
                                        package = "hcesfort.engih2018"))
   ```

3. **The note of E8 against its source file:**

   ```r
   # in hcesfort.engih2018
   d <- read.csv("acceptance-results/step2/step2_e8_palmitate.csv")
   d[grepl("Energia plausible \\| vitamina_a", d$etapa) &
       d$medida == "pct_inadecuado", ]   # 35.62 -> 49.12
   ```
