testthat::local_edition(3)

# Builds the whole app from app.R (without launching it) once for this file.
app_env <- local({
  env <- NULL
  function() {
    if (is.null(env)) {
      # project wd + isolated options only while app.R is being built
      local_lumen_project(env = environment())
      e <- new.env()
      warnings <- character(0)
      withCallingHandlers(
        sys.source(file.path(lumen_root, "app.R"), envir = e),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        },
        message = function(m) invokeRestart("muffleMessage")
      )
      e$.warnings <- warnings
      env <<- e
    }
    env
  }
})

leaf_modules <- function(x) {
  if (inherits(x, "teal_modules")) do.call(c, lapply(x$children, leaf_modules)) else list(x)
}
group_nodes <- function(x) {
  if (!inherits(x, "teal_modules")) return(list())
  c(list(x), do.call(c, lapply(x$children, group_nodes)))
}

test_that("app.R builds the teal app without warnings", {
  local_global_cache()
  env <- app_env()
  expect_true(is.function(env$app$server))
  expect_false(is.null(env$app$ui))
  expect_identical(env$.warnings, character(0))
})

test_that("the UI renders (regression: unlabeled module group broke ui_teal)", {
  env <- app_env()
  ui <- if (is.function(env$app$ui)) env$app$ui(list()) else env$app$ui
  html <- htmltools::renderTags(ui)$html
  expect_match(html, "lumen_dark_mode", fixed = TRUE)
  expect_match(html, "Lumen: Clinical Trial Analysis", fixed = TRUE)
  expect_no_match(html, "Roche|Genentech")
})

test_that("every module group has a label and all module labels are unique", {
  env <- app_env()
  groups <- group_nodes(env$all_modules)[-1] # the root may be unlabeled
  for (g in groups) expect_true(length(g$label) == 1 && nzchar(g$label))
  expect_false(anyDuplicated(env$all_labels) > 0)
  expect_identical(
    vapply(env$all_modules$children, function(x) x$label, character(1))[4:6],
    c("Exploratory Analysis", "Safety Analysis", "Efficacy Analysis")
  )
})

test_that("every module only refers to datasets that exist", {
  env <- app_env()
  used <- unique(unlist(lapply(leaf_modules(env$all_modules), function(m) m$datanames)))
  expect_identical(setdiff(used, c("all", names(env$data))), character(0))
})

test_that("module-specific filters: mapping refers to real modules and filter ids", {
  env <- app_env()
  mapping <- attr(env$filters, "mapping")
  ids <- vapply(env$filters, function(s) shiny::isolate(s$id), character(1))
  expect_true(all(unlist(mapping) %in% ids))
  expect_true(all(names(mapping) %in% c(env$all_labels, "global_filters")))
  expect_setequal(mapping$global_filters, c("ADSL SEX", "ADSL AGE"))
  safety <- vapply(leaf_modules(env$safety_modules), function(m) m$label, character(1))
  efficacy <- vapply(leaf_modules(env$efficacy_modules), function(m) m$label, character(1))
  for (l in safety) expect_true("ADSL SAFFL" %in% mapping[[l]], info = l)
  for (l in efficacy) expect_true("ADSL ITTFL" %in% mapping[[l]], info = l)
  for (l in setdiff(env$all_labels, c(safety, efficacy))) {
    expect_false(any(c("ADSL SAFFL", "ADSL ITTFL") %in% mapping[[l]]), info = l)
  }
})
