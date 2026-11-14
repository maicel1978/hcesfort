# Design: reports v3 and a realistic example

- **Date:** 2026-11-14. **Status:** approved by the maintainer on
  2026-11-14: the sixteen decisions of section 13 as recommended, with
  conditions on 1, 2, 5, 8 (zinc added) and 13, recorded in
  `docs/improvements.md`, section "Decisions (2026-11-14, reports v3)".
  No package code is written in this task (12d.0).
- **Input.** `docs/report-requirements-v2.md` (approved 2026-11-14):
  principles P6–P10, requirements DR9–DR13, R15–R24, X1–X2, Q1–Q4. Read
  with `docs/report-requirements-v1.md` and `docs/design-reports-v2.md`,
  which still hold where this note does not replace them.
- **Aim.** Two reports that hold up to a hostile but fair journal
  reviewer and that a decision maker can read: verdict or findings first,
  figures in the body, a published presentation standard instead of an
  invented rule, wording and thresholds that are cheap to change, and an
  example large enough for the presentation rules to behave as with real
  data.

## 1. Facts checked in this session

| Fact | How it was checked |
|---|---|
| The NCHS presentation standard for proportions: thresholds, actions and definitions of section 3.1 | Parker et al. 2017 opened and read (`https://www.cdc.gov/nchs/data/series/sr_02/sr02_175.pdf`, md5 `2ae6002af069bb55f555e2e271f1908d`; revision of 1 November 2018, Table II updated 8 April 2021): Table, p. 2; text, pp. 2–5; flow chart, p. 7; examples, pp. 8–9 |
| The Korn-Graubard interval as NCHS applies it: effective sample size multiplied by the squared ratio of *t* quantiles, **then** capped at the sample size | The twelve rows of Tables I and II of the report (pp. 8–9) recomputed by hand in R from the published `n`, percent, standard error and degrees of freedom: every limit within 0.1 percentage point (the rounding of the inputs). Capping before the *t* adjustment does not reproduce them |
| `survey::svyciprop(method = "beta")` (survey 4.5) is that interval **without** the cap, uses `degf()` and `nrow()` of the design it receives and ignores its `df` argument | Source printed in this session. It departs from the published limits in the rows where the effective sample size is above `n` (for example 2.5%, `n` = 589: published [1.4, 4.1], uncapped [1.5, 3.8]) |
| Folate: the UL applies to folate from fortified food or supplements, not to food folate | IOM 1998: Summary, p. 13 ("The ULs for folate and niacin apply to forms obtained from supplements, fortified foods, or a combination of the two"); chapter 8, p. 273 (the review is limited to supplemented folate), p. 280 (UL for adults 19 years and older, "1,000 µg/day of folate from fortified food or supplements"), p. 282 ("the UL of 1,000 µg/day of folic acid") |
| Vitamin A: the UL applies to preformed vitamin A from food, fortified food and supplements; provitamin A carotenoids are outside it | IOM 2001, chapter 4: p. 125 (the UL for provitamin A carotenoids is addressed in IOM 2000), p. 126 ("The UL derived here applies to chronic intake of preformed vitamin A from food, fortified food, and/or supplements"), p. 142 (UL for women 19–50 years, 3,000 µg/day of preformed vitamin A). Pages 126 and 142 read on the scanned page images |
| **Several page citations of `data-raw/requirements.csv` and `data-raw/SOURCES.md` are one page too high** | Same reading: the two vitamin A statements are cited at pp. 127 and 143 and are on pp. 126 and 142. By the page anchors of the online text, the same shift affects the vitamin A EAR (116 → 115), iron EAR (345 → 344) and UL (376 → 375), zinc EAR (476 → 475) and UL (487 → 486), the folate EAR (229 → 228) and the 18% iron absorption (316–317 → 315). Values are not affected. Item P124 |
| Both reports knit on 2,000 households (the example tiled 50 times: 15,900 records, 400 PSUs, 8 strata) in 3.8 s (readiness) and 8.3 s (results) | Run in this session |
| `tinytable` 0.19.0 has no dependency but `methods`; `gt` 1.4.0 has 60 recursive dependencies, `flextable` 64, `kableExtra` 48 | `tools::package_dependencies()` on the CRAN index; `tinytable::tt(caption =, notes =)`, `style_tt()`, `theme_html(portable = TRUE)` and `print(x, "markdown")` run. Its default HTML loads a script and a stylesheet from a CDN; `portable = TRUE` removes both |
| `ggplot2` is not installed by the environment's setup script, so the knit tests are skipped in a fresh container | `rownames(installed.packages())` at the start of this session |

