# Build `hces_example`, the realistic synthetic example dataset of hcesfort.
#
# Every value is INVENTED. Nothing comes from a survey, a food composition
# table or a fortification standard; the numbers only have plausible orders
# of magnitude so that examples, the report templates and the vignettes read
# like a real survey. Do not use them for analysis.
#
# Design: docs/design-reports-v3.md, section 7.1 (decisions V-D7 and V-D8 of
# docs/improvements.md). The 40 households that were `hces_example` until
# 2026-11-14 are now the test fixture tests/testthat/fixtures/hces_fixture.R.
#
# Run from the package root: Rscript data-raw/hces_example.R
# Base R only. The generator and the seed are set explicitly and every
# generated number is rounded before it is stored, so the build is
# deterministic.
#
# Sample: 3 regions x urban and rural = 6 strata; 200 PSUs of 10 households
# (25 to 40 PSUs per stratum), 2,000 households, 194 design degrees of
# freedom. The weight is a base weight of the stratum times a factor of the
# PSU. A latent wealth score has a stratum part, a PSU part and a household
# part: the PSU part makes households of one PSU alike, so design effects
# are above 1, as in a real survey. Wealth drives household size here and
# what is acquired in part 2; it is not stored.
#
# Foods: data-raw/example_foods.csv, entered by hand (every value
# invented). One row per survey food: recording unit and questionnaire
# section; probability of acquiring it in a week at mean wealth
# (`p_acquire`), its slope on wealth on the logit scale and a multiplier of
# the odds by region; typical weekly quantity for a household of three at
# mean wealth (`qty_week`, in `unit`) and its elasticity on wealth; price per
# unit; composition per 100 g edible portion (energy, iron, zinc, folate,
# vitamin A); state, enrichment, crosswalk status and edible portion; food
# group; up to two vehicles with their fractions.
#
# This file is written in two steps (docs/design-reports-v3.md, section
# 12): 12d.7 builds households and members; 12d.8 adds acquisitions, the
# expenditure groups, the user tables and the save() of the dataset.

RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20261114)

# The foods table is checked against its md5 in data-raw/MD5.
foods_file <- "data-raw/example_foods.csv"
registry <- utils::read.table("data-raw/MD5", col.names = c("md5", "file"))
stopifnot(unname(tools::md5sum(foods_file)) ==
            registry$md5[registry$file == basename(foods_file)])
foods <- utils::read.csv(foods_file, stringsAsFactors = FALSE,
                         na.strings = "")
stopifnot(!anyDuplicated(foods$food_code))

# Households --------------------------------------------------------------

# PSUs per stratum (sum 200) and an invented base weight per stratum.
design <- data.frame(
  region = rep(c("north", "central", "south"), each = 2),
  area = rep(c("urban", "rural"), times = 3),
  n_psu = c(40L, 30L, 38L, 32L, 35L, 25L),
  base_weight = c(150, 210, 170, 240, 160, 230),
  # Mean wealth of the stratum: urban above rural, the south the poorest.
  wealth = c(0.4, -0.3, 0.5, -0.2, 0.1, -0.6)
)
design$stratum <- paste(design$region, design$area, sep = "_")
stopifnot(sum(design$n_psu) == 200L)

psus <- design[rep(seq_len(nrow(design)), design$n_psu), ]
psus$psu <- sprintf("%s_%02d", psus$stratum, sequence(design$n_psu))
psus$psu_factor <- round(stats::runif(nrow(psus), 0.6, 1.4), 2)
psus$psu_wealth <- stats::rnorm(nrow(psus), 0, 0.4)

hh_per_psu <- 10L
households <- psus[rep(seq_len(nrow(psus)), each = hh_per_psu), ]
households <- data.frame(
  household_id = seq_len(nrow(households)),
  weight = round(households$base_weight * households$psu_factor, 1),
  stratum = households$stratum,
  psu = households$psu,
  region = households$region,
  area = households$area,
  wealth = round(households$wealth + households$psu_wealth +
                   stats::rnorm(nrow(households), 0, 0.8), 3)
)
n_households <- nrow(households)

