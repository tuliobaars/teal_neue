# =============================================================================
# Lumen - Data pipeline: ingestion -> pre-processing -> cache
#
# `load_lumen_data()` is the single entry point. It returns the analysis-ready
# datasets, using (in order) the first cache that is still valid:
#
#   1. session memory  (hidden `.lumen_cache` object in the Global Environment;
#                       makes repeated runApp() calls in one R session instant)
#   2. disk            (`cache/lumen_adam.rds`; survives R restarts)
#   3. fresh build     (ingest_adam() -> preprocess_adam(), then caches)
#
# Caches are invalidated automatically when R/ingest.R or R/preprocess.R
# change, or when the data source changes (source type, synthetic settings,
# {random.cdisc.data} version, or any parquet file's name/size/modification time).
#
# Options (set them before runApp(), or pass the arguments directly):
#   lumen.data_source   "bundled" "bundled" | "synthetic" | "parquet" (see ingest.R)
#   lumen.synthetic     list()    e.g. list(N = 200, seed = 7)
#   lumen.parquet_dir   "cache"   Folder with adsl.parquet, adae.parquet, ...
#   lumen.use_cache     TRUE      Use/maintain the memory + disk caches
#   lumen.refresh_cache FALSE     Force re-ingestion and re-processing
#   lumen.cache_global  FALSE     Copy every dataset (ADSL, ADAE, ...) into the
#                                 Global Environment for easy console access
#   lumen.cache_dir     "cache"
#
# Standalone use (no app), e.g. to explore the data in the console:
#   source("R/ingest.R"); source("R/preprocess.R"); source("R/data_pipeline.R")
#   load_lumen_data(cache_global = TRUE)
#   head(ADSL)
#
# This file only defines functions (no side effects when sourced).
# =============================================================================

#' Load the analysis-ready Lumen datasets
#'
#' @param source,synthetic,parquet_dir Data source settings (see ingest.R).
#' @param use_cache Logical. Use (and maintain) the memory and disk caches.
#' @param refresh Logical. Ignore existing caches and rebuild from the source.
#' @param cache_global Logical. Also assign every dataset into `global_env`.
#' @param cache_dir Directory for the on-disk cache.
#' @param global_env Environment for the session cache and the dataset copies
#'   (the Global Environment; tests pass a throw-away environment).
#' @return List with `datasets` (named list of data.frames), `meta`, `source`
#'   (resolved source settings), `signature` and `created`.
load_lumen_data <- function(source = getOption("lumen.data_source", "bundled"),
                            synthetic = getOption("lumen.synthetic", list()),
                            parquet_dir = getOption("lumen.parquet_dir", "cache"),
                            use_cache = getOption("lumen.use_cache", TRUE),
                            refresh = getOption("lumen.refresh_cache", FALSE),
                            cache_global = getOption("lumen.cache_global", FALSE),
                            cache_dir = getOption("lumen.cache_dir", "cache"),
                            global_env = globalenv()) {
  t0 <- Sys.time()
  config <- lumen_source_config(source, synthetic, parquet_dir)
  signature <- lumen_data_signature(config)
  cache_file <- file.path(cache_dir, "lumen_adam.rds")
  result <- NULL
  
  if (isTRUE(use_cache) && !isTRUE(refresh)) {
    mem <- get0(".lumen_cache", envir = global_env, inherits = FALSE)
    if (is.list(mem) && identical(mem$signature, signature)) {
      result <- mem
      from <- "session memory cache"
    } else if (file.exists(cache_file)) {
      disk <- tryCatch(readRDS(cache_file), error = function(e) NULL)
      if (is.list(disk) && identical(disk$signature, signature)) {
        result <- disk
        from <- paste("disk cache", sQuote(cache_file, FALSE))
      }
    }
  }
  
  if (is.null(result)) {
    raw <- ingest_adam(config$source, config$synthetic, config$parquet_dir)
    result <- preprocess_adam(raw)
    result$source <- config
    result$signature <- signature
    result$created <- Sys.time()
    from <- sprintf("%s source (fresh ingestion + pre-processing)", config$source)
    if (isTRUE(use_cache)) {
      tryCatch(
        {
          dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
          saveRDS(result, cache_file)
        },
        error = function(e) warning("[lumen] Could not write disk cache: ", conditionMessage(e), call. = FALSE)
      )
    }
  }
  
  if (isTRUE(use_cache)) {
    assign(".lumen_cache", result, envir = global_env)
  }
  
  if (isTRUE(cache_global)) {
    list2env(result$datasets, envir = global_env)
    message("[lumen] Datasets available in the Global Environment: ", toString(names(result$datasets)))
  }
  
  message(sprintf(
    "[lumen] %d datasets ready from %s in %.1fs",
    length(result$datasets), from, as.numeric(difftime(Sys.time(), t0, units = "secs"))
  ))
  result
}

#' Cache signature: changes whenever the data-producing code or the source changes
lumen_data_signature <- function(config = lumen_source_config(),
                                 files = file.path("R", c("ingest.R", "preprocess.R")),
                                 cache_version = 2L) {
  paste(c(cache_version, unname(tools::md5sum(files)), lumen_source_fingerprint(config)), collapse = "|")
}

#' Remove the memory and disk caches (and optionally the dataset copies)
lumen_clear_cache <- function(cache_dir = getOption("lumen.cache_dir", "cache"),
                              remove_global_datasets = FALSE,
                              global_env = globalenv()) {
  mem <- get0(".lumen_cache", envir = global_env, inherits = FALSE)
  if (isTRUE(remove_global_datasets) && is.list(mem)) {
    suppressWarnings(rm(list = names(mem$datasets), envir = global_env))
  }
  if (!is.null(mem)) rm(".lumen_cache", envir = global_env)
  unlink(file.path(cache_dir, "lumen_adam.rds"))
  invisible(TRUE)
}
