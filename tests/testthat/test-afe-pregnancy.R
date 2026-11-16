# Energy of pregnancy and lactation in adult_equivalents(): pregnancy_kcal,
# lactation_kcal and the rule against charging breast milk twice (P57;
# docs/design-12e5.md, section 1.3). Fixtures: helper-afe.R (reference
# 2000 kcal; household 3: a woman of 20 years, 2000 kcal, flagged
# pregnant, and a member without age). Expected values by hand.

test_that("the energy is added to the flagged members, by hand", {
  out <- afe_fixture(afe_mother(pregnant = TRUE), pregnancy_kcal = 360)
  expect_equal(out$energy_kcal_d, 5400 + 360)
  expect_equal(out$afe, 2.7 + 360 / 2000)
  out <- afe_fixture(afe_mother(lactating = TRUE), lactation_kcal = 505)
  expect_equal(out$afe, 2.7 + 505 / 2000)
  # A member flagged both gets both.
  out <- afe_fixture(afe_mother(TRUE, TRUE), pregnancy_kcal = 85,
                     lactation_kcal = 460)
  expect_equal(out$energy_kcal_d, 5400 + 85 + 460)
  # 0 reproduces the previous result exactly; a missing flag adds nothing.
  expect_identical(afe_fixture(afe_mother(TRUE, TRUE))$energy_kcal_d, 5400)
})

test_that("the AFE never decreases when the additions increase", {
  kcal <- vapply(c(0, 85, 285, 475), function(k) {
    afe_fixture(afe_mother(TRUE, TRUE), pregnancy_kcal = k,
                lactation_kcal = k)$afe
  }, numeric(1))
  expect_true(all(diff(kcal) > 0))
})

test_that("required where a member is flagged; malformed is an error", {
  err <- expect_error(afe_fixture(afe_mother(pregnant = TRUE),
                                  pregnancy_kcal = NULL),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "pregnancy_kcal")
  expect_match(conditionMessage(err), "1 member flagged", fixed = TRUE)
  err <- expect_error(afe_fixture(afe_mother(lactating = TRUE),
                                  lactation_kcal = NULL),
                      class = "hcesfort_error_argument")
  expect_identical(err$arg, "lactation_kcal")
  # Not flagged: neither is needed, and a value given is ignored.
  m <- afe_mother()
  expect_identical(
    afe_fixture(m, pregnancy_kcal = NULL, lactation_kcal = NULL)$afe,
    afe_fixture(m, pregnancy_kcal = 300, lactation_kcal = 500)$afe
  )
  for (k in list(-1, NA_real_, c(1, 2), "85", Inf)) {
    err <- expect_error(afe_fixture(pregnancy_kcal = k),
                        class = "hcesfort_error_argument")
    expect_identical(err$arg, "pregnancy_kcal")
  }
})

test_that("breast milk is not charged twice", {
  # Household 2 holds two infants; its first member is flagged lactating.
  m <- afe_members()
  m$lactating <- m$household_id == 2 & m$member_id == 1
  err <- expect_error(
    afe_fixture(m, infant_food_share = 0, milk_energy_cost = 1.25,
                lactation_kcal = 505),
    class = "hcesfort_error_argument"
  )
  expect_identical(err$arg, c("lactation_kcal", "milk_energy_cost"))
  # Charged once: through the infant, or to the mother.
  expect_no_error(afe_fixture(m, infant_food_share = 0,
                              milk_energy_cost = 1.25, lactation_kcal = 0))
  out <- afe_fixture(m, infant_food_share = 0, milk_energy_cost = 0,
                     lactation_kcal = 505)
  # Infants charged nothing; 505 added to the lactating member.
  expect_equal(out$energy_kcal_d[[2]], 2800 + 505)
  log <- audit_log(out)
  expect_false("breast_milk_energy_not_counted" %in% log$cause)
  # Without lactation energy the milk not charged is flagged.
  log <- audit_log(afe_fixture(m, infant_food_share = 0,
                               milk_energy_cost = 0, lactation_kcal = 0))
  expect_true("breast_milk_energy_not_counted" %in% log$cause)
})

test_that("the log notes the energy added and the members without it", {
  log <- audit_log(afe_fixture(afe_mother(TRUE, TRUE), pregnancy_kcal = 360,
                               lactation_kcal = 0))
  mine <- log[log$step == "adult_equivalents", ]
  row <- mine[mine$cause == "pregnancy_energy_added", ]
  expect_identical(row$kind, "note")
  expect_identical(row$n_records, 1L)
  expect_identical(row$detail, "360.0 kcal per day each; 360.0 in total")
  expect_false("lactation_energy_added" %in% mine$cause)
  # The woman is lactating with lactation_kcal = 0.
  expect_identical(
    mine$n_records[mine$cause == "pregnant_or_lactating_no_extra"], 1L
  )
  log <- audit_log(afe_fixture(afe_mother(TRUE, TRUE), pregnancy_kcal = 360,
                               lactation_kcal = 505))
  expect_false("pregnant_or_lactating_no_extra" %in% log$cause)
})

test_that("the shipped additions are those of FAO/WHO/UNU 2004", {
  a <- ref_energy_additions
  expect_equal(a$energy_kcal_d, c(85, 285, 475, 360, 505, 675, 460))
  expect_identical(a$condition, rep(c("pregnancy", "lactation"), c(4, 3)))
  # Section 6.3: 321 MJ (77,000 kcal) over 280 days; the trimesters of
  # 79, 93 and 93 days give about that total.
  expect_lt(abs(sum(c(85, 285, 475) * c(79, 93, 93)) - 77000), 1000)
  # Section 7.2: 807 g x 2.8 kJ/g / 0.80, in kcal (4.184 kJ per kcal).
  expect_lt(abs(807 * 2.8 / 0.80 / 4.184 - 675), 1)
})
