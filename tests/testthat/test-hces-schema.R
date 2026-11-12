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