# Non-response to the food module: about 1.5% of households, more often in
# urban areas.
p_refuse <- ifelse(households$area == "urban", 0.025, 0.008)
households$food_module_response <- stats::runif(n_households) >= p_refuse

# Members -----------------------------------------------------------------

# Household size falls with wealth: 1 + Poisson, at most 12 members.
size <- 1L + stats::rpois(n_households, exp(log(2.4) - 0.25 *
                                              households$wealth))
size <- pmin(size, 12L)

# A fixed age pyramid by five-year band (0-4 to 75-79), for members other
# than the head and the spouse.
pyramid <- c(0.17, 0.16, 0.15, 0.13, 0.08, 0.06, 0.05, 0.04, 0.035, 0.03,
             0.025, 0.02, 0.02, 0.015, 0.01, 0.005)
draw_ages <- function(n) {
  band <- sample(seq_along(pyramid), n, replace = TRUE, prob = pyramid)
  5L * (band - 1L) + sample(0:4, n, replace = TRUE)
}

members <- data.frame(
  household_id = rep(households$household_id, size),
  member_id = sequence(size)
)
n_members <- nrow(members)
head <- members$member_id == 1L
second <- members$member_id == 2L

# Heads: 20 to 79 years, 60% men. A second member is the spouse in three
# households of four: opposite sex, age within five years of the head.
members$age_years <- draw_ages(n_members)
members$age_years[head] <- sample(20:79, sum(head), replace = TRUE,
                                  prob = rep(c(3, 2, 1), each = 20))
members$sex <- ifelse(stats::runif(n_members) < 0.5, "female", "male")
members$sex[head] <- ifelse(stats::runif(sum(head)) < 0.6, "male", "female")
spouse <- second & stats::runif(n_members) < 0.75
head_row <- match(members$household_id, members$household_id[head])
head_row <- which(head)[head_row]
members$sex[spouse] <- ifelse(members$sex[head_row[spouse]] == "male",
                              "female", "male")
members$age_years[spouse] <- pmax(18L, members$age_years[head_row[spouse]] +
                                    sample(-5:5, sum(spouse), replace = TRUE))

# Pregnant women: 4% of women aged 15 to 49. Lactating women: in a
# household with an infant (age 0), one woman aged 15 to 49 who is not
# pregnant, with probability 0.8.
fertile <- members$sex == "female" & members$age_years %in% 15:49
members$pregnant <- fertile & stats::runif(n_members) < 0.04
infant_hh <- unique(members$household_id[members$age_years == 0L])
candidate <- fertile & !members$pregnant &
  members$household_id %in% infant_hh
first_candidate <- candidate & !duplicated(ifelse(candidate,
                                                  members$household_id, NA))
members$lactating <- first_candidate & stats::runif(n_members) < 0.8

# Item non-response: age missing for about 0.3% of members and sex for
# about 0.2%; such households have no adult female equivalents.
members$age_years[stats::runif(n_members) < 0.003] <- NA
members$sex[stats::runif(n_members) < 0.002] <- NA
members$age_years <- as.numeric(members$age_years)

# Acquisitions ------------------------------------------------------------

# Households that answered the food module; about 0.3% of them report no
# acquisition at all.
respond <- households$household_id[households$food_module_response]
empty <- respond[stats::runif(length(respond)) < 0.003]
buyers <- setdiff(respond, empty)

# About 1% of the buying households keep a short food list: they buy no
# staples (they eat out, or receive food baskets the survey does not
# record), only eggs, dairy, vegetables, fruits, beverages and soft drinks.
# None of these foods is a vehicle, so these households acquire no vehicle
# and exhibit R1.4 has a small nonzero estimate (P140, V-D20). They are
# drawn here from a stream of their own, and their other records are
# removed after the defects are planted, so that every other household
# keeps the records it had before they were added.
stream <- .Random.seed
set.seed(20261115)
short_list <- buyers[stats::runif(length(buyers)) < 0.01]
.Random.seed <- stream
short_foods <- foods$food_code[
  foods$food_group %in% c("eggs", "dairy", "vegetables", "fruits",
                          "beverages") | foods$food_code == "soft_drink"
]
short_rows <- foods$food_code %in% short_foods
stopifnot(all(is.na(foods$vehicle[short_rows])),
          all(is.na(foods$vehicle_2[short_rows])))

