# Analysis map: ENGIH 2018 → hcesfort

Output of roadmap task 0. It maps the original analysis
(`maicel1978/analisis_ENGIH2018`, branch `main`, commit `7caab91`) to the
package described in `docs/specification.md`. No package code is written in
this task.

What was read: `README.md`; `scripts/00`–`09`, `anexo_harina_maiz.R`,
`guardar_cifras_control.R` and the six `diagnostico_*.R`; every parameter file
in `data/raw/` (CSV and the five Excel workbooks, inspected sheet by sheet);
`data/auditoria/` including `cifras_control/`; `data/diagnosticos/`;
`reports/MANUAL_tecnico.qmd`, `reports/_comun.R` and the annexes of
`reports/INFORME_final.qmd`.

Second reading (2026-11-12, same commit): `reports/INFORME_factibilidad.qmd`,
the body of `reports/INFORME_final.qmd`, `reports/_metodo_densidad.qmd`,
`reports/_mapas_cobertura.qmd` and the prose of the two presentations. What it
changed is listed in section 9; E4 was withdrawn as an error and E1, E3, E7,
E10 and E24 were amended. The reports compute their figures when compiled, so
the figures themselves are not in the repository: those quoted in section 9
were supplied by the maintainer from the compiled documents.

What could not be checked: anything that needs the microdata. Findings whose
size depends on the microdata are marked **[needs microdata]**.

References are `script:lines` in the original repository at the commit above.

## 1. Pipeline at a glance

```
01 import      Q, unit factor, edible portion, crosswalk id   (per record, per section)
03 transform   g/day = Q × FC × EP / days ; flag outliers
04 AFE         energy requirement per member → AFE per household ;
               drop outliers ; g per AFE per day ; "exhaustion rule" flag
05 intake      composition (INCAP + FNDDS) → nutrients per record → per household
06 scenarios   unfortified baseline + added nutrient per scenario → per household
07 risk        EAR cut-point, iron probability, UL, density ; domains ; paired differences
08 groups      share of each food group in energy and micronutrients
09 maps        province choropleths
```

Sample sizes that recur below (from `README.md`, the control figures and
`data/diagnosticos/`): 8,892 households in the design file, 8,778 with an
intake estimate; Section 3A has 342,046 raw records, of which 281,761 reach the
"grams per AFE" table; Section 2 has 47,837, of which 46,478 do; 66 records are
then excluded as outliers (328,173 remain).

## 2. Step → package function

