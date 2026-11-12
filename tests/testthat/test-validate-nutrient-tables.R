test_that("composition: valid table passes and keeps the registry", {
  r <- fixture_nutrients()
  x <- validate_composition(fixture_composition(), r)
  expect_s3_class(x, c("hces_composition", "hces_tbl"))
  expect_identical(attr(x, "nutrients"), r)
  expect_identical(x$label, c("a", "b", "c"))
  expect_identical(validate_composition(x, r), x)
})

test_that("composition: missing values counted per nutrient by hand", {
  log <- audit_log(validate_composition(fixture_composition(),
                                        fixture_nutrients()))
  expect_identical(log$cause, c("all", rep("missing_nutrient_value", 2)))
  expect_identical(log$detail, c(NA, "iron_mg", "folate_ug_dfe"))
  expect_identical(log$n_records, c(3L, 1L, 2L))
})

test_that("composition: a missing registry column is a schema error", {
  x <- fixture_composition()
  x$folate_ug_dfe <- NULL
  err <- expect_error(validate_composition(x, fixture_nutrients()),
                      class = "hcesfort_error_schema")
  expect_identical(err$columns, "folate_ug_dfe")
})

test_that("composition: a nutrient with another unit is a units error", {
  x <- fixture_composition()
  names(x)[names(x) == "iron_mg"] <- "iron_ug"
  err <- expect_error(validate_composition(x, fixture_nutrients()),
                      class = "hcesfort_error_units")
  expect_identical(err$columns, "iron_ug")
  # Both columns present: still a units error.
  x <- fixture_composition()
  x$folate_ug <- 1
  expect_error(validate_composition(x, fixture_nutrients()),
               class = "hcesfort_error_units")
  # A column that only starts with the nutrient's name is not a unit.
  x <- fixture_composition()
  x$iron_source <- "x"
  expect_s3_class(validate_composition(x, fixture_nutrients()),
                  "hces_composition")
})

test_that("composition: wrong basis, state and negative content fail", {
  x <- fixture_composition()
  x$basis[1] <- "per_100g"
  x$food_state[2] <- "fried"
  x$iron_mg[3] <- -1
  err <- expect_error(validate_composition(x, fixture_nutrients()),
                      class = "hcesfort_error_value")
  expect_identical(err$rows, 1:3)
  expect_identical(err$columns, c("iron_mg", "basis", "food_state"))
})

test_that("composition: the registry is required", {
  expect_error(validate_composition(fixture_composition(), c(iron = "mg")),
               class = "hcesfort_error_argument")
  expect_error(validate_composition(list(), fixture_nutrients()),
               class = "hcesfort_error_schema")
})

test_that("scenarios: absent compliance is added as 1 with its note", {
  x <- validate_scenarios(fixture_scenarios(), fixture_nutrients())
  expect_s3_class(x, c("hces_scenarios", "hces_tbl"))
  expect_identical(x$compliance, c(1, 1))
  log <- audit_log(x)
  expect_identical(log$cause, c("all", "compliance_assumed_full"))
  expect_identical(log$n_records, c(2L, 2L))
  # Revalidation adds no second note.
  expect_identical(validate_scenarios(x, fixture_nutrients()), x)
})

test_that("scenarios: given compliance is kept without a note", {
  s <- fixture_scenarios()
  s$compliance <- c(0.8, 1)
  log <- audit_log(validate_scenarios(s, fixture_nutrients()))
  expect_identical(log$cause, "all")
  s$compliance[1] <- 1.2
  expect_error(validate_scenarios(s, fixture_nutrients()),
               class = "hcesfort_error_value")
  s$compliance[1] <- NA
  expect_error(validate_scenarios(s, fixture_nutrients()),
               class = "hcesfort_error_value")
})

test_that("scenarios: nutrient outside the registry is a value error", {
  s <- fixture_scenarios()
  s$nutrient[1] <- "zinc"
  err <- expect_error(validate_scenarios(s, fixture_nutrients()),
                      class = "hcesfort_error_value")
  expect_identical(err$columns, "nutrient")
})

