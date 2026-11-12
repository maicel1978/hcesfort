# Schemas of the reference tables taken by adult_equivalents(), and the
# check that their age intervals are well formed. The shipped tables
# (ref_energy_requirements, ref_bmr_equations) satisfy them; a user's
# replacement must too.

schema_energy_requirements <- function() {
  new_schema(
    "energy_requirements", c("sex", "age_unit", "age_from"),
    schema_col("sex", "text", "sex", values = c("female", "male")),
    schema_col("age_from", "number", "lower bound of the age interval",
               bounds = "[0, Inf)"),
    schema_col("age_to", "number", "upper bound, excluded (Inf allowed)",
               bounds = "(0, Inf]"),
    schema_col("age_unit", "text", "unit of the ages",
               values = c("month", "year")),
    schema_col("energy_kcal_d", "number", "daily energy requirement, kcal",
               bounds = "(0, Inf)"),
    schema_col("source", "text", "document and table")
  )
}

schema_bmr_equations <- function() {
  new_schema(
    "bmr_equations", c("sex", "age_from"),
    schema_col("sex", "text", "sex", values = c("female", "male")),
    schema_col("age_from", "number", "lower bound of the age interval, years",
               bounds = "[0, Inf)"),
    schema_col("age_to", "number", "upper bound, excluded (Inf allowed)",
               bounds = "(0, Inf]"),
    schema_col("slope_kcal_kg", "number", "kcal per day per kg of weight",
               bounds = "(0, Inf)"),
    schema_col("intercept_kcal", "number", "kcal per day"),
    schema_col("source", "text", "document and table")
  )
}

# Check a reference table: its schema, then that within each group the
# intervals [age_from, age_to) are not empty and do not overlap. Gaps are
# allowed; a member that falls in one is reported by the caller.
check_reference <- function(x, schema, groups, call = rlang::caller_env()) {
  check_schema(x, schema, call)
  table <- attr(schema, "table")
  bad <- which(x$age_to <= x$age_from)
  key <- interaction(x[groups], drop = TRUE)
  for (g in split(seq_len(nrow(x)), key)) {
    o <- g[order(x$age_from[g])]
    overlap <- utils::head(x$age_to[o], -1) > x$age_from[o][-1]
    bad <- c(bad, o[-1][overlap])
  }
  if (length(bad) == 0) {
    return(invisible(x))
  }
  bad <- sort(unique(bad))
  abort_hcesfort("value", c(
    "{.arg {table}} has empty or overlapping age intervals.",
    "x" = cli_escape(problem_bullet("bad interval", bad)),
    "i" = "Intervals are [age_from, age_to) and must not overlap."
  ), table = table, columns = c("age_from", "age_to"), rows = bad,
  n = length(bad), call = call)
}
