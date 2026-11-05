# =============================================================================
# Lumen - Data ingestion
#
# Returns the *raw* ADaM datasets as a named list (ADSL, ADAE, ...), exactly as
# delivered by the data source. No study-specific manipulation happens here
# (see preprocess.R). Every source is checked against the same data contract.
#
# Data sources (option `lumen.data_source`):
#   "bundled"   Pre-generated datasets shipped with {random.cdisc.data}
#               (cadsl, cadae, ...). Fast; always the same data.
#   "synthetic" Freshly generated synthetic data (random.cdisc.data::radsl(),
#               radae(), ...). Settings in option `lumen.synthetic`:
#                 list(N = 400, seed = 2025, args = list(ADAE = list(max_n_aes = 5)))
#               - N:    number of subjects
#               - seed: change it for a new draw; NA draws a random seed once
#                       per session (reported in the console)
#               - args: extra arguments per dataset, passed to the rad*() call
#   "parquet"   Every ADaM parquet file in a folder (option `lumen.parquet_dir`,
#               default "cache"): adsl.parquet, adae.parquet, ... or
#               adsl_adam.parquet, ... (case-insensitive). Needs {arrow}.
#               Other files in the folder are ignored.
#
# This file only defines functions (no side effects when sourced).
# =============================================================================

lumen_data_sources <- function() c("bundled", "synthetic", "parquet")

#' Ingest raw ADaM datasets from the configured source
#'
#' @return Named list of data.frames; validated against `adam_contract()`.
ingest_adam <- function(source = getOption("lumen.data_source", "bundled"),
                        synthetic = getOption("lumen.synthetic", list()),
                        parquet_dir = getOption("lumen.parquet_dir", "cache")) {
  config <- lumen_source_config(source, synthetic, parquet_dir)
  raw <- switch(config$source,
                bundled = ingest_bundled(),
                synthetic = ingest_synthetic(config$synthetic),
                parquet = ingest_parquet(config$parquet_dir)
  )
  extra <- setdiff(names(raw), names(adam_contract()))
  if (length(extra)) {
    message("[lumen] Datasets read but not used by the app: ", toString(extra))
  }
  validate_adam(raw)
  check_app_defaults(raw)
  raw
}

#' Resolve and normalise the data-source settings
lumen_source_config <- function(source = getOption("lumen.data_source", "bundled"),
                                synthetic = getOption("lumen.synthetic", list()),
                                parquet_dir = getOption("lumen.parquet_dir", "cache")) {
  source <- match.arg(source, lumen_data_sources())
  list(
    source = source,
    synthetic = if (source == "synthetic") synthetic_settings(synthetic),
    parquet_dir = if (source == "parquet") normalizePath(parquet_dir, winslash = "/", mustWork = FALSE)
  )
}

#' Fingerprint of the data source, used to invalidate the cache
lumen_source_fingerprint <- function(config) {
  rcd_version <- function() {
    tryCatch(as.character(utils::packageVersion("random.cdisc.data")), error = function(e) NA_character_)
  }
  switch(config$source,
         bundled = paste("bundled", rcd_version()),
         synthetic = paste("synthetic", rcd_version(), deparse1(config$synthetic)),
         parquet = {
           files <- adam_parquet_files(config$parquet_dir)
           info <- file.info(files)
           paste("parquet", config$parquet_dir, paste(basename(files), info$size, format(as.numeric(info$mtime), nsmall = 3), collapse = ";"))
         }
  )
}

# ---- Source: bundled ----------------------------------------------------------

ingest_bundled <- function() {
  list(
    ADSL    = random.cdisc.data::cadsl,
    ADAE    = random.cdisc.data::cadae,
    ADAETTE = random.cdisc.data::cadaette,
    ADCM    = random.cdisc.data::cadcm,
    ADEG    = random.cdisc.data::cadeg,
    ADEX    = random.cdisc.data::cadex,
    ADLB    = random.cdisc.data::cadlb,
    ADQS    = random.cdisc.data::cadqs,
    ADRS    = random.cdisc.data::cadrs,
    ADTTE   = random.cdisc.data::cadtte,
    ADVS    = random.cdisc.data::cadvs
  )
}