| # | Original step | Script:lines | Layer | Package function (specification) | Notes for the port |
|---|---|---|---|---|---|
| 1 | Download and md5 check of the raw files | `00:29-72` | adapter helper | `verify_md5()` (new, small) | The registry `fuentes_datos.csv` has empty `url` and `md5`: the check is not in force (see E16). |
| 2 | Read Section 2 (pantry stock) and Section 3A (daily acquisitions) | `01:89-145` | adapter | `engih2018_read()` → `acquisitions` | Column types forced by position; two unnamed/skipped columns. |
| 3 | Read members and design variables | `01:337-361`, `04:181-199` | adapter | → `members`, `households` | Design variables are taken with `first()` from the person file; constancy within household is not checked. |
| 4 | Resolve the unit to convert: presentation unit, else base unit | `01:271-278` | adapter | part of the adapter | ENGIH-specific questionnaire structure. |
| 5 | Unit → grams: universal dictionary first, food-specific table second | `01:173-186`, `01:383-388`, `01:420-425` | core + data | `convert_units()` | Core takes a conversion table keyed by `(unit)` or `(food, unit)`; the priority rule is an argument. Text join by description must become a join by code. |
| 6 | Guards on join tables (duplicate keys, empty keys) | `01:198-264` | core | contract validation (task 2) | Port as generic key-uniqueness and completeness checks. Source: `verificar_tabla_join()`. |
| 7 | Crosswalk survey food → composition id, validated rows only | `01:287-300`, `05:72-88` | data + core | `link_composition()` | Unvalidated rows must be counted in the audit log, not silently unmatched. |
| 8 | Edible portion | `01:309-325` | core | `link_composition()` (or a separate `apply_edible_portion()`) | Keyed by composition id in Sec 2 and by survey food in Sec 3A, because one composition id has two edible portions (`01:326-331`). The contract must key edible portion by survey food. |
| 9 | Reference period | `01:83`, `01:435-440`, `03:64-74` | adapter | `acquisitions$period_days` | Sec 2: constant 7. Sec 3A: number of distinct days with a record in the household, the adapter's default; 7 days as the option (see E4). |
| 10 | Daily grams = Q × FC × EP / days | `03:64-74` | core | `convert_units()` + `apparent_intake()` | Records with any missing factor become `NA` and are dropped later without a per-cause count (E3). |
| 11 | Record-level outlier flag | `03:95-107` | core | `flag_outliers()` (missing from the specification) | Flag only; the decision is a separate step. |
| 12 | Energy requirement per member and AFE | `04:76-163` | core + data | `compute_afe()` | Requirement table is reference data; age/sex coding is the adapter's job. |
| 13 | Household AFE and design variables | `04:181-199` | core | `compute_afe()` | `na.rm = TRUE` on members without AFE (E10). |
| 14 | Drop outliers and records without grams; grams per AFE | `04:234-245` | core | `apparent_intake()` | Three silent filters in one place. |
| 15 | "Exhaustion rule" for foods in both sections | `04:258-308` | adapter | section-combination rule (roadmap task 6) | Entirely ENGIH-specific: depends on question 9 of Sec 2 and on the final stock. The core only needs an `include` flag per record. |
| 16 | Read and harmonise INCAP and FNDDS | `05:51-144` | adapter / data-raw | composition table in the standard schema | Column matching by pattern because FNDDS headers contain line breaks. |
| 17 | Fill composition gaps | `05:151-170` | data-raw + core | documented imputation table; `fill_composition()` | Two rules: explicit borrowed values, and B12/D = 0 for unprocessed plant foods. |
| 18 | Nutrients per record and per household, four section variants | `05:183-219` | core | `apparent_intake()` | Main estimate: both sections, exhaustion rule on. |
| 19 | Energy plausibility flag | `05:225-229` | core | `flag_energy_plausibility()` or an argument of `apparent_intake()` | Flag only; used as sensitivity analysis. |
| 20 | Composition coverage and list of unmatched foods | `05:260-299` | core | audit log of `link_composition()` | Currently computed after the unmatched records were dropped (E3). |
| 21 | Assign vehicle to each food; flour fraction of derived products | `06:58-67`, `vehiculos_escenarios.csv` | data + core | `apply_scenario()` input: vehicle table keyed by food code | Regex on descriptions is ENGIH-specific and fragile. |
| 22 | Unfortified baseline: replace iron and folate of enriched foods | `06:69-91` | core | `apply_scenario()` (replacement of enriched foods) | See E6 for the simplification it makes. |
| 23 | Vehicle coverage and consumption; combined reach | `06:94-164` | core | `vehicle_coverage()` (missing from the specification) | Coverage, mean among all, median among consumers, reach of "at least one of". |
| 24 | Added nutrient per scenario; intake per household and scenario | `06:176-197` | core | `apply_scenario()` | mg/kg → unit per 100 g; folic acid → DFE × 1.7. |
| 25 | Scenario summary, folic acid above UL, Q5/Q1 ratio | `06:202-221` | core | `estimate()`, `above_ul()` | |
| 26 | EAR cut-point | `07:88-108`, `07:134-138` | core | `inadequacy(method = "ear_cutpoint")` | |
| 27 | Iron probability approach | `07:48-51`, `07:111-115`, `07:140-147` | core + data | `inadequacy(method = "iron_probability")` | Bioavailability as an argument; requirement distribution as reference data. |
| 28 | Above UL, on the added form for folate and vitamin A | `07:102-106` | core | `above_ul()` | The form the UL applies to must be a column of the reference table, not a `case_when` on nutrient names. |
| 29 | Nutrient density per 1,000 kcal; critical density | `07:107`, `diagnostico_densidad_critica.R` | core | `nutrient_density()` (missing from the specification) | The reports rely on it for geographic comparison. |
| 30 | Estimation by domain with the complex design; precision flag | `07:117-175` | core | `estimate()` | Precision rule (n < 50 or CI half-width > 10 pp) as arguments. |
| 31 | Paired differences between scenarios | `07:227-273` | core | `paired_difference()` | Mean of the within-household difference under the design. |
| 32 | Food-group shares | `08` | core (v0.2) | `food_group_shares()` | Known error E1. |
| 33 | Maps | `09` | out of the core | vignette or v0.2 | Depends on `sf`, `biscale`, `cowplot`; geometry is country-specific. |
| 34 | Maize-flour annex (coverage only) | `anexo_harina_maiz.R` | — | covered by `vehicle_coverage()` | |
| 35 | Control figures | `guardar_cifras_control.R` | test | acceptance test (task 10) | |

