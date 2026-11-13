# linkage_ladder(). Fixture and hand counts in helper-linkage.R.

test_that("linkage_ladder() counts each step by hand", {
  l <- linkage_ladder(lk_content(), lk_households())
  expect_identical(l$step, c("records", "with_quantity", "with_grams",
                             "matched", "validated"))
  expect_equal(l$n_records, c(10, 8, 8, 6, 4))
  expect_equal(l$n_households, c(3, 3, 3, 3, 2))
  expect_equal(l$share_records, c(10, 8, 8, 6, 4) / 10)
  # Weighted grams: 200 100 30 20 10 120 180 and 20 (record 11); 680.
  expect_equal(l$share_grams, c(NA, NA, 680, 650, 500) / 680)
  # Weighted expenditure of the included records with one: 152.
  expect_equal(l$share_expenditure, c(152, 131, 131, 126, 96) / 152)
})

test_that("the ladder never goes up", {
  for (x in list(lk_content(), example_content())) {
    h <- if (nrow(x) == 11) lk_households() else hces_example$households
    l <- linkage_ladder(x, h)
    for (col in c("n_records", "n_households", "share_records",
                  "share_grams", "share_expenditure")) {
      v <- l[[col]][!is.na(l[[col]])]
      expect_true(all(diff(v) <= 0), info = col)
    }
  }
})

test_that("equal weights give the unweighted shares", {
  l <- linkage_ladder(lk_content(), lk_households(weight = rep(5, 4)))
  expect_equal(l$share_grams, c(NA, NA, 320, 290, 220) / 320)
  expect_equal(l$share_expenditure, c(68, 61, 61, 56, 42) / 68)
})

test_that("scaling weights or quantities by k changes no share", {
  base <- linkage_ladder(lk_content(), lk_households())
  w <- linkage_ladder(lk_content(), lk_households(weight = c(2, 1, 3, 1) * 7))
  expect_equal(w, base)
  a <- lk_acquisitions()
  a$quantity <- a$quantity * 3
  a$expenditure_lcu <- a$expenditure_lcu * 3
  expect_equal(linkage_ladder(lk_content(a), lk_households()), base)
})

test_that("row order does not matter", {
  a <- lk_acquisitions()[c(11, 3, 1, 9, 5, 7, 2, 10, 4, 8, 6), ]
  expect_equal(linkage_ladder(lk_content(a), lk_households()[4:1, ]),
               linkage_ladder(lk_content(), lk_households()))
})

test_that("without expenditure the expenditure shares are missing", {
  a <- lk_acquisitions()
  a$expenditure_lcu <- NULL
  l <- linkage_ladder(lk_content(a), lk_households())
  expect_true(all(is.na(l$share_expenditure)))
  expect_equal(l$share_grams, c(NA, NA, 680, 650, 500) / 680)
})

test_that("household_share applies to expenditure as to grams", {
  a <- lk_acquisitions()
  a$household_share <- c(0.5, rep(1, 10))
  l <- linkage_ladder(lk_content(a), lk_households())
  # Record 1 counts half: 10 less in every step of expenditure.
  expect_equal(l$share_expenditure, c(142, 121, 121, 116, 86) / 142)
  expect_equal(l$share_grams, c(NA, NA, 580, 550, 400) / 580)
})

test_that("no included record gives missing shares, not an error", {
  a <- lk_acquisitions()
  a$include <- FALSE
  l <- linkage_ladder(lk_content(a), lk_households())
  expect_equal(l$n_records, rep(0L, 5))
  expect_true(all(is.na(l$share_records)))
  expect_true(all(is.na(l$share_grams)))
})

test_that("linkage_ladder() checks its inputs", {
  x <- lk_content()
  expect_error(linkage_ladder(dplyr::as_tibble(x), lk_households()),
               class = "hcesfort_error_audit")
  expect_error(linkage_ladder(x, lk_households()[-3, ]),
               class = "hcesfort_error_join")
  h <- lk_households()
  h$household_id <- as.character(h$household_id)
  expect_error(linkage_ladder(x, h), class = "hcesfort_error_join")
  expect_error(linkage_ladder(x, h[, -2]), class = "hcesfort_error_schema")
  expect_error(linkage_ladder(x), class = "hcesfort_error_argument")
})
