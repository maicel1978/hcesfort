# Review of the all-or-nothing compliance model (12e.5.6, 12e.5.7)

- **Date:** 2026-11-17. **Model:** Fable, high effort.
- **Scope:** the diff `f283284..4cc3e6c` of `R/`, `tests/` and
  `inst/report/`, read against `docs/design-12e5.md`, section 4, and
  R3-D1 to R3-D9. Brief: `docs/review-12e5-states-brief.md`. No package
  code changed.
- **Result:** the model is implemented as designed. The expectation over
  states is right by hand, the probabilities sum to 1 in every case tried,
  the survey weight enters once, and 9 of 11 non-equivalent mutations are
  caught by the tests. Two findings of substance: the total-intake path of
  `above_ul()` on the states table has no test (S3.1), and the premise of
  question 4, that average content is a lower bound, is false in general
  and on `hces_example` (S4.1). On size (S5), the log is not enough as the
  only protection; one optional, visible argument is recommended.
- **Items:** P217 to P220 in `docs/improvements.md`.

Scripts of this review (not committed): the hand checks, the bounds on
`hces_example`, the memory measurement and the mutation runner were run
in the session's scratchpad; every number below is from their output.

## 1. Expected value

**S1.1 (ok).** `collapse_states()` (`R/risk-states.R`, lines 18–31) sums
`state_probability × value` per key with `rowsum()`, on the rows of
`inadequacy_rows()` and `ul_rows()`, which compute each state as any
scenario. This is the probability-weighted expectation per household,
before any survey estimate. Checked by hand on household 1 of the fixture
`two_vehicles()` (flour 0.5, sugar 0.8; baseline iron 1 mg; EAR 5):

| state | probability | iron_mg | below EAR |
|---|---|---|---|
| none | 0.1 | 1.0 | 1 |
| flour | 0.1 | 6.5 | 0 |
| sugar | 0.4 | 3.0 | 1 |
| flour+sugar | 0.4 | 8.5 | 0 |

`p_inadequate` = 0.1 + 0.4 = 0.5 and `intake` = 5.35, both as the package
gives. The test "two vehicles at 0.5 and 0.8: inadequacy by hand" holds
the same values.

**S1.2 (ok).** The household weight enters once. The states table carries
no weight; `estimate_households()` refuses it (`refuse_states()`), and the
collapsed table has one row per household, so the design weight is applied
once in the estimator. Checked with weights 1, 3, 1 on the fixture: the
estimate of `p_inadequate` for scenario `both`, iron, is 0.875 = (0.5 × 1
+ 1 × 3) / 4 by hand.

**S1.3 (ok).** The non-expected columns of the result (`intake_status`,
`coverage`, `share_records_used`, `ul_scope`, …) are taken from the first
state. They come from the baseline and are equal across states, so the
choice does not matter (mutation M10, which takes the last state, is
equivalent and survives for that reason).

**S1.4 (ok).** The rows of the result are in the same order as under
average content: the test "compliance 1 everywhere: both models give the
same tables" compares whole data frames and passes. On `hces_example` with
two iron bioavailabilities the collapsed `inadequacy()` has 60,000 rows,
as under average content (2,000 households × 6 scenarios × 5 blocks).

## 2. States

**S2.1 (ok).** `scenario_state_list()` (`R/scenario-states.R`, lines
46–62) enumerates the 2^k subsets of the vehicles with compliance strictly
in (0, 1); vehicles at 1 are always on, at 0 always off. The
probabilities sum to 1 per scenario and household in every case tried:
two partial vehicles (0.5, 0.8); (0, 1); (0, 0); (1, 1); (0.3, 0); the
baseline; a scenario with no rows; and a vehicle nobody acquires (`pasta`
at 0.5 gives two states with probability 0.5 each, the same intake in
both). A household that buys none of the vehicles still gets 2^k rows;
its result equals the baseline, as expected (see S5.3 for the cost).

