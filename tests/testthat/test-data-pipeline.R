testthat::local_edition(3)

# Cache behaviour. Uses the fast "bundled" source, a temporary cache folder and
# a throw-away environment instead of the Global Environment.

load_quiet <- function(...) {
  msgs <- character(0)
  res <- withCallingHandlers(
    load_lumen_data(...),
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  list(result = res, messages = paste(msgs, collapse = "\n"))
}

test_that("first load builds from the source, then memory, then disk cache", {
  local_lumen_project()
  cache_dir <- getOption("lumen.cache_dir")
  env <- new.env()
  
  first <- load_quiet(global_env = env, cache_dir = cache_dir)
  expect_match(first$messages, "bundled source \\(fresh")
  expect_true(file.exists(file.path(cache_dir, "lumen_adam.rds")))
  expect_true(exists(".lumen_cache", envir = env, inherits = FALSE))
  
  second <- load_quiet(global_env = env, cache_dir = cache_dir)
  expect_match(second$messages, "session memory cache")
  expect_identical(second$result$datasets, first$result$datasets)
  
  third <- load_quiet(global_env = new.env(), cache_dir = cache_dir)
  expect_match(third$messages, "disk cache")
  expect_identical(third$result$datasets, first$result$datasets)
})

test_that("result carries datasets, metadata, source settings and signature", {
  local_lumen_project()
  res <- load_quiet(global_env = new.env())$result
  expect_named(res, c("datasets", "meta", "source", "signature", "created"), ignore.order = TRUE)
  expect_identical(res$source$source, "bundled")
  expect_identical(res$signature, lumen_data_signature(lumen_source_config("bundled")))
})

test_that("refresh = TRUE rebuilds even with a valid cache", {
  local_lumen_project()
  env <- new.env()
  load_quiet(global_env = env)
  again <- load_quiet(global_env = env, refresh = TRUE)
  expect_match(again$messages, "fresh")
})

test_that("use_cache = FALSE neither reads nor writes caches", {
  local_lumen_project()
  cache_dir <- withr::local_tempdir()
  env <- new.env()
  res <- load_quiet(global_env = env, cache_dir = cache_dir, use_cache = FALSE)
  expect_match(res$messages, "fresh")
  expect_false(file.exists(file.path(cache_dir, "lumen_adam.rds")))
  expect_false(exists(".lumen_cache", envir = env, inherits = FALSE))
})

test_that("a corrupted cache file is ignored and rebuilt", {
  local_lumen_project()
  cache_dir <- getOption("lumen.cache_dir")
  writeLines("not an rds file", file.path(cache_dir, "lumen_adam.rds"))
  res <- load_quiet(global_env = new.env(), cache_dir = cache_dir)
  expect_match(res$messages, "fresh")
  expect_type(readRDS(file.path(cache_dir, "lumen_adam.rds")), "list")
})

test_that("a stale cache (different signature) is not used", {
  local_lumen_project()
  cache_dir <- getOption("lumen.cache_dir")
  env <- new.env()
  load_quiet(global_env = env, cache_dir = cache_dir)
  stale <- get(".lumen_cache", envir = env)
  stale$signature <- "old"
  assign(".lumen_cache", stale, envir = env)
  saveRDS(stale, file.path(cache_dir, "lumen_adam.rds"))
  res <- load_quiet(global_env = env, cache_dir = cache_dir)
  expect_match(res$messages, "fresh")
})

test_that("cache_global copies every dataset; lumen_clear_cache removes them", {
  local_lumen_project()
  cache_dir <- getOption("lumen.cache_dir")
  env <- new.env()
  res <- load_quiet(global_env = env, cache_dir = cache_dir, cache_global = TRUE)
  expect_match(res$messages, "available in the Global Environment")
  for (ds in names(res$result$datasets)) {
    expect_identical(get(ds, envir = env), res$result$datasets[[ds]], info = ds)
  }
  lumen_clear_cache(cache_dir = cache_dir, remove_global_datasets = TRUE, global_env = env)
  expect_length(ls(env, all.names = TRUE), 0)
  expect_false(file.exists(file.path(cache_dir, "lumen_adam.rds")))
})

test_that("the cache signature tracks code and data-source changes", {
  local_lumen_project()
  bundled <- lumen_data_signature(lumen_source_config("bundled"))
  expect_identical(bundled, lumen_data_signature(lumen_source_config("bundled")))
  
  s1 <- lumen_data_signature(lumen_source_config("synthetic", list(N = 50, seed = 1)))
  s2 <- lumen_data_signature(lumen_source_config("synthetic", list(N = 50, seed = 2)))
  s3 <- lumen_data_signature(lumen_source_config("synthetic", list(N = 60, seed = 1)))
  expect_length(unique(c(bundled, s1, s2, s3)), 4)
  
  # pipeline code change (simulated with a modified copy of preprocess.R)
  tmp <- withr::local_tempfile(fileext = ".R")
  writeLines(c(readLines("R/preprocess.R"), "# changed"), tmp)
  expect_false(identical(
    bundled,
    lumen_data_signature(lumen_source_config("bundled"), files = c("R/ingest.R", tmp))
  ))
})

test_that("the parquet signature changes when a file is added or modified", {
  local_lumen_project()
  dir <- withr::local_tempdir()
  writeLines("a", file.path(dir, "adsl.parquet"))
  cfg <- lumen_source_config("parquet", parquet_dir = dir)
  before <- lumen_data_signature(cfg)
  expect_identical(before, lumen_data_signature(cfg))
  
  writeLines("b", file.path(dir, "adae.parquet"))
  added <- lumen_data_signature(cfg)
  expect_false(identical(before, added))
  
  writeLines("longer content", file.path(dir, "adsl.parquet"))
  modified <- lumen_data_signature(cfg)
  expect_false(identical(added, modified))
  
  # non-ADaM files in the folder do not invalidate the cache
  writeLines("ignored", file.path(dir, "notes.txt"))
  expect_identical(lumen_data_signature(cfg), modified)
})

test_that("synthetic source runs end-to-end through the pipeline", {
  local_lumen_project()
  res <- load_quiet(source = "synthetic", synthetic = list(N = 30, seed = 11), global_env = new.env())
  expect_match(res$messages, "synthetic source")
  expect_identical(nrow(res$result$datasets$ADSL), 30L)
  expect_identical(res$result$source$synthetic$seed, 11L)
})

test_that("parquet source runs end-to-end through the pipeline", {
  skip_if_not_installed("arrow")
  local_lumen_project()
  dir <- withr::local_tempdir()
  export_adam_parquet(ingest_bundled(), dir)
  res <- load_quiet(source = "parquet", parquet_dir = dir, global_env = new.env())
  expect_match(res$messages, "parquet source")
  direct <- load_quiet(source = "bundled", global_env = new.env(), use_cache = FALSE)$result
  for (ds in names(direct$datasets)) {
    expect_equal(as.data.frame(res$result$datasets[[ds]]), as.data.frame(direct$datasets[[ds]]),
                 ignore_attr = TRUE, info = ds)
  }
})
