# a compliance that differs within a vehicle is a value error

    Code
      aon(sc)
    Condition
      Error in `apply_scenario()`:
      ! Under "all_or_nothing" every vehicle of a scenario needs one compliance.
      x vehicle with more than one compliance in its scenario: 2 rows (1, 2)
      i A compliance that differs by nutrient is under-dosing: give the vehicle one compliance, or use "average_content".

# max_states stops a call before the rows are built (P219)

    Code
      aon(sc, max_states = 3)
    Condition
      Error in `apply_scenario()`:
      ! 1 scenario has more states than `max_states` (3).
      x both (2 vehicles, 4 states)
      i The table of states would have 21 rows (3 households times the states of every scenario and the baseline).
      i Use "average_content", raise `max_states`, or split the scenario.

