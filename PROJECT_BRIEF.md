> Status update: the deadline version is a completed country-level pilot. See README.md and scripts/02_country_analysis.R. The spatial work below is a future roadmap, not completed research.

# Mangrove Change and Conservation Priorities in Indonesia

An independent R research portfolio project for the I-CAN Research Data Analyst Intern application. This is a planned study, not completed research or an I-CAN collaboration.

## Research question

Where has mapped mangrove cover changed within one Indonesian coastal study area, and how do priorities for field assessment change when we emphasize historical loss, remaining habitat, or habitat connectivity?

## Scope

Build a reproducible analysis for one small study area, provisionally a coastal area in Demak Regency, Central Java. Confirm coverage, data access, and boundary suitability before fixing the location. Use two comparable years from the same Global Mangrove Watch release, adding intermediate years only after the core analysis works. Do not expand to all Indonesia or combine peatlands and mangroves.

## Data and scientific boundaries

- Use Global Mangrove Watch v4.1.12, pinned to https://zenodo.org/records/21346457, provisionally comparing 2000 and 2020. The publisher now recommends v4.1 over the initially proposed v3.0 for most users. These are mapped estimates; the provider documents temporal filtering and infilling of missing observations. See data/SOURCE_NOTES.md.
- Verify download access, licensing, spatial resolution, class definitions, and coverage before implementation. Record exact files, release, years, URLs, access dates, and checksums in a data manifest.
- Choose a documented boundary or a clearly disclosed analyst-defined study extent. Use an appropriate local projected coordinate system for area and distance calculations, and align rasters before comparison.
- Treat missing cells separately from mapped absence. Report gross mapped loss, gross mapped gain, persistent cover, and net change separately.
- A pixel classified as loss is not proof of a viable restoration site. Tidal conditions, tenure, land use, community preferences, and field validation are needed to assess feasibility.
- Connectivity and habitat area are screening indicators, not direct measurements of biodiversity. Do not invent local household data, restoration costs, carbon benefits, or ecological outcomes.
- If a socio-economic extension is feasible, use a documented public settlement or population layer and describe it as a proxy for potential human exposure or proximity. It cannot establish community benefits, consent, or equity.

## Core analytical workflow

1. Import and audit inputs: check missingness, geometry, coordinate systems, raster alignment, and study-area coverage.
2. Clip the data to the study area and calculate change categories and areas in hectares. Quantify valid observed area at both dates.
3. Create a modest spatial grid and calculate transparent indicators: historical loss fraction, remaining cover fraction, and distance to remaining mangrove habitat. Document denominators and normalization.
4. Produce separate screening scores for loss-focused field assessment and protection of remaining habitat. Do not imply that the same intervention suits both.
5. Compare three explicitly assumed policy-weight scenarios. Display indicator values alongside scores and show trade-offs; a weighted score alone is not evidence of optimal restoration.
6. Vary assumed weights over a documented range, with a fixed random seed, and report how often each grid cell appears in the highest-priority group. This measures sensitivity to preferences, not satellite classification accuracy or restoration success probability.
7. Check robustness to one alternative grid size. Explain remaining limitations, particularly mapping error and spatial dependence.

## Deliverables

- Reproducible R repository with documented setup and run order.
- Input manifest and data dictionary.
- GeoPackage containing the study boundary, analysis grid, and derived indicators, subject to source licensing.
- Three readable maps: historical cover change, contrasting screening priorities, and priority stability across weight scenarios.
- Two concise charts: cover-change accounting and scenario trade-offs.
- Quarto research report explaining the question, methods, findings, assumptions, and limitations.
- One-page decision brief translating results into recommendations for further investigation.

## Suggested R tools

Use sf and terra for spatial work; dplyr, tidyr, and ggplot2 for analysis and graphics; Quarto for the report; and renv for package reproducibility. Confirm current package documentation when implementing. Add targets or a Shiny explorer only if the core study is complete and reproducible.

## Two-to-three-week schedule

### Week 1: Real data and defensible change estimates

- Day 1: Establish R environment, verify data access and licenses, choose a small study extent.
- Day 2: Obtain inputs and create manifest, dictionary, and quality audit.
- Days 3–4: Implement spatial alignment, valid-data masking, and change accounting.
- Day 5: Produce the first change map and independently check area totals on a small subset.

### Week 2: Decision analysis and communication

- Days 6–7: Build spatial indicators and clearly separate protection from loss-focused assessment.
- Day 8: Compare scenarios and explain their assumptions.
- Day 9: Run weight sensitivity and one grid-size comparison.
- Day 10: Render the report, finalize maps, and draft the decision brief.

### Optional week 3: Strengthen the evidence

- Re-run from a clean R session and resolve setup or path problems.
- Improve captions, limitations, metadata, and repository instructions.
- Add one documented socio-economic proxy only if it answers a clear question.
- Prepare a five-minute walkthrough of the research question, one finding, one trade-off, and one limitation.
- Optional last: add a small Shiny explorer for scenario weights. The report and reproducible analysis take priority.

## Completion criteria

- Every reported result is generated from identifiable real inputs.
- One documented command or script sequence rebuilds the derived outputs after documented data acquisition.
- Area accounting reconciles: net change equals gross gain minus gross loss within the common valid-data footprint.
- Empty inputs, incompatible coordinate systems, and insufficient overlap produce clear errors.
- Maps include units, dates, legends, and source attribution.
- Recommendations distinguish desktop screening from field-validated feasibility.
- The README includes example outputs and an honest account of what the author implemented and learned.

## Why this matches the posting

The core demonstrates R data cleaning, exploratory analysis, reproducible scripts, geospatial database creation, thematic mapping, quantitative decision support, scenario and sensitivity analysis, and research documentation. It does not depend on training a complex machine-learning model or building a large application.

## Application wording after completion

Replace placeholders only with verified outputs: “Built a reproducible R workflow to quantify historical mangrove-cover change in [study area], compare conservation screening scenarios, and assess priority stability under alternative decision weights; communicated findings through geospatial outputs and a research brief.”


