# Handoff

- **Date:** 2026-11-14
- **Model:** Opus (steps 12d.1 and 12d.2).
- **Branch:** `claude/clever-cray-7hq3uw` (the session's development
  branch; `main` is not updated by this session). Merge it into `main`
  before the next session, or continue on it.
- **Environment:** the session moved from Default to the `hcesfort`
  environment (network only) to reach `www.cdc.gov`. Open the next session
  in `hcesfort`.

## What was done

| Commit | Step |
|---|---|
| `3785810` | 12d.1: maintainer's answers to the design v3 recorded (`docs/improvements.md`, "Decisions (2026-11-14, reports v3)"; status line of the design); every IOM page citation in `data-raw/` re-read on the scanned page and corrected (P124); md5 and `data/*.rda` rebuilt; no value changed |
| `665b9b6` | 12d.2: `ref_presentation_standard` (C1), the seven NCHS thresholds read in Parker et al. 2017 (Table, p. 2; definitions pp. 3–4; PDF md5 `2ae6002af069bb55f555e2e271f1908d`) |
| last commit | Handoff |

P124 in detail: table of corrected pages in `data-raw/SOURCES.md`, section
"Page citations re-read". Most IOM 2001 and 1998 citations were one page
too high; the same shift was found and corrected in IOM 2000 (vitamin E)
and IOM 2011 (vitamin D, pending row). IOM 2000b and the folate UL pages
were right.

`devtools::check()` after 12d.2: 0 errors, 0 warnings, 0 notes.
`lintr::lint_package()`: no lints (package installed first). Tests: no
failures; one skip (Quarto not installed).

## Exact next step

**12d.3** (Opus): `estimate_households(ci_method = "korn_graubard")` and
the column `ci_method` in every `hces_estimate` (C2 of
`docs/design-reports-v3.md`, section 3.2; tests U11–U12 of section 3.4;
P128 for the documentation of `"beta"` against `"korn_graubard"`).
Condition V-D2 of the maintainer: golden tests against
`survey::svyciprop(method = "beta")` (where the cap does not bind),
`stats::binom.test()` (equal weights, including 0 and `n` events) and the
twelve published rows of Tables I and II of the NCHS report (pp. 8–9),
typed into the test with their page. The PDF is at
`https://www.cdc.gov/nchs/data/series/sr_02/sr02_175.pdf` (reachable from
the `hcesfort` environment); `pdftotext` is installed. Then 12d.4 onwards.

## Open questions

None for the maintainer. P126: add `"tinytable"` to the `pkgs` vector of
the setup script of the `hcesfort` environment (Settings), or install it
by hand at the start of the session until then (needed from 12d.10):

```r
install.packages("tinytable")
```

## Recommended model for the next session

**Opus** (12d.3 onwards). This session stops at more than half of its
context. Sonnet for the wording pass of 12d.14.

## Maintainer review points

1. **Two corrected pages, on the scanned image.** The vitamin A UL for
   women 19–50 years (p. 142, not 143) and the iron EAR for women 19–30
   years (p. 344, not 345):

   ```r
   browseURL("https://nap.nationalacademies.org/books/10026/gif/142.gif")
   browseURL("https://nap.nationalacademies.org/books/10026/gif/344.gif")
   ```

2. **No value changed** in the reference tables of 12d.1, only their
   locations (run from the package root):

   ```r
   old <- new.env()
   system("git show 7cc78a3:data/ref_requirements.rda > /tmp/old.rda")
   load("/tmp/old.rda", old)
   keep <- setdiff(names(hcesfort::ref_requirements), "location")
   identical(old$ref_requirements[keep], hcesfort::ref_requirements[keep])
   ```

3. **The NCHS thresholds against the Table on p. 2 of the report:**

   ```r
   hcesfort::ref_presentation_standard[c("criterion", "value")]
   browseURL("https://www.cdc.gov/nchs/data/series/sr_02/sr02_175.pdf")
   ```
