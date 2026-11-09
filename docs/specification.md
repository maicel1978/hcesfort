# Specification v0.2 (draft)

Revised after roadmap task 0. The decisions behind each change are recorded in
`docs/improvements.md` (section "Decisions").

## Purpose
Estimate apparent micronutrient intake and model food fortification scenarios
from any Household Consumption and Expenditure Survey. Replicating the
ENGIH 2018 analysis in another country should mean writing a survey adapter
and supplying that country's tables, not redoing the analysis.

## Principles
- **Survey-agnostic core.** The core knows no survey, no country, no food
  list and no fixed set of nutrients. Everything it needs arrives as a table
  that satisfies a documented contract.
- **What is external stays external.** The package ships no microdata, no food
  composition tables, no crosswalks, no unit catalogues and no national
  standards. They belong to the user or to a companion repository. The package
  ships only small, generic reference tables (see layer 3), each with its
  source, and every function that uses one accepts a replacement as an
  argument.
- **It plugs into the existing ecosystem instead of replacing it.** Inputs and
  outputs are tibbles in tidy form. Variance estimation is delegated to
  `survey`/`srvyr`, and the survey design object is available to the user for
  any further estimate. Results are ready for `ggplot2`; the package exports
  no plotting or mapping functions.
- **Defensive programming** as set out in `CLAUDE.md`: data contracts, classed
  errors, checked joins, an audit log of every exclusion.
- **Every function returns its result together with its audit log**, and the
  log accumulates along a pipeline. The carrier (tibble subclass with an
  accessor, or a classed list) is chosen in task 2 by a test: the log must
  survive the verbs the pipeline uses, or its loss must raise a classed error.
- **Detect and decide are separate.** A function flags (outliers, implausible
  energy, stored purchases); another argument or function decides what to do
  with the flag. No threshold is a hidden default: defaults are documented
  with their source, or marked as having none.

## Architecture: three layers

### 1. Survey adapter (one per survey, outside the core)
An adapter reads the survey's own files and returns the standard tables. It is
ordinary user code or a companion package; the core provides the constructors
and validators it must pass, a synthetic example, and a vignette on writing
one. The ENGIH 2018 adapter lives in a companion repository together with its
parameter files and the acceptance test.

Standard tables (columns marked * are optional):

- `households`: household id, sampling weight, stratum, primary sampling unit,
  domains (region, area, income quintile, …), food-module response flag*.
- `members`: household id, age, sex, pregnant*, lactating*, share of meals
  taken at home*.
- `acquisitions`: household id, food code, quantity, unit, section or source,
  `period_days` (length of the observation window, not the number of days with
  records), `include` flag set by the adapter's section-combination rule,
  origin* (purchase, own production, gift), household share*.

Tables the user supplies alongside (not survey data, still external):

- `unit_factors`: unit, food*, factor, factor type (`mass_g`, `volume_ml`,
  `count`), density*, source.
- `crosswalk`: food code → composition id, equivalence type, validated flag,
  edible portion (keyed by food code).
- `composition`: composition id, nutrient columns with the unit in the name,
  plus metadata: basis, edition, state of the food, source. Optional columns
  for the forms an upper level applies to (`retinol_ug`, `folic_acid_ug`).
- `vehicles`: food code → vehicle, flour (or vehicle) fraction, source.
- `scenarios`: scenario, vehicle, nutrient, `level_mg_kg`, level basis
  (`nutrient` or `compound`), compound*, nutrient fraction*, compliance
  (default 1), source.

Nutrients are handled through a registry (name, unit, column), so the core is
not tied to the nutrients of the first case.

### 2. Generic core (knows no survey)

| Step | Function (working name) | Input → output |
|---|---|---|
| Contracts | `validate_*()` and constructors | any standard table → validated table or classed error |
| Units | `convert_units()` | acquisitions + unit factors → grams |
| Outliers | `flag_outliers()` | grams → flag; scale, grouping and thresholds are arguments |
| Adult equivalents | `adult_equivalents()` | members + energy requirements + reference person → equivalents per household |
| Composition | `link_composition()`, `fill_composition()` | grams + crosswalk + composition → nutrients per record, with coverage over all records |
| Apparent intake | `apparent_intake()` | nutrients + equivalents → intake per equivalent per day, one row per household of `households`, with a status |
| Plausibility | energy-plausibility flag | intake → flag |
| Baseline | `unfortified_baseline()` | composition + vehicles → baseline composition (removes enrichment only) |
| Scenarios | `apply_scenario()` | baseline + scenarios + vehicles → added and total intake per household |
| Vehicles | `vehicle_coverage()` | grams + vehicles → coverage, consumption among consumers, combined reach |
| Risk | `inadequacy()` | intake + requirements; method `"ear_cutpoint"` or `"iron_probability"` (bioavailability as an argument) |
| Upper level | `above_ul()` | intake + UL and the form it applies to |
| Density | `nutrient_density()` | intake + energy → per 1,000 kcal |
| Design | `as_hces_design()` | households + result → `srvyr` design on the full sample |
| Estimation | `estimate_prevalence()`, `estimate_difference()` | design → proportions, means and medians with intervals by domain; paired differences between scenarios |

Subsets are always estimated as domains of the full design.

### 3. Reference data shipped with the package, each with its source
Small, generic, replaceable by argument:
- EAR and UL (IOM), with the form the UL applies to.
- Energy requirements by age and sex and the reference adult
  (FAO/WHO/UNU 2004).
- WHO (2009) flour fortification levels by flour availability category and
  compound.
- Distribution of iron requirements for the probability approach.
- Conversion factors (folic acid → DFE, retinol forms → RAE).
- A synthetic example dataset in the standard schema, documented as invented.

A value whose source cannot be opened and checked is not shipped: it stays in
`data-raw/` marked `# SOURCE PENDING`.

## Validation
Acceptance test, in the companion repository of the ENGIH 2018 adapter, run
locally with the microdata. Two steps:

1. **Faithful port.** With the original choices exposed as explicit options,
   the package reproduces the control figures of the original analysis.
   Tolerance: 1e-6 absolute on percentages, means and medians.
2. **Corrections.** Each option that is an error is switched to the corrected
   default, one at a time; old and new figures are recorded in `NEWS.md`.

In this repository, every function is tested on hand-built fixtures and on the
synthetic dataset.

## Out of scope for v0.1 (in the roadmap)
- Retention factors (losses from washing and cooking).
- Harmonised average requirements (H-AR; Allen et al., 2020) as an alternative
  reference table.
- Prevalence weighted by persons, in addition to households.
- Food-group shares.
- Maps and plotting helpers (the user's `ggplot2`/`sf` code; shown in a
  vignette at most).
- Peru adapter: [CONFIRM the survey and its food modules].

## Pending decisions
- Name and location of the companion repository for the ENGIH 2018 adapter.
- Review track: rOpenSci statistical software review is the working
  assumption; requirements are confirmed in task 1. CRAN afterwards.
- WFP sponsorship: if accepted, WFP appears in `DESCRIPTION` as funder (role
  `fnd` in `Authors@R`) and in the README. No WFP logo or branding without
  written authorisation.
