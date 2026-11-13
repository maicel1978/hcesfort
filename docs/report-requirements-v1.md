# Report requirements v1

Status: APPROVED by the maintainer (13-11-2026). Source: the maintainer's critique of the rendered Spanish report on `hces_example` (13-11-2026, 17 printed pages, cited below as "p. N") and a second reading of the same render. Decisions D1–D8 were taken by the maintainer on 13-11-2026; this document turns them into verifiable requirements.

Each requirement states the problem, the requirement and how it is checked. "Auto" means an automated test on the rendered HTML or on the plot and table objects; "Maintainer" means the maintainer's review of a render with the ENGIH 2018 microdata on a local machine.

## 0. Principles

- P1. Two reports. The **data readiness report** covers decisions taken *with* the data, up to the analysis table. The **results report** covers decisions taken *from* the data. (D1)
- P2. A table or figure must be correct in meaning, not only in design. If a result can be misread, it is redesigned or removed.
- P3. The report states results; the analyst interprets them. No automatic interpretive sentences. (D2)
- P4. Simplicity wins: anything redundant, decorative or uncertain in meaning is removed.
- P5. Sections depend on the data. A missing optional variable disables its section with one sentence; it never breaks the render or shows an empty figure.

## A. Data readiness report (new)

Question it answers: *Can this survey support the analysis, and what is left to do before it can?*

- **DR1. Variable inventory.**
  - Requirement: one table with every input variable, marked essential or optional, present or absent, and the results sections that depend on it.
    - Essential: household id, weights, strata and PSU, food item, quantity, unit, reference period, member age and sex.
    - Optional: domains such as region and expenditure group, acquisition mode, food eaten away from home.
  - Check: Auto (one row per contract variable); Maintainer.
- **DR2. Minimum quantity and quality.**
  - Requirement: report food-module nonresponse, records missing quantity or unit, and households without adult female equivalents, against the thresholds in the parameters (`min_records_used`, `min_coverage`). Each threshold is shown with its value and whether it is met.
  - Check: Auto (every threshold appears with its status); Maintainer.
- **DR3. Linkage ladder.**
  - Requirement: count the records at each step: records → with quantity → with grams (conversion factor) → linked to composition → validated.
  - Each step is shown as a share of records, of grams and, when available, of expenditure.
  - This replaces annex B (pp. 8–9).
  - Check: Auto (the counts are monotone non-increasing); Maintainer.
- **DR4. Work queue.**
  - Requirement: the food items still pending (unlinked, not validated, or without a conversion factor or density), ranked by frequency and by weighted grams, with the reason each is pending. Also a cumulative coverage curve: share of grams covered against the number of items resolved in rank order.
  - Rationale: this is how the plantain conversion factor was found to matter.
  - Check: Maintainer.
- **DR5. Stopping rule and its cost.**
  - Requirement: state the rule, which is to cover at least X % of grams and of expenditure (D6; X provisional = 90). Report the unlinked share by each available domain, with 95% CI, and flag a domain whose unlinked share differs from the national share.
  - Rationale: this makes the selection bias of stopping visible.
  - Check: Auto (the flag logic has a unit test); Maintainer.
- **DR6. Plausibility.**
  - Requirement: median apparent energy per adult female equivalent, nationally and by domain, against the reference energy, plus the share of households with extreme values. This moves the energy figure out of annex D (p. 10).
  - Check: Maintainer.
- **DR7. Decisions taken with the data.**
  - Requirement: a table supplied by the analyst (source of the conversion factors, composition table, outlier rule, day divisor, imputation if any) with the evidence for each decision.
  - The decisions table that used to appear on p. 8 moves here.
  - Check: Auto (the render fails with a classed error if the file is missing or malformed).
- **DR8. Readiness verdict.**
  - Requirement: a matrix listing each results section as enabled or disabled, with the reason. The results report reads this matrix to decide which sections to render.
  - Check: Auto (removing an optional variable from the example disables exactly the sections that depend on it).

Note for the designer: DR4, DR5 and DR8 may need new exported functions. The designer decides this and records it in `docs/specification.md`.

## B. Results report

- **R1. Order.**
  - Requirement: (1) coverage of the vehicles; (2) quantity among the households that acquire them; (3) risk of inadequate intake; (4) fortification scenarios; (5) contribution of each food group. Then one short technical note (R14). Order provisional (D3).
  - Remove the one-page summary table (p. 1): it repeats the sections.
- **R2. No code in the output.**
  - Requirement: no function names, no `Fuente: f()` lines, no code spans, no raw codes (`vitamin_a`, `wheat_flour`, `expenditure_group`, `unclassified`, `baseline`, `flour_and_sugar`) and no English column headers in a Spanish report (pp. 2–12).
  - Every displayed value comes from a **label table** that the analyst supplies for nutrients, vehicles, vehicle groups, scenarios, domains, domain values and food groups, in the report language. A code without a label stops the render with a classed error that lists the missing labels. The render never falls back to the raw code.
  - Check: Auto (a regex over the rendered HTML for `\w+\(\)`, `<code>` and every code value in the input tables).
- **R3. No analyst placeholders in the output.**
  - Requirement: the guidance for the analyst lives in comments in the `.qmd` file, never in the rendered text. "*Analista: …*" appeared on pp. 2, 7, 8 and 9.
  - Check: Auto (no "Analista" or "Analyst" in the HTML).
- **R4. No automatic metadata or interpretive sentences.**
  - Requirement: remove the line "Encuesta… País… Año" (p. 1) and every bold auto-generated headline (pp. 1–5). The title is a parameter written by the analyst. Section headings may stay as questions.
  - Check: Auto (no parameter value other than the title is printed in the body).
