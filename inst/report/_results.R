# Results of the report: the only file that runs the hcesfort chain.
# report.qmd sources it with `params` set (see its YAML header).
#
# The block marked ADAPTER holds the inputs and the analytic choices of
# the example (hces_example, invented data). Replace it with the standard
# tables of your survey and your own choices; leave the rest unchanged.

library(hcesfort)

# ---- ADAPTER: inputs and choices (replace) ---------------------------
ex <- hcesfort::hces_example
households <- ex$households
members <- ex$members
acquisitions <- ex$acquisitions
unit_factors <- ex$unit_factors
crosswalk <- ex$crosswalk
nutrients <- nutrient_registry(ex$nutrients)
composition <- ex$composition
enrichment <- ex$enrichment
vehicles <- ex$vehicles
scenarios <- ex$scenarios
food_groups <- ex$food_groups
requirements <- hcesfort::ref_requirements
iron <- hcesfort::ref_iron_requirements
iron_distribution <- iron[iron$group == "females_menstruating_adult", ]
afe <- adult_equivalents(
  members,
  reference_kcal = reference_energy("female", 25, 55, pal = 1.76),
  weight_kg = c(female = 55, male = 65), pal = 1.76
)
grams <- convert_units(acquisitions, unit_factors, priority = "food")
compliance_model <- "average_content"
# ---- end of ADAPTER --------------------------------------------------

p <- lapply(params, function(v) if (is.list(v)) unlist(v) else v)
design <- as_hces_design(households, lonely_psu = p$lonely_psu)
precision <- function(e) {
  flag_precision(e, min_n = p$min_n, max_half_width = p$max_half_width)
}
keep_nutrients <- function(x) x[x$nutrient %in% p$nutrients, ]

# The chain, on the unfortified baseline.
base <- unfortified_baseline(composition, enrichment, nutrients)
content <- link_composition(grams, crosswalk, base, nutrients)
intake <- apparent_intake(content, afe, households)
all_vehicles <- unique(c(vehicles$vehicle, stats::na.omit(
  vehicles$vehicle_group
)))
use <- vehicle_coverage(grams, vehicles, afe, households,
                        combine = list(any_vehicle = all_vehicles))
s <- apply_scenario(intake, use, scenarios,
                    compliance_model = compliance_model)
risk <- inadequacy(
  s, requirements, distribution = list(iron = iron_distribution),
  bioavailability = list(iron = p$iron_bioavailability),
  min_coverage = p$min_coverage, min_records_used = p$min_records_used
)
ul <- above_ul(s, requirements, min_coverage = p$min_coverage,
               min_records_used = p$min_records_used)
# Above the UL on the form it applies to: the total where the diet part
# is known, else the added part.
ul$above_ul <- ifelse(is.na(ul$above_ul_total), ul$above_ul_added,
                      ul$above_ul_total)

# Q1. Risk by nutrient, reference scenario and baseline.
shown <- c("baseline", p$reference_scenario)
q1 <- estimate_households(design, keep_nutrients(risk), "p_inadequate",
                          level = p$level)
q1 <- precision(q1)
q1 <- q1[q1$scenario %in% shown, ]

# Q2. Risk by domain, reference scenario (exploratory).
risk_ref <- keep_nutrients(risk)
risk_ref <- risk_ref[risk_ref$scenario == p$reference_scenario, ]
q2 <- do.call(rbind, lapply(p$domains, function(d) {
  e <- precision(estimate_households(design, risk_ref, "p_inadequate",
                                     by = d, level = p$level))
  names(e)[names(e) == d] <- "domain_value"
  cbind(domain = d, as.data.frame(e))
}))

# Q3. Food-group shares before fortification.
groups <- food_group_intake(content, food_groups, afe, households)
q3 <- food_group_shares(design, groups, level = p$level)
nutrient_cols <- nutrients$column[nutrients$nutrient %in% p$nutrients]
q3 <- precision(q3[q3$variable %in% nutrient_cols, ])

# Q4. Reach of each vehicle, and grams among the households that acquire.
q4 <- precision(estimate_households(design, use, "acquired",
                                    level = p$level))
q4_qty <- estimate_households(design, use[use$level != "combined", ],
                              "qty_vehicle_g_d", statistic = "median",
                              domain = "acquired", level = p$level)

# Q5. Households outside every vehicle, by domain (exploratory).
any_use <- use[use$vehicle == "any_vehicle", ]
q5 <- do.call(rbind, lapply(c(list(NULL), as.list(p$domains)), function(d) {
  e <- as.data.frame(estimate_households(design, any_use, "acquired",
                                         by = d, level = p$level))
  label <- if (is.null(d)) "all" else d
  value <- if (is.null(d)) "all" else as.character(e[[d]])
  data.frame(domain = label, domain_value = value,
             none = 1 - e$estimate, ci_low = 1 - e$ci_high,
             ci_high = 1 - e$ci_low, n = e$n)
}))

# Q6. Paired change of each action, and households above the UL.
actions <- utils::read.csv("actions.csv", stringsAsFactors = FALSE)
q6 <- do.call(rbind, lapply(seq_len(nrow(actions)), function(i) {
  a <- actions[i, ]
  d <- estimate_difference(design, keep_nutrients(risk), "p_inadequate",
                           reference = a$scenario_from, level = p$level)
  d <- as.data.frame(d[d$scenario == a$scenario_to, ])
  cbind(action = a$action, d)
}))
# Equity across scenarios: the same paired change by the domain named in
# `equity_domain` (decision D6: no ratio of quintiles without an interval).
q6_equity <- do.call(rbind, lapply(seq_len(nrow(actions)), function(i) {
  a <- actions[i, ]
  d <- estimate_difference(design, keep_nutrients(risk), "p_inadequate",
                           reference = a$scenario_from,
                           by = p$equity_domain, level = p$level)
  d <- as.data.frame(d[d$scenario == a$scenario_to & d$se > 0, ])
  cbind(action = rep(a$action, nrow(d)), d)
}))
q6_ul <- as.data.frame(estimate_households(design, ul, "above_ul",
                                           level = p$level))

# Q7 and annexes: what each step excluded, flagged or filled.
decisions <- utils::read.csv("decisions.csv", stringsAsFactors = FALSE)
flow <- audit_summary(risk)
energy_col <- nutrients$column[nutrients$nutrient == "energy"]
energy_by_domain <- do.call(rbind, lapply(p$domains, function(d) {
  e <- estimate_households(design, intake, energy_col, statistic = "median",
                           by = d, level = p$level)
  names(e)[names(e) == d] <- "domain_value"
  cbind(domain = d, as.data.frame(e))
}))
iron_sensitivity <- NULL
if (length(p$iron_bioavailability_sensitivity) > 0) {
  b <- sort(unique(c(p$iron_bioavailability,
                     p$iron_bioavailability_sensitivity)))
  r <- inadequacy(s, requirements,
                  distribution = list(iron = iron_distribution),
                  bioavailability = list(iron = b),
                  min_coverage = p$min_coverage,
                  min_records_used = p$min_records_used)
  iron_sensitivity <- estimate_households(design, r[r$nutrient == "iron", ],
                                          "p_inadequate", level = p$level)
}
