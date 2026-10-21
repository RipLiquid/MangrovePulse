# Indonesia Mangrove Trends: a reproducible country-level pilot.
# Run with: Rscript --vanilla scripts/02_country_analysis.R
# One dependency, readxl, reads the original publisher workbook.
if (!file.exists("MangroveResearch.Rproj")) stop("Run from the project folder.")
dir.create(".r-library", showWarnings = FALSE)
.libPaths(c(normalizePath(".r-library"), .libPaths()))
if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", lib = ".r-library", repos = "https://cloud.r-project.org")
}
for (folder in c("data/raw", "data/processed", "outputs/figures", "outputs/tables",
                 "outputs/logs", "reports")) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
}

# 1. Acquire a pinned source and verify its identity before reading.
source_url <- paste0("https://zenodo.org/records/21346457/files/",
  "gmw_v4_timeseries_4112_gmw_country_stats_corr_area_formatted.xlsx?download=1")
input <- "data/raw/gmw_v4_timeseries_4112_gmw_country_stats_corr_area_formatted.xlsx"
expected_md5 <- "30800462dcd06a184df33aa66e0337a2"
options(timeout = 180)
if (!file.exists(input)) download.file(source_url, input, mode = "wb")
if (unname(tools::md5sum(input)) != expected_md5) {
  stop("Source checksum mismatch. Verify the download; do not analyze a partial file.")
}

# 2. Read each sheet and reshape wide country-year data to tidy records.
# Exclude footer totals and blank rows using the source's ISO identifier.
tidy_sheet <- function(sheet, value_name) {
  raw <- as.data.frame(readxl::read_excel(input, sheet = sheet))
  raw <- raw[!is.na(raw$iso) & nzchar(raw$iso), , drop = FALSE]
  if (anyDuplicated(raw$iso)) stop("Duplicate country identifier in ", sheet)
  year_names <- names(raw)[grepl("^[12][0-9]{3}$", names(raw))]
  if (!identical(as.integer(year_names), 1985:2025)) stop("Unexpected year coverage.")
  out <- do.call(rbind, lapply(year_names, function(y) {
    values <- suppressWarnings(as.numeric(raw[[y]]))
    if (any(!is.finite(values)) || any(values < 0)) stop("Missing or invalid extent in ", sheet)
    data.frame(iso = raw$iso, country = raw$cnty_name, year = as.integer(y), value = values)
  }))
  names(out)[4] <- value_name
  out
}
extent <- tidy_sheet("Extent", "extent_ha")
lower <- tidy_sheet("lower95th", "lower95_ha")
upper <- tidy_sheet("upper95th", "upper95_ha")
key <- c("iso", "country", "year")
all_data <- merge(merge(extent, lower, by = key), upper, by = key)
if (nrow(all_data) != nrow(extent)) stop("Unmatched country-year keys.")
stopifnot(all(all_data$lower95_ha <= all_data$extent_ha),
          all(all_data$extent_ha <= all_data$upper95_ha))
all_data <- all_data[order(all_data$iso, all_data$year), ]
write.csv(all_data, "data/processed/country_extent_tidy.csv", row.names = FALSE)

# 3. Focus on Indonesia after 2000 to reduce reliance on earlier infilled years.
idn <- all_data[all_data$iso == "IDN" & all_data$year >= 2000, ]
stopifnot(nrow(idn) == 26, identical(idn$year, 2000:2025))
idn$annual_net_change_ha <- c(NA_real_, diff(idn$extent_ha))
idn$index_2000 <- 100 * idn$extent_ha / idn$extent_ha[1]
write.csv(idn, "outputs/tables/indonesia_trend.csv", row.names = FALSE)

get_extent <- function(iso, year) {
  x <- all_data$extent_ha[all_data$iso == iso & all_data$year == year]
  if (length(x) != 1L) stop("Expected exactly one country-year observation.")
  x
}
start <- get_extent("IDN", 2000)
latest <- get_extent("IDN", 2025)
net_change <- latest - start
pct_change <- 100 * (latest / start - 1)
recent_rate <- (latest / get_extent("IDN", 2015))^(1 / 10) - 1

# A disclosed, fixed comparison group, not all Southeast Asian countries.
peers <- c("IDN", "MYS", "PHL", "VNM", "THA", "MMR")
comparison <- do.call(rbind, lapply(peers, function(code) {
  x <- all_data[all_data$iso == code & all_data$year >= 2000, ]
  data.frame(iso = code, country = x$country[1], year = x$year,
             index_2000 = 100 * x$extent_ha / x$extent_ha[1])
}))
write.csv(comparison, "outputs/tables/peer_comparison.csv", row.names = FALSE)

# 4. Deterministic sensitivity scenarios. No causal effect or forecast is claimed.
# +/- 0.10 percentage points is an analyst-selected change to the annual rate.
rate_offset <- 0.001
assumptions <- data.frame(
  scenario = c("Recent rate continues", "Rate minus 0.10 pp", "Rate plus 0.10 pp"),
  annual_rate = recent_rate + c(0, -rate_offset, rate_offset)
)
scenarios <- do.call(rbind, lapply(seq_len(nrow(assumptions)), function(i) {
  years <- 2025:2035
  data.frame(scenario = assumptions$scenario[i], year = years,
    annual_rate = assumptions$annual_rate[i],
    extent_ha = latest * (1 + assumptions$annual_rate[i])^(years - 2025))
}))
write.csv(assumptions, "outputs/tables/scenario_assumptions.csv", row.names = FALSE)
write.csv(scenarios, "outputs/tables/scenarios.csv", row.names = FALSE)

