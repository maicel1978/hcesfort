# Domains with small cells (DR11): one row of readiness_checks() per
# domain. Design: docs/design-reports-v3.md, section 4.3 (C5).

# Rows `domain_cells` of readiness_checks(): for each domain, `n` the
# number of its values in `households`, `value` the share of them with
# fewer than `min_n` households whose intake is estimated, `met` when that
# share is at most `max_small_cells`. A domain column absent from
# `households` gives a missing `value` (the verdict disables it as a
# missing input). A missing value of the domain is one more value, as in
# the cells of estimate_households().
domain_cell_checks <- function(intake, households, domains, min_n,
                               max_small_cells) {
  if (length(domains) == 0) {
    return(NULL)
  }
  status <- household_status_of(intake, households)
  rows <- lapply(domains, function(d) {
    if (!d %in% names(households)) {
      return(domain_cell_row(d, NA, NA, max_small_cells))
    }
    value <- as.character(households[[d]])
    cell <- match(value, unique(value))
    estimated <- tabulate(cell[status == "estimated"],
                          nbins = max(0L, cell))
    domain_cell_row(d, length(estimated), mean(estimated < min_n),
                    max_small_cells)
  })
  dplyr::bind_rows(rows)
}

# One row of the check; `met` when the share is at most the threshold.
domain_cell_row <- function(domain, n, value, threshold) {
  dplyr::tibble(
    check = "domain_cells", detail = domain, n = as.integer(n),
    value = as.numeric(value), threshold = threshold,
    met = ifelse(is.na(value), NA, value <= threshold)
  )
}

# `intake_status` of each household of `households`, in its order. The
# households must be exactly those of the intake table.
household_status_of <- function(intake, households,
                                call = rlang::caller_env()) {
  if (!is.data.frame(households) || !"household_id" %in% names(households)) {
    abort_hcesfort("schema", c(
      "{.arg households} must be a data frame with {.field household_id}."
    ), table = "households", columns = "household_id", call = call)
  }
  ids <- as.character(households$household_id)
  pos <- match(ids, as.character(intake$household_id))
  extra <- setdiff(as.character(intake$household_id), ids)
  if (anyDuplicated(ids) > 0 || anyNA(pos) || length(extra) > 0) {
    n <- sum(is.na(pos)) + length(extra) + sum(duplicated(ids))
    abort_hcesfort("join", c(
      "{.arg households} and {.arg intake} must have the same households,
      once each.",
      "x" = "{n} household{?s} unmatched or repeated.",
      "i" = "Pass the households table used to compute the intake."
    ), table = "households", other = "intake", columns = "household_id",
    n = n, call = call)
  }
  intake$intake_status[pos]
}

# `min_n` (a count of at least 1) and `max_small_cells` (a share), no
# defaults.
check_domain_cell_args <- function(min_n, max_small_cells,
                                   call = rlang::caller_env()) {
  if (missing(min_n) || !is.numeric(min_n) || length(min_n) != 1 ||
        is.na(min_n) || min_n < 1 || min_n != round(min_n)) {
    abort_hcesfort("argument", c(
      "{.arg min_n} must be one whole number of at least 1.",
      "i" = "It has no default; the template passes the {.field min_n} of
      the presentation standard."
    ), arg = "min_n", call = call)
  }
  if (missing(max_small_cells) || !is.numeric(max_small_cells) ||
        length(max_small_cells) != 1 || is.na(max_small_cells) ||
        max_small_cells < 0 || max_small_cells > 1) {
    abort_hcesfort("argument", c(
      "{.arg max_small_cells} must be one number in [0, 1].",
      "i" = "It has no default: the largest share of the values of a domain
      that may have fewer than {.arg min_n} households."
    ), arg = "max_small_cells", call = call)
  }
  invisible(TRUE)
}

# `domains`: NULL or text without missing values; `households` given.
check_domains_arg <- function(domains, households,
                              call = rlang::caller_env()) {
  if (missing(households)) {
    abort_hcesfort("argument", c(
      "{.arg households} is missing, with no default.",
      "i" = "Pass the households table the intake was computed from."
    ), arg = "households", call = call)
  }
  if (!is.null(domains) && (!is.character(domains) || anyNA(domains))) {
    abort_hcesfort("argument", c(
      "{.arg domains} must be NULL or the names of household columns."
    ), arg = "domains", call = call)
  }
  invisible(TRUE)
}
