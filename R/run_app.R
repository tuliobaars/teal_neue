#' Run the Lumen app
#'
#' `lumen_app()` builds the teal app: data ([build_lumen_teal_data()]),
#' the exploratory, safety and efficacy module groups, module-specific filters
#' (safety modules start on the safety population, efficacy modules on the
#' intent-to-treat population) and the header with the dark mode toggle.
#' `run_app()` wraps it in a Shiny app object, which starts the app when
#' printed at the console (or when returned from an `app.R` file).
#'
#' @inheritParams load_lumen_data
#' @param cache_global Copy every dataset into the Global Environment for easy
#'   console access? `run_app()` defaults to `TRUE`.
#' @return `lumen_app()`: a teal app (list with `ui` and `server`).
#'   `run_app()`: a `shiny.appobj`.
#' @seealso [lumen_options] for all settings.
#' @examples
#' \dontrun{
#' run_app()
#' run_app(source = "synthetic", synthetic = list(N = 200, seed = 7))
#' run_app(source = "parquet", parquet_dir = "path/to/adam")
#' }
#' @export
run_app <- function(source = getOption("lumen.data_source", "bundled"),
                    synthetic = getOption("lumen.synthetic", list()),
                    parquet_dir = getOption("lumen.parquet_dir", "cache"),
                    cache_global = getOption("lumen.cache_global", TRUE)) {
  app <- lumen_app(source, synthetic, parquet_dir, cache_global)
  shiny::shinyApp(app$ui, app$server)
}

#' @rdname run_app
#' @export
lumen_app <- function(source = getOption("lumen.data_source", "bundled"),
                      synthetic = getOption("lumen.synthetic", list()),
                      parquet_dir = getOption("lumen.parquet_dir", "cache"),
                      cache_global = getOption("lumen.cache_global", FALSE)) {
  t0 <- Sys.time()
  lumen_set_app_options()
  data <- build_lumen_teal_data(source, synthetic, parquet_dir, cache_global)
  modules <- lumen_modules(data)

  app <- teal::init(
    data = data,
    filter = lumen_filters(modules),
    modules = modules
  ) |>
    teal::modify_title(title = "Lumen: Clinical Trial Analysis", favicon = lumen_favicon) |>
    teal::modify_header(lumen_header()) |>
    teal::modify_footer(lumen_footer())

  message(sprintf("[lumen] App built in %.1fs", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  app
}

#' Display options from the teal.gallery templates (only set when unset)
#' @noRd
lumen_set_app_options <- function() {
  if (is.null(getOption("shiny.useragg"))) options(shiny.useragg = FALSE)
  if (is.null(getOption("teal.ggplot2_args"))) {
    options(teal.ggplot2_args = teal.widgets::ggplot2_args(labs = list(caption = "NEST PROJECT")))
  }
  invisible()
}