Not ported: `02_eda.R` (exploratory, depends on `dlookr`), the
`diagnostico_*.R` scripts (one-off evidence for decisions; their conclusions
are recorded in section 3), the Quarto reports.

## 3. Methodological decisions and thresholds

| Decision | Value | Script:lines | Source given in the original | Status |
|---|---|---|---|---|
| Reference period, Sec 2 | 7 days | `01:83` | survey design (stock on day 1 and day 8) | adapter parameter |
| Reference period, Sec 3A | distinct days with a record, per household (median 7, min 1, max 8) | `01:435-437`, `03:69-73` | own decision, tested in the feasibility report (table `tbl-pm`) | **kept as the default**; the design length (7 days) is the alternative option. See E4 |
| Sec 2 quantity | question 9, "consumed by the household from the initial stock" | `01:377` | questionnaire | adapter |
| Unit priority | universal factor over food-specific factor | `01:388`, `01:425` | own decision: 15 specific rows are inflated ×1000 | core argument |
| Food-specific factors | median of the reported package content per food × unit | `data_raw_unidades.xlsx` (`nota` column) | derived from the microdata; some verified at point of sale (one shop, one day) | adapter data; E19 |
| Volume → mass | 1 ml = 1 g for every liquid | `data_raw_unidades.xlsx`, sheet `diccionario_conversion` | "water density" | E18 |
| Crosswalk | only rows with `validado == TRUE` | `01:390`, `01:427`, `05:74` | own validation log | data |
| Edible portion | INCAP `EDIBLE`; 1.00 for FNDDS foods | `food_factors.xlsx`, `01:302-325` | INCAP; FNDDS assumed as consumed | data |
| Outlier detection | per composition id and section, n ≥ 20: grams/day > 5 × P99.5 or < P0.5 / 5 (and > 0) | `03:95-107` | none ("same rule as in the audit") | no source |
| Outlier treatment | exclude | `04:240` | report annex B | 66 records |
| AFE reference | woman 18–30 y, 55 kg, PAL 1.76 → 2,290.8 kcal | `04:117-139` | FAO/WHO/UNU 2004, table 5.2 and section 5.3 | verify in task 3 |
| Adult body weight | 65 kg men, 55 kg women | `04:118-119` | "methodological document" (not in the repository) | no verifiable source |
| Children 1–17 y | 34 values by age and sex, moderate activity | `04:76-112` | FAO/WHO/UNU 2004, tables 4.2 and 4.3 | verify in task 3 |
| Infants < 1 y | 649 kcal boys, 600 kcal girls (mean of 12 monthly values) | `04:144` | FAO/WHO/UNU 2004, section 3 | verify in task 3 |
| Pregnancy, lactation | not applied (not asked by the survey) | `04:38-44` | — | documented limitation |
| Members without age or sex | contribute 0 AFE | `04:186` | — | E10 |
| Section combination | Sec 2 + Sec 3A, minus Sec 3A acquisitions of 16 storable foods when the household still holds initial stock on day 8 | `04:258-308` | own decision; `diagnostico_solapamiento.R` | adapter |
| Composition basis | per 100 g edible portion, both tables | `05:36-39`, `05:186` | **assumed, not verified** (author's note) | verify in task 3 |
| INCAP units for Zn, B12, D, E | INFOODS tag units | `05:7-10` | **assumed, not verified** (author's note) | verify in task 3 |
| Missing nutrient value | counts as zero | `05:208` | manual: "intake is a floor" | must be audited per nutrient |
| Gap filling | 9 borrowed values; B12 and D = 0 for 4 plant food groups | `05:151-170`, `composicion_relleno.csv` | each row carries its donor food | data |
| Energy plausibility | 500–6,000 kcal per AFE per day; flag, do not exclude | `05:225-229` | none | no source |
| Citable central value | median, not mean | `05:231-232` | own decision | reporting |
| Unfortified rice and flour | INCAP 70213004 and 70213038 | `06:35-36` | INCAP | scenario parameter |
| Flour fraction of derived products | bread 0.7, pasta 1.0, crackers 0.85, biscuits 0.6, pastry 0.4 | `vehiculos_escenarios.csv` | none; marked `provisional` | no source |
| Baseline of derived products | iron and folate := flour fraction × unenriched flour | `06:80-90` | own decision, annex A.3 | E6 |
| Folic acid → DFE | × 1.7 | `06:42-43`, `07:103` | not cited | cite in task 3 |
| Vitamin A level → RAE | 1 mg/kg = 100 µg RAE per 100 g (level read as retinol) | `06:42-43` | not cited | E8 |
| Scenario levels | 7 scenarios, mg/kg | `escenarios_fortificacion.csv` | RTD 616 (two secondary sources agree; text not consulted), NORDOM 602, national rice proposal (ministry slide), WHO 2009 (B12 and vitamin A rows marked `por_confirmar`) | verify in task 3 |
| Baseline scenario for comparisons | "1a" (national standard applied to flour and bread, full compliance) | `07:63-65` | own decision | scenario parameter |
| Losses in storage and cooking | none | `06:20-21` | documented limitation | v0.2 |
| EAR and UL | IOM, women 19–30 y | `valores_referencia.csv` | edition named, no table or page | verify in task 3 |
| Iron requirement distribution | 13 percentiles, 18% bioavailability | `hierro_requerimiento.csv` | "IOM", no table or page | verify in task 3 |
| Iron bioavailability | 10% main, 18% sensitivity; requirement scaled by 0.18 / b | `07:48-51`, `07:112` | not cited | argument |
| Iron probability tails | 1 below P2.5, 0 above P97.5, linear in between | `07:113-114` | not cited | document |
| UL for folate and vitamin A | applied to the added amount only | `07:102-106` | IOM definition of the UL | E7 |
| Domains | national, region, zone, quintile (design domains); province (not a design domain) | `07:58-59` | survey documentation | adapter |
| Scenarios by domain | only the baseline scenario is disaggregated | `07:159` | own decision | argument |
| Precision flag | n < 50 households or CI half-width > 10 pp | `07:60-61`, `07:171` | none | no source |
| Variance | Taylor linearisation, PSU nested in stratum | every `as_survey_design()` call | survey design | core |
| Differences between scenarios | paired within household | `07:213-226` | own derivation | core |
| Food groups | 10 MDD-W groups plus 6 extra categories | `agrupacion_alimentos.csv` | FAO 2021 | v0.2 |

Hypotheses tested and discarded by the original analysis (manual, chapter
"Hipótesis evaluadas y descartadas"): household size, section split, exhaustion
rule and observed days do not explain the provincial pattern of risk; own
production does not either. Recorded energy varies between provinces for
reasons unrelated to diet, which is why the reports prefer nutrient density
for geographic comparison.

## 4. Generic and ENGIH-specific

**Generic (core).**
Grams = quantity × unit factor × edible portion ÷ days. Flagging outliers
separately from deciding what to do with them. AFE from an energy requirement
table. Linking to a composition table through a crosswalk, with coverage.
Household intake per AFE per day. Additive scenarios on an unfortified
baseline, with flour fractions for derived products. EAR cut-point, iron
probability approach, UL on a named form of the nutrient, nutrient density.
Design-based estimation by domain with a precision rule. Paired differences
between scenarios. Vehicle coverage and combined reach.

**Reference data (shipped, each with its source).**
Energy requirements (FAO/WHO/UNU 2004). EAR and UL (IOM). Iron requirement
distribution. WHO 2009 flour levels. The DFE and RAE conversion factors.

**ENGIH-specific (adapter and its data).**
File and sheet names, column positions and types. Household id built as
dwelling + household. Presentation unit versus base unit. The unit catalogue
and its factors. The food-specific factors. The crosswalk to INCAP/FNDDS and
the edible-portion table. Question 9 of Section 2, the day-8 stock and the
exhaustion rule with its 16 storable foods. Sex coding (1/2), zone derived
from the stratum label, province names. National scenarios (RTD 616,
NORDOM 602, rice proposal) and the regular expressions that assign vehicles.
The food-group assignment.

**Country data that is neither core nor adapter.**
The harmonised INCAP + FNDDS composition table. It is large, has its own
licence terms, and Peru will use another table. It belongs in `data-raw/` of an
adapter or in a companion data package; see `docs/improvements.md`.

## 5. Parameter files and where they go

| File | Content | Destination |
|---|---|---|
| `valores_referencia.csv` | EAR, UL, method, source | reference data (task 3), plus a column for the form the UL applies to |
| `hierro_requerimiento.csv` | iron requirement percentiles | reference data (task 3) |
| `escenarios_fortificacion.csv` | 105 rows: scenario × vehicle × nutrient × level | WHO 2009 rows → reference data; national rows → ENGIH adapter example. Normalise: one row per scenario × vehicle group × nutrient |
| `vehiculos_escenarios.csv` | vehicle, regex, flour fraction | adapter: vehicle table keyed by food code |
| `parametros_normativos.csv` | national standards with verification status | adapter documentation; not used by code |
| `composicion_relleno.csv` | borrowed composition values | adapter `data-raw/` |
| `agrupacion_alimentos.csv` | food → grouped food → MDD-W group | adapter (v0.2) |
| `crosswalk_tablas_composicion.xlsx` | survey food → composition id | adapter `data-raw/`; free-text notes contain personal names and must be cleaned |
| `food_factors.xlsx` | edible portion | adapter `data-raw/` |
| `data_raw_unidades.xlsx` | unit dictionary, universal and specific factors | adapter `data-raw/` |
| `food_composition_INCAP.xlsx`, `food_composition_FNDDS.xlsx` | composition tables | adapter `data-raw/`, licence to be confirmed |
| `fuentes_datos.csv` | url and md5 of the microdata | adapter; currently empty |
| `provincias_*`, `entregables_estado.csv` | maps, project management | not ported |

## 6. Errors and inconsistencies found

Severity: **A** changes published figures or their interpretation; **B** can
change them, size unknown without the microdata; **C** fragile or misleading
but probably harmless. Every item has a matching proposal in
`docs/improvements.md`.

### Errors

- **E1 (A, confirmed). Food-group shares use the enriched composition.**
  `08:39-49` joins `composicion_unificada.csv` directly. The unfortified
  baseline of `06:74-91` is not applied, so enriched rice (INCAP 70213002: iron
  4.36 mg, folate 386 µg DFE per 100 g, against 0.8 and 9 unenriched), enriched
  pasta and breads enter with US-style enrichment. `grupos_micronutrientes.csv`
  in the control figures gives cereals 81.6% of folate and 66.1% of iron; both
  are overstated. Already listed in `CLAUDE.md` as a known error. The final
  report states that the shares are "computed on the scenario without
  fortification" (`INFORME_final.qmd:607-608`, caption of the figure at
  `:553`): the text describes the intended method, the code does not apply
  it.
- **E2 (B, confirmed in the parameter file). A dozen is converted as 12 grams.**
  Unit 52 "Docena" has `FC = 12` with method "Conteo" and the remark "needs the
  unit weight". `01:173-176` keeps every non-missing `FC` as a universal factor
  in grams, and the universal factor has priority over the food-specific one.
  Any record declared in dozens gets 12 g per dozen. **[needs microdata]** for
  the number of records affected.
- **E3 (A, confirmed). Composition coverage is measured after the unmatched
  records were removed.** A record without a validated crosswalk row has no
  edible portion in Sec 2 (joined by composition id) and usually none in Sec 3A
  (`food_factors.xlsx` lists 407 of 769 foods), so its grams are `NA` and
  `04:240` drops it. `05:260-279` then computes coverage on the survivors: the
  result is close to 100% by construction and `alimentos_sin_composicion.csv`
  is empty. The manual states that unmatched foods "contribute zero" and that
  coverage is "weighted by grams"; neither describes the code. About 60,000
  Sec 3A records (18%) never reach the intake estimate; 36,840 of them for lack
  of a composition match (README), the rest for lack of a unit factor, quantity
  or household AFE. The pipeline keeps no count per cause; the feasibility
  report does compute one when compiled (`INFORME_factibilidad.qmd:390-404`,
  through `marcar_elegible()` of `reports/_comun.R:313-323`), with a
  hierarchical attribution (quantity, then unit factor, then composition, then
  edible portion), so a record that lacks both a factor and a match is counted
  under "no conversion factor". That report names the missing factor as the
  main cause; the README counts 36,840 records without a match. Both can be
  true under the hierarchy, and the package's audit log must therefore count
  causes without a hierarchy (one count per cause, plus the overlap). The most
  frequent food of Sec 3A (bouillon cube, 18,087 records) is among the
  unmatched. The per-nutrient coverage of the reports (final report,
  `fig-cobertura`; feasibility report, `tbl-cob-nutriente`) is likewise
  computed on the surviving records.
- **E4 (withdrawn as an error, 2026-11-12; kept as a documented choice). The
  Sec 3A divisor is the number of days with at least one record.**
  `01:435-437` counts distinct days with a record and `03:69-73` divides by
  it. The first reading called this an overstatement, on the argument that a
  day without purchases is a day of zero acquisition. That reading missed the
  test the original analysis had made: the feasibility report
  (`INFORME_factibilidad.qmd:286-322`, table `tbl-pm`) sets out both
  interpretations (observed for fewer days, or observed seven days with no
  purchase on some) and compares median energy per AFE by number of days with
  a record. The median is flat: 2,050 kcal with 1 day and 2,189 kcal with
  7 days (figures of the compiled report, supplied by the maintainer). If the
  divisor inflated intake, households with few days would show a higher
  median; they do not. **Decision of the maintainer:** the default reference
  period of Sec 3A is the number of days with a record; the design length
  (7 days) stays as an explicit option of the adapter.
  What remains open, to be measured with the microdata **[needs microdata]**:
  (a) the same table with the energy of Sec 3A alone, because the test uses
  the energy of both sections and Sec 2 is divided by a constant 7, which
  dilutes any effect of the divisor; (b) the upper tail by number of days: the
  same report attributes 349 of the 572 households above 6,000 kcal to bulk
  purchases concentrated on one day (`:795-805`), which is the pattern the
  divisor would amplify without moving the median; (c) what a divisor of 8
  means in a 7-day diary (`tbl-pm` filters to 7 or fewer).
- **E5 (B, confirmed). Households without retained records leave the risk
  denominator but stay in the coverage denominator.** 8,892 households are in
  the design; risk is estimated on 8,778 (`07:93-96` inner joins). Vehicle
  coverage (`06:100`) and the maize annex keep all 8,892 as non-consumers. The
  114 households are neither reported nor classified (no food acquired, or all
  records lost in E3). In addition the subset is taken before the design is
  declared (`07:158` for the energy-plausible subset too), instead of
  estimating a domain within the full design.
- **E6 (B, methodological). The unfortified baseline of derived products keeps
  only the flour.** `06:80-90` sets iron and folate of bread, pasta, crackers,
  biscuits and pastry to flour fraction × unenriched refined flour. The iron
  and folate of the other ingredients (eggs, milk, yeast, sugar) are discarded,
  and whole-grain items (`harina integral`, `pan integral`, `galletas
  integrales`) receive refined-flour values. The baseline of these foods is
  biased downwards and the limitation is not documented.
- **E7 (A, interpretation). The share above the UL is described as an upper
  bound and is not one.** `07:102-106` compares only the amount added by the
  scenario with the UL. Preformed retinol already in the diet (liver, dairy,
  eggs; INCAP has a `RETOL` column that is not read) and folic acid in foods
  fortified outside the scenario (FNDDS has a `Folic acid` column) are ignored.
  The reference file, the manual and the final report
  (`INFORME_final.qmd:417-420`, `:886-890`) call the result a "cota máxima";
  for vitamin A it is a lower bound.
- **E8 (B, unverified basis). The vitamin A level is read as retinol.**
  `06:42-43` converts mg/kg to µg RAE one to one. `parametros_normativos.csv`
  records the sugar standard with the compound "palmitato de retinol" and does
  not say whether 10 mg/kg is retinol or the ester. If it is the ester, the
  RAE added is about 55% of what scenario 1c assumes (molecular-weight ratio,
  to be verified). Scenario 1c moves the median from 289 to 698 µg RAE, so the
  basis matters. The same question applies to the WHO 2009 vitamin A rows
  (marked `por_confirmar`) and, for iron, to compound versus elemental iron.
- **E9 (C). Outliers are detected on household grams per day**, not per AFE or
  per capita (`03:95-107`), so large households are flagged more easily.
  Quantiles are unweighted, computed within section, and records without a
  composition id form one group.
- **E10 (B). Members without age or sex count as zero AFE** (`04:186`,
  `na.rm = TRUE`), which inflates the household's intake per AFE. Only a
  message is printed; the author lists it as pending. The feasibility report
  states that the AFE was computed for every household, "with no member
  without an assigned energy requirement" (`INFORME_factibilidad.qmd:488-489`,
  next to a table computed at compile time). If so, the defect is in the code
  and has no effect on the ENGIH figures; severity falls to C once the
  microdata confirm it. **[needs microdata]**
