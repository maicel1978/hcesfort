#' Share of each food group in the apparent intake, on the survey design
#'
#' For each nutrient and food group, the share of the mean apparent intake
#' per adult female equivalent (AFE) that the foods of the group bring,
#' estimated on the full design with its standard error and confidence
#' interval. The input is the household by group table of
#' [food_group_intake()], which is always on the unfortified baseline (E1).
#'
#' For nutrient *n* and group *g*, over the households with
#' `intake_status == "estimated"` (the others stay in the design, outside
#' the domain of estimation):
#'
#' \deqn{share_{gn} = \sum_h w_h a_{hgn} / \sum_h w_h a_{hn}}
#'
#' where \eqn{a_{hgn}} is the amount per AFE and day and \eqn{a_{hn}} its
#' sum over the groups. It is a ratio of weighted totals, estimated with
#' [survey::svyratio()], not a mean of household shares. The amounts are
#' per AFE, as every other figure of the package, so the share reads "of
#' the apparent intake of the reference woman"; it is not the share of the
#' national supply (household totals), which gives more weight to large
#' households.
#'
#' The interval is computed on the logit scale by the delta method,
#' \eqn{logit(p) \pm t \cdot se / (p (1 - p))}, and back-transformed, so it
#' stays between 0 and 1. A share of exactly 0 (no household acquired the
#' group) or 1 (the group is the only source) is returned with `se = 0`
#' and no interval, as the degenerate proportions of
#' [estimate_households()], and counted in the log (`degenerate_share`). A
#' nutrient whose total is zero in a domain gives a missing share and a log
#' row (`zero_total`). Degrees of freedom: as in [estimate_households()].
#'
#' The household table also gives the share of households that acquire
#' each group: `estimate_households(design, x, "acquired")`.
#'
#' @inheritParams estimate_households
#' @param x A table returned by [food_group_intake()].
#' @returns A tibble of class `hces_estimate` (and `hces_tbl`): the `by`
#'   columns, `food_group`, `statistic` (`"share"`), `variable` (the
#'   nutrient column), `estimate`, `se`, `ci_low`, `ci_high`,
#'   `conf_level`, `df`, `n` (households in the domain) and `n_missing`
#'   (households of the `by` domain without an estimated intake). One row
#'   per nutrient, group and domain. It passes through [flag_precision()].
#'   Its audit log continues the log of `x`.
#' @seealso [food_group_intake()], [flag_precision()].
#' @examples
#' e <- hces_example
#' nutrients <- nutrient_registry(e$nutrients)
#' grams <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
#' base <- unfortified_baseline(e$composition, e$enrichment, nutrients)
#' content <- link_composition(grams, e$crosswalk, base, nutrients)
#' afe <- adult_equivalents(
#'   e$members,
#'   reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
#'   weight_kg = c(female = 55, male = 65), pal = 1.76
#' )
#' groups <- food_group_intake(content, e$food_groups, afe, e$households)
#' design <- as_hces_design(e$households, lonely_psu = "adjust")
#' shares <- food_group_shares(design, groups)
#' subset(shares, variable == "iron_mg")
#' @export
food_group_shares <- function(design, x, by = NULL, level = 0.95,
                              df = "domain") {
  check_required()
  require_design(design)
  require_hces(x, "hces_group_intake")
  x <- audit_check_rows(x, "food_group_shares")
  check_estimate_args(design, x, "proportion", by, "logit", level, df)
  nutrients <- attr(x, "nutrients", exact = TRUE)$column
  ids <- design$variables$household_id
  check_group_ids(x, ids)
  groups <- unique(x$food_group)
  cells <- by_cells(design, by)
  amount <- function(g, col) {
    f <- x$food_group == g
    x[[col]][f][match(ids, x$household_id[f])]
  }
  out <- list()
  for (col in nutrients) {
    a <- lapply(groups, amount, col = col)
    total <- Reduce(`+`, a)
    for (k in seq_along(groups)) {
      for (j in seq_along(cells$masks)) {
        est <- share_cell(design, a[[k]], total, cells$masks[[j]], level, df)
        out[[length(out) + 1]] <- dplyr::bind_cols(
          cells$levels[j, ], dplyr::tibble(food_group = groups[[k]],
                                           statistic = "share",
                                           variable = col), est
        )
      }
    }
  }
  out <- dplyr::bind_rows(out)
  log <- dplyr::bind_rows(audit_get(x), shares_log(design, df, out))
  new_hces_tbl(out, "hces_estimate", log, c(by, "food_group", "variable"))
}

# One share: amounts `num` of the group and `total` of every group,
# aligned with the design (NA outside the estimated households), over the
# households of the cell `mask`.
share_cell <- function(design, num, total, mask, level, df) {
  inside <- mask & !is.na(total)
  r <- ratio_cell(design, num, total, inside, df)
  y <- num[inside]
  if (!is.na(r$estimate) && (all(y == 0) || all(y == total[inside]))) {
    r$estimate <- if (all(y == 0)) 0 else 1
    r$se <- 0
  }
  ci <- logit_interval(r$estimate, r$se, level, r$df)
  dplyr::tibble(estimate = r$estimate, se = r$se, ci_low = ci[[1]],
                ci_high = ci[[2]], conf_level = level, df = r$df, n = r$n,
                n_missing = sum(mask & is.na(total)))
}
