# Launch teal_neue from the project folder (RStudio "Run App", Posit Connect, ...).
# With the package installed you can simply call teal.neue::run_app().
#
# Settings (see ?teal_neue_options), e.g.:
#   options(teal_neue.data_source = "synthetic", teal_neue.synthetic = list(N = 200, seed = 7))
#   options(teal_neue.data_source = "parquet", teal_neue.parquet_dir = "path/to/adam")
#   options(teal_neue.color_mode = "dark")   # default colour mode ("light"; "auto" follows the OS)
#   options(teal_neue.style = FALSE)         # plain teal look of the source templates

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE)
teal.neue::run_app()
