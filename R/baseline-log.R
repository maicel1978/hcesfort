# Argument checks and audit rows of unfortified_baseline().

# Abort on a bad `method`, on a table that is already a baseline (applying
# the rules twice would remove the enrichment twice), or on a conversions
# table without the needed columns.
check_baseline_args <- function(comp, method, conversions,
                                call = rlang::caller_env()) {
  methods <- c("subtract", "replace_by_ingredient")
  if (!rlang::is_string(method) || !method %in% methods) {
    abort_hcesfort("argument", c(
      "{.arg method} must be one of {.val {methods}}."
    ), arg = "method", call = call)
  }
  if (!is.null(comp[["baseline_status"]])) {
    abort_hcesfort("argument", c(
      "{.arg composition} is already an unfortified baseline.",
      "x" = "It has the column {.field baseline_status}.",
      "i" = "Apply the rules to the original composition table, once."
    ), arg = "composition", call = call)
  }
  check_conversions(conversions, call = call)
}

# Abort when an id of `enrichment` has another type than the composition
# ids, or is absent from the composition table.
check_enrichment_ids <- function(comp, e, call = rlang::caller_env()) {
  for (col in c("composition_id", "enriched_ref_id", "unenriched_ref_id")) {
    ids <- e[[col]][!is.na(e[[col]])]
    if (length(ids) == 0) next
    if (!same_id_type(ids, comp$composition_id)) {
      abort_hcesfort("join", c(
        "{.field {col}} of {.arg enrichment} and {.field composition_id} of
        {.arg composition} differ in type."
      ), table = "enrichment", other = "composition", columns = col,
      n = NA_integer_, call = call)
    }
    absent <- unique(ids[!ids %in% comp$composition_id])
    if (length(absent) > 0) {
      n <- length(absent)
      abort_hcesfort("join", c(
        "{n} id{?s} in {.field {col}} of {.arg enrichment} {?is/are} not in
        {.arg composition}.",
        "x" = "Id{?s}: {.val {utils::head(absent, 5)}}."
      ), table = "enrichment", other = "composition", columns = col, n = n,
      call = call)
    }
  }
  invisible(TRUE)
}

# Abort when a pair rule has a reference row without a value for its
# nutrient, or when an `added` rule is used with the legacy method.
check_rule_values <- function(rules, method, call) {
  no_ref <- which(rules$pair & (is.na(rules$enriched) |
                                  is.na(rules$unenriched)))
  legacy <- which(!rules$pair & method == "replace_by_ingredient")
  if (length(no_ref) + length(legacy) == 0) {
    return(invisible(rules))
  }
  rows <- sort(c(no_ref, legacy))
  abort_hcesfort("value", c(
    "Some rules of {.arg enrichment} cannot be applied.",
    "x" = cli_escape(problem_bullet("reference row without a value",
                                    no_ref)),
    "x" = cli_escape(problem_bullet(
      "`added` rule with method \"replace_by_ingredient\"", legacy
    )),
    "i" = paste(
      "Fill the reference rows first ({.fn fill_composition}), or state",
      "the amount with {.field added} and {.code method = \"subtract\"}."
    )
  ), table = "enrichment", columns = "nutrient", rows = rows,
  n = length(rows), call = call)
}

# Audit rows of unfortified_baseline().
baseline_log <- function(rules, method, out, forms, n_rules) {
  step <- "unfortified_baseline"
  per_column <- function(kind, cause, f) {
    if (!any(f)) return(NULL)
    counts <- table(rules$column[f])
    audit_row(step, "composition", kind, cause, as.integer(counts),
              detail = names(counts))
  }
  one <- function(kind, cause, n, detail = NA_character_) {
    if (n == 0) return(NULL)
    audit_row(step, "composition", kind, cause, n, detail = detail)
  }
  has <- !is.na(rules$value)
  dplyr::bind_rows(
    audit_row(step, "composition", "input", "all", nrow(out)),
    if (n_rules == 0) {
      audit_row(step, "composition", "note", "no_enrichment_rules", 0L)
    },
    one("note", "method_replace_by_ingredient",
        if (method == "subtract") 0L else n_rules),
    per_column("note", "enrichment_removed", has),
    per_column("note", "difference_not_positive", has & rules$not_positive),
    per_column("note", "rule_not_needed", !has),
    per_column("flagged", "floored", has & rules$floored),
    one("flagged", "fortified_no_rule",
        sum(out$baseline_status == "fortified_no_rule")),
    if (any(forms$n > 0)) {
      k <- forms$n > 0
      audit_row(step, "composition", "flagged", "form_without_rule",
                forms$n[k], detail = forms$column[k])
    }
  )
}
