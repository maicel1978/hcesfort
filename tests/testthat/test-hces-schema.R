test_that("hces_schema() describes every standard table", {
  for (table in c("households", "members", "acquisitions")) {
    s <- hces_schema(table)
    expect_named(s, c("column", "type", "required", "na", "key", "rule",
                      "description"))
    expect_true(all(s$type %in% schema_types))
  }
  s <- hces_schema("members")
  expect_identical(s$column[s$key], c("household_id", "member_id"))
  expect_identical(s$rule[s$column == "sex"], "female, male")
  expect_identical(s$rule[s$column == "meals_home_share"], "in [0, 1]")
})

test_that("the required columns are those the validator requires", {
  fixtures <- list(households = fixture_households(),
                   members = fixture_members(),
                   acquisitions = fixture_acquisitions())
  validators <- list(households = validate_households,
                     members = validate_members,
                     acquisitions = validate_acquisitions)
  for (table in names(fixtures)) {
    required <- with(hces_schema(table), column[required])
    for (col in required) {
      x <- fixtures[[table]]
      x[[col]] <- NULL
      expect_error(validators[[table]](x), class = "hcesfort_error_schema",
                   info = paste(table, col))
    }
    optional <- with(hces_schema(table), column[!required])
    expect_length(intersect(optional, names(fixtures[[table]])), 0)
  }
})

test_that("hces_schema() rejects an unknown table", {
  err <- expect_error(hces_schema("food"), class = "hcesfort_error_argument")
  expect_identical(err$arg, "table")
  expect_error(hces_schema(c("members", "households")),
               class = "hcesfort_error_argument")
})

test_that("hces_schema() describes the user-supplied tables", {
  for (table in c("unit_factors", "crosswalk", "composition", "vehicles",
                  "scenarios")) {
    expect_s3_class(hces_schema(table), "tbl_df")
  }
  s <- hces_schema("composition")
  expect_true("<nutrient>_<unit>" %in% s$column)
  s <- hces_schema("unit_factors")
  expect_identical(s$column[s$key], c("unit", "food_code"))
})

test_that("user-table schemas list the columns their validators require", {
  r <- fixture_nutrients()
  cases <- list(
    unit_factors = list(fixture_unit_factors(), validate_unit_factors),
    crosswalk = list(fixture_crosswalk(), validate_crosswalk),
    vehicles = list(fixture_vehicles(), validate_vehicles),
    composition = list(fixture_composition(),
                       function(x) validate_composition(x, r)),
    scenarios = list(fixture_scenarios(),
                     function(x) validate_scenarios(x, r))
  )
  for (table in names(cases)) {
    required <- with(hces_schema(table), column[required])
    required <- setdiff(required, "<nutrient>_<unit>")
    for (col in required) {
      x <- cases[[table]][[1]]
      x[[col]] <- NULL
      expect_error(cases[[table]][[2]](x), class = "hcesfort_error_schema",
                   info = paste(table, col))
    }
  }
})
