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
* `link_composition()`: nutrients per record through the validated rows of
  the crosswalk, with the edible portion (keyed by survey food) and an
  optional yield factor. Every record is kept with its status; coverage is
  counted over all records, by records and by grams, before anything is
  dropped, and causes are not hierarchical (E3). A missing composition
  value leaves the nutrient missing, never zero (E21). A validated match to
  a composition id absent from the table is an error, not a silent loss.
  A missing yield factor counts as 1, and the linked records concerned are
  counted in the audit log (`yield_factor_assumed_one`).
* `fill_composition()`: fills missing composition values from a table of
  values with their source (`hces_schema("composition_fills")`); existing
  values are never overwritten and every filled cell is counted. The
  original's two rules (borrowed values; zero B12 and vitamin D in
  unprocessed plant foods) become rows of that table.
* `unmatched_foods()`: the foods with records not linked to the
  composition, what blocks them, and their weight in records and in grams
  (the original's list was empty by construction, E3).
* `check_crosswalk()`: quality controls of the crosswalk as flag columns,
  nothing changed: missing or conflicting edible portions, composition foods
  shared by several foods, cooked or as-consumed rows without a yield
  factor, missing nutrients, enriched rows, match types marked for review
  and nutrients outside ranges given by the user (E20, E21, E1). With the
  grams table, each food's records and grams rank the review.
* `apparent_intake()`: nutrients per adult female equivalent per day, one
  row per household of `households` with a status (`estimated`,
  `food_module_nonresponse`, `no_food_records`, `all_records_lost`,
  `no_afe`), so no household leaves the frame unseen (E5). Records not
  included, not linked or, when asked, flagged as outliers are left out and
  counted with their grams; the decision on outliers is a required
  argument when the flag exists. Missing composition values add nothing and
  each nutrient has a coverage column, the share of edible grams with a
  value (E21; the original summed them as zero without saying so).
* `flag_energy_plausibility()`: flags households outside an energy range
  given by the user (the original's 500 and 6,000 kcal are one call, not a
  default). `nutrient_density()`: nutrients per 1,000 kcal (or another
  amount).
* `unfortified_baseline()`: removes what enrichment added to a composition
  table, cell by cell, from a table of rules with their source
  (`hces_schema("enrichment")`, `validate_enrichment()`), so intake can be
  computed without the fortification a scenario adds. The original
  replaced the iron and folate of every derived product by those of its
  flour, deleting the nutrients of the other ingredients (E6); the default
  now subtracts the difference between the enriched and the unenriched
  ingredient times its fraction, never below what the unenriched
  ingredient brings. The original rule is `method =
  "replace_by_ingredient"`.
* `vehicle_coverage()`: vehicle use per household, vehicle, vehicle group
  and combination of vehicles, on the purchased basis, from one vehicles
  table (the original defined the vehicles twice by regular expressions,
  E12). Households without food records keep a missing `acquired` and stay
  in the frame, with the same denominator as risk (E5; the original counted
  them as non-consumers).
* `apply_scenario()`: total and added intake per household under each
  scenario, the baseline included. It refuses an intake not built on an
  unfortified baseline: the original's prevalence script used the enriched
  composition (E1). The level basis is stated in each scenario row: compound
  to form (`nutrient_fraction`), the form (`form`) and its equivalent factor
  read from the conversions table, instead of the constants 1.7 and "read as
  retinol" in the code (E8, P52). Compliance enters under a named model
  (`compliance_model = "average_content"`), required when a compliance is
  below 1 (the original assumed full compliance without saying so, P32).
  The amount of the form is kept apart (`folic_acid_ug_added`) for the
  upper level.
* `vehicles` gains the optional column `vehicle_group`; `scenarios` the
  optional column `form`, and `nutrient_fraction` must be missing when the
  basis is `nutrient`. `nutrient_density()` and `flag_energy_plausibility()`
  accept the scenario table.
* `inadequacy()`: per household, scenario and nutrient, the probability of
  an intake below the requirement: the EAR cut-point, or the probability
  approach for a nutrient whose requirement distribution the caller gives
  (iron), with the bioavailability as a required argument (the original's
  10% has no source). A nutrient whose share of grams with a composition
  value is below `min_coverage` is an error (`hcesfort_error_coverage`):
  the original reported a share below the EAR for vitamin D with much of
  the grams missing, summed as zero (E21).
* `above_ul()`: per household, scenario and nutrient, whether the intake the
  UL applies to is above it: the total intake for iron and zinc; for folic
  acid and preformed vitamin A the form only, added by the scenarios and,
  when the composition has it, already in the diet (E7). The original
  compared the added amount only and called it an upper bound; it is a
  lower bound, now named so (`ul_scope = "form_added_only"`). One row per
  nutrient and one table of ULs remove E13 and E14.
* Reference tables: `ref_requirements$ul_unit` states the unit of each UL
  (the folate UL is in µg of folic acid, not DFE; the vitamin A UL in µg of
  preformed vitamin A); `ref_conversions$ul_form` links a form to the upper
  level it counts towards. New error class `hcesfort_error_coverage`.
* `as_hces_design()`: the survey design of the households (primary
  sampling units nested in strata, weights) as a `srvyr` design. The choice
  for strata with a single PSU is a required argument and is applied per
  call, never left in the global options (E24).
* `estimate_prevalence()`: proportions, means and medians of a result
  table with standard errors and intervals, by group and domain, always as
  domains of the full design (the original took subsets before declaring
  the design, E5). Proportions use the logit interval of
  `survey::svyciprop()` by default, which stays between 0 and 1 (the
  original's symmetric interval is `ci_method = "mean"`); medians have an
  interval (E24). Degrees of freedom are those of the domain by default.
* `estimate_difference()`: paired differences between scenarios, the mean
  of the within-household difference, with its interval; no
  `significant` column (E24). `flag_precision()`: flags estimates on few
  households or with wide intervals, both limits required (the original's
  50 households and 10 points have no source).
* Record loss (review of v0.1, H1): `apparent_intake()` returns
  `n_records_included`, `share_records_used` and `share_grams_used` per
  household; `inadequacy()` and `above_ul()` return `share_records_used`
  and take a required `min_records_used`, an overall gate on the share of
  included records used (`hcesfort_error_coverage` with
  `measure = "records_used"`). The composition gate (`min_coverage`) only
  sees the records used: in `hces_example` every `_coverage` was 1 while a
  third of the included records never reached the intake.
* Validity of the cut-point (review of v0.1, H2, L9): `requirements`
  needs the column `cutpoint_valid`; `inadequacy()` refuses the EAR
  cut-point for a nutrient whose requirement is skewed (`FALSE`) unless
  its distribution is given. `ref_requirements` gains `cutpoint_valid`
  (`FALSE` for iron: IOM 2000, *Applications in Dietary Assessment*,
  pp. 81 and 91) and `ear_bioavailability` (0.18 for iron), written in the
  log, rescaling nothing. Before, iron passed in `requirements` without a
  distribution was assessed by the cut-point without a word.
* Household flags as domains (review of v0.1, H3): `estimate_prevalence()`
  and `estimate_difference()` take `domain_from`, a household table of the
  package holding the logical column named by `domain` (one row per
  household of the design, checked). The energy-plausibility sensitivity
  analysis of the original can now be run on the risk tables; the log of
  the estimate records the domain, its origin, the households with a
  missing flag and the log of the flag.
* Intake and vehicle use on the same footing (review of v0.1, H4, P76):
  `vehicle_coverage()` returns `afe` and `n_members`; `apparent_intake()`
  and `vehicle_coverage()` keep their outlier decision (attribute
  `outlier_decision`); `apply_scenario()` refuses a pair built with a
  different AFE or outlier decision (`hcesfort_error_join`). Before, a
  scenario could add fortificant from records the baseline had excluded.
* `hces_example` recalibrated (review of v0.1, H6): quantities scale with
  household size, the planted defects stay in a few records (milk has a
  density; one milk record in cups has not), a fourteenth food (pumpkin)
  carries vitamin A, and the folic acid level of `flour_and_sugar` is
  4.5 mg/kg. Median energy is now about 2,200 kcal per AFE per day
  (518 before), 90% of the included records reach the intake (68%
  before), and two households pass the folic acid UL. A golden test runs
  the whole chain and compares 17 figures with values computed without
  the package (`data-raw/golden_example.R`), at 1e-8.
* Corrections to the original ENGIH 2018 analysis will be recorded in this
  file, with the figures before and after, as each function is written.
  Errors of the original analysis are not ported; the list of those found is
  in `docs/analysis-map.md` (E1 to E26).
