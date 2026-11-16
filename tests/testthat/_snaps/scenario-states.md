# a compliance that differs within a vehicle is a value error

    Code
      aon(sc)
    Condition
      Error in `apply_scenario()`:
      ! Under "all_or_nothing" every vehicle of a scenario needs one compliance.
      x vehicle with more than one compliance in its scenario: 2 rows (1, 2)
      i A compliance that differs by nutrient is under-dosing: give the vehicle one compliance, or use "average_content".

