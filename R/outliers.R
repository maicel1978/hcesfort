#' Flag outlying quantities
#'
#' Flag records whose grams per day are far from the rest of their group,
#' without removing or changing them: detecting is this step, deciding what
#' to do with a flagged record is a separate, explicit step.
#'
#' A value is flagged high when it is above `multiplier` times the quantile
#' `probs[2]` of its group, and low when it is above zero and below the
#' quantile `probs[1]` divided by `multiplier`. Quantiles are computed over
#' the values of the group that can be assessed, unweighted, with
#' [stats::quantile()] of the given `type`. A group with fewer than
#' `min_group` values is not assessed. The original ENGIH 2018 analysis
#' used `probs = c(0.005, 0.995)`, `multiplier = 5` and `min_group = 20`
#' by food, on household grams per day (E9); none of these values has a
#' published source, so none is a default here.
#'
#' The value assessed is the record's grams per day (`level = "record"`) or
#' the household's sum of grams per day in the group (`level =
#' "household"`; every record with grams of a flagged household and group
#' is flagged, and records without grams are left out of the sum),
#' on one of three scales: as recorded for the household (`"household"`),
#' per member (`"per_capita"`) or per adult female equivalent
#' (`"per_afe"`). The last two need `afe`.
#'
#' @param grams Table returned by [convert_units()].
#' @param by Names of the columns of `grams` that form the groups, for
#'   example `"food_code"`. A missing value forms its own group.
#' @param scale `"household"`, `"per_capita"` or `"per_afe"`; required.
#' @param level `"record"` or `"household"`; required.
#' @param probs Two probabilities, lower and upper; required.
#' @param multiplier One number of at least 1; required.
#' @param min_group Smallest number of values a group needs to be
#'   assessed (a positive whole number); required.
#' @param afe Table returned by [adult_equivalents()]; needed by the scales
#'   `"per_capita"` (`n_members`) and `"per_afe"` (`afe`).
#' @param type Quantile algorithm of [stats::quantile()], 1 to 9.
#' @returns `grams` with the column `outlier`: `TRUE` (flagged), `FALSE`
#'   or `NA` (not assessed). The audit log records the rule (in `detail`
#'   of the `input` row), the records flagged high and low with their
#'   grams per day (`outlier_high`, `outlier_low`), and the records not
#'   assessed: without grams (`not_assessed_no_grams`), without AFE or
#'   members (`not_assessed_no_afe`) or in a group too small
#'   (`not_assessed_small_group`).
#' @seealso [convert_units()], [adult_equivalents()], [audit_log()].
#' @examples
#' grams <- convert_units(
#'   hces_example$acquisitions, hces_example$unit_factors,
#'   priority = "food"
#' )
#' flagged <- flag_outliers(
#'   grams, by = "food_code", scale = "household", level = "record",
#'   probs = c(0.05, 0.95), multiplier = 3, min_group = 5
#' )
#' table(flagged$outlier, useNA = "ifany")
#' audit_log(flagged)
#' @export
flag_outliers <- function(grams, by, scale, level, probs, multiplier,
                          min_group, afe = NULL, type = 7) {
  require_hces(grams, "hces_grams")
  g <- audit_check_rows(grams, "flag_outliers")
  scale <- check_required_choice(scale,
                                 c("household", "per_capita", "per_afe"))
  level <- check_required_choice(level, c("record", "household"))
  check_outlier_args(g, by, probs, multiplier, min_group, type)
  divisor <- outlier_divisor(g, scale, afe)
  unit <- if (level == "record") seq_len(nrow(g)) else
    group_id(g, c("household_id", by))
  value <- unit_value(g$qty_g_d, unit, divisor)
  group <- group_id(g, by)[match(seq_len(max(0L, unit)), unit)]
  res <- assess_groups(value, group, probs, multiplier, min_group, type)
  out <- dplyr::as_tibble(g)
  out$outlier <- ifelse(is.na(g$qty_g_d), NA, res$flag[unit])
  rule <- outlier_rule(by, scale, level, probs, multiplier, min_group, type)
  log <- outlier_log(out, res, unit, divisor, rule)
  new_hces_tbl(out, "hces_grams", dplyr::bind_rows(audit_get(g), log),
               "record_id")
}

# An integer id per distinct combination of the columns `cols` of `x`;
# missing values form their own group.
group_id <- function(x, cols) {
  keys <- dplyr::as_tibble(x)[cols]
  dplyr::group_indices(dplyr::group_by(keys, dplyr::across(dplyr::all_of(
    cols
  ))))
}

# The divisor of each record for the scale: 1, the household's members or
# its AFE (NA when the household has none, or zero).
outlier_divisor <- function(g, scale, afe, call = rlang::caller_env()) {
  if (scale == "household") {
    return(rep(1, nrow(g)))
  }
  if (is.null(afe)) {
    abort_hcesfort("argument", c(
      "{.arg afe} is needed by {.code scale = \"{scale}\"}.",
      "i" = "Pass the table returned by {.fn adult_equivalents}."
    ), arg = "afe", call = call)
  }
  require_hces(afe, "hces_afe", call = call)
  if (!same_id_type(g$household_id, afe$household_id)) {
    abort_hcesfort("join", c(
      "{.field household_id} differs in type between {.arg grams} and
      {.arg afe}."
    ), table = "grams", other = "afe", columns = "household_id",
    n = NA_integer_, call = call)
  }
  col <- if (scale == "per_afe") "afe" else "n_members"
  keys <- dplyr::tibble(household_id = g$household_id)
  joined <- dplyr::left_join(
    keys, dplyr::as_tibble(afe)[c("household_id", col)], by = "household_id",
    relationship = "many-to-one", unmatched = "drop", na_matches = "never"
  )
  d <- joined[[col]]
  d[!is.na(d) & d <= 0] <- NA_real_
  d
}

# The value of each assessment unit: the sum of the grams per day of its
# records with grams, divided by the divisor (one per household, so the
# first). A unit without any record with grams has no value.
unit_value <- function(qty_g_d, unit, divisor) {
  n <- max(0L, unit)
  has <- !is.na(qty_g_d)
  f <- factor(unit[has], levels = seq_len(n))
  sums <- vapply(split(qty_g_d[has], f), sum, numeric(1), USE.NAMES = FALSE)
  sums[tabulate(unit[has], nbins = n) == 0] <- NA_real_
  sums / divisor[match(seq_len(n), unit)]
}

# Flags of the units: TRUE above the upper fence or below the lower one,
# FALSE inside, NA when the unit has no value or its group is too small.
assess_groups <- function(value, group, probs, multiplier, min_group, type) {
  ok <- !is.na(value)
  n_groups <- max(0L, group)
  n_ok <- tabulate(group[ok], nbins = n_groups)
  big <- n_ok[group] >= min_group
  q <- matrix(NA_real_, nrow = n_groups, ncol = 2)
  for (k in which(n_ok >= min_group)) {
    q[k, ] <- stats::quantile(value[ok & group == k], probs, type = type,
                              names = FALSE)
  }
  high <- ok & big & value > multiplier * q[group, 2]
  low <- ok & big & value > 0 & value < q[group, 1] / multiplier
  flag <- ifelse(ok & big, high | low, NA)
  list(flag = flag, high = high, low = low, small = ok & !big, ok = ok)
}
