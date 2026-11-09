# Specification v0.1 (draft)

## Purpose
Replicating the ENGIH 2018 analysis in another country (Peru first) should mean writing a survey adapter, not redoing the analysis.

## Principles
- Defensive programming as set out in `CLAUDE.md`: data contracts, classed errors, checked joins, an audit log of every exclusion.
- Every function returns its result together with its audit log (as an attribute or a list element; decide in task 2).
- A new survey never touches the core: it only adds an adapter.

## Architecture: three layers

### 1. Survey adapter (one per survey)
Reads the survey's own files and returns three standard tables:
- `households`: household id, sampling weight, stratum, primary sampling unit, domains (region, area, income quintile, …).
- `members`: household id, age, sex and, where available, pregnancy or lactation.
- `acquisitions`: household id, food code, quantity, unit, section or source, reference period in days.

Everything country-specific (sections, local units, the rule that combines stock and daily acquisitions) lives here.

### 2. Generic core (knows no survey)

| Step | Proposed function | Input → output |
|---|---|---|
| Units | `convert_units()` | acquisitions + conversion table → grams |
| Adult equivalents | `compute_afe()` | members + energy requirements → adult female equivalents (AFE) per household |
| Composition | `link_composition()` | grams + crosswalk + composition tables → nutrients per record |
| Apparent intake | `apparent_intake()` | nutrients + AFE → intake per AFE per day |
| Scenarios | `apply_scenario()` | composition + scenario definition (vehicles, levels, flour fractions of derived products, replacement of enriched foods) → modified composition |
| Risk | `inadequacy()` | intake + requirements; method `"ear_cutpoint"` or `"iron_probability"` (bioavailability as an argument) |
| Upper level | `above_ul()` | intake of the added or total nutrient + UL |
| Estimation | `estimate()`, `paired_difference()` | complex survey design (srvyr) → proportions with CIs; paired differences between scenarios |

### 3. Reference data shipped with the package, each with its source
- EAR and UL (IOM).
- Energy requirement of the reference adult woman (AFE denominator).
- WHO (2009) flour fortification levels by flour availability category and compound.
- Distribution of iron requirements for the probability approach.

## Validation
Acceptance test: with the ENGIH 2018 adapter and the microdata available locally, the package reproduces the control figures of the original analysis (risk, scenarios, differences). Tolerance: [DECIDE, e.g. 0.05 percentage points].

## Out of scope for v0.1 (in the roadmap)
- Retention factors (losses from washing and cooking) and partial compliance.
- Harmonised average requirements (H-AR; Allen et al., 2020) as an alternative to the IOM EAR.
- Prevalence weighted by persons, in addition to households.
- Food groups and maps.
- Peru adapter: [CONFIRM the survey and its food modules].

## Pending decisions
- CRAN, rOpenSci review, or both.
- WFP sponsorship: if accepted, WFP appears in `DESCRIPTION` as funder (role `fnd` in `Authors@R`) and in the README. No WFP logo or branding without written authorisation.

