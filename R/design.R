#' Survey design of the households
#'
#' Declare the complex sampling design of the survey from the households
#' table: primary sampling units nested in strata, with the household
#' weights. Every estimate of the package is computed on this design, on the
#' full sample: a subset (a region, the households with an estimate, the
#' households with plausible energy) is a domain of the design, never a
#' smaller design (E5 of the original analysis), and variances are computed
#' by Taylor linearisation.
#'
#' A stratum with a single primary sampling unit has no variance of its
#' own. What to do with it is a choice of the analyst, so `lonely_psu` has
#' no default; its values are those of the option `survey.lonely.psu` of the
#' survey package (see `?survey::svyCprod`): `"fail"`, `"remove"`,
#' `"adjust"`, `"average"` or `"certainty"`. The choice is stored with the
#' design and applied by [estimate_prevalence()] and
#' [estimate_difference()], so the global option is never left changed.
#' Under `"fail"`, a domain with such a stratum is an
#' `hcesfort_error_value`.
#'
#' The design is a plain `survey` design otherwise, and a further estimate
#' computed directly with `survey` or `srvyr` does **not** see the choice:
#' it uses the global option. Apply it around such a call:
#'
#' ```
#' old <- options(survey.lonely.psu = attr(design, "hces_lonely_psu"))
#' survey::svymean(~x, design)
#' options(old)
#' ```
#'
#' @param households Households table ([hces_schema()]`("households")`),
#'   validated or not. Its other columns (region, area, quintile) are kept
#'   as domain variables.
#' @param lonely_psu What to do with strata of a single primary sampling
#'   unit; required.
#' @returns A survey design of class `tbl_svy` (srvyr), usable with the
#'   functions of `survey` and `srvyr`, with the attribute
#'   `hces_lonely_psu`.
#' @seealso [estimate_prevalence()], [estimate_difference()].
#' @examples
#' design <- as_hces_design(hces_example$households, lonely_psu = "adjust")
#' design
#' @export
as_hces_design <- function(households, lonely_psu) {
  check_required()
  h <- validate_households(households)
  choices <- c("fail", "remove", "adjust", "average", "certainty")
  if (missing(lonely_psu) || !rlang::is_string(lonely_psu) ||
        !lonely_psu %in% choices) {
    abort_hcesfort("argument", c(
      "{.arg lonely_psu} must be one of {.val {choices}}.",
      "i" = paste(
        "It has no default: a stratum with one primary sampling unit is",
        "the analyst's decision (see {.code ?survey::svyCprod})."
      )
    ), arg = "lonely_psu")
  }
  data <- as.data.frame(dplyr::as_tibble(h))
  design <- srvyr::as_survey_design(
    data, ids = "psu", strata = "stratum", weights = "weight", nest = TRUE
  )
  attr(design, "hces_lonely_psu") <- lonely_psu
  design
}

# Abort unless `design` was built by as_hces_design().
require_design <- function(design, call = rlang::caller_env()) {
  if (inherits(design, "survey.design2") &&
        !is.null(attr(design, "hces_lonely_psu", exact = TRUE))) {
    return(invisible(design))
  }
  abort_hcesfort("argument", c(
    "{.arg design} must be a design built by {.fn as_hces_design}.",
    "i" = "It carries the choice for strata with a single PSU."
  ), arg = "design", call = call)
}

# For each household of the design, the value of `value` in each group of
# `x` (the key columns other than household_id), and the domain flag.
# Returns a list with `keys` (one row per group) and `values` (a matrix,
# households by groups).
align_values <- function(design, x, value, domain,
                         call = rlang::caller_env()) {
  ids <- design$variables$household_id
  check_value_column(x, value, call)
  absent <- setdiff(unique(x$household_id), ids)
  if (length(absent) > 0) {
    abort_hcesfort("join", c(
      "{length(absent)} household{?s} of {.arg x} {?is/are} not in the
      design.",
      "i" = "Build the design from the households table of the analysis."
    ), table = "x", other = "design", columns = "household_id",
    n = length(absent), call = call)
  }
  key <- setdiff(attr(x, "audit_key", exact = TRUE), "household_id")
  keys <- unique(dplyr::as_tibble(x)[key])
  g <- match(group_id(x, key), group_id(keys, key))
  y <- as.numeric(x[[value]])
  if (!is.null(domain)) y[!(x[[domain]] %in% TRUE)] <- NA_real_
  values <- matrix(NA_real_, length(ids), nrow(keys))
  values[cbind(match(x$household_id, ids), g)] <- y
  list(keys = keys, values = values)
}

# One string per row identifying the combination of `key` columns.
group_id <- function(x, key) {
  if (length(key) == 0) return(rep("", nrow(x)))
  do.call(paste, c(lapply(key, function(k) as.character(x[[k]])),
                   sep = "\r"))
}