## 2. Review of the v2 reports

As a journal reviewer (hostile but fair) and as an information designer.
Each finding names where this design answers it.

| # | Finding | Answer |
|---|---|---|
| H1 | The 15-point precision rule is invented | 3 (NCHS standard, with every departure stated) |
| H2 | A dumbbell in the body with the interval of the effect in an appendix invites reading two points as a significant change | 6.3 (two panels: levels, and the paired difference with its interval) |
| H3 | "0%" from a sample is printed as a fact about the population | 3.3 (Clopper-Pearson limit on `n`; the sentence says "in the sample") |
| H4 | The UL note calls every added-only comparison a lower bound for the same reason; for folate the reason is wrong | 6.4 (statement per form, verified) |
| H5 | The unit is the household per adult female equivalent, and intake is apparent; "risk" and "inadequate intake" drift between exhibits | 8 (glossary; one term per concept) |
| H6 | The baseline "without fortification" is modelled, not observed | 8 (the titles of section 2 say "modelled baseline without fortification") |
| H7 | Titles do not say where and when; `n` is missing or sits in a precision column | 5.3, 5.4 |
| H8 | Thresholds are applied but not printed with their source | 6.6 (technical note: the standard used, with citation) |
| I1 | Tables first makes a decision maker read 20 tables to find 6 messages | 6 (figures in the body, tables in one appendix) |
| I2 | Hollow points mean "comparator" in one figure and "wide interval" in another | 5.5 (one meaning per mark) |
| I3 | Figures of 3 rows and of 15 rows have the same height | 5.5 (height from the number of rows) |
| I4 | A reader cannot cite an exhibit | 5.1 (stable visible IDs) |
| I5 | The inventory lists 30 rows to show that 2 are absent | 4.2 (short inventory; full list in an appendix) |

## 3. Presentation standard (R18)

### 3.1 The standard, as read

Parker JD, Talih M, Malec DJ, et al. *National Center for Health
Statistics data presentation standards for proportions.* Vital Health
Stat 2(175). 2017.

| Criterion | Value | Action | Page |
|---|---|---|---|
| Interval | 95%, two-sided, Clopper-Pearson; Korn-Graubard for complex surveys | — | 2, 3 |
| Sample size `n` (denominator) | below 30 | suppress | 2 |
| Effective sample size `n_e = p(1 − p) / var(p)` | below 30 | suppress | 2, 3 |
| `n_e` above `n` | — | use `n`, also for the interval | 3 |
| Absolute width of the interval | 0.30 or more | suppress | 2 |
| Absolute width | 0.05 or less | present, subject to the two rows below | 2 |
| Relative width (width / `p`), when the absolute width is between 0.05 and 0.30 | above 130% | suppress | 2, 3 |
| Events: 0, or equal to `n` | — | interval from `n`; flag for statistical review | 2, 3 |
| Degrees of freedom (PSUs minus strata, of the subgroup) | below 8 | flag for statistical review | 2, 4 |
| Complement would not meet the criteria | — | present, with a footnote that the complement may be unreliable | 2, 4 |
| Any flag or suppression | — | a footnote gives the reason | 2 |

Also read: there is no minimum number of events (p. 5); flagged estimates
may all be suppressed automatically, or presented after review (pp. 2,
5); departures must be justified (p. 2); the Standards "were not
developed to apply to" rates, percentiles and means, and give no
thresholds for them (p. 5).

### 3.2 Package changes

**C1. Reference table `ref_presentation_standard`** (shipped, with
source, replaceable by argument, like `ref_conversions`). Entered in
`data-raw/presentation_standard.csv`, registered by md5, listed in
`data-raw/SOURCES.md` as verified. Columns `criterion`, `value`, `source`,
`location`, `status`; rows `conf_level` 0.95, `min_n` 30,
`min_n_effective` 30, `small_absolute_width` 0.05,
`large_absolute_width` 0.30, `max_relative_width` 1.30, `min_df` 8. R18's
check "threshold values carry the citation" is this table.

