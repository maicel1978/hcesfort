# Full chain on hces_example against golden values computed without the
# package (data-raw/golden_example.R, base R and survey only). The choices
# of the chain are listed in that script. Regression net of the review of
# v0.1 (M11) and template of the acceptance test.

golden_chain <- function() {
  ex <- hcesfort::hces_example
  req <- hcesfort::ref_requirements
  n <- nutrient_registry(ex$nutrients)
  g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
  b <- unfortified_baseline(ex$composition, ex$enrichment, n)
  bmr <- hcesfort::ref_bmr_equations
  eq <- bmr[bmr$sex == "female" & bmr$age_from == 18, ]
  afe <- adult_equivalents(
    ex$members,
    reference_kcal = (eq$slope_kcal_kg * 55 + eq$intercept_kcal) * 1.76,
    weight_kg = c(female = 55, male = 65), pal = 1.76
  )
  intake <- apparent_intake(link_composition(g, ex$crosswalk, b), afe,
                            ex$households)
  use <- vehicle_coverage(g, ex$vehicles, afe, ex$households)
  s <- apply_scenario(intake, use, ex$scenarios,
                      compliance_model = "average_content")
  iron <- hcesfort::ref_iron_requirements
  iron <- iron[iron$group == "females_menstruating_adult", ]
  risk <- inadequacy(s, req, distribution = list(iron = iron),
                     bioavailability = list(iron = 0.10), min_coverage = 0.8,
                     min_records_used = 0.8)
  ul <- above_ul(s, req, min_coverage = 0.8,
                 min_records_used = 0.8)
  list(afe = afe, intake = intake, use = use, s = s, risk = risk, ul = ul,
       design = as_hces_design(ex$households, lonely_psu = "adjust"))
}

test_that("the full chain on hces_example reproduces the golden values", {
  gold <- utils::read.csv(testthat::test_path("fixtures",
                                              "golden-example.csv"))
  gold <- stats::setNames(gold$value, gold$name)
  ch <- golden_chain()
  est <- ch$intake[ch$intake$intake_status == "estimated", ]
  s <- ch$s[ch$s$intake_status == "estimated", ]
  fs <- s[s$scenario == "flour_and_sugar", ]
  flour <- ch$use[ch$use$vehicle == "flour" &
                    ch$use$use_status == "estimated", ]
  r <- ch$risk
  pick <- function(e, sc) e[e$scenario == sc, ]
  folate <- r[r$nutrient == "folate", ]
  iron <- r[r$nutrient == "iron", ]
  p_folate <- pick(estimate_prevalence(ch$design, folate, "p_inadequate"),
                   "baseline")
  p_iron <- pick(estimate_prevalence(ch$design, iron, "p_inadequate"),
                 "baseline")
  d_folate <- pick(estimate_difference(ch$design, folate, "p_inadequate",
                                       reference = "baseline"), "flour")
  folic <- ch$ul[ch$ul$nutrient == "folate" &
                   ch$ul$scenario == "flour_and_sugar", ]
  got <- c(
    afe_sum = sum(ch$afe$afe, na.rm = TRUE),
    n_estimated = nrow(est),
    share_records_used = sum(ch$intake$n_records_used) /
      sum(ch$intake$n_records_included),
    mean_energy_kcal = mean(est$energy_kcal),
    mean_iron_mg = mean(est$iron_mg),
    mean_folate_ug_dfe = mean(est$folate_ug_dfe),
    mean_vitamin_a_ug_rae = mean(est$vitamin_a_ug_rae),
    mean_flour_g_d = mean(flour$qty_vehicle_g_d),
    mean_folate_added_flour_and_sugar = mean(fs$folate_ug_dfe_added),
    mean_vitamin_a_flour_and_sugar = mean(fs$vitamin_a_ug_rae),
    n_above_folic_acid_ul = sum(folic$above_ul_added, na.rm = TRUE),
    prev_folate_baseline = p_folate$estimate,
    se_folate_baseline = p_folate$se,
    prev_iron_b010_baseline = p_iron$estimate,
    se_iron_b010_baseline = p_iron$se,
    diff_folate_flour = d_folate$estimate,
    se_diff_folate_flour = d_folate$se
  )
  expect_setequal(names(got), names(gold))
  for (nm in names(gold)) {
    expect_equal(got[[nm]], gold[[nm]], tolerance = 1e-8, label = nm)
  }
})

test_that("the recalibrated example reads like a survey (H6)", {
  ch <- golden_chain()
  est <- ch$intake[ch$intake$intake_status == "estimated", ]
  energy <- stats::median(est$energy_kcal)
  expect_gt(energy, 1800)
  expect_lt(energy, 2600)
  base <- ch$risk[ch$risk$scenario == "baseline" &
                    ch$risk$intake_status == "estimated", ]
  for (n in c("iron", "folate", "vitamin_a")) {
    p <- mean(base$p_inadequate[base$nutrient == n])
    expect_true(p > 0.05 && p < 0.99, label = n)
  }
  above <- ch$ul$above_ul_added %in% TRUE | ch$ul$above_ul_total %in% TRUE
  expect_true(any(above))
  expect_false(all(above[ch$ul$intake_status == "estimated"]))
})

test_that("the logs of the full chain hold no branch twice", {
  # Every input of apply_scenario() derives from the same validated
  # tables; before 11b.8 their rows were repeated once per branch.
  ch <- golden_chain()
  for (x in ch[c("intake", "use", "s", "risk", "ul")]) {
    expect_false(anyDuplicated(audit_log(x)) > 0)
  }
  steps <- audit_log(ch$s)$step
  expect_identical(sum(steps == "validate_acquisitions" &
                         audit_log(ch$s)$kind == "input"), 1L)
})
