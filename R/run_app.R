#' Run the teal_neue app
#'
#' `teal_neue_app()` builds the teal app: data ([build_teal_neue_data()]),
#' the exploratory, safety and efficacy module groups, module-specific filters
#' (safety modules start on the safety population, efficacy modules on the
#' intent-to-treat population), the header with the dark mode toggle and the
#' teal_neue look (see the "Look and feel" section of [teal_neue_options]).
#' `run_app()` wraps it in a Shiny app object, which starts the app when
#' printed at the console (or when returned from an `app.R` file).
#'
#' @inheritParams load_teal_neue_data
#' @param cache_global Copy every dataset into the Global Environment for easy
#'   console access? `run_app()` defaults to `TRUE`.
#' @return `teal_neue_app()`: a teal app (list with `ui` and `server`).
#'   `run_app()`: a `shiny.appobj`.
#' @seealso [teal_neue_options] for all settings.
#' @examples
#' \dontrun{
#' run_app()
#' run_app(source = "synthetic", synthetic = list(N = 200, seed = 7))
#' run_app(source = "parquet", parquet_dir = "path/to/adam")
#' }
#' @export
run_app <- function(source = getOption("teal_neue.data_source", "bundled"),
                    synthetic = getOption("teal_neue.synthetic", list()),
                    parquet_dir = getOption("teal_neue.parquet_dir", "cache"),
                    cache_global = getOption("teal_neue.cache_global", TRUE)) {
  app <- teal_neue_app(source, synthetic, parquet_dir, cache_global)
  shiny::shinyApp(teal_neue_fast_ui(app$ui), app$server)
}

#' @rdname run_app
#' @export
teal_neue_app <- function(source = getOption("teal_neue.data_source", "bundled"),
                          synthetic = getOption("teal_neue.synthetic", list()),
                          parquet_dir = getOption("teal_neue.parquet_dir", "cache"),
                          cache_global = getOption("teal_neue.cache_global", FALSE)) {
  t0 <- Sys.time()
  steps <- character(0)
  tick <- function(what) {
    t1 <- Sys.time()
    steps[[length(steps) + 1L]] <<- sprintf("%s %.2fs", what, as.numeric(difftime(t1, t0, units = "secs")))
    t0 <<- t1
  }
  start <- t0
  style <- teal_neue_style_enabled()
  teal_neue_color_mode() # validate the option before building anything
  teal_neue_set_app_options()

  # The same app, built earlier in this R session with the same settings and
  # data, is reused: a relaunch is instant.
  key <- teal_neue_app_key(source, synthetic, parquet_dir, style)
  cached <- get0("app_cache", envir = the, inherits = FALSE)
  if (!is.null(key) && is.list(cached) && identical(cached$key, key)) {
    if (isTRUE(cache_global)) load_teal_neue_data(source, synthetic, parquet_dir, cache_global = TRUE)
    message(sprintf(
      "[teal_neue] App reused from this R session in %.2fs",
      as.numeric(difftime(Sys.time(), start, units = "secs"))
    ))
    return(cached$app)
  }

  data <- build_teal_neue_data(source, synthetic, parquet_dir, cache_global)
  tick("data")
  modules <- teal_neue_modules(data)
  tick("modules")
  data_label <- teal_neue_data_label(data[[".teal_neue"]]$source, nrow(data[["ADSL"]]))
  index <- if (style) teal_neue_index(modules, overview = teal_neue_app_overview(data, modules))
  tick("overview")

  app <- teal::init(
    data = data,
    filter = teal_neue_filters(modules),
    modules = modules
  ) |>
    teal::modify_title(title = "teal_neue \u00b7 Clinical Trial Analysis", favicon = teal_neue_favicon()) |>
    teal::modify_header(teal_neue_header(data_label, style = style, index = index)) |>
    teal::modify_footer(teal_neue_footer(style = style))
  tick("teal")

  if (!is.null(key)) assign("app_cache", list(key = key, app = app), envir = the)
  message(sprintf(
    "[teal_neue] App built in %.1fs (%s)",
    as.numeric(difftime(Sys.time(), start, units = "secs")), paste(steps, collapse = ", ")
  ))
  app
}

#' Key of the app cache: everything the app depends on
#'
#' `NULL` (no caching) when option `teal_neue.app_cache` is `FALSE` or a
#' data refresh is requested.
#' @noRd
teal_neue_app_key <- function(source, synthetic, parquet_dir, style) {
  if (!isTRUE(getOption("teal_neue.app_cache", TRUE)) || isTRUE(getOption("teal_neue.refresh_cache", FALSE))) {
    return(NULL)
  }
  config <- tryCatch(teal_neue_source_config(source, synthetic, parquet_dir), error = function(e) NULL)
  if (is.null(config)) return(NULL)
  rlang::hash(list(
    version = teal_neue_version(),
    data = teal_neue_data_signature(config),
    style = style,
    color_mode = teal_neue_color_mode(),
    motion = teal_neue_motion(),
    ggtheme = teal_neue_ggtheme(),
    ggplot2_args = getOption("teal.ggplot2_args")
  ))
}

#' Serve the app's page from memory
#'
#' teal builds the page (every module's interface) on each browser request.
#' The page does not change between requests, so the first one is kept and
#' served again: reloads and new sessions get the page at once. Requests with
#' a query string (e.g. a bookmark to restore) are always built afresh.
#' @param ui The app's UI: a function of the request, or a tag list.
#' @noRd
teal_neue_fast_ui <- function(ui) {
  if (!is.function(ui) || !isTRUE(getOption("teal_neue.app_cache", TRUE))) return(ui)
  page <- NULL
  function(request) {
    query <- if (is.null(request)) NULL else request$QUERY_STRING
    plain <- is.null(query) || !nzchar(as.character(query))
    if (plain && !is.null(page)) return(page)
    out <- if (length(formals(ui))) ui(request) else ui()
    if (plain) page <<- out
    out
  }
}