- **E11 (C). Exhaustion rule with missing final stock.** `04:292-298` sums
  `cantidad_final` without `na.rm`; a missing value makes the comparison `NA`
  and the household is treated as having no stock, silently. Quantities in
  different units are summed (only the sign is used).

### Inconsistencies

- **E12. Two definitions of the wheat vehicle.** `reports/_comun.R` (regex
  `TRIGO_INCLUIR` / `TRIGO_EXCLUIR`) and `vehiculos_escenarios.csv` used by
  `06`. Coverage in the reports and in the scenarios can differ.
- **E13. `escenarios_resumen.csv` repeats folate-only columns on every
  nutrient row** (`06:231`): `pct_folico_sobre_ul`, `folato_q1`, `folato_q5`
  and the ratio appear on the iron, zinc, B12 and vitamin A rows.
- **E14. The folic acid UL is defined twice**: constant in `06:44` and row in
  `valores_referencia.csv`.
- **E15. Documentation that no longer matches the code.** The header of `01`
  says Sec 3A is the main source and Sec 2 is used only for net availability;
  the code sums both, and the final report repeats that Sec 3A "is the main
  source" (`INFORME_final.qmd:284-285`). The final report says coverage
  "weighted by grams accompanies the results" (`:347-350`); it is computed on
  the surviving records (E3). The manual says Sec 2 consumption is "deduced from the
  difference" of stocks; the code uses question 9. `01` reports 168 rows with
  encoding damage in the Sec 3A unit sheet; the versioned workbook has none
  and now carries a food code that the join does not use (`01:421-424` still
  joins by description). The manual lists "reference values pending
  confirmation" as a limitation while the file marks all of them `adoptado`.
