# This checks the environment and records the planned study extent.
# It does not download data or calculate research findings.
if (!file.exists("MangroveResearch.Rproj")) stop("Open MangroveResearch.Rproj first.")
if (file.exists("renv/activate.R")) source("renv/activate.R")
if (!requireNamespace("sf", quietly = TRUE)) stop("Run scripts/00_setup.R first.")

dir.create("outputs/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

# Analyst-defined rectangle near Demak: a starting extent for data inspection.
# This is not an administrative boundary or a confirmed Living Lab location.
bounds <- sf::st_bbox(c(xmin = 110.40, ymin = -6.95,
                        xmax = 110.65, ymax = -6.70), crs = sf::st_crs(4326))
study_area <- sf::st_sf(
  name = "Provisional Demak coastal study extent",
  boundary_type = "Analyst-defined rectangle; review before analysis",
  geometry = sf::st_as_sfc(bounds)
)
study_area <- sf::st_transform(study_area, 32749) # WGS 84 / UTM zone 49S
stopifnot(all(sf::st_is_valid(study_area)))
sf::st_write(study_area, "data/processed/study_area.gpkg",
             layer = "study_area", delete_layer = TRUE, quiet = TRUE)

log <- c(
  paste("Check time (UTC):", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "Status: project setup only; no mangrove data analyzed.",
  "Study extent: provisional analyst-defined rectangle near Demak, Indonesia.",
  paste("Rectangle area, hectares:", round(as.numeric(sf::st_area(study_area)) / 10000, 1)),
  "The rectangle includes water and land; its area is not mangrove habitat area.",
  "Next: verify source metadata, licensing, coding, and local coverage before analysis."
)
writeLines(log, "outputs/logs/project_check.txt")
cat(paste(log, collapse = "\n"), "\n")
