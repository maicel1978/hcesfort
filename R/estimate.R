#' Estimate proportions, means and medians on the survey design
#'
#' Estimate, for each group of a result table (scenario, nutrient,
#' bioavailability, vehicle) and each domain, the proportion, mean or median
#' of one of its columns, with its standard error and confidence interval,
#' on the full design. Households whose value is missing (not estimated,
#' outside `domain`) are outside the domain of estimation, not dropped from
#' the design.
#'
#' * `"proportion"`: a 0/1 indicator or a probability (`p_inadequate`,
#'   `above_ul_total`, `acquired`); interval by [survey::svyciprop()] with
#'   `ci_method` (`"logit"` by default, which stays between 0 and 1; `"mean"`
#'   is the symmetric interval of the original analysis, E24).
#' * `"mean"`: [survey::svymean()] and a *t* interval.
#' * `"median"`: [survey::svyquantile()] at 0.5, interval by its default
#'   (Woodruff) method.
#'
#' A proportion whose values in the domain are all 0 (or all 1) is
#' returned as that exact value with `se = 0` and no interval (`ci_low`,
#' `ci_high` missing), and counted in the log (`degenerate_proportion`):
#' the interval methods give either a spurious estimate (`"logit"`) or no
#' limits (`"beta"`) there, and a sample of few households is not
#' certainty.
#'
#' Degrees of freedom of the *t* intervals: `"domain"` (by default) uses
#' those of the domain, `survey::degf()` of the subset design, as the
#' original analysis did and as `survey` does on a subset; `"design"` those
#' of the full design; or a number (`Inf` for normal intervals).
#'
#' @param design A design built by [as_hces_design()].
#' @param x A table returned by [inadequacy()], [above_ul()],
#'   [apply_scenario()], [apparent_intake()] or [vehicle_coverage()].
#' @param value Name of the column of `x` to estimate.
#' @param statistic `"proportion"`, `"mean"` or `"median"`.
#' @param by `NULL`, or names of domain columns of the design (households
#'   table), such as `"region"`; each combination of their values is a
#'   domain.
#' @param domain `NULL`, or the name of a logical column: only households
#'   where it is `TRUE` enter the domain. Looked up in `domain_from` when
#'   given, else in `x`, then in the design.
#' @param domain_from `NULL`, or a table returned by hcesfort with
#'   `household_id` and the column `domain`, one row per household of the
#'   design (for example the result of [flag_energy_plausibility()], or of
#'   [vehicle_coverage()] filtered to one vehicle). A household whose flag
#'   is missing is outside the domain and counted in the log
#'   (`domain_flag_missing`). Its log rows not already in the log of `x`
#'   are added, so the thresholds behind the flag stay with the estimate.
#' @param ci_method Interval method for proportions, passed to
#'   [survey::svyciprop()].
#' @param level Confidence level.
#' @param df `"domain"`, `"design"` or a number.
#' @returns A tibble of class `hces_estimate` (and `hces_tbl`): the group
#'   columns of `x`, the `by` columns, `statistic`, `variable`, `estimate`,
#'   `se`, `ci_low`, `ci_high`, `conf_level`, `df`, `n` (households in the
#'   domain) and `n_missing` (households of the `by` domain whose value is
#'   missing). Its audit log continues the log of `x`.
#' @seealso [estimate_difference()], [flag_precision()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' eq <- subset(ref_bmr_equations, sex == "female" & age_from == 18)
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households)
#' design <- as_hces_design(hces_example$households, lonely_psu = "adjust")
#' estimate_households(design, use, "acquired", by = "region")
#' @export
estimate_households <- function(design, x, value, statistic = "proportion",
                                by = NULL, domain = NULL, domain_from = NULL,
                                ci_method = "logit", level = 0.95,
                                df = "domain") {
  check_required()
  require_design(design)
  require_hces(x, "hces_tbl")
  check_estimate_args(design, x, statistic, by, ci_method, level, df)
  d <- resolve_domain(design, x, domain, domain_from)
  a <- align_values(design, x, value, d$x_domain)
  cells <- by_cells(design, by, d$inside)
  out <- lapply(seq_len(nrow(a$keys)), function(k) {
    dplyr::bind_rows(lapply(seq_along(cells$masks), function(j) {
      est <- with_lonely_psu(design, estimate_cell(
        design, a$values[, k], cells$masks[[j]], statistic, ci_method,
        level, df
      ))
      dplyr::bind_cols(a$keys[k, ], cells$levels[j, ], est)
    }))
  })
  out <- dplyr::bind_rows(out)
  out$variable <- rep(value, nrow(out))
  log <- estimate_log("estimate_households", design, x, value, statistic,
                      ci_method, df, out)
  log <- dplyr::bind_rows(domain_input_log(x, domain_from), log,
                          domain_log("estimate_households", domain, d))
  new_hces_tbl(out, "hces_estimate", log, c(names(a$keys), by))
}