**C2. `estimate_households(ci_method = "korn_graubard")`.** Point
estimate and variance from `survey::svymean()` on the domain, as today.
Interval: `n_e = p(1 − p) / var`, multiplied by
`(qt(α/2, n − 1) / qt(α/2, df))²`, capped at `n`; limits
`qbeta(α/2, x, n_e − x + 1)` and `qbeta(1 − α/2, x + 1, n_e − x)` with
`x = n_e p`. A proportion that is 0 or 1 in the sample keeps `se = 0` and
gets the Clopper-Pearson interval on `n` (today: no interval; unchanged
for the other methods). `df` is honoured (`"domain"` by default, which is
what p. 4 asks of subgroups). Every `hces_estimate` gains the column
`ci_method` (`"korn_graubard"`, `"logit"`, …; `"t"` for means and
differences, `"woodruff"` for medians), so a later step can check which
interval it judges. The default `ci_method` does not change.

**C3. `flag_presentation(estimates, standard = ref_presentation_standard)`**
(new, exported; detection only). Adds `n_effective`, `ci_width`,
`ci_relative_width`, `presentation` (`"present"`, `"review"`,
`"suppress"`), `presentation_reason` and `complement_unreliable`, and
counts each status in the audit log. For rows with
`statistic == "proportion"` it applies the flow chart of p. 7 in its
order: `sample_size`, `effective_sample_size`, `absolute_width`,
`relative_width` (suppress); then `zero_events`, `degrees_of_freedom`
(review). It aborts (`hcesfort_error_argument`) when a proportion was not
estimated with `ci_method = "korn_graubard"` at the `conf_level` of the
standard: the standard judges that interval and no other.
`flag_precision()` stays for callers with their own limits; the reports
stop using it, and `max_half_width` leaves `choices`.

### 3.3 Departures, each printed in the technical note

| # | Departure | Reason |
|---|---|---|
| S1 | **Other estimators** (median quantity, paired differences, food-group shares, unlinked shares): only `sample_size` and `degrees_of_freedom` apply; the interval is always shown; no width rule | The standard gives no thresholds for them (p. 5). Inventing one is what R18 removes |
| S2 | **Proportions that are means of probabilities** (iron by the probability approach): the standard is applied to the mean probability | Its variance is at most that of a binary outcome, so `n_e` reaches `n` and is capped: the judgement is conservative. "Zero events" means a mean of exactly 0 or 1 |
| S3 | **Statistical review** is the analyst's: `choices$review` is `"show"` (the estimate is printed with a mark and the reason) or `"suppress"` | pp. 2 and 5 allow both. No value is a default of the package |
| S4 | **Zero events** are presented as a sentence with `n` and the Clopper-Pearson limit, not as a table row | D4 of v1 and R19, R21; the interval is the one the standard prescribes |

### 3.4 Tests

- The interval equals `survey::svyciprop(method = "beta")` to 1e-8 where
  the cap does not bind and `df = "domain"`; equals
  `stats::binom.test()$conf.int` to 1e-8 on a design of equal weights
  without clusters, including 0 and `n` events.
- The twelve published rows of Tables I and II (pp. 8–9), typed into the
  test with their page: limits within 0.15 point, and the published
  decision of each row (suppress, review, present, complement footnote).
- One hand-built estimate per criterion and boundary (29 and 30
  households; widths 0.05 and 0.30; relative width 130%; 7 and 8 degrees
  of freedom), each handled as the table of 3.1 says.
- Invariants: the status does not depend on row order; lowering a
  threshold of `standard` never turns `suppress` into `present`; the
  interval contains the estimate and stays within [0, 1].

## 4. Data readiness report (DR9–DR13)

### 4.1 Order (P8)

| # | Section | ID | Content |
|---|---|---|---|
| 1 | Verdict (DR9) | D1 | The verdict matrix, then one paragraph of three sentences built from the verdict and the checks: what the data support (sections and domains enabled), what they do not (each with its reason), what is left (foods pending, the share of grams and expenditure they hold, thresholds not met). Sentence patterns live in `terms.csv`; they state counts and statuses, never a judgement |
| 2 | Variables | D2 | Essential variables, and the optional ones that are absent or partly missing (DR13) |
| 3 | Minimum quantity and quality | D3 | The checks with their thresholds, `domain_cells` included (4.3) |
| 4 | Linkage ladder | D4 | As today |
| 5 | Work queue | D5, D6 | Table and coverage curve, as today |
| 6 | Stopping rule and its cost | D7, D8 | The rule and the national unlinked share. By domain (DR10): one sentence naming the domain variables in which no value differs from the rest of the population; table D8 only for a domain variable with at least one value that differs, with all its values |
| 7 | Energy plausibility | D9 | National only (DR10): one sentence (median per AFE, its share of the reference energy, share of households outside the bounds, with intervals) and one figure, a weighted histogram of energy per AFE with the bounds and the reference energy. No by-domain exhibit |
| 8 | Decisions taken with the data | D10 | `decisions.csv` |
| A | Appendix | DA1 | The full inventory |

