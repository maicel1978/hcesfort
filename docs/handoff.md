# Handoff

- **Date:** 2026-11-16
- **Model:** Opus 5.5 (12e.5.5).
- **Branch:** `claude/adoring-mccarthy-ki6i5p`, pushed.
- **Environment:** run `R CMD INSTALL .` at the start (the report tests use
  the installed package). The full `devtools::test()` runs in parallel,
  about 6 minutes: run it in the background, one at a time, and **do not
  edit `R/` or `tests/` while it runs**. A single report test file needs
  `NOT_CRAN=true` or it is skipped.

## What was done

See the commit message and `NEWS.md`.

- **12e.5.5** (P162, R3-D6): `missing_values()` in `R/missing-values.R`,
  the work queue of missing composition values by nutrient and food;
  log row `foods_without_value` in `apparent_intake()`; the `coverage`
  note of `inadequacy()` and `above_ul()` and the error of the gate name
  `missing_values()`; one paragraph in the three help pages (section 3.1
  of the design, with the example of finding 8). Readiness report: Table
  **D3.1** after D3 (numbered so that D4 to D10 keep their ids; terms en
  and es); two snapshot blocks accepted (the new table only). No figure
  changes. Fixture of finding 8 in `tests/testthat/helper-missing-values.R`.
- Self-review items P211 and P212.

## Exact next step

**12e.5.6** (Opus), from `docs/design-12e5.md`, section 4 (P163, R3-D7):
`compliance_model = "all_or_nothing"`, the states in `apply_scenario()`.
New code in `R/scenario-states.R`. Then 12e.5.7 and 12e.5.8 (Opus); in
12e.5.8, the coverage exhibit with both coverages, the column at
compliance 1 (rule of the maintainer: no report leaves the project
without it) and P210. `devtools::check()` and `lintr::lint_package()` once
at the end of task 12e.

## Open questions

None.

## Recommended model for the next session

**Opus, high effort** (12e.5.6).

## Maintainer review points

1. **The case of finding 8** (one row: vitamin A, the liver, 10 g of
   410 g), and the note that points to the list:

   ```r
   library(hcesfort)
   a <- data.frame(record_id = 1:6, household_id = rep(1:3, each = 2),
                   food_code = rep(c("rice", "liver"), 3),
                   quantity = rep(c(400, 10), 3), unit = "g",
                   section = "diary", period_days = 1, include = TRUE)
   h <- data.frame(household_id = 1:3, weight = 1, stratum = "s", psu = 1:3)
   cw <- data.frame(food_code = c("rice", "liver"),
                    composition_id = c("R1", "L1"), match_type = "exact",
                    validated = TRUE, edible_portion = 1)
   comp <- data.frame(composition_id = c("R1", "L1"),
                      vitamin_a_ug_rae = c(0, NA),
                      basis = "per_100g_edible", food_state = "raw",
                      source = "invented")
   f <- data.frame(unit = "g", factor = 1, factor_type = "mass_g",
                   source = "invented")
   x <- link_composition(convert_units(a, f, priority = "food"), cw, comp,
                         nutrient_registry(c(vitamin_a = "ug_rae")))
   missing_values(x, h)
   ```

2. **The queue on the example** (folate of the biscuit, 0.5% of the
   grams), and the row of the log:

   ```r
   g <- convert_units(hces_example$acquisitions, hces_example$unit_factors,
                      priority = "food")
   content <- link_composition(g, hces_example$crosswalk,
                               hces_example$composition,
                               nutrient_registry(hces_example$nutrients))
   missing_values(content, hces_example$households)
   afe <- adult_equivalents(hces_example$members,
     reference_energy("female", 25, 55, pal = 1.76),
     c(female = 55, male = 65), 1.76, infant_food_share = 1,
     pregnancy_kcal = 0, lactation_kcal = 0)
   l <- audit_log(apparent_intake(content, afe, hces_example$households))
   l[l$cause == "foods_without_value", ]
   ```

3. **Table D3.1 in the readiness report** (wording en and es):

   ```r
   dir <- tempfile()
   use_report_template(dir, lang = "es")
   system2("quarto", c("render", file.path(dir, "readiness.qmd")))
   # open readiness.html in `dir`: section 3, Cuadro D3.1
   ```

## Design of the ENGIH adapter (2026-11-16, Fable; a separate session)

This section does not change the next step above.

- **Done:** `docs/design-adapter-engih.md` (mapping, A1 export, step 1
  options and tolerances, step 2 with expected directions, download,
  companion repository, external anchor); items P188 to P200; errors E27
  to E29 and amendments in `docs/analysis-map.md`, section 10; A0 in the
  roadmap. In `analisis_ENGIH2018`, branch `claude/intelligent-cori-3aev98`:
  `scripts/exportar_cifras_etapas.R` (run only on invented stand-ins).
- **Waiting for the maintainer:** the eight decisions of section 9 of the
  design; A1 (decision 2), which needs the microdata and nothing from the
  package.
- **Next for the adapter, after approval and after 12e.5.3:** A2 in the
  companion repository (Opus), from sections 1, 6 and 7 of the design.
  P188 (one sentence of help, Sonnet) before A3.
- **Network:** `www.bancentral.gov.do` is outside the environment; the
  page of the microdata was not opened.

Review points of the design:

1. **Every interval of the control figures has 925 degrees of freedom**
   (in `analisis_ENGIH2018`):

   ```r
   r <- read.csv2("data/auditoria/cifras_control/riesgo_inadecuacion.csv",
                  dec = ".")
   t <- r$semiamplitud_ic / (r$cv * r$pct_inadecuado)
   range(t); qt(0.975, 925)
   ```

