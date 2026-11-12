# inadequacy(). Fixture: as_run() of helper-scenario.R. Intake per AFE:
# baseline h1 iron 1, folate 20; h2 iron 0.5, folate 10; h3 not estimated.
# s1: h1 iron 6.5, folate 326; h2 iron 3.25, folate 163. s2: h1 vitamin A
# 100, iron as baseline.
# Invented requirements: iron EAR 3 mg, folate 320 ug DFE, vitamin A 50.
# Invented iron distribution: P2.5 2 mg, P50 4 mg, P97.5 8 mg at b0 = 0.2.
in_req <- function(iron = 3, folate = 320, vitamin_a = 50) {
  data.frame(nutrient = c("iron", "folate", "vitamin_a", "zinc"),
             unit = c("mg", "ug_dfe", "ug_rae", "mg"),
             ear = c(iron, folate, vitamin_a, 6), cutpoint_valid = TRUE)
}

in_dist <- function(k = 1) {
  data.frame(group = "women", percentile = c(2.5, 50, 97.5),
             requirement_mg_d = c(2, 4, 8) * k, bioavailability = 0.2)
}

risk <- function(r, scenario, h, nutrient, b = NA) {
  f <- r$scenario == scenario & r$household_id == h &
    r$nutrient == nutrient & (is.na(b) | r$bioavailability %in% b)
  r$p_inadequate[f]
}

test_that("cut-point by hand for two nutrients and two scenarios", {
  r <- inadequacy(as_run(), in_req(), min_coverage = 0.9, min_records_used = 0)
  expect_s3_class(r, c("hces_inadequacy", "hces_tbl"))
  expect_identical(risk(r, "baseline", 1, "iron"), 1)
  expect_identical(risk(r, "s1", 1, "iron"), 0)
  expect_identical(risk(r, "s1", 2, "iron"), 0)
  expect_identical(risk(r, "s1", 1, "folate"), 0)
  expect_identical(risk(r, "s1", 2, "folate"), 1)
  expect_identical(risk(r, "s2", 1, "vitamin_a"), 0)
  expect_identical(risk(r, "s1", 3, "iron"), NA_real_)
  expect_identical(unique(r$method), "ear_cutpoint")
  expect_equal(r$added[r$scenario == "s1" & r$household_id == 1 &
                         r$nutrient == "folate"], 306)
  expect_false("zinc" %in% r$nutrient)
})

test_that("an intake equal to the EAR is adequate; intake 0 is not", {
  r <- inadequacy(as_run(), in_req(iron = 6.5), min_coverage = 0,
                  min_records_used = 0)
  expect_identical(risk(r, "s1", 1, "iron"), 0)
  expect_identical(risk(r, "baseline", 1, "vitamin_a"), 1)
})

test_that("probability approach by hand, two bioavailabilities", {
  r <- inadequacy(as_run(), in_req(), distribution = list(iron = in_dist()),
                  bioavailability = list(iron = c(0.1, 0.2)),
                  min_coverage = 0.9, min_records_used = 0)
  iron <- r[r$nutrient == "iron", ]
  expect_identical(unique(iron$method), "probability")
  expect_identical(nrow(iron), 3L * 3L * 2L)
  expect_identical(risk(r, "baseline", 1, "iron", 0.2), 1)
  # 6.5 between P50 and P97.5: F = 0.5 + 2.5 / 4 x 0.475.
  expect_equal(risk(r, "s1", 1, "iron", 0.2), 1 - (0.5 + 2.5 / 4 * 0.475))
  # At b = 0.1: 3.25 between P2.5 and P50: F = 0.025 + 1.25 / 2 x 0.475.
  expect_equal(risk(r, "s1", 1, "iron", 0.1), 1 - (0.025 + 1.25 / 2 * 0.475))
  expect_true(all(is.na(iron$ear)))
})

