# Build the reference tables shipped with hcesfort.
#
# Values come from the CSV files of this directory; their sources are listed
# in data-raw/SOURCES.md. Only rows with status "verified" are shipped; the
# `status` column is dropped. The md5 of every CSV must match data-raw/MD5,
# so a value cannot change without a deliberate update of the registry.
#
# Run from the package root: Rscript data-raw/reference.R

csv_md5_ok <- function(dir = "data-raw") {
  registry <- utils::read.table(file.path(dir, "MD5"),
                                col.names = c("md5", "file"))
  actual <- unname(tools::md5sum(file.path(dir, registry$file)))
  bad <- registry$file[actual != registry$md5]
  if (length(bad) > 0) {
    stop("md5 differs from data-raw/MD5: ", paste(bad, collapse = ", "))
  }
  invisible(TRUE)
}

# Read one CSV and keep its verified rows, without the status column.
read_reference <- function(file, dir = "data-raw") {
  x <- utils::read.csv(file.path(dir, file), stringsAsFactors = FALSE,
                       encoding = "UTF-8", na.strings = "")
  stopifnot(all(x$status %in% c("verified", "pending")))
  x <- x[x$status == "verified", setdiff(names(x), "status")]
  rownames(x) <- NULL
  dplyr::as_tibble(x)
}

# Name of each shipped table and its CSV.
reference_files <- c(
  ref_requirements = "requirements.csv",
  ref_iron_requirements = "iron_requirement_percentiles.csv",
  ref_energy_requirements = "energy_requirements.csv",
  ref_bmr_equations = "bmr_equations.csv",
  ref_conversions = "nutrient_conversions.csv",
  ref_who2009_flour = "who2009_wheat_flour_levels.csv"
)

if (sys.nframe() == 0L) {
  csv_md5_ok()
  for (name in names(reference_files)) {
    assign(name, read_reference(reference_files[[name]]))
    save(list = name, file = file.path("data", paste0(name, ".rda")),
         compress = "xz", version = 2)
  }
}
