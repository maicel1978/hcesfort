# Handoff

- **Date:** 2026-11-15
- **Model:** Opus (CI fix and step 12d.12).
- **Branch:** `claude/modest-bohr-0hyk4h`. `18be1f1` is merged into
  `main` (CI green: R-CMD-check, test-coverage, lint). Merge the later
  commits into `main` and confirm CI before 12d.13 is closed.
- **Environment:** the setup script of `hcesfort` now installs
  `tinytable` and Quarto 1.11.9 (from PyPI; startup does not fail if pip
  fails). Unproven until a fresh container is built: check
  `quarto --version` at the start. If it is missing,
  `pip install --break-system-packages quarto-cli==1.11.9`.

## What was done

| Commit | Step |
|---|---|
| `18be1f1` | CI fix: tables written with `knitr::knit_print()` (`emit_table()`), so the inline script of tinytable stays in a raw HTML block (it was the `<code>` of K15); test without Quarto; `.lintr` exclusions for three test files; `skip_if_no_knit()` in `helper-report.R` |
| `2486d6d` | 12d.12: Spanish wording against section 8 ("vincular" throughout, "resto de los hogares", "ingesta aparente inadecuada", "rango plausible", lists with "y"/"and"); maintainer answers V-D20 to V-D22; P126, P140 resolved; P141, P142 |
| `38c926f` | D9 draws up to the upper bound; households above it counted in the note (V-D21); P143 |
| last commit | roadmap, handoff |

`devtools::test()`: 0 failures, 0 skips (Quarto installed in the
session, so the render test ran). `devtools::check()` after `38c926f`:
0 errors, 0 warnings, 0 notes (9.2 minutes). `lintr::lint_package()`:
clean.

## Exact next step

**12d.13** (Opus): results report in English, builders R0 to RT3 in
`_results.R` (K19 to K26). Its first commit applies P140 / V-D20: about
1% of households of `hces_example` with a short food list and no staple
purchases (drawn before the food loop in `data-raw/hces_example.R`);
re-check the calibration test; regenerate the golden values from the
independent script. Fold in P141 (label of a missing domain value) if it
fits.

## Open questions

None.

## Recommended model for the next session

**Opus** (12d.13 is implementation). This session stops past half of
its context.

## Maintainer review points

1. **The Spanish readiness report after the wording pass:**

   ```r
   dir <- file.path(tempdir(), "preparacion")
   use_report_template(dir, "es")
   quarto::quarto_render(file.path(dir, "readiness.qmd"))
   ```

2. **D9 with the long tail hidden** (`figure/D9.png` in the folder of
   point 1, and the note "9 hogares por encima de 6,000 kcal, no
   representados").

3. **No raw script outside HTML blocks** (the cause of the red CI):

   ```r
   quarto::quarto_render(file.path(dir, "results.qmd"))
   any(grepl("<code>", readLines(file.path(dir, "results.html"))))  # FALSE
   ```
