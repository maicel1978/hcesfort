# Argument checks and audit rows of food_group_intake().

# Abort with hcesfort_error_join when `food_code` has incompatible types in
# `content` and `food_groups`.
check_food_code_type <- function(x, g, call = rlang::caller_env()) {
  if (nrow(x) == 0 || same_id_type(x$food_code, g$food_code)) {
    return(invisible(TRUE))
  }
  abort_hcesfort("join", c(
    "{.field food_code} differs in type between {.arg content} and
    {.arg food_groups}.",
    "i" = "Give both as text or both as whole numbers."
  ), table = "content", other = "food_groups", columns = "food_code",
  n = NA_integer_, call = call)
}

# Audit rows of food_group_intake(): records received and excluded by
# cause; used records of estimated households (`used`) without a group;
# foods of `g` absent from `x`; per group and nutrient, used records
# without a value.
food_group_log <- function(x, g, reasons, used, group, nutrients) {
  step <- "food_group_intake"
  rec <- function(kind, cause, f, detail = NA_character_) {
    if (!any(f)) return(NULL)
    grams <- x$qty_g_d[f & !is.na(x$qty_g_d)]
    audit_row(step, "nutrient_content", kind, cause, sum(f),
              length(unique(x$household_id[f])),
              qty_g = if (length(grams) > 0) sum(grams) else NA_real_,
              detail = detail)
  }
  unclassified <- used & group == unclassified_group
  absent <- setdiff(g$food_code, x$food_code)
  dplyr::bind_rows(
    rec("input", "all", rep(TRUE, nrow(x))),
    lapply(names(reasons), function(r) rec("excluded", r, reasons[[r]])),
    rec("note", "used", used),
    rec("flagged", "unclassified", unclassified,
        paste(sort(unique(x$food_code[unclassified])), collapse = ", ")),
    if (length(absent) > 0) {
      audit_row(step, "food_groups", "note", "group_not_in_content",
                length(absent), detail = paste(absent, collapse = ", "))
    },
    no_value_rows(rec, x, used, group, nutrients)
  )
}

# One flagged row per group and nutrient with used records without a value.
no_value_rows <- function(rec, x, used, group, nutrients) {
  rows <- list()
  for (lv in unique(group[used])) {
    for (col in nutrients$column) {
      f <- used & group == lv & is.na(x[[col]])
      rows[[length(rows) + 1]] <- rec("flagged", "no_nutrient_value", f,
                                      paste0(lv, ": ", col))
    }
  }
  dplyr::bind_rows(rows)
}
