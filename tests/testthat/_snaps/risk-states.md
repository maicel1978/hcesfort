# the estimators refuse the table of states

    Code
      estimate_households(d, s, "iron_mg", statistic = "mean")
    Condition
      Error in `estimate_households()`:
      ! `x` is a table of states of all-or-nothing compliance.
      x Its rows are states of a household, not households.
      i Pass it to `inadequacy()` or `above_ul()` first; the means of intake by scenario are those of `compliance_model = "average_content"`.

