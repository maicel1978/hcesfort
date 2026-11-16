# The energy of infants in adult_equivalents(): `infant_food_share` and
# `milk_energy_cost` (P158; docs/design-12e5.md, section 1). Fixtures:
# afe_members() and afe_fixture() of test-adult-equivalents.R (invented
# tables: infants female 500 kcal in months [0, 6), 700 in [6, 12); male
# 600 and 800; reference 2000 kcal). Household 2 holds a girl of 7 months,
# a boy of unknown month and a man of 2800 kcal. Expected values by hand.

test_that("a share of 1 reproduces the full requirement", {
  out <- afe_fixture(infant_food_share = 1)
  expect_equal(out$afe, c(2.7, 2.1, NA))
  # A cost given with a share of 1 changes nothing, exactly.
  out2 <- afe_fixture(infant_food_share = 1, milk_energy_cost = 1.25)
  expect_identical(out2$energy_kcal_d, out$energy_kcal_d)
})

test_that("with milk_energy_cost = 1 the share does not matter", {
  feeding <- data.frame(age_from = c(0, 6), age_to = c(6, 12),
                        food_share = c(0, 0.4))
  for (s in list(0, 0.3, feeding)) {
    expect_identical(hh2_kcal(infant_food_share = s, milk_energy_cost = 1),
                     4200)
  }
})

test_that("share and cost by hand, by month and for an unknown month", {
  # Share 0 and cost 1.25: girl 700 * 1.25 = 875; boy (600 + 800) / 2 *
  # 1.25 = 875; man 2800. Total 4550.
  expect_equal(hh2_kcal(infant_food_share = 0, milk_energy_cost = 1.25),
               4550)
  # Table: share 0 under 6 months, 1 after; cost 0.5. Girl of 7 months:
  # 700. Boy of unknown month: mean of 600 * 0.5 and 800 * 1 = 550.
  feeding <- data.frame(age_from = c(6, 0), age_to = c(12, 6),
                        food_share = c(1, 0))
  out <- afe_fixture(infant_food_share = feeding, milk_energy_cost = 0.5)
  expect_equal(out$energy_kcal_d[[2]], 700 + 550 + 2800)
  expect_equal(out$afe[[2]], 4050 / 2000)
})

test_that("a woman with a girl of 2 months, shipped tables (design 1.5)", {
  reference <- reference_energy("female", 25, weight_kg = 55, pal = 1.76)
  m <- data.frame(household_id = 1, member_id = 1:2, age_years = c(25, 0),
                  sex = "female", age_months = c(NA, 2))
  out <- adult_equivalents(m, reference_kcal = reference,
                           weight_kg = c(female = 55, male = 65), pal = 1.76,
                           infant_food_share = 0, milk_energy_cost = 1.25)
  # Table 3.2 of FAO/WHO/UNU 2004: girls of 2 months, 550 kcal per day.
  expect_equal(out$energy_kcal_d, reference + 550 * 1.25)
  expect_equal(out$afe, 1 + 687.5 / reference)
})

test_that("anchor: the energy cost of lactation of FAO/WHO/UNU 2004", {
  # Section 7.2: 807 g milk per day x 2.8 kJ/g / 0.80 = 675 kcal per day;
  # 550 g per day from six months, 460 kcal per day. Milk energy 0.67
  # kcal/g (section 7.1.2). An infant whose requirement is all milk (share
  # 0, cost 1 / 0.80) is charged the cost of lactation.
  energy <- afe_energy()
  energy$energy_kcal_d[[1]] <- 807 * 0.67
  m <- data.frame(household_id = 1, member_id = 1, age_years = 0,
                  sex = "female", age_months = 1)
  out <- adult_equivalents(m, 2000, c(female = 50, male = 70), 2,
                           infant_food_share = 0, milk_energy_cost = 1.25,
                           energy = energy, bmr = afe_bmr())
  expect_lt(abs(out$energy_kcal_d - 675), 1)
  # Partial breastfeeding at 7 months: E = 700, milk 550 * 0.67 = 368.5,
  # share 1 - 368.5 / 700; the milk part is charged about 460.
  m$age_months <- 7
  out <- adult_equivalents(m, 2000, c(female = 50, male = 70), 2,
                           infant_food_share = 1 - 368.5 / 700,
                           milk_energy_cost = 1.25, energy = afe_energy(),
                           bmr = afe_bmr())
  expect_lt(abs(out$energy_kcal_d - (700 - 368.5) - 460), 1)
})

