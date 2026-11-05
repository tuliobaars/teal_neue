# =============================================================================
# Lumen - Pre-processing
#
# Turns the raw ADaM datasets from ingest.R into the analysis-ready datasets
# used by the app. The logic is taken unchanged from the three teal.gallery
# templates (app_exploratory.R, app_safety.R, app_efficacy.R); only the
# packaging changed (one function per dataset, fully namespaced calls so it
# runs without attaching packages and is immune to masking such as
# MASS::select() vs dplyr::select()).
#
# This file only defines functions (no side effects).
# =============================================================================

#' Run all pre-processing steps
#'
#' @param raw Named list returned by `ingest_adam()`.
#' @return A list with
#'   * `datasets`: named list of analysis-ready data.frames
#'   * `meta`: extra information needed by the app configuration
preprocess_adam <- function(raw) {
  list(
    datasets = list(
      # shared
      ADSL     = preprocess_adsl(raw$ADSL),
      ADLB     = raw$ADLB,
      # exploratory
      ADRS     = raw$ADRS,
      ADLBPCA  = derive_adlbpca(raw$ADLB),
      # efficacy
      ADRS_EFF = derive_adrs_efficacy(raw$ADRS),
      ADTTE    = raw$ADTTE,
      ADQS     = preprocess_adqs(raw$ADQS),
      # safety
      ADAE     = preprocess_adae(raw$ADAE),
      ADAETTE  = preprocess_adaette(raw$ADAETTE),
      ADEX     = preprocess_adex(raw$ADEX),
      ADEG     = raw$ADEG,
      ADVS     = preprocess_advs(raw$ADVS),
      ADCM     = preprocess_adcm(raw$ADCM)
    ),
    meta = list(
      # ADSL columns that were character before being converted to factors
      # (used by the efficacy "Cross Table" to offer only the original factors)
      adsl_char_vars = adsl_character_vars(raw$ADSL)
    )
  )
}

# ---- ADSL (shared; efficacy template pre-processing) -------------------------

adsl_character_vars <- function(adsl) {
  names(Filter(isTRUE, sapply(adsl, is.character)))
}

preprocess_adsl <- function(adsl) {
  labels <- teal.data::col_labels(adsl, fill = FALSE)
  char_vars <- adsl_character_vars(adsl)
  labels <- c(labels, AGEGR1 = "Age Group")
  
  adsl <- adsl |>
    dplyr::mutate(
      AGEGR1 = factor(dplyr::case_when(
        AGE < 45 ~ "<45",
        AGE >= 45 ~ ">=45"
      ))
    ) |>
    dplyr::mutate(dplyr::across(dplyr::all_of(char_vars), factor))
  
  teal.data::col_labels(adsl) <- labels
  adsl
}

# ---- Exploratory -------------------------------------------------------------

# Wide lab data (one column per PARAMCD x AVISIT) for the PCA module
derive_adlbpca <- function(adlb) {
  adlb |>
    dplyr::select(USUBJID, STUDYID, SEX, ARMCD, AVAL, AVISIT, PARAMCD) |>
    tidyr::pivot_wider(
      values_from = "AVAL",
      names_from = c("PARAMCD", "AVISIT"),
      names_sep = " - "
    )
}

# ---- Efficacy ----------------------------------------------------------------

# Efficacy response subset: best overall response + follow-up records
derive_adrs_efficacy <- function(adrs) {
  labels <- teal.data::col_labels(adrs, fill = FALSE)
  adrs <- dplyr::filter(adrs, PARAMCD == "BESRSPI" | AVISIT == "FOLLOW UP")
  teal.data::col_labels(adrs) <- labels
  adrs
}

preprocess_adqs <- function(adqs) {
  labels <- teal.data::col_labels(adqs, fill = FALSE)
  adqs <- adqs |>
    dplyr::filter(ABLFL != "Y" & ABLFL2 != "Y") |>
    dplyr::filter(AVISIT %in% c("WEEK 1 DAY 8", "WEEK 2 DAY 15", "WEEK 3 DAY 22")) |>
    dplyr::mutate(
      AVISIT = as.factor(AVISIT),
      AVISITN = rank(AVISITN) |>
        as.factor() |>
        as.numeric() |>
        as.factor()
    )
  teal.data::col_labels(adqs) <- labels
  adqs
}

# ---- Safety ------------------------------------------------------------------

