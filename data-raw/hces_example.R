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
#   without factor ("sack"), a milk record in a volume unit without density
#   ("cup"), and two recall periods;
# - unit factors of the three types, volume factors without density;
# - a crosswalk with an unmatched food, an unvalidated match and a missing
#   edible portion;
# - a composition table with a missing nutrient value, an enriched pasta and
#   an enriched flour, and the enrichment rules that remove what was added;
# - a food with two vehicles of different groups; a scenario with a
#   compound-based level;
# - a grouping of foods that leaves one food (egg) without a group;
# - an invented socioeconomic domain, `expenditure_group`, Q1 to Q5;
# - an invented expenditure for every acquisition, `expenditure_lcu`.

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
# An invented socioeconomic domain, five groups of eight households (Q1 the
# lowest), assigned without the random generator so that the other tables
# do not change. Added 2026-11-12 for the report template (G6).
households$expenditure_group <- paste0(
  "Q", (households$household_id * 3L) %% 5L + 1L
)

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

# Foods, the unit in which each is usually recorded and a typical weekly
# quantity in that unit for a household of three members. Recalibrated on
# 2026-11-12 (review of v0.1, H6) so that the median energy per AFE is
# plausible and iron, folate and vitamin A straddle their requirements.
foods <- data.frame(
  food_code = c("rice", "wheat_flour", "bread", "pasta", "beans", "oil",
                "sugar", "milk", "egg", "chicken", "banana", "biscuit",
                "local_herb", "pumpkin"),
  unit = c("lb", "lb", "piece", "g", "lb", "l", "lb", "l", "piece", "lb",
           "piece", "g", "bunch", "lb"),
  typical = c(10, 5, 30, 800, 4, 1.5, 4, 5, 18, 4, 12, 400, 1, 5),
  # How often a household acquires the food: the planted defects (banana
  # without edible portion, unvalidated biscuit, unmatched herb) are rare.
  frequency = c(1, 0.8, 0.9, 0.6, 0.8, 1, 1, 0.7, 0.7, 0.7, 0.1, 0.1, 0.1,
                0.8)
)

# Acquisitions: 6 to 11 foods per household that answered the food module,
# quantities proportional to household size; household 39 has members but
# no acquisitions.
buyers <- setdiff(households$household_id, c(39L, 40L))
n_foods <- sample(6:11, length(buyers), replace = TRUE)
acquisitions <- do.call(rbind, lapply(seq_along(buyers), function(i) {
  pick <- foods[sample(nrow(foods), n_foods[[i]], prob = foods$frequency), ]
  scale <- size[[buyers[[i]]]] / 3
  data.frame(
    household_id = buyers[[i]], food_code = pick$food_code,
    quantity = round(pick$typical * scale *
                       stats::runif(nrow(pick), 0.5, 1.6), 2),
    unit = pick$unit
  )
}))
acquisitions <- cbind(record_id = seq_len(nrow(acquisitions)), acquisitions)
acquisitions$section <- ifelse(acquisitions$food_code %in% c("egg", "banana"),
                               "recall", "diary")
acquisitions$period_days <- ifelse(acquisitions$section == "recall", 30, 7)
recall <- acquisitions$section == "recall"
acquisitions$quantity[recall] <- acquisitions$quantity[recall] * 30 / 7
acquisitions$include <- TRUE
acquisitions$origin <- "purchase"
acquisitions$quantity[[2]] <- NA
acquisitions$unit[[4]] <- NA
acquisitions$include[[6]] <- FALSE
acquisitions$quantity[[8]] <- acquisitions$quantity[[8]] * 200
acquisitions$unit[[10]] <- "sack"
# One milk record in cups: a volume unit without a density for milk.
milk <- which(acquisitions$food_code == "milk")
acquisitions$unit[[milk[[1]]]] <- "cup"
acquisitions$quantity[[milk[[1]]]] <- 8
pieces <- acquisitions$unit %in% c("piece", "bunch")
acquisitions$quantity[pieces] <- pmax(1, round(acquisitions$quantity[pieces]))
rownames(acquisitions) <- NULL
# Expenditure in invented local currency units: an invented price per unit
# of each food times the quantity, without the random generator so that the
# other tables do not change. The milk record in cups has a price per cup;
# the record without quantity has an amount paid (expenditure is the only
# measure known for every record). Added 2026-11-13 (design reports v2,
# section 3.1).
price <- c(rice = 25, wheat_flour = 20, bread = 5, pasta = 0.1, beans = 45,
           oil = 150, sugar = 25, milk = 60, egg = 7, chicken = 70,
           banana = 5, biscuit = 0.15, local_herb = 15, pumpkin = 20)
acquisitions$expenditure_lcu <- round(
  price[acquisitions$food_code] * acquisitions$quantity, 2
)
acquisitions$expenditure_lcu[[milk[[1]]]] <- 8 * 15
acquisitions$expenditure_lcu[[2]] <- 50
acquisitions$expenditure_lcu <- unname(acquisitions$expenditure_lcu)

unit_factors <- data.frame(
  unit = c("lb", "g", "l", "l", "l", "cup", "piece", "piece", "piece",
           "bunch"),
  food_code = c(NA, NA, NA, "oil", "milk", NA, "bread", "egg", "banana",
                "local_herb"),
  factor = c(453.6, 1, 1000, 1000, 1000, 240, 1, 1, 1, 1),
  factor_type = c("mass_g", "mass_g", "volume_ml", "volume_ml", "volume_ml",
                  "volume_ml", "count", "count", "count", "count"),
  density_g_ml = c(NA, NA, NA, 0.92, 1.03, NA, NA, NA, NA, NA),
  piece_weight_g = c(NA, NA, NA, NA, NA, NA, 60, 50, 120, 80),
  source = "synthetic: invented"
)