# One row per buying household and food. The odds of acquiring a food rise
# or fall with wealth, change by region, and have a PSU effect, so that
# neighbours buy alike.
psu_ids <- unique(households$psu)
psu_food <- matrix(round(stats::rnorm(length(psu_ids) * nrow(foods), 0, 0.5),
                         3), nrow = length(psu_ids))
regions <- c("north", "central", "south")
region_mult <- as.matrix(foods[paste0("mult_", regions)])
grid <- expand.grid(food = seq_len(nrow(foods)),
                    hh = match(buyers, households$household_id))
hh <- households[grid$hh, ]
fd <- foods[grid$food, ]
logit <- stats::qlogis(fd$p_acquire) + fd$wealth_slope * hh$wealth +
  log(region_mult[cbind(grid$food, match(hh$region, regions))]) +
  psu_food[cbind(match(hh$psu, psu_ids), grid$food)]
keep <- stats::runif(nrow(grid)) < stats::plogis(logit)
hh <- hh[keep, ]
fd <- fd[keep, ]
n_records <- nrow(fd)

# Quantity in the recording unit for the period of the section: the weekly
# quantity of a household of three, scaled by size and wealth, with
# household noise. Diary: 7 days; recall: 30 days.
period <- ifelse(fd$section == "recall", 30, 7)
quantity <- fd$qty_week * (size[grid$hh[keep]] / 3)^0.85 *
  exp(fd$qty_elasticity * hh$wealth) *
  exp(stats::rnorm(n_records, 0, 0.35)) * period / 7
count_unit <- fd$unit %in% c("piece", "can", "bunch")
quantity <- ifelse(count_unit, pmax(1, round(quantity)),
                   ifelse(fd$unit == "g", round(quantity, -1),
                          round(quantity, 2)))

origin <- ifelse(hh$area == "rural",
                 sample(c("purchase", "own_production", "gift"), n_records,
                        replace = TRUE, prob = c(0.84, 0.12, 0.04)),
                 sample(c("purchase", "own_production", "gift"), n_records,
                        replace = TRUE, prob = c(0.95, 0.01, 0.04)))
acquisitions <- data.frame(
  record_id = seq_len(n_records), household_id = hh$household_id,
  food_code = fd$food_code, quantity = quantity, unit = fd$unit,
  section = fd$section, period_days = period, include = TRUE,
  origin = origin,
  # Amount paid, or the value imputed to own production and gifts.
  expenditure_lcu = round(fd$price_lcu * quantity *
                            exp(stats::rnorm(n_records, 0, 0.1)), 2)
)

# Planted defects, at rates of a real survey. Milk sometimes in cups (a
# volume unit without a density for milk); a few records in sacks (a unit
# without factor); a few extreme quantities (a zero typed too many: the
# expenditure is not scaled); missing quantities (the amount paid is
# known), missing units; records left out by the section rule of the
# invented adapter.
cups <- which(acquisitions$food_code == "milk_fresh" &
                stats::runif(n_records) < 0.1)
acquisitions$quantity[cups] <- round(acquisitions$quantity[cups] / 0.24)
acquisitions$unit[cups] <- "cup"
pick <- function(rate, among = rep(TRUE, n_records)) {
  which(among & stats::runif(n_records) < rate)
}
sacks <- pick(0.002, acquisitions$unit == "lb")
acquisitions$unit[sacks] <- "sack"
acquisitions$quantity[sacks] <- 1
extreme <- pick(0.001)
acquisitions$quantity[extreme] <- acquisitions$quantity[extreme] * 10
acquisitions$quantity[pick(0.003)] <- NA
acquisitions$unit[pick(0.002)] <- NA
acquisitions$include[pick(0.005)] <- FALSE