- **E16. The md5 check is not in force.** `fuentes_datos.csv` has no url and no
  md5 for either microdata file. The control figures cannot be tied to a
  specific version of the input.
- **E17. Unchecked joins.** Sec 2 edible portion by composition id (`01:393`),
  the same key that fans out in Sec 3A (`01:326-331`); crosswalk joins without
  a uniqueness guard (`01:389-392`, `01:426-429`); `04:243` inner join drops
  records of households missing from the member file without a count;
  `08:45-48` drops households the same way.
- **E18. Liquids are converted with the density of water**, including oil, which is lighter than water and a fortification vehicle in
  other countries. Its grams are overstated.
- **E19. The package content declared in each record is discarded.** The
  food-specific factor is the median of `contenido_empaque_presentacion` per
  food × unit; several rows are marked low-confidence in the workbook itself
  (for example oil by "bottle" = 113.4 g, "bimodal pattern").
- **E20. Crosswalk rows that deserve review.** 114 validated Sec 3A rows have
  no equivalence type; 8 validated rows are typed `requiere_revision`; live
  chickens are matched to an FNDDS cooked-chicken code with edible portion 1.0;
  `Habichuelas blanditas` (2,708 records) is matched to "green beans, cooked".
  FNDDS describes foods as consumed, while the survey records purchases.
