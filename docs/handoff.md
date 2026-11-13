# Handoff

- **Date:** 2026-11-13
- **Model:** Fable (design session, task 12c.0).
- **Branch:** `main` (the design branch was fast-forwarded into `main`).

## What was done

`docs/design-reports-v2.md` (task 12c.0), from the approved
`docs/report-requirements-v1.md`:

- structure of the data readiness report and of the results report, and
  the files `use_report_template()` copies;
- contract of the label table (R2) and of the decisions table (DR7);
- contract changes: optional column `expenditure_lcu`, column
  `precision_status` of `flag_precision()`, `unmatched_foods()` as the
  work queue;
- eight new exported functions with their contracts;
- the automated checks of section C as test specifications (U1–U10,
  K1–K15);
- the commit plan 12c.1 to 12c.13.

`docs/roadmap.md` (steps of 12c), `docs/specification.md` (what is
planned, marked as not yet existing) and `docs/improvements.md` (P107 to
P111) are updated. No package code was written; the state of `R/`,
`inst/` and `tests/` is that of `dca4617`. `devtools::check()` was not
run: nothing it checks changed.

## Exact next step

The maintainer approved the design on 2026-11-13: decisions 1–6 and 8–12
as recommended; decision 7 amended (comparator kept as the template
choice `choices$comparator`, no package contract change, test K16). See
section 11 of `docs/design-reports-v2.md`.

**Opus** records these answers in `docs/improvements.md` (section
"Decisions") and starts 12c.1, then continues through the commit plan
(section 10) on `main`, one step per commit, `devtools::test()` green and
lint clean at each commit, `devtools::check()` before each push. Stop and
hand off (docs/model-routing.md) when the session quota passes 85%, after
12c.8 at the latest, or if a contract of sections 3 to 5 has to change
(then return to Fable).

## Open questions for the maintainer

1. The twelve decisions of section 11 of the design (P107).
2. From earlier handoffs, still pending: P99 and P103 of
   `docs/improvements.md`. The points of P103 about headlines no longer
   apply (R4 removes the headlines).

## Recommended model for the next session

**Opus 5.5** (12c.1 to 12c.8).

## Maintainer review points

1. **Every requirement has a place.** Read section 8 of the design
   (traceability) against `docs/report-requirements-v1.md`: P1–P5,
   DR1–DR8, R1–R14.
2. **The flag of DR5 (decision 5).** The difference between the unlinked
   share of a domain and that of the rest of the population, as the
   design proposes to compute it:

   ```r
   devtools::load_all()
   ex <- hces_example
   g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
   x <- as.data.frame(link_composition(
     g, ex$crosswalk, ex$composition, nutrient_registry(ex$nutrients)
   ))
   x <- x[x$include, ]
   grams <- ifelse(is.na(x$qty_g_d), 0, x$qty_g_d)
   h <- as.data.frame(ex$households)
   by_hh <- function(v) {
     s <- tapply(v, factor(x$household_id, h$household_id), sum)
     ifelse(is.na(s), 0, s)
   }
   h$den <- by_hh(grams)
   h$num <- by_hh(grams * (x$composition_status != "linked"))
   north <- h$region == "north"
   h$n1 <- h$num * north
   h$d1 <- h$den * north
   h$n0 <- h$num * !north
   h$d0 <- h$den * !north
   options(survey.lonely.psu = "adjust")
   des <- survey::svydesign(ids = ~psu, strata = ~stratum,
                            weights = ~weight, data = h, nest = TRUE)
   tot <- survey::svytotal(~n1 + d1 + n0 + d0, des)
   con <- survey::svycontrast(tot, quote(n1 / d1 - n0 / d0))
   con
   confint(con, df = survey::degf(des))
   # The two ratios, estimated separately, give the same difference:
   coef(survey::svyratio(~num, ~den, subset(des, region == "north"))) -
     coef(survey::svyratio(~num, ~den, subset(des, region != "north")))
   ```

   In this session: difference −0.0098, standard error 0.0132, interval
   −0.042 to 0.023 (not flagged).
3. **Cell sizes of the example (decision 11).** Every cell of
   `expenditure_group` has 8 households and its estimates rest on 7 or 8
   (column `n`), so `min_n = 10` would suppress them all and `min_n = 8`
   suppresses Q1 and Q3 only:

   ```r
   table(hcesfort::hces_example$households$expenditure_group)
   g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
   afe <- adult_equivalents(
     ex$members,
     reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
     weight_kg = c(female = 55, male = 65), pal = 1.76
   )
   use <- vehicle_coverage(g, ex$vehicles, afe, ex$households)
   design <- as_hces_design(ex$households, lonely_psu = "adjust")
   est <- estimate_households(design, use, "acquired",
                              by = "expenditure_group")
   unique(est[c("expenditure_group", "n", "n_missing")])
   ```
