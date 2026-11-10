# Start-up speed: app cache, page cache, memoised registry

test_that("the page is built once for plain requests, always for requests with a query", {
  n <- 0
  ui <- function(request) {
    n <<- n + 1
    htmltools::div("page", n)
  }
  fast <- teal_neue_fast_ui(ui)
  a <- fast(list(QUERY_STRING = ""))
  b <- fast(list(QUERY_STRING = ""))
  expect_identical(a, b)
  expect_identical(n, 1)
  fast(list(QUERY_STRING = "?_state_id_=abc")) # e.g. a bookmark to restore
  expect_identical(n, 2)
  # switched off with the app cache
  withr::with_options(list(teal_neue.app_cache = FALSE), expect_identical(teal_neue_fast_ui(ui), ui))
  # a static UI is passed through
  tags <- htmltools::div("static")
  expect_identical(teal_neue_fast_ui(tags), tags)
})

test_that("the app cache key follows the settings and can be switched off", {
  skip_if_not_installed("teal.neue")
  k1 <- teal_neue_app_key("bundled", list(), "cache", TRUE)
  expect_type(k1, "character")
  expect_identical(teal_neue_app_key("bundled", list(), "cache", TRUE), k1)
  expect_false(identical(teal_neue_app_key("bundled", list(), "cache", FALSE), k1))
  withr::with_options(list(teal_neue.color_mode = "dark"), expect_false(identical(teal_neue_app_key("bundled", list(), "cache", TRUE), k1)))
  withr::with_options(list(teal_neue.refresh_cache = TRUE), expect_null(teal_neue_app_key("bundled", list(), "cache", TRUE)))
  withr::with_options(list(teal_neue.app_cache = FALSE), expect_null(teal_neue_app_key("bundled", list(), "cache", TRUE)))
})

test_that("the TLG Catalog registry is built once per session", {
  first <- tlg_catalog()
  expect_true(exists("tlg_catalog", envir = the, inherits = FALSE))
  expect_identical(tlg_catalog(), first)
  expect_identical(names(tlg_catalog_build()), names(first))
})

test_that("clearing the cache also forgets the app", {
  mem <- new.env()
  assign("app_cache", list(key = "k", app = list()), envir = mem)
  teal_neue_clear_cache(cache_dir = withr::local_tempdir(), memory_env = mem)
  expect_false(exists("app_cache", envir = mem, inherits = FALSE))
})
