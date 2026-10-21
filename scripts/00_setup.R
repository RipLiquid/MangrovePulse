# Run this from the MangroveResearch RStudio project.
# Install packages into this project's library, without changing other projects.
if (!file.exists("MangroveResearch.Rproj")) {
  stop("Open MangroveResearch.Rproj before running this script.")
}

folders <- c("data/raw", "data/processed", "outputs/figures", "outputs/tables",
             "outputs/logs", "reports")
invisible(lapply(folders, dir.create, recursive = TRUE, showWarnings = FALSE))

options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (!file.exists("renv/activate.R")) {
  renv::init(bare = TRUE, restart = FALSE)
} else {
  source("renv/activate.R")
}

packages <- c("sf", "terra", "dplyr", "tidyr", "ggplot2", "jsonlite", "knitr", "rmarkdown")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) renv::install(missing)
renv::snapshot(packages = c("renv", packages), prompt = FALSE)

status <- data.frame(
  package = packages,
  version = vapply(packages, function(x) as.character(utils::packageVersion(x)), character(1))
)
write.csv(status, "outputs/logs/package_versions.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "outputs/logs/session_info.txt")
print(status)
message("Setup complete. Next run source('scripts/01_project_check.R').")
