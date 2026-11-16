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
#'   is the symmetric interval of the original analysis, E24), or
#'   `"korn_graubard"` (below).
#' * `"mean"`: [survey::svymean()] and a *t* interval.
#' * `"median"`: [survey::svyquantile()] at 0.5, interval by its default
#'   (Woodruff) method. Where that interval is undefined (in a small
#'   domain, `survey` returns `NaN` for a limit or the standard error), the
#'   median is kept with `se`, `ci_low` and `ci_high` missing, and the cell
#'   is counted in the log (`undefined_quantile_interval`).
#'
#' `"korn_graubard"` is the interval of the NCHS data presentation
#' standards for proportions (Parker et al. 2017, Vital Health Stat
#' 2(175), pp. 3-4, 8-9), the interval those standards judge.
#' The estimate and its variance come from [survey::svymean()] on the
#' domain; the effective sample size \eqn{p(1 - p) / var} is multiplied by
#' \eqn{(t_{n-1} / t_{df})^2}, with `n` the households of the domain and
#' `df` as below, and capped at `n`; the limits are the Clopper-Pearson
#' limits on that size. `"beta"` is [survey::svyciprop()] as it is: the
#' same formula without the cap (so its interval is narrower where the
#' design effect is below 1), with the degrees of freedom of the subset
#' design whatever `df` says, and no interval for a proportion of 0 or 1.
#'
#' A proportion whose values in the domain are all 0 (or all 1) is
#' returned as that exact value with `se = 0` and counted in the log
#' (`degenerate_proportion`). Under `"korn_graubard"` its interval is the
#' Clopper-Pearson interval on `n`, as the NCHS standards prescribe (p. 4).
#' Under the other methods it has no interval (`ci_low`, `ci_high`
#' missing): they give either a spurious estimate (`"logit"`) or no limits
#' (`"beta"`) there, and a sample of few households is not certainty. Any
#' other cell whose households all have the same value (a mean, a median,
#' a difference of zero) follows the same rule: the value, `se = 0`, no
#' interval, counted in the log (`no_variation`).
#'
#' Degrees of freedom of the *t* intervals: `"domain"` (by default) uses
#' those of the domain, `survey::degf()` of the subset design, as the
#' original analysis did and as `survey` does on a subset; `"design"` those
#' of the full design; or a number (`Inf` for normal intervals). A cell
#' whose domain has no degrees of freedom (a domain inside one primary
#' sampling unit), whatever `df` says, keeps its estimate and standard
#' error, has no interval, `df` set to those of the domain (0) and
#' `n_effective` missing (its standard error cannot be estimated), and is
#' counted in the log (`no_degrees_of_freedom`).
#'
#' The option `survey.adjust.domain.lonely` of `survey` is set to `FALSE`
#' during the estimate, whatever its global value, and written in the log
#' (`adjust_domain_lonely`). PSU codes found in more than one stratum are
#' counted in the log (`psu_in_several_strata`): the design nests PSUs in
#' strata, so each is a different PSU.
#'
#' @param design A design built by [as_hces_design()].
#' @param x A table returned by [inadequacy()], [above_ul()],
#'   [apply_scenario()], [apparent_intake()] or [vehicle_coverage()].
#' @param value Name of the column of `x` to estimate.
#' @param statistic `"proportion"`, `"mean"` or `"median"`. A proportion
#'   needs a logical column or values in \[0, 1\], such as `p_inadequate`;
#'   any other value is an error (`hcesfort_error_value`).
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
#' @param ci_method Interval method for proportions: `"korn_graubard"`, or
#'   a method of [survey::svyciprop()] (`"logit"`, `"likelihood"`,
#'   `"asin"`, `"beta"`, `"mean"`, `"xlogit"`, `"wilson"`).
#' @param level Confidence level.
#' @param df `"domain"`, `"design"` or a number.
#' @returns A tibble of class `hces_estimate` (and `hces_tbl`): the group
#'   columns of `x`, the `by` columns, `statistic`, `variable`, `estimate`,
#'   `se`, `ci_low`, `ci_high`, `ci_method` (the interval method: the
#'   `ci_method` given for a proportion, `"t"` for a mean, `"woodruff"` for
#'   a median), `conf_level`, `df`, `n` (households in the
#'   domain), `n_missing` (households of the `by` domain whose value is
#'   missing), `n_effective` (`n` divided by the design effect, computed as
#'   the weighted variance of the values over the squared standard error,
#'   capped at `n`; `n` when `se` is 0; `NA` for a median and for a cell
#'   without degrees of freedom) and
#'   `interval_note` (why the interval is missing or exact:
#'   `"degenerate_proportion"`, `"no_variation"`, `"no_degrees_of_freedom"`,
#'   `"undefined_quantile_interval"`; `NA` otherwise). Its audit log
#'   continues the log of `x`.
#' @seealso [estimate_difference()], [flag_precision()].
#' @examples
#' nutrients <- nutrient_registry(hces_example$nutrients)
#' grams <- convert_units(hces_example$acquisitions,
#'                        hces_example$unit_factors, priority = "food")
#' afe <- adult_equivalents(
#'   hces_example$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76,
#'   infant_food_share = 1, pregnancy_kcal = 0, lactation_kcal = 0
#' )
#' use <- vehicle_coverage(grams, hces_example$vehicles, afe,
#'                         hces_example$households, fortifiable = "use")
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
  x <- audit_check_rows(x, "estimate_households")
  check_estimate_args(design, x, statistic, by, ci_method, level, df)
  d <- resolve_domain(design, x, domain, domain_from)
  a <- align_values(design, x, value, d$x_domain)
  check_proportion_values(x, value, statistic)
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
  new_hces_tbl(out, "hces_estimate", log,
               c(names(a$keys), by, "statistic", "variable"))
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
  row <- dplyr::tibble(statistic = statistic, estimate = NA_real_,
                       se = NA_real_, ci_low = NA_real_, ci_high = NA_real_,
                       ci_method = interval_name(statistic, ci_method),
                       conf_level = level, df = dfv, n = n,
                       n_missing = sum(mask & !inside),
                       n_effective = NA_real_, interval_note = NA_character_)
  if (n == 0) return(row)
  dom <- if (identical(df, "domain")) dfv else survey::degf(sub)
  r <- cell_result(sub, y[inside], statistic, ci_method, level, dfv, dom, n)
  row[c("estimate", "se", "ci_low", "ci_high")] <- as.list(unname(r$values))
  row$interval_note <- r$note
  if (identical(r$note, "no_degrees_of_freedom")) {
    row$df <- dom
  } else if (statistic != "median") {
    row$n_effective <- effective_n(sub, r$values[[2]], n)
  }
  row
}

