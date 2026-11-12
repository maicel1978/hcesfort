# Argument checks of adult_equivalents().

# The chosen value of a character argument with a fixed set of choices;
# the first choice when the argument is left at its default.
check_choice <- function(x, choices, arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  if (identical(x, choices)) {
    return(choices[[1]])
  }
  if (rlang::is_string(x) && x %in% choices) {
    return(x)
  }
  abort_hcesfort("argument", c(
    "{.arg {arg}} must be one of {.val {choices}}."
  ), arg = arg, call = call)
}

# Abort unless reference_kcal and pal are positive numbers and weight_kg
# is a positive numeric vector named female and male.
check_afe_args <- function(reference_kcal, weight_kg, pal,
                           call = rlang::caller_env()) {
  positive <- function(v) is.numeric(v) && all(is.finite(v) & v > 0)
  if (!(positive(reference_kcal) && length(reference_kcal) == 1)) {
    abort_afe_arg("reference_kcal", "one positive number (kcal per day)",
                  call)
  }
  if (!(positive(pal) && length(pal) == 1)) {
    abort_afe_arg("pal", "one positive number", call)
  }
  named <- !is.null(names(weight_kg)) &&
    setequal(names(weight_kg), c("female", "male")) && length(weight_kg) == 2
  if (!(positive(weight_kg) && named)) {
    abort_afe_arg("weight_kg", paste(
      "a positive numeric vector named {.code female} and {.code male},",
      "for example {.code c(female = 55, male = 65)}"
    ), call)
  }
  invisible(TRUE)
}

abort_afe_arg <- function(arg, what, call) {
  abort_hcesfort("argument", c(
    paste0("{.arg ", arg, "} must be ", what, ".")
  ), arg = arg, call = call)
}

# TRUE or FALSE: whether to use meals_home_share. Required when the column
# is present; must not be TRUE when it is absent.
check_meal_share <- function(meal_share, m, call = rlang::caller_env()) {
  has_column <- !is.null(m[["meals_home_share"]])
  if (is.null(meal_share) && !has_column) {
    return(FALSE)
  }
  ok <- rlang::is_bool(meal_share) && (has_column || !meal_share)
  if (ok) {
    return(meal_share)
  }
  abort_hcesfort("argument", c(
    if (has_column) {
      "{.arg members} has {.field meals_home_share}: say whether to use it."
    } else {
      "{.arg meal_share} is {.val TRUE} but {.arg members} has no
      {.field meals_home_share}."
    },
    "i" = "Set {.arg meal_share} to {.val TRUE} or {.val FALSE}."
  ), arg = "meal_share", call = call)
}

# Abort when a member with age and sex has no requirement: the reference
# tables have a gap at that age.
check_covered <- function(m, kcal, call = rlang::caller_env()) {
  gap <- which(!is.na(m$age_years) & !is.na(m$sex) & is.na(kcal))
  if (length(gap) == 0) {
    return(invisible(TRUE))
  }
  abort_hcesfort("value", c(
    "{length(gap)} member{?s} {?has/have} no energy requirement.",
    "x" = cli_escape(problem_bullet("member without requirement", gap)),
    "i" = paste(
      "The reference tables have no interval for their sex and age;",
      "check {.arg energy} and {.arg bmr}."
    )
  ), table = "members", columns = c("age_years", "sex"), rows = gap,
  n = length(gap), call = call)
}