- **R5. Table before figure; formal titles.**
  - Requirement: every result has a table first and a figure second. The table title states what is measured, the population, the unit and the scenario.
  - Figures have titles on both axes with units, and legends with labels. The y axes on pp. 2, 4, 6 and 7 have no title.
  - Values are percentages, and differences are in percentage points, not proportions (p. 6: "−0.4").
  - Check: Auto (every ggplot object has non-empty `x` and `y` labels; no axis shows a proportion where the table shows a percentage); Maintainer.
- **R6. One figure per domain variable.**
  - Requirement: no facets that mix domain variables (p. 3, p. 10). Each domain variable gets its own table and figure, rendered only if DR8 enables it.
  - Check: Auto (dropping `region` from the example removes its figure and leaves one sentence instead).
- **R7. Small cells and degenerate estimates.**
  - Requirement: suppress any domain cell with fewer households than `min_n`. On p. 3 and pp. 11–12, cells of 7 and 8 households are shown although `min_n` = 10: this is a defect.
  - Show any estimate of 0 % or 100 % with SE 0 as one sentence, not as a row with an indeterminate CI (p. 5, section "who is left out"; p. 11, folate Q2). (D4)
  - Mark low-precision estimates and explain the marking once, in a table note.
  - Check: Auto (unit tests on the suppression rules).
- **R8. Coverage.**
  - Requirement:
    - Show vehicles and vehicle groups in separate tables. Explain the group in a note: "wheat flour (any form) = flour, bread or pasta". On p. 4, a 97 % figure next to a 64 % figure reads as a contradiction.
    - Report quantity among acquirers as median g per AFE per day, with CI and n.
    - Show "who is left out" only if it is not degenerate.
  - Check: Maintainer.
- **R9. Risk of inadequate intake.**
  - Requirement: this section shows **only the baseline without fortification**, one estimate per nutrient. Scenario effects belong to R10. On p. 2, vitamin A is shown under a flour scenario that adds no vitamin A, so the two points coincide and suggest an effect that does not exist.
  - State the method per nutrient in a table note: the cut-point method, or the probability method for iron with its bioavailability.
  - Check: Maintainer.
- **R10. Scenarios.** This section must hold up to hostile review.
  - (a) The scenario table uses labels and shows the level as nutrient per kg, converting compound-basis rows. It shows compliance and the source as a citation. "synthetic: invented" appears only in the example, as a footnote.
  - (b) Each scenario has one name, used in every table, figure and sentence. On p. 5 and p. 6, two naming systems appear and the same action is named twice.
  - (c) The effects table shows paired differences in percentage points with 95% CI, only for the pairs of scenario and nutrient where the scenario adds that nutrient. Then one figure per nutrient.
  - (d) Equity: one figure per nutrient and domain, not five overlapping series (p. 7).
  - (e) Upper level: a table beside the effects that names the form compared, e.g. "added folic acid only, without dietary folate", and its bias direction (see `docs/erratum-engih2018.md`).
  - (f) The figure per nutrient is a dumbbell: one row per scenario (and per domain value in the equity figure), with the baseline point and the scenario point joined by a segment, so the reader sees the size of the change. A dumbbell does not show the uncertainty of a paired difference, so the effects table in (c) carries that CI and the figure note says so. The maintainer used this chart in earlier presentations of the original analysis, where it was well received.
  - Check: Auto ((b): one label per scenario across all outputs); Maintainer.
- **R11. Food groups.**
  - Requirement: a shares table computed on the baseline without fortification. Food items with no assigned group appear as "Sin grupo asignado", with their share given in the note. Groups with a share of 0 are shown as "0" without a CI.
  - Check: Maintainer.
- **R12. Removed from the results report.** (D5)
  - Requirement:
    - remove the section "¿Qué no pueden responder estas cifras…?" and annexes A–H (pp. 7–17);
    - move the data flow, decisions and energy plausibility to the readiness report (DR3, DR6, DR7);
    - move methods, the bias direction and the STROBE-nut checklist to the technical manual;
    - write the session information to a separate `sessionInfo.txt` file;
    - drop the iron bioavailability sensitivity from the body; it goes in a table in the technical note.
  - Check: Auto (no annex headings in the HTML).
- **R13. Rendering.**
  - Requirement: no table overflows the page width in the printed output (annex B was cut off), no table row has an abnormal height (annex F took three nearly empty pages), and no figure is empty or blank (annex D).
  - Check: Maintainer (print preview); Auto where feasible.
- **R14. Technical note.**
  - Requirement: at most half a page with the reference values used (EAR and UL with their source), the iron bioavailability (with the sensitivity table) and a link to the readiness report. Open decision O2.

## C. Acceptance

1. All the Auto checks pass in `devtools::check()` on `hces_example`.
2. The maintainer renders both reports with the ENGIH 2018 microdata on a local machine, prints them and approves them. No version is accepted on the synthetic example alone. (D7)

## D. Out of scope for this round

- The interactive matching tool (v0.2, D8).
- The Peru adapter.
- Vignettes.
- The large calibrated example (queue item 6).

## E. Decisions (resolved 13-11-2026: the maintainer accepted the proposals)

- O1. Threshold X of the stopping rule: 90 % of grams and of expenditure. It is a parameter; the report states the value used.
- O2. Keep the half-page technical note (R14).
- O3. Differences in percentage points.
- O4. Quantity among acquirers stays inside the coverage section.