# 5. Charts use base R so rerunning requires no plotting framework.
ink <- "#173B35"
green <- "#167D64"
gold <- "#B37B24"
red <- "#B65B4D"
chart <- function(path, draw) {
  png(path, width = 1600, height = 920, res = 160, bg = "#FAFCF9")
  on.exit(dev.off())
  par(mar = c(6.2, 5.3, 4.5, 1.5), col.axis = ink, col.lab = ink,
      col.main = ink, family = "sans", las = 1, bty = "l")
  draw()
}
chart("outputs/figures/01_indonesia_trend.png", function() {
  plot(idn$year, idn$extent_ha / 1e6, type = "n",
    ylim = range(c(idn$lower95_ha, idn$upper95_ha)) / 1e6,
    xlab = "Year", ylab = "Mangrove extent (million hectares)",
    main = "Indonesia: mangrove extent, 2000-2025")
  polygon(c(idn$year, rev(idn$year)), c(idn$lower95_ha, rev(idn$upper95_ha)) / 1e6,
    col = "#D7E8DF", border = NA)
  lines(idn$year, idn$extent_ha / 1e6, col = green, lwd = 3)
  points(idn$year, idn$extent_ha / 1e6, pch = 16, cex = 0.45, col = green)
  legend("topright", c("Corrected extent estimate", "Provider 95% interval for extent"),
    col = c(green, "#D7E8DF"), lwd = c(3, 10), bty = "n", cex = 0.8)
  mtext("Source: Global Mangrove Watch v4.1.12. Intervals do not quantify uncertainty in change.",
    side = 1, line = 4.8, cex = 0.66, col = ink)
})
chart("outputs/figures/02_peer_comparison.png", function() {
  colors <- c(green, "#4675A6", gold, "#8D6297", red, "#6C7E65")
  plot(range(comparison$year), range(comparison$index_2000), type = "n",
    xlab = "Year", ylab = "Extent index (2000 = 100)",
    main = "Mangrove trends across six selected countries")
  abline(h = 100, col = "#CDD6CF", lty = 2)
  for (i in seq_along(peers)) {
    x <- comparison[comparison$iso == peers[i], ]
    lines(x$year, x$index_2000, col = colors[i], lwd = if (i == 1) 3 else 1.7)
  }
  labels <- vapply(peers, function(code) comparison$country[comparison$iso == code][1], character(1))
  legend("bottomleft", labels, col = colors, lwd = 2, bty = "n", cex = 0.75, ncol = 2)
  mtext("Source: GMW v4.1.12. Relative change does not compare absolute habitat area.",
    side = 1, line = 4.8, cex = 0.7, col = ink)
})
chart("outputs/figures/03_scenario_sensitivity.png", function() {
  colors <- c(green, red, gold)
  plot(range(scenarios$year), range(scenarios$extent_ha) / 1e6, type = "n",
    xlab = "Year", ylab = "Conditional extent (million hectares)",
    main = "How sensitive is 2035 extent to the assumed annual rate?")
  for (i in seq_len(nrow(assumptions))) {
    x <- scenarios[scenarios$scenario == assumptions$scenario[i], ]
    lines(x$year, x$extent_ha / 1e6, col = colors[i], lwd = 2.5, lty = i)
  }
  legend("topleft", assumptions$scenario, col = colors, lwd = 2.5, lty = 1:3, bty = "n", cex = 0.8)
  mtext("Analyst-selected rate assumptions, not predictions or estimated restoration impacts.",
    side = 1, line = 4.8, cex = 0.7, col = ink)
})

# 6. Generate a portable HTML brief alongside documented numeric results.
fmt <- function(x) format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE)
summary <- data.frame(metric = c("extent_2000_ha", "extent_2025_ha", "net_change_ha",
  "net_change_percent", "annual_compound_rate_2015_2025_percent"),
  value = c(start, latest, net_change, pct_change, 100 * recent_rate))
write.csv(summary, "outputs/tables/key_results.csv", row.names = FALSE)
direction <- if (net_change < 0) "decrease" else "increase"
headline <- sprintf("Indonesia's estimated mangrove extent shows a %.2f%% net %s between 2000 and 2025.",
                    abs(pct_change), direction)
