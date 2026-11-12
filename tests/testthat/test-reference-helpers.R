# reference_energy() and who2009_levels().

test_that("reference_energy() applies the equation of the age by hand", {
  # FAO/WHO/UNU 2004, women 18-30: 14.818 * 55 + 486.6 = 1,301.59;
  # times 1.76 = 2,290.7984.
  expect_equal(reference_energy("female", 25, 55, 1.76), 2290.7984,
               tolerance = 1e-10)
  # Men 30-60: (11.472 * 70 + 873.1) * 1.5 = 2,514.21.
  expect_equal(reference_energy("male", 45, 70, 1.5), 2514.21,
               tolerance = 1e-10)
  # Interval [age_from, age_to): 30 years uses the 30-60 equation.
  expect_equal(reference_energy("female", 30, 55, 1),
               8.126 * 55 + 845.6, tolerance = 1e-10)
})

test_that("reference_energy() scales with pal and takes another table", {
  e1 <- reference_energy("female", 25, 55, 1)
  expect_equal(reference_energy("female", 25, 55, 2), 2 * e1,
               tolerance = 1e-12)
  bmr <- data.frame(sex = "female", age_from = 0, age_to = Inf,
                    slope_kcal_kg = 10, intercept_kcal = 100,
                    source = "test fixture")
  expect_identical(reference_energy("female", 25, 50, 2, bmr = bmr), 1200)
})

test_that("reference_energy() fails without an equation or with bad input", {
  bmr <- data.frame(sex = "female", age_from = 18, age_to = 30,
                    slope_kcal_kg = 10, intercept_kcal = 100,
                    source = "test fixture")
  expect_error(reference_energy("female", 40, 55, 1.76, bmr = bmr),
               class = "hcesfort_error_value")
  expect_error(reference_energy("male", 25, 55, 1.76, bmr = bmr),
               class = "hcesfort_error_value")
  bad <- list(list(sex = "woman"), list(age_years = -1),
              list(age_years = NA_real_), list(weight_kg = 0),
              list(weight_kg = c(55, 60)), list(pal = -1),
              list(pal = "1.76"))
  base <- list(sex = "female", age_years = 25, weight_kg = 55, pal = 1.76)
  for (b in bad) {
    err <- expect_error(do.call(reference_energy, utils::modifyList(base, b)),
                        class = "hcesfort_error_argument")
    expect_identical(err$arg, names(b))
  }
  expect_error(reference_energy("female", 25),
               class = "hcesfort_error_argument")
  expect_error(reference_energy("female", 25, 55, 1.76, bmr = bmr[, 1:3]),
               class = "hcesfort_error_schema")
})

test_that("who2009_levels() places boundary values in their band", {
  band <- function(a) {
    unique(who2009_levels(a, "low")$availability_g_d)
  }
  expect_identical(band(0), "<75")
  expect_identical(band(74.9), "<75")
  expect_identical(band(75), "75-149")
  expect_identical(band(149.5), "75-149")
  expect_identical(band(150), "150-300")
  expect_identical(band(300), "150-300")
  expect_identical(band(300.1), ">300")
  expect_identical(band(1e6), ">300")
})

test_that("who2009_levels() returns one row per nutrient and compound", {
  low <- who2009_levels(120, "low")
  # Low extraction: 4 iron compounds, folic acid, B12, vitamin A, zinc.
  expect_identical(nrow(low), 8L)
  expect_false(anyDuplicated(low[c("nutrient", "compound")]) > 0)
  expect_identical(
    low$level_mg_kg[low$compound == "ferrous sulfate"], 60
  )
  expect_identical(low$level_mg_kg[low$nutrient == "folic_acid"], 2.6)
  # Electrolytic iron is not recommended below 150 g per day.
  el <- low[low$compound == "electrolytic iron", ]
  expect_false(el$recommended)
  expect_true(is.na(el$level_mg_kg))
  high <- who2009_levels(200, "high")
  expect_identical(sort(unique(high$extraction)), c("high", "low or high"))
  expect_identical(high$level_mg_kg[high$nutrient == "zinc"], 80)
  expect_identical(nrow(high), 5L)
})

test_that("who2009_levels() is a filter: rows unchanged, order irrelevant", {
  shuffled <- ref_who2009_flour[rev(seq_len(nrow(ref_who2009_flour))), ]
  a <- who2009_levels(160, "low")
  b <- who2009_levels(160, "low", table = shuffled)
  key <- function(x) x[order(x$nutrient, x$compound), ]
  expect_identical(as.data.frame(key(a)), as.data.frame(key(b)))
  expect_identical(names(a), names(ref_who2009_flour))
})

test_that("who2009_levels() checks its arguments", {
  for (a in list(-1, NA_real_, Inf, c(1, 2), "100")) {
    err <- expect_error(who2009_levels(a, "low"),
                        class = "hcesfort_error_argument")
    expect_identical(err$arg, "availability_g_d")
  }
  err <- expect_error(who2009_levels(100, "medium"),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "extraction")
  expect_error(who2009_levels(100), class = "hcesfort_error_argument")
  expect_error(who2009_levels(100, "low", table = ref_who2009_flour[, 1:3]),
               class = "hcesfort_error_schema")
})
