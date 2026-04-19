# =============================================================================
# R/setup.R  (simplified)
# Shared setup for all Quarto panels in the Peace Atlas.
# Sourced at the top of every .qmd page via:
#   source(here::here("R", "setup.R"))
#
# Requires the pipeline (run_all.R) to have produced:
#   output/pdet_panel_long.rds      — long-format PDET panel
#   output/pdet_munis_geometry.rds  — 170 PDET municipality polygons
#   output/col_munis_geometry.rds   — full Colombia polygons (for basemap)
# =============================================================================

suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
  library(stringr)
  library(leaflet)
  library(leaflet.extras)
  library(plotly)
  library(DT)
  library(spdep)
  library(ggplot2)
  library(scales)
  library(RColorBrewer)
  library(viridis)
  library(patchwork)
  library(glue)
  library(here)
})

sf::sf_use_s2(FALSE)

# ── Paths ─────────────────────────────────────────────────────────────────────
DISS       <- "G:/My Drive/Universidad/PhD/PSU/Dissertation"
OUTPUT_DIR <- file.path(DISS, "output")      # pipeline outputs (new)
PROC_DIR   <- file.path(DISS, "01. data/output")  # legacy processed outputs

# ── Load pre-built panel ──────────────────────────────────────────────────────
# Produced by run_all.R → 04_assemble_panel.R
# One row per (dane_code × year); 170 PDET municipalities.

panel_path <- file.path(OUTPUT_DIR, "pdet_panel_long.rds")
if (!file.exists(panel_path)) {
  warning(glue(
    "Panel not found: {panel_path}\n",
    "Run 'source(\"02. analysis/run_all.R\")' first to build it."
  ))
  panel <- tibble(dane_code = character(), year = integer())
} else {
  panel <- readRDS(panel_path)
}

PDET_CODES <- unique(panel$dane_code)

# ── Load pre-built geometry ───────────────────────────────────────────────────
# Produced by 01_build_geometry.R.
# No GADM download on render — just read the cached file.

load_geo <- function(stem) {
  path <- file.path(OUTPUT_DIR, paste0(stem, ".rds"))
  if (!file.exists(path)) {
    warning(glue("Geometry not found: {path}\nRun 01_build_geometry.R first."))
    return(NULL)
  }
  geo <- readRDS(path)
  if (!inherits(geo, "sf")) geo <- sf::st_as_sf(geo)
  geo
}

col_munis  <- load_geo("col_munis_geometry")   # full Colombia (1,122 munis)
pdet_munis <- load_geo("pdet_munis_geometry")   # 170 PDET only

# ── Metadata table ────────────────────────────────────────────────────────────
# Maps column prefixes → human-readable labels and peace dimensions.
# Add new entries here when new data sources are merged into the panel.

