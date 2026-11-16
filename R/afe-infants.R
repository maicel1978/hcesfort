# Energy of infants charged to the household (docs/design-12e5.md,
# section 1.2; P158): E x (s + (1 - s) c), with E the requirement of the
# infant, s the share eaten from the household's food (`infant_food_share`)
# and c the dietary energy charged per unit of breast-milk energy
# (`milk_energy_cost`). Written as E x (1 - (1 - s) (1 - c)), so that s = 1
# or c = 1 return E exactly (the rule of the original analysis).

# The infant arguments, checked: `share` a table of [age_from, age_to)
# months with `food_share`, `cost` one number (1 when not needed), `given`
# the text of the log, and `milk_charged` (some infant's milk is charged
# to the household through the infant). Abort when an argument needed by the
# members is missing or when a given one is malformed; a value given where
# it is not needed is accepted and ignored.
check_infant_args <- function(infant_food_share, milk_energy_cost, m,
                              call = rlang::caller_env()) {
  n_infants <- sum(!is.na(m$age_years) & m$age_years < 1)
  if (is.null(infant_food_share)) {
    if (n_infants > 0) abort_infant_share(n_infants, call)
    return(list(share = share_table(1), cost = 1, given = NA_character_,
                milk_charged = FALSE))
  }
  share <- check_share_value(infant_food_share, call)
  needs_cost <- n_infants > 0 && any(share$food_share < 1)
  if (is.null(milk_energy_cost)) {
    if (needs_cost) abort_milk_cost(call)
    cost <- 1
  } else {
    cost <- check_milk_cost(milk_energy_cost, call)
  }
  given <- paste0("infant_food_share: ", describe_share(share),
                  "; milk_energy_cost: ",
                  if (is.null(milk_energy_cost)) "not given" else cost)
  list(share = share, cost = cost, given = given,
       milk_charged = needs_cost && cost > 0)
}

# The share as a table of intervals of months covering [0, 12).
share_table <- function(x) {
  data.frame(age_from = 0, age_to = 12, food_share = x)
}

# The share in words for the log: one number, or each interval.
describe_share <- function(share) {
  if (nrow(share) == 1) return(as.character(share$food_share))
  paste0("[", share$age_from, ", ", share$age_to, ") ", share$food_share,
         collapse = "; ")
}

# Factor of the infant's requirement charged to the household, for ages in
# months (each looked up in the intervals of `share`).
infant_factor <- function(months, infant) {
  s <- rep(NA_real_, length(months))
  for (i in seq_len(nrow(infant$share))) {
    hit <- months >= infant$share$age_from[[i]] &
      months < infant$share$age_to[[i]]
    s[hit] <- infant$share$food_share[[i]]
  }
  1 - (1 - s) * (1 - infant$cost)
}

# Audit rows of the infants: a note with the arguments and the energy
# charged against the full requirement; flagged when breast milk is not
# charged at all (`milk_energy_cost = 0` with a share below 1, and no
# lactation energy added to a mother).
infant_log <- function(step, m, kcal, full, infant, hh) {
  inf <- !is.na(full)
  if (!any(inf)) return(NULL)
  charged <- sum(kcal[inf])
  required <- sum(full[inf])
  rows <- list(audit_row(
    step, "members", "note", "infant_energy", sum(inf), hh(inf),
    detail = paste0(infant$given, "; kcal per day charged ",
                    format_kcal(charged), " of ", format_kcal(required))
  ))
  left_out <- inf & kcal < full
  if (infant$cost == 0 && any(left_out) && !infant$lactation_added) {
    rows[[2]] <- audit_row(
      step, "members", "flagged", "breast_milk_energy_not_counted",
      sum(left_out), hh(left_out),
      detail = paste0(format_kcal(required - charged),
                      " kcal per day of breast milk not counted")
    )
  }
  dplyr::bind_rows(rows)
}

format_kcal <- function(x) {
  format(round(x, 1), big.mark = ",", nsmall = 1, trim = TRUE)
}

# The share checked and as a table sorted by age; abort with
# `hcesfort_error_argument` naming the problem.
check_share_value <- function(x, call) {
  if (is.numeric(x) && !is.data.frame(x) && length(x) == 1 &&
        is.finite(x) && x >= 0 && x <= 1) {
    return(share_table(x))
  }
  problem <- share_problem(x)
  if (is.null(problem)) {
    x <- as.data.frame(x)[c("age_from", "age_to", "food_share")]
    x <- x[order(x$age_from), ]
    rownames(x) <- NULL
    return(x)
  }
  abort_hcesfort("argument", c(
    "{.arg infant_food_share} must be one number in [0, 1], or a table
    with {.field age_from}, {.field age_to} (months) and
    {.field food_share}.",
    "x" = cli_escape(problem),
    "i" = "See {.help hcesfort::adult_equivalents}."
  ), arg = "infant_food_share", call = call)
}

# What is wrong with a table of shares by month, or NULL.
share_problem <- function(x) {
  cols <- c("age_from", "age_to", "food_share")
  if (!is.data.frame(x)) return("It is neither one number nor a table.")
  if (!all(cols %in% names(x))) return("A column is missing.")
  ok <- vapply(cols, function(k) {
    is.numeric(x[[k]]) && nrow(x) > 0 && all(is.finite(x[[k]]))
  }, logical(1))
  if (!all(ok)) {
    return("A column is not numeric, is empty or has missing values.")
  }
  x <- x[order(x$age_from), ]
  n <- nrow(x)
  if (any(x$food_share < 0 | x$food_share > 1)) {
    return("A share is outside [0, 1].")
  }
  if (any(x$age_from >= x$age_to)) return("An interval is empty.")
  if (x$age_from[[1]] != 0 || x$age_to[[n]] != 12) {
    return("The intervals do not cover 0 to 12 months.")
  }
  if (n > 1 && any(x$age_to[-n] != x$age_from[-1])) {
    return("Two intervals leave a gap or overlap.")
  }
  NULL
}

# One finite number >= 0, or abort.
check_milk_cost <- function(x, call) {
  if (is.numeric(x) && length(x) == 1 && is.finite(x) && x >= 0) return(x)
  abort_hcesfort("argument", c(
    "{.arg milk_energy_cost} must be one number, 0 or more."
  ), arg = "milk_energy_cost", call = call)
}

abort_infant_share <- function(n, call) {
  abort_hcesfort("argument", c(
    "{.arg members} has {n} infant{?s} (under one year): say what share of
    their energy requirement comes from the household's food.",
    "i" = "{.code infant_food_share = 1} charges the full requirement, the
    rule of the original analysis: breast milk reaches the infant through
    its mother's diet.",
    "i" = "A share below 1 also needs {.arg milk_energy_cost}. See
    {.help hcesfort::adult_equivalents}."
  ), arg = "infant_food_share", call = call)
}

abort_milk_cost <- function(call) {
  abort_hcesfort("argument", c(
    "{.arg infant_food_share} is below 1: say how much dietary energy the
    household spends per unit of breast-milk energy.",
    "i" = "{.code milk_energy_cost = 1} charges the milk at par; 1.25 its
    full cost (FAO/WHO/UNU 2004, section 7.2); 0 charges nothing through
    the infant (charge it to the mother with {.arg lactation_kcal}). See
    {.help hcesfort::adult_equivalents}."
  ), arg = "milk_energy_cost", call = call)
}
