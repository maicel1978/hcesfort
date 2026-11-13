# read_labels(), label_codes(), read_decisions(). Fixtures: small CSV
# files written in a temporary directory.

write_csv_lines <- function(lines) {
  f <- withr::local_tempfile(fileext = ".csv", .local_envir = parent.frame())
  writeLines(enc2utf8(lines), f, useBytes = TRUE)
  f
}

label_lines <- c(
  "type,parent,code,label",
  "nutrient,,iron,Hierro",
  "nutrient,,folate,Folato",
  "scenario,,baseline,Sin fortificación",
  "domain,,region,Región",
  "domain_value,region,south,Sur",
  "domain_value,region,north,Norte",
  "domain_value,zone,north,Norte"
)

test_that("read_labels() reads text, keeps order and UTF-8", {
  x <- read_labels(write_csv_lines(label_lines))
  expect_identical(names(x), c("type", "parent", "code", "label"))
  expect_identical(nrow(x), 7L)
  expect_true(all(vapply(x, is.character, logical(1))))
  expect_identical(x$label[[3]], "Sin fortificación")
  expect_identical(x$parent[1:4], rep(NA_character_, 4))
  expect_identical(x$code, c("iron", "folate", "baseline", "region",
                             "south", "north", "north"))
})

test_that("codes are text: a numeric code is not converted", {
  x <- read_labels(write_csv_lines(c("type,parent,code,label",
                                     "domain_value,q,01,First",
                                     "domain_value,q,1,One")))
  expect_identical(x$code, c("01", "1"))
  expect_equal(as.character(label_codes(c("1", "01"), x, "domain_value",
                                        "q")), c("One", "First"))
})

test_that("needed codes without a label are all listed in one error", {
  f <- write_csv_lines(label_lines)
  err <- expect_error(
    read_labels(f, needed = list(
      nutrient = c("iron", "zinc", "vitamin_a"),
      domain_value = list(region = c("north", "east"))
    )),
    class = "hcesfort_error_join"
  )
  expect_identical(err$missing$code, c("zinc", "vitamin_a", "east"))
  expect_identical(err$missing$parent, c(NA, NA, "region"))
  expect_match(conditionMessage(err), "nutrient,,zinc,<label>", fixed = TRUE)
  expect_match(conditionMessage(err), "domain_value,region,east,<label>",
               fixed = TRUE)
  expect_s3_class(read_labels(f, needed = list(nutrient = "iron")), "tbl_df")
})

test_that("a repeated key, a repeated label or a wrong parent fail", {
  dup_key <- c(label_lines, "nutrient,,iron,Iron again")
  expect_error(read_labels(write_csv_lines(dup_key)),
               class = "hcesfort_error_key")
  dup_label <- c(label_lines, "nutrient,,zinc,Hierro")
  err <- expect_error(read_labels(write_csv_lines(dup_label)),
                      class = "hcesfort_error_value")
  expect_identical(err$rows, 8L)
  # The same label under two parents is allowed (rows 6 and 7).
  no_parent <- c(label_lines, "domain_value,,east,Este")
  expect_error(read_labels(write_csv_lines(no_parent)),
               class = "hcesfort_error_value")
  with_parent <- c(label_lines, "nutrient,region,zinc,Zinc")
  expect_error(read_labels(write_csv_lines(with_parent)),
               class = "hcesfort_error_value")
  empty <- c(label_lines, "nutrient,,zinc,")
  err <- expect_error(read_labels(write_csv_lines(empty)),
                      class = "hcesfort_error_value")
  expect_identical(err$columns, "label")
})

test_that("a missing file, column or argument fails with its class", {
  expect_error(read_labels(tempfile()), class = "hcesfort_error_argument")
  expect_error(read_labels(), class = "hcesfort_error_argument")
  expect_error(read_labels(write_csv_lines(c("type,code,label",
                                             "nutrient,iron,Iron"))),
               class = "hcesfort_error_schema")
  expect_error(read_labels(write_csv_lines(label_lines), needed = "iron"),
               class = "hcesfort_error_argument")
})

test_that("label_codes() follows table order and never returns a code", {
  x <- read_labels(write_csv_lines(label_lines))
  f <- label_codes(c("north", "south", NA, "north"), x, "domain_value",
                   parent = "region")
  expect_s3_class(f, "factor")
  expect_identical(levels(f), c("Sur", "Norte"))
  expect_identical(as.character(f), c("Norte", "Sur", NA, "Norte"))
  g <- label_codes(c("folate", "iron"), x, "nutrient")
  expect_identical(levels(g), c("Hierro", "Folato"))
  only <- label_codes("folate", x, "nutrient")
  expect_identical(levels(only), "Folato")
  err <- expect_error(label_codes(c("iron", "zinc"), x, "nutrient"),
                      class = "hcesfort_error_join")
  expect_identical(err$missing$code, "zinc")
  expect_error(label_codes("east", x, "domain_value", parent = "region"),
               class = "hcesfort_error_join")
  expect_error(label_codes("iron", x, c("a", "b")),
               class = "hcesfort_error_argument")
  expect_error(label_codes("iron", x[, -4], "nutrient"),
               class = "hcesfort_error_schema")
})

test_that("read_decisions() reads and checks the decisions", {
  lines <- c("decision,choice,evidence",
             "Outliers,Kept,\"Few records, none implausible\"",
             "Unit factor of sack,45 kg,Market survey")
  d <- read_decisions(write_csv_lines(lines))
  expect_identical(names(d), c("decision", "choice", "evidence"))
  expect_identical(d$evidence[[1]], "Few records, none implausible")
  expect_error(read_decisions(tempfile()), class = "hcesfort_error_argument")
  expect_error(read_decisions(write_csv_lines(c("decision,choice",
                                                "a,b"))),
               class = "hcesfort_error_schema")
  expect_error(read_decisions(write_csv_lines(c(lines, "Outliers,x,y"))),
               class = "hcesfort_error_key")
  err <- expect_error(read_decisions(write_csv_lines(c(lines, "Other,,y"))),
                      class = "hcesfort_error_value")
  expect_identical(err$columns, "choice")
  expect_error(read_decisions(write_csv_lines("decision,choice,evidence")),
               class = "hcesfort_error_value")
})

test_that("the schemas of labels and decisions are public", {
  expect_identical(hces_schema("labels")$column,
                   c("type", "parent", "code", "label"))
  expect_identical(hces_schema("decisions")$key, c(TRUE, FALSE, FALSE))
})
