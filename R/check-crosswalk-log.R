# Argument checks, grams per food and audit rows of check_crosswalk().

# Abort unless review_types is NULL or text, and ranges and group are
# coherent with the composition table and the registry.
check_review_args <- function(review_types, ranges, group, comp, nutrients,
                              call = rlang::caller_env()) {
  bad <- function(arg, what) {
    abort_hcesfort("argument", paste0("{.arg ", arg, "} ", what, "."),
                   arg = arg, call = call)
  }
  if (!is.null(review_types) && !is.character(review_types)) {
    bad("review_types", "must be a character vector")
  }
  if (!is.null(group) &&
        !(rlang::is_string(group) && group %in% names(comp))) {
    bad("group", "must name one column of {.arg composition}")
  }
  if (is.null(ranges)) {
    return(invisible(TRUE))
  }
  need <- c("column", "min", "max", if (!is.null(group)) "group")
  if (!is.data.frame(ranges) || !all(need %in% names(ranges))) {
    bad("ranges", "must be a data frame with columns {.field {need}}")
  }
  if (!all(ranges$column %in% nutrients$column)) {
    bad("ranges", "names a column that is not a nutrient of the registry")
  }
  if (!is.numeric(ranges$min) || !is.numeric(ranges$max) ||
        any(ranges$min > ranges$max, na.rm = TRUE)) {
    bad("ranges", "needs numeric {.field min} and {.field max}, min first")
  }
  invisible(TRUE)
}

# `out` with the records and grams per day as acquired of each food, from
# the grams table; foods without records get 0 and NA.
add_food_grams <- function(out, grams) {
  if (is.null(grams)) {
    return(out)
  }
  k <- match(grams$food_code, out$food_code)
  out$n_records <- tabulate(k, nbins = nrow(out))
  has <- !is.na(k) & !is.na(grams$qty_g_d)
  g <- vapply(seq_len(nrow(out)), function(i) {
    if (any(has & k == i)) sum(grams$qty_g_d[has & k == i]) else NA_real_
  }, numeric(1))
  out$qty_g_d <- g
  out
}

# Audit rows of check_crosswalk(): rows received and, per control, the
# validated rows flagged, with their grams per day when known.
check_log <- function(out, nutrients) {
  step <- "check_crosswalk"
  flags <- grep("^flag_", names(out), value = TRUE)
  f_list <- lapply(flags, function(col) !is.na(out[[col]]) & out[[col]])
  names(f_list) <- sub("^flag_", "", flags)
  f_list$missing_nutrients <- !is.na(out$n_missing_nutrients) &
    out$n_missing_nutrients > 0
  rows <- lapply(names(f_list), function(cause) {
    f <- f_list[[cause]]
    if (!any(f)) return(NULL)
    g <- out[["qty_g_d"]][f]
    qty <- if (is.null(g) || all(is.na(g))) NA_real_ else sum(g[!is.na(g)])
    audit_row(step, "crosswalk", "flagged", cause, sum(f), qty_g = qty)
  })
  dplyr::bind_rows(
    audit_row(step, "crosswalk", "input", "all", nrow(out),
              detail = paste(nrow(nutrients), "nutrients")),
    rows
  )
}
