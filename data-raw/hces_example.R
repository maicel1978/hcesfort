# Build `hces_example`, the synthetic example dataset of hcesfort.
#
# Every value is INVENTED. Nothing comes from a survey, a food composition
# table or a fortification standard; the numbers only have plausible orders
# of magnitude so that examples and vignettes read naturally. Do not use
# them for analysis.
#
# Run from the package root: Rscript data-raw/hces_example.R
# The result is deterministic (fixed seed, base R only).
#
# The dataset deliberately contains the cases the package must handle, so
# examples and tests exercise them (expected counts are checked in
# tests/testthat/test-example-data.R):
# - a household that did not answer the food module, and one with members
#   but no acquisitions;
# - members with a missing age and a missing sex, a pregnant and a
#   lactating woman;
# - acquisitions with a missing quantity, a missing unit, a record left out
#   by the section rule (include = FALSE), a very large quantity, a unit
#   without factor ("sack"), and two recall periods;
# - unit factors of the three types, a volume factor without density;
# - a crosswalk with an unmatched food, an unvalidated match and a missing
#   edible portion;
# - a composition table with a missing nutrient value and an enriched row;
# - a food with two vehicles; a scenario with a compound-based level.

set.seed(20261112)

n_households <- 40L
strata <- rep(c("urban", "rural"), each = n_households / 2)

households <- data.frame(
  household_id = seq_len(n_households),
  weight = round(stats::runif(n_households, 80, 400), 1),
  stratum = strata,
  psu = paste0(strata, "_", rep(1:4, each = 5, times = 2)),
  food_module_response = TRUE,
  region = rep(c("north", "south"), times = n_households / 2)
)
households$food_module_response[[40]] <- FALSE

# Members: 1 to 6 per household; the first is an adult.
size <- sample(1:6, n_households, replace = TRUE)
members <- data.frame(
  household_id = rep(households$household_id, size),
  member_id = sequence(size)
)
n_members <- nrow(members)
members$age_years <- ifelse(
  members$member_id == 1L,
  sample(20:75, n_members, replace = TRUE),
  sample(0:80, n_members, replace = TRUE)
)
members$sex <- sample(c("female", "male"), n_members, replace = TRUE)
members$pregnant <- FALSE
members$lactating <- FALSE
women <- which(members$sex == "female" & members$age_years %in% 18:40)
members$pregnant[women[[1]]] <- TRUE
members$lactating[women[[2]]] <- TRUE
members$age_years[[3]] <- NA
members$sex[[5]] <- NA

# Foods, the unit in which each is usually recorded and a typical quantity
# in that unit.
foods <- data.frame(
  food_code = c("rice", "wheat_flour", "bread", "pasta", "beans", "oil",
                "sugar", "milk", "egg", "chicken", "banana", "biscuit",
                "local_herb"),
  unit = c("lb", "lb", "piece", "g", "lb", "l", "lb", "l", "piece", "lb",
           "piece", "g", "bunch"),
  typical = c(5, 2, 10, 400, 2, 1, 4, 3, 12, 3, 8, 300, 1)
)

# Acquisitions: 3 to 8 foods per household that answered the food module;
# household 39 has members but no acquisitions.
buyers <- setdiff(households$household_id, c(39L, 40L))
n_foods <- sample(3:8, length(buyers), replace = TRUE)
acquisitions <- do.call(rbind, lapply(seq_along(buyers), function(i) {
  pick <- foods[sample(nrow(foods), n_foods[[i]]), ]
  data.frame(
    household_id = buyers[[i]], food_code = pick$food_code,
    quantity = round(pick$typical * stats::runif(nrow(pick), 0.3, 1.7), 2),
    unit = pick$unit
  )
}))
acquisitions <- cbind(record_id = seq_len(nrow(acquisitions)), acquisitions)
acquisitions$section <- ifelse(acquisitions$food_code %in% c("egg", "banana"),
                               "recall", "diary")
acquisitions$period_days <- ifelse(acquisitions$section == "recall", 30, 7)
acquisitions$include <- TRUE
acquisitions$origin <- "purchase"
acquisitions$quantity[[2]] <- NA
acquisitions$unit[[4]] <- NA
acquisitions$include[[6]] <- FALSE
acquisitions$quantity[[8]] <- acquisitions$quantity[[8]] * 200
acquisitions$unit[[10]] <- "sack"
pieces <- acquisitions$unit %in% c("piece", "bunch")
acquisitions$quantity[pieces] <- pmax(1, round(acquisitions$quantity[pieces]))
rownames(acquisitions) <- NULL

