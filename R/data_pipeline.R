# Data pipeline: ingestion -> pre-processing -> cache.

#' Load the analysis-ready teal_neue datasets
#'
#' The single entry point to the data. Returns the analysis-ready datasets,
#' using (in order) the first cache that is still valid:
#' 1. session memory (kept inside the package for the R session; makes
#'    repeated app launches instant),
#' 2. disk (`teal_neue_adam.rds` in `cache_dir`; survives R restarts),
#' 3. a fresh build: [ingest_adam()] then [preprocess_adam()], which is cached.
#'
#' Caches are invalidated automatically when the data-producing code changes
#' (package version or the ingestion/pre-processing functions) or when the data
#' source changes (source type, synthetic settings, 'random.cdisc.data'
#' version, or any parquet file's name, size or modification time).
#'
#' @inheritParams ingest_adam
#' @param use_cache Use (and maintain) the memory and disk caches?
#' @param refresh Ignore existing caches and rebuild from the source?
#' @param cache_global Also copy every dataset (`ADSL`, `ADAE`, ...) into
#'   `global_env` for easy console access?
#' @param cache_dir Folder of the disk cache.
#' @param global_env Environment receiving the dataset copies when
#'   `cache_global = TRUE`.
#' @param memory_env Environment holding the session memory cache.
#' @return A list with `datasets` (named list of data.frames), `meta`,
#'   `source` (the resolved source settings), `signature` and `created`.
#' @seealso [teal_neue_options], [teal_neue_clear_cache()]
#' @examples
#' \donttest{
#' neue <- load_teal_neue_data(cache_dir = tempdir())
#' names(neue$datasets)
#' # second call: served from the session memory cache
#' neue <- load_teal_neue_data(cache_dir = tempdir())
#' }
#' @export
load_teal_neue_data <- function(source = getOption("teal_neue.data_source", "bundled"),
                                synthetic = getOption("teal_neue.synthetic", list()),
                                parquet_dir = getOption("teal_neue.parquet_dir", "cache"),
                                use_cache = getOption("teal_neue.use_cache", TRUE),
                                refresh = getOption("teal_neue.refresh_cache", FALSE),
                                cache_global = getOption("teal_neue.cache_global", FALSE),
                                cache_dir = teal_neue_cache_dir_default(),
                                global_env = globalenv(),
                                memory_env = the) {
  t0 <- Sys.time()
  config <- teal_neue_source_config(source, synthetic, parquet_dir)
  signature <- teal_neue_data_signature(config)
  cache_file <- file.path(cache_dir, "teal_neue_adam.rds")
  result <- NULL

  if (isTRUE(use_cache) && !isTRUE(refresh)) {
    mem <- get0("data_cache", envir = memory_env, inherits = FALSE)
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
        error = function(e) warning("[teal_neue] Could not write disk cache: ", conditionMessage(e), call. = FALSE)
      )
    }
  }

  if (isTRUE(use_cache)) {
    assign("data_cache", result, envir = memory_env)
  }

  if (isTRUE(cache_global)) {
    list2env(result$datasets, envir = global_env)
    message("[teal_neue] Datasets available in the Global Environment: ", toString(names(result$datasets)))
  }

  message(sprintf(
    "[teal_neue] %d datasets ready from %s in %.1fs",
    length(result$datasets), from, as.numeric(difftime(Sys.time(), t0, units = "secs"))
  ))
  result
}

#' Remove the teal_neue data caches
#'
#' Clears the session memory caches (data and the app built from it) and
#' deletes the disk cache file; optionally also removes the dataset copies
#' made with `cache_global = TRUE`.
#'
#' @inheritParams load_teal_neue_data
#' @param remove_global_datasets Also remove `ADSL`, `ADAE`, ... from
#'   `global_env`?
#' @return Invisibly `TRUE`.
#' @examples
#' \donttest{
#' teal_neue_clear_cache(cache_dir = tempdir())
#' }
#' @export
teal_neue_clear_cache <- function(cache_dir = teal_neue_cache_dir_default(),
                                  remove_global_datasets = FALSE,
                                  global_env = globalenv(),
                                  memory_env = the) {
  mem <- get0("data_cache", envir = memory_env, inherits = FALSE)
  if (isTRUE(remove_global_datasets) && is.list(mem)) {
    suppressWarnings(rm(list = names(mem$datasets), envir = global_env))
  }
  if (!is.null(mem)) rm("data_cache", envir = memory_env)
  if (exists("app_cache", envir = memory_env, inherits = FALSE)) rm("app_cache", envir = memory_env)
  unlink(file.path(cache_dir, "teal_neue_adam.rds"))
  invisible(TRUE)
}

#' Cache signature: changes whenever the data-producing code or the source changes
#' @noRd
teal_neue_data_signature <- function(config = teal_neue_source_config(),
                                     code = teal_neue_code_fingerprint(),
                                     cache_version = 3L) {
  paste(c(cache_version, code, teal_neue_source_fingerprint(config)), collapse = "|")
}

#' Hash of the package version and of every function that produces data
#' @noRd
teal_neue_code_fingerprint <- function() {
  ns <- environment(teal_neue_code_fingerprint)
  pattern <- "^(ingest_|preprocess_|derive_|decode_ae_|ae_|adsl_character_vars$|recode_column$|synthetic_settings$)"
  fns <- sort(grep(pattern, ls(ns, all.names = TRUE), value = TRUE))
  rlang::hash(list(
    version = as.character(utils::packageVersion("teal.neue")),
    code = lapply(mget(fns, envir = ns), deparse)
  ))
}
