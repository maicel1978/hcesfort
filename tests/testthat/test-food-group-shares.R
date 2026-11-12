# food_group_shares() on the six households of helper-food-groups.R.
# Estimated: h1, h2, h3, h5, h6 (h4 has no records). Hand amounts of iron
# per AFE and day: h1 cereals 1, pulses 2.5, unclassified 0.5; h2 cereals
# 1; h3 pulses 2.5; h5 cereals 2 (300 g / 1.5), dairy 0; h6 pulses 4,
# unclassified 0.4. Weights 10, 20, 30, 40, 15, 25.

test_that("estimate and se equal survey::svyratio() to 1e-8", {
  x <- fg_intake6()
  s <- food_group_shares(fg_design(), x)
  expect_s3_class(s, c("hces_estimate", "hces_tbl"))
  for (g in c("cereals", "pulses", "unclassified")) {
    for (col in c("iron_mg", "folate_ug_dfe", "energy_kcal")) {
      r <- direct_share(x, g, col)
      row <- s[s$food_group == g & s$variable == col, ]
      expect_equal(row$estimate, unname(coef(r)), tolerance = 1e-8)
      expect_equal(row$se, unname(survey::SE(r))[[1]], tolerance = 1e-8)
      expect_identical(row$n, 5L)
      expect_identical(row$n_missing, 1L)
    }
  }
})

test_that("the hand value of the iron share of cereals", {
  s <- food_group_shares(fg_design(), fg_intake6())
  # Cereals: 10 x 1 + 20 x 1 + 15 x 2 = 60; total: 10 x 4 + 20 x 1 +
  # 30 x 2.5 + 15 x 2 + 25 x 4.4 = 275.
  row <- s[s$food_group == "cereals" & s$variable == "iron_mg", ]
  expect_equal(row$estimate, 60 / 275)
})

test_that("the interval follows the logit delta formula", {
  s <- food_group_shares(fg_design(), fg_intake6(), level = 0.9)
  row <- s[s$food_group == "pulses" & s$variable == "iron_mg", ]
  t <- qt(0.95, row$df)
  half <- t * row$se / (row$estimate * (1 - row$estimate))
  expect_equal(row$ci_low, plogis(qlogis(row$estimate) - half))
  expect_equal(row$ci_high, plogis(qlogis(row$estimate) + half))
  expect_equal(row$df, 3) # 5 PSU of the domain - 2 strata
  expect_true(all(s$ci_low >= 0 & s$ci_high <= 1, na.rm = TRUE))
  d <- food_group_shares(fg_design(), fg_intake6(), df = "design")
  expect_true(all(d$df == 4))
  n <- food_group_shares(fg_design(), fg_intake6(), df = Inf)
  row <- n[n$food_group == "pulses" & n$variable == "iron_mg", ]
  half <- qnorm(0.975) * row$se / (row$estimate * (1 - row$estimate))
  expect_equal(row$ci_high, plogis(qlogis(row$estimate) + half))
})

test_that("shares sum to 1 over the groups, in every domain", {
  s <- food_group_shares(fg_design(), fg_intake6(), by = "region")
  sums <- as.vector(tapply(s$estimate, paste(s$region, s$variable), sum))
  expect_equal(sums, rep(1, length(sums)), tolerance = 1e-8)
  expect_identical(names(s)[1:2], c("region", "food_group"))
  r <- direct_share(fg_intake6(), "cereals", "iron_mg",
                    fg_households6()$region == "a")
  row <- s[s$region == "a" & s$food_group == "cereals" &
             s$variable == "iron_mg", ]
  expect_equal(row$estimate, unname(coef(r)), tolerance = 1e-8)
  expect_equal(row$se, unname(survey::SE(r))[[1]], tolerance = 1e-8)
})

test_that("scaling quantities leaves the shares unchanged", {
  a <- food_group_shares(fg_design(), fg_intake6())
  b <- food_group_shares(fg_design(), fg_intake6(scale = 7))
  expect_equal(b$estimate, a$estimate, tolerance = 1e-8)
  expect_equal(b$se, a$se, tolerance = 1e-8)
})

