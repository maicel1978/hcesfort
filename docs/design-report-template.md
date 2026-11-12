# Design: country results report template

- **Date:** 2026-11-12. **Status:** design, waiting for approval
  (section 8). No package code is written by this note.
- **Aim.** A Quarto template for the results report of one country, laid
  out by the questions a decision-maker asks, not as introduction, methods,
  results and discussion. The package creates it with one function
  (working name `use_report_template()`); a vignette only explains its use.

## 1. Sources opened in this session

| Source | What was read | Where |
|---|---|---|
| Six strategic questions | Section 3 of `docs/vision-y-arquitectura.md` | `analisis_ENGIH2018`, `baea50c^` |
| Decision dashboard | `reports/dashboard_decision_fortificacion.qmd`: coverage, scenarios, "decisions that condition the interpretation", what it allows and does not allow to decide | `analisis_ENGIH2018`, `0a56f55^` |
| Validated presentation | `reports/presentacion_sistema_evaluacion.qmd`: research questions, order of results, annexes | `analisis_ENGIH2018`, `main` |
| Malawi article | Tang et al. 2022, *Ann. N.Y. Acad. Sci.* 1508(1):105–122, doi:10.1111/nyas.14697. Main text only; its online supplement (Tables S1–S5, Figures S1–S7) was **not** opened | `referencias/tang-2021-modeling-food-fortification.pdf` at `2dad5b1` |
| STROBE-nut | Lachat et al. 2016, *PLoS Med.* 13(6):e1002036, doi:10.1371/journal.pmed.1002036. Table 1 and the item headings | PMC4896435, full text through the NCBI BioC service |
| FACT | Aaron et al. 2017, *J. Nutr.* 147(5):984S–994S, doi:10.3945/jn.116.245753: the article that presents the toolkit and its coverage indicators | PMC5404213, same service |

**Not opened: the FACT manual itself** (GAIN and Oxford Policy Management,
2019). `www.gainhealth.org` is outside the allowed network of this session.
Everything said below about the FACT comes from Aaron et al. 2017 and must
be checked against the manual before the template cites the manual
(decision D10).

## 2. Principles of the template

1. **One section, one decision question.** The section title is the
   question; the first line under it is the headline, a sentence that
   states the finding with its figure and confidence interval.
2. **One exhibit per section** (figure or table) that carries the
   headline, with the interval drawn or printed, then at most three
   sentences of reading. Everything else goes to the annexes.
3. **Every figure names its source function.** Each chunk calls an
   exported function of the package; the caption note says which. No
   number is typed by hand: headlines use inline R.
