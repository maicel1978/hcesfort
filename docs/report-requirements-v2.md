# Report requirements v2

Status: APPROVED by the maintainer (2026-11-14). Source: the maintainer's review of the two reports rendered in Spanish on `hces_example` (14-11-2026), plus a second reading of the same renders. It supersedes `docs/report-requirements-v1.md` where they disagree; everything else in v1 still holds.

Each requirement gives the problem, the requirement and its check. "Auto" means an automated test; "Maintainer" means the maintainer's review of a render.

## 0. Principles (new or changed)

- P6. **Peer-review standard.** Both reports must hold up to a hostile but fair journal reviewer: correct statements, cited standards, no invented thresholds where a published standard exists, precise language.
- P7. **Decision makers read figures.** In the body of the results report, each result is a figure. The full tables go in one appendix of tables at the end. Small reference tables, such as the scenarios and the EAR/UL, stay as tables in the body. This replaces R5 "table before figure".
- P8. **General to particular.** Each report opens with its conclusion (verdict or main findings), then the evidence, in the order of the analysis.
- P9. **Delegate what is fragile.** Use the tested functions of established packages instead of our own code wherever one exists: intervals from `survey`, graphics from `ggplot2`, table rendering from one established table package chosen by the designer. Where something can fail, the report removes it, delegates it, or replaces it with one sentence. Applies to the package and to both reports. A new dependency is justified in the design, and the core Imports stay minimal (CLAUDE.md).
- P10. **Built to change with feedback.** Experts will send comments, and each must be cheap to apply:
  - wording lives in `terms.csv` and `labels.csv`;
  - thresholds and switches live in one place in `_inputs.R`;
  - each exhibit has a stable ID, so a comment can cite it, and is built by one function;
  - rendered tables have snapshot tests, so every change is visible in review.

## A. Data readiness report

- **DR9. Verdict first.**
  - Requirement: the report opens with the verdict (DR8) and a one-paragraph summary: what the data support, what they do not, and what is left to do.
  - Check: Maintainer.
- **DR10. Only preprocessing.**
  - Requirement: the report holds the inventory, thresholds, linkage ladder, work queue, stopping rule, decisions and verdict. Estimates by domain that read as results are removed.
  - Energy plausibility stays national, as a data-quality check, with one figure. By-domain energy medians are removed.
  - The unlinked share by domain becomes one sentence when no domain differs ("No region or expenditure group differs from the rest of the population"). The table appears only for the domains that differ.
  - Check: Auto (no by-domain energy exhibit; one sentence when no domain is flagged).
- **DR11. Domains with small cells.**
  - Requirement: the verdict disables a domain when the share of its cells below `min_n` exceeds a parameter (proposed: half). Currently the verdict says "enabled" for expenditure groups of 7 households while `min_n` is 8, and the results report fills with dashes.
  - Check: Auto.
- **DR12. Dependency map.**
  - Requirement: in the inventory, optional domain variables are needed only for "analysis by <domain>", not for "all sections" (`region` and `expenditure_group` are wrong now). `food_module_response` is needed for the household status.
  - Check: Auto.
- **DR13. Inventory readable.**
  - Requirement: the inventory shows the essential variables and only the optional ones that are absent or partly missing. The full list goes in an appendix.
  - Check: Maintainer.

## B. Results report

- **R15. Figures in the body, tables in an appendix** (P7).
  - Requirement: every figure shows the point and the 95% interval, with the value labelled when legible. The appendix has one table per figure, with the same ID.
  - Check: Auto (every body figure has an appendix table with the same ID).
- **R16. Titles that answer what, who, where and when.**
  - Requirement: every figure and table has a formal title, e.g. "Hogares que adquieren cada vehículo de fortificación, % (IC 95%). República Dominicana, ENGIH 2018".
  - Place and survey come from optional choices (`choices$place`, `choices$survey`). When absent, the title has no place or time. No other metadata is printed. The analyst also writes the report title.
  - Check: Auto (with the choices set, every title ends with them; without, no title has a trailing separator).
- **R17. No precision column; n in a note.**
  - Requirement: remove the "Precisión" column. The number of households goes in the note of each table ("n = 38 hogares"), or as a column only where it varies by row (domains).
  - Check: Auto.