# Fortifiable vehicle (docs/design-12e5.md, section 2.4): a food of own
# production could not have been fortified by industry; the rule of this
# invented adapter. Set without the random generator.
acquisitions$fortifiable <- !acquisitions$origin %in% "own_production"

# The short food lists.
acquisitions <- acquisitions[acquisitions$food_code %in% short_foods |
                               !acquisitions$household_id %in% short_list, ]
acquisitions$record_id <- seq_len(nrow(acquisitions))
rownames(acquisitions) <- NULL
stopifnot(all(short_list %in% acquisitions$household_id))

# Expenditure groups ------------------------------------------------------

# Weighted quintiles (household weights) of food expenditure per member and
# day. A household that answered the module and acquired nothing spends 0;
# a household that did not answer has no group (its food expenditure is
# unknown).
spent <- tapply(acquisitions$expenditure_lcu / acquisitions$period_days,
                acquisitions$household_id, sum)
per_member <- unname(spent[as.character(households$household_id)]) / size
per_member[households$household_id %in% empty] <- 0
weighted_quintile <- function(x, w) {
  ok <- !is.na(x)
  o <- order(x[ok])
  share <- cumsum(w[ok][o]) / sum(w[ok])
  group <- rep(NA_character_, length(x))
  group[which(ok)[o]] <- paste0("Q", pmin(5L, ceiling(share * 5 - 1e-9)))
  group
}
households$expenditure_group <- weighted_quintile(per_member,
                                                  households$weight)

# User tables -------------------------------------------------------------

invented <- "synthetic: invented"

# Unit factors. Volume units have a density only for named foods, so milk
# in cups has none; "sack" has no factor at all.
counted <- c(bread = 60, plantain = 280, sardines_canned = 125,
             egg = 50, evaporated_milk = 410, avocado = 250,
             local_herb = 80, leafy_greens = 250, banana = 120,
             orange = 180, mango = 250)
count_unit_of <- foods$unit[match(names(counted), foods$food_code)]
unit_factors <- data.frame(
  unit = c("lb", "kg", "g", "l", "l", "l", "l", "cup", count_unit_of),
  food_code = c(NA, NA, NA, NA, "milk_fresh", "vegetable_oil", "soft_drink",
                NA, names(counted)),
  factor = c(453.6, 1000, 1, 1000, 1000, 1000, 1000, 240,
             rep(1, length(counted))),
  factor_type = c("mass_g", "mass_g", "mass_g", rep("volume_ml", 5),
                  rep("count", length(counted))),
  density_g_ml = c(NA, NA, NA, NA, 1.03, 0.92, 1.04, NA,
                   rep(NA, length(counted))),
  piece_weight_g = c(rep(NA, 8), unname(counted)),
  source = invented
)

# Crosswalk and composition: one composition row per matched food, and the
# enriched wheat flour that enrichment rules refer to.
matched <- !is.na(foods$match_type)
foods$composition_id <- NA_character_
foods$composition_id[matched] <- sprintf("C%02d", seq_len(sum(matched)))
crosswalk <- foods[c("food_code", "composition_id", "match_type",
                     "validated", "edible_portion")]

nutrients <- c(energy = "kcal", iron = "mg", zinc = "mg",
               folate = "ug_dfe", vitamin_a = "ug_rae")
value_cols <- paste(names(nutrients), nutrients, sep = "_")
composition <- rbind(
  foods[matched, c("composition_id", "description", value_cols,
                   "food_state", "fortified")],
  data.frame(composition_id = "C90", description = "wheat flour, enriched",
             energy_kcal = 364, iron_mg = 4.4, zinc_mg = 0.7,
             folate_ug_dfe = 290, vitamin_a_ug_rae = 0, food_state = "raw",
             fortified = TRUE)
)
composition$basis <- "per_100g_edible"
composition$source <- invented
rownames(composition) <- NULL

