# estimate_unlinked(). Fixtures in helper-linkage.R: the work-queue
# fixture (hand counts there) and ul_case(), eight households with a linked
# and an unlinked food, one PSU each, for the reference functions of survey.

test_that("the share and its se are those of survey::svyratio()", {
  case <- ul_case(c(50, 2, 40, 3, 60, 1, 45, 4))
  des <- reference_design(case)
  est <- estimate_unlinked(case$design, case$content, by = "region")
  for (r in c("north", "south")) {
    ref <- survey::svyratio(~num, ~den, subset(des, region == r))
    row <- est[est$region == r, ]
    expect_equal(row$estimate, unname(coef(ref)), tolerance = 1e-8)
    expect_equal(row$se, unname(survey::SE(ref))[[1]], tolerance = 1e-8)
  }
  nat <- estimate_unlinked(case$design, case$content)
  ref <- survey::svyratio(~num, ~den, des)
  expect_equal(nat$estimate, unname(coef(ref)), tolerance = 1e-8)
  expect_equal(nat$se, unname(survey::SE(ref))[[1]], tolerance = 1e-8)
})

test_that("the difference is that of survey::svycontrast()", {
  case <- ul_case(c(50, 2, 40, 3, 60, 1, 45, 4))
  des <- reference_design(case)
  tot <- survey::svytotal(~n1 + d1 + n0 + d0, des)
  con <- survey::svycontrast(tot, quote(n1 / d1 - n0 / d0))
  t <- qt(0.975, survey::degf(des))
  ref <- unname(coef(con)) + c(0, -1, 1) * t * unname(survey::SE(con))[[1]]
  row <- estimate_unlinked(case$design, case$content, by = "region")[1, ]
  expect_identical(row$region, "north")
  expect_equal(c(row$difference, row$difference_ci_low,
                 row$difference_ci_high), ref, tolerance = 1e-8)
  rest <- survey::svyratio(~num, ~den, subset(des, region == "south"))
  expect_equal(row$rest_estimate, unname(coef(rest)), tolerance = 1e-8)
})

test_that("differs flags a domain built to differ, not one built not to", {
  far <- estimate_unlinked(ul_case(c(50, 2, 40, 3, 60, 1, 45, 4))$design,
                           ul_case(c(50, 2, 40, 3, 60, 1, 45, 4))$content,
                           by = "region")
  expect_identical(far$differs, c(TRUE, TRUE))
  near_case <- ul_case(c(5, 6, 4, 3, 6, 5, 4, 5))
  near <- estimate_unlinked(near_case$design, near_case$content,
                            by = "region")
  expect_identical(near$differs, c(FALSE, FALSE))
  expect_equal(near$difference[[1]], -near$difference[[2]])
})

test_that("the national row has no comparison", {
  case <- ul_case(c(50, 2, 40, 3, 60, 1, 45, 4))
  nat <- estimate_unlinked(case$design, case$content)
  expect_identical(nrow(nat), 1L)
  expect_true(all(is.na(unlist(nat[c("rest_estimate", "difference",
                                     "difference_ci_low",
                                     "difference_ci_high", "differs")]))))
})

test_that("nationally, 1 - estimate is the last step of the ladder", {
  for (case in list(list(lk_content(), lk_households()),
                    list(example_content(), hces_example$households))) {
    design <- as_hces_design(case[[2]], lonely_psu = "adjust")
    l <- linkage_ladder(case[[1]], case[[2]])
    for (m in c("grams", "expenditure")) {
      e <- estimate_unlinked(design, case[[1]], measure = m)
      expect_equal(1 - e$estimate, l[[paste0("share_", m)]][[5]],
                   info = m)
    }
  }
})

test_that("by records, the share is of weighted records, by hand", {
  design <- as_hces_design(lk_households(), lonely_psu = "adjust")
  e <- estimate_unlinked(design, lk_content(), measure = "records")
  # Included records weighted: 3 x 2 + 3 x 1 + 4 x 3 = 21; not linked:
  # 0 + 3 x 1 + 3 x 3 = 12.
  expect_equal(e$estimate, 12 / 21)
  expect_identical(e$variable, "unlinked_records")
  expect_identical(e$n, 4L)
})

test_that("a share of 0 or 1 is exact, without interval", {
  case <- ul_case(rep(0, 8))
  e <- estimate_unlinked(case$design, case$content, by = "region")
  expect_equal(e$estimate, c(0, 0))
  expect_equal(e$se, c(0, 0))
  expect_true(all(is.na(e$ci_low)))
  expect_identical(e$differs, c(FALSE, FALSE))
  case <- ul_case(rep(10, 8), rice_g = rep(0, 8))
  e <- estimate_unlinked(case$design, case$content)
  expect_equal(c(e$estimate, e$se), c(1, 0))
})

test_that("results do not depend on row order or the scale of weights", {
  case <- ul_case(c(50, 2, 40, 3, 60, 1, 45, 4))
  base <- estimate_unlinked(case$design, case$content, by = "region")
  h <- case$households
  h$weight <- h$weight * 3
  d3 <- as_hces_design(h[8:1, ], lonely_psu = "fail")
  out <- estimate_unlinked(d3, case$content, by = "region")
  cols <- c("estimate", "se", "difference", "difference_ci_low", "differs")
  expect_equal(out[cols], base[cols], tolerance = 1e-10)
})

test_that("flag_precision() applies and the log counts the flags", {
  case <- ul_case(c(50, 2, 40, 3, 60, 1, 45, 4))
  e <- estimate_unlinked(case$design, case$content, by = "region")
  f <- flag_precision(e, min_n = 4, max_half_width = 1)
  expect_identical(f$low_precision, c(FALSE, FALSE))
  log <- audit_log(e)
  expect_identical(
    log$n_records[log$cause == "differs_from_rest"], 2L
  )
})

test_that("estimate_unlinked() checks its inputs", {
  design <- as_hces_design(lk_households(), lonely_psu = "adjust")
  x <- lk_content()
  expect_error(estimate_unlinked(design, dplyr::as_tibble(x)),
               class = "hcesfort_error_audit")
  expect_error(estimate_unlinked(lk_households(), x),
               class = "hcesfort_error_argument")
  expect_error(estimate_unlinked(design, x, measure = "kcal"),
               class = "hcesfort_error_argument")
  expect_error(estimate_unlinked(design, x, by = "nope"),
               class = "hcesfort_error_argument")
  a <- lk_acquisitions()
  a$expenditure_lcu <- NULL
  expect_error(estimate_unlinked(design, lk_content(a), measure =
                                   "expenditure"),
               class = "hcesfort_error_argument")
  small <- as_hces_design(lk_households()[1:2, ], lonely_psu = "adjust")
  expect_error(estimate_unlinked(small, x), class = "hcesfort_error_join")
})
