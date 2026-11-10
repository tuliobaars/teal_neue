# teal_neue

<!-- badges: start -->
<!-- badges: end -->

**teal_neue** brings the exploratory, safety and efficacy analyses of a
clinical trial together in a single
[teal](https://insightsengineering.github.io/teal/) app. It combines the three
[teal.gallery](https://github.com/insightsengineering/teal.gallery) templates
(exploratory, safety, efficacy) on top of a cached, tested data pipeline for
CDISC ADaM data, with a modernised look: same structure and analyses, modern
fonts, cleaner plots and a proper dark mode. It is still recognisably teal.

The R package is called `teal.neue` (R package names cannot contain `_`).

## Features

- **One app, three sections**: Exploratory, Safety and Efficacy analysis tabs,
  plus shared data table, variable browser and app info.
- **TLG Catalog**: every table, listing and graph of the
  [TLG Catalog](https://insightsengineering.github.io/tlg-catalog/stable/tlg-index.html)
  (135 outputs), one page per topic (Adverse Events, Concomitant Medications,
  Lab Results, ...) with a searchable list of outputs, on the filtered data,
  each with its reproducible R code.
- **Correct starting populations**: filters are module-specific; safety
  analyses start on the safety population (`SAFFL == "Y"`), efficacy analyses
  on the intent-to-treat population (`ITTFL == "Y"`).
- **Three data sources**: the synthetic data bundled with *random.cdisc.data*,
  freshly generated synthetic data (choose size and seed), or your own ADaM
  datasets as parquet files.
- **Data contract**: every source is validated before the app starts, with a
  complete list of any problems.
- **Fast start-up**: session memory and disk caches, invalidated automatically
  when the code or the data change.
- **Reproducible**: each module's "Show R code" reproduces its data in a fresh
  R session.
- **Readable adverse events**: placeholder AE codes are mapped to illustrative
  MedDRA-style names (e.g. *Headache*, *Diarrhoea*).
- **Quick to start**: relaunching the app in the same R session is instant,
  and reloads serve the page from memory.
- **Fast to navigate**: a command bar (`Ctrl/Cmd+K`) reaches every module
  and all 135 TLG outputs by name or ID; a breadcrumb shows where you are;
  every view has a link (bookmark it, share it, use the browser's back
  button); keyboard shortcuts for everything (`?`).
- **The study at a glance**: the home page (click the logo) summarises
  demographics, safety and efficacy by arm in small interactive widgets
  (point at an arm to follow it everywhere; read the survival curves with a
  crosshair), each linking to the module that goes into detail.
- **Outputs you can work with**: hover a plot to expand it (zoom, pan), pin
  it, compare it with a pinned version after changing a filter (swipe, side
  by side or difference), copy or download it; hover a table to copy it for
  Excel or download it as CSV.
- **Modern look, still teal**: "Instrument", ruled white panels on a
  dot-grid canvas, one teal accent, Inter / system font for reading and
  JetBrains Mono for dataset names, IDs and numbers, a quiet tint per
  category (Exploratory, Safety, Efficacy, TLG Catalog), an Appearance panel
  (text size, spacing, accent, corners, contrast, canvas, motion), cleaner plot defaults. It is layered over teal's standard theme
  with no Sass compilation at start-up and no third-party requests.
- **Light by default, dark mode that works**: an ink-blue dark palette,
  widgets fixed for dark mode, plots kept as white paper, a circular reveal
  when switching, no white flash on load; the browser remembers each user's
  choice.

## Installation

```r
# from the project folder (dependencies pinned with renv)
renv::restore()
devtools::install()

# the parquet data source also needs arrow
install.packages("arrow")
```

## Quick start

```r
library(teal.neue)

run_app()                                                       # bundled synthetic data
run_app(source = "synthetic", synthetic = list(N = 200, seed = 7))  # fresh synthetic data
run_app(source = "parquet", parquet_dir = "path/to/adam")        # adsl.parquet, adae.parquet, ...
```

In RStudio you can also open `app.R` and press **Run App**.

After the app closes, the analysis datasets (`ADSL`, `ADAE`, ...) are available
in the Global Environment. Without the app:

```r
neue <- load_teal_neue_data(cache_global = TRUE)
head(ADSL)
```

All settings are R options; see `?teal_neue_options`.

## Keyboard

| Keys | Does |
|---|---|
| `Ctrl K` / `Cmd K`, `/` | Command bar: jump to any module, TLG output or action |
| `H` | Home (or click the logo) |
| `[`  `]` | Previous / next module |
| `T` `A` `D` | Light/dark, appearance panel, cycle spacing |
| `F` `\` | Focus mode, filter panel |
| `C` `P` `L` | Show R code, pins, copy a link to this view |
| `?` | All shortcuts |

## Look and feel

```r
options(teal_neue.color_mode = "dark")  # default colour mode: "light" (default), "dark", "auto" (follows the OS)
options(teal_neue.motion = FALSE)       # no animations
options(teal_neue.app_cache = FALSE)    # rebuild the app on every run_app()
options(teal_neue.ggtheme = "bw")       # default ggplot2 theme of the exploratory plots ("minimal")
options(teal_neue.style = FALSE)        # plain teal look of the source templates
```

| What | Where |
|---|---|
| Fonts, colours, layout of the added elements, dark mode | `inst/www/teal_neue.css` (Bootstrap CSS variables over teal's default theme) |
| Command bar, breadcrumb, deep links, shortcuts, plot and table tools, pins, viewer, colour mode | `inst/www/teal_neue.js` |
| Module index for the command bar | `R/app_ui.R` (`teal_neue_index()`) |
| Study overview on the home page | `R/overview.R` (figures), `inst/www/teal_neue.js` (widgets) |
| TLG Catalog pages | `R/tlg_catalog.R` (module, icons), `R/tlg_entries_*.R` (outputs), `inst/www/tlg_catalog.*` (layout; its look is in `teal_neue.css`) |
| Header, footer, favicon | `R/app_ui.R` |
| Plot defaults | `R/plot_theme.R` (`teal_neue_ggplot2_args()`, via teal's `teal.ggplot2_args` option) |

Plot settings go through teal's own mechanisms, so they appear in each
module's "Show R code". Fonts are deliberately not set inside plots: a font
family in the code would break reproduction and PDF export on machines
without that font.

## TLG Catalog

The **TLG Catalog** tab (next to Data Table) reproduces the outputs of the
[TLG Catalog](https://insightsengineering.github.io/tlg-catalog/stable/tlg-index.html):
87 tables, 29 listings and 19 graphs in 16 pages (Adverse Events, Concomitant
Medications, Deaths, Demography, Disclosures, Disposition, ECG, Efficacy,
Exposure, Lab Results, Medical History, Pharmacokinetics, Anti-Drug
Antibodies, Risk Management Plan, Vital Signs, Other Graphs). Pick an output
in the list on the left (or search it by id or title); it is computed on the
app's *filtered* data, and **Show R code** gives the complete, runnable code.

- The code follows the catalog (tern, rtables, rlistings, tern.mmrm) adapted
  to this app's datasets; each output links to its catalog page.
- Outputs that need datasets the app does not load (ADPC, ADPP, ADAB, ADMH,
  ADHY) use the *random.cdisc.data* examples, restricted to the filtered
  patients (`tlg_example_data()`); the page says so.
- RBMIT01 needs the *rbmi* package, which is not installed by default; its
  page explains this.
- An output that cannot be produced (e.g. with your own data) shows the error
  and its code, and never affects the other pages. Results are cached per
  output until the filters change.

## Data pipeline

```
 source ──► ingest_adam() ──► validate_adam() ──► preprocess_adam() ──► cache ──► app
```

| Step | Function | Notes |
|---|---|---|
| Ingestion | `ingest_adam()` | `"bundled"`, `"synthetic"` or `"parquet"` |
| Contract | `validate_adam()`, `check_app_defaults()` | required datasets/columns; values the app pre-selects |
| Pre-processing | `preprocess_adam()` | derivations from the teal.gallery templates |
| Cache | `load_teal_neue_data()` | memory -> disk -> fresh build; `teal_neue_clear_cache()` |
| teal data | `build_teal_neue_data()` | reproducible code + join keys |

## Documentation

- `vignette("teal_neue")` - getting started and a tour of the app
- `vignette("data-sources")` - data sources, the data contract, caching,
  switching to real data
- `vignette("development")` - package layout, adding modules, tests, deployment

## Development

```r
devtools::load_all()
devtools::document()   # man/ and NAMESPACE from roxygen comments
devtools::test()       # test suite
devtools::check()
```

The data invariants run on several different datasets (bundled, two synthetic
draws, a parquet round trip) so they hold whatever the data are. Quick run:
`Sys.setenv(TEAL_NEUE_TEST_SCENARIOS = "bundled")`.

## License

MIT © teal_neue authors. Bundled fonts: Inter and JetBrains Mono, SIL Open
Font License 1.1 (`inst/www/fonts/OFL.txt`). Built on the open-source
[teal](https://insightsengineering.github.io/teal/) framework and the
teal.gallery templates (`inst/templates/`).
