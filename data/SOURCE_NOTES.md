# Source notes for the completed country-level pilot

- Dataset: Global Mangrove Watch: Timeseries of Mangrove Extent.
- Pinned release: 4.1.12, published July 13, 2026.
- Record: https://zenodo.org/records/21346457.
- Retrieved: October 21, 2026.
- License: CC BY 4.0, verified through the Zenodo record API.
- Input: gmw_v4_timeseries_4112_gmw_country_stats_corr_area_formatted.xlsx.
- Verified MD5: 30800462dcd06a184df33aa66e0337a2.
- Sheets: Extent, lower95th, upper95th.
- Grain: country or territory by calendar year, 1985-2025.
- Units: hectares, already corrected using the provider's accuracy assessment.
- Provider documentation: data/raw/PROVIDER_README.txt.

The R workflow preserves the original workbook, removes blank/footer rows, reshapes all source years, and analyzes Indonesia over 2000-2025. The comparison group consists of Indonesia, Malaysia, the Philippines, Viet Nam, Thailand, and Myanmar.

No spatial source files were analyzed in this pilot. The provisional Demak rectangle and spatial prioritization study belong to the future roadmap. The additional downloaded gain/loss archive was not used in the reported findings and is excluded from the portfolio package.

Published extent intervals do not provide temporal covariance for a confidence interval on change. Scenario offsets are explicit analyst assumptions, not estimates from an intervention study. Temporal filtering and infilling limit interpretation of annual observations.

The initial brief proposed v3.0. The publisher now recommends v4.1 for most users, so this workflow uses a single pinned v4.1.12 release throughout.
