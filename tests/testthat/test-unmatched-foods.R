# unmatched_foods() as the work queue. Fixture and hand counts in
# helper-linkage.R. Included records 10, weighted grams 680, weighted
# expenditure 152; linked 4 records, 500 g, 96.
#
# Not linked, by hand (weights 2, 1, 3): egg 120 g, 24; beans 30 g, 6;
# herb 20 g, 4; salt 10 g (record 5) and no grams (record 9, missing
# unit), 1 + 6 = 7; rice no grams (record 8, missing quantity), 15. The
# rice record 10 is not included and does not count.

test_that("unmatched_foods() lists foods with records not linked", {
  u <- unmatched_foods(lk_content(), lk_households())
  expect_identical(u$food_code, c("egg", "beans", "herb", "salt", "rice"))
  expect_identical(u$match_status, c("missing_edible_portion",
                                     "not_validated", "unmatched_food",
                                     "not_in_crosswalk", "matched"))
  expect_identical(u$reasons, c("missing_edible_portion", "not_validated",
                                "unmatched_food",
                                "missing_unit; not_in_crosswalk",
                                "missing_quantity"))
  expect_identical(u$units_no_grams, c(NA, NA, NA, NA, "g"))
  expect_equal(u$n_records, c(1, 1, 1, 2, 2))
  expect_equal(u$n_not_linked, c(1, 1, 1, 2, 1))
  expect_equal(u$n_no_grams, c(0, 0, 0, 1, 1))
  expect_equal(u$n_households, c(1, 1, 1, 2, 1))
  expect_equal(u$qty_g_d_not_linked, c(120, 30, 20, 10, NA))
  expect_equal(u$expenditure_lcu_d_not_linked, c(24, 6, 4, 7, 15))
  expect_equal(u$share_records, c(1, 1, 1, 2, 1) / 10)
  expect_equal(u$share_grams, c(120, 30, 20, 10, NA) / 680)
  expect_equal(u$share_expenditure, c(24, 6, 4, 7, 15) / 152)
  expect_identical(u$rank, 1:5)
  expect_equal(u$cum_share_records, c(5, 6, 7, 9, 10) / 10)
  expect_equal(u$cum_share_grams, c(620, 650, 670, 680, 680) / 680)
  expect_equal(u$cum_share_expenditure, c(120, 126, 130, 137, 152) / 152)
})

test_that("order ranks by records or by expenditure", {
  u <- unmatched_foods(lk_content(), lk_households(), order = "records")
  expect_identical(u$food_code, c("salt", "egg", "beans", "herb", "rice"))
  u <- unmatched_foods(lk_content(), lk_households(), order = "expenditure")
  expect_identical(u$food_code, c("egg", "rice", "salt", "beans", "herb"))
  expect_equal(u$cum_share_expenditure, c(120, 135, 142, 148, 152) / 152)
})

test_that("cumulative shares rise to 1 from the last step of the ladder", {
  for (case in list(list(lk_content(), lk_households()),
                    list(example_content(), hces_example$households))) {
    u <- unmatched_foods(case[[1]], case[[2]])
    l <- linkage_ladder(case[[1]], case[[2]])
    last <- l[l$step == "validated", ]
    for (m in c("records", "grams", "expenditure")) {
      cum <- u[[paste0("cum_share_", m)]]
      own <- u[[paste0("share_", m)]]
      expect_true(all(diff(cum) >= -1e-12), info = m)
      expect_equal(cum[[length(cum)]], 1, info = m)
      expect_equal(cum[[1]] - ifelse(is.na(own[[1]]), 0, own[[1]]),
                   last[[paste0("share_", m)]], info = m)
    }
  }
})

test_that("the queue agrees with the ladder and the audit log", {
  x <- lk_content()
  u <- unmatched_foods(x, lk_households())
  l <- linkage_ladder(x, lk_households())
  expect_equal(sum(u$n_not_linked) + l$n_records[[5]], l$n_records[[1]])
  log <- audit_log(x)
  linked <- log$n_records[log$step == "link_composition" &
                            log$cause == "linked"]
  # The linked record left out by the section rule (rice, record 10).
  expect_equal(sum(u$n_not_linked) + linked, sum(x$include) + 1)
})

test_that("weights scale the amounts, not the shares or the order", {
  a <- unmatched_foods(lk_content(), lk_households())
  b <- unmatched_foods(lk_content(), lk_households(c(2, 1, 3, 1) * 4))
  expect_equal(b$qty_g_d_not_linked, a$qty_g_d_not_linked * 4)
  same <- setdiff(names(a), c("qty_g_d_not_linked",
                              "expenditure_lcu_d_not_linked"))
  expect_equal(b[same], a[same])
})

test_that("row order does not matter", {
  a <- lk_acquisitions()[c(11, 3, 1, 9, 5, 7, 2, 10, 4, 8, 6), ]
  expect_equal(unmatched_foods(lk_content(a), lk_households()[4:1, ]),
               unmatched_foods(lk_content(), lk_households()))
})

test_that("without expenditure its columns are missing", {
  a <- lk_acquisitions()
  a$expenditure_lcu <- NULL
  u <- unmatched_foods(lk_content(a), lk_households())
  expect_true(all(is.na(u$expenditure_lcu_d_not_linked)))
  expect_true(all(is.na(u$cum_share_expenditure)))
  expect_equal(u$cum_share_grams, c(620, 650, 670, 680, 680) / 680)
  expect_error(unmatched_foods(lk_content(a), lk_households(),
                               order = "expenditure"),
               class = "hcesfort_error_argument")
})

test_that("a fully linked table gives an empty queue", {
  a <- lk_acquisitions()[c(1, 2, 7, 11), ]
  u <- unmatched_foods(lk_content(a), lk_households())
  expect_identical(nrow(u), 0L)
  expect_true(all(c("reasons", "rank", "cum_share_grams") %in% names(u)))
})

test_that("unmatched_foods() checks its inputs", {
  x <- lk_content()
  expect_error(unmatched_foods(dplyr::as_tibble(x), lk_households()),
               class = "hcesfort_error_audit")
  expect_error(unmatched_foods(x, lk_households(), order = "x"),
               class = "hcesfort_error_argument")
  expect_error(unmatched_foods(x, lk_households()[-2, ]),
               class = "hcesfort_error_join")
  expect_error(unmatched_foods(x), class = "hcesfort_error_argument")
})
