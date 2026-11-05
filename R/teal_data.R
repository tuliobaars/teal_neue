# =============================================================================
# Lumen - teal_data object
#
# Wraps the data pipeline (ingest.R -> preprocess.R -> data_pipeline.R) in a
# `teal_data` object. The code recorded here is what teal shows under
# "Show R code", so it is kept short and reproducible: it sources the pipeline
# scripts and calls `load_lumen_data()` (which uses the cache when valid).
#
# This file only defines functions (no side effects when sourced).
# =============================================================================

#' Join keys: standard CDISC keys + ADRS_EFF (same keys as ADRS, child of ADSL)
lumen_join_keys <- function() {
  c(
    teal.data::default_cdisc_join_keys[c(
      "ADSL", "ADRS", "ADLB", "ADLBPCA", "ADTTE", "ADQS",
      "ADAE", "ADAETTE", "ADEX", "ADEG", "ADVS", "ADCM"
    )],
    teal.data::join_keys(
      teal.data::join_key("ADRS_EFF", keys = c("STUDYID", "USUBJID", "PARAMCD", "AVISIT")),
      teal.data::join_key("ADSL", "ADRS_EFF", keys = c("STUDYID", "USUBJID"))
    )
  )
}

#' Build the teal_data object used by app.R
#'
#' Steps:
#'   1. Pre-flight: check the pipeline scripts are reachable from the working
#'      directory (the teal code sources them with relative paths).
#'   2. Run the pipeline in plain R. Any ingestion/pre-processing error is
#'      raised here with a normal traceback, the caches are filled and - if
#'      `lumen.cache_global` is TRUE - the datasets are copied to the Global
#'      Environment.
#'   3. Record the reproducible teal code. It re-uses the session cache filled
#'      in step 2, so the pipeline is not run twice.
#'   4. If the teal code fails, stop with the *real* error message. (teal code
#'      errors are returned as a `qenv.error` object rather than raised; passing
#'      that object on hides the cause behind a misleading `join_keys<-` error.)
build_lumen_teal_data <- function() {
  # 1. Pre-flight
  pipeline_files <- file.path("R", c("ingest.R", "preprocess.R", "data_pipeline.R"))
  missing_files <- pipeline_files[!file.exists(pipeline_files)]
  if (length(missing_files)) {
    stop(
      "[lumen] Data pipeline scripts not found: ", toString(missing_files),
      "\nThe working directory must be the project folder (currently: ", getwd(), ").",
      call. = FALSE
    )
  }
  
  # 2. Plain-R pipeline run (errors surface normally)
  pipeline <- new.env()
  for (f in pipeline_files) sys.source(f, envir = pipeline, keep.source = FALSE)
  pipeline$load_lumen_data()
  
  # 3. Reproducible teal code
  data <- teal.data::teal_data()
  data <- within(data, {
    # Packages used by the code that the analysis modules generate.
    # NOTE: MASS must be attached *before* dplyr, otherwise MASS::select()
    # masks dplyr::select().
    library(MASS)
    library(dplyr)
    library(tidyr)
    library(ggExtra)
    library(ggpmisc)
    library(ggpp)
    library(goftest)
    library(gridExtra)
    library(htmlwidgets)
    library(jsonlite)
    library(lattice)
    library(rlang)
    library(rtables)
    library(nestcolor)
    library(broom)
    library(colourpicker)
    library(sparkline)
    
    # Ingestion + pre-processing (see R/ingest.R and R/preprocess.R).
    # Served from cache when the pipeline code has not changed.
    .lumen <- local({
      source("R/ingest.R", local = TRUE)
      source("R/preprocess.R", local = TRUE)
      source("R/data_pipeline.R", local = TRUE)
      load_lumen_data(cache_global = FALSE)
    })
    
    ADSL <- .lumen$datasets$ADSL
    ADRS <- .lumen$datasets$ADRS
    ADRS_EFF <- .lumen$datasets$ADRS_EFF
    ADLB <- .lumen$datasets$ADLB
    ADLBPCA <- .lumen$datasets$ADLBPCA
    ADTTE <- .lumen$datasets$ADTTE
    ADQS <- .lumen$datasets$ADQS
    ADAE <- .lumen$datasets$ADAE
    ADAETTE <- .lumen$datasets$ADAETTE
    ADEX <- .lumen$datasets$ADEX
    ADEG <- .lumen$datasets$ADEG
    ADVS <- .lumen$datasets$ADVS
    ADCM <- .lumen$datasets$ADCM
  })
  
  # 4. Surface teal-code errors instead of passing a qenv.error along
  if (inherits(data, "qenv.error")) {
    stop("[lumen] The teal data code failed:\n", conditionMessage(data), call. = FALSE)
  }
  
  teal.data::join_keys(data) <- lumen_join_keys()
  data
}