# Estimate, SE, limits and the note on the interval of one cell with
# households: no interval without variation (P165) or without degrees of
# freedom in the domain (`dom`, whatever `dfv` says; P166, P204);
# `undefined_quantile_interval` for a median whose interval survey cannot
# compute.
cell_result <- function(sub, v, statistic, ci_method, level, dfv, dom, n) {
  if (all(v == v[[1]])) {
    if (statistic == "proportion" && v[[1]] %in% c(0, 1)) {
      return(list(values = degenerate_values(v[[1]], n, ci_method, level),
                  note = "degenerate_proportion"))
    }
    return(list(values = c(v[[1]], 0, NA_real_, NA_real_),
                note = "no_variation"))
  }
  if (dom <= 0) {
    r <- cell_values(sub, statistic, ci_method, level, Inf, n)
    r[3:4] <- NA_real_
    return(list(values = r, note = "no_degrees_of_freedom"))
  }
  r <- cell_values(sub, statistic, ci_method, level, dfv, n)
  undefined <- statistic == "median" && anyNA(r[2:4])
  list(values = r,
       note = if (undefined) "undefined_quantile_interval" else NA_character_)
}

# Effective sample size of a mean or a proportion: n divided by the design
# effect (NCHS 2017, p. 3), computed as s^2 / se^2 with s^2 the weighted
# variance of the values in the domain (divisor the sum of the weights),
# capped at `n`; `n` when the standard error is 0. For a 0/1 outcome s^2 is
# p (1 - p), the formula of the standards; for a probability it is the
# variance of the values themselves (P164, finding 10 of the v0.2 review).
effective_n <- function(sub, se, n) {
  w <- stats::weights(sub)
  keep <- w > 0
  w <- w[keep]
  y <- sub$variables$.y[keep]
  s2 <- sum(w * (y - sum(w * y) / sum(w))^2) / sum(w)
  if (is.na(se)) return(NA_real_)
  if (se == 0) return(as.numeric(n))
  min(s2 / se^2, n)
}

# Estimate, SE and interval limits of one cell with variation.
cell_values <- function(sub, statistic, ci_method, level, dfv, n) {
  switch(
    statistic,
    proportion = if (ci_method == "korn_graubard") {
      e <- survey::svymean(~.y, sub)
      p <- unname(stats::coef(e))
      se <- unname(survey::SE(e))[[1]]
      c(p, se, korn_graubard_interval(p, se, n, dfv, level))
    } else {
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
      undefined_interval(c(stats::coef(e), survey::SE(e),
                           stats::confint(e)))
    }
  )
}

# A proportion of exactly 0 or 1 in the sample: the value with se = 0;
# the Clopper-Pearson interval on `n` under "korn_graubard" (NCHS 2017,
# p. 4), no interval under the other methods.
degenerate_values <- function(p, n, ci_method, level) {
  ci <- if (ci_method == "korn_graubard") {
    clopper_pearson(p * n, n, level)
  } else {
    c(NA_real_, NA_real_)
  }
  c(p, 0, ci)
}

# The name of the interval method stored in the column ci_method.
interval_name <- function(statistic, ci_method) {
  switch(statistic, proportion = ci_method, mean = "t",
         median = "woodruff")
}

# A quantile whose interval is undefined (a limit or the SE not finite,
# as survey returns NaN in a small domain) keeps its estimate, with no SE
# and no interval: counted by estimate_log() (undefined_quantile_interval).
undefined_interval <- function(r) {
  if (any(!is.finite(r[2:4]))) r[2:4] <- NA_real_
  r
}

# The log of `x` followed by the rows of the log of `domain_from` it does
# not hold yet.
domain_input_log <- function(x, domain_from) {
  if (is.null(domain_from)) return(audit_get(x))
  audit_combine(x, domain_from)
}