- **R18. A published presentation standard for proportions.**
  - Requirement: replace the invented 15-point rule with the NCHS data presentation standards for proportions (Parker et al., 2017, Vital Health Stat 2(175)). That standard covers the effective sample size, the absolute and relative width of the interval, the degrees of freedom, and Korn-Graubard intervals (`survey::svyciprop(method = "beta")`).
  - The designer verifies the thresholds in the document before writing them, and states any departure. An estimate that fails the standard is suppressed or flagged according to it.
  - Check: Auto (threshold values carry the citation; a fixture estimate failing each criterion is handled as the standard says).
- **R19. Orphan sentences.**
  - Requirement: a sentence about exact estimates (D4) comes right after the title of its exhibit, never before it or between exhibits (p. "Nacional = 0%" now appears before its table).
  - Check: Auto.
- **R20. Structural zeros.**
  - Requirement: a food group with no content of a nutrient in the composition table is not a row with "same value in every household". The note lists such groups in one line: "Sin aporte de hierro: grasas y aceites, lácteos, frutas".
  - Check: Auto.
- **R21. Upper level.**
  - Requirement: one sentence for the zeros: "Ningún hogar supera el UL de <nutrientes> con ningún escenario". Only the nonzero estimates are shown.
  - The direction of the bias is corrected for folate. The UL of folate applies to synthetic folic acid only (IOM 1998), so comparing the added folic acid is the right construct; what can be missing is folic acid from foods already fortified and from supplements. For vitamin A the comparison is a lower bound, because preformed retinol from the diet is not counted.
  - The designer verifies both statements in the IOM reports and cites the page.
  - Check: Auto (sentence logic); Maintainer (wording).
- **R22. Scenario names.**
  - Requirement: the scenarios table gains an abbreviation column (`labels.csv`: label and short label). Figures use the short label, tables the full one, and the scenarios table gives both.
  - Iron rows name the compound when known; "—" is not acceptable for a form the scenario defines.
  - The method note says "biodisponibilidad del hierro 10%", not "método probabilístico (10%)".
  - Check: Auto.
- **R23. Vehicles chosen by the analyst.**
  - Requirement: `choices$vehicles` (in `_inputs.R`) selects which vehicles of `vehicles.csv` enter the report, with all vehicles by default. The package functions keep returning tidy tibbles, so an analyst can build any other figure with `ggplot2`, including facets by domain; the getting-started vignette shows one example.
  - Check: Auto.
- **R24. Language.**
  - Requirement: every sentence and label in both languages is revised for precision and register: technical and sober, no ambiguity, and consistent terms across both reports.
  - Check: Maintainer.

## C. Example data

- **X1. A realistic example.**
  - Requirement: replace `hces_example` with a synthetic survey large enough for the presentation rules to behave as with real data: about 2,000 households, 2 regions or more, 5 expenditure groups and tens of PSUs per stratum.
  - Vehicles typical of Latin America: rice, wheat flour (with bread and pasta), maize flour, sugar and vegetable oil.
  - Scenarios with plausible names and levels, labelled as invented.
  - Built by a documented and seeded script in `data-raw/`. It stays synthetic: no real microdata (CLAUDE.md).
  - Check: Auto (size and structure); Maintainer (render).
- **X2. Golden values follow the example.**
  - Requirement: the golden test is regenerated from an independent base-R computation, never from the package itself.
  - Check: Auto.

## D. Robustness and change

- **Q1. Snapshot tests.** Every exhibit of both reports, in both languages, has a snapshot test of its table (`testthat::expect_snapshot`). A change in wording or numbers shows up as a reviewable diff.
- **Q2. Exhibit registry.** One table lists every exhibit: ID, report, section, builder function, enabling verdict section and appendix table. Comments from experts cite these IDs.
- **Q3. Feedback log.** `docs/feedback/` holds one file per round of expert comments: comment, exhibit ID, decision, and the requirement or test that resulted.
- **Q4. Validation before polish.** No requirement of this document is accepted on `hces_example` alone. Acceptance needs a render with the ENGIH 2018 microdata on the maintainer's machine (v1, section C).

## E. Out of scope

- Interactive tools (v0.2).
- The Peru adapter.
- Vignettes other than the getting-started example of R23.