test_that("the six probabilities of the shipped table (design, section 3)", {
  d <- subset(ref_iron_requirements, group == "females_menstruating_adult")
  t <- distribution_table(d, "iron", "mg", NULL)
  expect_equal(p_inadequate_probability(c(4, 4.42, 8.07, 18.23, 19), 0.18, t),
               c(1, 0.975, 0.5, 0.025, 0))
  expect_equal(p_inadequate_probability(14.526, 0.10, t), 0.5)
})

test_that("an hces_intake works and has no scenario", {
  p <- as_pipeline()
  r <- inadequacy(p$intake, in_req(), min_coverage = 0, min_records_used = 0)
  expect_true(all(is.na(r$scenario)))
  expect_identical(r$added[r$household_id == 1], c(0, 0, 0))
  expect_identical(r$added[r$household_id == 3], c(NA_real_, NA, NA))
})

test_that("the audit log counts by hand", {
  r <- inadequacy(as_run(), in_req(), distribution = list(iron = in_dist()),
                  bioavailability = list(iron = 0.2), min_coverage = 0,
                  min_records_used = 0)
  log <- audit_log(r)
  log <- log[log$step == "inadequacy", ]
  expect_identical(log$n_records[log$cause == "all"], 9L)
  expect_identical(log$detail[log$cause == "nutrient_without_requirement"],
                   "energy")
  expect_identical(log$detail[log$cause == "requirement_without_nutrient"],
                   "zinc")
  expect_true("iron: probability, b = 0.2" %in% log$detail)
  # Tails at b = b0: baseline 1 and 0.5, s2 1 and 0.5 are below 2 mg.
  expect_identical(log$n_records[log$cause == "tails_fixed"], 4L)
  expect_identical(log$detail[log$cause == "not_estimated"],
                   "no_food_records")
})

test_that("coverage below the minimum is a coverage error", {
  s <- as_run()
  s$iron_mg_coverage[s$household_id == 1] <- 0.5
  # Overall: (0.5 x 240 + 1 x 50) / 290 = 0.586.
  err <- expect_error(inadequacy(s, in_req(), min_coverage = 0.6,
                                 min_records_used = 0),
                      class = "hcesfort_error_coverage")
  expect_identical(err$nutrients, "iron")
  expect_equal(err$coverage, 170 / 290)
  expect_s3_class(inadequacy(s, in_req(), min_coverage = 0.5,
                             min_records_used = 0),
                  "hces_inadequacy")
  expect_error(inadequacy(s, in_req()), class = "hcesfort_error_argument")
  expect_error(inadequacy(s, in_req(), min_coverage = 2, min_records_used = 0),
               class = "hcesfort_error_argument")
})

test_that("requirements: key, units and schema errors", {
  s <- as_run()
  expect_error(inadequacy(s, rbind(in_req(), in_req()), min_coverage = 0,
                          min_records_used = 0),
               class = "hcesfort_error_key")
  req <- in_req()
  req$unit[[1]] <- "ug"
  expect_error(inadequacy(s, req, min_coverage = 0, min_records_used = 0),
               class = "hcesfort_error_units")
  expect_error(inadequacy(s, req[-3], min_coverage = 0, min_records_used = 0),
               class = "hcesfort_error_schema")
  expect_error(inadequacy(as.data.frame(s), in_req(), min_coverage = 0,
                          min_records_used = 0),
               class = "hcesfort_error_audit")
})

