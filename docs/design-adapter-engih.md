# Design of the ENGIH 2018 adapter and of the acceptance test

Status: **written 2026-11-16 (Fable); waiting for approval** (eight
decisions, section 9). No package code was changed and no microdata were
opened. Brief: `docs/adapter-design-brief.md`. Implemented in the companion
repository `hcesfort.engih2018` (Opus), after approval.

Inputs read: `docs/roadmap.md` (A1 to A4, 12e.5), `docs/analysis-map.md`,
`docs/specification.md`, `docs/design-12e5.md`, section 5.5 of
`docs/review-v0.2.md`; in `analisis_ENGIH2018` (commit `7caab91`): scripts
`00`, `01`, `03` to `08`, `anexo_harina_maiz.R`, `guardar_cifras_control.R`,
`diagnostico_procedencia.R`, `reports/_comun.R`, the six control files, the
parameter files of `data/raw/` and the sections of the manual and of the
feasibility report on the source and on unused variables.

What was **run** in this session (section 10 says how): the control files
and the parameter workbooks were analysed with R; the options of step 1 were
tried on `hces_example` against `srvyr`; the export script of A1 was run on
invented stand-in files. Anything that depends on the microdata is marked
**[needs microdata]** and has a row in the export of A1.

## 0. Summary: what the reading changed

| # | Finding | Evidence | Consequence |
|---|---|---|---|
| 1 | The intervals of the control figures use **925 degrees of freedom in all 800 rows**, provinces and the energy-plausible subset included. The feasibility report and the help of `estimate_households()` say "those of the subdesign". | `t = half-width / (cv × estimate)` gives 925.0 in every row of `riesgo_inadecuacion.csv`; 925 = 933 PSUs − 8 strata | Step 1 uses `df = "design"`, not the default. The help sentence is wrong (P188). E24 is amended. |
| 2 | With `ci_method = "mean"` and `df = "design"` the package gives the numbers of `srvyr` exactly: proportion by domain, subset, mean, median among consumers with its interval, paired difference. With `df = "domain"` it does not. | Run on `hces_example`; largest difference 0, and 7e-4 under `"domain"` | The estimation layer needs no change for step 1. |
| 3 | **New error E27.** 37 of the 75 foods that the vehicle patterns select have no validated composition match. The original drops their records before anything else, so they are missing from vehicle coverage and from every scenario: 1,284 of 36,352 records of wheat products (3.5%), 653 of 1,338 of pastry. | Patterns of `vehiculos_escenarios.csv` applied to the 799 descriptions; `freq_registros` of the crosswalk | Step 1 needs a vehicles table limited to matched foods; step 2 uses all 75. |
| 4 | **New error E28.** The original counts a household as a consumer of a vehicle when its grams are above zero; a record without unit factor or with quantity zero is non-consumption. `vehicle_coverage()` counts the record. | `06:104`, `?vehicle_coverage` | In step 1 the test derives the indicator from the grams; step 2 uses `acquired`. |
| 5 | **E29 (declared in the manual, missing from the map).** Section 3A records the household's share of an acquisition (`PORCENTAJE_HOGAR`), its destination and who paid (`QUIEN_PAGO1`: own production is code 2). The chain reads and discards them. | `MANUAL_tecnico.qmd:99-118`, `diagnostico_procedencia.R` | `origin`, `household_share` and `fortifiable` have a source in the survey. |
| 6 | Infants: the original uses the rounded means 649 and 600 kcal; the package table gives 649.42 and 600.42. A household with one infant differs by 1.8e-4 AFE. | Run: 2.527183 against 2.527002 | Step 1 passes an `energy` table with the rounded values. |
| 7 | The food-specific unit factors of Section 3A are joined **by description**, and five rows that carry the weight of one piece (eggs 53 g, garlic 3 g, bread 50 g, onion 148 g) have no food code at all; one Section 2 factor (liquid milk, 1,000) is applied through a **missing unit** matched to a missing key. | `data_raw_unidades.xlsx`; `dplyr` joins match `NA` to `NA` | The adapter resolves descriptions to codes and gives the missing unit an explicit code. |
| 8 | Several fears of the map do not materialise in the versioned tables: no fan-out by composition id in Section 2 (30 ids, all unique); every food without a validated match has no edible portion (407 rows = 407 rows), so E3 is exact; E2 touches 13 records; no food factor competes with a generic one, so `priority` decides nothing; every composition id belongs to one vehicle, so the baseline by composition row equals the original's baseline by survey food. | Section 10 | Fewer legacy options than expected; four invariants for the tests of the companion repository. |
| 9 | Two original choices cannot be reproduced through an option today, both in the outlier flag (group size counted on rows; edible against purchased grams in one group of 1,349 records). | `03:95-107`, `?flag_outliers` | A1 measures whether they matter; nothing is changed before that (section 4.4). |
| 10 | No published worked example of apparent intake from an HCES with **data, code and results** was found. The closest has data and results and no code. | Section 8 | No end-to-end external test in v0.1; a candidate for v0.2 (P196). |

## 1. Mapping

### 1.1 Source files

| File | Sheet | Rows (original analysis) | Key |
|---|---|---|---|
| `Registros_Cuestionario_B.xlsx` | `Cuest. B Sec 2` (pantry stock, days 1 and 8) | 47,837 | none; a row is a food held by a household |
| | `Cuest. B Sec 3A` (daily acquisitions, 33 columns, the 14th unnamed) | 342,046 | none; `VIVIENDA`, `HOGAR`, `DIA`, `ORDEN` to be checked **[needs microdata]** |
| `Sociodemograficas_e_ingresos.xlsx` | `Base` (one row per person) | 8,892 households | `VIVIENDA`, `HOGAR`, `MIEMBRO` |

Both are read with every column as text and typed by name; the number of
rows and of columns and the column names are checked against a registry
(`hcesfort_error_schema` otherwise). The original types Section 3A by
position.

### 1.2 `households` (8,892 rows expected)

| Column | From | Rule | Check |
|---|---|---|---|
| `household_id` | `VIVIENDA`, `HOGAR` (person file) | `"<vivienda>_<hogar>"`; `HOGAR` repeats between dwellings | unique |
| `weight` | `FACTOR_EXPANSION` | constant within the household | error if not constant (the original takes `first()`); > 0 |
| `stratum` | `ESTRATO` | as is | 8 values |
| `psu` | `UPM` | as is, nested in the stratum | 933 pairs; codes in several strata counted |
| `region` | `GRUPO_REGION` | domain of the survey | 4 values |
| `area` | `DES_ESTRATO` | `rural` when the label contains "Rural", else `urban` | every label recognised |
| `quintile` | `QUINTIL` | the survey's own variable, as text; its ranking variable is not documented | 5 values |
| `province` | `DES_PROVINCIA` (`ID_PROVINCIA`) | not a design domain | 32 values |

