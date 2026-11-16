# Brief: design of the ENGIH 2018 adapter and of the acceptance test

- **Model:** Fable, high effort. One session. No package code; no microdata.
- **Approved by the maintainer:** 2026-11-15 (the ENGIH validation is the only
  check of the package that is not AI against AI; it has no design yet).
- **Output:** `docs/design-adapter-engih.md`, plus the open items in
  `docs/improvements.md` (search the last id first) and a new
  `docs/handoff.md` section. Commit and push to the session branch.

## Why

The review v0.2 (section 5.5) says what the ENGIH validation proves and what
it does not. A1 to A4 in `docs/roadmap.md` are one line each. The adapter is
where a real survey meets the contracts: units, recall days, the overlap of
sections 2 and 3A, own production, infants. Errors there change every figure.

## Read

- `docs/roadmap.md`: A1 to A4 and step 12e.5.
- `docs/analysis-map.md` whole (errors E1 to E26).
- `docs/specification.md`: the contracts of the standard tables.
- `docs/design-12e5.md`: the sections on infants, `fortifiable` and
  missing composition values (the final contract the adapter must meet).
- `docs/review-v0.2.md`: section 5.5 only.
- The original pipeline: repository `maicel1978/analisis_ENGIH2018`, branch
  `main` (the maintainer adds it to the session). Read its scripts and
  `data/auditoria/cifras_control/`. Do not copy microdata anywhere.

## Design, in this order

1. **Mapping.** Each ENGIH file and variable to each standard table and
   column, with units, keys and expected cardinality. Which variable says the
   origin of an acquisition (purchase, own production, gift), and so how the
   adapter sets `fortifiable`. Infants and pregnancy: what the survey records.
2. **A1, control figures.** The exact list to export from the original
   pipeline, and the script the maintainer runs locally to export them (with
   md5 of the inputs). Include the open checks of E2 and E4.
3. **A3, step 1.** The original choices as explicit options of the package;
   for each figure, the tolerance and why. Which original choices the package
   cannot reproduce, and what to do then.
4. **A4, step 2.** Each erroneous default (E1 to E26) corrected one at a time:
   the expected direction and rough size of the change, so that a surprise is
   visible.
5. **Download and reproducibility.** A script that downloads the microdata
   from the public source recorded in `analisis_ENGIH2018`
   (`reports/INFORME_factibilidad.qmd`), checks md5, and never commits them.
6. **Structure of the companion repository** `hcesfort.engih2018`: files,
   what runs in CI (no microdata) and what runs only locally.
7. **An end-to-end external anchor.** Search for a published, reproducible
   worked example of apparent intake from an HCES (data and results
   available). If one exists and is usable, say how to turn it into a test;
   if not, say so. Cite only what was opened in the session.

## Rules

- Questions to the maintainer: at the end, numbered, each with the
  recommended option and why. Only what you cannot decide from the documents.
- Keep the note to what A1 to A4 need. No v0.2 features.
- Sources not opened: `# SOURCE PENDING`.
