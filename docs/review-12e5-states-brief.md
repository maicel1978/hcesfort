# Brief: short review of the all-or-nothing compliance model (12e.5.6, 12e.5.7)

- **Model:** Fable, high effort. One short session; the Fable quota is nearly
  spent, so keep to the diff and write as you go. No package code changes.
- **Output:** `docs/review-12e5-states.md` (findings only, each with file,
  line and a failing input where possible), new ids in
  `docs/improvements.md` (search the last id first), a short section in
  `docs/handoff.md` that does not change its "Exact next step". Commit and
  push to the session branch after each question answered, so that a cut
  loses nothing.

## Scope

The diff `f283284..4cc3e6c` of `R/`, `tests/` and `inst/report/` (steps
12e.5.6 and 12e.5.7), read against `docs/design-12e5.md`, section 4, and the
decisions R3-D1 to R3-D9 in `docs/improvements.md`.

## Questions to answer, in this order

1. **Expected value.** Is the collapse of the states table in
   `inadequacy()` and `above_ul()` the probability-weighted expectation over
   states, per household, before any survey estimate? Check by hand on one
   household with two vehicles (four states). Is the household weight used
   once only?
2. **States.** Do the state probabilities sum to 1 per household, including
   households that buy none of the vehicles, one vehicle, and a vehicle with
   compliance 0 or 1? Are vehicles treated as independent, as the design
   says, and is that stated in the help?
3. **Can the tests fail?** Run a few mutations (swap a probability, drop a
   state, double-count the baseline). Name any test whose expected value
   comes from the package's own output.
4. **Bounds.** On `hces_example`, is the above-UL figure under all or
   nothing between the mean-content figure and the bound at compliance 1,
   for every nutrient and scenario? Is a reversal possible in principle?
5. **Size (P213).** Number of rows produced for `plus_oil` and memory on a
   survey of about 9,000 households. Is reporting the number of states in
   the audit log enough, or is a limit needed? Recommend; do not implement.

Do not re-review 12e.5.1 to 12e.5.5.
