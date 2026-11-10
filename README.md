# hcesfort

<!-- badges: start -->
[![R-CMD-check](https://github.com/maicel1978/hcesfort/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/maicel1978/hcesfort/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

R package to estimate apparent micronutrient intake and to model food
fortification scenarios from Household Consumption and Expenditure Surveys
(HCES).

**Status: under construction.** The package has no user-facing functions yet.
The plan is in [`docs/roadmap.md`](docs/roadmap.md) and the design in
[`docs/specification.md`](docs/specification.md).

## What it will do

From three standard tables (households, members, food acquisitions) and the
tables the analyst supplies (unit factors, food composition, fortification
scenarios), the package will:

- convert acquisitions to grams and to nutrients, per adult equivalent and day;
- model fortification scenarios on an unfortified baseline;
- estimate the risk of inadequate intake (EAR cut-point, probability approach
  for iron) and the share above the upper level, with the complex design of
  the survey;
- return, with every result, an audit log that counts each exclusion.

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

## Code of conduct

Please note that the hcesfort project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project, you agree to abide by its terms.
