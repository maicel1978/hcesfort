test_that("nutrient_registry() builds the column names", {
  r <- nutrient_registry(c(energy = "kcal", iron = "mg", folate = "ug_dfe"))
  expect_s3_class(r, c("hces_nutrients", "tbl_df"))
  expect_named(r, c("nutrient", "unit", "column"))
  expect_identical(r$column, c("energy_kcal", "iron_mg", "folate_ug_dfe"))
})

test_that("equivalent tags are kept and the base is parsed", {
  r <- nutrient_registry(c(vitamin_a = "ug_rae", niacin = "mg_ne"))
  expect_identical(r$unit, c("ug_rae", "mg_ne"))
  expect_identical(unit_base(r$unit), c("ug", "mg"))
  expect_identical(unit_base(c("kj", "g")), c("kj", "g"))
})

test_that("bad nutrient names are argument errors", {
  for (bad in list(c(iron = "mg", iron = "ug"), c(Iron = "mg"),
                   c("mg"), c(`iron mg` = "mg"), character(0),
                   list(iron = "mg"), c(iron = NA_character_))) {
    expect_error(nutrient_registry(bad), class = "hcesfort_error_argument")
  }
})

test_that("an unknown base unit is a units error", {
  err <- expect_error(nutrient_registry(c(iron = "mg", zinc = "mcg")),
                      class = "hcesfort_error_units")
  expect_identical(err$columns, "zinc")
  expect_error(nutrient_registry(c(iron = "MG")),
               class = "hcesfort_error_units")
})

test_that("require_registry() rejects a plain vector", {
  expect_error(require_registry(c(iron = "mg")),
               class = "hcesfort_error_argument")
})
