app_datasets <- c("ADSL", "ADRS", "ADRS_EFF", "ADLB", "ADLBPCA", "ADTTE", "ADQS",
                  "ADAE", "ADAETTE", "ADEX", "ADEG", "ADVS", "ADCM")

build_quiet <- function(...) suppressMessages(build_lumen_teal_data(..., cache_global = FALSE))

test_that("build_lumen_teal_data returns teal_data with every dataset", {
  local_lumen_options()
  data <- build_quiet()
  expect_s4_class(data, "teal_data")
  expect_true(all(app_datasets %in% names(data)))
  cached <- get("data_cache", envir = the)
  for (ds in app_datasets) expect_identical(data[[ds]], cached$datasets[[ds]], info = ds)
  expect_type(data[[".lumen"]]$meta$adsl_char_vars, "character")
  expect_identical(data[[".lumen"]]$source$source, "bundled")
})

test_that("join keys: every dataset is a child of ADSL (incl. derived ADRS_EFF and ADLBPCA)", {
  jk <- lumen_join_keys()
  parents <- teal.data::parents(jk)
  for (ds in setdiff(app_datasets, "ADSL")) expect_identical(parents[[ds]], "ADSL", info = ds)
  expect_setequal(unname(jk["ADRS_EFF", "ADRS_EFF"]), unname(jk["ADRS", "ADRS"]))
  for (ds in c("ADRS_EFF", "ADLBPCA")) {
    expect_setequal(unname(jk["ADSL", ds]), c("STUDYID", "USUBJID"))
  }
})

test_that("primary keys of the derived and subject-level datasets are unique in the data", {
  local_lumen_options()
  data <- build_quiet()
  jk <- teal.data::join_keys(data)
  for (ds in c("ADSL", "ADRS_EFF", "ADLBPCA")) {
    keys <- unname(jk[ds, ds])
    expect_true(length(keys) > 0, info = ds)
    expect_false(anyDuplicated(as.data.frame(data[[ds]])[keys]) > 0, info = ds)
  }
})

test_that("reproducible code: safe package order, resolved source settings", {
  local_lumen_options()
  code <- paste(teal.code::get_code(build_quiet(source = "synthetic", synthetic = list(N = 30, seed = 11))), collapse = "\n")
  expect_match(code, "lumen::load_lumen_data(", fixed = TRUE)
  expect_match(code, 'source = "synthetic"', fixed = TRUE)
  expect_match(code, "seed = 11L", fixed = TRUE)
  expect_match(code, "cache_global = FALSE", fixed = TRUE)
  # MASS before dplyr, otherwise MASS::select() masks dplyr::select()
  expect_lt(regexpr("library(MASS)", code, fixed = TRUE), regexpr("library(dplyr)", code, fixed = TRUE))
})

test_that("the 'Show R code' output reproduces the app's data in a fresh environment", {
  local_lumen_options()
  data <- build_quiet()
  code <- paste(teal.code::get_code(data), collapse = "\n")
  env <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = code), envir = env))
  for (ds in app_datasets) expect_identical(env[[ds]], data[[ds]], info = ds)
})

test_that("data errors surface with their real message (not as a join_keys error)", {
  local_lumen_options()
  expect_error(
    build_quiet(source = "parquet", parquet_dir = file.path(tempdir(), "no-such-folder")),
    "Parquet folder not found"
  )
})