META <- tibble::tribble(
  ~prefix, ~label,                              ~dimension,        ~data_source,

  # ── V: Violence & Conflict ──
  "V_selective_killing",     "Selective Killings",           "negative_peace",  "CNMH",

  "V_massacre",              "Massacres",                    "negative_peace",  "CNMH",
  "V_forced_disappearance",  "Forced Disappearances",       "negative_peace",  "CNMH",
  "V_kidnapping",            "Kidnapping",                   "negative_peace",  "CNMH",
  "V_sexual_violence",       "Sexual Violence",              "negative_peace",  "CNMH",
  "V_landmine",              "Landmines",                    "active_conflict", "CNMH",
  "V_child_recruitment",     "Child Recruitment",            "negative_peace",  "CNMH",
  "V_conflict_events",       "UCDP Conflict Events",         "active_conflict", "UCDP GED v25.1",
  "V_battle_deaths",         "UCDP Battle Deaths",           "active_conflict", "UCDP GED v25.1",
  "V_homicides",             "Homicides (VERDATA)",          "security",        "JEP / VERDATA",
  "V_false_positive",        "False Positive Cases",         "negative_peace",  "CERAC",
  "V_extrajudicial",         "Extrajudicial Executions",     "negative_peace",  "CERAC",
  "V_territorial_control",   "Armed Group Control",          "active_conflict", "Aponte González",
  "V_coca_cultivation",      "Coca Cultivation",             "active_conflict", "Aponte González",
  "V_criminal_pact",         "Criminal Pact (Daly)",         "negative_peace",  "Daly",
  "V_political_violence",    "Political Violence Index",     "negative_peace",  "Daly",

  # ── P: Peacebuilding & Implementation ──
  "P_impl",                  "SIIPO Implementation Index",   "peacebuilding",   "ART / SIIPO",
  "P_pilar1_investment",     "Pilar 1 Investment",           "peacebuilding",   "ART / DNP",
  "P_n_projects",            "ART Construction Projects",    "peacebuilding",   "ART Obras",
  "P_investment_total",      "ART Investment (COP)",         "peacebuilding",   "ART Obras",
  "P_aid_usd",               "International Aid (USD)",      "peacebuilding",   "APC",
  "P_n_interventions",       "APC Interventions",            "peacebuilding",   "APC",
  "P_n_initiatives",         "PDET Peace Initiatives",       "peacebuilding",   "ART / PDET",
  "P_n_memory_initiatives",  "CNMH Memory Initiatives",      "transitional_j",  "CNMH",

  # ── J: Justice & Dispute Resolution ──
  "J_n_justice_rooms",       "Local Justice Rooms (SLJ)",    "inst_peace",      "SLJ Registry",
  "J_slj_present",           "SLJ Presence (binary)",        "inst_peace",      "SLJ Registry",
  "J_n_cases_processed",     "Casas de Justicia Caseloads",  "inst_peace",      "Ministry of Justice",
  "J_n_conciliadores",       "Equity Conciliators",          "positive_peace",  "Conciliadores Registry",
  "J_n_conciliation",        "Conciliation Requests",        "positive_peace",  "Conciliadores Registry",
  "J_n_restitution",         "Land Restitution Sentences",   "transitional_j",  "URT",

  # ── S: Socioeconomic & Structural ──
  "S_pop_total",             "Total Population",             "controls",        "DNP / DANE",
  "S_gdp_percapita",         "GDP per Capita (constant)",    "controls",        "DNP / DANE",
  "S_nbi",                   "Unmet Basic Needs (NBI)",      "controls",        "DNP / DANE",
  "S_ipm",                   "Multidimensional Poverty (IPM)","controls",       "DNP / DANE",
  "S_poverty_headcount",     "Poverty Headcount",            "controls",        "DNP / DANE",
  "S_gini_land",             "Land Gini Index",              "controls",        "IGAC 2023",
  "S_income_total_pc",       "Per Capita Income",            "controls",        "DNP TerriData",
  "S_tax_income_pc",         "Per Capita Tax Revenue",       "controls",        "DNP TerriData",
  "S_ethnic_minority_share", "Ethnic Minority Share",        "controls",        "DNP / DANE",

  # ── G: Geographic & Territorial ──
  "G_terrain_ruggedness",    "Terrain Ruggedness",           "structural_risk", "PRIO-GRID v2.0",
  "G_nightlight",            "Nighttime Light",              "structural_risk", "PRIO-GRID v2.0",
  "G_forest_share",          "Forest Cover Share",           "structural_risk", "PRIO-GRID v2.0",
  "G_indigenous_pct",        "Indigenous Territory (%)",     "territorial",     "ANT",
  "G_afro_pct",              "Afro-Colombian Territory (%)", "territorial",     "ANT",
  "G_peasant_pct",           "Peasant Reserve Zone (%)",     "territorial",     "ANT"
)

# ── Colour and label constants ─────────────────────────────────────────────────
DIM_COLOURS <- c(
  negative_peace  = "#b2182b",
  active_conflict = "#d6604d",
  security        = "#f4a582",
  inst_peace      = "#2166ac",
  positive_peace  = "#1b7837",
  peacebuilding   = "#4dac26",
  transitional_j  = "#762a83",
  territorial     = "#8c510a",
  structural_risk = "#888888",
  controls        = "#444444"
)

DIM_LABELS <- c(
  negative_peace  = "Negative Peace",
  active_conflict = "Active Conflict",
  security        = "Security",
  inst_peace      = "Institutional Peace",
  positive_peace  = "Positive Peace",
  peacebuilding   = "Peacebuilding",
  transitional_j  = "Transitional Justice",
  territorial     = "Territorial Structure",
  structural_risk = "Structural Risk",
  controls        = "Controls"
)

