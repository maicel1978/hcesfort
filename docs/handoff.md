# Handoff

- **Date:** 2026-11-16
- **Model:** Opus 5.5 (step 12e.4).
- **Branch:** `claude/docs-routing-handoff-9dlnd0`, pushed.
- **Environment:** run `R CMD INSTALL .` at the start (the report tests use
  the installed package). The full `devtools::test()` now runs in
  parallel (`Config/testthat/parallel: true`), about 5.5 minutes here:
  run it in the background, one at a time.

## What was done

12e.4 (P164 effective size under R2-D6, P165 to P168, P172, P183), see the
commit messages and `NEWS.md`:

- Estimators: a cell without variation has no interval (`no_variation`);
  a cell without degrees of freedom has no interval and no warning
  (`no_degrees_of_freedom`); new columns `interval_note` and
  `n_effective` (`n` over the design effect, from the variance of the
  values); `flag_precision()` decides `exact` on the values;
  `flag_presentation()` uses `n_effective`; `survey.adjust.domain.lonely`
  fixed at `FALSE` and logged; note `psu_in_several_strata`.
- Validators: `level_mg_kg <= 1e6`; mass per 100 g at most 100 g;
  `age_months` against `age_years`. The optional fixture's adult month
  (30) became 450, consistent with the age (it is still ignored).
- `apparent_intake()`: flagged row `zero_intake`.
- Report: note `usual_intake` under the risk exhibits (en, es); departure
  S2 rewritten. Golden values regenerated (iron `n_effective`; the fixture
  iron estimate now suppressed); report snapshots accepted (zinc cells of
  zero prevalence lose their interval; the new note).
- New items P184 to P187 (self-review).
- Parallel tests kept: `Config/testthat/parallel: true` in `DESCRIPTION`.
  Serial and parallel runs of the same tree gave the same counts (52
  files, 529 tests, 3415 expectations, 0 failures, 0 warnings, 0 skips)
  in 10 min 45 s and 5 min 29 s.

## Not done

- **`surveytable` anchor (R2-D7):** the install was refused again by the
  session's permission classifier. As decided on 2026-11-15, the test is
  dropped; recorded under R2-D7 in `docs/improvements.md`.

## Exact next step

**First, P201 and P204** (one small session, Opus, high effort), as
answered by the maintainer under "Review of 12e.1 to 12e.4" below: read
sections "12e.1" (V1.1) and "12e.4" (V4.2, V4.3) of `docs/review-12e.md`
and items P201 and P204 of `docs/improvements.md`. Each fix comes with a
test that fails before it. Golden values and report snapshots must not
change; if one does, stop and report it.

**Then 12e.5.1** (`infant_food_share`, `milk_energy_cost` in
`adult_equivalents()`), from `docs/design-12e5.md` (read its sections for
12e.5.1 and decisions R3-D1 to R3-D9 in `docs/improvements.md`). Then
12e.5.2 to 12e.5.8 (Opus). `devtools::check()` and `lintr::lint_package()`
once at the end of task 12e.

## Open questions

None.

## Recommended model for the next session

**Opus, high effort** (P201 and P204, then 12e.5.1).

## Maintainer review points

1. **The effective size of the iron estimate** (`n` over the design effect,
   no longer the number of households):

   ```r
   library(hcesfort)
   example(flag_presentation)  # builds the chain objects
   e <- estimate_households(design, use, "acquired", by = "region",
                            ci_method = "korn_graubard")
   e[c("region", "estimate", "se", "n", "n_effective", "interval_note")]
   ```

2. **A cell without degrees of freedom** has no interval and no warning:

   ```r
   d <- as_hces_design(hces_example$households, lonely_psu = "adjust")
   h <- hces_example$households
   one <- h$psu == h$psu[[1]] & h$stratum == h$stratum[[1]]
   x <- hcesfort:::new_hces_tbl(
     data.frame(household_id = h$household_id,
                y = ifelse(one, seq_along(one), NA)),
     "hces_intake", key = "household_id")
   estimate_households(d, x, "y", statistic = "mean")
   ```

3. **The new report note** reads well in both languages:

   ```r
   read.csv(system.file("report/es/terms.csv", package = "hcesfort"))[
     c(159, 217), "label"]
   ```

## Design of the ENGIH adapter (2026-11-16, Fable; a separate session)

This section does not change the next step above (12e.5.1, Opus).

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

Record these in `docs/improvements.md` with the first commit of the next step.

## Review of 12e.1 to 12e.4 (2026-11-16, Fable; a separate session)

This section does not change the next step above (12e.5.1, Opus).

- **Done:** `docs/review-12e.md`, from `docs/review-12e-brief.md`: the
  five questions answered, findings V1.1 to V4.4, 17 mutations run; items
  P201 to P206 in `docs/improvements.md`. No package code changed.
- **Result:** the figures of the chain and of the estimators are
  unchanged outside the approved rules; no blocker for A3; no shared
  state in the parallel tests. Two major findings: V1.1 (P201) and V3.1.
- **For the session that takes them (Opus):** read sections "12e.1"
  (V1.1) and "12e.4" (V4.2, V4.3) of the review; P201 before A2, P204
  before A3.

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
