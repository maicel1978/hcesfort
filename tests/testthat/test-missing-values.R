# missing_values(): the work queue of missing composition values.
#
# Fixture of finding 8 (liver_case()) in helper-missing-values.R.

test_that("the only source of a nutrient without a value is listed", {
  x <- liver_case()
  v <- missing_values(x$content, x$households)
  expect_identical(nrow(v), 1L)
  expect_identical(v$nutrient, "vitamin_a")
  expect_identical(v$column, "vitamin_a_ug_rae")
  expect_identical(v$food_code, "liver")
  expect_identical(v$composition_id, "L1")
  expect_identical(v$n_records, 3L)
  expect_identical(v$n_households, 3L)
  expect_equal(v$qty_edible_g_d, 30)
  expect_equal(v$share_grams, 10 / 410)
  expect_identical(v$rank, 1L)
  expect_equal(v$cum_share_grams, 1)
  expect_s3_class(v, "tbl_df")
})

test_that("nutrients selects and orders by the registry", {
  x <- liver_case()
  expect_identical(nrow(missing_values(x$content, x$households, "iron")), 0L)
  v <- missing_values(x$content, x$households, c("vitamin_a", "iron"))
  expect_identical(v$nutrient, "vitamin_a")
  # Registry order, once each, whatever the order of the argument.
  y <- liver_case(comp = data.frame(composition_id = c("R1", "L1", "B1"),
                                    iron_mg = c(1, NA, 1),
                                    vitamin_a_ug_rae = c(0, NA, 0)))
  v <- missing_values(y$content, y$households,
                      c("vitamin_a", "iron", "iron"))
  expect_identical(v$nutrient, c("iron", "vitamin_a"))
})

test_that("the lk fixture: weights, edible portion, the ranks and shares", {
  # Linked and included (weights 2, 1, 3): rice 100 g x 2 = 200, oil
  # (edible 0.5) (25 + 5) x 2 = 60, fish 60 x 3 = 180: 440 weighted
  # edible grams. Fish (C5) has no iron: 180 / 440.
  v <- missing_values(lk_content(), lk_households())
  expect_identical(v$food_code, "fish")
  expect_identical(v$composition_id, "C5")
  expect_equal(v$qty_edible_g_d, 180)
  expect_equal(v$share_grams, 180 / 440)
  expect_equal(v$cum_share_grams, 1)
})

test_that("a food with two composition rows, and the rank by grams", {
  # Bread, no value, 50 g in household 1 only; the liver of household 3
  # is moved to the composition row L2 (no value either). By hand: liver
  # 30 g (L1; L2), bread 50 g; total 1280. Bread ranks first.
  x <- liver_case(comp = data.frame(
    composition_id = c("R1", "L1", "B1"), iron_mg = 1,
    vitamin_a_ug_rae = c(0, NA, NA)
  ), bread = TRUE)
  y <- as.data.frame(x$content)
  y$composition_id[y$household_id == 3 & y$food_code == "liver"] <- "L2"
  y <- restore_audit(y, x$content)
  v <- missing_values(y, x$households, "vitamin_a")
  expect_identical(v$food_code, c("bread", "liver"))
  expect_identical(v$composition_id, c("B1", "L1; L2"))
  expect_identical(v$n_households, c(1L, 3L))
  expect_equal(v$share_grams, c(50, 30) / 1280)
  expect_equal(v$cum_share_grams, (1200 + cumsum(c(50, 30))) / 1280)
  expect_identical(v$rank, 1:2)
})

test_that("shares sum to one minus the weighted coverage by grams", {
  content <- example_content(biscuit = TRUE)
  h <- hces_fixture()$households
  v <- missing_values(content, h)
  expect_gt(nrow(v), 0)
  w <- h$weight[match(content$household_id, h$household_id)]
  used <- content$include & content$composition_status == "linked"
  g <- content$qty_edible_g_d * w
  for (n in unique(v$nutrient)) {
    col <- v$column[v$nutrient == n][[1]]
    covered <- sum(g[used & !is.na(content[[col]])]) / sum(g[used])
    expect_equal(sum(v$share_grams[v$nutrient == n]), 1 - covered, info = n)
    cum <- v$cum_share_grams[v$nutrient == n]
    expect_equal(cum[[length(cum)]], 1, info = n)
    expect_true(all(diff(cum) > 0), info = n)
  }
})