- **E21. Missing composition values weigh on vitamins D and E.** INCAP lacks
  vitamin E for 489 of 1,466 foods, vitamin D for 412, folate for 281, B12 for
  233, zinc for 202. They count as zero. The reported 95.8% (vitamin D) and
  82.7% (vitamin E) of households below the EAR are partly an artefact, and
  the per-nutrient coverage is not among the control figures.
- **E22. Food-group shares ignore the design and mix denominators.** `08:63-68`
  computes weighted shares without standard errors, on households with
  consumption only, and shares the per-AFE total rather than the national
  nutrient supply.
- **E23. Maize flour is treated as unfortified** although the national
  standard is recorded as mandatory; the standard's text was not available and
  its units are inconsistent (documented in `anexo_harina_maiz.R`).
- **E24. Confidence intervals.** Proportions use symmetric intervals, which
  can leave [0, 100] at the extremes; the share above the UL and the medians
  have no interval; `significativa` is derived from 336 pairwise intervals
  without adjustment. No option is set for strata with a single PSU. The final
  report says the intervals use the *t* distribution with the degrees of
  freedom of the corresponding subdesign (`INFORME_final.qmd:289-291`); task 11
  must reproduce that choice in acceptance step 1 and state its own.
- **E25. AFE counts every listed member** as if all ate every meal at home,
  while food eaten away from home is not in the numerator. Intake per AFE is
  biased downwards for households that eat out more (urban, higher quintiles).
  Declared only partly in annex A.2.