preprocess_adaette <- function(adaette) {
  adaette <- adaette |>
    dplyr::mutate(is_event = dplyr::case_when(
      grepl("TOT", .data$PARAMCD, fixed = TRUE) ~ TRUE,
      TRUE ~ CNSR == 0
    )) |>
    dplyr::mutate(n_events = dplyr::case_when(
      grepl("TOT", .data$PARAMCD, fixed = TRUE) ~ as.integer(.data$AVAL),
      TRUE ~ as.integer(is_event)
    )) |>
    teal.data::col_relabel(is_event = "Is an Event") |>
    teal.data::col_relabel(n_events = "Number of Events")
  
  adaette_ae <- dplyr::filter(adaette, grepl("TOT", .data$PARAMCD, fixed = TRUE)) |>
    dplyr::select(-"AVAL")
  adaette_oth <- dplyr::filter(adaette, !(grepl("TOT", .data$PARAMCD, fixed = TRUE)))
  
  adaette_tte <- adaette |>
    dplyr::filter(PARAMCD == "AEREPTTE") |>
    dplyr::select(USUBJID, ARM, ARMCD, AVAL)
  
  adaette_ae <- dplyr::full_join(adaette_ae, adaette_tte, by = c("USUBJID", "ARM", "ARMCD"))
  rbind(adaette_ae, adaette_oth)
}

preprocess_adex <- function(adex) {
  labels <- teal.data::col_labels(adex, fill = FALSE)
  # Simulate the TDURD parameter, which is not in the ADEX data from
  # `random.cdisc.data` (fixed seed => identical values on every run)
  set.seed(1, kind = "Mersenne-Twister")
  adex <- adex |>
    dplyr::distinct(USUBJID, .keep_all = TRUE) |>
    dplyr::mutate(
      PARAMCD = "TDURD",
      PARAM = "Overall duration (days)",
      AVAL = sample(
        x = seq(1, 200),
        size = dplyr::n(),
        replace = TRUE
      ),
      AVALU = "Days",
      PARCAT1 = "OVERALL"
    ) |>
    dplyr::bind_rows(adex)
  adex <- adex |>
    dplyr::filter(PARCAT1 == "OVERALL" & PARAMCD %in% c("TDOSE", "TNDOSE", "TDURD"))
  teal.data::col_labels(adex) <- labels
  adex
}

# For real data, ADVS needs some preprocessing like grouping different ANRIND
# and BNRIND into abnormal
preprocess_advs <- function(advs) {
  advs |>
    dplyr::mutate(ONTRTFL = ifelse(AVISIT %in% c("SCREENING", "BASELINE"), "", "Y")) |>
    teal.data::col_relabel(ONTRTFL = "On Treatment Record Flag") |>
    dplyr::mutate(ANRIND = as.character(ANRIND), BNRIND = as.character(BNRIND)) |>
    dplyr::mutate(
      ANRIND = dplyr::case_when(
        ANRIND == "HIGH HIGH" ~ "HIGH",
        ANRIND == "LOW LOW" ~ "LOW",
        TRUE ~ ANRIND
      ),
      BNRIND = dplyr::case_when(
        BNRIND == "HIGH HIGH" ~ "HIGH",
        BNRIND == "LOW LOW" ~ "LOW",
        TRUE ~ BNRIND
      )
    )
}

preprocess_adcm <- function(adcm) {
  dplyr::mutate(adcm, CMSEQ = as.integer(CMSEQ))
}

# Study-specific analysis subgroups and baskets from ADAE
preprocess_adae <- function(adae) {
  # Readable AE names first, so the AESI basket labels below use them too
  adae <- decode_ae_terms(adae)
  adae |>
    dplyr::mutate(
      TMPFL_SER = AESER == "Y",
      TMPFL_REL = AEREL == "Y",
      TMPFL_GR5 = AETOXGR == "5",
      TMP_SMQ01 = !is.na(SMQ01NAM),
      TMP_SMQ02 = !is.na(SMQ02NAM),
      TMP_CQ01 = !is.na(CQ01NAM)
    ) |>
    teal.data::col_relabel(
      TMPFL_SER = "Serious AE",
      TMPFL_REL = "Related AE",
      TMPFL_GR5 = "Grade 5 AE",
      TMP_SMQ01 = tern::aesi_label(adae$SMQ01NAM, adae$SMQ01SC),
      TMP_SMQ02 = tern::aesi_label(adae$SMQ02NAM, adae$SMQ02SC),
      TMP_CQ01 = tern::aesi_label(adae$CQ01NAM)
    )
}

# ---- ADAE: readable adverse event names -------------------------------------
#
# {random.cdisc.data} uses placeholder codes for the MedDRA-style hierarchy:
#   AESOC "cl A"  > AEBODSYS "cl A.1" > AEHLGT "hlgt A.1.1" > AEHLT "hlt A.1.1.1"
#   > AEDECOD "dcd A.1.1.1.1" (AELLT "llt ...", AETERM "trm ..." share the code)
# The depth of the code identifies the level, so one dictionary covers all
# levels. Names follow MedDRA spelling (e.g. "Diarrhoea"). Every code maps to a
# distinct name within its level, so no AE groups are merged and counts are
# unchanged. NOTE: the grades/seriousness stay as simulated by
# random.cdisc.data; the names are illustrative, not clinically matched.