recent <- sprintf("The 2015-2025 compound annual rate is %+.3f%%. This recent rate need not persist.", 100 * recent_rate)
html <- c('<!doctype html><html lang="en"><meta charset="utf-8">',
  '<meta name="viewport" content="width=device-width,initial-scale=1">',
  '<title>Indonesia Mangrove Trends</title><style>',
  'body{margin:0;background:#eef3ee;color:#173b35;font:17px/1.65 system-ui,sans-serif}',
  'main{max-width:1000px;margin:36px auto;padding:40px;background:#fff;border-radius:16px}',
  'h1{font-size:42px;line-height:1.12;letter-spacing:-1px}h2{margin-top:35px;font-size:25px}',
  '.eyebrow{color:#167d64;font-weight:700;letter-spacing:2px;font-size:12px}',
  '.cards{display:flex;gap:16px;flex-wrap:wrap}.card{background:#edf5ef;padding:20px;flex:1;min-width:190px}',
  '.number{font-size:30px;font-weight:750;display:block}img{width:100%;height:auto}',
  'a{color:#167d64}.note{font-size:14px;color:#4c655d}li{margin:7px 0}',
  '@media(max-width:650px){main{padding:22px;margin:10px}h1{font-size:32px}}',
  '</style><main><div class="eyebrow">INDEPENDENT RESEARCH PILOT / R ANALYSIS</div>',
  '<h1>Indonesia Mangrove Trends</h1><p>Historical change, regional context, and scenario sensitivity.</p>',
  paste0('<p><strong>', headline, '</strong></p><div class="cards">'),
  paste0('<div class="card">2000 extent<span class="number">', fmt(start), '</span>hectares</div>'),
  paste0('<div class="card">2025 extent<span class="number">', fmt(latest), '</span>hectares</div>'),
  paste0('<div class="card">Net change<span class="number">', fmt(net_change), '</span>hectares</div></div>'),
  '<h2>Research question</h2><p>How has Indonesia\'s estimated mangrove extent changed since 2000, how does its relative trajectory compare with five selected regional countries, and how sensitive are conditional 2035 values to assumed annual rates?</p>',
  '<h2>Historical change and uncertainty</h2><img src="../outputs/figures/01_indonesia_trend.png" alt="Indonesia historical extent with provider intervals">',
  paste0('<p>', recent, '</p>'),
  '<p>Annual national totals measure net change. They cannot locate local habitat loss, quantify gross loss and gain, or establish the causes of change.</p>',
  '<h2>Regional comparison</h2><img src="../outputs/figures/02_peer_comparison.png" alt="Indexed trends for six selected countries">',
  '<p>Indexing to 100 in 2000 makes relative trajectories comparable. The comparison group is fixed in advance: Indonesia, Malaysia, the Philippines, Viet Nam, Thailand, and Myanmar. It is not a complete regional ranking.</p>',
  '<h2>Scenario sensitivity</h2><img src="../outputs/figures/03_scenario_sensitivity.png" alt="Conditional rate scenarios for 2025 to 2035">',
  '<p>Each scenario starts from the 2025 estimate. Extent equals the starting value multiplied by (1 + annual rate) raised to years elapsed. The baseline uses the 2015-2025 compound rate. Alternatives adjust it by plus or minus 0.10 percentage points per year. These deterministic assumptions have no assigned probability and do not estimate any intervention\'s impact.</p>',
  '<h2>Methods and checks</h2><ul><li>Read the original three-sheet workbook in R using readxl. Verify its published MD5 checksum.</li>',
  '<li>Remove footer totals and blank rows, reshape country-year values, join estimates and intervals on keys, and validate uniqueness, completeness, nonnegative values, and ordered intervals.</li>',
  '<li>Retain all 41 source years in the cleaned table. Use 2000-2025 for the focal analysis and calculate changes directly from source estimates.</li>',
  '<li>Export tidy data, numeric results, scenario assumptions, figures, session information, and this report from one script.</li></ul>',
  '<h2>Interpretation and next research step</h2><p>Use the national trend to motivate local investigation. A next phase would map gross change within a small study area, examine observation quality, and integrate hydrological and community evidence before evaluating restoration sites.</p>',
  '<h2>Limitations</h2><p>This is descriptive country-level analysis. Published intervals apply to extent estimates; differences between years require temporal error covariance for an appropriate change interval. Do not treat overlapping intervals as a significance test. The source applies a global accuracy-based area correction and includes temporally filtered and infilled estimates, so local accuracy and year-to-year independence are not assured. National patterns cannot demonstrate restoration effectiveness, biodiversity change, carbon outcomes, or community benefits.</p>',
  '<h2>Source</h2><p>Bunting et al. (2026), <a href="https://zenodo.org/records/21346457">Global Mangrove Watch: Timeseries of Mangrove Extent, v4.1.12</a>. Country extent and provider 95% intervals, in hectares. CC BY 4.0. Accessed October, 2026.</p>',
  '</html>')
writeLines(html, "reports/research_brief.html", useBytes = TRUE)
writeLines(c(headline, recent, "", "Scope: country-level descriptive analysis and deterministic sensitivity scenarios.",
             "No site prioritization or field validation has been completed."), "reports/key_findings.txt")
writeLines(capture.output(sessionInfo()), "outputs/logs/country_analysis_session.txt")
write.csv(data.frame(source_url = source_url, md5 = expected_md5,
  package_readxl = as.character(packageVersion("readxl")),
  run_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "outputs/logs/run_manifest.csv", row.names = FALSE)
cat("\n", headline, "\n", recent, "\n\nCreated reports/research_brief.html and 3 figures.\n")
