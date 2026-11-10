#' teal.neue: Modernised Clinical Trial Analysis App Built on 'teal'
#'
#' teal_neue combines the exploratory, safety and efficacy teal.gallery
#' templates into a single 'teal' app, backed by a cached data pipeline
#' (ingestion -> pre-processing -> cache) that can read bundled or freshly
#' generated synthetic ADaM data, or ADaM parquet files. Over the standard
#' teal theme it adds an interactive layer (command bar, breadcrumb, deep
#' links, keyboard shortcuts, plot and table tools, pins with visual
#' comparison) and a calm "instrument" look, and its TLG Catalog section
#' reproduces every output of the TLG Catalog on the filtered data.
#'
#' Main entry points:
#' * [run_app()] / [teal_neue_app()]: build and run the app.
#' * [load_teal_neue_data()]: the analysis-ready datasets (cached).
#' * [ingest_adam()], [preprocess_adam()]: the two pipeline steps.
#' * [adam_contract()]: what the data must provide.
#' * [teal_neue_ggplot2_args()]: the plot defaults.
#' * [tlg_example_data()]: example datasets used by some TLG Catalog outputs.
#' * [teal_neue_options]: all settings.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import teal
#' @import teal.modules.clinical
#' @import teal.modules.general
#' @import teal.picks
#' @importFrom rlang .data
## usethis namespace: end
NULL

# Session-level memory cache used by load_teal_neue_data()
the <- new.env(parent = emptyenv())

# Column names used with dplyr's non-standard evaluation, and the placeholders
# substituted into the reproducible teal code (see build_teal_neue_data()).
utils::globalVariables(c(
  "ABLFL", "ABLFL2", "AEREL", "AESER", "AETOXGR", "AGE", "ANRIND", "ARM", "ARMCD",
  "AVAL", "AVISIT", "AVISITN", "BNRIND", "CMSEQ", "CNSR", "CQ01NAM", "PARAMCD",
  "PARCAT1", "SEX", "SMQ01NAM", "SMQ02NAM", "STUDYID", "USUBJID", "is_event",
  "TEAL_NEUE_SOURCE", "TEAL_NEUE_SYNTHETIC", "TEAL_NEUE_PARQUET_DIR", ".teal_neue"
))
