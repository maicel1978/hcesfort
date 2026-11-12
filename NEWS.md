# hcesfort 0.0.0.9000

* Package skeleton: licence, tests (testthat 3), roxygen2 with markdown,
  continuous integration on Linux, macOS and Windows, lint, and a test that
  enforces the size limits of `CLAUDE.md` (functions of at most 40 lines of
  body, files in `R/` of at most 300 lines).
* Classed errors: every error of the package has the class
  `hcesfort_error` and one specific class (`?hcesfort_errors`).
* Audit log: tables returned by the package carry a log of what each step
  received, excluded, flagged or filled (`audit_log()`). A change in the
  number of rows made outside the package is recorded at the next step;
  `restore_audit()` re-attaches the log after a verb that drops it.
* Data contracts of the standard tables `households`, `members` and
  `acquisitions` (`hces_schema()`), checked by `validate_households()`,
  `validate_members()`, `validate_acquisitions()` and, across the three
  tables, `validate_survey()`. Missing measurements are counted in the audit
  log; impossible values are classed errors.
* Nutrient registry (`nutrient_registry()`): the user declares the nutrients
  and their units; column names carry the unit (`iron_mg`).
* Data contracts of the user-supplied tables, checked by
  `validate_unit_factors()`, `validate_crosswalk()`, `validate_vehicles()`,
  `validate_composition()` and `validate_scenarios()`. Missing nutrient
  values are counted per nutrient, never read as zero; a scenario without
  `compliance` gets 1 and the assumption is written in the audit log.
* `hces_example`: a synthetic survey with every input table, invented
  values only, built by `data-raw/hces_example.R`.
* Reference tables with their source, each row read in the document and
  located by table and page (`?reference_tables`): EAR and UL with the
  intake the UL applies to (`ref_requirements`), percentiles of iron
  requirements (`ref_iron_requirements`), energy requirements
  (`ref_energy_requirements`) and BMR equations (`ref_bmr_equations`),
  conversion factors to DFE and RAE (`ref_conversions`), and the WHO 2009
  wheat flour levels (`ref_who2009_flour`). Values that could not be
  checked are not shipped. Compared with the parameter files of the
  original ENGIH 2018 analysis, every value agrees with its document; the
  WHO 2009 vitamin B12 and vitamin A rows, marked unconfirmed there, are
  now verified (Table 1), and the vitamin E UL (1,000 mg, supplementary
  alpha-tocopherol only), left blank there, is entered.
* `adult_equivalents()`: adult female equivalents per household from the
  energy requirement of each member (FAO/WHO/UNU 2004 tables for infants
  and children; BMR times PAL for adults, with weights and PAL given by the
  caller) and the requirement of a reference person. Members without age or
  sex leave the household without AFE and are flagged, instead of counting
  zero as in the original analysis (E10; the original rule is
  `missing = "zero"`). Infants get the requirement of their month of age
  when it is known (the original used the mean of the first year for all,
  `infants = "annual_mean"`).
* `convert_units()`: acquired quantities to grams and grams per day with a
  typed table of unit factors (`mass_g`, `volume_ml` times a density,
  `count` times a piece weight). A unit counted in pieces is never read as
  grams (E2: the original converted a dozen as 12 g), and a volume without
  density is not converted unless the caller gives a density (E18: the
  original used the density of water for every liquid). The choice between
  a food-specific and a generic factor is a required argument (the original
  used the generic first, `priority = "generic"`). Records without grams are
  kept, with the reason, and counted in the audit log before anything is
  dropped (E3).
* `flag_outliers()`: flags records far from their group (above a multiple
  of an upper quantile, or above zero and below a lower quantile divided by
  it) without removing them. Grouping, quantiles, multiplier, minimum group
  size, scale (household, per capita, per AFE) and level (record, or the
  household's total in the group) are arguments without default. The
  original flagged on household grams per day by food with quantiles 0.5%
  and 99.5%, multiplier 5 and 20 records (E9); that rule is one call, not
  a default. Groups too small, records without grams and households without
  AFE are not assessed and are counted in the audit log.
* Corrections to the original ENGIH 2018 analysis will be recorded in this
  file, with the figures before and after, as each function is written.
  Errors of the original analysis are not ported; the list of those found is
  in `docs/analysis-map.md` (E1 to E26).
