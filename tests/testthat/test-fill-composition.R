# fill_composition(). Fixture: the composition of test-link-composition.R
# (C5 has no iron); fills invented.

fill_comp <- function() {
  data.frame(
    composition_id = paste0("C", 1:3), iron_mg = c(2, NA, NA),
    folate_ug_dfe = c(10, 0, NA), basis = "per_100g_edible",
    food_state = "raw", source = "test fixture"
  )
}

fill_nutrients <- function() {
  nutrient_registry(c(iron = "mg", folate = "ug_dfe"))
}

# By hand: C2 iron NA -> 1.5; C3 iron NA -> 0; C3 folate NA -> 20;
# C1 iron is 2, so the fill of 9 is not used.
fill_values <- function() {
  data.frame(
    composition_id = c("C2", "C3", "C3", "C1"),
    nutrient = c("iron", "iron", "folate", "iron"),
    value = c(1.5, 0, 20, 9),
    source = c("borrowed", "zero rule", "borrowed", "borrowed")
  )
}

test_that("fill_composition() fills only missing values, by hand", {
  x <- fill_composition(fill_comp(), fill_values(), fill_nutrients())
  expect_s3_class(x, c("hces_composition", "hces_tbl"))
  expect_equal(x$iron_mg, c(2, 1.5, 0))
  expect_equal(x$folate_ug_dfe, c(10, 0, 20))
  log <- audit_log(x)
  l <- log[log$step == "fill_composition", ]
  filled <- l[l$cause == "filled_from_table", ]
  expect_equal(filled$detail, c("folate_ug_dfe", "iron_mg"))
  expect_equal(filled$n_records, c(1, 2))
  expect_equal(l$n_records[l$cause == "fill_not_needed"], 1)
  expect_identical(attr(x, "nutrients"), fill_nutrients())
})

test_that("filling never lowers a value and row order does not matter", {
  base <- fill_composition(fill_comp(), fill_values(), fill_nutrients())
  perm <- fill_composition(fill_comp()[3:1, ], fill_values()[4:1, ],
                           fill_nutrients())
  expect_equal(perm$iron_mg, base$iron_mg[3:1])
  orig <- fill_comp()
  keep <- !is.na(orig$iron_mg)
  expect_equal(base$iron_mg[keep], orig$iron_mg[keep])
})

test_that("a filled table links, and its registry travels", {
  comp <- validate_composition(fill_comp(), fill_nutrients())
  x <- fill_composition(comp, fill_values()[1, ])
  expect_equal(x$iron_mg[2], 1.5)
  expect_true("validate_composition" %in% audit_log(x)$step)
})

test_that("an empty fills table changes nothing", {
  x <- fill_composition(fill_comp(), fill_values()[0, ], fill_nutrients())
  expect_equal(x$iron_mg, fill_comp()$iron_mg)
})

test_that("fills are checked against their contract and the table", {
  f <- fill_values()
  f$nutrient[1] <- "zinc"
  expect_error(fill_composition(fill_comp(), f, fill_nutrients()),
               class = "hcesfort_error_value")
  f <- fill_values()
  f$value[1] <- -1
  expect_error(fill_composition(fill_comp(), f, fill_nutrients()),
               class = "hcesfort_error_value")
  f <- fill_values()
  f$composition_id[1] <- "C9"
  expect_error(fill_composition(fill_comp(), f, fill_nutrients()),
               class = "hcesfort_error_join")
  f <- fill_values()
  f$composition_id <- 1:4
  expect_error(fill_composition(fill_comp(), f, fill_nutrients()),
               class = "hcesfort_error_join")
  expect_error(fill_composition(fill_comp(), rbind(fill_values(),
                                                   fill_values()[1, ]),
                                fill_nutrients()),
               class = "hcesfort_error_key")
  expect_error(fill_composition(fill_comp(), fill_values()),
               class = "hcesfort_error_argument")
})