test_that("scenarios: compound basis needs the nutrient fraction", {
  s <- fixture_scenarios()
  s$nutrient_fraction[2] <- NA
  err <- expect_error(validate_scenarios(s, fixture_nutrients()),
                      class = "hcesfort_error_value")
  expect_identical(err$rows, 2L)
  s$nutrient_fraction <- NULL
  expect_error(validate_scenarios(s, fixture_nutrients()),
               class = "hcesfort_error_value")
  s$level_basis <- "nutrient"
  expect_s3_class(validate_scenarios(s, fixture_nutrients()),
                  "hces_scenarios")
})

test_that("scenarios: duplicated scenario, vehicle and nutrient fail", {
  s <- fixture_scenarios()
  s$nutrient[2] <- "iron"
  expect_error(validate_scenarios(s, fixture_nutrients()),
               class = "hcesfort_error_key")
})

test_that("results do not depend on row order", {
  x <- fixture_composition()
  r <- fixture_nutrients()
  expect_identical(audit_log(validate_composition(x[3:1, ], r)),
                   audit_log(validate_composition(x, r)))
})

test_that("scenarios: nutrient fraction with basis nutrient is a value error", {
  s <- fixture_scenarios()
  s$nutrient_fraction[[1]] <- 0.5
  err <- expect_error(validate_scenarios(s, fixture_nutrients()),
                      class = "hcesfort_error_value")
  expect_identical(err$rows, 1L)
  expect_identical(err$columns, "nutrient_fraction")
})

test_that("scenarios: form is kept and a pending source is counted", {
  s <- fixture_scenarios()
  s$form <- c(NA, "folic_acid")
  s$source[[2]] <- "SOURCE PENDING"
  out <- validate_scenarios(s, fixture_nutrients())
  expect_identical(out$form, c(NA, "folic_acid"))
  log <- audit_log(out)
  expect_identical(log$n_records[log$cause == "source_pending"], 1L)
})

# Enrichment rules: one by reference pair, one by amount added.
fixture_enrichment <- function() {
  data.frame(
    composition_id = c("C01", "C02"), nutrient = c("iron", "folate"),
    enriched_ref_id = c("C03", NA), unenriched_ref_id = c("C04", NA),
    ingredient_fraction = c(0.6, NA), added = c(NA, 100),
    source = c("invented", "SOURCE PENDING")
  )
}

test_that("enrichment: both ways pass, pending source counted", {
  out <- validate_enrichment(fixture_enrichment(), fixture_nutrients())
  expect_s3_class(out, "hces_enrichment")
  log <- audit_log(out)
  expect_identical(log$cause, c("all", "source_pending"))
  expect_identical(log$n_records, c(2L, 1L))
})

test_that("enrichment: absent columns of one way are added as missing", {
  e <- fixture_enrichment()[2, c("composition_id", "nutrient", "added",
                                 "source")]
  out <- validate_enrichment(e, fixture_nutrients())
  expect_true(is.na(out$enriched_ref_id))
  e0 <- e[0, ]
  expect_identical(nrow(validate_enrichment(e0, fixture_nutrients())), 0L)
})

test_that("enrichment: both, neither or a partial pair is a value error", {
  e <- fixture_enrichment()
  e <- rbind(e, e, e)
  e$composition_id <- paste0("C", 1:6)
  e$added[[1]] <- 5
  e$added[[2]] <- NA
  e$unenriched_ref_id[[3]] <- NA
  err <- expect_error(validate_enrichment(e, fixture_nutrients()),
                      class = "hcesfort_error_value")
  expect_identical(err$rows, 1:3)
})

test_that("enrichment: key, vocabulary and fraction are checked", {
  e <- fixture_enrichment()
  e$composition_id[[2]] <- "C01"
  e$nutrient[[2]] <- "iron"
  expect_error(validate_enrichment(e, fixture_nutrients()),
               class = "hcesfort_error_key")
  e <- fixture_enrichment()
  e$nutrient[[1]] <- "zinc"
  expect_error(validate_enrichment(e, fixture_nutrients()),
               class = "hcesfort_error_value")
  e <- fixture_enrichment()
  e$ingredient_fraction[[1]] <- 1.2
  expect_error(validate_enrichment(e, fixture_nutrients()),
               class = "hcesfort_error_value")
  expect_error(validate_enrichment(e, "iron"),
               class = "hcesfort_error_argument")
})