test_that("merging two groups gives the sum of their shares", {
  g <- fg_food_groups()
  g$food_group[g$food_group == "dairy"] <- "pulses"
  a <- food_group_shares(fg_design(), fg_intake6())
  m <- food_group_shares(fg_design(), fg_intake6(groups = g))
  for (col in c("iron_mg", "folate_ug_dfe", "energy_kcal")) {
    pick <- function(s, grp) {
      s$estimate[s$food_group == grp & s$variable == col]
    }
    expect_equal(pick(m, "pulses"), pick(a, "pulses") + pick(a, "dairy"),
                 tolerance = 1e-8)
  }
})

test_that("row order of the inputs does not change the shares", {
  a <- food_group_shares(fg_design(), fg_intake6())
  b <- food_group_shares(fg_design(fg_households6()[6:1, ]),
                         fg_intake6(order = 11:1))
  key <- function(s) s[order(s$variable, s$food_group), ]
  expect_equal(key(b)$estimate, key(a)$estimate, tolerance = 1e-8)
  expect_equal(key(b)$se, key(a)$se, tolerance = 1e-8)
})

test_that("degenerate shares and zero totals", {
  s <- food_group_shares(fg_design(), fg_intake6())
  # Dairy brings no iron: exactly 0, se 0, no interval.
  row <- s[s$food_group == "dairy" & s$variable == "iron_mg", ]
  expect_identical(c(row$estimate, row$se), c(0, 0))
  expect_true(is.na(row$ci_low) && is.na(row$ci_high))
  # Domain region "b" restricted to h2, h4, h6 is fine; a domain where only
  # cereals bring the nutrient gives a share of 1.
  h <- fg_households6()
  h$region <- c("a", "b", "c", "c", "b", "c")
  s <- food_group_shares(fg_design(h), fg_intake6(), by = "region")
  row <- s[s$region == "b" & s$food_group == "cereals" &
             s$variable == "iron_mg", ]
  expect_identical(c(row$estimate, row$se), c(1, 0))
  log <- audit_log(s)
  expect_true("degenerate_share" %in% log$cause)
  # Folate in region "c": h3 beans (no value) and h6 egg -> not zero; a
  # domain with only h3 has a zero folate total.
  h$region <- c("a", "a", "c", "a", "a", "a")
  s <- food_group_shares(fg_design(h), fg_intake6(), by = "region")
  z <- s[s$region == "c" & s$variable == "folate_ug_dfe", ]
  expect_true(all(is.na(z$estimate)))
  expect_true(all(z$n == 1L))
  log <- audit_log(s)
  expect_identical(log$detail[log$cause == "zero_total"], "folate_ug_dfe")
})

test_that("the log records the choices; flag_precision() passes", {
  s <- food_group_shares(fg_design(), fg_intake6())
  log <- audit_log(s)
  log <- log[log$step == "food_group_shares", ]
  expect_identical(log$detail[log$cause == "ci_method"], "logit_delta")
  expect_identical(log$detail[log$cause == "lonely_psu"], "fail")
  expect_true("food_group_intake" %in% audit_log(s)$step)
  p <- flag_precision(s, min_n = 3, max_half_width = 0.1)
  expect_true("low_precision" %in% names(p))
})

test_that("an empty domain gives missing shares", {
  h <- fg_households6()
  h$region <- c("a", "a", "a", "z", "a", "a") # z: only h4, not estimated
  s <- food_group_shares(fg_design(h), fg_intake6(), by = "region")
  z <- s[s$region == "z", ]
  expect_true(all(z$n == 0L & is.na(z$estimate)))
  expect_true("empty_domain" %in% audit_log(s)$cause)
})

test_that("arguments are checked", {
  x <- fg_intake6()
  expect_error(food_group_shares(fg_design()),
               class = "hcesfort_error_argument")
  expect_error(food_group_shares(fg_households6(), x),
               class = "hcesfort_error_argument")
  expect_error(food_group_shares(fg_design(), as.data.frame(x)),
               class = "hcesfort_error_audit")
  expect_error(food_group_shares(fg_design(), x, by = "food_group"),
               class = "hcesfort_error_argument")
  expect_error(food_group_shares(fg_design(), x, level = 2),
               class = "hcesfort_error_argument")
  expect_error(food_group_shares(fg_design(), x, df = "x"),
               class = "hcesfort_error_argument")
  expect_error(food_group_shares(fg_design(fg_households6()[1:5, ]), x),
               class = "hcesfort_error_join")
})