BASEMAPS <- list(
  "Positron (minimal)"     = leaflet::providers$CartoDB.Positron,
  "OpenStreetMap"          = leaflet::providers$OpenStreetMap,
  "Gray Canvas (academic)" = leaflet::providers$Esri.WorldGrayCanvas
)

# Null-coalescing operator
`%or_null%` <- function(a, b) if (!is.null(a)) a else b

# ── Leaflet choropleth helper ─────────────────────────────────────────────────
# col_munis  : sf object (full Colombia or PDET subset) with dane_code column
# data_df    : data frame with dane_code + the variable column (may be panel)
#              If panel (has 'year' column), pass a single-year slice.
# var_col    : string — column name to map
# pdet_only  : if TRUE, non-PDET municipalities show outline only (NA fill)

make_choropleth <- function(col_munis_sf, data_df, var_col,
                            label_str   = var_col,
                            pdet_only   = TRUE,
                            palette     = "YlOrRd",
                            reverse_pal = FALSE,
                            n_bins      = 7) {

  if (is.null(col_munis_sf)) {
    warning("No geometry available — returning empty map.")
    return(leaflet::leaflet() |> leaflet::addTiles())
  }

  # If panel has year column, summarise to municipality level
  if ("year" %in% names(data_df)) {
    data_df <- data_df |>
      dplyr::group_by(dane_code) |>
      dplyr::summarise(across(all_of(var_col), ~ sum(.x, na.rm = TRUE)),
                       .groups = "drop")
  }

  map_sf <- col_munis_sf |>
    dplyr::left_join(
      data_df |> dplyr::select(dane_code, dplyr::all_of(var_col)),
      by = "dane_code"
    )

  if (pdet_only && length(PDET_CODES) > 0) {
    map_sf[[var_col]][!map_sf$dane_code %in% PDET_CODES] <- NA
  }

  vals       <- map_sf[[var_col]]
  valid_vals <- vals[!is.na(vals)]
  if (length(valid_vals) == 0) {
    warning(glue::glue("No valid values for {var_col}"))
    return(leaflet::leaflet() |> leaflet::addTiles() |>
             leaflet::addControl("<b>No data available</b>", position = "topright"))
  }

  pal <- leaflet::colorBin(palette = palette, domain = valid_vals,
                            bins = n_bins, na.color = "#e8e8e8",
                            reverse = reverse_pal)

  labels <- glue::glue(
    "<b>{map_sf$muni_name}</b> ({map_sf$dept_name})<br/>",
    "{label_str}: <b>{ifelse(is.na(vals), 'No data', format(round(vals, 2), big.mark=','))}</b><br/>",
    "PDET: {ifelse(map_sf$dane_code %in% (PDET_CODES %or_null% ''), 'Yes', 'No')}"
  ) |> lapply(htmltools::HTML)

  m <- leaflet::leaflet(map_sf, options = leaflet::leafletOptions(minZoom = 4)) |>
    leaflet::addProviderTiles(BASEMAPS[["Positron (minimal)"]],     group = "Positron (minimal)") |>
    leaflet::addProviderTiles(BASEMAPS[["OpenStreetMap"]],           group = "OpenStreetMap") |>
    leaflet::addProviderTiles(BASEMAPS[["Gray Canvas (academic)"]],  group = "Gray Canvas (academic)") |>
    leaflet::addPolygons(
      fillColor        = ~pal(get(var_col)),
      fillOpacity      = 0.75,
      color            = "#555", weight = 0.4, opacity = 0.6,
      smoothFactor     = 0.5,
      label            = labels,
      highlightOptions = leaflet::highlightOptions(
        weight = 2, color = "#222", fillOpacity = 0.9, bringToFront = TRUE)
    ) |>
    leaflet::addLegend(pal = pal, values = valid_vals, title = label_str,
                       position = "bottomright", opacity = 0.85,
                       na.label = "No data / Non-PDET") |>
    leaflet::addLayersControl(
      baseGroups    = names(BASEMAPS),
      options       = leaflet::layersControlOptions(collapsed = FALSE)
    ) |>
    leaflet::addScaleBar(position = "bottomleft") |>
    leaflet.extras::addResetMapButton() |>
    leaflet::setView(lng = -74.3, lat = 3.9, zoom = 5)
  m
}