# ---- Source: freshly generated synthetic data --------------------------------

#' Complete and check the synthetic-data settings
#'
#' A missing/NA seed means "random": a seed is drawn once and written back to
#' option `lumen.synthetic`, so every later call in the session (including the
#' app's reproducible R code) generates the very same data.
synthetic_settings <- function(settings = list()) {
  settings <- as.list(settings)
  random_seed <- "seed" %in% names(settings) &&
    (is.null(settings[["seed"]]) || (length(settings[["seed"]]) == 1 && is.na(settings[["seed"]])))
  settings <- settings[!vapply(settings, is.null, logical(1))]
  s <- utils::modifyList(list(N = 400L, seed = 2025L, args = list()), settings)
  
  if (random_seed) {
    s$seed <- sample.int(.Machine$integer.max, 1L)
    options(lumen.synthetic = utils::modifyList(settings, list(seed = s$seed)))
    message("[lumen] Random synthetic-data seed: ", s$seed,
            " (set options(lumen.synthetic = list(seed = ", s$seed, ")) to reproduce)")
  }
  
  if (!is.numeric(s$N) || length(s$N) != 1 || is.na(s$N) || s$N < 1 || s$N != round(s$N)) {
    stop("[lumen] lumen.synthetic$N must be a single positive whole number.", call. = FALSE)
  }
  if (!is.numeric(s$seed) || length(s$seed) != 1) {
    stop("[lumen] lumen.synthetic$seed must be a single number (or NA for a random seed).", call. = FALSE)
  }
  unknown <- setdiff(names(s$args), names(adam_contract()))
  if (!is.list(s$args) || length(unknown)) {
    stop("[lumen] lumen.synthetic$args must be a list named by dataset (",
         toString(names(adam_contract())), "). Unknown: ", toString(unknown), call. = FALSE)
  }
  s$N <- as.integer(s$N)
  s$seed <- as.integer(s$seed)
  s
}

ingest_synthetic <- function(settings = synthetic_settings()) {
  generate <- function(dataset, fun, base_args) {
    f <- getExportedValue("random.cdisc.data", fun)
    do.call(f, utils::modifyList(base_args, as.list(settings$args[[dataset]])))
  }
  adsl <- generate("ADSL", "radsl", list(N = settings$N, seed = settings$seed))
  child <- function(dataset, fun) generate(dataset, fun, list(adsl = adsl, seed = settings$seed))
  list(
    ADSL    = adsl,
    ADAE    = child("ADAE", "radae"),
    ADAETTE = child("ADAETTE", "radaette"),
    ADCM    = child("ADCM", "radcm"),
    ADEG    = child("ADEG", "radeg"),
    ADEX    = child("ADEX", "radex"),
    ADLB    = child("ADLB", "radlb"),
    ADQS    = child("ADQS", "radqs"),
    ADRS    = child("ADRS", "radrs"),
    ADTTE   = child("ADTTE", "radtte"),
    ADVS    = child("ADVS", "radvs")
  )
}

# ---- Source: parquet folder --------------------------------------------------

#' Dataset name from a parquet file name: adsl.parquet / adsl_adam.parquet -> "ADSL"
adam_name_from_file <- function(path) {
  toupper(sub("_?adam\\.parquet$|\\.parquet$", "", basename(path), ignore.case = TRUE))
}