test_that("the AFE never decreases when milk_energy_cost increases", {
  kcal <- vapply(c(0, 0.5, 1, 1.25, 2), function(k) {
    hh2_kcal(infant_food_share = 0.3, milk_energy_cost = k)
  }, numeric(1))
  expect_true(all(diff(kcal) > 0))
})

test_that("required arguments: missing where needed is a classed error", {
  err <- expect_error(afe_fixture(infant_food_share = NULL),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "infant_food_share")
  expect_match(conditionMessage(err), "2 infants", fixed = TRUE)
  err <- expect_error(afe_fixture(infant_food_share = 0.5),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "milk_energy_cost")
  # Without infants neither is needed; a value given is ignored.
  adults <- afe_members()[afe_members()$household_id != 2, ]
  a <- afe_fixture(adults, infant_food_share = NULL)
  b <- afe_fixture(adults, infant_food_share = 0.2)
  expect_identical(a$afe, b$afe)
  expect_false("infant_energy" %in% audit_log(a)$cause)
})

test_that("malformed shares and costs are classed errors", {
  bad <- list(
    gap = data.frame(age_from = c(0, 7), age_to = c(6, 12),
                     food_share = 1),
    overlap = data.frame(age_from = c(0, 5), age_to = c(6, 12),
                         food_share = 1),
    outside = data.frame(age_from = 0, age_to = 12, food_share = 1.2),
    beyond = data.frame(age_from = 0, age_to = 13, food_share = 1),
    empty = data.frame(age_from = c(0, 6, 6), age_to = c(6, 6, 12),
                       food_share = 1),
    column = data.frame(age_from = 0, age_to = 12),
    missing = data.frame(age_from = 0, age_to = 12, food_share = NA_real_),
    numbers = c(0.5, 0.5), negative = -0.1, text = "1"
  )
  for (b in bad) {
    err <- expect_error(afe_fixture(infant_food_share = b),
                        class = "hcesfort_error_argument")
    expect_identical(err$arg, "infant_food_share")
  }
  for (k in list(-1, NA_real_, c(1, 2), "1")) {
    err <- expect_error(afe_fixture(infant_food_share = 0,
                                    milk_energy_cost = k),
                        class = "hcesfort_error_argument")
    expect_identical(err$arg, "milk_energy_cost")
  }
})

test_that("the log notes the infant energy and flags uncharged milk", {
  log <- audit_log(afe_fixture(infant_food_share = 1))
  note <- log[log$cause == "infant_energy", ]
  expect_identical(note$kind, "note")
  expect_identical(note$detail, paste0(
    "infant_food_share: 1; milk_energy_cost: not given; ",
    "kcal per day charged 1,400.0 of 1,400.0"
  ))
  expect_false("breast_milk_energy_not_counted" %in% log$cause)
  # Share 0.25, cost 0: girl 700 * 0.25 = 175, boy 700 * 0.25 = 175; 1050
  # kcal of milk left out.
  log <- audit_log(afe_fixture(infant_food_share = 0.25,
                               milk_energy_cost = 0))
  flag <- log[log$cause == "breast_milk_energy_not_counted", ]
  expect_identical(flag$kind, "flagged")
  expect_identical(flag$n_records, 2L)
  expect_identical(flag$n_households, 1L)
  expect_identical(flag$detail,
                   "1,050.0 kcal per day of breast milk not counted")
  expect_match(log$detail[log$cause == "infant_energy"],
               "charged 350.0 of 1,400.0", fixed = TRUE)
})
