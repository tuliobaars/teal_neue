#' Lumen options
#'
#' All settings are regular R options. Set them before building the app (or
#' pass the equivalent arguments to [run_app()] / [load_lumen_data()]).
#'
#' @section Data source:
#' \describe{
#'   \item{`lumen.data_source`}{`"bundled"` (default), `"synthetic"` or
#'     `"parquet"`. See [ingest_adam()].}
#'   \item{`lumen.synthetic`}{Settings for the `"synthetic"` source:
#'     `list(N = 400, seed = 2025, args = list())`. `N` is the number of
#'     subjects; change `seed` for a new draw (`NA` draws a random seed once per
#'     session); `args` holds extra arguments per dataset for the
#'     `random.cdisc.data::rad*()` generators, e.g.
#'     `list(ADAE = list(max_n_aes = 5))`.}
#'   \item{`lumen.parquet_dir`}{Folder read by the `"parquet"` source
#'     (default `"cache"`).}
#' }
#'
#' @section Caching:
#' \describe{
#'   \item{`lumen.use_cache`}{Use the session memory and disk caches
#'     (default `TRUE`).}
#'   \item{`lumen.refresh_cache`}{Force re-ingestion and re-processing
#'     (default `FALSE`).}
#'   \item{`lumen.cache_global`}{Copy every dataset (`ADSL`, `ADAE`, ...) into
#'     the Global Environment for easy console access (default `FALSE`;
#'     [run_app()] turns it on).}
#'   \item{`lumen.cache_dir`}{Folder of the disk cache (default
#'     `tools::R_user_dir("lumen", "cache")`).}
#' }
#'
#' @examples
#' \dontrun{
#' options(lumen.data_source = "synthetic", lumen.synthetic = list(N = 200, seed = 7))
#' run_app()
#' }
#' @name lumen_options
NULL

lumen_cache_dir_default <- function() {
  getOption("lumen.cache_dir", tools::R_user_dir("lumen", which = "cache"))
}