unit_factors <- data.frame(
  unit = c("lb", "g", "l", "l", "piece", "piece", "piece", "bunch"),
  food_code = c(NA, NA, NA, "oil", "bread", "egg", "banana", "local_herb"),
  factor = c(453.6, 1, 1000, 1000, 1, 1, 1, 1),
  factor_type = c("mass_g", "mass_g", "volume_ml", "volume_ml", "count",
                  "count", "count", "count"),
  density_g_ml = c(NA, NA, NA, 0.92, NA, NA, NA, NA),
  piece_weight_g = c(NA, NA, NA, NA, 60, 50, 120, 80),
  source = "synthetic: invented"
)

crosswalk <- data.frame(
  food_code = foods$food_code,
  composition_id = c("C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08",
                     "C09", "C10", "C11", "C12", NA),
  match_type = c("exact", "exact", "similar", "exact", "exact", "exact",
                 "exact", "similar", "exact", "proxy", "exact", NA, NA),
  validated = c(rep(TRUE, 11), FALSE, FALSE),
  edible_portion = c(1, 1, 1, 1, 1, 1, 1, 1, 0.88, 0.7, NA, 1, NA)
)

nutrients <- c(energy = "kcal", iron = "mg", folate = "ug_dfe",
               vitamin_a = "ug_rae")

composition <- data.frame(
  composition_id = sprintf("C%02d", 1:12),
  description = c("rice, white, raw", "wheat flour, unfortified",
                  "bread, white", "pasta, dry, enriched", "beans, dry",
                  "vegetable oil", "sugar, white", "milk, whole",
                  "egg, whole, raw", "chicken, raw", "banana, raw",
                  "biscuit, sweet"),
  energy_kcal = c(360, 364, 266, 371, 333, 884, 387, 61, 143, 215, 89, 480),
  iron_mg = c(0.8, 1.2, 1.5, 3.3, 5, 0, 0.1, 0, 1.8, 0.9, 0.3, 2),
  folate_ug_dfe = c(8, 26, 40, 400, 390, 0, 0, 5, 47, 7, 20, NA),
  vitamin_a_ug_rae = c(0, 0, 0, 0, 0, 0, 0, 46, 160, 40, 3, 10),
  basis = "per_100g_edible",
  food_state = c("raw", "raw", "as_consumed", "raw", "raw", "raw", "raw",
                 "as_consumed", "raw", "raw", "raw", "as_consumed"),
  fortified = c(FALSE, FALSE, FALSE, TRUE, rep(FALSE, 8)),
  source = "synthetic: invented"
)

vehicles <- data.frame(
  food_code = c("wheat_flour", "bread", "pasta", "biscuit", "biscuit",
                "sugar"),
  vehicle = c("wheat_flour", "wheat_flour", "wheat_flour", "wheat_flour",
              "sugar", "sugar"),
  vehicle_fraction = c(1, 0.6, 1, 0.5, 0.25, 1),
  source = "synthetic: invented"
)

scenarios <- data.frame(
  scenario = c("flour", "flour", "flour_and_sugar", "flour_and_sugar",
               "flour_and_sugar"),
  vehicle = c("wheat_flour", "wheat_flour", "wheat_flour", "wheat_flour",
              "sugar"),
  nutrient = c("iron", "folate", "iron", "folate", "vitamin_a"),
  level_mg_kg = c(40, 2, 40, 2, 10),
  level_basis = c("nutrient", "compound", "nutrient", "compound",
                  "nutrient"),
  compound = c("iron compound", "folic acid", "iron compound", "folic acid",
               "vitamin A compound"),
  nutrient_fraction = c(NA, 1, NA, 1, NA),
  compliance = c(0.8, 0.8, 0.8, 0.8, 0.6),
  source = "synthetic: invented"
)

hces_example <- list(
  households = households, members = members, acquisitions = acquisitions,
  unit_factors = unit_factors, crosswalk = crosswalk,
  nutrients = nutrients, composition = composition, vehicles = vehicles,
  scenarios = scenarios
)

save(hces_example, file = "data/hces_example.rda", compress = "xz",
     version = 2)