2. **The 37 vehicle foods without a validated match (E27)**: the table of
   section 0, finding 3. In `analisis_ENGIH2018`:

   ```r
   x <- readxl::read_excel("data/raw/crosswalk_tablas_composicion.xlsx",
                           sheet = "Cuest. B Sec 3A")
   d <- iconv(tolower(x$descripcion_engih), to = "ASCII//TRANSLIT")
   pastry <- grepl("^bizcocho|^pan dulce|^donas?|^masitas", d)
   tapply(x$freq_registros[pastry], as.logical(x$validado[pastry]), sum)
   ```

3. **The expected directions of step 2** (design, section 5): read the
   column "A surprise is" before any corrected figure exists; say now if
   one of them is wrong.


### Answers of the maintainer to section 9 of `docs/design-adapter-engih.md` (2026-11-16)

Approved, all as recommended, except decision 2:

1. The companion repository is an R package. Approved.
2. A1 is run now by the maintainer. **The branch of the export script is not
   merged into `main` of `analisis_ENGIH2018`**: that repository is the
   delivered consultancy work and stays as delivered. The maintainer runs the
   script from the branch `claude/intelligent-cori-3aev98` and pushes the
   aggregated tables of `etapas/` to that branch. The script moves to the
   companion repository when it is created.
3. Download addresses: the maintainer copies them once into the registry.
4. `fortifiable` is `FALSE` only for own production (`QUIEN_PAGO1` = 2).
5. `PORCENTAJE_HOGAR` is used in the corrected analysis (step 2), old and new
   figures in `NEWS.md`.
6. Non-food codes are dropped by the adapter, with a count.
7. The original outlier rule is kept; a sensitivity run is reported.
8. Vehicle coverage in the corrected analysis is `acquired`; both figures in
   `NEWS.md`.

Record these in `docs/improvements.md` with the first commit of the next step
(done 2026-11-16: A-D1 to A-D8).

## Review of 12e.1 to 12e.4 (2026-11-16, Fable; a separate session)

This section does not change the next step above.

- **Done:** `docs/review-12e.md`, from `docs/review-12e-brief.md`: the
  five questions answered, findings V1.1 to V4.4, 17 mutations run; items
  P201 to P206 in `docs/improvements.md`. No package code changed.
- **Result:** the figures of the chain and of the estimators are
  unchanged outside the approved rules; no blocker for A3; no shared
  state in the parallel tests. Two major findings: V1.1 (P201) and V3.1.
- **For the session that takes them (Opus):** read sections "12e.1"
  (V1.1) and "12e.4" (V4.2, V4.3) of the review; P201 before A2, P204
  before A3. **Both done 2026-11-16** (`96c241e`).

### Questions for the maintainer

1. **The bound at compliance 1 in the results report** (V3.1). R2-D4 put
   it in 12e.3; the session left a sentence under the exhibit and moved
   the figure to P179 (task 12). Recommended: the column at compliance 1
   is added in 12e.5.8, when the exhibit is touched for the all-or-nothing
   model, and in any case before a report leaves the project; the
   sensitivity by days (V3.2, P182) stays in task 12. Why: the report
   still prints 0.59% as its safety figure where the bound is 19.7%.
2. **P201 (stacked estimate tables) now or with the adapter?**
   Recommended: one small Opus commit before 12e.5.1 continues, with P204
   in the same session. Why: about ten lines and a test; the adapter (A2)
   will stack estimates, and A3 runs with `df = "design"`.

### Answers of the maintainer (2026-11-16)

1. Approved as recommended. The column at compliance 1 enters the results
   report in 12e.5.8. Rule: no report leaves the project without it.
   P182 stays in task 12.
2. Approved as recommended. P201 and P204 are fixed now, in one Opus
   session before 12e.5.1 (see "Exact next step").

### Review points

1. **Stacked estimates are refused** (V1.1):

   ```r
   library(hcesfort)
   example(flag_presentation)  # builds design and use
   ea <- estimate_households(design, use, "acquired",
                             ci_method = "korn_graubard")
   use$acq2 <- use$acquired
   eb <- estimate_households(design, use, "acq2",
                             ci_method = "korn_graubard")
   flag_presentation(dplyr::bind_rows(ea, eb))  # hcesfort_error_key
   ```

2. **A domain inside one PSU under `df = "design"`** has an interval of
   width zero and no note (V4.2):

   ```r
   h <- hces_example$households
   d <- as_hces_design(h, lonely_psu = "adjust")
   one <- h$psu == h$psu[[1]] & h$stratum == h$stratum[[1]]
   x <- hcesfort:::new_hces_tbl(
     data.frame(household_id = h$household_id,
                y = ifelse(one, seq_along(one) / 10, NA)),
     "hces_intake", key = "household_id")
   estimate_households(d, x, "y", statistic = "mean", df = "design")[
     c("estimate", "se", "ci_low", "ci_high", "df", "interval_note")]
   ```

3. **The effective size against `survey`** (question 3 of the brief):

   ```r
   h <- data.frame(household_id = 1:200, weight = 1, stratum = 1,
                   psu = rep(1:10, each = 20))
   h$p <- rep(seq(0.30, 0.70, length.out = 10), each = 20)
   x <- hcesfort:::new_hces_tbl(h[c("household_id", "p")],
                                "hces_inadequacy", key = "household_id")
   e <- estimate_households(as_hces_design(h, "adjust"), x, "p")
   s <- survey::svydesign(ids = ~psu, strata = ~stratum,
                          weights = ~weight, data = h)
   m <- survey::svymean(~p, s, deff = "replace")
   c(e$n_effective, 200 / survey::deff(m) * 199 / 200)  # 9 and 9
   ```
