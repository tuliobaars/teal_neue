#' teal_neue options
#'
#' All settings are regular R options. Set them before building the app (or
#' pass the equivalent arguments to [run_app()] / [load_teal_neue_data()]).
#'
#' @section Data source:
#' \describe{
#'   \item{`teal_neue.data_source`}{`"bundled"` (default), `"synthetic"` or
#'     `"parquet"`. See [ingest_adam()].}
#'   \item{`teal_neue.synthetic`}{Settings for the `"synthetic"` source:
#'     `list(N = 400, seed = 2025, args = list())`. `N` is the number of
#'     subjects; change `seed` for a new draw (`NA` draws a random seed once per
#'     session); `args` holds extra arguments per dataset for the
#'     `random.cdisc.data::rad*()` generators, e.g.
#'     `list(ADAE = list(max_n_aes = 5))`.}
#'   \item{`teal_neue.parquet_dir`}{Folder read by the `"parquet"` source
#'     (default `"cache"`).}
#' }
#'
#' @section Caching:
#' \describe{
#'   \item{`teal_neue.use_cache`}{Use the session memory and disk caches
#'     (default `TRUE`).}
#'   \item{`teal_neue.refresh_cache`}{Force re-ingestion and re-processing
#'     (default `FALSE`).}
#'   \item{`teal_neue.cache_global`}{Copy every dataset (`ADSL`, `ADAE`, ...) into
#'     the Global Environment for easy console access (default `FALSE`;
#'     [run_app()] turns it on).}
#'   \item{`teal_neue.app_cache`}{Keep the built app in memory for the R
#'     session and reuse it when [run_app()] is called again with the same
#'     settings and data (instant relaunch), and serve the app's page from
#'     memory after the first request (default `TRUE`).}
#'   \item{`teal_neue.cache_dir`}{Folder of the disk cache (default
#'     `tools::R_user_dir("teal.neue", "cache")`).}
#' }
#'
#' @section Look and feel:
#' \describe{
#'   \item{`teal_neue.style`}{Use the teal_neue look and its interactive
#'     layer: the header with the breadcrumb and command bar (Ctrl/Cmd+K),
#'     keyboard shortcuts, deep links, plot and table tools, pins and the
#'     viewer, refined light and dark palettes, self-hosted fonts and cleaner
#'     plot defaults (default `TRUE`). `FALSE` gives the plain teal look of
#'     the source templates.}
#'   \item{`teal_neue.motion`}{Animations (default `TRUE`): short
#'     transitions, the sliding tab indicator, the colour-mode reveal. `FALSE`
#'     turns them off; they are also off for users who ask their system for
#'     reduced motion.}
#'   \item{`teal_neue.color_mode`}{Colour mode for first-time visitors:
#'     `"light"` (default), `"dark"` or `"auto"` (follows the operating
#'     system). A choice made with the header toggle is remembered by the
#'     browser and takes precedence.}
#'   \item{`teal_neue.ggtheme`}{Default ggplot2 theme of the exploratory plot
#'     modules (default `"minimal"`; any of `"gray"`, `"bw"`, `"linedraw"`,
#'     `"light"`, `"dark"`, `"minimal"`, `"classic"`). Users can still change it
#'     in each module. `NULL` keeps each module's own default.}
#' }
#'
#' The app also sets two options of its building blocks, only if you have not
#' set them yourself: `teal.ggplot2_args` (plot captions and typography, see
#' [teal_neue_ggplot2_args()]) and `shiny.useragg` (`FALSE`, as in the
#' teal.gallery templates).
#'
#' @examples
#' \dontrun{
#' options(teal_neue.data_source = "synthetic", teal_neue.synthetic = list(N = 200, seed = 7))
#' options(teal_neue.color_mode = "dark")
#' run_app()
#' }
#' @name teal_neue_options
NULL

teal_neue_cache_dir_default <- function() {
  getOption("teal_neue.cache_dir", tools::R_user_dir("teal.neue", which = "cache"))
}

#' @noRd
teal_neue_style_enabled <- function(style = getOption("teal_neue.style", TRUE)) {
  if (!(isTRUE(style) || isFALSE(style))) {
    stop("[teal_neue] Option teal_neue.style must be TRUE or FALSE.", call. = FALSE)
  }
  style
}

#' @noRd
teal_neue_color_mode <- function(mode = getOption("teal_neue.color_mode", "light")) {
  modes <- c("auto", "light", "dark")
  if (!(is.character(mode) && length(mode) == 1 && mode %in% modes)) {
    stop("[teal_neue] Option teal_neue.color_mode must be one of: ", toString(dQuote(modes, FALSE)), call. = FALSE)
  }
  mode
}

#' @noRd
teal_neue_motion <- function(motion = getOption("teal_neue.motion", TRUE)) {
  if (!(isTRUE(motion) || isFALSE(motion))) {
    stop("[teal_neue] Option teal_neue.motion must be TRUE or FALSE.", call. = FALSE)
  }
  motion
}

#' @noRd
teal_neue_ggtheme <- function(ggtheme = getOption("teal_neue.ggtheme", "minimal")) {
  themes <- c("gray", "bw", "linedraw", "light", "dark", "minimal", "classic", "void")
  if (!is.null(ggtheme) && !(is.character(ggtheme) && length(ggtheme) == 1 && ggtheme %in% themes)) {
    stop("[teal_neue] Option teal_neue.ggtheme must be NULL or one of: ", toString(dQuote(themes, FALSE)), call. = FALSE)
  }
  ggtheme
}

