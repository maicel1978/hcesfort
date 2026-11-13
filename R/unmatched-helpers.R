# Helpers of unmatched_foods(). Design: docs/design-reports-v2.md,
# section 3.3.

# Reasons a record is not linked, in the order they are listed: the
# `grams_status` of convert_units(), then the `match_status` of
# link_composition().
not_linked_reasons <- c(
  "missing_quantity", "missing_unit", "no_factor", "no_density",
  "no_piece_weight", "missing_household_share", "not_in_crosswalk",
  "unmatched_food", "not_validated", "missing_edible_portion"
)

# Counts per food of the included records `d` with their measures `m`:
# one row per distinct `food_code` of `d`, in order of appearance.
food_counts <- function(d, m) {
  ids <- unique(d$food_code)
  k <- factor(match(d$food_code, ids), seq_along(ids))
  out_rec <- !m$validated
  no_g <- is.na(d$qty_g_d)
  has_e <- out_rec & !is.na(m$expenditure_w)
  by_food <- function(v, f) {
    vapply(split(v, k), f, numeric(1), USE.NAMES = FALSE)
  }
  sum_or_na <- function(v, any) {
    ifelse(by_food(any, sum) > 0, by_food(v, sum), NA_real_)
  }
  per_food <- function(f) {
    vapply(split(seq_len(nrow(d)), k), f, character(1), USE.NAMES = FALSE)
  }
  dplyr::tibble(
    food_code = ids,
    match_status = d$match_status[match(ids, d$food_code)],
    reasons = per_food(function(i) food_reasons(d[i, ], out_rec[i])),
    units_no_grams = per_food(function(i) collapse_or_na(d$unit[i][no_g[i]])),
    n_records = as.integer(by_food(rep(1, nrow(d)), sum)),
    n_not_linked = as.integer(by_food(out_rec, sum)),
    n_no_grams = as.integer(by_food(no_g, sum)),
    n_households = as.integer(by_food(seq_len(nrow(d)), function(i) {
      length(unique(d$household_id[i][out_rec[i]]))
    })),
    qty_g_d_not_linked = sum_or_na(ifelse(out_rec, m$grams_w, 0),
                                   out_rec & !no_g),
    expenditure_lcu_d_not_linked = sum_or_na(ifelse(has_e, m$expenditure_w,
                                                    0), has_e)
  )
}

# The reasons of the records of one food not linked (`out_rec`), in the
# order of `not_linked_reasons`, separated by "; ".
food_reasons <- function(d, out_rec) {
  d <- d[out_rec, ]
  found <- c(d$grams_status[is.na(d$qty_g_d)],
             d$match_status[d$match_status != "matched"])
  collapse_or_na(not_linked_reasons[not_linked_reasons %in% found],
                 sort = FALSE)
}

# Distinct non-missing values of `v` separated by "; ", `NA` when none.
collapse_or_na <- function(v, sort = TRUE) {
  v <- unique(v[!is.na(v)])
  if (length(v) == 0) {
    return(NA_character_)
  }
  paste(if (sort) sort(v) else v, collapse = "; ")
}

# `out` with the shares of the not-linked records of each food over all
# included records (`m`), their weighted grams and weighted expenditure.
add_food_shares <- function(out, m, has_exp) {
  den <- measure_totals(m)
  out$share_records <- out$n_not_linked / den[["records"]]
  out$share_grams <- out$qty_g_d_not_linked / den[["grams"]]
  out$share_expenditure <- if (has_exp) {
    out$expenditure_lcu_d_not_linked / den[["expenditure"]]
  } else {
    rep(NA_real_, nrow(out))
  }
  out
}

# Totals of the included records of `m`, and of those linked: records,
# weighted grams of records with grams, weighted expenditure of records
# with one.
measure_totals <- function(m, f = rep(TRUE, nrow(m))) {
  has_e <- !is.na(m$expenditure_w)
  c(records = sum(f),
    grams = sum(m$grams_w[f & m$with_grams]),
    expenditure = sum(m$expenditure_w[f & has_e]))
}

# Rows of `out` in the order asked; missing amounts last, ties by food.
rank_foods <- function(out, order) {
  g <- -out$qty_g_d_not_linked
  r <- -out$n_not_linked
  e <- -out$expenditure_lcu_d_not_linked
  i <- switch(order,
    grams = base::order(g, r, out$food_code, na.last = TRUE),
    records = base::order(r, g, out$food_code, na.last = TRUE),
    expenditure = base::order(e, r, out$food_code, na.last = TRUE)
  )
  out[i, ]
}

# `out` (ranked) with `rank` and the cumulative shares linked once each
# food and those before it are resolved.
add_cumulative <- function(out, m, has_exp) {
  linked <- measure_totals(m, m$validated) / measure_totals(m)
  cum <- function(base, share) base + cumsum(ifelse(is.na(share), 0, share))
  out$rank <- seq_len(nrow(out))
  out$cum_share_records <- cum(linked[["records"]], out$share_records)
  out$cum_share_grams <- cum(linked[["grams"]], out$share_grams)
  out$cum_share_expenditure <- if (has_exp) {
    cum(linked[["expenditure"]], out$share_expenditure)
  } else {
    rep(NA_real_, nrow(out))
  }
  out
}
