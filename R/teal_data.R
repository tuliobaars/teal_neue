# The teal_data object: datasets + reproducible code + join keys.

#' Build the app's teal_data object
#'
#' Wraps [load_teal_neue_data()] in a `teal_data` object with join keys.
#' `teal_neue_join_keys()` returns the standard CDISC keys for the standard
#' datasets plus explicit keys for the two derived datasets (`ADRS_EFF` and
#' `ADLBPCA`), which are not part of the CDISC defaults.
#'
#' Steps:
#' 1. Run the data pipeline in plain R, so any ingestion or pre-processing
#'    error is raised with a normal traceback (and the cache is filled).
#' 2. Record the reproducible code shown under "Show R code". It calls
#'    `teal.neue::load_teal_neue_data()` with the *resolved* source settings written
#'    out (e.g. the synthetic seed), so it reproduces the same data in a new
#'    session. In the app session it is served from the memory cache.
#' 3. If the recorded code fails, stop with its real error message (teal
#'    returns code errors as a `qenv.error` object instead of raising them).
#'
#' @inheritParams load_teal_neue_data
#' @return `build_teal_neue_data()`: a `teal_data` object with 13 datasets
#'   and join keys. `teal_neue_join_keys()`: a `join_keys` object.
#' @examples
#' \donttest{
#' data <- build_teal_neue_data(cache_global = FALSE)
#' names(data)
#' teal.data::join_keys(data)
#' }
#' @export
build_teal_neue_data <- function(source = getOption("teal_neue.data_source", "bundled"),
                                 synthetic = getOption("teal_neue.synthetic", list()),
                                 parquet_dir = getOption("teal_neue.parquet_dir", "cache"),
                                 cache_global = getOption("teal_neue.cache_global", FALSE)) {
  # 1. Plain-R pipeline run (errors surface normally); resolves the settings
  config <- teal_neue_source_config(source, synthetic, parquet_dir)
  load_teal_neue_data(config$source, config$synthetic, config$parquet_dir, cache_global = cache_global)

  # 2. Reproducible teal code
  data <- teal.data::teal_data()
  data <- teal.code::eval_code(data, teal_neue_library_code())
  data <- within(
    data,
    {
      .teal_neue <- teal.neue::load_teal_neue_data(
        source = TEAL_NEUE_SOURCE,
        synthetic = TEAL_NEUE_SYNTHETIC,
        parquet_dir = TEAL_NEUE_PARQUET_DIR,
        cache_global = FALSE
      )
      ADSL <- .teal_neue$datasets$ADSL
      ADRS <- .teal_neue$datasets$ADRS
      ADRS_EFF <- .teal_neue$datasets$ADRS_EFF
      ADLB <- .teal_neue$datasets$ADLB
      ADLBPCA <- .teal_neue$datasets$ADLBPCA
      ADTTE <- .teal_neue$datasets$ADTTE
      ADQS <- .teal_neue$datasets$ADQS
      ADAE <- .teal_neue$datasets$ADAE
      ADAETTE <- .teal_neue$datasets$ADAETTE
      ADEX <- .teal_neue$datasets$ADEX
      ADEG <- .teal_neue$datasets$ADEG
      ADVS <- .teal_neue$datasets$ADVS
      ADCM <- .teal_neue$datasets$ADCM
    },
    TEAL_NEUE_SOURCE = config$source,
    TEAL_NEUE_SYNTHETIC = config$synthetic,
    TEAL_NEUE_PARQUET_DIR = config$parquet_dir
  )

  # 3. Surface teal-code errors instead of passing a qenv.error along
  if (inherits(data, "qenv.error")) {
    stop("[teal_neue] The teal data code failed:\n", conditionMessage(data), call. = FALSE)
  }

  teal.data::join_keys(data) <- teal_neue_join_keys()
  data
}

#' @rdname build_teal_neue_data
#' @export
teal_neue_join_keys <- function() {
  c(
    teal.data::default_cdisc_join_keys[c(
      "ADSL", "ADRS", "ADLB", "ADTTE", "ADQS",
      "ADAE", "ADAETTE", "ADEX", "ADEG", "ADVS", "ADCM"
    )],
    teal.data::join_keys(
      # efficacy response subset: same keys as ADRS
      teal.data::join_key("ADRS_EFF", keys = c("STUDYID", "USUBJID", "PARAMCD", "AVISIT")),
      teal.data::join_key("ADSL", "ADRS_EFF", keys = c("STUDYID", "USUBJID")),
      # wide lab data for the PCA module: one row per subject
      teal.data::join_key("ADLBPCA", keys = c("STUDYID", "USUBJID")),
      teal.data::join_key("ADSL", "ADLBPCA", keys = c("STUDYID", "USUBJID"))
    )
  )
}

#' Packages used by the code the analysis modules generate (attached in the
#' teal code so "Show R code" is runnable on its own).
#' NOTE: MASS must be attached *before* dplyr, otherwise MASS::select() masks
#' dplyr::select().
#' @noRd
teal_neue_library_code <- function() {
  pkgs <- c(
    "MASS", "dplyr", "tidyr", "ggExtra", "ggpmisc", "ggpp", "goftest", "gridExtra",
    "htmlwidgets", "jsonlite", "lattice", "rlang", "rtables", "nestcolor", "broom",
    "colourpicker", "sparkline"
  )
  paste0("library(", pkgs, ")", collapse = "\n")
}
