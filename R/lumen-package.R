#' lumen: Integrated Clinical Trial Analysis App Built on 'teal'
#'
#' Combines the exploratory, safety and efficacy teal.gallery templates into a
#' single 'teal' app, backed by a cached data pipeline (ingestion ->
#' pre-processing -> cache) that can read bundled or freshly generated
#' synthetic ADaM data, or ADaM parquet files.
#'
#' Main entry points:
#' * [run_app()] / [lumen_app()]: build and run the app.
#' * [load_lumen_data()]: the analysis-ready datasets (cached).
#' * [ingest_adam()], [preprocess_adam()]: the two pipeline steps.
#' * [adam_contract()]: what the data must provide.
#' * [lumen_options]: all settings.
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

# Session-level memory cache used by load_lumen_data()
the <- new.env(parent = emptyenv())

# Column names used with dplyr's non-standard evaluation, and the placeholders
# substituted into the reproducible teal code (see build_lumen_teal_data()).
utils::globalVariables(c(
  "ABLFL", "ABLFL2", "AEREL", "AESER", "AETOXGR", "AGE", "ANRIND", "ARM", "ARMCD",
  "AVAL", "AVISIT", "AVISITN", "BNRIND", "CMSEQ", "CNSR", "CQ01NAM", "PARAMCD",
  "PARCAT1", "SEX", "SMQ01NAM", "SMQ02NAM", "STUDYID", "USUBJID", "is_event",
  "LUMEN_SOURCE", "LUMEN_SYNTHETIC", "LUMEN_PARQUET_DIR", ".lumen"
))
