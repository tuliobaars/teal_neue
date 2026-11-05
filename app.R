# Launch Lumen from the project folder (RStudio "Run App", Posit Connect, ...).
# With the package installed you can simply call lumen::run_app().
#
# Settings (see ?lumen_options), e.g.:
#   options(lumen.data_source = "synthetic", lumen.synthetic = list(N = 200, seed = 7))
#   options(lumen.data_source = "parquet", lumen.parquet_dir = "path/to/adam")

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE)
lumen::run_app()
