# Full chain on the shipped hces_example and on hces_fixture() against
# golden values computed without the package (data-raw/golden_example.R,
# base R and survey only). The choices of the chain are listed in that
# script. Regression net of the review of v0.1 (M11), X2 of the reports v3
# design, and template of the acceptance test.

golden_chain <- function(ex = hces_fixture()) {
  req <- hcesfort::ref_requirements
  n <- nutrient_registry(ex$nutrients)
  g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
  b <- unfortified_baseline(ex$composition, ex$enrichment, n)
  afe <- adult_equivalents(
    ex$members,
    reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
    weight_kg = c(female = 55, male = 65), pal = 1.76,
    meal_share = if (!is.null(ex$members$meals_home_share)) TRUE
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
  content <- link_composition(g, ex$crosswalk, b)
  groups <- food_group_intake(content, ex$food_groups, afe, ex$households)
  design <- as_hces_design(ex$households, lonely_psu = "adjust")
  list(afe = afe, intake = intake, use = use, s = s, risk = risk, ul = ul,
       groups = groups, shares = food_group_shares(design, groups),
       design = design, cols = paste(names(ex$nutrients), ex$nutrients,
                                     sep = "_"))
}

# Prevalence of one nutrient in the baseline: Korn-Graubard estimate judged
# by the presentation standard, as the golden script names its values.
golden_prevalence <- function(ch, nutrient, suffix) {
  r <- ch$risk[ch$risk$nutrient == nutrient, ]
  e <- estimate_households(ch$design, r, "p_inadequate",
                           ci_method = "korn_graubard")
  f <- flag_presentation(e[e$scenario == "baseline", ])
  status <- c(present = 0, review = 1, suppress = 2)
  stats::setNames(
    c(f$estimate, f$se, f$ci_low, f$ci_high, f$n_effective,
      status[[f$presentation]], as.numeric(f$complement_unreliable)),
    paste0(c("prev", "se", "kg_low", "kg_high", "n_effective",
             "presentation", "complement_unreliable"), "_", suffix)
  )
}

# The package's values under the names of the golden script; `cfg` names
# the vehicle and the scenarios `one` and `two` of the dataset.
golden_got <- function(ch, cfg) {
  est <- ch$intake[ch$intake$intake_status == "estimated", ]
  s <- ch$s[ch$s$intake_status == "estimated", ]
  two <- s[s$scenario == cfg$two, ]
  vehicle <- ch$use[ch$use$vehicle == cfg$vehicle &
                      ch$use$level == "vehicle" &
                      ch$use$use_status == "estimated", ]
  folate <- ch$risk[ch$risk$nutrient == "folate", ]
  d_folate <- estimate_difference(ch$design, folate, "p_inadequate",
                                  reference = "baseline")
  d_folate <- d_folate[d_folate$scenario == cfg$one, ]
  folic <- ch$ul[ch$ul$nutrient == "folate" & ch$ul$scenario == cfg$two, ]
  share <- function(col) {
    ch$shares[ch$shares$food_group == "cereals" &
                ch$shares$variable == col, ]
  }
  c(
    afe_sum = sum(ch$afe$afe, na.rm = TRUE),
    n_estimated = nrow(est),
    share_records_used = sum(ch$intake$n_records_used) /
      sum(ch$intake$n_records_included),
    stats::setNames(colMeans(est[ch$cols]), paste0("mean_", ch$cols)),
    mean_vehicle_g_d = mean(vehicle$qty_vehicle_g_d),
    mean_folate_added_two = mean(two$folate_ug_dfe_added),
    mean_vitamin_a_two = mean(two$vitamin_a_ug_rae),
    n_above_folic_acid_ul_two = sum(folic$above_ul_added, na.rm = TRUE),
    golden_prevalence(ch, "folate", "folate_baseline"),
    golden_prevalence(ch, "iron", "iron_b010_baseline"),
    diff_folate_one = d_folate$estimate,
    se_diff_folate_one = d_folate$se,
    share_cereals_folate = share("folate_ug_dfe")$estimate,
    se_share_cereals_folate = share("folate_ug_dfe")$se,
    share_cereals_iron = share("iron_mg")$estimate,
    se_share_cereals_iron = share("iron_mg")$se
  )
}

expect_golden <- function(file, ex, cfg) {
  gold <- utils::read.csv(testthat::test_path("fixtures", file))
  gold <- stats::setNames(gold$value, gold$name)
  got <- golden_got(golden_chain(ex), cfg)
  expect_setequal(names(got), names(gold))
  for (nm in names(gold)) {
    expect_equal(got[[nm]], gold[[nm]], tolerance = 1e-8, label = nm)
  }
}

test_that("the full chain on hces_fixture() reproduces the golden values", {
  expect_golden("golden-fixture.csv", hces_fixture(),
                list(vehicle = "flour", one = "flour",
                     two = "flour_and_sugar"))
})

test_that("the chain reaches the optional columns (P169)", {
  expect_golden("golden-optional.csv", hces_fixture(optional = TRUE),
                list(vehicle = "flour", one = "flour",
                     two = "flour_and_sugar"))
  # The optional columns change the values: the golden files differ.
  read <- function(f) utils::read.csv(testthat::test_path("fixtures", f))
  plain <- read("golden-fixture.csv")
  opt <- read("golden-optional.csv")
  for (nm in c("afe_sum", "mean_iron_mg", "mean_vehicle_g_d",
               "se_folate_baseline")) {
    expect_false(isTRUE(all.equal(plain$value[plain$name == nm],
                                  opt$value[opt$name == nm])), label = nm)
  }
})

test_that("the full chain on hces_example reproduces the golden values", {
  skip_on_cran()
  expect_golden("golden-example.csv", hces_example,
                list(vehicle = "wheat_flour", one = "wheat_flour",
                     two = "plus_oil"))
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
  for (x in ch[c("intake", "use", "s", "risk", "ul", "groups", "shares")]) {
    expect_false(anyDuplicated(audit_log(x)) > 0)
  }
  steps <- audit_log(ch$s)$step
  expect_identical(sum(steps == "validate_acquisitions" &
                         audit_log(ch$s)$kind == "input"), 1L)
})

test_that("E1: the baseline lowers the share of the enriched group", {
  # The shares on the composition as linked (with the enriched pasta) are
  # computed by hand here: food_group_shares() refuses that table.
  ex <- hces_fixture()
  ch <- golden_chain()
  n <- nutrient_registry(ex$nutrients)
  g <- convert_units(ex$acquisitions, ex$unit_factors, priority = "food")
  raw <- link_composition(g, ex$crosswalk, validate_composition(
    ex$composition, n
  ))
  expect_error(food_group_intake(raw, ex$food_groups, ch$afe,
                                 ex$households),
               class = "hcesfort_error_audit")
  est <- ch$intake$household_id[ch$intake$intake_status == "estimated"]
  w <- ex$households$weight[match(est, ex$households$household_id)]
  afe <- ch$afe$afe[match(est, ch$afe$household_id)]
  used <- raw$include & raw$composition_status == "linked"
  cereal <- raw$food_code %in%
    ex$food_groups$food_code[ex$food_groups$food_group == "cereals"]
  by_hh <- function(v, f) {
    vapply(est, function(h) sum(v[f & raw$household_id == h], na.rm = TRUE),
           1)
  }
  for (col in c("folate_ug_dfe", "iron_mg")) {
    linked <- sum(w * by_hh(raw[[col]], used & cereal) / afe) /
      sum(w * by_hh(raw[[col]], used) / afe)
    base <- ch$shares$estimate[ch$shares$food_group == "cereals" &
                                 ch$shares$variable == col]
    expect_lt(base, linked)
  }
})