#' ADaM parquet files in a folder, named by dataset
adam_parquet_files <- function(dir) {
  if (!dir.exists(dir)) {
    stop("[lumen] Parquet folder not found: ", dir, call. = FALSE)
  }
  files <- sort(list.files(dir, pattern = "\\.parquet$", ignore.case = TRUE, full.names = TRUE))
  names(files) <- adam_name_from_file(files)
  files <- files[grepl("^AD[A-Z0-9_]+$", names(files))]
  if (!length(files)) {
    stop("[lumen] No ADaM parquet files (ad*.parquet or ad*_adam.parquet) in: ", dir, call. = FALSE)
  }
  dup <- unique(names(files)[duplicated(names(files))])
  if (length(dup)) {
    stop("[lumen] More than one parquet file for: ", toString(dup), " in ", dir, call. = FALSE)
  }
  files
}

require_arrow <- function(available = requireNamespace("arrow", quietly = TRUE)) {
  if (!isTRUE(available)) {
    stop("[lumen] The parquet data source needs the 'arrow' package. Install it with:\n",
         "  renv::install(\"arrow\"); renv::snapshot()", call. = FALSE)
  }
}

ingest_parquet <- function(dir = getOption("lumen.parquet_dir", "cache")) {
  require_arrow()
  files <- adam_parquet_files(dir)
  lapply(files, arrow::read_parquet)
}

#' Write datasets as <name>.parquet (e.g. adsl.parquet), the layout read by
#' the "parquet" source. Typical use: freeze a synthetic draw or hand data over.
#'   export_adam_parquet(ingest_adam("synthetic", list(N = 200, seed = 7)), "cache")
export_adam_parquet <- function(datasets, dir, overwrite = FALSE) {
  require_arrow()
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  paths <- file.path(dir, paste0(tolower(names(datasets)), ".parquet"))
  if (!overwrite && any(file.exists(paths))) {
    stop("[lumen] Files already exist (use overwrite = TRUE): ", toString(basename(paths[file.exists(paths)])), call. = FALSE)
  }
  for (i in seq_along(datasets)) arrow::write_parquet(datasets[[i]], paths[[i]])
  invisible(stats::setNames(paths, names(datasets)))
}

# ---- Data contract -----------------------------------------------------------

#' Datasets and columns the app needs from *any* source (raw, pre-processing level)
adam_contract <- function() {
  list(
    ADSL = c("STUDYID", "USUBJID", "AGE", "SEX", "RACE", "COUNTRY", "REGION1", "ARM", "ARMCD",
             "ACTARM", "ACTARMCD", "SAFFL", "ITTFL", "STRATA1", "STRATA2", "BMRKR1", "BMRKR2"),
    ADAE = c("STUDYID", "USUBJID", "AETERM", "AEDECOD", "AEBODSYS", "AESOC", "AETOXGR", "AESER",
             "AEREL", "SMQ01NAM", "SMQ01SC", "SMQ02NAM", "SMQ02SC", "CQ01NAM"),
    ADAETTE = c("STUDYID", "USUBJID", "ARM", "ARMCD", "PARAMCD", "AVAL", "CNSR"),
    ADCM = c("STUDYID", "USUBJID", "CMSEQ", "ATC2", "CMDECOD"),
    ADEG = c("STUDYID", "USUBJID", "PARAMCD", "AVISIT", "AVAL", "ANRIND", "BNRIND"),
    ADEX = c("STUDYID", "USUBJID", "PARAMCD", "PARAM", "AVAL", "PARCAT1", "PARCAT2"),
    ADLB = c("STUDYID", "USUBJID", "SEX", "ARMCD", "PARAMCD", "PARAM", "AVISIT", "AVAL", "BASE",
             "CHG", "PCHG", "ANRIND", "AVALU", "ATOXGR", "BTOXGR", "WGRLOVFL", "WGRLOFL",
             "WGRHIVFL", "WGRHIFL"),
    ADQS = c("STUDYID", "USUBJID", "PARAMCD", "AVISIT", "AVISITN", "AVAL", "BASE", "CHG", "PCHG",
             "ABLFL", "ABLFL2"),
    ADRS = c("STUDYID", "USUBJID", "PARAMCD", "AVISIT", "AVAL", "AVALC"),
    ADTTE = c("STUDYID", "USUBJID", "PARAMCD", "AVAL", "CNSR", "EVNTDESC"),
    ADVS = c("STUDYID", "USUBJID", "PARAMCD", "PARAM", "AVISIT", "ANRIND", "BNRIND")
  )
}

