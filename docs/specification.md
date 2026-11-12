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
  log accumulates along a pipeline. The carrier is a tibble subclass with an
  accessor, chosen in task 2 by a test (`docs/design-task2.md`): the package
  re-attaches the log explicitly, a lost log raises a classed error, and a
  table changed between two package functions is recorded in the log.
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
  `period_days` (the number of days the recorded quantity is divided by; the
  adapter sets it and documents its rule: the design length of the window, or
  the days with a record where the survey supports that reading), `include`
  flag set by the adapter's section-combination rule,
  origin* (purchase, own production, gift), household share*.

Tables the user supplies alongside (not survey data, still external):

- `unit_factors`: unit, food*, factor, factor type (`mass_g`, `volume_ml`,
  `count`), density*, source.
- `crosswalk`: food code → composition id, equivalence type, validated flag,
  edible portion (keyed by food code).
- `composition`: composition id, nutrient columns with the unit in the name,
  plus metadata: basis, edition, state of the food, source. Optional columns
  for the forms an upper level applies to (`retinol_ug`, `folic_acid_ug`).
- `enrichment`: composition id + nutrient → what enrichment added, by a
  reference pair (enriched and unenriched rows, ingredient fraction) or by
  an amount `added`, source.
- `vehicles`: food code → vehicle, vehicle group*, vehicle fraction (of the
  food as purchased), source.
- `food_groups`: food code → food group, source (one group per food;
  `unclassified` is reserved). No classification is shipped.
- `scenarios`: scenario, vehicle, nutrient, `level_mg_kg`, level basis
  (`nutrient` or `compound`), compound*, form* (required when the unit of
  the nutrient is an equivalent), nutrient fraction* (only with basis
  `compound`), compliance (default 1, noted in the log), source.

Nutrients are handled through a registry (name, unit, column), so the core is
not tied to the nutrients of the first case.

### 2. Generic core (knows no survey)

| Step | Function (working name) | Input → output |
|---|---|---|
| Contracts | `validate_*()` and constructors | any standard table → validated table or classed error |
| Units | `convert_units()` | acquisitions + unit factors → grams |
| Outliers | `flag_outliers()` | grams → flag; scale, grouping and thresholds are arguments |
| Adult equivalents | `adult_equivalents()`, `reference_energy()` | members + energy requirements + reference person → equivalents per household; the reference person's requirement from the BMR equations |
| Composition | `link_composition()`, `fill_composition()` | grams + crosswalk + composition → nutrients per record, with coverage over all records |
| Apparent intake | `apparent_intake()` | nutrients + equivalents → intake per equivalent per day, one row per household of `households`, with a status |
| Plausibility | `flag_energy_plausibility()` | intake + energy column + `lower`, `upper` → flag |
| Baseline | `unfortified_baseline()` | composition + enrichment → baseline composition (removes enrichment only) |
| Vehicles | `vehicle_coverage()` | grams + vehicles + equivalents → vehicle use per household (acquired, grams per AFE and per member), by vehicle, group and combination |
| Flour levels | `who2009_levels()` | per capita flour availability (ratio of weighted totals of grams and members) + extraction → rows of the WHO 2009 table |
| Scenarios | `apply_scenario()` | baseline intake + vehicle use + scenarios → total and added intake per household and scenario, baseline included |
| Risk | `inadequacy()` | intake + requirements (+ requirement distributions) → probability below the requirement per household, scenario and nutrient: EAR cut-point, or the probability approach for the nutrients given a distribution (bioavailability as a required argument); minimum coverage required |
| Upper level | `above_ul()` | intake + UL, its unit and the form it applies to → above the UL per household, scenario and nutrient: total intake, or the form (added part, diet part where the composition has it) |
| Food groups | `food_group_intake()` | baseline nutrients + food groups + equivalents → amount per equivalent per day by household and group (foods without a group in `unclassified`) |
| Density | `nutrient_density()` | intake + energy → per 1,000 kcal |
| Design | `as_hces_design()` | households + choice for single-PSU strata → `srvyr` design on the full sample |
| Estimation | `estimate_households()`, `estimate_difference()`, `flag_precision()` | design + result table → proportions, means and medians with intervals by group and domain; paired differences between scenarios; precision flag with limits given by the caller |
| Group shares | `food_group_shares()` | design + intake by group → share of each group in the mean intake per equivalent, by nutrient and domain (ratio of weighted totals, logit interval) |

Subsets are always estimated as domains of the full design.

Audit log, across the core: every table carries its log; the logs of
several inputs are merged without repeating a shared branch.
`audit_log()` returns it, `audit_summary()` summarises what each step
excluded, flagged or filled with the share of its input, `audit_record()`
lets an adapter record its own steps, and `restore_audit()` re-attaches the
log after a verb that drops it.

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
   Tolerance: 1e-6 absolute on percentages, means and medians. The run
   records the versions of R and of every attached package next to the
   figures.
2. **Corrections.** Each option that is an error is switched to the corrected
   default, one at a time; old and new figures are recorded in `NEWS.md`.

In this repository, every function is tested on hand-built fixtures and on the
synthetic dataset.

## Out of scope for v0.1 (in the roadmap)
- Retention factors (losses from washing and cooking).
- Harmonised average requirements (H-AR; Allen et al., 2020) as an alternative
  reference table.
- Prevalence weighted by persons, in addition to households.
- Food-group shares under a fortification scenario (P95); the shares on
  the unfortified baseline are in v0.1.
- Maps and plotting helpers (the user's `ggplot2`/`sf` code; shown in a
  vignette at most).
- Peru adapter: the survey is not confirmed; the contracts assume no
  questionnaire design.
- Food-matching support module (proposal P42 of `docs/improvements.md`).

## Pending decisions
- Review track: the standard rOpenSci software review is the target (the
  `srr` workflow of the statistical review is not adopted); confirmed at the
  end. `codemeta.json`, the pkgdown site and badges wait for v1.0. CRAN
  afterwards.
- WFP sponsorship: if accepted, WFP appears in `DESCRIPTION` as funder (role
  `fnd` in `Authors@R`) and in the README. No WFP logo or branding without
  written authorisation.

Decided: the companion repository of the ENGIH 2018 adapter is
`hcesfort.engih2018`.
