# Handoff

- **Date:** 2026-11-15
- **Model:** Opus (12d.13).
- **Branch:** `claude/elegant-cori-26i111`, pushed; `main` holds
  everything up to `1626391`. Merge the commits below into `main` and
  confirm CI (R-CMD-check, test-coverage, lint) before 12d.14 starts.
- **Environment:** Quarto 1.11.9 and `tinytable` were present in this
  container. hcesfort itself was not installed, so the Quarto render test
  failed until `R CMD INSTALL .` was run: the render test uses the
  installed package. Install it at the start of a session.

## What was done

| Commit | Step |
|---|---|
| `535cd75` | P140 / V-D20: about 1% of households of `hces_example` keep a short food list without vehicles (26 households acquire none), drawn from a random stream of their own so every other household keeps its records; calibration test unchanged and passing; golden values regenerated from the independent script; maintainer answers P141 to P143 recorded (V-D23 to V-D25) |
| `82d2303` | 12d.13, part 1: machinery shared by both reports (appendix with headers and notes, `n` dropped from a table when constant, "No data" for a missing domain value in D8 and the results, thousands mark on axes, reference line per panel, zero line in every band of R3.4); terms of the results exhibits in both languages |
| `6b4915c` | 12d.13, part 2: `_scenarios.R`, builders of R3.1 to R4.1 and RT1 to RT3 |
| `4160b1a` | 12d.13, part 3: `_results.R` rewritten as builders of R0 to R2.2; `results.qmd` of both languages reduced to headings and `show_exhibit()` calls; tests K19 to K26 |
| last commit | roadmap, improvements (P144 to P149), handoff |

`devtools::test()`: 0 failures, 0 skips (3073 expectations, Quarto render
included). `devtools::check()` and `lintr::lint_package()`: see the last
section.

## Exact next step

**12d.14** (Sonnet): render both results reports and settle the wording
of `inst/report/{en,es}/terms.csv` and the headings of `results.qmd`
against section 8 of `docs/design-reports-v3.md`; P142 is resolved,
P145 and P147 are in scope; P146 if the maintainer accepts it. The code
is done: the Spanish report already runs the same code as the English
one.

## Open questions (for the maintainer)

1. **P148 (high): households with implausible energy reach the results.**
   R3.3 shows iron above the UL in 0.2% of households, all of them
   outside the plausible energy range that the readiness report flags.
   *Recommended:* a choice `energy_action` (`"keep"` or `"exclude"`, no
   default) in `_inputs.R`, recorded in `decisions.csv` and counted in
   the notes. It changes the choices of the template.
2. **P144 (medium): table R3.1 has 60 rows**, because cumulative
   scenarios restate the vehicles of the one before. *Recommended:* keep
   the table as entered, with a note.
3. **P146 (medium): cells with no household** ("No data", n = 0) are
   printed with the suppression reason. *Recommended:* their own note
   line, in 12d.14.

## Recommended model for the next session

**Sonnet** (12d.14 is wording). Fable only if P148 is answered "design
it".

## Maintainer review points

1. **The English results report:**

   ```r
   dir <- file.path(tempdir(), "results")
   use_report_template(dir, "en")
   quarto::quarto_render(file.path(dir, "results.qmd"))
   ```

2. **R1.4 has a small nonzero estimate** (V-D20), concentrated in the
   lowest quintile:

   ```r
   a <- hces_example$acquisitions
   buyers <- unique(a$household_id)
   none <- setdiff(buyers, a$household_id[a$food_code %in%
                                            hces_example$vehicles$food_code])
   length(none)  # 26
   table(hces_example$households$expenditure_group[
     match(none, hces_example$households$household_id)])
   ```

3. **The upper-level exhibit R3.3** (`figure/R3_3.png` in the folder of
   point 1): zinc in the zero sentence, iron, folate and vitamin A in the
   figure, and the four statements of the note (P148).
