# Handoff

- **Date:** 2026-11-12
- **Session:** design note of the corrections of the v0.1 review; no
  package code written. Model: see the trailer of the commit.
- **Branch:** `main`

## What was done

| Commit | Content |
|---|---|
| this commit | `docs/design-review-v0.1.md`: design of corrections 1, 2, 3, 8 and 10, correction 4 accepted, renames, ten decisions to approve (section 8). `docs/review-v0.1.md`: section 9 completed with the full text of Tang et al. 2021 (section 9.1), maintainer's answers recorded in section 11. `docs/improvements.md`: P85, P86. `docs/roadmap.md`: task 11b |

State: documentation only; `R/`, `tests/` and `data-raw/` are untouched since
`4260d5f`, where `devtools::check()` was 0/0/0. The check was not run again
in this session.

## Exact next step

1. The maintainer approves or amends the ten decisions of section 8 of
   `docs/design-review-v0.1.md`.
2. **Opus** implements roadmap items 11b.1 to 11b.10 in order, one commit
   each (at most 300 lines of code), following the design note. Correction
   2 (11b.2) enters the new columns in `data-raw/requirements.csv` with the
   statuses of the note's section 2, and updates `SOURCES.md` and the md5.
3. **Sonnet** does correction 9 (limits of the method, README) with task 12,
   citing only what section 9.1 of the review marks as verified.

## Open questions

- Section 8 of `docs/design-review-v0.1.md` (ten decisions, each with the
  recommended option).
- Sources still unopened: IOM 2000 (*Applications in Dietary Assessment*),
  the 2022 systematic review of Tang et al. (abstract only), the supplement
  of Tang et al. 2021 (Tables S1–S5: AFE parameters, outlier rule, H-AR
  values). The article supplied was the 2021 Malawi paper, not the review.

## Recommended model for the next session

**Opus 5.5**: implementation of an approved design. Back to Fable only if a
decision of section 8 is changed in a way that alters a contract not covered
by the note.

## Maintainer review points

1. **The quotations taken from Tang et al. 2021.** Section 9.1 of the review
   gives each with its page; the design relies on two of them (iron and the
   cut-point, zinc thresholds).

   ```r
   # In a clone of analisis_ENGIH2018 with full history:
   system("git show 2dad5b1:referencias/tang-2021-modeling-food-fortification.pdf > tang.pdf")
   tools::md5sum("tang.pdf")  # 4eec227b1dd276d1ee847035c2551ca6
   # Notes of Figures 1 and 2 (pp. 112-113); outliers p. 107;
   # limitations pp. 118-119.
   ```

2. **Iron was never reported by cut-point in the original.** The design
   drops the legacy argument on this answer.

   ```r
   # In analisis_ENGIH2018:
   r <- read.csv2("data/auditoria/cifras_control/riesgo_inadecuacion.csv")
   table(r$metodo[r$nutriente == "hierro_mg"])
   # Seen in this session: 100 rows at 10% and 100 at 18%, both
   # "Probabilidad"; no "Punto de corte" row for iron.
   ```

3. **What the new gate would say on the example today** (records used over
   records included, the figure `min_records_used` will be compared with).

   ```r
   library(hcesfort)
   ex <- hces_example
   g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
   n <- nutrient_registry(ex$nutrients)
   b <- unfortified_baseline(ex$composition, ex$enrichment, n)
   l <- link_composition(g, ex$crosswalk, b)
   sum(l$include & l$composition_status == "linked") / sum(l$include)
   ```
