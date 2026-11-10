# Shared test setup: data scenarios and isolation helpers.
#
# The data invariants are checked on several *different* datasets so they hold
# whatever the data are, not just for one snapshot:
#   bundled          random.cdisc.data's pre-generated datasets
#   synthetic_small  freshly generated, 40 subjects, seed 1
#   synthetic_alt    freshly generated, 90 subjects, seed 20240
#   parquet          bundled data written to parquet and read back (needs {arrow})
# Run a subset with e.g. Sys.setenv(TEAL_NEUE_TEST_SCENARIOS = "bundled").

teal_neue_scenarios <- function() {
  all <- c("bundled", "synthetic_small", "synthetic_alt", "parquet")
  chosen <- Sys.getenv("TEAL_NEUE_TEST_SCENARIOS", paste(all, collapse = ","))
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
        dir <- file.path(tempfile("teal-neue-parquet-"))
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

#' Isolated options and caches for a test: temporary disk cache, fresh memory
#' cache, nothing copied to the Global Environment.
local_teal_neue_options <- function(env = parent.frame()) {
  withr::local_options(
    list(
      teal_neue.cache_dir = withr::local_tempdir(.local_envir = env),
      teal_neue.cache_global = FALSE,
      teal_neue.refresh_cache = FALSE,
      teal_neue.use_cache = TRUE,
      teal_neue.data_source = "bundled",
      teal_neue.synthetic = NULL,
      teal_neue.parquet_dir = NULL,
      teal_neue.style = TRUE,
      teal_neue.color_mode = "light",
      teal_neue.motion = TRUE,
      teal_neue.ggtheme = "minimal",
      teal.ggplot2_args = NULL
    ),
    .local_envir = env
  )
  local_memory_cache(env)
}

#' Save and restore the package's session memory cache
local_memory_cache <- function(env = parent.frame()) {
  had <- exists("data_cache", envir = the, inherits = FALSE)
  old <- if (had) get("data_cache", envir = the)
  withr::defer(
    {
      if (had) assign("data_cache", old, envir = the) else suppressWarnings(rm("data_cache", envir = the))
    },
    envir = env
  )
}
