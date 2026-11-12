# Regression test of the experiment that chose the carrier of the audit log
# (docs/design-task2.md, section 4). It asserts what dplyr, tidyr and base R
# do with the class and the attribute of a carrier. If a new version of one
# of them changes a group, this test shows it; the package itself does not
# depend on these behaviours. Verbs of tidyr and srvyr are added here when
# those packages enter `Imports`.

survives <- function(z) {
  c(class = inherits(z, "hces_tbl"), log = !is.null(attr(z, "audit")))
}

test_that("class and log survive row and column verbs", {
  x <- fixture_carrier()
  other <- data.frame(household_id = c(10L, 20L), region = c("a", "b"))
  ops <- list(
    mutate = function(d) dplyr::mutate(d, kg = qty_g / 1000),
    mutate_by = function(d) {
      dplyr::mutate(d, s = sum(qty_g), .by = household_id)
    },
    filter = function(d) dplyr::filter(d, qty_g > 60),
    arrange = function(d) dplyr::arrange(d, qty_g),
    select = function(d) dplyr::select(d, record_id, qty_g),
    rename = function(d) dplyr::rename(d, grams = qty_g),
    slice = function(d) dplyr::slice(d, 1:2),
    distinct = function(d) dplyr::distinct(d, household_id),
    left_join = function(d) dplyr::left_join(d, other, by = "household_id"),
    bind_rows = function(d) dplyr::bind_rows(d, d),
    subset_rows = function(d) d[1:2, ],
    dollar_assign = function(d) {
      d$kg <- d$qty_g / 1000
      d
    },
    rds = function(d) {
      path <- withr::local_tempfile(fileext = ".rds")
      saveRDS(d, path)
      readRDS(path)
    }
  )
  for (op in names(ops)) {
    expect_identical(survives(ops[[op]](x)), c(class = TRUE, log = TRUE),
                     info = op)
  }
})

test_that("class is lost and log survives in some verbs", {
  x <- fixture_carrier()
  ops <- list(
    group_by = function(d) dplyr::group_by(d, household_id),
    as_tibble = dplyr::as_tibble,
    as_data_frame = as.data.frame
  )
  for (op in names(ops)) {
    expect_identical(survives(ops[[op]](x)), c(class = FALSE, log = TRUE),
                     info = op)
  }
})

test_that("class and log are lost by verbs that build a new table", {
  x <- fixture_carrier()
  ops <- list(
    ungroup = function(d) dplyr::ungroup(dplyr::group_by(d, household_id)),
    summarise = function(d) {
      dplyr::summarise(d, s = sum(qty_g), .by = household_id)
    },
    grouped_mutate = function(d) {
      dplyr::mutate(dplyr::group_by(d, household_id), s = sum(qty_g))
    },
    right_side_join = function(d) {
      dplyr::left_join(data.frame(record_id = 1L), d, by = "record_id")
    },
    merge = function(d) merge(d, data.frame(record_id = 1L))
  )
  for (op in names(ops)) {
    expect_identical(survives(ops[[op]](x)), c(class = FALSE, log = FALSE),
                     info = op)
  }
})