Tables stay in the body of this report: P7 is a rule of the results
report, and this one is read by the analyst.

### 4.2 Dependency map (DR12) — C4

`needed_by` of `readiness_inventory()` takes its values from one constant
in `R/readiness-map.R`:

| Input | `needed_by` |
|---|---|
| essential columns and tables | `all` |
| a domain column | `domain` (printed "analysis by <label of the domain>") |
| `food_module_response` | `household_status` |
| `age_months`, `pregnant`, `lactating`, `meals_home_share`, `weight_kg` | `adult_equivalents` |
| `household_share` | `quantities` |
| `expenditure_lcu` | `linkage_expenditure` |
| `enrichment` | `baseline` |
| `vehicles`, `scenarios`, `food_groups` | the sections, as today |
| `origin` | `none` |

### 4.3 Domains with small cells (DR11) — C5

`readiness_checks()` gains `households`, `domains`, `min_n` and
`max_small_cells` (no defaults) and one row per domain: check
`domain_cells`, `n` the number of values of the domain, `value` the share
of them with fewer than `min_n` households with an estimated intake,
`threshold` `max_small_cells`, `met` when `value` is at most the
threshold. `readiness_verdict()` disables the rows of a domain whose
`domain_cells` is not met (`threshold_not_met`). The template passes
`min_n` of the presentation standard and `choices$max_small_cells`
(proposed 0.5). The effective sample size cannot be used here: it is
known only once an estimate exists.

## 5. Shared machinery of the template

### 5.1 Exhibit registry (Q2)

`exhibits.csv`, shipped with the template and free of language:

| Column | Content |
|---|---|
| `id` | stable ID, printed in the report: `D1`…`D10`, `DA1`; `R0`, `R1.1`…`R4.1`, `RT1`…`RT3` |
| `report`, `section` | where it is shown |
| `body` | what the body shows: `figure`, `table` or `sentence` |
| `builder` | the one function of `_readiness.R` or `_results.R` that builds it |
| `verdict_section` | the section of the verdict that enables it, or empty |
| `repeats` | `none`, `domain`, `nutrient` or `nutrient_domain` |
| `appendix` | whether the appendix prints its table |

