# food_group_intake() on the fixture of helper-food-groups.R. Hand values,
# per AFE and day:
# h1 (AFE 2): cereals rice 200 g -> 100 g, iron 1, folate 10; pulses beans
#   100 g -> 50 g, iron 2.5, folate not counted (no value) = 0;
#   unclassified egg 50 g -> 25 g, iron 0.5, folate 12.5; dairy 0.
# h2 (AFE 1): cereals iron 1, folate 10; dairy milk 400 g, iron 0,
#   folate 20.
# h3 (AFE 1): pulses 50 g, iron 2.5; the rice record is not included.
# h4: no record; status no_food_records, amounts missing.

test_that("amounts by household and group match the hand values", {
  x <- fg_intake()
  expect_s3_class(x, c("hces_group_intake", "hces_tbl"))
  expect_identical(attr(x, "audit_key"), c("household_id", "food_group"))
  expect_identical(nrow(x), 16L)
  expect_identical(unique(x$food_group),
                   c("cereals", "pulses", "dairy", "unclassified"))
  expect_identical(unique(x$household_id), 1:4)
  expect_equal(fg_val(x, 1, "cereals", "iron_mg"), 1)
  expect_equal(fg_val(x, 1, "pulses", "iron_mg"), 2.5)
  expect_equal(fg_val(x, 1, "pulses", "folate_ug_dfe"), 0)
  expect_equal(fg_val(x, 1, "unclassified", "folate_ug_dfe"), 12.5)
  expect_equal(fg_val(x, 1, "unclassified", "qty_edible_g_d"), 25)
  expect_equal(fg_val(x, 2, "dairy", "folate_ug_dfe"), 20)
  expect_equal(fg_val(x, 2, "dairy", "iron_mg"), 0)
  expect_equal(fg_val(x, 3, "pulses", "qty_edible_g_d"), 50)
  expect_equal(fg_val(x, 3, "cereals", "iron_mg"), 0)
  expect_identical(fg_val(x, 1, "dairy", "acquired"), FALSE)
  expect_identical(fg_val(x, 2, "dairy", "acquired"), TRUE)
  expect_identical(fg_val(x, 3, "cereals", "n_records_used"), 0L)
})

test_that("a household not estimated has missing amounts", {
  x <- fg_intake()
  h4 <- x[x$household_id == 4, ]
  expect_true(all(h4$intake_status == "no_food_records"))
  expect_true(all(is.na(h4$iron_mg)))
  expect_true(all(is.na(h4$acquired)))
})

test_that("the log counts exclusions, unclassified and missing values", {
  log <- audit_log(fg_intake())
  log <- log[log$step == "food_group_intake", ]
  row <- function(cause) log[log$cause == cause, ]
  expect_identical(log$cause, c("all", "not_included", "used",
                                "unclassified", "group_not_in_content",
                                "no_nutrient_value"))
  expect_identical(row("not_included")$qty_g, 999)
  expect_identical(row("unclassified")$detail, "egg")
  expect_identical(row("unclassified")$qty_g, 50)
  expect_identical(row("group_not_in_content")$detail, "bread")
  nv <- row("no_nutrient_value")
  expect_identical(nv$detail, "pulses: folate_ug_dfe")
  expect_identical(c(nv$n_records, nv$n_households), c(2L, 2L))
  expect_identical(nv$qty_g, 150)
})

test_that("the sum over groups equals apparent_intake()", {
  content <- fg_content()
  x <- food_group_intake(content, fg_food_groups(), fg_afe(),
                         fg_households())
  ai <- apparent_intake(content, fg_afe(), fg_households())
  for (col in c("qty_edible_g_d", "energy_kcal", "iron_mg",
                "folate_ug_dfe")) {
    s <- as.vector(tapply(x[[col]], x$household_id, sum))
    expect_equal(s, ai[[col]], tolerance = 1e-8)
  }
  expect_identical(unique(x$intake_status), unique(ai$intake_status))
})

test_that("scaling quantities scales amounts; row order does not matter", {
  a <- fg_intake()
  b <- fg_intake(scale = 3)
  expect_equal(b$iron_mg, 3 * a$iron_mg)
  c <- fg_intake(order = c(7, 3, 5, 1, 6, 2, 4))
  expect_equal(as.data.frame(c), as.data.frame(a))
  g <- fg_food_groups()[c(3, 1, 4, 2), ]
  d <- food_group_intake(fg_content(), g, fg_afe(), fg_households())
  expect_setequal(unique(d$food_group), unique(a$food_group))
  key <- function(t) t[order(t$household_id, t$food_group), ]
  expect_equal(as.data.frame(key(d))$iron_mg, as.data.frame(key(a))$iron_mg)
})

test_that("content without the baseline step is refused (E1)", {
  content <- fg_content(baseline = FALSE)
  err <- expect_error(
    food_group_intake(content, fg_food_groups(), fg_afe(), fg_households()),
    class = "hcesfort_error_audit"
  )
  expect_match(conditionMessage(err), "content")
  expect_identical(err$arg, "content")
})

test_that("the outlier decision is required and applied", {
  content <- fg_content()
  content$outlier <- content$record_id == 1
  expect_error(
    food_group_intake(content, fg_food_groups(), fg_afe(), fg_households()),
    class = "hcesfort_error_argument"
  )
  x <- food_group_intake(content, fg_food_groups(), fg_afe(),
                         fg_households(), outliers = "exclude")
  expect_equal(fg_val(x, 1, "cereals", "iron_mg"), 0)
  expect_identical(fg_val(x, 1, "cereals", "acquired"), FALSE)
  expect_match(attr(x, "outlier_decision"), "^exclude")
  log <- audit_log(x)
  expect_identical(
    log$n_records[log$step == "food_group_intake" &
                    log$cause == "outlier_excluded"], 1L
  )
  k <- food_group_intake(content, fg_food_groups(), fg_afe(),
                         fg_households(), outliers = "keep")
  expect_equal(fg_val(k, 1, "cereals", "iron_mg"), 1)
})

test_that("every food grouped: no unclassified group", {
  g <- rbind(fg_food_groups(),
             data.frame(food_code = "egg", food_group = "eggs",
                        source = "test fixture"))
  x <- food_group_intake(fg_content(), g, fg_afe(), fg_households())
  expect_false("unclassified" %in% x$food_group)
  log <- audit_log(x)
  expect_false("unclassified" %in% log$cause[log$step == "food_group_intake"])
})

test_that("inputs are checked", {
  content <- fg_content()
  g <- fg_food_groups()
  expect_error(food_group_intake(content, g, fg_afe()),
               class = "hcesfort_error_argument")
  expect_error(food_group_intake(as.data.frame(content), g, fg_afe(),
                                 fg_households()),
               class = "hcesfort_error_audit")
  g$food_group[1] <- "unclassified"
  expect_error(food_group_intake(content, g, fg_afe(), fg_households()),
               class = "hcesfort_error_value")
  g <- fg_food_groups()
  g$food_code <- 1:4
  expect_error(food_group_intake(content, g, fg_afe(), fg_households()),
               class = "hcesfort_error_join")
  h <- fg_households()[1:3, ]
  expect_error(food_group_intake(content, fg_food_groups(), fg_afe(), h),
               class = "hcesfort_error_join")
})