- **E26. Reproducibility.** No lockfile; scripts start with `rm(list = ls())`;
  `LEEME.txt` of the control figures records the R version and commit
  (`d56fc70`) but not package versions.

### Hard-coded values without a verifiable source

Outlier thresholds (5 ×, P0.5 / P99.5, n ≥ 20); energy plausibility limits
(500 and 6,000 kcal); adult body weights (65 and 55 kg); flour fractions; iron
bioavailability of 10% as the main assumption; precision rule (50 households,
10 pp); the 1.7 DFE factor (correct convention, not cited); INCAP and FNDDS
edition and download date (the FNDDS title row is truncated and the year is
not recorded).

## 7. Control figures and the acceptance test

`data/auditoria/cifras_control/` (generated 2026-10-23, commit `d56fc70`,
R 4.6.1) holds six aggregated files:

| File | Rows | Content | Reproducible by a corrected package? |
|---|---|---|---|
| `riesgo_inadecuacion.csv` | 800 | % below EAR / iron probability, CI, CV, % above UL, median density; 7 scenarios nationally, baseline by region, zone, quintile and province; all households and energy-plausible | only if E2, E5 and E10 are reproduced as they are (the divisor of E4 is the default, not a legacy option) |
| `diferencias_escenarios.csv` | 336 | paired differences for every ordered pair of scenarios | same |
| `escenarios_resumen.csv` | 35 | median and mean intake by scenario, folic acid above UL, Q5/Q1 | same |
| `escenarios_consumo_vehiculos.csv` | 3 | coverage and consumption of rice, sugar and wheat | same |
| `grupos_micronutrientes.csv` | 16 | food-group shares | no: E1 is fixed by design |
| `anexo_harina_maiz.csv` | 8 | maize flour coverage | same as the first four |

