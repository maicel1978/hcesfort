# Brief: hostile review v0.2 (Fable)

Status: approved by the maintainer (2026-11-15). To be run after task 12d is closed, in its own session, by Fable at high effort. Output: `docs/review-v0.2.md`. No package code is changed in this session.

## Role

Act as three reviewers at once, each hostile but fair:

- an rOpenSci statistical software reviewer;
- a reviewer for a nutrition journal who knows HCES methods (MIMI, FACT and the work of Tang and colleagues);
- a reviewer for JOSS.

## Scope

The core and the method. The reports are out of scope: they were just rebuilt in task 12d.

1. **Estimators:** adult female equivalents, unit conversion, composition linkage, apparent intake, the unfortified baseline, scenarios, inadequacy (cut-point and the iron probability approach), the UL comparison, design-based estimation, paired differences, Korn-Graubard and the presentation standard.
2. **Data contracts and their failure modes:** silent drops, joins, units, missing values.
3. **Assumptions against the literature:** each with its source, or "unsupported".
4. **Edge cases:** one-person households, infants, zero intake, single-PSU strata, empty domains, all-zero vehicles.
5. **What a JOSS or rOpenSci reviewer would reject,** and why.

## Circular validation (priority)

The code, the tests, the example data and the golden values were all produced with AI assistance. Classify every test file by the source of its expected values:

- **(a) independent and external:** published tables (NCHS, IOM), `survey`, `binom.test()`, values typed from a document;
- **(b) independent but AI-written:** the golden base-R script;
- **(c) self-referential:** values copied from the package output.

Then:

- Report the share of core estimators covered only by (b) or (c).
- For each such estimator, propose at least one external anchor: a published worked example (for instance in the MIMI or Tang papers, or in IOM or WHO documents), an identity that can be checked by hand, or a reference implementation in another package. Give the exact source, verified in the document in this session, or mark it `# SOURCE PENDING`.
- State what the validation against the ENGIH 2018 control figures (tasks A1–A4) will and will not prove.

## Form of the output

- Numbered findings. Each has a severity (blocker, major, minor), evidence (file and line, or a reproducible R snippet that was run), and a proposed fix with the roadmap task where it fits.
- One section on circular validation, with the classification table.
- A short verdict: what must be fixed before the ENGIH validation, and what can wait.
- Questions to the maintainer at the end, numbered, each with a recommendation.

Record the findings in `docs/improvements.md` with their priority. Stop for approval.
