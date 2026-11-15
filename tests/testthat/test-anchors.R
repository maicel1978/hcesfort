# Anchors outside the package (review v0.2, finding 6, section 5.3; P160).
# Each expected value comes from a published table or a reference
# implementation, not from arithmetic written for the package. Published
# values are typed from the page opened on 2026-11-15; the page is named in
# each test.

# FAO/WHO/UNU 2004, Human energy requirements, the three examples under
# Table 5.1 (fao.org/4/y5686e/y5686e07.htm): TEE = PAL x BMR of a
# population with a mean weight. The report rounds the BMR to 0.1 MJ before
# multiplying, so the equations of Table 5.2 agree within 1%, not exactly.
test_that("reference_energy() agrees with the FAO 2004 worked examples", {
  examples <- data.frame(
    sex = c("female", "female", "male"), age_years = c(40, 22, 22),
    weight_kg = c(55, 57, 70), pal = c(1.53, 1.76, 2.25),
    tee_kcal = c(1975, 2355, 3925)
  )
  for (i in seq_len(nrow(examples))) {
    e <- examples[i, ]
    got <- reference_energy(e$sex, e$age_years, e$weight_kg, pal = e$pal)
    expect_lt(abs(got / e$tee_kcal - 1), 0.01)
  }
})

# IOM 2001, Dietary Reference Intakes ... Iron ..., Appendix Table I-7,
# p. 703, menstruating women not using oral contraceptives: probability of
# inadequacy for each range of usual intake (mg/d), 18% bioavailability.
# The table is a step function of 12 bands plus the two tails (footnote d);
# the package interpolates the percentiles of Table I-4 linearly, so at the
# middle of each band it agrees within 0.01, and below 4.42 mg it gives 1
# and above 18.23 mg 0.
iom_table_i7 <- function() {
  data.frame(
    from = c(4.42, 4.89, 5.46, 6.23, 6.88, 7.47, 8.08, 8.77, 9.64, 10.83,
             13.06, 15.50),
    to = c(4.88, 5.45, 6.22, 6.87, 7.46, 8.07, 8.76, 9.63, 10.82, 13.05,
           15.49, 18.23),
    p = c(0.96, 0.93, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.25, 0.15, 0.08,
          0.04)
  )
}

test_that("the iron probability agrees with IOM 2001 Table I-7", {
  d <- subset(ref_iron_requirements, group == "females_menstruating_adult")
  t <- distribution_table(d, "iron", "mg", NULL)
  bands <- iom_table_i7()
  mid <- (bands$from + bands$to) / 2
  got <- p_inadequate_probability(mid, 0.18, t)
  expect_lt(max(abs(got - bands$p)), 0.01)
  expect_identical(p_inadequate_probability(c(1, 4.41), 0.18, t), c(1, 1))
  expect_identical(p_inadequate_probability(c(18.24, 40), 0.18, t), c(0, 0))
})

# Conservation: the sum over the estimated households of AFE x intake per
# AFE equals the sum of the nutrient over the included records of those
# households that have a value (records not used have no value).
test_that("apparent intake conserves the nutrients of the records", {
  e <- hces_example
  g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
  afe <- adult_equivalents(
    e$members, reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
    weight_kg = c(female = 55, male = 65), pal = 1.76
  )
  b <- unfortified_baseline(e$composition, e$enrichment,
                            nutrient_registry(e$nutrients))
  content <- link_composition(g, e$crosswalk, b)
  intake <- apparent_intake(content, afe, e$households)
  est <- intake[intake$intake_status == "estimated", ]
  r <- content[content$household_id %in% est$household_id &
                 content$include, ]
  for (col in c("energy_kcal", "iron_mg", "folate_ug_dfe")) {
    has <- !is.na(r[[col]])
    expect_equal(sum(est$afe * est[[col]]), sum(r[[col]][has]),
                 tolerance = 1e-10)
  }
})

# The paired difference against survey::svycontrast() of the two means on
# the domain of the households with both values (helper-estimate.R).
test_that("estimate_difference() agrees with svycontrast()", {
  x <- es_result()
  h <- es_households()
  h$base <- x$p[x$scenario == "base"]
  h$fort <- x$p[x$scenario == "fort"]
  d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         nest = TRUE, data = h)
  sub <- d[!is.na(h$base) & !is.na(h$fort), ]
  ref <- survey::svycontrast(survey::svymean(~ base + fort, sub),
                             c(base = -1, fort = 1))
  e <- estimate_difference(es_design(), x, "p", reference = "base")
  expect_equal(e$estimate, as.vector(stats::coef(ref)), tolerance = 1e-8)
  expect_equal(e$se, as.vector(survey::SE(ref)), tolerance = 1e-8)
})

# A domain mean is a ratio of totals on the full design, with no
# subsetting: survey::svyratio() of y x domain over the domain indicator.
test_that("a domain mean agrees with svyratio() on the full design", {
  x <- es_result()
  h <- es_households()
  y <- x$intake[x$scenario == "base"]
  e <- estimate_households(es_design(), x, "intake", by = "region",
                           statistic = "mean")
  e <- e[e$scenario == "base", ]
  for (reg in c("a", "b")) {
    h$den <- as.numeric(h$region == reg & !is.na(y))
    h$num <- ifelse(h$den == 1, y, 0)
    d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                           nest = TRUE, data = h)
    r <- survey::svyratio(~num, ~den, d)
    expect_equal(e$estimate[e$region == reg], as.vector(stats::coef(r)),
                 tolerance = 1e-8)
    expect_equal(e$se[e$region == reg], as.vector(survey::SE(r)),
                 tolerance = 1e-8)
  }
})

# The internal logit interval of the shares against
# survey::svyciprop(method = "logit") on a 0/1 value.
test_that("logit_interval() agrees with svyciprop(method = 'logit')", {
  h <- es_households()
  h$y <- c(1, 0, 1, 1, 0, 0, 1, 0)
  d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         nest = TRUE, data = h)
  m <- survey::svymean(~y, d)
  df <- survey::degf(d)
  ref <- survey::svyciprop(~y, d, method = "logit", df = df)
  got <- logit_interval(unname(stats::coef(m)), unname(survey::SE(m))[[1]],
                        0.95, df)
  expect_equal(got, unname(attr(ref, "ci")), tolerance = 1e-8)
})
