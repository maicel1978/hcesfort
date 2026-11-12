# Sources of the reference tables

Every value in the CSV files of this directory was read in a document opened
on 2026-11-12, at the place given in the `location` column of its row. A row
is `verified` when its value was read in the document; `pending` when it was
not (the reason is in `location`). Only `verified` rows are shipped
(`data-raw/reference.R`). The maintainer checks the `pending` rows.

The md5 of each CSV is registered in `data-raw/MD5` and checked by
`tests/testthat/test-reference-data.R`. Changing a value means changing the
CSV, its row here if needed, and its md5, in the same commit.

The values were also compared with the parameter files of the original
analysis (`analisis_ENGIH2018`, `data/raw/` and `scripts/04_equivalente_adulto.R`):
every value used there agrees with the document.

## Documents

| Key | Document | Opened at |
|---|---|---|
| FAO/WHO/UNU 2004 | FAO. 2004. *Human energy requirements. Report of a Joint FAO/WHO/UNU Expert Consultation, Rome, 17–24 October 2001.* FAO Food and Nutrition Technical Report Series 1. | <https://www.fao.org/4/y5686e/y5686e00.htm> (chapters 3, 4 and 5: `y5686e05.htm`, `y5686e06.htm`, `y5686e07.htm`) |
| IOM 1998 | Institute of Medicine. 1998. *Dietary Reference Intakes for Thiamin, Riboflavin, Niacin, Vitamin B6, Folate, Vitamin B12, Pantothenic Acid, Biotin, and Choline.* Washington, DC: The National Academies Press. doi:10.17226/6015 | <https://nap.nationalacademies.org/read/6015> |
| IOM 2000 | Institute of Medicine. 2000. *Dietary Reference Intakes for Vitamin C, Vitamin E, Selenium, and Carotenoids.* Washington, DC: The National Academies Press. doi:10.17226/9810 | <https://nap.nationalacademies.org/read/9810> |
| IOM 2001 | Institute of Medicine. 2001. *Dietary Reference Intakes for Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron, Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc.* Washington, DC: The National Academies Press. doi:10.17226/10026 | <https://nap.nationalacademies.org/read/10026> |
| IOM 2011 | Institute of Medicine. 2011. *Dietary Reference Intakes for Calcium and Vitamin D.* Washington, DC: The National Academies Press. doi:10.17226/13050 | <https://nap.nationalacademies.org/read/13050> |
| WHO 2009 | World Health Organization. 2009. *Recommendations on wheat and maize flour fortification. Meeting report: interim consensus statement.* WHO/NMH/NHD/MNM/09.1. Geneva. | <https://iris.who.int/handle/10665/111837> (PDF of 3 pages, md5 `9cf668a20a2cf32a8c35b676bb9993d4`) |

Page numbers of the IOM reports are those printed in the books, as shown by
the online reader. The FAO report online has no page numbers; tables are
cited by number.

## Tables

| CSV | Shipped as | Rows (verified / pending) | Source and place |
|---|---|---|---|
| `requirements.csv` | `ref_requirements` | 6 / 1 | IOM 1998, 2000, 2001, 2011; EAR for women 19–30 years and UL for adults; place per row |
| `iron_requirement_percentiles.csv` | `ref_iron_requirements` | 182 / 0 | IOM 2001, Appendix Tables I-3 (p. 700) and I-4 (p. 701); bioavailability from the table footnotes (I-3) and chapter 9, pp. 316–317 and 343 (I-4) |
| `energy_requirements.csv` | `ref_energy_requirements` | 58 / 0 | FAO/WHO/UNU 2004, Table 3.2 (infants, by month), Tables 4.2 (boys) and 4.3 (girls), column "Daily energy requirement, kcal/d" |
| `bmr_equations.csv` | `ref_bmr_equations` | 12 / 0 | FAO/WHO/UNU 2004, Table 5.2 (Schofield equations, kcal/day) |
| `nutrient_conversions.csv` | `ref_conversions` | 7 / 1 | IOM 1998 (DFE), IOM 2001 (RAE, IU) |
| `who2009_wheat_flour_levels.csv` | `ref_who2009_flour` | 40 / 0 | WHO 2009, Table 1, with its footnotes |

## Pending values (not shipped)

| CSV | Row | Value | Why pending | How to check |
|---|---|---|---|---|
| `requirements.csv` | `vitamin_d` | EAR 10 µg and UL 100 µg are verified (IOM 2011, pp. 388 and 444); `ul_applies_to = total` is not | The chapters read (summary, 1, 5, 6) were not found to state whether the UL refers to total intake. IOM 2001 says so as a general rule (Summary, p. 27), but that is another report. | Find the statement in IOM 2011 (chapter 1 or the UL chapter); if it says total intake, set `status` to `verified`. |
| `nutrient_conversions.csv` | `retinyl_palmitate` | no value | No document opened gives a factor from mass of retinyl palmitate to retinol activity (analysis map, E8). A value derived from molecular weights is a computation, not a source. | Give a document with the factor, or decide that scenario levels for vitamin A must be given as retinol. |

## Notes on use

- `requirements.csv` covers one group (women 19–30 years), the reference
  group of the original analysis. Other life stages are not entered yet.
- Age intervals are `[age_from, age_to)`: `age_from` inclusive, `age_to`
  exclusive, in the unit of the table. FAO "1–2" years is `[1, 2)`; IOM
  "19–30 years" (completed years) is `[19, 31)`.
- `ref_bmr_equations`: "< 3" is `[0, 3)` and "≥ 60" is `[60, Inf)`.
- `who2009_wheat_flour_levels.csv`: availability categories are kept as
  printed (`<75`, `75-149`, `150-300`, `>300` g/day); the numeric bounds
  repeat the printed numbers and do not decide which category a boundary
  value belongs to. `NR` (not recommended) is a missing level with
  `recommended = FALSE`. The table header gives the "level of nutrient to be
  added in parts per million"; ppm is mg/kg.
- The iron requirement percentiles are of **dietary** iron at the stated
  bioavailability (absorbed requirement divided by the bioavailability).