Consequence: the acceptance test cannot both reproduce these figures and fix
the errors above. The proposal in `docs/improvements.md` (P1) is a two-step
test: first reproduce the original figures with the original choices exposed
as explicit options, then change each default that is an error and record the
shift in `NEWS.md`.

## 8. Open points for the maintainer

The questions of task 0 were answered on 2026-11-12; the answers are in the
section "Decisions (2026-11-12)" of `docs/improvements.md`.

## 9. Second reading: what the other reports add (2026-11-12)

Findings changed: E4 withdrawn; E1, E3, E7, E10, E15 and E24 amended above.
No other finding changes. New material for the package, none of it an error
of the original:

| Source | What it says | Consequence for the package |
|---|---|---|
| `INFORME_factibilidad.qmd:286-322` | Test of the Sec 3A divisor by days with a record. | E4. The adapter documents its rule for `period_days`; the core takes the column as given. |
| `INFORME_factibilidad.qmd:795-805` | The outlier rule works per food; 572 households exceed 6,000 kcal per AFE per day: 223 from the overlap of sections (before the exhaustion rule existed), 349 from bulk purchases on one day. A household-level check is proposed and never built. | `flag_outliers()` needs a household-level scale as well as a record-level one (task 6); the energy-plausibility flag of task 8 is that check. |
| `INFORME_factibilidad.qmd:650-684` | The crosswalk was built by assisted candidate generation and manual review; the review found errors in 9 of 148 assignments, of three recurring kinds: part of the food, state of preparation, degree of processing. | Evidence for the quality controls of the food-matching module (proposal P42). |
| `INFORME_factibilidad.qmd:856-892` | Each section alone gives about 1,200 kcal per AFE per day; only the sum is plausible. | Confirms that `include` and `section` belong in the acquisitions contract; no change. |
| `INFORME_factibilidad.qmd:91-114`, `:893-965` | Three earlier scenarios built by substituting composition codes; superseded by the seven additive scenarios. | Not ported. |
| `INFORME_factibilidad.qmd:1120-1125` | Design variables: 8 strata, 933 PSUs, expansion factor without missing values. | Check for the adapter (task A2). |
| `_metodo_densidad.qmd` | Critical density = EAR / reference energy × 1,000. The density criterion replaces the absolute criterion only where the variation of recorded energy is an artefact (between provinces), not where it is real (between quintiles, where it inverts the gradient); it stops discriminating for nutrients whose intake follows energy (vitamin E); it assumes multiplicative over-recording; iron is excluded. | `nutrient_density()` (task 8) returns the density and the critical density and documents these limits; it does not turn density into a prevalence by default. |
| `INFORME_final.qmd:429-439` | The quintile is the survey's own `QUINTIL`; the variable used to rank households is not documented. | Adapter documentation. |
| `INFORME_final.qmd:945-955` | Seven explanations of the geographic variation examined and discarded; unit factors of non-standard units remain as a possible origin. | None for the core; noted for the adapter. |

The presentations and `_mapas_cobertura.qmd` repeat the figures and caveats of
the reports and add no method.