ae_dictionary <- function() {
  c(
    # AESOC (depth 1)
    "A" = "Gastrointestinal disorders",
    "B" = "Cardiovascular disorders",
    "C" = "Infections and immune system disorders",
    "D" = "Nervous system and general disorders",
    # AEBODSYS (depth 2)
    "A.1" = "Gastrointestinal disorders",
    "B.1" = "Cardiac disorders",
    "B.2" = "Vascular disorders",
    "C.1" = "Infections and infestations",
    "C.2" = "Immune system disorders",
    "D.1" = "Nervous system disorders",
    "D.2" = "General disorders and administration site conditions",
    # AEHLGT (depth 3)
    "A.1.1" = "Gastrointestinal signs and symptoms",
    "B.1.1" = "Coronary artery disorders",
    "B.2.1" = "Vascular hypertensive disorders",
    "B.2.2" = "Decreased and nonspecific blood pressure disorders and shock",
    "C.1.1" = "Infections - pathogen unspecified",
    "C.2.1" = "Allergic conditions",
    "D.1.1" = "Central nervous system disorders",
    "D.2.1" = "General system disorders NEC",
    # AEHLT (depth 4)
    "A.1.1.1" = "Gastrointestinal signs and symptoms NEC",
    "B.1.1.1" = "Ischaemic coronary artery disorders",
    "B.2.1.2" = "Vascular hypertensive disorders NEC",
    "B.2.2.3" = "Vascular hypotensive disorders",
    "C.1.1.1" = "Lower respiratory tract and lung infections",
    "C.2.1.2" = "Allergic conditions NEC",
    "D.1.1.1" = "Central nervous system haemorrhages and cerebrovascular accidents",
    "D.1.1.4" = "Headaches NEC",
    "D.2.1.5" = "Asthenic conditions",
    # AEDECOD / AELLT / AETERM (depth 5)
    "A.1.1.1.1" = "Diarrhoea",
    "A.1.1.1.2" = "Nausea",
    "B.1.1.1.1" = "Myocardial infarction",
    "B.2.1.2.1" = "Hypertension",
    "B.2.2.3.1" = "Hypotension",
    "C.1.1.1.3" = "Pneumonia",
    "C.2.1.2.1" = "Hypersensitivity",
    "D.1.1.1.1" = "Cerebrovascular accident",
    "D.1.1.4.2" = "Headache",
    "D.2.1.5.3" = "Fatigue"
  )
}

ae_code_pattern <- "^(cl|hlgt|hlt|llt|dcd|trm) ([A-Z](\\.[0-9]+)*)$"

# Whole-value codes, e.g. "dcd A.1.1.1.1" -> "Diarrhoea"
decode_ae_values <- function(x, dict = ae_dictionary()) {
  code <- sub(ae_code_pattern, "\\2", x)
  code[!grepl(ae_code_pattern, x)] <- NA_character_
  out <- unname(dict[code])
  ifelse(is.na(out), x, out)
}

# Codes embedded in text, e.g. "C.1.1.1.3/B.2.2.3.1 AESI" -> "Pneumonia/Hypotension AESI"
decode_ae_text <- function(x, dict = ae_dictionary()) {
  pt <- dict[lengths(strsplit(names(dict), ".", fixed = TRUE)) == 5]
  for (code in names(pt)) {
    x <- gsub(
      sprintf("(?<![A-Za-z0-9.])%s(?![0-9.])", gsub(".", "\\.", code, fixed = TRUE)),
      pt[[code]], x,
      perl = TRUE
    )
  }
  x
}

# Recode a character/factor column via its unique values, keeping attributes (labels)
recode_column <- function(x, fun) {
  if (is.factor(x)) {
    levels(x) <- fun(levels(x))
  } else if (is.character(x)) {
    u <- unique(x)
    x[] <- unname(stats::setNames(fun(u), u)[x])
  }
  x
}

decode_ae_terms <- function(adae) {
  term_cols <- intersect(c("AETERM", "AELLT", "AEDECOD", "AEHLT", "AEHLGT", "AEBODSYS", "AESOC"), names(adae))
  text_cols <- intersect(c("SMQ01NAM", "SMQ02NAM", "CQ01NAM"), names(adae))
  for (col in term_cols) adae[[col]] <- recode_column(adae[[col]], decode_ae_values)
  for (col in text_cols) adae[[col]] <- recode_column(adae[[col]], decode_ae_text)
  
  # Anything still coded is missing from ae_dictionary(): keep it, but say so
  leftover <- unique(unlist(lapply(term_cols, function(col) {
    v <- unique(as.character(adae[[col]]))
    v[!is.na(v) & grepl(ae_code_pattern, v)]
  })))
  if (length(leftover)) {
    warning("[lumen] AE codes without a name in ae_dictionary() (left unchanged): ", toString(leftover), call. = FALSE)
  }
  adae
}