4. **Headlines are guarded.** A headline is a claim ("the largest risk is
   X"). The chunk that builds it stops with a clear message when the data
   no longer support the sentence, as the validated presentation did
   (`stop("La conclusión supone que …")`). A report that renders is a
   report whose headlines hold.
5. **Survey-agnostic.** No country, survey, vehicle or nutrient in the
   template body. They come from the YAML `params` and from the tables the
   analyst supplies. It renders out of the box on `hces_example`.
6. **No hidden thresholds.** Precision rule, coverage minimum, iron
   bioavailability and reference scenario are `params`, printed in annex F.
7. **Equity is exploratory.** The domain comparisons are described as
   exploratory, with the number of comparisons made. The phrase used in
   the presentation about a hypothesis set before the analysis is not
   carried over, in the template or in its Spanish version.
8. **"Apparent" and "potential" everywhere.** Intake is apparent
   (household acquisition per adult female equivalent), contributions are
   potential (they assume the compliance stated in the scenario table).
   Tang et al. use both words throughout, and the presentation's validity
   conditions 3 and 4 require them.
9. **No plotting function is exported.** The `ggplot2` code lives in the
   template, short and editable (`CLAUDE.md`, scope).

## 3. Structure, section by section

Order: first the need (1–3), then the instrument (4–5), then the options
(6), then the limits (7). It follows the order of results of the validated
presentation, with the six strategic questions as section titles.

### Front page: the answer in one page

- Title states the method (STROBE-nut nut-1): "apparent micronutrient
  intake from the <survey> household consumption and expenditure survey".
- One line per question below: the six headlines, generated, each with its
  interval.
- A reading box of three lines: what apparent intake is, what it is not
  (not deficiency, not individual intake), and that scenario gains are
  potential.
- A verdict line on fitness for use, linked to section 7 (decision D2).

### Q1. Which micronutrients have the greatest risk of inadequate intake?

| | |
|---|---|
| Headline | "With <reference scenario>, the greatest risk is <nutrient>: x% of households (95% CI a–b)." |
| Exhibit | Dot and interval per nutrient, ordered; the unfortified baseline shown beside the reference scenario |
| Functions | `unfortified_baseline()` → `apply_scenario()` → `inadequacy()` → `estimate_households(statistic = "proportion")` → `flag_precision()` |
| Status | **Available.** The template needs the `reference_scenario` param (D3) |
| Notes | Iron by the probability approach, with the bioavailability in the caption. Nutrients that fail `min_coverage` appear as "not estimated", never dropped |

### Q2. Which population groups are most at risk? (exploratory)

| | |
|---|---|
| Headline | "The risk of <nutrient> ranges from x% to y% across <domain>; n of k domains have insufficient precision." |
| Exhibit | Dot and interval by domain (area, region, expenditure quintile), one panel per priority nutrient; imprecise estimates marked |
| Functions | `estimate_households(by = <domain>)`, `flag_precision(min_n, max_half_width)` |
| Status | **Available** for any domain column of `households`. Gaps: `hces_example` has no expenditure quintile (G6); no test between domains (G3) |
| Notes | A dot plot with intervals replaces the map of the presentation: a map cannot show the interval, and geometry is country data (the specification keeps maps out). The annex of the presentation showed that the territorial pattern followed recorded energy, so the same figure for energy sits in annex D |

### Q3. Which foods supply each key micronutrient?

| | |
|---|---|
| Headline | "<Food group> supplies x% (95% CI a–b) of the <nutrient> of the diet before fortification." |
| Exhibit | Stacked bars or a table: share of each food group in the total of each nutrient |
| Functions | `food_group_shares()`, **which does not exist** (roadmap v0.2) |
| Status | **Missing (G2).** The section cannot be produced today |
| Notes | **Computed on the unfortified baseline only** (`unfortified_baseline()` output), never on the composition as linked: this is error E1 of the original, where enriched rice, pasta and bread entered with their enrichment and the cereal shares of folate and iron were overstated. The function must refuse a table that has not passed through `unfortified_baseline()`. The caption says "before fortification"; the share under a scenario is a separate, optional exhibit of Q6 |

### Q4. How far does each fortification vehicle reach?

| | |
|---|---|
| Headline | "<Vehicles> reach x% of households or more; <vehicle>, y%." |
| Exhibit | Dot and interval of the percentage of households that acquire each vehicle, with the median grams per AFE and day among those who acquire it |
| Functions | `vehicle_coverage()` → `estimate_households(value = "acquired")` for coverage; `estimate_households(value = "qty_vehicle_g_d", statistic = "median", domain = "acquired")` for the quantity |
| Status | **Available** |
| Notes | The label is "acquires the vehicle", the only coverage stage an HCES observes (section 5.3). The caption states that the quantity is among consumers only (STROBE-nut nut-14). A vehicle defined as a product and as a group (flour, flour and its products) is shown both ways, as the dashboard's wheat flour case did, through `vehicle_group` |

### Q5. Who is left outside the reach of the vehicles? (exploratory)

| | |
|---|---|
| Headline | "x% of households (95% CI a–b) acquire none of the vehicles; among <group>, y%." |
| Exhibit | Table by domain: coverage of each vehicle and of "none" (the last column of Table 3 of Tang et al.) |
| Functions | `vehicle_coverage(combine = list(any = <all vehicles>))` → `estimate_households(by = <domain>)`; "none" is the complement of `any` |
| Status | **Available** for coverage by domain. The ratio of coverage between two groups with its interval is missing (G3) |
| Notes | Aaron et al. summarise equity with the coverage among the vulnerable ("met need") and a coverage ratio; the first is a domain estimate and is available, the second is G3 |

### Q6. What would each fortification scenario change?

| | |
|---|---|
| Headline | "<Action> would lower the risk of <nutrient> by x points (95% CI a–b); <other action> would not change it." |
| Exhibit 1 | Scenario table: vehicle, nutrient, level, basis, compliance, source (the template's version of Table 1 of Tang et al.), printed from the `scenarios` table |
| Exhibit 2 | Paired difference and interval per action and nutrient, each action against its stated comparator |
| Exhibit 3 | Households above the upper level per scenario, on the form the UL applies to |
| Functions | `apply_scenario()`, `inadequacy()`, `estimate_difference(reference = …)`, `above_ul()` + `estimate_households()` |
| Status | **Available.** Gap: the comparator of each action is a hand-written table in the template (D5) |
| Notes | A gain is never shown without exhibit 3 on the same page. The equity reading uses the paired difference by quintile (`estimate_difference(by = "quintile")`), which has an interval. The quintile 5 to quintile 1 ratio of median intake of the presentation had no interval and is not carried over until G3 exists (D6) |

### Q7. What can these figures not answer, and what is needed next?

| | |
|---|---|
| Headline | "The comparison between scenarios is more robust than the absolute level." (fixed sentence, from the presentation) |
| Exhibit | "Decisions that condition the interpretation": the dashboard's table (decision, situation, effect if unresolved, evidence available), filled by the analyst, with the rows the package can derive pre-filled from the audit log and the params (requirement source, bioavailability, compliance, outlier decision, record loss) |
| Functions | `audit_summary()`, `link_composition()` coverage, `flag_energy_plausibility()` |
| Status | **Available**; the table itself is text the analyst writes |
| Notes | Ends with the open questions of the presentation, as prompts: measured compliance, validation against individual intake or biomarkers, next survey round, who maintains the estimate. Fitness for use is answered here with its conditions (D2) |

### Annexes (method, never in the body)

| Annex | Content | Functions | STROBE-nut |
|---|---|---|---|
| A. Methods | Survey and food module, recall period, design; conversion to grams; composition sources and matching; AFE; estimators table of the presentation | text + `hces_schema()` | nut-5, 7.1, 8.1, 8.2, 12.2 |
| B. Data flow | Records and households at each step, with cause of exclusion | `audit_summary()`, `unmatched_foods()`, `check_crosswalk()` | nut-13 |
| C. Biases and their direction | The presentation's table: source of error, direction of the effect on the estimated risk, control applied | text, analyst | nut-9, 19 |
| D. Sensitivity | Iron bioavailability; outlier decision on and off; `min_coverage`; energy plausibility; risk and energy by domain | `inadequacy(bioavailability =)`, `flag_outliers()`, `flag_energy_plausibility()` | nut-17 |
| E. Full tables | Every estimate with n, standard error, interval, degrees of freedom, precision flag | `estimate_households()`, `flag_precision()` | nut-14 |
| F. Reference values | Requirements, upper levels, conversion factors, with source; the params used | `ref_requirements`, `ref_iron_requirements`, `ref_conversions` | nut-8.3 |
| G. Reproducibility | Package version, session, md5 of the input files, where the code and data are | `utils::sessionInfo()`, `tools::md5sum()` | nut-22.2 |
| H. Reporting checklist | STROBE-nut items with the section that answers each, and those that do not apply (7.2 dietary patterns, 8.4 biomarkers, 12.3 measurement-error adjustment, 16 supplements: not captured by the survey, stated as a limit) | static table | all |

## 4. Mechanics

- `use_report_template(path, lang = "en")` copies the template files from
  `inst/` to `path`, refuses to overwrite, and returns the paths
  invisibly. It needs no new dependency: it copies files. Quarto is needed
  only to render, and is not an R dependency of the package.
- Files: `report.qmd` (the body), `_results.R` (the only place where the
  chain is run; wired to `hces_example`, with one marked block to replace
  by the adapter's tables), `_figures.R` (the `ggplot2` code), and
  `decisions.csv` (the table of Q7).
- `params`: country, survey, year, priority nutrients, reference scenario,
  domains, `min_n`, `max_half_width`, `min_coverage`, iron
  bioavailability, confidence level. None has a silent default in the
  package; the shipped YAML sets them for the example and prints them in
  annex F.
- A test renders the template on `hces_example` when Quarto is installed
  and skips otherwise; another checks that every function named in the
  template is exported.

## 5. Contrast with the three references

### 5.1 Tang et al. 2022 (Malawi)

| In the article | In the template |
|---|---|
| Three objectives: coverage and quantity; contribution to density, apparent intake and inadequacy; differences between residence and socioeconomic groups | Q4, Q1 and Q6, Q2 and Q5. The template adds Q3 (food sources) and Q7 (limits), which the article treats in the discussion |
| Table 1, fortification parameters per scenario | Exhibit 1 of Q6 |
| Table 2, description of the survey population by residence and quintile | Annex A, short. Not in the body: it answers no decision question |
| Table 3, coverage and median (IQR) among consumers, national, by region, by residence and quintile, with a "none consumed" column; no confidence intervals | Q4 and Q5, with intervals |
| Figures 1 and 2, percentile curves of density and apparent intake per scenario with the inadequacy threshold | Not in the body. Optional annex figure; needs quantiles other than the median (G4) |
| Figures 3 and 4, seasonality by residence and quintile | Not included: needs the interview date, which the standard `households` table does not require. Optional, v0.2 |
| Nutrient density next to apparent intake, with a critical density threshold | Density is available (`nutrient_density()`); the template reports risk on apparent intake only. Critical densities need a reference table the package does not ship (G5) |
| Quintiles of expenditure per capita built separately for urban and rural | The domain column comes from the adapter; the template states how it was built (STROBE-nut nut-11) |
| Excess intake mentioned from a supplementary table | Exhibit 3 of Q6, in the body |
| Limits: intrahousehold distribution, constant composition, uniform fortification of the vehicle, HCES measurement error | Annex C, with the direction of each bias as in the presentation |

### 5.2 STROBE-nut (Lachat et al. 2016)

STROBE-nut is a reporting checklist for a paper; it does not prescribe an
order. The template keeps the decision order and meets the checklist
through the annexes: annex H maps each item to its place (last column of
the annex table above). Three items change the body, not just the annexes:
nut-1 (the title names the assessment method), nut-14 (say whether a
quantity is over all households or consumers only: Q4) and nut-20
(nutritional relevance of the findings: the reading sentences of each
section). nut-22.1 (ethics) is answered by one sentence in annex A on the
secondary use of public or licensed microdata.

### 5.3 FACT (as described by Aaron et al. 2017)

| In the article | In the template |
|---|---|
| Three coverage measures in sequence: consumes the vehicle, consumes it in a fortifiable form (industrially processed), consumes it fortified; the stage where coverage falls is the programme bottleneck | An HCES observes the first stage. The second is reachable only when the adapter's `vehicles` table separates industrial from non-industrial products; the third is not observable and enters as the `compliance` of the scenario. Q4 labels its figure as stage one and says so |
| Raw coverage, met need (coverage among the vulnerable) and coverage ratio (vulnerable over non-vulnerable) | Raw coverage: Q4. Met need: Q5, as a domain estimate. Coverage ratio: G3 |
| Vulnerability by multidimensional poverty, women's dietary diversity and rural residence | An HCES usually gives residence and expenditure quintile; the template takes whatever domain columns the analyst names and does not assume the other two |
| Performance criteria: raw coverage ≥ 50%, met need ≥ 75% in at least one vulnerable group, no coverage ratio significantly below 1; the authors say the criteria can be changed | Not adopted as defaults. They may be passed as params and are then printed; no threshold is hidden |

## 6. What the package lacks

| Id | Gap | Needed by | Priority | Where it fits |
|---|---|---|---|---|
| G1 | `use_report_template()` and the template files in `inst/` | all | high | new task 12b (Opus), after this design is approved; the vignette in task 12 (Sonnet) |
| G2 | `food_group_shares()` on the unfortified baseline, with the design. Needs a `food_group` column in a standard table: a contract change, so a short design first | Q3 | high | roadmap v0.2 today; D4 proposes to bring it forward |
| G3 | Contrast between two domains with its interval: difference and ratio of proportions (coverage ratio, gap between quintiles). `estimate_difference()` is paired within household and does not cover it | Q2, Q5, Q6 | medium | v0.2, next to P91 (a ratio helper over `survey::svyratio()`/`svycontrast()`) |
| G4 | Quantiles other than the median in `estimate_households()` | optional annex figure | low | v0.2 |
| G5 | Critical nutrient density thresholds as a sourced reference table | optional | low | with the H-AR table, v0.2 |
| G6 | `hces_example` has `region` and `stratum` only: no socioeconomic domain, so Q2 and Q5 cannot show a quintile on the example | Q2, Q5 | medium | task 12b: add an invented `expenditure_group` column |
| G7 | No record of analytic choices (bioavailability, reference energy, compliance) beside the audit log of exclusions; the Q7 table is filled by hand and from params | Q7 | low | v0.2 |

Not gaps: scenario table (printed from `scenarios`), "none of the
vehicles" (`combine`), precision flags, data flow, sensitivity to iron
bioavailability. All exist.

## 7. Risks

- **A template that overstates.** Headlines are sentences; the guard of
  principle 4 is the control. The self-review of task 12b must try to
  break each headline with altered example data.
- **Template drift.** The template calls exported functions; a rename
  breaks it silently unless the test of section 4 runs in CI.
- **Scope.** The template adds files and one exported function, no
  plotting API and no dependency.

## 8. Decisions for the maintainer

Recommended option first.

1. **D1. Name and form.** `use_report_template(path, lang)` copying plain
   Quarto files, *recommended*, against a Quarto extension
   (`quarto use template`), which needs a repository layout of its own and
   Quarto to install.
2. **D2. Where the fitness-for-use question goes.** The presentation asked
   it first ("does the survey allow the estimate?"). *Recommended:* one
   verdict line on the front page and the full answer, with its
   conditions, in Q7; the body opens with the need (Q1). Alternative: keep
   it as the first section.
3. **D3. Reference scenario of Q1 and Q2.** *Recommended:* a required
   param with no default; the unfortified baseline is always shown beside
   it. The presentation used the current standard at full compliance; a
   country without measured compliance may prefer the baseline.
4. **D4. Q3 before `food_group_shares()` exists.** *Recommended:* bring
   G2 forward into v0.1 (design by Fable, then Opus), because Q3 is one of
   the six questions and E1 is a known error whose correction is not yet
   demonstrable. Alternative: ship the template with Q3 marked "not
   available in this version".
5. **D5. Actions in Q6.** *Recommended:* the analyst writes a small table
   (action, scenario from, scenario to), as the presentation did; the
   package does not infer an order of scenarios.
6. **D6. Equity measure across scenarios.** *Recommended:* paired
   difference by quintile now, with intervals; the quintile 5 to 1 ratio
   returns only when G3 gives it an interval.
7. **D7. Share estimator for G2.** *Recommended:* ratio of weighted
   totals (the group's share of the population's supply), consistent with
   P90, against the mean of household shares. To confirm in the G2 design.
8. **D8. Languages.** *Recommended:* English and Spanish templates from
   the first version (`lang = "es"`), since the first two countries read
   Spanish. Alternative: English only, Spanish with the Spanish vignette.
9. **D9. Thresholds of Aaron et al. (50%, 75%, ratio below 1).**
   *Recommended:* not shown unless the analyst passes them.
10. **D10. FACT manual.** Can you open `www.gainhealth.org` to this
    environment or send the PDF? *Recommended:* yes, before the template
    text cites the manual; until then it cites Aaron et al. 2017 only.
11. **D11. Dot plot instead of a map in Q2.** *Recommended:* yes, for the
    interval; the vignette on plotting may show a map as the user's own
    code.
