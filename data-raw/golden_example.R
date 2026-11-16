# Golden values of the full chain (review of v0.1, M11; X2 of
# docs/design-reports-v3.md, section 7.2).
#
# Computed here WITHOUT any function of hcesfort: base R and `survey` only,
# from the documented rules of each step, so that a shared misreading of a
# rule by the package and its tests cannot hide. Two datasets: the shipped
# realistic example `hces_example`, the test fixture `hces_fixture`
# (the 40 households that were `hces_example` until 2026-11-14) and the
# same fixture with the optional columns and a single-PSU stratum
# (`hces_optional`, P169), with the shipped reference tables (read as
# data). The values are written to tests/testthat/fixtures/
# golden-example.csv, golden-fixture.csv and golden-optional.csv and
# compared at 1e-8 by tests/testthat/test-golden-example.R, which runs the
# chain with the package.
#
# Choices of the chain: reference woman 18-30 years, 55 kg, PAL 1.76; men
# 65 kg; infants by the mean of their months; a member without age or sex
# leaves the household without AFE; unit factors by food first; no outlier
# rule; average-content compliance on the fortifiable grams (a record
# whose `fortifiable` is FALSE gets nothing; a missing value counts as
# fortifiable; all records when the column is absent); iron by the
# probability approach for
# menstruating adult women; food-group shares with the grouping of each
# dataset. Each dataset names a vehicle and two scenarios: `one` (compared
# with the baseline) and `two` (added folate and vitamin A, folic acid
# above the upper level).
#
# The prevalences also get the 95% Korn-Graubard interval and their status
# under the NCHS data presentation standards for proportions (Parker et al.
# 2017), both written from section 3.1 of docs/design-reports-v3.md.
#
# Run from the package root: Rscript data-raw/golden_example.R

for (f in c("ref_energy_requirements", "ref_bmr_equations", "ref_conversions",
            "ref_iron_requirements", "ref_requirements",
            "ref_presentation_standard", "hces_example")) {
  load(file.path("data", paste0(f, ".rda")))
}
hces_fixture <- readRDS("tests/testthat/fixtures/hces-fixture.rds")
hces_optional <- readRDS("tests/testthat/fixtures/hces-fixture-optional.rds")

# 95% Korn-Graubard interval of a proportion on a domain design (section
# 3.2, C2) and its presentation status (section 3.1). n is the number of
# households of the domain; the interval uses the effective sample size
# p(1 - p) / var (n when the variance is 0) times
# (qt(0.025, n - 1) / qt(0.025, df))^2, capped at n; the status uses n over
# the design effect, capped at n. Status: 0 present, 1
# review, 2 suppress; complement 1 when one minus the proportion fails the
# relative-width criterion.
korn_graubard <- function(sub, formula) {
  std <- stats::setNames(ref_presentation_standard$value,
                         ref_presentation_standard$criterion)
  m <- survey::svymean(formula, sub)
  p <- unname(stats::coef(m))
  v <- unname(survey::SE(m))^2
  n <- nrow(sub)
  df <- survey::degf(sub)
  alpha <- 1 - std[["conf_level"]]
  n_raw <- if (v == 0) n else p * (1 - p) / v
  n_e <- min(n_raw * (stats::qt(alpha / 2, n - 1) /
                        stats::qt(alpha / 2, df))^2, n)
  # The status uses n over the design effect: the weighted variance of
  # the values (divisor the sum of the weights) over v, which is
  # p (1 - p) / v for a 0/1 outcome (P164).
  w <- stats::weights(sub)
  y <- sub$variables[[all.vars(formula)]][w > 0]
  w <- w[w > 0]
  s2 <- sum(w * (y - sum(w * y) / sum(w))^2) / sum(w)
  n_raw <- min(if (v == 0) n else s2 / v, n)
  x <- n_e * p
  lower <- if (x == 0) 0 else stats::qbeta(alpha / 2, x, n_e - x + 1)
  upper <- if (x == n_e) 1 else stats::qbeta(1 - alpha / 2, x + 1, n_e - x)
  width <- upper - lower
  wide <- width > std[["small_absolute_width"]]
  status <- if (n < std[["min_n"]] || n_raw < std[["min_n_effective"]] ||
                  width >= std[["large_absolute_width"]] ||
                  (wide && width / p > std[["max_relative_width"]])) {
    2
  } else if (p %in% c(0, 1) || df < std[["min_df"]]) {
    1
  } else {
    0
  }
  c(kg_low = lower, kg_high = upper, n_effective = n_raw,
    presentation = status,
    complement_unreliable = as.numeric(
      wide && width / (1 - p) > std[["max_relative_width"]]
    ))
}

