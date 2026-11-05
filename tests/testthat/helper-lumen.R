# Shared test setup: sources the pipeline and provides the data scenarios.
#
# The data invariants are checked on several *different* datasets so they hold
# whatever the data are, not just for one snapshot:
#   bundled          random.cdisc.data's pre-generated datasets
#   synthetic_small  freshly generated, 40 subjects, seed 1
#   synthetic_alt    freshly generated, 90 subjects, seed 20240
#   parquet          bundled data written to parquet and read back (needs {arrow})
# Run a subset with e.g. Sys.setenv(LUMEN_TEST_SCENARIOS = "bundled").

lumen_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/")

for (f in c("ingest.R", "preprocess.R", "data_pipeline.R", "teal_data.R")) {
  sys.source(file.path(lumen_root, "R", f), envir = environment(), keep.source = FALSE)
}

lumen_scenarios <- function() {
  all <- c("bundled", "synthetic_small", "synthetic_alt", "parquet")
  chosen <- Sys.getenv("LUMEN_TEST_SCENARIOS", paste(all, collapse = ","))
  intersect(trimws(strsplit(chosen, ",")[[1]]), all)
}

.scenario_cache <- new.env()

build_scenario <- function(name) {
  warnings <- character(0)
  raw <- withCallingHandlers(
    switch(name,
           bundled = ingest_adam("bundled"),
           synthetic_small = ingest_adam("synthetic", synthetic = list(N = 40, seed = 1)),
           synthetic_alt = ingest_adam("synthetic", synthetic = list(N = 90, seed = 20240)),
           parquet = {
             if (!requireNamespace("arrow", quietly = TRUE)) stop("package 'arrow' is not installed")
             dir <- file.path(tempfile("lumen-parquet-"))
             export_adam_parquet(ingest_bundled(), dir)
             ingest_adam("parquet", parquet_dir = dir)
           }
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) invokeRestart("muffleMessage")
  )
  processed <- withCallingHandlers(
    preprocess_adam(raw),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(raw = raw, processed = processed, warnings = warnings)
}

#' Memoised scenario data; skips the calling test if the scenario cannot be built
#' (the dedicated "scenario builds" test reports the actual error).
scenario <- function(name) {
  if (is.null(.scenario_cache[[name]])) {
    .scenario_cache[[name]] <- tryCatch(build_scenario(name), error = function(e) e)
  }
  res <- .scenario_cache[[name]]
  if (inherits(res, "error")) {
    testthat::skip(sprintf("scenario '%s' could not be built: %s", name, conditionMessage(res)))
  }
  res
}

scenario_error <- function(name) {
  if (is.null(.scenario_cache[[name]])) {
    .scenario_cache[[name]] <- tryCatch(build_scenario(name), error = function(e) e)
  }
  res <- .scenario_cache[[name]]
  if (inherits(res, "error")) res else NULL
}

#' Minimal raw data that satisfies the contract (tiny, for fast unit tests)
minimal_raw <- function(n = 2) {
  ids <- sprintf("S%02d", seq_len(n))
  lapply(adam_contract(), function(cols) {
    df <- as.data.frame(stats::setNames(rep(list(rep("x", n)), length(cols)), cols), stringsAsFactors = FALSE)
    df$STUDYID <- "STUDY1"
    df$USUBJID <- ids
    df
  })
}

#' Run code with the project root as working directory and isolated caches/options
local_lumen_project <- function(env = parent.frame()) {
  withr::local_dir(lumen_root, .local_envir = env)
  withr::local_options(
    list(
      lumen.cache_dir = withr::local_tempdir(.local_envir = env),
      lumen.cache_global = FALSE,
      lumen.refresh_cache = FALSE,
      lumen.use_cache = TRUE,
      lumen.data_source = "bundled",
      lumen.synthetic = NULL,
      lumen.parquet_dir = NULL
    ),
    .local_envir = env
  )
}

#' Save and restore the session cache in the Global Environment
local_global_cache <- function(env = parent.frame()) {
  had <- exists(".lumen_cache", envir = globalenv(), inherits = FALSE)
  old <- if (had) get(".lumen_cache", envir = globalenv())
  withr::defer(
    {
      if (had) assign(".lumen_cache", old, envir = globalenv()) else suppressWarnings(rm(".lumen_cache", envir = globalenv()))
    },
    envir = env
  )
}
