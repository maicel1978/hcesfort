#' Validate the three tables of a survey together
#'
#' Validates `households`, `members` and `acquisitions` with
#' [validate_households()] and its siblings, then checks how they refer to
#' each other:
#'
#' * `household_id` must have a compatible type in the three tables (all
#'   text or all numeric); otherwise every later join would fail
#'   (`hcesfort_error_join`);
#' * every member and every acquisition must belong to a household of
#'   `households` (`hcesfort_error_join`).
#'
#' Households without members and households without acquisitions are
#' accepted: they stay in the survey design. They are counted as `note`
#' rows (`households_without_members`, `households_without_acquisitions`)
#' in the audit log of `households`.
#'
#' @param households,members,acquisitions Data frames with the columns of
#'   their schemas ([hces_schema()]).
#' @returns A list of class `hces_survey` with the three validated tables,
#'   named `households`, `members` and `acquisitions`.
#' @seealso [validate_households()], [hcesfort_errors].
#' @examples
#' households <- data.frame(
#'   household_id = 1:2, weight = c(150, 210), stratum = 1, psu = 1:2
#' )
#' members <- data.frame(
#'   household_id = c(1L, 1L, 2L), member_id = c(1L, 2L, 1L),
#'   age_years = c(34, 6, 71), sex = c("female", "male", "female")
#' )
#' acquisitions <- data.frame(
#'   record_id = 1:3, household_id = c(1L, 1L, 2L),
#'   food_code = c("rice", "oil", "rice"), quantity = c(2, 1, 1),
#'   unit = c("lb", "l", "lb"), section = "diary", period_days = 7,
#'   include = TRUE
#' )
#' survey <- validate_survey(households, members, acquisitions)
#' audit_log(survey$households)
#' @export
validate_survey <- function(households, members, acquisitions) {
  check_required()
  households <- validate_households(households)
  members <- validate_members(members)
  acquisitions <- validate_acquisitions(acquisitions)
  check_household_refs(members, households, "members")
  check_household_refs(acquisitions, households, "acquisitions")
  if (!"validate_survey" %in% audit_get(households)$step) {
    ids <- households$household_id
    flags <- list(
      households_without_members = !ids %in% members$household_id,
      households_without_acquisitions = !ids %in% acquisitions$household_id
    )
    notes <- count_notes(households, "validate_survey", "households", flags)
    attr(households, "audit") <- dplyr::bind_rows(audit_get(households),
                                                  notes)
  }
  structure(
    list(households = households, members = members,
         acquisitions = acquisitions),
    class = "hces_survey"
  )
}

# Abort unless every `household_id` of `x` is in `households`, with a
# compatible type.
check_household_refs <- function(x, households, table,
                                 call = rlang::caller_env()) {
  if (!same_id_type(x$household_id, households$household_id)) {
    abort_hcesfort("join", c(
      "{.field household_id} has another type in {.arg {table}}.",
      "x" = paste(
        "{.cls {class(x$household_id)}} in {.arg {table}},",
        "{.cls {class(households$household_id)}} in {.arg households}."
      ),
      "i" = "Use the same type in every table."
    ), table = table, other = "households", columns = "household_id",
    n = NA_integer_, call = call)
  }
  orphan <- !x$household_id %in% households$household_id
  if (!any(orphan)) {
    return(invisible(x))
  }
  ids <- unique(x$household_id[orphan])
  absent <- paste0(
    "household_id absent from `households`: ",
    paste(utils::head(ids, 5), collapse = ", "),
    if (length(ids) > 5) ", ...", "."
  )
  abort_hcesfort("join", c(
    "{sum(orphan)} row{?s} of {.arg {table}} belong{?s/} to no household.",
    "x" = cli_escape(absent),
    "i" = "Add the households, or remove the rows and say why."
  ), table = table, other = "households", columns = "household_id",
  n = sum(orphan), call = call)
}