golden_values <- function(ex, cfg) {
  hh <- ex$households
  # 1. Adult female equivalents.
  bmr <- function(sex, age, weight) {
    e <- ref_bmr_equations[ref_bmr_equations$sex == sex &
                             age >= ref_bmr_equations$age_from &
                             age < ref_bmr_equations$age_to, ]
    e$slope_kcal_kg * weight + e$intercept_kcal
  }
  reference_kcal <- bmr("female", 25, 55) * 1.76
  er <- ref_energy_requirements
  # Optional columns: an infant with `age_months` in [0, 12) takes the row
  # of its month; an adult with `weight_kg` takes its own weight; the AFE
  # is multiplied by `meals_home_share` (a missing share: missing AFE).
  member_kcal <- function(sex, age, months, weight) {
    if (is.na(sex) || is.na(age)) return(NA_real_)
    mo <- er[er$age_unit == "month" & er$sex == sex & er$age_to <= 12, ]
    if (age < 1 && !is.na(months) && months < 12) {
      return(mo$energy_kcal_d[months >= mo$age_from & months < mo$age_to])
    }
    if (age < 1) return(mean(mo$energy_kcal_d))
    yr <- er[er$age_unit == "year" & er$sex == sex, ]
    if (age < max(yr$age_to)) {
      return(yr$energy_kcal_d[age >= yr$age_from & age < yr$age_to])
    }
    if (is.na(weight)) weight <- c(female = 55, male = 65)[[sex]]
    bmr(sex, age, weight) * 1.76
  }
  m <- ex$members
  column <- function(x, col, default) {
    if (is.null(x[[col]])) rep(default, nrow(x)) else x[[col]]
  }
  m$kcal <- mapply(member_kcal, m$sex, m$age_years,
                   column(m, "age_months", NA_real_),
                   column(m, "weight_kg", NA_real_))
  m$afe <- m$kcal / reference_kcal * column(m, "meals_home_share", 1)
  afe <- tapply(m$afe, m$household_id, sum)
  hh$afe <- unname(afe[as.character(hh$household_id)])

  # 2. Grams per day.
  a <- ex$acquisitions
  uf <- ex$unit_factors
  row_of <- function(unit, food) {
    i <- which(uf$unit %in% unit & uf$food_code %in% food)
    if (length(i) == 0) i <- which(uf$unit %in% unit & is.na(uf$food_code))
    if (length(i) == 0) NA_integer_ else i
  }
  k <- mapply(row_of, a$unit, a$food_code)
  f <- uf[k, ]
  grams <- ifelse(f$factor_type == "mass_g", a$quantity * f$factor,
           ifelse(f$factor_type == "volume_ml",
                  a$quantity * f$factor * f$density_g_ml,
                  a$quantity * f$factor * f$piece_weight_g))
  # A missing `household_share` leaves the record without grams.
  a$qty_g_d <- grams * column(a, "household_share", 1) / a$period_days

  # 3. Unfortified baseline composition and the link.
  comp <- ex$composition
  cols <- paste(names(ex$nutrients), ex$nutrients, sep = "_")
  rownames(comp) <- comp$composition_id
  base <- comp
  for (r in seq_len(nrow(ex$enrichment))) {
    e <- ex$enrichment[r, ]
    col <- cols[startsWith(cols, e$nutrient)]
    if (is.na(e$added)) {
      removed <- e$ingredient_fraction *
        max(comp[e$enriched_ref_id, col] - comp[e$unenriched_ref_id, col], 0)
      floor <- e$ingredient_fraction * comp[e$unenriched_ref_id, col]
    } else {
      removed <- e$added
      floor <- 0
    }
    base[e$composition_id, col] <- max(comp[e$composition_id, col] - removed,
                                       floor)
  }
  cw <- ex$crosswalk[match(a$food_code, ex$crosswalk$food_code), ]
  linked <- !is.na(cw$composition_id) & cw$validated &
    !is.na(cw$edible_portion) & !is.na(a$qty_g_d)
  used <- linked & a$include
  # A missing `yield_factor` is taken as 1.
  yield <- column(cw, "yield_factor", NA_real_)
  edible <- a$qty_g_d * cw$edible_portion * ifelse(is.na(yield), 1, yield)
  content <- sapply(cols, function(col) {
    edible * base[cw$composition_id, col] / 100
  })

  # 4. Intake per AFE.
  ids <- hh$household_id
  has_records <- ids %in% a$household_id
  any_used <- ids %in% a$household_id[used]
  estimated <- hh$food_module_response & has_records & any_used &
    !is.na(hh$afe) & hh$afe > 0
  sum_by <- function(v, keep) {
    s <- tapply(ifelse(keep & !is.na(v), v, 0),
                factor(a$household_id, levels = ids), sum)
    as.vector(s)
  }
  intake <- sapply(cols, function(col) sum_by(content[, col], used) / hh$afe)
  intake[!estimated, ] <- NA
  inc <- a$include
  records_share <- sum(used & a$household_id %in% ids) / sum(inc)

  # 5. Vehicle grams per AFE and the scenarios: all grams of the vehicle,
  # or only those that count as fortifiable.
  v <- ex$vehicles
  fortifiable <- if (is.null(a$fortifiable)) rep(TRUE, nrow(a)) else
    !a$fortifiable %in% FALSE
  vehicle_g <- function(vehicle, fortifiable_only = FALSE) {
    vv <- v[v$vehicle == vehicle, ]
    fr <- vv$vehicle_fraction[match(a$food_code, vv$food_code)]
    keep <- inc & !is.na(fr) & !is.na(a$qty_g_d)
    if (fortifiable_only) keep <- keep & fortifiable
    sum_by(a$qty_g_d * ifelse(is.na(fr), 0, fr), keep) / hh$afe
  }
  sc <- ex$scenarios
  conv <- ref_conversions
  added <- function(scenario, nutrient) {
    rows <- sc[sc$scenario == scenario & sc$nutrient == nutrient, ]
    out <- rep(0, length(ids))
    for (r in seq_len(nrow(rows))) {
      x <- rows[r, ]
      mg_kg <- x$level_mg_kg * if (x$level_basis == "compound") {
        x$nutrient_fraction
      } else {
        1
      }
      per_100g <- if (is.na(x$form)) {
        mg_kg / 10
      } else {
        mg_kg / 10 * 1000 * conv$factor[conv$from_form == x$form]
      }
      out <- out + vehicle_g(x$vehicle, fortifiable_only = TRUE) *
        per_100g * x$compliance / 100
    }
    out[!estimated] <- NA
    out
  }

  # 6. Inadequacy: cut-point (folate, vitamin A) and probability (iron).
  ear <- function(n) ref_requirements$ear[ref_requirements$nutrient == n]
  iron_tab <- ref_iron_requirements[ref_iron_requirements$group ==
                                      "females_menstruating_adult", ]
  p_iron <- function(intake, b) {
    absorbed <- intake * b / iron_tab$bioavailability[[1]]
    f <- stats::approx(iron_tab$requirement_mg_d, iron_tab$percentile / 100,
                       xout = absorbed, rule = 2, ties = mean)$y
    f[absorbed < min(iron_tab$requirement_mg_d)] <- 0
    f[absorbed > max(iron_tab$requirement_mg_d)] <- 1
    ifelse(is.na(intake), NA, 1 - f)
  }
  folate_base <- intake[, "folate_ug_dfe"]
  folate_flour <- folate_base + added(cfg$one, "folate")
  p_folate_base <- as.numeric(folate_base < ear("folate"))
  p_folate_flour <- as.numeric(folate_flour < ear("folate"))
  vita_fs <- intake[, "vitamin_a_ug_rae"] + added(cfg$two, "vitamin_a")
  folic_fs <- added(cfg$two, "folate") / 1.7
  ul_folic <- ref_requirements$ul[ref_requirements$nutrient == "folate"]

  # 7. Estimates on the design, domain of the estimated households.
  hh$y_folate <- ifelse(is.na(p_folate_base), 0, p_folate_base)
  hh$y_iron <- ifelse(estimated, p_iron(intake[, "iron_mg"], 0.10), 0)
  hh$y_diff <- ifelse(estimated, p_folate_flour - p_folate_base, 0)
  d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                         nest = TRUE, data = hh)
  sub <- d[estimated, ]
  old <- options(survey.lonely.psu = "adjust")
  kg_folate <- korn_graubard(sub, ~y_folate)
  kg_iron <- korn_graubard(sub, ~y_iron)
  pf <- survey::svyciprop(~y_folate, sub, method = "logit",
                          df = survey::degf(sub))
  pi <- survey::svyciprop(~y_iron, sub, method = "logit",
                          df = survey::degf(sub))
  pd <- survey::svymean(~y_diff, sub)
  options(old)

  # 8. Food-group shares on the baseline: ratio of weighted totals of the
  # amounts per AFE of the cereals and of every group, estimated households.
  fg <- ex$food_groups
  group <- fg$food_group[match(a$food_code, fg$food_code)]
  group[is.na(group)] <- "unclassified"
  share_of <- function(col, g) {
    num <- sum_by(content[, col], used & group == g) / hh$afe
    hh$num <- ifelse(estimated, num, 0)
    hh$den <- ifelse(estimated, intake[, col], 0)
    d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                           nest = TRUE, data = hh)
    old <- options(survey.lonely.psu = "adjust")
    on.exit(options(old))
    survey::svyratio(~num, ~den, d[estimated, ])
  }
  sh_folate <- share_of("folate_ug_dfe", "cereals")
  sh_iron <- share_of("iron_mg", "cereals")

  data.frame(
    name = c("afe_sum", "n_estimated", "share_records_used",
             paste0("mean_", cols), "mean_vehicle_g_d",
             "mean_fortifiable_g_d",
             "mean_folate_added_two", "mean_vitamin_a_two",
             "n_above_folic_acid_ul_two",
             "prev_folate_baseline", "se_folate_baseline",
             paste0(names(kg_folate), "_folate_baseline"),
             "prev_iron_b010_baseline", "se_iron_b010_baseline",
             paste0(names(kg_iron), "_iron_b010_baseline"),
             "diff_folate_one", "se_diff_folate_one",
             "share_cereals_folate", "se_share_cereals_folate",
             "share_cereals_iron", "se_share_cereals_iron"),
    value = c(sum(hh$afe, na.rm = TRUE), sum(estimated), records_share,
              colMeans(intake[estimated, ]),
              mean(vehicle_g(cfg$vehicle)[estimated]),
              mean(vehicle_g(cfg$vehicle, fortifiable_only = TRUE)[estimated]),
              mean(added(cfg$two, "folate")[estimated]),
              mean(vita_fs[estimated]), sum(folic_fs > ul_folic, na.rm = TRUE),
              stats::coef(pf), survey::SE(pf), kg_folate,
              stats::coef(pi), survey::SE(pi), kg_iron,
              stats::coef(pd), survey::SE(pd),
              stats::coef(sh_folate), survey::SE(sh_folate),
              stats::coef(sh_iron), survey::SE(sh_iron))
  )
}

write_golden <- function(golden, file) {
  utils::write.csv(transform(golden, value = sprintf("%.15g", value)),
                   file.path("tests/testthat/fixtures", file),
                   row.names = FALSE, quote = FALSE)
  print(golden)
}
write_golden(golden_values(hces_example, list(vehicle = "wheat_flour",
                                              one = "wheat_flour",
                                              two = "plus_oil")),
             "golden-example.csv")
write_golden(golden_values(hces_fixture, list(vehicle = "flour",
                                              one = "flour",
                                              two = "flour_and_sugar")),
             "golden-fixture.csv")
write_golden(golden_values(hces_optional, list(vehicle = "flour",
                                               one = "flour",
                                               two = "flour_and_sugar")),
             "golden-optional.csv")
