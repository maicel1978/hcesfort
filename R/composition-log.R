# Checks across tables and audit rows of link_composition().

# Abort when the ids that join grams, crosswalk and composition have
# incompatible types, or when a validated crosswalk row names a
# composition food that is not in the composition table.
check_composition_ids <- function(g, cw, comp, call = rlang::caller_env()) {
  pairs <- list(
    c("grams", "crosswalk", "food_code"),
    c("crosswalk", "composition", "composition_id")
  )
  tables <- list(grams = g, crosswalk = cw, composition = comp)
  for (p in pairs) {
    a <- tables[[p[1]]][[p[3]]]
    b <- tables[[p[2]]][[p[3]]]
    if (!all(is.na(b)) && !all(is.na(a)) && !same_id_type(a, b)) {
      abort_hcesfort("join", c(
        "{.field {p[3]}} differs in type between {.arg {p[1]}} and
        {.arg {p[2]}}.",
        "i" = "Use the same type (both character or both numeric)."
      ), table = p[1], other = p[2], columns = p[3], n = NA_integer_,
      call = call)
    }
  }
  ids <- cw$composition_id[cw$validated]
  absent <- unique(ids[!ids %in% comp$composition_id])
  if (length(absent) > 0) {
    n <- length(absent)
    abort_hcesfort("join", c(
      "{n} validated crosswalk match{?es} {?is/are} not in
      {.arg composition}.",
      "x" = "Composition id{?s}: {.val {utils::head(absent, 5)}}.",
      "i" = "Add the rows to the composition table or correct the crosswalk."
    ), table = "crosswalk", other = "composition", columns = "composition_id",
    n = n, call = call)
  }
  invisible(TRUE)
}

# Audit rows of link_composition(): records received, each reason without
# nutrients, the overlap of no grams and no validated match, the records
# linked, and per nutrient the linked records without a value. `qty_g` is
# the grams per day as acquired of the records that have them. Linked
# records whose yield factor was missing and taken as 1 are a note.
link_log <- function(out, reasons, nutrients, yield_assumed) {
  step <- "link_composition"
  row <- function(kind, cause, f, detail = NA_character_) {
    if (!any(f)) return(NULL)
    has_g <- f & !is.na(out$qty_g_d)
    audit_row(step, "grams", kind, cause, sum(f),
              length(unique(out$household_id[f])),
              qty_g = if (any(has_g)) sum(out$qty_g_d[has_g]) else NA_real_,
              detail = detail)
  }
  linked <- out$composition_status == "linked"
  no_match <- reasons$not_in_crosswalk | reasons$unmatched_food |
    reasons$not_validated
  missing <- lapply(nutrients$column, function(col) {
    row("flagged", "missing_nutrient_value", linked & is.na(out[[col]]), col)
  })
  dplyr::bind_rows(
    audit_row(step, "grams", "input", "all", nrow(out),
              length(unique(out$household_id)),
              qty_g = sum(out$qty_g_d[!is.na(out$qty_g_d)])),
    lapply(names(reasons), function(r) row("flagged", r, reasons[[r]])),
    row("flagged", "no_grams_and_no_match", reasons$no_grams & no_match),
    row("note", "linked", linked),
    row("note", "yield_factor_assumed_one", linked & yield_assumed),
    missing
  )
}