test_that("distribution and bioavailability errors", {
  s <- as_run()
  run <- function(d = list(iron = in_dist()), b = list(iron = 0.2)) {
    inadequacy(s, in_req(), distribution = d, bioavailability = b,
               min_coverage = 0, min_records_used = 0)
  }
  two <- rbind(in_dist(), transform(in_dist(), group = "men"))
  expect_error(run(list(iron = two)), class = "hcesfort_error_key")
  bad <- in_dist()
  bad$percentile <- c(50, 2.5, 97.5)
  expect_error(run(list(iron = bad)), class = "hcesfort_error_value")
  bad <- in_dist()
  bad$bioavailability <- c(0.1, 0.2, 0.2)
  expect_error(run(list(iron = bad)), class = "hcesfort_error_value")
  expect_error(run(list(iron = in_dist()[-2])), class = "hcesfort_error_schema")
  expect_error(run(b = NULL), class = "hcesfort_error_argument")
  expect_error(run(b = list(iron = 1.2)), class = "hcesfort_error_argument")
  expect_error(run(list(zinc = in_dist())), class = "hcesfort_error_argument")
  expect_error(inadequacy(s, in_req(), bioavailability = list(iron = 0.2),
                          min_coverage = 0, min_records_used = 0),
               class = "hcesfort_error_argument")
})

test_that("against survey::svymean on a hand-built design", {
  r <- inadequacy(as_run(), in_req(), distribution = list(iron = in_dist()),
                  bioavailability = list(iron = 0.1), min_coverage = 0,
                  min_records_used = 0)
  w <- c(1, 3)
  for (n in c("folate", "iron")) {
    one <- r[r$scenario == "s1" & r$nutrient == n &
               r$intake_status == "estimated", ]
    y <- if (n == "folate") as.numeric(one$intake < 320) else
      1 - stats::approx(c(2, 4, 8), c(0.025, 0.5, 0.975),
                        xout = one$intake * 0.1 / 0.2, yleft = 0,
                        yright = 1)$y
    design <- survey::svydesign(ids = ~1, weights = ~w,
                                data = data.frame(y = y, w = w))
    expect_equal(sum(one$p_inadequate * w) / sum(w),
                 unname(stats::coef(survey::svymean(~y, design))),
                 tolerance = 1e-8)
  }
})

test_that("invariants: bounds and monotonicity", {
  run <- function(p = as_pipeline(), req = in_req(), b = 0.2, k = 1,
                  sc = as_scenarios()) {
    inadequacy(as_run(sc, p), req, distribution = list(iron = in_dist(k)),
               bioavailability = list(iron = b), min_coverage = 0,
               min_records_used = 0)
  }
  r <- run()
  ok <- !is.na(r$p_inadequate)
  expect_true(all(r$p_inadequate[ok] >= 0 & r$p_inadequate[ok] <= 1))
  more <- run(p = as_pipeline(scale = 2))
  expect_true(all(more$p_inadequate[ok] <= r$p_inadequate[ok]))
  lower <- run(req = in_req(folate = 100, vitamin_a = 10))
  expect_true(all(lower$p_inadequate[ok] <= r$p_inadequate[ok]))
  better <- run(b = 0.3)
  expect_true(all(better$p_inadequate[ok] <= r$p_inadequate[ok]))
  base <- r[r$scenario == "baseline", ]
  for (sc in c("s1", "s2")) {
    one <- r[r$scenario == sc, ]
    expect_true(all(one$p_inadequate <= base$p_inadequate, na.rm = TRUE))
  }
  scaled <- run(p = as_pipeline(scale = 3), req = in_req(9, 960, 150), k = 3)
  expect_equal(scaled$p_inadequate, r$p_inadequate)
})

test_that("invariant: b = b0 compares the intake with the table itself", {
  r <- inadequacy(as_run(), in_req(), distribution = list(iron = in_dist()),
                  bioavailability = list(iron = 0.2), min_coverage = 0,
                  min_records_used = 0)
  one <- r[r$nutrient == "iron" & !is.na(r$intake), ]
  f <- stats::approx(c(2, 4, 8), c(0.025, 0.5, 0.975), xout = one$intake,
                     yleft = 0, yright = 1)$y
  expect_equal(one$p_inadequate, 1 - f)
})

test_that("invariant: row order of requirements", {
  r1 <- inadequacy(as_run(), in_req(), min_coverage = 0, min_records_used = 0)
  r2 <- inadequacy(as_run(), in_req()[4:1, ], min_coverage = 0,
                   min_records_used = 0)
  k <- function(r) paste(r$scenario, r$household_id, r$nutrient)
  expect_identical(r2$p_inadequate[match(k(r1), k(r2))], r1$p_inadequate)
})