#' Check raw datasets against the contract. Errors list *every* problem at once.
validate_adam <- function(raw, contract = adam_contract()) {
  problems <- character(0)
  missing_ds <- setdiff(names(contract), names(raw))
  if (length(missing_ds)) problems <- c(problems, paste("missing datasets:", toString(missing_ds)))
  
  for (ds in intersect(names(contract), names(raw))) {
    x <- raw[[ds]]
    if (!is.data.frame(x)) {
      problems <- c(problems, sprintf("%s is not a data.frame", ds))
      next
    }
    if (nrow(x) == 0) problems <- c(problems, sprintf("%s has no rows", ds))
    missing_cols <- setdiff(contract[[ds]], names(x))
    if (length(missing_cols)) problems <- c(problems, sprintf("%s is missing columns: %s", ds, toString(missing_cols)))
  }
  
  adsl <- raw[["ADSL"]]
  if (is.data.frame(adsl) && "USUBJID" %in% names(adsl) && anyDuplicated(adsl$USUBJID)) {
    problems <- c(problems, "ADSL has duplicated USUBJID values (must be one row per subject)")
  }
  if (length(problems)) {
    stop("[lumen] The ADaM data does not meet the app's data contract:\n  - ",
         paste(problems, collapse = "\n  - "), call. = FALSE)
  }
  
  # Subjects in analysis datasets without an ADSL record are dropped by the
  # ADSL-based filters, so flag them (warning, not error: it can be legitimate)
  orphans <- vapply(setdiff(names(contract), "ADSL"), function(ds) {
    length(setdiff(unique(as.character(raw[[ds]]$USUBJID)), as.character(adsl$USUBJID)))
  }, integer(1))
  if (any(orphans > 0)) {
    warning("[lumen] Subjects without an ADSL record: ",
            toString(sprintf("%s (%d)", names(orphans)[orphans > 0], orphans[orphans > 0])), call. = FALSE)
  }
  invisible(TRUE)
}

#' Values the app's modules select by default (see app.R). Data without them
#' still loads, but those defaults will need adjusting.
adam_app_defaults <- function() {
  list(
    list("ADSL", "ARMCD", c("ARM A", "ARM B", "ARM C")),
    list("ADSL", "ARM", c("A: Drug X", "B: Placebo", "C: Combination")),
    list("ADAETTE", "PARAMCD", c("AETTE1", "AEREPTTE")),
    list("ADEG", "PARAMCD", "HR"),
    list("ADEG", "AVISIT", "POST-BASELINE MINIMUM"),
    list("ADEX", "PARAMCD", "TDOSE"),
    list("ADEX", "PARCAT1", "OVERALL"),
    list("ADEX", "PARCAT2", "Drug A"),
    list("ADLB", "PARAMCD", c("ALT", "CRP", "IGA")),
    list("ADLB", "AVISIT", c("SCREENING", "WEEK 5 DAY 36")),
    list("ADQS", "PARAMCD", "FKSI-FWB"),
    list("ADQS", "AVISIT", "WEEK 1 DAY 8"),
    list("ADRS", "PARAMCD", c("BESRSPI", "INVET")),
    list("ADTTE", "PARAMCD", "OS")
  )
}

check_app_defaults <- function(raw, defaults = adam_app_defaults()) {
  missing <- unlist(lapply(defaults, function(d) {
    x <- raw[[d[[1]]]][[d[[2]]]]
    absent <- setdiff(d[[3]], unique(as.character(x)))
    if (length(absent)) sprintf("%s$%s: %s", d[[1]], d[[2]], toString(absent))
  }))
  if (length(missing)) {
    warning("[lumen] Values used as default selections in the app are not in the data ",
            "(update app.R): ", paste(missing, collapse = "; "), call. = FALSE)
  }
  invisible(missing)
}
