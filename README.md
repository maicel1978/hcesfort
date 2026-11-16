# hcesfort

<!-- badges: start -->
[![R-CMD-check](https://github.com/maicel1978/hcesfort/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/maicel1978/hcesfort/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

R package to estimate apparent micronutrient intake and to model food
fortification scenarios from Household Consumption and Expenditure Surveys
(HCES).

**Status: experimental, before its first release.** The chain from the
standard tables to design-based estimates works and is tested; the
interfaces may still change, and the method has not yet been reviewed by
outside experts. The plan is in [`docs/roadmap.md`](docs/roadmap.md) and
the design in [`docs/specification.md`](docs/specification.md).

## The chain

From three standard tables (households, members, food acquisitions) and the
tables the analyst supplies (unit factors, food composition, fortification
scenarios), on the synthetic `hces_example`:

```r
library(hcesfort)
ex <- hces_example
nutrients <- nutrient_registry(ex$nutrients)
baseline <- unfortified_baseline(ex$composition, ex$enrichment, nutrients)
grams <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
content <- link_composition(grams, ex$crosswalk, baseline)
afe <- adult_equivalents(ex$members,
  reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
  weight_kg = c(female = 55, male = 65), pal = 1.76,
  infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0)
intake <- apparent_intake(content, afe, ex$households)
use <- vehicle_coverage(grams, ex$vehicles, afe, ex$households,
                        fortifiable = "use")
scenarios <- apply_scenario(intake, use, ex$scenarios,
                            compliance_model = "average_content")
folate <- ref_requirements[ref_requirements$nutrient == "folate", ]
risk <- inadequacy(scenarios, folate, min_coverage = 0.8,
                   min_records_used = 0.8)
design <- as_hces_design(ex$households, lonely_psu = "adjust")
estimate_households(design, risk, "p_inadequate",
                    ci_method = "korn_graubard")
audit_log(risk)  # every exclusion, flag and assumption of the chain
```

The vignette `vignette("getting-started", package = "hcesfort")` runs the
chain step by step, with the probability approach for iron and the upper
levels; `use_report_template()` writes data-readiness and results reports.

## What the figures are and are not

The EAR cut-point and the probability approach for iron are defined on the
*usual* intake of persons (IOM 2000b, *Dietary Reference Intakes:
Applications in Dietary Assessment*, pp. 73, 81 and 99; IOM 2001, Table I-7,
p. 703). An HCES records what a household acquired over a period, not what
each person usually eats. `hcesfort` applies the methods to that apparent
intake, per adult female equivalent, with no adjustment:

- the figures describe **households, not persons**: food is assumed to be
  shared in proportion to energy requirements;
- purchase frequency and stocks add variance that usual intake does not
  have, so the share below a requirement moves towards 50% and the share
  above an upper level goes up;
- the upper levels are those of adults; children, the most exposed to
  excess from fortified staples, are not assessed;
- under the average-content compliance model the share above an upper level
  is understated; the same levels at compliance 1 give its upper bound.

The results are screening figures to compare scenarios on the same data,
not prevalences of inadequacy. Each of these limits is written in the audit
log of the result.

## Design principles

- **Survey-agnostic.** A new survey needs an adapter that produces the
  standard tables; the core does not change.
- **No data inside.** Microdata, food composition tables and national
  standards stay with their owners. The package ships only small reference
  tables with their source, each replaceable by argument, and a synthetic
  example.
- **It connects, it does not replace.** Tidy tibbles in and out, variance
  estimation through `survey` and `srvyr`, results ready for `ggplot2`.

## Installation

```r
# install.packages("pak")
pak::pak("maicel1978/hcesfort")
```

## Origin of the method

The method comes from an analysis of the ENGIH 2018 survey of the Dominican
Republic (<https://github.com/maicel1978/analisis_ENGIH2018>).
[`docs/analysis-map.md`](docs/analysis-map.md) maps that analysis to this
package and lists the errors that are corrected rather than ported.

## Use of AI tools

Developed with the help of AI tools under the author's supervision;
methodological decisions and validation are the author's.

## Code of conduct

Please note that the hcesfort project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project, you agree to abide by its terms.
