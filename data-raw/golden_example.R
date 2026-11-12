# Golden values of the full chain on `hces_example` (review of v0.1, M11).
#
# Computed here WITHOUT any function of hcesfort: base R and `survey` only,
# from the documented rules of each step, so that a shared misreading of a
# rule by the package and its tests cannot hide. The data are the shipped
# `hces_example` and reference tables (read as data). The values are written
# to tests/testthat/fixtures/golden-example.csv and compared at 1e-8 by
# tests/testthat/test-golden-example.R, which runs the chain with the
# package.
#
# Choices of the chain: reference woman 18-30 years, 55 kg, PAL 1.76; men
# 65 kg; infants by the mean of their months; a member without age or sex
# leaves the household without AFE; unit factors by food first; no outlier
# rule; average-content compliance; iron by the probability approach for
# menstruating adult women; food-group shares with the example grouping
# (the egg unclassified).
#
# Run from the package root: Rscript data-raw/golden_example.R

load("data/hces_example.rda")
for (f in c("ref_energy_requirements", "ref_bmr_equations", "ref_conversions",
            "ref_iron_requirements", "ref_requirements")) {
  load(file.path("data", paste0(f, ".rda")))
}
ex <- hces_example
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
member_kcal <- function(sex, age) {
  if (is.na(sex) || is.na(age)) return(NA_real_)
  if (age < 1) {
    return(mean(er$energy_kcal_d[er$age_unit == "month" & er$sex == sex &
                                   er$age_to <= 12]))
  }
  yr <- er[er$age_unit == "year" & er$sex == sex, ]
  if (age < max(yr$age_to)) {
    return(yr$energy_kcal_d[age >= yr$age_from & age < yr$age_to])
  }
  bmr(sex, age, c(female = 55, male = 65)[[sex]]) * 1.76
}
m <- ex$members
m$kcal <- mapply(member_kcal, m$sex, m$age_years)
afe <- tapply(m$kcal, m$household_id, sum) / reference_kcal
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
a$qty_g_d <- grams / a$period_days

# 3. Unfortified baseline composition and the link.
comp <- ex$composition
cols <- c("energy_kcal", "iron_mg", "folate_ug_dfe", "vitamin_a_ug_rae")
rownames(comp) <- comp$composition_id
base <- comp
for (r in seq_len(nrow(ex$enrichment))) {
  e <- ex$enrichment[r, ]
  col <- cols[startsWith(cols, e$nutrient)]
  removed <- e$ingredient_fraction *
    (comp[e$enriched_ref_id, col] - comp[e$unenriched_ref_id, col])
  floor <- e$ingredient_fraction * comp[e$unenriched_ref_id, col]
  base[e$composition_id, col] <- max(comp[e$composition_id, col] - removed,
                                     floor)
}
cw <- ex$crosswalk[match(a$food_code, ex$crosswalk$food_code), ]
linked <- !is.na(cw$composition_id) & cw$validated &
  !is.na(cw$edible_portion) & !is.na(a$qty_g_d)
used <- linked & a$include
edible <- a$qty_g_d * cw$edible_portion
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

# 5. Vehicle grams per AFE and the scenarios.
v <- ex$vehicles
vehicle_g <- function(vehicle) {
  vv <- v[v$vehicle == vehicle, ]
  fr <- vv$vehicle_fraction[match(a$food_code, vv$food_code)]
  keep <- inc & !is.na(fr) & !is.na(a$qty_g_d)
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
    out <- out + vehicle_g(x$vehicle) * per_100g * x$compliance / 100
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
folate_flour <- folate_base + added("flour", "folate")
p_folate_base <- as.numeric(folate_base < ear("folate"))
p_folate_flour <- as.numeric(folate_flour < ear("folate"))
vita_fs <- intake[, "vitamin_a_ug_rae"] +
  added("flour_and_sugar", "vitamin_a")
folic_fs <- added("flour_and_sugar", "folate") / 1.7
ul_folic <- ref_requirements$ul[ref_requirements$nutrient == "folate"]

# 7. Estimates on the design, domain of the estimated households.
hh$y_folate <- ifelse(is.na(p_folate_base), 0, p_folate_base)
hh$y_iron <- ifelse(estimated, p_iron(intake[, "iron_mg"], 0.10), 0)
hh$y_diff <- ifelse(estimated, p_folate_flour - p_folate_base, 0)
d <- survey::svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                       nest = TRUE, data = hh)
sub <- d[estimated, ]
old <- options(survey.lonely.psu = "adjust")
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

golden <- data.frame(
  name = c("afe_sum", "n_estimated", "share_records_used",
           "mean_energy_kcal", "mean_iron_mg", "mean_folate_ug_dfe",
           "mean_vitamin_a_ug_rae", "mean_flour_g_d",
           "mean_folate_added_flour_and_sugar",
           "mean_vitamin_a_flour_and_sugar", "n_above_folic_acid_ul",
           "prev_folate_baseline", "se_folate_baseline",
           "prev_iron_b010_baseline", "se_iron_b010_baseline",
           "diff_folate_flour", "se_diff_folate_flour",
           "share_cereals_folate", "se_share_cereals_folate",
           "share_cereals_iron", "se_share_cereals_iron"),
  value = c(sum(hh$afe, na.rm = TRUE), sum(estimated), records_share,
            colMeans(intake[estimated, ]),
            mean(vehicle_g("flour")[estimated]),
            mean(added("flour_and_sugar", "folate")[estimated]),
            mean(vita_fs[estimated]), sum(folic_fs > ul_folic, na.rm = TRUE),
            stats::coef(pf), survey::SE(pf), stats::coef(pi), survey::SE(pi),
            stats::coef(pd), survey::SE(pd),
            stats::coef(sh_folate), survey::SE(sh_folate),
            stats::coef(sh_iron), survey::SE(sh_iron))
)
utils::write.csv(transform(golden, value = sprintf("%.15g", value)),
                 "tests/testthat/fixtures/golden-example.csv",
                 row.names = FALSE, quote = FALSE)
print(golden)
