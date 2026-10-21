# Integration and regression checks, using base R assertions.
# Run from the repository root: Rscript --vanilla tests/check_analysis.R
# Builds in a temporary directory so tracked outputs are never overwritten.
run_checks <- function() {
  root <- normalizePath(".", winslash = "/")
  stopifnot(file.exists("MangroveResearch.Rproj"))
  scripts <- list.files("scripts", pattern = "\\.R$", full.names = TRUE)
  stopifnot(length(scripts) > 0L)
  invisible(lapply(scripts, parse))
  cat("PASS: all analysis scripts parse.\n")

  local_library <- file.path(root, ".r-library")
  if (dir.exists(local_library)) .libPaths(c(local_library, .libPaths()))
  sandbox <- tempfile("mangrove-ci-")
  dir.create(sandbox)
  on.exit({setwd(root); unlink(sandbox, recursive = TRUE)}, add = TRUE)
  file.copy("MangroveResearch.Rproj", sandbox)
  dir.create(file.path(sandbox, "data/raw"), recursive = TRUE)
  input_name <- "gmw_v4_timeseries_4112_gmw_country_stats_corr_area_formatted.xlsx"
  input <- file.path(root, "data/raw", input_name)
  if (file.exists(input)) file.copy(input, file.path(sandbox, "data/raw", input_name))

  setwd(sandbox)
  env <- new.env(parent = globalenv())
  source(file.path(root, "scripts/02_country_analysis.R"), local = env)

  # Independent regression values verified against the pinned source workbook.
  results <- read.csv("outputs/tables/key_results.csv")
  values <- setNames(results$value, results$metric)
  stopifnot(abs(values[["extent_2000_ha"]] - 3253708.959507783) < 0.01,
            abs(values[["extent_2025_ha"]] - 3146543.546600554) < 0.01,
            abs(values[["net_change_ha"]] - (-107165.4129072288)) < 0.01)
  cat("PASS: headline areas match the pinned source.\n")

  tidy <- read.csv("data/processed/country_extent_tidy.csv")
  stopifnot(!anyDuplicated(tidy[c("iso", "year")]),
            all(is.finite(tidy$extent_ha)), all(tidy$extent_ha >= 0),
            all(tidy$lower95_ha <= tidy$extent_ha),
            all(tidy$extent_ha <= tidy$upper95_ha))
  coverage <- split(tidy$year, tidy$iso)
  stopifnot(all(vapply(coverage, function(y) identical(sort(y), 1985:2025), logical(1))))
  idn <- read.csv("outputs/tables/indonesia_trend.csv")
  stopifnot(identical(idn$year, 2000:2025),
            sum(is.na(idn$annual_net_change_ha)) == 1L,
            abs(sum(idn$annual_net_change_ha, na.rm = TRUE) - values[["net_change_ha"]]) < 0.01)
  peers <- read.csv("outputs/tables/peer_comparison.csv")
  stopifnot(length(unique(peers$iso)) == 6L,
            all(abs(peers$index_2000[peers$year == 2000] - 100) < 1e-9))
  cat("PASS: unique complete records, valid intervals, net-change accounting, and peer baselines.\n")

  scenarios <- read.csv("outputs/tables/scenarios.csv")
  stopifnot(nrow(scenarios) == 33L, all(is.finite(scenarios$extent_ha)),
            all(abs(scenarios$extent_ha[scenarios$year == 2025] - values[["extent_2025_ha"]]) < 0.01))
  endpoint <- scenarios[scenarios$year == 2035, ]
  endpoint <- endpoint[order(endpoint$annual_rate), ]
  stopifnot(all(diff(endpoint$extent_ha) > 0))
  cat("PASS: scenarios share the observed baseline and higher rates yield higher endpoints.\n")

  report <- paste(readLines("reports/research_brief.html", warn = FALSE), collapse = "\n")
  image_tags <- regmatches(report, gregexpr('src="[^"]+\\.png"', report))[[1]]
  stopifnot(length(image_tags) == 3L)
  image_paths <- sub('^src="', "", sub('"$', "", image_tags))
  images <- file.path("reports", image_paths)
  stopifnot(all(file.exists(images)), all(file.info(images)$size > 1000))
  png_signature <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  stopifnot(all(vapply(images, function(p) identical(readBin(p, "raw", n = 8), png_signature), logical(1))))
  cat("PASS: report links resolve to three nonempty PNG images.\n")

  # Negative-path check: changed input bytes must be rejected, not analyzed.
  bad_input <- file.path("data/raw", input_name)
  writeBin(charToRaw("invalid input"), bad_input)
  problem <- tryCatch({source(file.path(root, "scripts/02_country_analysis.R"),
                               local = new.env(parent = globalenv())); NULL}, error = identity)
  stopifnot(inherits(problem, "error"), grepl("checksum mismatch", conditionMessage(problem)))
  cat("PASS: corrupted source input is rejected.\n\nAll checks passed.\n")
}
run_checks()
