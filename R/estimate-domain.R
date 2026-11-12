# The domain of an estimate: a logical column of `x`, of the design, or of
# a household table given in `domain_from` (correction 3 of the v0.1
# review).

# Where `domain` lives and which households of the design it holds: a list
# with `x_domain` (a column name of `x`, or NULL), `inside` (a logical
# vector over the households of the design, or NULL), `origin` and
# `n_missing` (households whose flag is missing, for `domain_from`).
resolve_domain <- function(design, x, domain, domain_from,
                           call = rlang::caller_env()) {
  vars <- design$variables
  none <- list(x_domain = NULL, inside = NULL, origin = NA_character_,
               n_missing = 0L)
  if (!is.null(domain_from)) {
    flag <- domain_from_flag(vars$household_id, domain, domain_from, call)
    return(list(x_domain = NULL, inside = flag %in% TRUE,
                origin = "domain_from", n_missing = sum(is.na(flag))))
  }
  if (is.null(domain)) return(none)
  if (rlang::is_string(domain) && is.logical(x[[domain]])) {
    return(utils::modifyList(none, list(x_domain = domain, origin = "x")))
  }
  if (rlang::is_string(domain) && is.logical(vars[[domain]])) {
    return(utils::modifyList(none, list(inside = vars[[domain]] %in% TRUE,
                                        origin = "design")))
  }
  abort_hcesfort("argument", c(
    "{.arg domain} must name a logical column of {.arg x} or of the
    households table.",
    "i" = "For a column of another hcesfort table (such as
    {.field energy_plausible}), pass that table in {.arg domain_from}."
  ), arg = "domain", call = call)
}

# The flag `domain` of `domain_from` for each household of `ids`, after
# checking: a carrier, the column logical, one row per household, and the
# same households as the design.
domain_from_flag <- function(ids, domain, domain_from, call) {
  require_hces(domain_from, "hces_tbl", arg = "domain_from", call = call)
  if (!rlang::is_string(domain) || !is.logical(domain_from[[domain]]) ||
        is.null(domain_from[["household_id"]])) {
    abort_hcesfort("argument", c(
      "{.arg domain} must name a logical column of {.arg domain_from}, which
      must have {.field household_id}."
    ), arg = "domain", call = call)
  }
  h <- domain_from$household_id
  dup <- which(duplicated(h))
  if (length(dup) > 0) {
    abort_hcesfort("key", c(
      "{.arg domain_from} must have one row per household.",
      "x" = "{length(dup)} household{?s} repeated.",
      "i" = "Filter one vehicle or one scenario first."
    ), table = "domain_from", columns = "household_id", rows = dup,
    n = length(dup), call = call)
  }
  only_design <- sum(!ids %in% h)
  only_from <- sum(!h %in% ids)
  if (only_design + only_from > 0) {
    abort_hcesfort("join", c(
      "{.arg domain_from} and the design must hold the same households.",
      "x" = "Only in the design: {only_design}; only in {.arg domain_from}:
      {only_from}."
    ), table = "domain_from", other = "design", columns = "household_id",
    n = only_design + only_from, call = call)
  }
  domain_from[[domain]][match(ids, h)]
}

# Audit rows of the domain of an estimate.
domain_log <- function(step, domain, d) {
  if (is.null(domain)) return(NULL)
  dplyr::bind_rows(
    audit_row(step, "estimate", "note", "domain", 1L,
              detail = paste0(domain, " (", d$origin, ")")),
    if (d$n_missing > 0) {
      audit_row(step, "estimate", "flagged", "domain_flag_missing",
                d$n_missing, d$n_missing, detail = domain)
    }
  )
}