test_that("not included and not linked records do not count", {
  x <- liver_case()
  y <- x$content
  y$include[y$household_id == 1 & y$food_code == "liver"] <- FALSE
  y$composition_status[y$household_id == 2 &
                         y$food_code == "liver"] <- "not_validated"
  v <- missing_values(y, x$households)
  expect_identical(v$n_records, 1L)
  expect_equal(v$share_grams, 10 / (3 * 400 + 10))
})

test_that("weights scale amounts, not shares; row order does not matter", {
  e <- example_content(biscuit = TRUE)
  h <- hces_fixture()$households
  a <- missing_values(e, h)
  h4 <- h
  h4$weight <- h4$weight * 4
  b <- missing_values(e, h4)
  expect_equal(b$qty_edible_g_d, a$qty_edible_g_d * 4)
  same <- setdiff(names(a), "qty_edible_g_d")
  expect_equal(b[same], a[same])
  r <- restore_audit(as.data.frame(e)[rev(seq_len(nrow(e))), ], e)
  expect_equal(missing_values(r, h[rev(seq_len(nrow(h))), ]), a)
})

test_that("nothing missing gives no rows with the same columns", {
  x <- liver_case(comp = data.frame(composition_id = c("R1", "L1", "B1"),
                                    iron_mg = 1, vitamin_a_ug_rae = 5))
  v <- missing_values(x$content, x$households)
  expect_identical(nrow(v), 0L)
  expect_identical(names(v), c("nutrient", "column", "food_code",
                               "composition_id", "n_records",
                               "n_households", "qty_edible_g_d",
                               "share_grams", "rank", "cum_share_grams"))
})

test_that("errors: wrong table, unknown nutrient, households missing", {
  x <- liver_case()
  expect_error(missing_values(x$households, x$households),
               class = "hcesfort_error")
  expect_error(missing_values(x$content, x$households, "zinc"),
               class = "hcesfort_error_argument")
  expect_error(missing_values(x$content, x$households, character(0)),
               class = "hcesfort_error_argument")
  expect_error(missing_values(x$content, x$households[1:2, ]),
               class = "hcesfort_error_join")
  expect_error(missing_values(x$content), class = "hcesfort_error_argument")
})

test_that("apparent_intake() logs the used records without a value", {
  l <- audit_log(liver_intake())
  f <- l[l$step == "apparent_intake" & l$cause == "foods_without_value", ]
  expect_identical(f$kind, "flagged")
  expect_identical(f$detail, "vitamin_a_ug_rae: 1 foods")
  expect_identical(f$n_records, 3L)
  expect_identical(f$n_households, 3L)
  expect_equal(f$qty_g, 30)
})

test_that("the coverage notes point to missing_values() below 1 only", {
  i <- liver_intake()
  req <- data.frame(nutrient = c("iron", "vitamin_a"),
                    unit = c("mg", "ug_rae"), ear = c(3, 500),
                    cutpoint_valid = TRUE, ul = c(45, 3000),
                    ul_unit = c("mg", "ug_rae"),
                    ul_applies_to = "total")
  r <- inadequacy(i, req, min_coverage = 0.95, min_records_used = 0.95)
  u <- above_ul(i, req, min_coverage = 0.95, min_records_used = 0.95)
  see <- "; foods without a value: see missing_values()"
  for (l in list(audit_log(r), audit_log(u))) {
    d <- l$detail[l$cause == "coverage" & l$step %in% c("inadequacy",
                                                        "above_ul")]
    expect_identical(d, c("iron: 1.0000 (min_coverage 0.95)",
                          paste0("vitamin_a: 0.9756 (min_coverage 0.95)",
                                 see)))
  }
  err <- expect_error(inadequacy(i, req, min_coverage = 0.99,
                                 min_records_used = 0),
                      class = "hcesfort_error_coverage")
  expect_match(conditionMessage(err), "missing_values()", fixed = TRUE)
})