# One estimate on the design: `y` the values of the households (NA outside
# the domain), `mask` the households of the `by` cell.
estimate_cell <- function(design, y, mask, statistic, ci_method, level,
                          df) {
  inside <- mask & !is.na(y)
  y[is.na(y)] <- 0
  d <- stats::update(design, .y = y)
  sub <- d[inside, ]
  n <- sum(inside)
  dfv <- if (identical(df, "domain")) survey::degf(sub) else
    if (identical(df, "design")) survey::degf(design) else df
  na_row <- dplyr::tibble(statistic = statistic, estimate = NA_real_,
                          se = NA_real_, ci_low = NA_real_,
                          ci_high = NA_real_, conf_level = level, df = dfv,
                          n = n, n_missing = sum(mask & !inside))
  if (n == 0) return(na_row)
  if (statistic == "proportion" && degenerate(y[inside])) {
    na_row[c("estimate", "se")] <- list(y[inside][[1]], 0)
    return(na_row)
  }
  r <- switch(
    statistic,
    proportion = {
      e <- survey::svyciprop(~.y, sub, method = ci_method, level = level,
                             df = dfv)
      c(stats::coef(e), survey::SE(e), attr(e, "ci"))
    },
    mean = {
      e <- survey::svymean(~.y, sub)
      c(stats::coef(e), survey::SE(e), stats::confint(e, level = level,
                                                      df = dfv))
    },
    median = {
      e <- survey::svyquantile(~.y, sub, quantiles = 0.5, ci = TRUE,
                               alpha = 1 - level, df = dfv)
      c(stats::coef(e), survey::SE(e), stats::confint(e))
    }
  )
  na_row[c("estimate", "se", "ci_low", "ci_high")] <- as.list(unname(r))
  na_row
}

# The log of `x` followed by the rows of the log of `domain_from` it does
# not hold yet.
domain_input_log <- function(x, domain_from) {
  if (is.null(domain_from)) return(audit_get(x))
  audit_combine(x, domain_from)
}

# TRUE when every value is 0 or every value is 1: the proportion is exact
# in the sample and no interval method gives a usable interval.
degenerate <- function(y) {
  all(y == 0) || all(y == 1)
}

# Evaluate `expr` with the option survey.lonely.psu set to the choice
# stored on `design`, restoring the option afterwards. The error of survey
# for a stratum with one PSU (under "fail") becomes hcesfort_error_value.
with_lonely_psu <- function(design, expr, call = rlang::caller_env()) {
  old <- options(survey.lonely.psu = attr(design, "hces_lonely_psu"))
  on.exit(options(old), add = TRUE)
  tryCatch(force(expr), error = function(e) {
    msg <- conditionMessage(e)
    if (!grepl("only one PSU", msg, fixed = TRUE)) stop(e)
    abort_hcesfort("value", c(
      "A stratum of the domain has a single primary sampling unit.",
      "x" = cli_escape(msg),
      "i" = paste(
        "{.arg lonely_psu} of {.fn as_hces_design} is {.val fail}; choose",
        "{.val adjust}, {.val average}, {.val remove} or {.val certainty}."
      )
    ), table = "households", columns = c("stratum", "psu"),
    n = NA_integer_, call = call)
  })
}