**S2.2 (ok).** Independence between vehicles is the product rule of line
59, as the design says; stated in `?apply_scenario` ("vehicles are assumed
independent, so the probability of a state is the product …"), in the
report note `ul_model_all_or_nothing` (en and es), and in the log row
`vehicles_assumed_independent`. `?inadequacy` and `?above_ul` name the
states and the weights but not independence; one cross-reference to
`?apply_scenario` would do (no item: a sentence for 12e.5.8).

**S2.3 (low, P220).** A vehicle name that contains `+` makes the state
label ambiguous, and two different states can share a label. Failing
input: vehicles `a`, `b` and `a+b` (the third never acquired) in one
scenario at compliance 0.5. `apply_scenario()` returns the states `a+b`
(the vehicle `a+b` on) and `a+b` (vehicles `a` and `b` on) with different
added amounts and a repeated key, and does not fail; `inadequacy()` then
aborts with `hcesfort_error_key` and a message that blames a join between
functions. `check_vehicle_compliance()` is the place for the check (a `+`
in a vehicle name under all or nothing), or the label should use a
separator the schema forbids.

**S2.4 (ok).** A missing compliance is refused by `validate_scenarios()`
(`hcesfort_error_value`) before the states are built; a compliance that
differs within a vehicle gives the classed error with the rows (snapshot).
The same vehicle may differ between scenarios (tested).

## 3. Can the tests fail?

Mutation runner: a copy of the repository per mutation, the four test
files `scenario-states`, `risk-states`, `above-ul` and `apply-scenario`
(58 tests), unmutated control 0 failures.

| Mutation | Where | Failures |
|---|---|---|
| M1 swap the probability (c for 1 − c) | `scenario_state_list()` | 6 |
| M2 drop the all-on state | `scenario_state_list()` | 9 |
| M3 count the first state twice in the collapse | `collapse_states()` | 5 |
| M4 plain mean over states instead of weighted | `collapse_states()` | 4 |
| M5 every state at the full level of all vehicles | `states_rows()` | 8 |
| M6 `above_ul_total` not collapsed | `above_ul()` | **0** |
| M7 `amount_total` not collapsed | `above_ul()` | **0** |
| M8 targets at the given compliance, not at 1 | `apply_scenario()` | 8 |
| M9 the understates flag also under all or nothing | `understates_ul_rows()` | 1 |
| M10 constant columns from the last state (equivalent) | `collapse_states()` | 0 |
| M11 compliance 1 counted as partial | `scenario_state_list()` | 3 |
| M12 `added` not collapsed in `inadequacy()` | `inadequacy()` | 1 |

**S3.1 (medium, P217).** `above_ul_total` and `amount_total` on the
states table are not tested: the states tests use `states_ul()`, a UL on
folic acid with the added part only (`form_added_only`), so a collapse
that leaves `above_ul_total` or `amount_total` as the value of the first
state passes every test, including the report test under all or nothing
(it only checks the range 0 to 100). Failing input, fixture
`two_vehicles()`, UL on total iron of 6 mg: household 1 has
`amount_total` 5.35 and `above_ul_total` 0.1 × [6.5 > 6] + 0.4 × [8.5 >
6] = 0.5 (the package gives both); under M6 the value would be 0, under
M7 the amount 1. A test with this input, and one with a form that has a
diet part (`form_diet_and_added`, as "a form with both parts" in
`test-above-ul.R`), closes the gap. On `hces_example`, `above_ul_total`
for iron under `plus_oil` is 0.0023 (all or nothing) against 0.0020
(average content), so the path is exercised by the report without being
checked.

**S3.2 (note).** Tests whose expected value comes from the package's own
output (consistency tests, not hand values): "the expected added amount
equals that of average content" (both files), "compliance 1 everywhere"
(both files), "invariant: row order" (both files), "one vehicle: above
the UL is c × [full] + (1 − c) × [baseline]" (`full` is the package at
compliance 1) and "the estimate is the same combination of two
`svymean()`" (`y_full` and `y_base` from the package; `svymean()` is the
external anchor). The hand-anchored tests are "four states by hand", "one
vehicle at 0.5", "rows … probabilities sum to 1", "the hand example",
"two vehicles … inadequacy by hand", the last assertions of the two
one-vehicle tests (0.9 and 0.3 / 3) and the log test. The mix is
adequate: M1 to M5 and M8 are each caught by at least one hand-anchored
test.

**S3.3 (note).** M9 and M12 are caught by one test each. Enough, but the
understates flag under all or nothing deserves an assertion of its own
rather than a line inside the one-vehicle test.

## 4. Bounds

**S4.1 (low, P218).** The premise of the question is false in general:
average content is **not** a lower bound of all or nothing. For one
vehicle with added amount `A` and compliance `c`, average content gives
`[c·A > UL]` and all or nothing `c·[A > UL]`; a household with `c·A > UL`
counts 1 under average content and `c` under all or nothing. The fixture
already shows it: in "one vehicle: above the UL …", household 1 at
compliance 0.9 has `above_ul_added` 1 under average content and 0.9 under
all or nothing. On `hces_example` (survey-weighted shares over the
estimated households, every nutrient and scenario, `ref_requirements`):

