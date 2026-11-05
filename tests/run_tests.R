# Run the Lumen test suite from the project root:
#   Rscript tests/run_tests.R
# or, in RStudio, source("tests/run_tests.R").
#
# Quick run (bundled data only, skips the synthetic/parquet scenarios):
#   Sys.setenv(LUMEN_TEST_SCENARIOS = "bundled"); source("tests/run_tests.R")
#
# The parquet tests need {arrow}: renv::install("arrow"); renv::snapshot()
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
