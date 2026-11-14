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

# Part 2 (12d.8): acquisitions from `foods`, expenditure groups (weighted
# quintiles of food expenditure per member), unit factors, crosswalk,
# composition, enrichment, vehicles, scenarios, food groups, and save().