test_that("no nutrient with an EAR gives no rows; missing intakes stay NA", {
  req <- in_req()
  req$ear <- NA_real_
  r <- inadequacy(as_run(), req, min_coverage = 0, min_records_used = 0)
  expect_identical(nrow(r), 0L)
  expect_s3_class(r, "hces_inadequacy")
  t <- distribution_table(in_dist(), "iron", "mg", NULL)
  expect_identical(p_inadequate_probability(c(NA, NA), 0.2, t),
                   c(NA_real_, NA_real_))
})

# Where the cut-point is not valid (correction 2).
test_that("a nutrient with cutpoint_valid FALSE needs its distribution", {
  req <- in_req()
  req$cutpoint_valid[req$nutrient == "iron"] <- FALSE
  err <- expect_error(inadequacy(as_run(), req, min_coverage = 0,
                                 min_records_used = 0),
                      class = "hcesfort_error_value")
  expect_identical(err$columns, "cutpoint_valid")
  expect_match(conditionMessage(err), "distribution")
  r <- inadequacy(as_run(), req, distribution = list(iron = in_dist()),
                  bioavailability = list(iron = 0.2), min_coverage = 0,
                  min_records_used = 0)
  expect_identical(unique(r$method[r$nutrient == "iron"]), "probability")
  expect_error(inadequacy(as_run(), ref_requirements, min_coverage = 0,
                          min_records_used = 0),
               class = "hcesfort_error_value")
})

test_that("cutpoint_valid is a required, complete logical column", {
  req <- in_req()
  err <- expect_error(inadequacy(as_run(), req[names(req) != "cutpoint_valid"],
                                 min_coverage = 0, min_records_used = 0),
                      class = "hcesfort_error_schema")
  expect_identical(err$columns, "cutpoint_valid")
  req$cutpoint_valid[2] <- NA
  expect_error(inadequacy(as_run(), req, min_coverage = 0,
                          min_records_used = 0),
               class = "hcesfort_error_value")
  req <- in_req()
  req$cutpoint_valid <- "TRUE"
  expect_error(inadequacy(as_run(), req, min_coverage = 0,
                          min_records_used = 0),
               class = "hcesfort_error_value")
  req <- in_req()
  req$ear_bioavailability <- c(0.18, NA, 1.2, NA)
  err <- expect_error(inadequacy(as_run(), req, min_coverage = 0,
                                 min_records_used = 0),
                      class = "hcesfort_error_value")
  expect_identical(err$columns, "ear_bioavailability")
})

test_that("ear_bioavailability is written in the log, rescales nothing", {
  req <- in_req()
  req$ear_bioavailability <- c(0.18, NA, NA, NA)
  r <- inadequacy(as_run(), req, min_coverage = 0, min_records_used = 0)
  plain <- inadequacy(as_run(), in_req(), min_coverage = 0,
                      min_records_used = 0)
  expect_identical(r$p_inadequate, plain$p_inadequate)
  log <- audit_log(r)
  note <- log[log$cause == "ear_assumes_bioavailability", ]
  expect_identical(note$detail, "iron: 0.18")
  r <- inadequacy(as_run(), req, distribution = list(iron = in_dist()),
                  bioavailability = list(iron = 0.2), min_coverage = 0,
                  min_records_used = 0)
  expect_false("ear_assumes_bioavailability" %in% audit_log(r)$cause)
})

test_that("ref_requirements: iron is not a cut-point nutrient", {
  r <- ref_requirements
  expect_identical(r$cutpoint_valid[r$nutrient == "iron"], FALSE)
  expect_equal(r$ear_bioavailability[r$nutrient == "iron"], 0.18)
  expect_true(all(r$cutpoint_valid[r$nutrient != "iron"]))
})