| column | aon ≤ compliance 1 | average ≤ aon |
|---|---|---|
| `above_ul_added` | all 12 | 11 of 12 |
| `above_ul_total` | all 12 | all 12 |
| `p_inadequate` (aon ≥ compliance 1, average ≥ aon) | all 24 | 10 of 24 |

The reversal: `plus_sugar`, vitamin A, `above_ul_added` 0.000468 under
average content against 0.000328 under all or nothing (and 0.000468 at
compliance 1). Per household, all 38 rows with 1 under average content
have less than 1 under all or nothing. For `p_inadequate` the two models
are not ordered either (`wheat_flour` iron 0.67370 against 0.67367; zinc
0.26441 against 0.26407).

The upper bound holds in general: the all-on state is the state at
compliance 1 and adding a fortificant never lowers an amount, so
`above_ul` under all or nothing is at most the figure at compliance 1, and
`p_inadequate` at least. Where the text says more than that it should be
corrected: `?above_ul` ("the share at compliance c under all-or-nothing is
near c times the share at compliance 1, which can be far above the
average-content figure": true as written, but the surrounding sentence
"no household ever receives the full dose, so the share is understated"
and the report note `ul_average_content` ("the share above the upper
level is understated") state an ordering that does not hold). The right
statement: the two models give the same mean and are not ordered in the
shares; the figure at compliance 1 bounds both. This matters for
12e.5.8, which adds the column at compliance 1 to the upper-level
exhibit: that column is the bound, the average-content column is not a
floor.

## 5. Size (P213)

**S5.1 (measured).** On `hces_example` (2,000 households, 6 scenarios,
3 to 7 vehicles of partial compliance):

| | average content | all or nothing |
|---|---|---|
| rows of the scenario table | 12,000 | 498,000 |
| rows of `plus_oil` (7 vehicles, 128 states) | 2,000 | 256,000 |
| size of the table | – | 98.8 MB (208 bytes per row, 28 columns) |
| peak memory, `apply_scenario()` + `above_ul()` + `inadequacy()` | 128 MB | 830 MB |
| time of `apply_scenario()` | 0.4 s | 11.0 s |

Scaled to 9,000 households with the same scenarios: 2.24 million rows,
about 445 MB for the states table and about 3.7 GB of peak memory for
the three steps (the collapse builds one tibble per nutrient and
bioavailability over all state rows before summing). With 10 vehicles of
partial compliance in one scenario: 1,024 states × 9,000 = 9.2 million
rows, 1.9 GB for the table alone, and the collapse several times that.
Twelve vehicles would not fit a typical workstation.

**S5.2 (recommendation).** The log alone is not enough: it is written
after the rows are built, which is when the memory is spent, and the
failure mode of P213 (a typo of 0.99 for 1 over many vehicles) kills the
session before any log is readable. The protection should run before
`states_rows()`, from numbers known at that point (households × Σ 2^k
and the column count). Without a fixed threshold (maintainer's decision),
two things, both visible:

1. `apply_scenario()` gains `max_states` (the largest 2^k allowed per
   scenario; `NULL`, the default, means no limit and the help says so).
   Above it, `hcesfort_error_value` names the scenarios, their `k`, the
   rows the table would have, and suggests `"average_content"`, raising
   the limit or splitting the scenario. The report template sets it in
   `_inputs.R` as a visible choice next to `compliance_model`.
2. The log row `states` adds, per scenario, the rows and the approximate
   size in MB (rows × columns × 8 bytes), so the audit says what the
   table costs even when no limit is set.

Not recommended now: building only the states a household can
distinguish (2^(k_h) with `k_h` its partial vehicles acquired). On
`hces_example` that is 154,487 rows against 498,000 (31%), but the
probabilities then differ by household, the label `none` would absorb the
vehicles not acquired, and the design's "the probabilities are the same
for every household" would no longer hold; it belongs with P214 in task
12 if the size of a real survey asks for it. P214 (time linear in
vehicles) stays as recorded: 11 s on the example is acceptable, about one
minute on 9,000 households.

**S5.3 (note).** The 2^k rows of a household that acquires none of the
partial vehicles carry the same intake in every state; they are the
price of the uniform probabilities and are counted in S5.1.

## Not reviewed

12e.5.1 to 12e.5.5, as the brief says. P215 and P216 (log counts in state
rows; the gates read the first scenario) were confirmed in passing and
need no new item.