An exhibit that repeats is cited by its ID and its instance ("Figure
R2.2, Region"). `show_exhibit(id)` reads the registry, asks the verdict,
calls the builder, stores `tables[[id]]` and `figures[[id]]` and prints.
The two `.qmd` files of each language keep headings, free text and these
one-line calls, so the code written once per language (P121) nearly
disappears.

### 5.2 Wording and switches (P10)

- Titles, notes, sentence patterns and headers: `terms.csv`, by exhibit
  ID. Labels of the analyst's codes: `labels.csv`.
- **C6.** `labels.csv` gains the optional column `short_label` (R22);
  `label_codes(short = TRUE)` uses it where given, else the label; unique
  within `type` + `parent`. New label type `compound`.
- `choices` gains `place`, `survey` (R16; both may be `NULL`), `vehicles`
  (R23; `NULL` is all), `review` (S3) and `max_small_cells`; it loses
  `min_n`, `max_half_width` and `level`, which now come from
  `presentation_standard <- hcesfort::ref_presentation_standard`, written
  in `_inputs.R` where the analyst may replace it and must then justify
  it in `decisions.csv`.
- `choices$vehicles` filters `vehicles` before the chain. A scenario that
  fortifies a vehicle left out stops the render
  (`hcesfort_error_argument`, naming the scenarios): nothing is dropped
  silently.

### 5.3 Titles (R16)

`<kind> <ID>. <what>, <unit> (<interval>). <place>, <survey>`, for
example "Figura R1.1. Hogares que adquieren cada vehículo de
fortificación, % (IC 95%). República Dominicana, ENGIH 2018". Place and
survey are appended only when set; no other metadata is printed. The
title is text above the exhibit, so that the sentence of R19 can follow
it.

### 5.4 Notes and marks (R17, R19)

Order inside an exhibit: title; sentences about zero-event estimates
(R19); figure or table; note. The note gives, in this order and only
when they occur: `n` ("n = 1,962 households"; a column instead where it
varies by row); "—" suppressed, with the reasons; "†" flagged for
statistical review, with the reasons; "‡" the complement may be
unreliable; exhibit-specific lines. The "Precision" column is removed.

### 5.5 Figures and tables (P9)

- `ggplot2` only. Dot and 95% interval, the value printed beside it
  (`check_overlap = TRUE` decides legibility). Row order is the order of
  `labels.csv`, not of the values, so a figure keeps its shape between
  renders. Percentages of households on a 0–100 axis; differences and
  upper-level shares on a free axis with a zero line.
- One meaning per mark: filled point = the estimate; hollow point = the
  comparator of a scenario; "†" on the value label = statistical review.
  Suppressed estimates are not drawn.
- Each figure is written with `ggplot2::ggsave()` at a height computed
  from its number of rows and included as an image whose alternative text
  is its title.
- Tables are rendered by **`tinytable`** (Suggests; decision 1) through
  one function of `_tables.R`, with `theme_html(portable = TRUE)`.
  Snapshot tests do not depend on the renderer (9.1).
- A small stylesheet keeps an exhibit on one printed page (R13).

## 6. Results report (R15–R24)

Body: figures; the scenarios table and the reference tables stay as
tables (P7). The appendix prints one table per figure, with the same ID
(R15).

### 6.1 Order

| # | Section | ID | Body |
|---|---|---|---|
| 0 | Main findings (P8) | R0 | Figure: households with inadequate apparent intake under the modelled baseline and under each scenario that adds the nutrient, one panel per nutrient. Then the analyst's own findings; the template writes none (P3; decision 5) |
| 1 | Coverage | R1.1 | Households acquiring each vehicle |
| | | R1.2 | Each vehicle group and any vehicle; the note lists the members of each group |
| | | R1.3 | Median quantity among acquirers, g per AFE per day |
| | | R1.4 | Households acquiring no vehicle, by domain; the national figure is the complement of R1.2 and is not repeated |
| 2 | Inadequate apparent intake | R2.1 | By nutrient, modelled baseline |
| | | R2.2 | By domain, one figure per domain variable, panels by nutrient, a dashed line at the national estimate |
| 3 | Scenarios | R3.1 | Table (6.2) |
| | | R3.2 | Effect of each scenario, one figure per nutrient (6.3) |
| | | R3.3 | Above the upper level (6.4) |
| | | R3.4 | Effect by domain, per nutrient and equity domain |
| 4 | Food groups | R4.1 | Share of each group, panels by nutrient (6.5) |
| — | Technical note | RT1–RT3 | 6.6 |
| A | Appendix of tables | same IDs | |

### 6.2 Scenarios table (R22)

Columns: scenario (label), abbreviation (short label), vehicle, nutrient,
compound or form, level in mg of nutrient per kg, compliance, source.
The compound is printed when the scenario names one, else the form; a
row with neither prints "not stated" from `terms.csv`, never "—".
Figures use the short label, tables the label. The method note reads
"iron: probability approach, iron bioavailability 10%".

### 6.3 Effect of a scenario (R15 against R10f)

Two panels on shared rows, one row per scenario: left, the dumbbell
(comparator hollow, scenario filled, % of households); right, the paired
difference in percentage points with its 95% interval and a zero line.
The dumbbell shows the size of the change and the right panel its
uncertainty, in the same exhibit. The two points carry no intervals of
their own: two separate intervals invite the overlap reading that the
paired difference exists to avoid. R3.4 has the same two panels with one
row per domain value and one band per scenario.

### 6.4 Upper level (R21)

1. One sentence for the zeros: "In the sample (n = …), no household
   exceeds the UL of <nutrients> under any scenario (upper 95% limit:
   x% of households)."
2. Figure R3.3 with the estimates above zero only.
3. One statement per nutrient, from `terms.csv`, keyed by the form the UL
   applies to (`ul_applies_to`) and by what was compared (`ul_scope`); a
   form without a statement stops the render with the list of missing
   terms.

| Form and scope | Statement | Source |
|---|---|---|
| `folic_acid`, added only | The UL applies to folate from fortified food or supplements, not to food folate. The folic acid added by the scenario is therefore the right quantity to compare. Folic acid from foods fortified outside the scenarios and from supplements is not recorded by the survey: where they exist, the share is a lower bound | IOM 1998, pp. 13, 280 |
| `preformed_vitamin_a`, added only | The UL applies to preformed vitamin A from food, fortified food and supplements. Only the retinol added by the scenario is compared; preformed vitamin A of the diet and of supplements is not counted: the share is a lower bound | IOM 2001, pp. 126, 142 |
| a form, diet and added | As above, with the diet counted; supplements are not | same |
| `total` | Total intake of the scenario; supplements and water are not counted, and records or composition values that are missing lower it | IOM 2001, as cited in `data-raw/SOURCES.md` (page to re-check, P124) |

The line "the adult UL is applied to intake per AFE; children have lower
upper levels" stays.

### 6.5 Food groups (R20)

A group whose share of a nutrient is exactly 0 leaves the figure and the
table and is listed in the note: "No iron from: fats and oils, dairy,
fruits". This replaces the "0 without interval" of R11. The share of
foods without a group stays in the note.

### 6.6 Technical note

RT1: EAR and UL used, with source. RT2: the presentation standard used
(the rows of `presentation_standard`, with citation), the departures
S1–S4, `choices$review`, the choice for strata with one PSU. RT3: iron
bioavailability sensitivity. Then the link to the readiness report.

## 7. Realistic example (X1, X2)

### 7.1 `hces_example` is replaced — C7

| Element | Design |
|---|---|
| Sample | 2,000 households: 3 regions × urban and rural = 6 strata; 200 PSUs (25 to 40 per stratum) of 10 households; 194 design degrees of freedom |
| Weights | A base weight per stratum times a PSU factor, so weights are unequal |
| Clustering | A PSU effect on household wealth and on what is acquired, so design effects are above 1 and `n_e` below `n`, as in a real survey |
| Domains | `region` (3), `area` (2) and `expenditure_group` (5: weighted quintiles of food expenditure per member, computed by the script). About 400 households per quintile and 600 or more per region |
| Members | Household size falls with wealth; ages and sexes from a fixed pyramid; pregnant and lactating women |
| Foods | About 45, in `data-raw/example_foods.csv` (entered by hand, every value invented): unit, probability of acquisition and its slope on wealth, region multiplier, typical quantity and its elasticity, price, invented composition (energy, iron, folate, vitamin A), edible portion, crosswalk status, food group, vehicle and fraction |
| Vehicles | Rice; wheat flour, bread and pasta (group wheat flour); maize flour, concentrated in one region; sugar; vegetable oil; a biscuit that carries flour and sugar |
| Scenarios | Five, with levels invented and labelled so in the scenarios table: wheat flour (iron, folic acid); the same plus maize flour; plus rice; plus vitamin A in sugar; plus vitamin A in oil. Iron rows name a compound. `choices$comparator` stays `NULL`, with a commented example comparing each addition with the wheat-flour scenario |
| Planted defects | Every case of the present example, at rates of a real survey: module non-response, households without AFE, records without quantity or unit, units without factor, volume without density, foods unmatched or not validated or without edible portion, excluded records, a few extreme quantities, two recall periods, enriched foods, a food without group |
| Nutrients | Energy, iron, folate, vitamin A, as today |
| Calibration | Targets checked by a test as broad bands, not exact values: median energy per AFE near the reference; baseline inadequacy of the three nutrients between 20% and 80% with a gradient by expenditure group; one scenario with a share above the folic acid UL above zero, and zeros for the others |
| Script | `data-raw/hces_example.R`, base R only, `RNGkind()` and seed set explicitly, every generated number rounded before it is stored. The data stay invented and say so |

The present 40-household dataset is not lost: it moves to
`tests/testthat/fixtures/` with its script and keeps serving the unit
tests whose expected values are computed by hand on it (CLAUDE.md:
minimal hand-built households). Roxygen examples and the template run on
the new example.

### 7.2 Golden values (X2)

`data-raw/golden_example.R` (base R and `survey`, no function of
hcesfort) is run on the new example and on the fixture; it gains the
Korn-Graubard interval and the presentation status of each golden
estimate, written from section 3.1. The package must agree to 1e-8.

## 8. Language (R24)

One term per concept, in both reports and both languages; the wording
pass applies this table to every sentence and label, and the maintainer
reads the result.

| Concept | English | Spanish |
|---|---|---|
| Unit of every share | % of households | % de hogares |
| Intake | apparent intake per adult female equivalent (AFE) | ingesta aparente por equivalente de mujer adulta (EMA) |
| Below the requirement | inadequate apparent intake | ingesta aparente inadecuada |
| Baseline | modelled baseline without fortification | línea de base modelada, sin fortificación |
| Change | paired difference, percentage points | diferencia pareada, puntos porcentuales |
| Upper level | tolerable upper intake level (UL) | nivel máximo de ingesta tolerable (UL) |
| Interval | 95% CI | IC 95% |
| Suppressed | suppressed (NCHS standard) | suprimido (estándar NCHS) |

Not used: "deficiency", "population" for households, "risk" without
"of inadequate apparent intake", "significant".

## 9. Robustness and change (Q1–Q4)

### 9.1 Snapshot tests (Q1)

Every exhibit is an object (ID, title, sentences, display table, notes)
with a plain-text print method. One `testthat::expect_snapshot()` per
exhibit, report and language prints it on `hces_example`. The snapshot is
of the object, not of HTML, so a change of renderer or of its version
changes no snapshot, while a changed word or number is a reviewable
diff.

### 9.2 Registry tests (Q2)

Every ID of `exhibits.csv` has a title in `terms.csv` of each language
and a builder that exists; every figure of the results body has an
appendix table of the same ID (R15); every exhibit printed is in the
registry.

### 9.3 Feedback log (Q3)

`docs/feedback/README.md` and one CSV per round
(`YYYY-MM-DD-round-N.csv`): `comment`, `exhibit_id`, `decision`
(accepted, rejected, deferred, with the reason), `result` (requirement,
test or commit). Reviewers are identified by role, not by name. A test,
skipped where `docs/` is absent, checks that every `exhibit_id` is in the
registry.

### 9.4 Acceptance (Q4)

Nothing here is accepted on the example alone: the maintainer renders
both reports with the ENGIH 2018 microdata.

## 10. Automated checks added or changed

| Id | Req. | Test |
|---|---|---|
| U11–U14 | R18 | Section 3.4 |
| U15 | DR11 | A domain with more than `max_small_cells` of its values below `min_n` is disabled, and only that domain |
| U16 | DR12 | `needed_by` by hand for every row of 4.2 |
| U17 | R22 | `short_label`: fallback to the label, uniqueness, classed errors |
| K17 | DR9 | The first exhibit of the readiness report is D1 |
| K18 | DR10 | No exhibit of energy by domain; with no domain flagged, one sentence and no table D8 |
| K19 | R15 | Section 9.2; every figure layer has an interval or is the dumbbell panel of R3.2 or R3.4 |
| K20 | R16 | With `place` and `survey` set every title ends with them; without, no title ends with a separator |
| K21 | R17 | No precision column; every table has `n` in its note or as a column |
| K22 | R19 | A zero-event sentence comes between the title of its exhibit and its figure |
| K23 | R20 | A group with no content of a nutrient is in the note and in no row |
| K24 | R21 | The zero sentence lists exactly the nutrients with no household above the UL; the figure has only estimates above zero |
| K25 | R22 | Figures use short labels, tables labels; no iron row prints "—" |
| K26 | R23 | `choices$vehicles` restricts section 1; a scenario on a vehicle left out fails with its class |
| K27 | X1 | Size and structure of `hces_example`; calibration bands |
| K5, K7 | — | Replaced by K19 and by U11–U14 |

## 11. Dependencies

`tinytable` joins Suggests (template only), justified in its commit
message. Imports do not change. `ggplot2` and `tinytable` must be in the
environment's setup script, or the knit tests skip (section 1).

## 12. Commit plan (12d.1 onwards, Opus unless noted)

Each commit at most 300 lines of code, with its tests,
`devtools::test()` green and lint clean; `NEWS.md` with each exported
change.

| Step | Content |
|---|---|
| 12d.1 | P124: each page citation of IOM 1998 and 2001 in `data-raw/` re-read on the scanned page and corrected; md5 |
| 12d.2 | C1: `ref_presentation_standard` |
| 12d.3 | C2: `ci_method = "korn_graubard"`; column `ci_method` (U11, U12) |
| 12d.4 | C3: `flag_presentation()` (U13, U14) |
| 12d.5 | C6: `short_label`, label type `compound` (U17) |
| 12d.6 | C4, C5: dependency map; `domain_cells` in the checks and the verdict (U15, U16) |
| 12d.7 | C7, part 1: `example_foods.csv`; households and members of the generating script; the old dataset becomes a test fixture |
| 12d.8 | C7, part 2: acquisitions and user tables; data and its documentation; labels of the template; K27 |
| 12d.9 | X2: golden values on the new example and on the fixture |
| 12d.10 | Template machinery: `exhibits.csv`, exhibit object, titles, notes, `tinytable`, figure functions, new `choices` |
| 12d.11 | Readiness report, English (K17, K18) |
| 12d.12 | Readiness report, Spanish |
| 12d.13 | Results report, English (K19–K26) |
| 12d.14 | Results report, Spanish; wording pass of section 8 in both languages (Sonnet) |
| 12d.15 | Snapshot and registry tests (Q1, Q2) |
| 12d.16 | `docs/feedback/` (Q3); getting-started vignette with one `ggplot2` figure by domain (R23; English, Spanish in task 12); specification, `NEWS.md`, self-review; handoff for the maintainer's render on ENGIH 2018 (Q4) |

A step that would pass 300 lines is split. Stop and return to Fable if a
contract of sections 3 to 5 has to change, or if the published rows of
3.4 cannot be reproduced.

## 13. Decisions for the maintainer

Recommended option first.

1. **Table package.** *Recommended: `tinytable`* — no dependencies, HTML,
   PDF and Word, in Suggests. It is younger than `gt` and its API is not
   yet at 1.0, so it is called from one function only. Alternative: `gt`,
   mature and with 60 dependencies.
2. **Korn-Graubard interval.** *Recommended: the formula of C2 on the
   estimate and variance of `survey`, with the NCHS cap,* tested against
   `survey`, `binom.test()` and the published tables. Alternative:
   `svyciprop(method = "beta")` as it is, declaring that it departs from
   the standard where the design effect is below 1.
3. **Statistical review.** *Recommended: `choices$review = "show"` in the
   shipped template* (mark and reason), with `"suppress"` as the other
   value. The analyst is the clearance official of the standard.
4. **Estimators other than proportions (S1).** *Recommended: sample size
   and degrees of freedom only, interval always shown.* Alternative: keep
   a width limit set by the analyst for them.
5. **Opening of the results report.** P8 asks for the main findings
   first; P3 and R4 forbid sentences written by the template.
   *Recommended: figure R0 and a place for the analyst's findings.*
   Alternatives: a list of key figures generated from the tables; the
   figure alone.
6. **Effect of a scenario.** *Recommended: the two panels of 6.3,* which
   meet R15 and keep the dumbbell of R10f. Alternative: the dumbbell
   alone, with the interval in the appendix.
7. **The example.** *Recommended: replace `hces_example`; the present
   dataset becomes a test fixture.* Alternative: export both.
8. **Structure of the example** (7.1): 3 regions, 6 strata, 200 PSUs of
   10 households, five scenarios, four nutrients. *Recommended as
   written.* Say if a vehicle, a scenario or a nutrient (zinc) should be
   added.
9. **Thresholds as a shipped reference table** (C1), replaceable in
   `_inputs.R`. *Recommended.* Alternative: a list written in
   `_inputs.R` only.
10. **DR11.** *Recommended: `max_small_cells = 0.5`, cells counted on the
    households with an estimated intake against the `min_n` of the
    standard.*
11. **Unlinked share by domain.** *Recommended: the table of a domain
    variable is printed with all its values when at least one differs.*
    Alternative: only the rows that differ.
12. **Visible IDs** of 5.1 ("Figure R2.2", "Table D4"). *Recommended.*
13. **Upper-level sentence** with "in the sample", `n` and the upper
    limit (6.4). *Recommended.* Alternative: the plain sentence of R21.
14. **P124.** *Recommended: correct the page citations in 12d.1,* each
    after reading the scanned page.
15. **Getting-started vignette** in 12d.16, in English; its Spanish
    version with task 12. *Recommended.*
16. **Names.** `flag_presentation()`, `ref_presentation_standard`,
    `ci_method = "korn_graubard"`, columns `presentation`,
    `presentation_reason`, `n_effective`, `ci_width`,
    `ci_relative_width`, `complement_unreliable`, `short_label`; check
    `domain_cells`; choices `place`, `survey`, `vehicles`, `review`,
    `max_small_cells`.

## 14. Traceability

| Requirement | Where |
|---|---|
| P6 | 2, 3, 6.4 |
| P7, R15 | 6, 6.1, 9.2 |
| P8, DR9 | 4.1, 6.1 |
| P9 | 3.2, 5.5 |
| P10 | 5.1, 5.2, 9 |
| DR10 | 4.1 rows 6 and 7 |
| DR11 | 4.3 |
| DR12 | 4.2 |
| DR13 | 4.1 rows 2 and A |
| R16 | 5.3 |
| R17, R19 | 5.4 |
| R18 | 3 |
| R20 | 6.5 |
| R21 | 6.4 |
| R22 | 5.2, 6.2 |
| R23 | 5.2, 12 (12d.16) |
| R24 | 8 |
| X1, X2 | 7 |
| Q1–Q4 | 9 |