# What enrichment added. The pasta is made of flour only: enriched flour
# (C90) against unfortified flour at fraction 1. The breakfast cereal gives
# the amounts added per 100 g directly.
id_of <- function(food) foods$composition_id[foods$food_code == food]
enrichment <- data.frame(
  composition_id = c(rep(id_of("pasta"), 2), rep(id_of("breakfast_cereal"),
                                                 4)),
  nutrient = c("iron", "folate", "iron", "zinc", "folate", "vitamin_a"),
  enriched_ref_id = c("C90", "C90", NA, NA, NA, NA),
  unenriched_ref_id = c(rep(id_of("wheat_flour"), 2), NA, NA, NA, NA),
  ingredient_fraction = c(1, 1, NA, NA, NA, NA),
  added = c(NA, NA, 10, 4, 400, 250),
  source = invented
)

# Vehicles: up to two per food.
v1 <- foods[!is.na(foods$vehicle), c("food_code", "vehicle",
                                     "vehicle_group", "vehicle_fraction")]
v2 <- foods[!is.na(foods$vehicle_2), c("food_code", "vehicle_2",
                                       "vehicle_fraction_2")]
names(v2) <- c("food_code", "vehicle", "vehicle_fraction")
v2$vehicle_group <- NA_character_
vehicles <- rbind(v1, v2[names(v1)])
vehicles$source <- invented
rownames(vehicles) <- NULL

# Scenarios: five, each adding to the one before. Levels and compliance are
# invented, not taken from any standard; they were tuned so that only folic
# acid passes its upper level, and only once rice is fortified (rice has
# no zinc).
level_rows <- function(scenario, vehicle, compliance, iron_compound,
                       folic_acid = 2, zinc = 20) {
  rows <- data.frame(
    scenario = scenario, vehicle = vehicle,
    nutrient = c("iron", "zinc", "folate"),
    level_mg_kg = c(40, zinc, folic_acid), level_basis = "nutrient",
    compound = c(iron_compound, "zinc oxide", NA),
    form = c(NA, NA, "folic_acid"), nutrient_fraction = NA_real_,
    compliance = compliance, source = invented
  )
  rows[!is.na(rows$level_mg_kg), ]
}
vitamin_a <- data.frame(
  vehicle = c("sugar", "oil"), nutrient = "vitamin_a",
  level_mg_kg = c(10, 6), level_basis = c("compound", "nutrient"),
  compound = c("vitamin A compound (invented)", NA), form = "retinol",
  nutrient_fraction = c(0.5, NA), compliance = c(0.7, 0.9),
  source = invented
)
wheat <- do.call(rbind, lapply(c("wheat_flour", "bread", "pasta"),
                               level_rows, scenario = "wheat_flour",
                               compliance = 0.8,
                               iron_compound = "ferrous fumarate"))
maize <- level_rows("x", "maize_flour", 0.6, "sodium iron EDTA")
rice <- level_rows("x", "rice", 0.5, "ferric pyrophosphate",
                   folic_acid = 4, zinc = NA)
stack <- list(wheat, maize, rice, vitamin_a[1, ], vitamin_a[2, ])
names_s <- c("wheat_flour", "plus_maize", "plus_rice", "plus_sugar",
             "plus_oil")
scenarios <- do.call(rbind, lapply(seq_along(names_s), function(k) {
  rows <- do.call(rbind, lapply(stack[seq_len(k)], function(r) {
    r$scenario <- names_s[[k]]
    r[c("scenario", names(r)[names(r) != "scenario"])]
  }))
  rows
}))
rownames(scenarios) <- NULL

food_groups <- foods[!is.na(foods$food_group), c("food_code", "food_group")]
food_groups$source <- invented
rownames(food_groups) <- NULL

# Save --------------------------------------------------------------------

households$wealth <- NULL
households <- households[c("household_id", "weight", "stratum", "psu",
                           "food_module_response", "region", "area",
                           "expenditure_group")]
hces_example <- list(
  households = households, members = members, acquisitions = acquisitions,
  unit_factors = unit_factors, crosswalk = crosswalk,
  nutrients = nutrients, composition = composition, enrichment = enrichment,
  vehicles = vehicles, scenarios = scenarios, food_groups = food_groups
)
save(hces_example, file = "data/hces_example.rda", compress = "xz",
     version = 2)
