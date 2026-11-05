testthat::local_edition(3)

app_datasets <- c("ADSL", "ADRS", "ADRS_EFF", "ADLB", "ADLBPCA", "ADTTE", "ADQS",
                  "ADAE", "ADAETTE", "ADEX", "ADEG", "ADVS", "ADCM")

test_that("build_lumen_teal_data returns teal_data with every dataset", {
  local_lumen_project()
  local_global_cache()
  data <- suppressMessages(build_lumen_teal_data())
  expect_s4_class(data, "teal_data")
  expect_true(all(app_datasets %in% names(data)))
  cached <- get(".lumen_cache", envir = globalenv())
  for (ds in app_datasets) expect_identical(data[[ds]], cached$datasets[[ds]], info = ds)
  expect_type(data[[".lumen"]]$meta$adsl_char_vars, "character")
  expect_identical(data[[".lumen"]]$source$source, "bundled")
})

test_that("join keys: every dataset is a child of ADSL, ADRS_EFF mirrors ADRS", {
  local_lumen_project()
  local_global_cache()
  jk <- teal.data::join_keys(suppressMessages(build_lumen_teal_data()))
  parents <- teal.data::parents(jk)
  for (ds in setdiff(app_datasets, "ADSL")) expect_identical(parents[[ds]], "ADSL", info = ds)
  expect_setequal(unname(jk["ADRS_EFF", "ADRS_EFF"]), unname(jk["ADRS", "ADRS"]))
  expect_setequal(unname(jk["ADSL", "ADRS_EFF"]), c("STUDYID", "USUBJID"))
})

test_that("reproducible code loads packages in a safe order and uses the pipeline", {
  local_lumen_project()
  local_global_cache()
  code <- paste(teal.code::get_code(suppressMessages(build_lumen_teal_data())), collapse = "\n")
  expect_match(code, "load_lumen_data(cache_global = FALSE)", fixed = TRUE)
  # MASS before dplyr, otherwise MASS::select() masks dplyr::select()
  expect_lt(regexpr("library(MASS)", code, fixed = TRUE), regexpr("library(dplyr)", code, fixed = TRUE))
})

test_that("wrong working directory gives a clear error", {
  local_lumen_project()
  withr::local_dir(withr::local_tempdir())
  expect_error(build_lumen_teal_data(), "scripts not found")
})

test_that("data errors surface with their real message (not as a join_keys error)", {
  local_lumen_project()
  local_global_cache()
  withr::local_options(lumen.data_source = "parquet", lumen.parquet_dir = file.path(tempdir(), "no-such-folder"))
  expect_error(suppressMessages(build_lumen_teal_data()), "Parquet folder not found")
})
