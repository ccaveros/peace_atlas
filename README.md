# Peace Atlas — PDET Colombia

> Exploratory spatial analysis of peace indicator candidates at the PDET municipal level
> GEOG 560: Spatial Regression · Penn State · Spring 2026
> Cecilia Cavero-Sanchez

**Deploy:** Drag `docs/` folder to [drop.netlify.com](https://drop.netlify.com) for an instant shareable URL. No account needed.

---

## Site Structure

```
quarto_peace_atlas/
├── _quarto.yml              # Site config, navbar, output to docs/
├── index.qmd                # Overview, panel summary table, coverage chart, PDET map
├── panel1_atlas.qmd         # Variable Atlas — choropleth maps (1 per category tab), Moran's I, missingness map
├── descriptives.qmd         # Per-variable diagnostics: distributions, temporal trends, flags, correlation heatmap
├── panel2_bivariate.qmd     # Bivariate Moran, LISA maps, MAUP sensitivity (PDET munis only)
├── panel3_regression.qmd    # OLS / SLM / SEM / SDM + residual maps
├── explorer.qmd             # Interactive explorer: 5 category tabs + spatial autocorrelation (LISA + Moran scatter)
├── audit.qmd                # Data audit, gap analysis, source coverage table
├── R/
│   └── setup.R              # Shared paths, data loading, META table, leaflet helpers, patchwork
├── assets/
│   └── custom.scss          # Site theme
└── docs/                    # Quarto output — serve locally or deploy
```

---

## Variable Naming Convention

All panel variables follow: **`{category}_{name}__{source}`**

| Prefix | Category |
|--------|----------|
| `V_` | Violence and Conflict |
| `P_` | Peacebuilding and Implementation |
| `J_` | Justice and Dispute Resolution |
| `S_` | Socioeconomic and Structural |
| `G_` | Geographic and Territorial |

Source suffixes: `cnmh`, `ucdp`, `jep`, `cerac`, `aponte`, `daly`, `art`, `pdet`, `apc`, `slj`, `casjust`, `concil`, `urt`, `dnp`, `igac`, `prio`, `ant`

---

## Panel Data

- **File**: `pdet_panel_v*.parquet` in `02. analysis/pdet_outputs/`
- **Dimensions**: 170 PDET municipalities x 2000-2025 = 4,420 rows x 161 columns
- **Numeric variables**: 155 across 5 categories
- **Geometry**: `pdet_munis` (sf object) loaded via `R/setup.R`

The panel is loaded in `R/setup.R` — update `OUTPUT_DIR` if you move the project:
```r
OUTPUT_DIR <- here::here("..", "output")
PDET_DIR   <- here::here("..", "02. analysis", "pdet_outputs")
```

---

## Deployment

### Option 1 — Netlify Drop (instant, no account)
1. Run `quarto render` locally
2. Go to [drop.netlify.com](https://drop.netlify.com)
3. Drag the `docs/` folder
4. Copy the URL (e.g. `https://abc123.netlify.app`)

### Option 2 — GitHub Pages (permanent)
1. Push repo to `ccaveros/quarto_peace_atlas`
2. Settings -> Pages -> Branch: `main`, Folder: `/docs`
3. Site at `ccaveros.github.io/quarto_peace_atlas`

### Option 3 — Local preview
```bash
cd "08. quarto_peace_atlas"
quarto preview
```

---

## Dependencies

```r
install.packages(c(
  "here", "sf", "dplyr", "tidyr", "readr", "purrr", "stringr",
  "spdep", "spatialreg", "leaflet", "leaflet.extras",
  "plotly", "DT", "ggplot2", "scales", "patchwork",
  "RColorBrewer", "viridis", "glue", "data.table",
  "arrow", "psych", "htmltools", "knitr", "moments"
))
```

---

## Data Sources

| Source | Prefix | Variables | Years | Coverage |
|--------|--------|-----------|-------|----------|
| CNMH | `V_*__cnmh` | 26 | 2000-2025 | 161 munis |
| CERAC | `V_*__cerac` | 11 | 2000-2010 | 169 munis |
| UCDP | `V_*__ucdp` | 4 | 2000-2024 | 160 munis |
| JEP/VERDATA | `V_*__jep` | 3 | 2000-2018 | 161 munis |
| Aponte Gonzalez | `V_*__aponte` | 18 | 2000-2016 | 76 munis |
| Daly | `V_*__daly` | 6 | 2000-2016 | 65-170 munis |
| PDET Initiatives | `P_*__pdet` | 10 | static | 161 munis |
| ART/SIIPO | `P_*__art` | 22 | 2012-2025 | 170 munis |
| APC | `P_*__apc` | 5 | 2018-2025 | 154 munis |
| SLJ | `J_*__slj` | 2 | annual | 161 munis |
| Casas de Justicia | `J_*__casjust` | 1 | 2019-2025 | 32 munis |
| Conciliacion | `J_*__concil` | 2 | 2000-2025 | 115 munis |
| URT | `J_*__urt` | 1 | annual | 120 munis |
| DNP TerriData | `S_*__dnp` | 20 | 2000-2023 | 170 munis |
| IGAC | `S_*__igac` | 2 | static | 161 munis |
| PRIO-GRID | `G_*__prio` | 8 | 2000-2023 | 161 munis |
| ANT Territories | `G_*__ant` | 9 | static | 161 munis |

See `descriptives_interpretation.md` in `output/` for full variable-by-variable diagnostics and transformation recommendations.

---

## Status (April 2026)

| Page | Status |
|------|--------|
| `index.qmd` | Rendering |
| `panel1_atlas.qmd` | Rendering |
| `descriptives.qmd` | Rendering |
| `panel2_bivariate.qmd` | Rendering |
| `panel3_regression.qmd` | Rendering |
| `explorer.qmd` | Rendering |
| `audit.qmd` | Rendering |
| Latent variable analysis (EFA/CFA/MIMIC) | In progress |
