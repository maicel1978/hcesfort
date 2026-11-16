# Energy added to members flagged pregnant or lactating
# (docs/design-12e5.md, sections 1.2 and 1.3; P57, decision R3-D3).

# The extra energy arguments, checked: `pregnancy` and `lactation` (kcal
# per day; 0 when not given), the members they apply to, and
# `lactation_added` (some lactating member gets energy). Abort when an
# argument needed by the flags is missing or malformed, or when breast
# milk would be charged twice: to the mother (`lactation_kcal`) and
# through the infant (`milk_energy_cost` with a share below 1).
check_extra_args <- function(pregnancy_kcal, lactation_kcal, m, infant,
                             call = rlang::caller_env()) {
  pregnant <- flag_or_false(m[["pregnant"]]) & rep(TRUE, nrow(m))
  lactating <- flag_or_false(m[["lactating"]]) & rep(TRUE, nrow(m))
  p <- check_extra_value(pregnancy_kcal, "pregnancy_kcal", "pregnant",
                         sum(pregnant), call)
  l <- check_extra_value(lactation_kcal, "lactation_kcal", "lactating",
                         sum(lactating), call)
  added <- any(lactating) && l > 0
  if (added && infant$milk_charged) abort_double_milk(call)
  list(pregnancy = p, lactation = l, pregnant = pregnant,
       lactating = lactating, lactation_added = added)
}

# One number >= 0; 0 when not given and not needed; abort when not given
# and `n` members carry the flag.
check_extra_value <- function(x, arg, flag, n, call) {
  if (is.null(x)) {
    if (n == 0) return(0)
    abort_hcesfort("argument", c(
      "{.arg members} has {n} member{?s} flagged {.field {flag}}: say how
      much energy to add, kcal per day.",
      "i" = "{.code {arg} = 0} adds none, the rule of the original
      analysis; {.code ref_energy_additions} lists the values of
      FAO/WHO/UNU 2004. See {.help hcesfort::adult_equivalents}."
    ), arg = arg, call = call)
  }
  if (is.numeric(x) && length(x) == 1 && is.finite(x) && x >= 0) return(x)
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be one number, 0 or more (kcal per day)."
  ), arg = arg, call = call)
}

abort_double_milk <- function(call) {
  abort_hcesfort("argument", c(
    "Breast milk would be charged twice: to the mother
    ({.arg lactation_kcal}) and through the infant
    ({.arg milk_energy_cost} with {.arg infant_food_share} below 1).",
    "i" = "Set {.code milk_energy_cost = 0} (the milk is charged to the
    mother) or {.code lactation_kcal = 0} (it is charged through the
    infant)."
  ), arg = c("lactation_kcal", "milk_energy_cost"), call = call)
}

# Extra energy of each member, kcal per day.
extra_energy <- function(extra) {
  extra$pregnancy * extra$pregnant + extra$lactation * extra$lactating
}

# Audit rows: energy added to pregnant and to lactating members, and the
# flagged members that get none.
extra_log <- function(step, extra, hh) {
  added <- function(cause, value, f) {
    if (value == 0 || !any(f)) return(NULL)
    audit_row(step, "members", "note", cause, sum(f), hh(f),
              detail = paste0(format_kcal(value), " kcal per day each; ",
                              format_kcal(value * sum(f)), " in total"))
  }
  none <- (extra$pregnant & extra$pregnancy == 0) |
    (extra$lactating & extra$lactation == 0)
  dplyr::bind_rows(
    added("pregnancy_energy_added", extra$pregnancy, extra$pregnant),
    added("lactation_energy_added", extra$lactation, extra$lactating),
    afe_note(step, "note", "pregnant_or_lactating_no_extra", none, hh)
  )
}
