# Reference tables (data-raw/SOURCES.md). The first two tests need the
# source repository (data-raw/ is not part of the built package) and are
# skipped in R CMD check; the invariants run everywhere.

data_raw_dir <- function() {
  dir <- testthat::test_path("..", "..", "data-raw")
  if (!file.exists(file.path(dir, "MD5"))) {
    testthat::skip("data-raw/ is not reachable (installed package).")
  }
  dir
}

ref_tables <- function() {
  names <- c(
    "ref_requirements", "ref_iron_requirements", "ref_energy_requirements",
    "ref_bmr_equations", "ref_conversions", "ref_who2009_flour"
  )
  rlang::set_names(lapply(names, get), names)
}

test_that("every reference CSV has the md5 registered in data-raw/MD5", {
  dir <- data_raw_dir()
  registry <- utils::read.table(file.path(dir, "MD5"),
                                col.names = c("md5", "file"))
  expect_setequal(registry$file, list.files(dir, pattern = "\\.csv$"))
  actual <- unname(tools::md5sum(file.path(dir, registry$file)))
  expect_identical(actual, registry$md5)
})

test_that("the shipped tables are the verified rows of the CSV files", {
  dir <- data_raw_dir()
  env <- new.env()
  sys.source(file.path(dir, "reference.R"), envir = env)
  shipped <- ref_tables()
  expect_setequal(names(env$reference_files), names(shipped))
  for (name in names(shipped)) {
    built <- env$read_reference(env$reference_files[[name]], dir = dir)
    expect_identical(built, shipped[[name]], label = name)
  }
})

test_that("every shipped row has a source and a place, none pending", {
  for (x in ref_tables()) {
    expect_s3_class(x, "tbl_df")
    expect_false(anyNA(x$source) || anyNA(x$location))
    expect_false("status" %in% names(x))
    text <- unlist(x[vapply(x, is.character, logical(1))])
    expect_false(any(grepl("PENDING", text, fixed = TRUE)))
  }
})

test_that("requirements: EAR below UL, vocabulary of ul_applies_to", {
  r <- ref_requirements
  expect_false(anyDuplicated(r[c("nutrient", "sex", "age_from")]) > 0)
  has_ul <- !is.na(r$ul)
  expect_true(all(r$ear[has_ul] < r$ul[has_ul]))
  expect_identical(is.na(r$ul), is.na(r$ul_applies_to))
  expect_true(all(r$ul_applies_to[has_ul] %in% c(
    "total", "preformed_vitamin_a", "folic_acid",
    "supplemental_alpha_tocopherol"
  )))
  # Units parse as units of the nutrient registry.
  expect_s3_class(nutrient_registry(rlang::set_names(r$unit, r$nutrient)),
                  "hces_nutrients")
  expect_false("vitamin_d" %in% r$nutrient)
})

test_that("iron: 13 increasing percentiles per group; median near EAR", {
  ir <- ref_iron_requirements
  p <- c(2.5, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 97.5)
  for (g in split(ir, ir$group)) {
    expect_identical(g$percentile, p)
    expect_true(all(diff(g$requirement_mg_d) > 0))
  }
  expect_length(unique(ir$group), 14L)
  # The EAR is the 50th percentile, rounded (IOM 2001, Table I-4, note c).
  women <- ir[ir$group == "females_menstruating_adult", ]
  ear <- ref_requirements$ear[ref_requirements$nutrient == "iron"]
  expect_lt(abs(women$requirement_mg_d[women$percentile == 50] - ear), 0.05)
})

# TRUE when the intervals [from, to) of one table follow each other with
# neither gap nor overlap.
contiguous <- function(from, to) {
  o <- order(from)
  all(utils::head(to[o], -1) == from[o][-1])
}

test_that("energy tables: contiguous ages, hand-computed values", {
  e <- ref_energy_requirements
  for (g in split(e, list(e$sex, e$age_unit))) {
    expect_true(contiguous(g$age_from, g$age_to))
  }
  months <- e[e$age_unit == "month", ]
  expect_identical(nrow(months), 24L)
  # Mean of the twelve months, as in the original analysis: 649 and 600.
  expect_equal(mean(months$energy_kcal_d[months$sex == "male"]),
               7793 / 12)
  expect_equal(mean(months$energy_kcal_d[months$sex == "female"]),
               7205 / 12)
  b <- ref_bmr_equations
  for (g in split(b, b$sex)) {
    expect_true(contiguous(g$age_from, g$age_to))
    expect_identical(range(c(g$age_from, g$age_to)), c(0, Inf))
  }
  # Woman 18-30 y, 55 kg, PAL 1.76: 2290.8 kcal/day in the original.
  w <- b[b$sex == "female" & b$age_from == 18, ]
  expect_equal((w$slope_kcal_kg * 55 + w$intercept_kcal) * 1.76,
               (14.818 * 55 + 486.6) * 1.76)
  expect_equal(round((w$slope_kcal_kg * 55 + w$intercept_kcal) * 1.76, 1),
               2290.8)
})

test_that("conversions: positive factors, RAE carotenoid ratios", {
  cv <- ref_conversions
  expect_true(all(cv$factor > 0))
  rae <- stats::setNames(cv$factor, cv$from_form)
  expect_equal(rae[["dietary_beta_carotene"]], 1 / 12)
  expect_equal(rae[["other_provitamin_a_carotenoids"]], 1 / 24)
  expect_equal(rae[["folic_acid"]], 1.7)
  expect_false("retinyl_palmitate" %in% cv$from_form)
})

test_that("WHO 2009: four categories per row, levels fall with intake", {
  w <- ref_who2009_flour
  expect_identical(w$recommended, !is.na(w$level_mg_kg))
  cats <- c("<75", "75-149", "150-300", ">300")
  for (g in split(w, list(w$nutrient, w$extraction, w$compound),
                  drop = TRUE)) {
    expect_identical(g$availability_g_d, cats)
    lv <- g$level_mg_kg[g$recommended]
    expect_true(all(diff(lv) <= 0))
  }
  expect_identical(nrow(w), 40L)
  expect_true(all(w$level_basis == "nutrient"))
})