crosswalk <- data.frame(
  food_code = foods$food_code,
  composition_id = c("C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08",
                     "C09", "C10", "C11", "C12", NA, "C14"),
  match_type = c("exact", "exact", "similar", "exact", "exact", "exact",
                 "exact", "similar", "exact", "proxy", "exact", NA, NA,
                 "exact"),
  validated = c(rep(TRUE, 11), FALSE, FALSE, TRUE),
  edible_portion = c(1, 1, 1, 1, 1, 1, 1, 1, 0.88, 0.7, NA, 1, NA, 0.8)
)

nutrients <- c(energy = "kcal", iron = "mg", folate = "ug_dfe",
               vitamin_a = "ug_rae")

composition <- data.frame(
  composition_id = sprintf("C%02d", 1:14),
  description = c("rice, white, raw", "wheat flour, unfortified",
                  "bread, white", "pasta, dry, enriched", "beans, dry",
                  "vegetable oil", "sugar, white", "milk, whole",
                  "egg, whole, raw", "chicken, raw", "banana, raw",
                  "biscuit, sweet", "wheat flour, enriched",
                  "pumpkin, raw"),
  energy_kcal = c(360, 364, 266, 371, 333, 884, 387, 61, 143, 215, 89, 480,
                  364, 26),
  iron_mg = c(0.8, 1.2, 1.5, 3.3, 5, 0, 0.1, 0, 1.8, 0.9, 0.3, 2, 3, 0.8),
  folate_ug_dfe = c(8, 26, 40, 400, 390, 0, 0, 5, 47, 7, 20, NA, 290, 16),
  vitamin_a_ug_rae = c(0, 0, 0, 0, 0, 0, 0, 46, 160, 40, 3, 10, 0, 426),
  basis = "per_100g_edible",
  food_state = c("raw", "raw", "as_consumed", "raw", "raw", "raw", "raw",
                 "as_consumed", "raw", "raw", "raw", "as_consumed", "raw",
                 "raw"),
  fortified = c(FALSE, FALSE, FALSE, TRUE, rep(FALSE, 8), TRUE, FALSE),
  source = "synthetic: invented"
)

# What enrichment added: the enriched pasta (C04) is made of flour only, so
# its ingredient is the enriched flour (C13) against the unfortified flour
# (C02) at fraction 1; the enriched flour is its own reference. By hand,
# iron: pasta 3.3 - 1 x (3 - 1.2) = 1.5; flour 1.2. Folate: pasta
# 400 - (290 - 26) = 136; flour 26.
enrichment <- data.frame(
  composition_id = c("C04", "C04", "C13", "C13"),
  nutrient = c("iron", "folate", "iron", "folate"),
  enriched_ref_id = "C13", unenriched_ref_id = "C02",
  ingredient_fraction = 1, added = NA_real_,
  source = "synthetic: invented"
)

# Vehicles by product class; the three wheat products share the group
# "wheat_flour". The biscuit carries flour and sugar.
vehicles <- data.frame(
  food_code = c("wheat_flour", "bread", "pasta", "biscuit", "biscuit",
                "sugar"),
  vehicle = c("flour", "bread", "pasta", "bread", "sugar", "sugar"),
  vehicle_group = c("wheat_flour", "wheat_flour", "wheat_flour",
                    "wheat_flour", NA, NA),
  vehicle_fraction = c(1, 0.6, 1, 0.5, 0.25, 1),
  source = "synthetic: invented"
)

# Scenario "flour" fortifies flour and bread only; "flour_and_sugar" also
# pasta, with more folic acid (so that a few households pass the upper
# level of folic acid), and sugar with vitamin A given as an invented
# compound.
wheat <- function(scenario, products, folic_acid) {
  data.frame(
    scenario = scenario, vehicle = rep(products, each = 2),
    nutrient = c("iron", "folate"), level_mg_kg = c(40, folic_acid),
    level_basis = "nutrient", compound = NA_character_,
    form = c(NA, "folic_acid"), nutrient_fraction = NA_real_,
    compliance = 0.8, source = "synthetic: invented"
  )
}
scenarios <- rbind(
  wheat("flour", c("flour", "bread"), 2),
  wheat("flour_and_sugar", c("flour", "bread", "pasta"), 4.5),
  data.frame(
    scenario = "flour_and_sugar", vehicle = "sugar", nutrient = "vitamin_a",
    level_mg_kg = 10, level_basis = "compound",
    compound = "vitamin A compound", form = "retinol",
    nutrient_fraction = 0.5, compliance = 0.6, source = "synthetic: invented"
  )
)

# Food groups for food_group_intake(): an invented grouping, not a
# published classification. The egg is left without a group on purpose,
# so that the example has an `unclassified` share.
food_groups <- data.frame(
  food_code = c("rice", "wheat_flour", "bread", "pasta", "biscuit",
                "beans", "oil", "sugar", "milk", "chicken", "banana",
                "local_herb", "pumpkin"),
  food_group = c(rep("cereals", 5), "pulses", "fats_and_oils", "sugars",
                 "dairy", "meat", "fruits", "vegetables", "vegetables"),
  source = "synthetic: invented"
)

hces_example <- list(
  households = households, members = members, acquisitions = acquisitions,
  unit_factors = unit_factors, crosswalk = crosswalk,
  nutrients = nutrients, composition = composition, enrichment = enrichment,
  vehicles = vehicles, scenarios = scenarios, food_groups = food_groups
)

save(hces_example, file = "data/hces_example.rda", compress = "xz",
     version = 2)
