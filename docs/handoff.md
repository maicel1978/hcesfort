# Handoff

- **Date:** 2026-11-19
- **Model:** Sonnet 5.5 (P188).
- **Branch:** `claude/funny-goldberg-jknbmy`, pushed.
- **Environment:** run `R CMD INSTALL .` at the start (the report tests use
  the installed package). The full `devtools::test()` runs in parallel,
  about 6 minutes: run it in the background, one at a time, and **do not
  edit `R/`, `tests/` or `inst/` while it runs**. A single report test file
  needs `NOT_CRAN=true` or it is skipped. `devtools::check()` needs the
  system tool `qpdf` (`apt-get install -y qpdf`), or it warns.

## What was done

- **P188:** the help of `estimate_households()` no longer says `df = "domain"`
  is what the original analysis did; it says the original used the full
  design (925 df) and that reproducing it needs `df = "design"`. Docs only
  (roxygen + `man/`); no test run needed.

- **12e.9:** `devtools::check()` 0 errors, 0 warnings, 0 notes (7.6 min,
  `NOT_CRAN=true`); `lintr::lint_package()` no lints. No code change.
  Task 12e is closed in the roadmap; A0 ticked (its decisions were
  approved on 2026-11-16).

## Exact next step

**A1 is done** (2026-11-16, by the maintainer): the stage tables are in
`analisis_ENGIH2018`, branch `claude/intelligent-cori-3aev98`, commit
`513ca4a`, under `data/auditoria/cifras_control/etapas/` (21 tables). The
md5 of the inputs are in `e00_entradas.csv`: `Registros_Cuestionario_B.xlsx`
`850ea1fb53c9a9c64102957a194e7426`, `Sociodemograficas_e_ingresos.xlsx`
`d9a58c8f325ec368bd72e5f40feebf53`. The original chain ran without errors
and reproduced the October control figures (`riesgo_inadecuacion.csv`).

Next, in this order (not before Thursday 2026-11-19, quota):

1. ~~P188~~ done 2026-11-19.
2. **A2** (Opus): companion repository `hcesfort.engih2018` and the adapter,
   from `docs/design-adapter-engih.md`. The session needs both repositories.

## Open questions

None.

**Answers of the maintainer (2026-11-16):** 1, tasks 12c and 12d: the
maintainer ticks them after reviewing the renders. 2, P188 in a short
Sonnet session before A2.

## Recommended model for the next session

**Opus** (A2).

## Maintainer review points

1. **The check is clean on your machine** (12e.9):

   ```r
   devtools::check()   # 0 errors, 0 warnings, 0 notes
   lintr::lint_package()
   ```

2. **The review points of 12e.5.8** stay valid: see the commit `c398f90`
   (`git show c398f90:docs/handoff.md`).

## Review of the all-or-nothing model (2026-11-17, Fable; a separate session)

This section does not change the next step above.

- **Done:** `docs/review-12e5-states.md`, from
  `docs/review-12e5-states-brief.md`: the five questions answered,
  findings S1.1 to S5.3, 12 mutations run (9 of 11 non-equivalent ones
  caught); items P217 to P220 in `docs/improvements.md`. No package code
  changed.
- **Result:** the expectation over states, the probabilities and the
  single use of the weight are right. Two findings for 12e.5.8: the
  total-intake path of `above_ul()` on the states table has no test
  (P217, failing input given), and average content is not a lower bound
  of all or nothing, on the fixture and on `hces_example` (P218): the
  help and the report note say "understated" where only the bound at
  compliance 1 holds. The column at compliance 1 that 12e.5.8 adds is
  that bound.
- **P213, recommendation (P219):** the log alone is not enough, because
  it is written after the memory is spent. An optional `max_states`
  argument with no limit by default, set visibly in the report template,
  plus the rows and MB in the log row `states`. Measured on the example:
  498,000 rows, 830 MB of peak memory against 128 MB under average
  content; about 3.7 GB at 9,000 households. The maintainer decides.

### Answers of the maintainer (2026-11-16)

1. P217: approved; add the tests in 12e.5.8.
2. P218: approved; correct `?above_ul` and the report note in 12e.5.8. Only
   the figure at compliance 1 is a guaranteed upper bound; average content
   and all or nothing are not ordered.
3. P219: approved as recommended (optional `max_states`, `NULL` by default
   meaning no limit, set visibly in the report template; rows and MB in the
   log row `states`), in 12e.5.8, before the acceptance A3 runs on the full
   survey. Building only the distinguishable states stays in task 12.

### Review points

1. **Average content above all or nothing on the example** (S4.1):

   ```r
   library(hcesfort)
   # i, u as in review point 2 of the section of 12e.5.6 and 12e.5.7
   ul <- function(sc, m) {
     x <- above_ul(apply_scenario(i, u, sc, compliance_model = m),
                   ref_requirements, min_coverage = 0.8,
                   min_records_used = 0.8)
     x <- x[x$scenario == "plus_sugar" & x$nutrient == "vitamin_a", ]
     w <- hces_example$households$weight[match(x$household_id,
       hces_example$households$household_id)]
     ok <- !is.na(x$above_ul_added)
     sum((x$above_ul_added * w)[ok]) / sum(w[ok])
   }
   sc1 <- hces_example$scenarios; sc1$compliance <- 1
   c(average = ul(hces_example$scenarios, "average_content"),
     aon = ul(hces_example$scenarios, "all_or_nothing"),
     full = ul(sc1, "average_content"))  # 0.000468, 0.000328, 0.000468
   ```

2. **The untested path** (P217): `above_ul_total` on the states table.

   ```r
   devtools::load_all()
   source("tests/testthat/helper-scenario.R")
   s <- aon(two_vehicles())
   ul <- data.frame(nutrient = "iron", unit = "mg", ul = 6, ul_unit = "mg",
                    ul_applies_to = "total")
   u <- above_ul(s, ul, min_coverage = 0.9, min_records_used = 0)
   u[u$scenario == "both", c("household_id", "amount_total",
                             "above_ul_total")]  # h1: 5.35, 0.5
   ```

3. **The cost of the states** (P219), peak memory of the three steps:

   ```r
   invisible(gc(reset = TRUE))
   s <- apply_scenario(i, u, hces_example$scenarios,
                       compliance_model = "all_or_nothing")
   x <- above_ul(s, ref_requirements, min_coverage = 0.8,
                 min_records_used = 0.8)
   nrow(s); format(object.size(s), units = "MB"); sum(gc()[, 6])  # max MB
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