`food_module_response` is not set: the files have no such variable.
Households without any record get the status `no_food_records`.

### 1.3 `members`

| Column | From | Rule |
|---|---|---|
| `household_id` | as above | every member's household is in `households` (1 to many, no orphan) |
| `member_id` | `MIEMBRO` | unique within the household |
| `age_years` | `A403` | completed years; missing stays missing |
| `sex` | `A402` | 1 `male`, 2 `female`, anything else missing and counted |

**What the survey does not record.** Age in months (an infant is "0
years"), pregnancy, lactation, breastfeeding, body weight, meals taken at
home. The original author checked the dictionary sheet of the person file
for pregnancy and lactation (`04:38-44`); the adapter repeats that check on
the dictionary when A2 is written **[needs microdata]**. Consequences, all
decided in `docs/design-12e5.md`: `infants = "annual_mean"`,
`infant_food_share = 1` (R3-D2), no `pregnant` or `lactating` column, adult
weights by argument (65 and 55 kg, no verifiable source: analysis map,
section 3).

### 1.4 `acquisitions`

| Column | Section 2 | Section 3A |
|---|---|---|
| `record_id` | `"S2-<row>"` | `"S3A-<row>"`: the row of the sheet, stable because the file is fixed by md5 |
| `household_id` | `VIVIENDA`, `HOGAR` | the same |
| `food_code` | `"S2:<VARIEDAD>"` | `"S3A:<ID_VARIEDAD>"` |
| `quantity` | `CONSUMO_EXCLUSIVO_HOGAR` (question 9: consumed from the initial stock) | `CANTIDAD_ADQUIRIDA` |
| `unit` | presentation unit, else base unit; `no_unit` when both are missing | the same |
| `section` | `sec2` | `sec3a` |
| `period_days` | 7 | days with a record in the household (option, 1.5) |
| `include` | `TRUE` | `FALSE` when the exhaustion rule marks it (1.6) |
| `origin` | missing (a stock has no recorded origin) | from `QUIEN_PAGO1` (1.7) |
| `household_share` | 1 (the question asks what the household consumed) | `PORCENTAJE_HOGAR / 100` (1.7) |
| `fortifiable` | missing | from `origin` (1.7) |
| `outlier_group` | composition id of the validated match (extra column, for 4.2) | the same |

The two sections have **two code lists that overlap** (code 1 is `PANES` in
Section 2 and `Pan de agua` in Section 3A), hence the prefix. In
`agrupacion_alimentos.csv` the description is one to one with the code
(30 + 769 foods, no repeated description, and equal to the crosswalk's);
A1 confirms it on the records (`e01_descripciones`).

The unit of a record is the original's `resolver_unidad()`: the
presentation unit when present (about 36% to 41% of the rows), else the
base unit. `no_unit` exists because the original converts Section 2 liquid
milk without any unit at 1,000 per unit of quantity through a missing key
(finding 7); A1 counts those records (`sin_unidad_con_fc`).

`expenditure_lcu` (`MONTO_TOTAL`, with `MONEDA`) is not needed by A1 to A4
and waits for the readiness report (P197).

Non-foods: 11 validated crosswalk rows are typed `no_alimento_excluir`
(purified water alone has 5,937 records in volume units). They never
reached the original's intake. Decision 6: the adapter drops them with a
count.

### 1.5 `period_days` of Section 3A

| Option of the adapter | Rule | Use |
|---|---|---|
| `days = "with_record"` | distinct values of `DIA` in the household | default (E4, decision of 2026-11-12) |
| `days = "design"` | 7 | sensitivity |
| `days_missing = "count"` | a missing `DIA` counts as one more day: what `n_distinct()` does in `01:437` | step 1 |
| `days_missing = "ignore"` | missing days are not a day; a household with only missing days is an error | step 2 |

Whether any `DIA` is missing is **[needs microdata]** (`e03_dia_faltante`).
If none is, the two last options are the same and the second is dropped.

### 1.6 `include`: the exhaustion rule

Ported from `04:258-308`, by code instead of by regular expression: a table
`storable.csv` (key, section, `food_code`) lists the 16 keys; it is built by
a `data-raw/` script from the original patterns, and a test checks that the
patterns applied to the descriptions give the table (18 of the 30 Section 2
foods and 68 of the 769 Section 3A foods are storable). A Section 3A record is not
included when its food has a key and the household's Section 2 rows of that
key have a positive sum of `CANTIDAD_FINAL`.

| Option | Rule | Use |
|---|---|---|
| `stock_missing = "no_stock"` | a missing `CANTIDAD_FINAL` makes the sum missing and the household is treated as without stock (E11) | step 1 |
| `stock_missing = "known"` | the sum of the known values; rows with a missing value counted | step 2 |
| `sections = "both_exhaustion"`, `"both"`, `"sec2"`, `"sec3a"` | the four variants of `05:212-219` | main, and the three comparisons |

The rule looks only at Section 2 rows, whatever their unit factor or
outlier flag: it does not depend on any package step, so the adapter can
set `include` before `convert_units()`.

### 1.7 Origin, share and the fortifiable vehicle

`QUIEN_PAGO1` (dictionary quoted in `diagnostico_procedencia.R`): 1 the
household; 2 own production; 3 taken from the household's business; 4 payment
in kind; 5 and 6 gifts from another household (abroad, national); 7 to 10
gifts and transfers from NGO, public institutions, firms; 11 health
insurance; 99 other.

| Column | Rule | Open |
|---|---|---|
| `origin` | `purchase` (1), `own_production` (2), `own_business` (3), `in_kind` (4), `gift` (5 to 10), `other` (11, 99), missing | codes outside the list are an error |
| `fortifiable` | `FALSE` when `origin` is `own_production`; missing when `origin` is missing (all Section 2); `TRUE` otherwise | whether the place of purchase (`ID_TIPO_ESTABLECIMIENTO`) should refine it: decision 4 |
| `household_share` | `PORCENTAJE_HOGAR / 100`; missing stays missing (the record then has no grams, `missing_household_share`) | how many are missing or zero **[needs microdata]** (`e_participacion`) |

Step 1 reproduces the original by leaving `household_share` out of the
table and by `fortifiable = "ignore"`. The rule for `fortifiable` is the
definition of `docs/design-12e5.md`, section 2.1: the vehicle "is processed
industrially". Goods taken from the household's shop or received as a gift
are industrial products like those bought. Section 2 stock has no origin,
so its vehicle records count as fortifiable and are flagged
(`fortifiable_unknown`): the log will show how many grams that is.

### 1.8 Tables supplied alongside

All come from `analisis_ENGIH2018/data/raw/`, converted once to CSV by
scripts in `data-raw/`, registered by md5, with the free-text notes cleaned
of personal names (the unit and crosswalk workbooks contain them).

| Table | Source | Rows | Key and rules |
|---|---|---|---|
| `unit_factors`, generic | sheet `diccionario_conversion` with a factor | 11 | `unit`; mass units `mass_g`; millilitre, litre, cc, gallon, *botellón* `volume_ml`; dozen: see 4.1 |
| `unit_factors`, by food | sheets `Cuest. B Sec 2` (84 rows with a factor) and `Cuest. B Sec 3A` (626) | 710 | `unit` + `food_code`; Section 3A rows resolved from the description to the code, the five rows without a code included; `source` from `validacion` and `nota` |
| `crosswalk` | `crosswalk_tablas_composicion.xlsx` (30 + 769 rows), `food_factors.xlsx` | 799 | `food_code`; edible portion by composition id in Section 2 (30 unique ids) and by food in Section 3A (407 rows) |
| `composition` | INCAP (1,466 rows) and FNDDS 2017-2018 (7,083 rows) | 8,549 | `composition_id` (no id is in both tables: the original stops if one is); eight nutrient columns; `retinol_ug` (INCAP `RETOL`, FNDDS `Retinol`), `folic_acid_ug` (FNDDS only) |
| fills | `composicion_relleno.csv` (9), and the rule "vitamins B12 and D are 0 in four groups of unprocessed plant foods" written out row by row | 9 + generated | applied with `fill_composition()` |
| `enrichment` | built from the vehicle of each food (4.3) | 44 | `composition_id` + nutrient |
| `vehicles` | `vehiculos_escenarios.csv` applied to the descriptions, frozen as codes; maize flour for the annex | 75 + 2 | `food_code` + vehicle; fractions `SOURCE PENDING` (marked `provisional` in the original) |
| `food_groups` | `agrupacion_alimentos.csv` | 799 | `food_code` |
| `scenarios` | `escenarios_fortificacion.csv` | 105 | scenario + vehicle + nutrient; `level_basis = "nutrient"`, `form` `folic_acid` and `retinol`, compliance 1 |
| requirements | `valores_referencia.csv` (7 nutrients), `hierro_requerimiento.csv` (13 percentiles) | | passed by argument in step 1 (they include vitamin D, and vitamin E has no upper level there) |

Two repairs the contracts force, both counted with `audit_record()`:
114 validated Section 3A rows have no equivalence type (E20) and get
`match_type = "not_recorded"`; 13 rows are marked validated and have no
composition id (the 11 non-foods, one row "to review" and one without
equivalent) and become `validated = FALSE`.

Not verified, as in the original (analysis map, section 3): that both
composition tables are per 100 g of edible portion, and the INCAP units of
zinc and of vitamins B12, D and E. `basis` is written `per_100g_edible`
with `# SOURCE PENDING` in `data-raw/SOURCES.md` until the documentation of
both tables is opened (A2).

## 2. A1: control figures

### 2.1 Before anything: tie the figures to the files

The six control files of 2026-10-23 were produced with microdata whose md5
was never recorded (E16). So the first act of A1, by the maintainer:

1. Compute the md5 of the two files at hand and write them in
   `data/raw/fuentes_datos.csv` (with the two download addresses, section 6).
2. Run the original chain and `guardar_cifras_control.R` again.
   `git diff data/auditoria/cifras_control/` must show only `LEEME.txt`.

If the six files change, the files at hand are not those of October and
the acceptance test has no reference: stop and say so.

### 2.2 The export script

`scripts/exportar_cifras_etapas.R`, written in this session and pushed to
the branch `claude/intelligent-cori-3aev98` of `analisis_ENGIH2018`. Base R
and `readxl`. It changes nothing of the chain; it reads `data/clean/` and,
for the variables the chain discards, the Section 3A sheet. It writes 21
aggregated tables and a `LEEME.txt` (date, commit, `sessionInfo()`) to
`data/auditoria/cifras_control/etapas/`, and refuses to write if a table
has a household, dwelling or member column.

It was run here on invented files with the columns the chain writes (it
cannot be run on the real ones); the totals of four tables were recomputed
independently and agree. **It has never met the microdata**: an error on
the first real run is likely to be a column name, and is to be reported,
not worked around.

```r
# in analisis_ENGIH2018, after the chain 01 to 08 and anexo_harina_maiz.R
source("scripts/exportar_cifras_etapas.R")
```

| File | Content | Used by |
|---|---|---|
| `e00_entradas` | md5 and size of the two microdata files and of every parameter file | registry, section 6 |
| `e01_registros` | per section: records, households, without quantity, quantity zero, without unit (and of those converted), factor generic, by food, none, without match, without edible portion, with grams, flagged; grams per day purchased and edible | units, link |
| `e01_causas_cruce` | per section: records by combination of the four causes of loss | E3: causes without a hierarchy |
| `e01_descripciones` | codes, descriptions and pairs per section | finding 7 |
| `e_e2_docenas` | records in dozens, by food | **open check of E2** |
| `e_e18_volumen` | records and grams in volume units, oil apart | E18 |
| `e03_dias`, `e03_dia_faltante` | households by days with a record; records without a day | **open check (c) of E4**; 1.5 |
| `e03_atipicos` | per section: groups, groups with 20 rows and fewer than 20 values, flagged records, of which in such groups and in the group of two edible portions | 4.4 |
| `e04_afe` | persons without age, sex or AFE; infants by sex; households with such a member, with AFE zero, with records and no person, without records; distribution of the household AFE; strata, PSUs, PSU codes in several strata, design variables not constant in a household | E10, E17, A2 |
| `e04_gramos_por_ema`, `e04_agotamiento` | per section: records and households kept, marked as stored, grams per AFE; Section 2 rows without final stock | E11, the rule of 1.6 |
| `e05_ingesta` | for each of the four section variants and eight nutrients: households, median, mean, weighted median and mean, household total per day (intake × AFE), households above 6,000 and below 500 kcal | intake; the conservation check |
| `e05_cobertura` | per nutrient: used records without a value, foods without a value, share of grams with a value | E21 |
| `e06_vehiculos` | per vehicle and for maize flour: records, households with a record, records without match, without factor, with quantity zero, records used, households with grams, grams | E27, E28 |
| `e06_escenarios` | per scenario and nutrient: households, sums of baseline, added and total | scenarios |
| `e07_diseno` | households, PSUs, strata and strata with one PSU: frame, with intake, energy-plausible | finding 1 |
| `e_e4_energia_por_dias` | by days with a record: households, median energy in total, **Section 3A alone** and Section 2 alone, 95th percentile of Section 3A, households above 6,000 kcal | **open checks (a) and (b) of E4** |
| `e_procedencia`, `e_establecimiento` | vehicle by who paid, and by type of shop: records, with grams, grams | `fortifiable`, decision 4 |
| `e_participacion` | records by household share; grams if the share were applied; records and grams destined to a business | E29, decision 5 |

The two files of A1 the roadmap names and this list does not repeat, "AFE
distribution" and "median intake per nutrient", are `e04_afe` and
`e05_ingesta`.

### 2.3 What the open checks decide

| Check | Reading |
|---|---|
| E2 | The parameter workbook already counts 12 records in dozens in Section 3A (sour lime 4, passion fruit 3, sea crab 3, green banana 1, orange 1) and 1 in Section 2. `e_e2_docenas` should say the same; if it does, E2 changes no national figure visibly. |
| E4 (a) | If the median energy of Section 3A alone is flat across days with a record, the divisor stands. If it falls as days rise, the divisor inflates intake and the default must be reopened (stop, Fable). |
| E4 (b) | Households above 6,000 kcal concentrated at one or two days with a record: the amplification the feasibility report describes; it feeds the sensitivity run with 7 days. |
| E4 (c) | Households with 8 days: what the eighth is (a diary of seven days closed on the eighth, or a missing day counted, 1.5). |

## 3. The original choices as explicit options

Each row is one choice of the original. "Where" is an option of
`engih2018_options()` in the adapter (which changes a table or a column) or
an argument of a package function. Step 1 uses the second column for every
row; step 2 moves one row at a time to the third (section 5).

| # | Choice | Step 1 (original) | Corrected or default | Where | Map |
|---|---|---|---|---|---|
| S1 | Days of Section 3A | with a record; missing day counted | with a record; missing ignored | adapter `days`, `days_missing` | E4 |
| S2 | Unit priority | `"generic"` (decides nothing: no record has both) | the same | `convert_units(priority)` | P59 |
| S3 | Dozen | generic `mass_g`, 12 | `count`, 12, weight of a piece by food | adapter `dozen` | E2 |
| S4 | Liquids | `volume_ml` with `density_g_ml = 1` | density by food, each with its source | adapter `density` | E18 |
| S5 | Household share | column absent | `household_share` from the survey | adapter `share` | E29 |
| S6 | Outlier flag | `by = c("section", "outlier_group")`, `scale = "household"`, `level = "record"`, `probs = c(0.005, 0.995)`, `multiplier = 5`, `min_group = 20`, `type = 7`; `outliers = "exclude"` | the same (decision 7) | `flag_outliers()`, `apparent_intake()` | E9 |
| S7 | Members without age or sex | `missing_members = "zero"` | `"na"` | `adult_equivalents()` | E10 |
| S8 | Energy requirements | package table with the 24 infant rows replaced by 649 (boys) and 600 (girls); adults 65 and 55 kg, PAL 1.76; reference `reference_energy("female", 25, 55, pal = 1.76)` | package table | `adult_equivalents(energy =)` | finding 6 |
| S9 | Infants | `infants = "annual_mean"`; `infant_food_share = 1` | the same; one sensitivity run | `adult_equivalents()` | R3-D2 |
| S10 | Section rule | exhaustion; missing final stock is no stock | exhaustion; known values | adapter `sections`, `stock_missing` | E11 |
| S11 | Baseline | `method = "replace_by_ingredient"` with the 44 legacy rules | `"subtract"` with reference pairs | `unfortified_baseline()`, adapter `enrichment` | E6 |
| S12 | Vehicles | the 38 foods with a validated match | all 75 | adapter `vehicles` | E27 |
| S13 | Fortifiable | `fortifiable = "ignore"` | `"use"` | `vehicle_coverage()` | P159 |
| S14 | Consumer of a vehicle | grams above zero; a household without records is a non-consumer | `acquired`; missing stays missing | computed in the test | E5, E28 |
| S15 | Levels | `level_basis = "nutrient"`; vitamin A as retinol | by the text of each standard | adapter `scenarios` | E8 |
| S16 | Requirements | the original's two files | `ref_requirements`, `ref_iron_requirements` | `inadequacy(requirements =)` | |
| S17 | Iron | probability, bioavailability 0.10 and 0.18 | the same | `inadequacy(bioavailability =)` | |
| S18 | Upper level | folate and vitamin A on the added amount; the rest on the total | total of the form, diet included | which column of `above_ul()` is estimated | E7 |
| S19 | Gates | `min_coverage = 0`, `min_records_used = 0` | thresholds of the analyst | `inadequacy()`, `above_ul()` | E3, E21 |
| S20 | Energy plausibility | 500 to 6,000 kcal, bounds included; as a subset | the same, as a domain | `flag_energy_plausibility()`, `domain_from` | |
| S21 | Intervals | `ci_method = "mean"`, `df = "design"`; `lonely_psu = "fail"` | `"korn_graubard"` or `"logit"`; `df` by decision | estimators | E24 |
| S22 | Food-group shares | composition as it is (an `enrichment` table without rows) | on the baseline | adapter `enrichment` | E1 |
| S23 | Precision | `min_n = 50`, `max_half_width = 0.10` | presentation standard | `flag_precision()` | |
| S24 | Compliance model | `"average_content"` (compliance is 1 everywhere, so the model decides nothing) | the same | `apply_scenario()` | |

The chain of step 1, with the tables of section 1:

```r
o <- engih2018_options("original")
s <- engih2018_survey(dir, o)        # households, members, acquisitions
t <- engih2018_tables(o)             # the tables of 1.8
grams <- convert_units(s$acquisitions, t$unit_factors, priority = "generic") |>
  flag_outliers(by = c("section", "outlier_group"), scale = "household",
                level = "record", probs = c(0.005, 0.995), multiplier = 5,
                min_group = 20)
afe <- adult_equivalents(s$members, reference_kcal = ref, pal = 1.76,
                         weight_kg = c(female = 55, male = 65),
                         infant_food_share = 1, energy = t$energy,
                         infants = "annual_mean", missing_members = "zero")
comp <- fill_composition(t$composition, t$fills)
base <- unfortified_baseline(comp, t$enrichment,
                             method = "replace_by_ingredient")
intake <- link_composition(grams, t$crosswalk, base) |>
  apparent_intake(afe, s$households, outliers = "exclude")
use <- vehicle_coverage(grams, t$vehicles, afe, s$households,
                        outliers = "exclude", fortifiable = "ignore")
scen <- apply_scenario(intake, use, t$scenarios,
                       compliance_model = "average_content",
                       baseline_label = "0. Sin fortificación")
```

`infant_food_share` and `fortifiable` are the arguments of 12e.5; the
adapter is written after steps 12e.5.1 and 12e.5.3 (R3-D8).

## 4. A3, step 1: figure by figure

### 4.1 Tolerances

| Kind of figure | Tolerance | Why |
|---|---|---|
| Counts (records, households, `n`) | exact | integers |
| Percentages, their limits, differences in points | 1e-6 absolute on the 0 to 100 scale | the specification; both sides call `survey` on the same values |
| `cv`, shares in [0, 1] | 1e-8 absolute | the same on the other scale |
| Medians and means of intake, grams, densities | 1e-6 absolute | the specification; the largest are a few thousand, and double arithmetic leaves about 1e-12 |
| Sums over records or households (stage files) | 1e-9 **relative** | a sum of 1e8 grams differs by 1e-4 between two orders of addition; an absolute 1e-6 would fail for no reason |
| `precision_baja`, `significativa` | equal | logical, derived |

Where rounding can still bite: the original passes every intermediate
table through a CSV file, so a value may differ from the package's in its
last digit. That moves a percentage only if a household sits on a
threshold. The test therefore counts, on the package side, the households
within a relative 1e-9 of each EAR, upper level and plausibility bound;
with none, a difference of one household's weight share (about 0.01 point)
cannot be rounding and is a real disagreement.

### 4.2 The six control files

`est()` stands for `estimate_households(design, x, value, ..., ci_method =
"mean", df = "design")` and `dif()` for `estimate_difference(..., df =
"design")`, on `as_hces_design(households, lonely_psu = "fail")`.
Exception (found in A3.3, P237): a median *with an interval* takes
`df = "domain"`. `srvyr::survey_median()` passes no degrees of freedom,
and `survey::svyquantile()` then takes those of the households of the
group with a value; only `survey_mean()` takes those of the whole design.
It concerns the medians among consumers of `escenarios_consumo_vehiculos`
and `anexo_harina_maiz`; the other medians have no interval.

| File, rows | Column | Package |
|---|---|---|
| `riesgo_inadecuacion`, 800 | `pct_inadecuado` and limits, `cv`, `n` | `est(inadequacy(scen, ...), "p_inadequate")`, nationally for the 7 scenarios, and `by` region, area, quintile and province for scenario 1a; rows "Energia plausible" with `domain_from = flag_energy_plausibility(intake, "energy_kcal", 500, 6000)`. `cv` is `se / estimate`. |
| | `pct_sobre_ul` | `est()` of `above_ul_added` for folate and vitamin A and of `above_ul_total` for the rest; missing where there is no upper level |
| | `densidad_mediana` | `est(nutrient_density(...), statistic = "median")`, households with energy above zero |
| | `semiamplitud_ic`, `precision_baja` | derived; `flag_precision(min_n = 50, max_half_width = 0.10)` |
| `diferencias_escenarios`, 336 | `dif_pp` and limits, `n` | `dif()` with each of the 7 scenarios as reference. The 130 rows whose difference is exactly zero have limits 0 in the original and no interval in the package (`no_variation`): the test requires estimate 0 and that note. `significativa` is derived in the test. |
| `escenarios_resumen`, 35 | `mediana`, `media` and limits | `est(scen, <nutrient>, statistic = "median")` and `"mean"` |
| | `pct_folico_sobre_ul`, `folato_q1`, `folato_q5`, ratio | `above_ul_added` of folate; median of folate `by = "quintile"`; the ratio derived. The original repeats them on every nutrient row (E13): compared once per scenario. |
| `escenarios_consumo_vehiculos`, 3 | coverage and limits, mean among all, median among consumers and limits | rows `group` (wheat) and `vehicle` (rice, sugar) of `use`; indicator and grams as in S14: `g = coalesce(qty_vehicle_g_d, 0)`, consumer `g > 0`, median of `g` where `g > 0` |
| `anexo_harina_maiz`, 8 | the same, by area and quintile | the vehicle `maize_flour` |
| `grupos_micronutrientes`, 16 × 7 | share of each group | `food_group_shares()` on the chain with S22; estimates only (the original has no interval). Records without a group are dropped by the original and are `unclassified` in the package: A1 gives their number, expected 0. |

All 800 + 336 + 35 + 3 + 8 + 16 rows are compared, not a sample.

### 4.3 The stage files, and the baseline rules

Before the six files, the test compares the stages in order and stops at
the first that differs: `e01_registros` with the log and `grams_status` of
`convert_units()` and the status of `link_composition()`; `e03_atipicos`
with the log of `flag_outliers()`; `e04_afe` with `adult_equivalents()`;
`e04_gramos_por_ema` with the records used; `e05_ingesta` with
`apparent_intake()` on the four section variants and the composition
without baseline; `e06_vehiculos` and `e06_escenarios` with `use` and
`scen`; `e07_diseno` with the design.

The 44 legacy rules of `enrichment` (S11), one for iron and one for folate
per composition row of a vehicle food:

| Vehicle | Composition rows | Unenriched reference | Fraction |
|---|---|---|---|
| Rice | 70213002, 70213004 | 70213004 | 1 |
| Wheat flour | 70213038, 70213158 (whole grain) | 70213038 | 1 |
| Bread | 8 rows | 70213038 | 0.7 |
| Pasta | 70213057, 70213060, 70213169 | 70213038 | 1 |
| Crackers | 3 rows | 70213038 | 0.85 |
| Biscuits | 70214002 | 70213038 | 0.6 |
| Pastry | 70214127, 70218005, FNDDS 53116000 | 70213038 | 0.4 |

Sugar has no rule (the original leaves it as it is). The original applies
the rule by the vehicle of the survey food; the package by composition
row. They are the same here because every composition row has one vehicle;
the only row shared with a food that is not a vehicle is 70213038 (flour,
and the food "Trigo"), which is its own reference at fraction 1. None of
the 22 rows lacks iron or folate.

### 4.4 What the package cannot reproduce today, and what to do

| # | Original | Package | When it matters | What to do |
|---|---|---|---|---|
| U1 | A group is assessed when it has 20 **rows** | 20 **values** with grams | only if a record is flagged in a group of 20 rows and fewer than 20 values (`atipicos_en_grupos_con_menos_de_20_valores`) | If the count is 0, nothing. Otherwise stop: the choice is an argument of `flag_outliers()` or a documented difference (Fable, maintainer). |
| U2 | The flag is computed on **edible** grams | on **purchased** grams | The rule is relative, so it is the same wherever a group has one edible portion: every group but one, composition row 70211088 (pigeon peas in the pod 0.48, shelled 1.00; 1,349 records) | Compare the flagged records of that group (`atipicos_guandu`). If they differ, as U1. |
| U3 | Zero difference with limits 0 | no interval | 130 rows | Rule of comparison (4.2). No change. |
| U4 | Coverage "by grams" computed after the loss (E3) | coverage over all records | never in a control file | Not reproduced; `e05_cobertura` is compared with the same quantity computed in the test from the records used. |
| U5 | Subset taken before the design is declared (E5, E24) | domain of the full design | only if a PSU has no household in the subset or a stratum keeps one PSU; the 925 degrees of freedom of every row say that none does, given 933 PSUs and 8 strata | `e07_diseno` confirms it. If a PSU were lost, standard errors would differ in the eighth digit or more: then compare estimates at 1e-6 and standard errors against a direct `survey` call in the test. |

Nothing in this table justifies a change of the package before A1 is
read. If U1 or U2 bite, the affected records are a handful of the 66
flagged, and the stage comparison says exactly which.

Stop rule for the implementing session (`docs/model-routing.md`): a figure
that disagrees after the stages agree, with no household on a threshold,
is "a result that disagrees with the original and the reason is not
obvious": stop and hand over to Fable. Do not widen a tolerance.

## 5. A4, step 2: one correction per commit

Each commit moves one row of section 3, runs the whole chain, and writes
old and new national figures in `NEWS.md` of the companion repository (and
the full aggregated tables in `inst/acceptance/steps/<id>/`). "Old" is the
state after the previous commit, so each change is attributable. The
expected direction is written **before** the run; a result outside it is a
finding, not a figure to record.

Order: upstream first. Rough sizes come from the parameter files and the
control figures; "A1" means the size is in the export.

| Order | Error | Correction | Expected direction and size | A surprise is |
|---|---|---|---|---|
| 1 | E16, E26 | md5 registry; versions recorded | no figure | any change |
| 2 | E12 to E15, E17, E22 (no interval) | one vehicles table, one requirements table, tidy output, checked joins | no figure. E17: `con_registros_y_sin_modulo` of A1 says whether a household was ever dropped by the inner join | any change |
| 3 | E3, E21 | coverage over all records; `missing_values()`; gates set by the maintainer | intake unchanged. Reported for the first time: about 10.8% of Section 3A records without a validated match (36,833 of 342,039 by the crosswalk's own counts; the README says 36,840), and the grams they weigh. Vitamins D and E flagged by their coverage (INCAP lacks vitamin E for a third of its rows) | a share of unlinked records away from 10.8%; intake moving |
| 4 | E2 | dozen as `count` with a piece weight | 13 records. No national figure moves by 0.01 point | more |
| 5 | E18 | density by food | Oil is declared by volume in most of its Section 2 rows (3,369 in gallons) and 634 of Section 3A. Its grams fall by the density (about 8%, value `# SOURCE PENDING`). Energy and vitamin E fall slightly (oils and fats carry 68.2% of vitamin E); the share below the EAR of vitamin E rises; nothing else moves beyond 0.5 point | iron, folate, zinc, B12 or vitamin A intake changing; vitamin E rising |
| 6 | E10 | `missing_members = "na"` | The feasibility report says no member lacks a requirement: no change. `e04_afe` says how many | any change contradicts the report |
| 7 | E11, S1 | known final stock; missing days ignored | More records marked as stored: intake falls or stays. Fewer days: intake of those households rises. Sizes: A1 (`registros_sin_cantidad_final`, `registros_sin_dia`) | the opposite sign |
| 8 | E29 | `household_share` | Intake falls by the factor `g_dia_si_se_aplicara / g_dia_total` of A1 on average; shares below the EAR rise. The manual calls it small | a rise in intake |
| 9 | E27 | all 75 vehicle foods | Wheat coverage (91.8%) rises by less than 1 point; wheat flour per AFE (mean 46.9 g) rises by 1% to 3%; iron and folate added by scenarios 1a to 3 rise in proportion; shares below the EAR under those scenarios fall by less than 0.5 point; scenario 0 unchanged | any fall in coverage or grams; scenario 0 moving |
| 10 | E5, E28 | `acquired`; households without records outside the denominator | Coverage rises: at most 114 / 8,892 from the denominator (rice 85.5% to at most 86.6%) plus the households of `hogares_con_registro_y_sin_gramos`. Risk figures unchanged (same 8,778 households), now with the 114 counted by status | risk figures moving |
| 11 | P159 | `fortifiable = "use"` | Added amounts fall by the own-production grams of each vehicle (`e_procedencia`, code 2); baseline unchanged; `acquired_fortifiable` at most `acquired` | a rise; baseline moving |
| 12 | E6 | `"subtract"` with pairs: rice 70213002 against 70213004, flour 70213039 (enriched, all purpose) against 70213038; no rule for the three whole-grain rows | Every baseline cell is at least its legacy value (the floor of `"subtract"` is the legacy value), so baseline iron and folate rise or stay, and the shares below the EAR at scenario 0 fall or stay. Iron: about +0.35 mg per 100 g of bread, a few tenths of a mg per day. Folate: most bread cells hit the floor, little change. Amounts added by scenarios unchanged | any baseline cell below its legacy value; added amounts moving |
| 13 | E1 | shares on the baseline | Cereals lose share in folate (81.6%) and iron (66.1%). With `T_e` the mean on the composition as it is (`e05_ingesta`) and `T_b` the baseline mean (280.0 µg DFE; 11.28 mg): the new share is about `1 − (1 − 0.816) × T_e / T_b` for folate and `1 − (1 − 0.661) × T_e / T_b` for iron. Zinc, vitamins A, B12, D and E: shares identical to 1e-6, since the baseline touches only iron and folate | another nutrient moving; a cereal share rising |
| 14 | E7 | upper level on the total of the form (diet retinol, diet folic acid) | Shares above the upper level rise or stay in every scenario (they were lower bounds: folic acid from 0% at baseline to 8.0% in scenario 3). Never fall | a fall |
| 15 | E8 | level basis by the text of each standard | **The largest uncertainty of the analysis.** If the 10 mg/kg of the sugar standard are retinyl palmitate, the vitamin A added by scenario 1c is roughly halved and its median (698 µg RAE against 289 at baseline) falls towards the EAR of 500. Run both readings as sensitivity until the text of NORDOM 602 is read; the ratio of molecular weights is `# SOURCE PENDING` | — |
| 16 | E24 | package intervals; `df` | Every point estimate identical to 1e-6. Intervals: inside 0 to 100 (23 rows had a limit outside); medians and upper-level shares gain one; with `df = "domain"` province intervals widen | a point estimate moving |
| 17 | S8, S16 | package energy table and requirements | AFE of a household with an infant +0.0002: nothing visible. Vitamin E gains the package's upper level | any visible change from S8 |

Not corrected in v0.1, stated in the adapter's documentation: E9 (the
outlier rule is kept, decision 7), E19 (declared package content: A1
measures how many records have one; P198), E20 (crosswalk rows to review:
data decisions of the maintainer, each its own commit when taken), E23
(maize flour has no scenario), E25 (meals away from home are not in the
survey), E4 (kept as the default; the 7-day run is reported as
sensitivity).

Step 2 has no reference (review v0.2, section 5.5). The directions above
are its only check, which is why they are written first.

## 6. Download and reproducibility

**Source.** `reports/INFORME_factibilidad.qmd:246-252` gives the public
page: Banco Central de la República Dominicana, *Encuesta Nacional de
Gastos e Ingresos de los Hogares (ENGIH) 2018* [microdata],
`https://www.bancentral.gov.do/a/d/4796-engih-2018`. The host is outside
this session's network, so the page was **not opened**: the addresses of
the two files and the terms of use are `# SOURCE PENDING`. The maintainer
copies the two addresses, as the page gives them, with the date.

**Registry.** `inst/extdata/sources.csv`: `file`, `url`, `md5`, `bytes`,
`kind` (`microdata`, `parameter`), `consulted`, `note`. The md5 of the
microdata come from `e00_entradas` of A1, so the registry, the control
figures and the stage figures name the same files.

**Functions** (in the adapter; `hcesfort` keeps only the generic md5
check):

| Function | Does |
|---|---|
| `engih2018_data_dir()` | the directory of the microdata: the environment variable `ENGIH2018_DATA`, else `tools::R_user_dir("hcesfort.engih2018", "data")`. Never a path inside the repository, except `data-raw/private/` |
| `engih2018_download(dir)` | for each microdata row: download if absent (`mode = "wb"`), then md5; a mismatch is an `hcesfort_error_md5` that names both sums and tells the reader the source may have republished the file. Ported from `scripts/00_descargar_datos.R` |
| `engih2018_verify(dir)` | md5 of what is there, without network; called first by `engih2018_survey()` |

**Never committed.** `.gitignore` has `data-raw/private/`, `*.xlsx` and
`*.dta` outside `inst/extdata/`; a test that runs in CI walks the files
tracked by git and fails on a file above 5 MB, on any tracked file whose
md5 is a microdata md5 of the registry, and on a CSV with a column named
like a household or person identifier outside the test fixtures.

**Versions.** `renv.lock` in the companion repository (E26); each
acceptance run writes `sessionInfo()` next to its figures, as the
specification asks.

## 7. The companion repository `hcesfort.engih2018`

An R package, under the rules of `CLAUDE.md` (size limits, classed errors,
checked joins, English).

```
DESCRIPTION            Imports: hcesfort, readxl, dplyr, rlang, cli
R/sources.R            registry, download, md5
R/read.R               the three sheets, typed by name, counts checked
R/households.R  R/members.R  R/acquisitions.R
R/period.R  R/sections.R  R/origin.R      rules of 1.5, 1.6, 1.7
R/tables.R             engih2018_tables(): the tables of 1.8
R/options.R            engih2018_options(): the choices of section 3
R/survey.R             engih2018_survey(dir, options): validated tables
inst/extdata/          parameter tables as CSV, sources.csv, storable.csv
inst/acceptance/       the six control files, etapas/, steps/<id>/
data-raw/              scripts from the original workbooks; SOURCES.md;
                       private/ (ignored)
tests/testthat/        below
```

`engih2018_options()` has two presets, `"original"` and `"corrected"`, and
prints every choice; a single option is changed with
`modifyList()`-style arguments, which is how step 2 moves one row at a
time. Each choice the adapter applies is written in the audit log with
`audit_record()`.

| Runs in CI (no microdata) | Runs only locally (`ENGIH2018_DATA` set) |
|---|---|
| Every parameter table passes its `validate_*()` | `engih2018_verify()` |
| The invariants of finding 8: unique composition ids in Section 2; one vehicle per composition row; edible portion 1 for every matched vehicle food; no food factor on a unit with a generic factor | `validate_survey()` on the real tables; the counts of 1.1 and 1.2 |
| The frozen code tables equal the original patterns applied to the descriptions (vehicles, storable foods) | Step 1: the stage files, then the six control files (section 4) |
| The mapping rules on hand-built data frames of invented households: unit resolution, `no_unit`, days, exhaustion rule with and without a missing stock, origin, share | Step 2: each correction against its expected direction (section 5) |
| Options: both presets are complete; an unknown option is an error | |
| No microdata in the repository (section 6) | |
| `R CMD check`, lint, size limits | |

The acceptance tests are skipped, with a message, when the variable is not
set; they are never skipped silently on the maintainer's machine, because
the handoff of each acceptance step quotes their count.

## 8. An end-to-end external anchor

Searched: published worked examples of apparent intake from an HCES whose
data and results are both available. Opened in this session:

| Candidate | Data | Code | Results | Usable |
|---|---|---|---|---|
| Kalimbira et al. 2025, *Nutrients* 17(15):2485, doi:10.3390/nu17152485 (PMC12348564): HCES against 24-hour recall, Kasungu, Malawi | IHS5 2019/20, World Bank Microdata Library (catalog 3818; the access terms were not read); 183 households selected by stated criteria | no code statement | four tables: median intakes, vehicle coverage, shares of inadequate intake with and without fortification | **not as it is**: without the composition matches and the code, agreement can only be loose |
| `micronutrientsupport/hcesNutR` (GitHub; MAPS project) | sample files "randomly generated to mimic the structure" of IHS5 | R package, MIT | the README prints no numeric result | no: nothing to compare with |
| `kmtang/ihs4` (GitHub): "Micronutrient Analysis of the Fourth Integrated Household Survey of Malawi" | IHS4, to be downloaded (catalog 2936) | R Markdown files; no licence; the README has unresolved merge markers | folders of outputs, not opened | no: unlicensed, unpublished state |
| `micronutrientsupport/r4hces` (book project), `MIMI-wfp` (organisation) | not stated on the pages opened | — | — | not established |

**Conclusion: none exists that is usable as a test today.** What a
reproducible anchor needs (data, the composition matches, unit factors and
results of one analysis) was not found together.

The closest is Kalimbira et al. 2025: public data, the same method (seven
days, adult female equivalent), published medians and coverage for 183
households. Turning it into a test means a second adapter (IHS5), the
selection of the 183 households by the published criteria, and a tolerance
set in advance in percent, not 1e-6, because the food matches are not
published. That is the size of the Peru adapter; it is recorded for v0.2
(P196), and the first step would be to ask the authors for their matches
and code.

For ENGIH itself the original used one outside source: del Rosario (2021),
*El consumo de alimentos en República Dominicana* (IDIAF), the ten foods
with the largest weight in expenditure, against which it compared its
ranking by quantity (`INFORME_factibilidad.qmd:686-735`). It is an
ordinal check on another quantity, and the document was not opened here
(`# SOURCE PENDING`).

So the statement of the review stands and A1 to A4 do not change it: the
ENGIH validation proves the arithmetic against an independent
implementation of the same method, not the method.

## 9. Decisions for the maintainer

The recommended option first. Only what the documents do not settle.

1. **Approve the design, and the companion repository as an R package**
   (section 7). Recommended: the mapping rules can then be tested in CI
   without microdata. Alternative: a repository of scripts, which leaves
   the acceptance test as the only test of the adapter.
2. **A1 now, by you, in three acts**: md5 and rerun of the original chain
   (2.1), the export script (2.2), and commit of
   `data/auditoria/cifras_control/etapas/`. Recommended now, in parallel
   with 12e.5: the script needs nothing from the package, and its tables
   decide U1, U2 and decisions 4 and 5. Please merge the script's branch
   into `main` of `analisis_ENGIH2018`, or tell me to keep it apart.
3. **The two download addresses.** Recommended: you copy them from the
   Banco Central page into the registry, once, with the date. Alternative:
   allow `www.bancentral.gov.do` in the environment so a session can read
   the page and its terms of use.
4. **`fortifiable` from the origin only**: `FALSE` for own production
   (`QUIEN_PAGO1` = 2), as in `hces_example`. Recommended for v0.1.
   Alternative: also by type of shop, decided after you read
   `e_procedencia` and `e_establecimiento`; it needs the dictionary of
   `ID_TIPO_ESTABLECIMIENTO`.
5. **The household's share in the corrected analysis** (E29): use
   `PORCENTAJE_HOGAR`. Recommended: the survey measured it and the contract
   has the column; the manual already declares its omission as an
   assumption. Acquisitions destined to a business with a share of 100 stay
   in (the survey says the household's share is the whole). Alternative:
   leave it as a documented limitation.
6. **Non-foods** (11 codes typed `no_alimento_excluir`; purified water has
   5,937 records): the adapter drops them with a count. Recommended:
   otherwise water dominates the grams "not linked" of the readiness
   report. No figure of step 1 depends on it. Alternative: keep them as
   unmatched foods.
7. **The outlier rule in the corrected analysis** (E9): keep the original
   rule and report one sensitivity run per AFE. Recommended: no rule has a
   source, the rule removes 66 records, and changing it would move every
   figure for a reason no document supports. Alternative: per AFE as the
   main rule.
8. **Vehicle coverage** (E28): the corrected figure is `acquired` (a
   record of the vehicle, with or without grams), and `NEWS.md` gives both.
   Recommended: a Section 2 row says the household held the food, which is
   use of the vehicle even when nothing was consumed from the stock that
   week. Alternative: keep "grams above zero" as the definition for ENGIH.

Already decided elsewhere and applied here: infants (R3-D2), `fortifiable`
used only when the call says so (R3-D4), 12e.5 before A2 (R3-D8), the
days of Section 3A (E4, 2026-11-12), unit priority (P59).

## 10. What was verified in this session, and how

| Claim | How |
|---|---|
| 925 degrees of freedom in every row; intervals symmetric; 23 rows with a limit outside 0 to 100; 130 zero differences | `riesgo_inadecuacion.csv`, `diferencias_escenarios.csv` read in R; `uniroot()` on `qt(0.975, df)` |
| The options of S21 reproduce `srvyr` | `hces_example` (2,000 households, 6 strata, 200 PSUs), invented outcome, 30 households without a value: `srvyr` on the subset against `estimate_households()` and `estimate_difference()`; differences 0 |
| Infant values; S8 | `adult_equivalents(infants = "annual_mean")` against the original's arithmetic, with the package table (differs) and with the 24 infant rows set to 649 and 600 (equal to 12 digits); the 34 yearly values of both tables are identical |
| Findings 3, 7 and 8; the rules of 4.3; the counts of 2.3 and 5 | the five parameter workbooks and the CSV files of `data/raw/`, read with `readxl`; the vehicle and storable patterns applied to the 799 descriptions |
| The export script runs and adds up | invented stand-ins (60 households, 1,100 records); four totals recomputed apart |

Not verified: anything marked **[needs microdata]**; the record
descriptions of the microdata (taken from `agrupacion_alimentos.csv`, which
the original joins to the records by description); the Banco Central page;
the documents of section 8 beyond the pages named.

## 11. Sources opened

| Document | Where | What was read |
|---|---|---|
| Kalimbira et al. 2025 | `pmc.ncbi.nlm.nih.gov/articles/PMC12348564/` | citation, data availability statement, survey and sample, divisor, table titles (through a page summary, not the full text) |
| `micronutrientsupport/hcesNutR` | `github.com/micronutrientsupport/hcesNutR` | README |
| `kmtang/ihs4` | `github.com/kmtang/ihs4` | repository page and README |
| `micronutrientsupport/r4hces`, `MIMI-wfp` | their GitHub pages | file list; pinned repositories |

Not obtained (`# SOURCE PENDING`): the Banco Central page of the ENGIH
2018 and its terms of use; del Rosario (2021); the documentation of the
INCAP and FNDDS tables (basis and units); the text of NORDOM 602 and
RTD 616 (E8); a cited density for oil (E18).
