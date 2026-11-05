# lumen

<!-- badges: start -->
<!-- badges: end -->

**lumen** brings the exploratory, safety and efficacy analyses of a clinical
trial together in a single [teal](https://insightsengineering.github.io/teal/)
app. It combines the three
[teal.gallery](https://github.com/insightsengineering/teal.gallery) templates
(exploratory, safety, efficacy) on top of a cached, tested data pipeline for
CDISC ADaM data.

## Features

- **One app, three sections**: Exploratory, Safety and Efficacy analysis tabs,
  plus shared data table, variable browser and app info.
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
- **Dark mode** toggle.

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
library(lumen)

run_app()                                                       # bundled synthetic data
run_app(source = "synthetic", synthetic = list(N = 200, seed = 7))  # fresh synthetic data
run_app(source = "parquet", parquet_dir = "path/to/adam")        # adsl.parquet, adae.parquet, ...
```

In RStudio you can also open `app.R` and press **Run App**.

After the app closes, the analysis datasets (`ADSL`, `ADAE`, ...) are available
in the Global Environment. Without the app:

```r
lumen <- load_lumen_data(cache_global = TRUE)
head(ADSL)
```

All settings are R options; see `?lumen_options`.

## Data pipeline

```
 source ──► ingest_adam() ──► validate_adam() ──► preprocess_adam() ──► cache ──► app
```

| Step | Function | Notes |
|---|---|---|
| Ingestion | `ingest_adam()` | `"bundled"`, `"synthetic"` or `"parquet"` |
| Contract | `validate_adam()`, `check_app_defaults()` | required datasets/columns; values the app pre-selects |
| Pre-processing | `preprocess_adam()` | derivations from the teal.gallery templates |
| Cache | `load_lumen_data()` | memory -> disk -> fresh build; `lumen_clear_cache()` |
| teal data | `build_lumen_teal_data()` | reproducible code + join keys |

## Documentation

- `vignette("lumen")` - getting started and a tour of the app
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
`Sys.setenv(LUMEN_TEST_SCENARIOS = "bundled")`.

## License

MIT © lumen authors. Built on the open-source
[teal](https://insightsengineering.github.io/teal/) framework and the
teal.gallery templates (`inst/templates/`).
