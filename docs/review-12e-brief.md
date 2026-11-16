# Brief: short review of steps 12e.1 to 12e.4

- **Model:** Fable, high effort. One short session; the Fable quota is nearly
  spent, so keep to the diff. No package code changes.
- **Output:** `docs/review-12e.md` (findings only, each with file, line and a
  failing input where possible), new ids in `docs/improvements.md` (search the
  last id first), a section in `docs/handoff.md`. Commit and push to the
  session branch.

## Scope

The diff `491eeb4..1605a94` of `R/`, `tests/`, `inst/report/` and
`DESCRIPTION` (steps 12e.1 to 12e.4), read against what was approved:

- `docs/review-v0.2.md`: findings 1, 2, 3, 6, 9, 10 to 15 and 18, and
  section 8;
- the answers R2-D1 to R2-D9 and R3-D1 to R3-D9 in `docs/improvements.md`.

## Questions to answer

1. Is each approved correction done as approved, and nothing else changed in
   behaviour? List any change of behaviour not covered by an approval.
2. Are the new tests able to fail? For the key check (12e.1), the
   anchors (12e.2) and the interval rules (12e.4), name any test whose
   expected value comes from the package's own output.
3. The effective size (12e.4): `n / deff`, capped at `n`. Is the design
   effect computed as the NCHS standard defines it for a proportion and for a
   mean? Does the change of the golden values follow from it?
4. `Config/testthat/parallel: true`: can any test share state (snapshots,
   temporary files, options) and so pass or fail by order?
5. Blockers for the ENGIH acceptance (A3): anything in the diff that would
   stop the package from reproducing the original with `df = "design"` and
   `ci_method = "mean"` (`docs/design-adapter-engih.md`, section 3).

Do not re-review what the review v0.2 already covered outside this diff.
