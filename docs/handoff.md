# Handoff

- **Date:** 2026-11-14
- **Model:** Fable (design, task 12d.0).
- **Branch:** `claude/loving-bell-599967` (the session's development
  branch; `main` is not updated by this session). Merge it into `main`
  before the next session, or continue on it.

## What was done

| Commit | Step |
|---|---|
| last commit of the branch | 12d.0: `docs/design-reports-v3.md` written; roadmap split into 12d.1–12d.16; items P124–P129 in `docs/improvements.md` |

No package code changed. Sources opened and read in this session:

- Parker et al. 2017, Vital Health Stat 2(175) (NCHS presentation
  standard): thresholds on p. 2, definitions on pp. 3–4, flow chart on
  p. 7. Its twelve published examples (pp. 8–9) were recomputed by hand.
- IOM 1998 (folate UL: pp. 13, 273, 280, 282) and IOM 2001 (vitamin A
  UL: pp. 125, 126, 142, the last two on the scanned pages).

`devtools::check()`: 0 errors, 0 warnings, 0 notes, with `ggplot2`
installed, so the knit tests of the template ran.
`lintr::lint_package()`: no lints. It needs the package installed
(`devtools::install(quick = TRUE)`); otherwise `object_usage_linter`
reports every internal function as undefined.

## Exact next step

1. **The maintainer** answers the sixteen decisions of section 13 of
   `docs/design-reports-v3.md` (each has a recommended option).
2. **Opus** records the answers in `docs/improvements.md` (section
   "Decisions (reports v3)") and in the status line of the design, then
   starts at 12d.1 and follows section 12 of the design, one step per
   commit.
3. An answer that changes a contract of sections 3 to 5 of the design
   beyond the alternatives listed goes back to Fable.

## Open questions

The sixteen decisions (P125). The ones that shape the most work:
1 (table package), 2 (Korn-Graubard interval with the NCHS cap),
5 (opening of the results report), 6 (two-panel effect figure),
7 and 8 (the example).

## Answers of the maintainer (2026-11-14, design v3)

All sixteen questions of section 13 of `docs/design-reports-v3.md` as recommended, with these conditions:

1. **Tables:** `tinytable`, in Suggests and used only by the template. Check that a Word export of a rendered report through Quarto keeps the tables readable.
2. **Korn-Graubard:** the own formula is accepted only with its tests against `survey`, `binom.test()` and the published NCHS examples (pp. 8–9), to the stated tolerance. It is a golden test.
5. **Opening of the results report:** the findings slot for the analyst is omitted from the render when the analyst writes nothing. No placeholder text is ever printed (v1 R3).
8. **Example:** add zinc, which the ENGIH 2018 analysis included. Five nutrients: iron, zinc, folate, vitamin A and energy. Zinc levels and requirements need a verified source, or `# SOURCE PENDING`.
13. **UL sentence:** as recommended; the sentence names the upper limit as the upper limit of the 95% interval and gives the interval method.

Record these in `docs/improvements.md` with the first commit of 12d.1.

## Environment

- A cloud environment named `hcesfort` was created for this repository
  (the hosts of the Default environment plus `www.cdc.gov` and
  `stacks.cdc.gov`, needed to read the NCHS report). Choose it when
  opening the next session. Its setup script is the one of the Default
  environment and has not yet started a fresh container.
- `ggplot2` is not in that script (P126): without it the knit tests of
  the report template are skipped. Install it by hand at the start of the
  session until the script has it:

  ```r
  install.packages(c("ggplot2", "tinytable"))
  ```

## Recommended model for the next session

**Opus**, after the maintainer's answers (12d.1 onwards). Sonnet for the
wording pass of 12d.14.

## Maintainer review points

1. **The NCHS interval, by hand, against a published row** (Parker et al.
   2017, Table II, p. 9: Hispanic men, published limits 42.0 and 62.3;
   non-Hispanic black women, where the cap at `n` acts, 18.8 and 32.2):

   ```r
   kg <- function(p, se, n, df, cap = TRUE) {
     ne <- p * (1 - p) / se^2 * (qt(0.025, n - 1) / qt(0.025, df))^2
     if (cap) ne <- min(ne, n)
     100 * c(qbeta(0.025, ne * p, ne * (1 - p) + 1),
             qbeta(0.975, ne * p + 1, ne * (1 - p)))
   }
   kg(0.522, 0.0449, 169, 11)               # 42.0 62.3
   kg(0.251, 0.0283, 175, 12)               # 18.9 32.2 (published 18.8 32.2)
   kg(0.251, 0.0283, 175, 12, cap = FALSE)  # 19.1 31.8: survey's "beta"
   ```

2. **The IOM pages** (P124): the vitamin A statements are on pp. 126 and
   142, not 127 and 143 as `data-raw/SOURCES.md` says.

   ```r
   browseURL("https://nap.nationalacademies.org/books/10026/gif/126.gif")
   browseURL("https://nap.nationalacademies.org/books/10026/gif/142.gif")
   browseURL("https://nap.nationalacademies.org/books/6015/gif/280.gif")
   ```

3. **The table package** (decision 1), on any small table:

   ```r
   d <- data.frame(Nutrient = c("Iron", "Folate"), `%` = c("62.1", "—"),
                   check.names = FALSE)
   x <- tinytable::tt(d, caption = "Table R2.1. Title",
                      notes = list("n = 1,962 households.",
                                   "—: suppressed (sample size)."))
   tinytable::save_tt(tinytable::theme_html(x, portable = TRUE),
                      file.path(tempdir(), "t.html"), overwrite = TRUE)
   browseURL(file.path(tempdir(), "t.html"))
   ```
