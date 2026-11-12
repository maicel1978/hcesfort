# Argument checks and audit rows of apparent_intake().

# The outlier decision: required when `x` has the column `outlier`, NULL
# otherwise.
check_outlier_decision <- function(outliers, x, call = rlang::caller_env()) {
  has_column <- !is.null(x[["outlier"]])
  if (!has_column && is.null(outliers)) {
    return(NULL)
  }
  if (has_column && rlang::is_string(outliers) &&
        outliers %in% c("exclude", "keep")) {
    return(outliers)
  }
  abort_hcesfort("argument", c(
    if (has_column) {
      "{.arg content} has the column {.field outlier}: say what to do with
      the flagged records."
    } else {
      "{.arg outliers} is given but {.arg content} has no column
      {.field outlier}."
    },
    "i" = if (has_column) {
      "Set {.arg outliers} to {.val exclude} or {.val keep}."
    } else {
      "Run {.fn flag_outliers} first, or leave {.arg outliers} as NULL."
    }
  ), arg = "outliers", call = call)
}

# Abort when household ids have incompatible types, or when `content` or
# `afe` have households absent from `households`.
check_intake_ids <- function(x, afe, h, call = rlang::caller_env()) {
  for (other in list(list("content", x), list("afe", afe))) {
    ids <- other[[2]]$household_id
    if (length(ids) > 0 && !same_id_type(ids, h$household_id)) {
      abort_hcesfort("join", c(
        "{.field household_id} differs in type between {.arg {other[[1]]}}
        and {.arg households}."
      ), table = other[[1]], other = "households", columns = "household_id",
      n = NA_integer_, call = call)
    }
    absent <- unique(ids[!ids %in% h$household_id])
    if (length(absent) > 0) {
      n <- length(absent)
      abort_hcesfort("join", c(
        "{n} household{?s} of {.arg {other[[1]]}} {?is/are} not in
        {.arg households}.",
        "x" = "Id{?s}: {.val {utils::head(absent, 5)}}."
      ), table = other[[1]], other = "households", columns = "household_id",
      n = n, call = call)
    }
  }
  invisible(TRUE)
}

# Audit rows of apparent_intake(): records received; records left out by
# cause, with their grams per day as acquired; households by status; and
# per nutrient, estimated households whose coverage is below 1.
intake_log <- function(x, reasons, used, out, nutrients) {
  step <- "apparent_intake"
  rec <- function(kind, cause, f) {
    if (!any(f)) return(NULL)
    g <- x$qty_g_d[f & !is.na(x$qty_g_d)]
    audit_row(step, "nutrient_content", kind, cause, sum(f),
              length(unique(x$household_id[f])),
              qty_g = if (length(g) > 0) sum(g) else NA_real_)
  }
  hh <- function(kind, cause, f, detail = NA_character_) {
    if (!any(f)) return(NULL)
    audit_row(step, "intake", kind, cause, sum(f), sum(f), detail = detail)
  }
  est <- out$intake_status == "estimated"
  statuses <- setdiff(unique(out$intake_status), "estimated")
  dplyr::bind_rows(
    rec("input", "all", rep(TRUE, nrow(x))),
    lapply(names(reasons), function(r) rec("excluded", r, reasons[[r]])),
    rec("note", "used", used),
    lapply(sort(statuses), function(s) {
      hh("flagged", s, out$intake_status == s)
    }),
    hh("note", "estimated", est),
    lapply(nutrients$column, function(col) {
      cov <- out[[paste0(col, "_coverage")]]
      hh("flagged", "incomplete_nutrient_value", est & !is.na(cov) & cov < 1,
         col)
    })
  )
}
