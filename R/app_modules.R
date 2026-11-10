# Module configuration: the three teal.gallery templates (inst/templates/)
# as tab groups, plus the shared pages. Module calls are kept as in the
# templates; see the NOTE comments for the intentional changes.
#
# The exploratory plot modules are created through teal_neue_plot_module()
# (R/plot_theme.R), which only adds the app's default ggplot2 theme
# (option teal_neue.ggtheme) to modules that support it.

#' All app modules
#' @param data The app's `teal_data` (see [build_teal_neue_data()]).
#' @noRd
teal_neue_modules <- function(data) {
  source <- data[[".teal_neue"]]$source
  all_modules <- modules(
    module_app_info(source),
    tm_data_table("Data Table"),
    modules_tlg_catalog(datanames = names(data)),
    tm_variable_browser("Variable Browser"),
    modules_exploratory(teal_neue_file_viewer_paths(source)),
    modules_safety(data),
    modules_efficacy(data)
  )
  labels <- leaf_labels(all_modules)
  if (anyDuplicated(labels)) {
    stop("Module labels must be unique: ", toString(unique(labels[duplicated(labels)])), call. = FALSE)
  }
  all_modules
}

#' Front page
#' @noRd
module_app_info <- function(teal_neue_source) {
  tm_front_page(
    label = "App Info",
    header_text = c(
      "About this app" = paste(
        "teal_neue brings together exploratory, safety and efficacy analyses of a clinical trial in one place.",
        "Use the tabs to move between sections; each analysis opens with the population used in its",
        "source template (safety population for Safety, intent-to-treat population for Efficacy).",
        "The TLG Catalog tab reproduces every table, listing and graph of the TLG Catalog on the filtered data, one page per topic.",
        "Press Ctrl+K (Cmd+K on a Mac) anywhere to jump to any module or TLG output by name, and ? to see every keyboard shortcut.",
        "Click the logo (or press H) to come back here: Study at a glance summarises the whole study by arm, before any filter.",
        "Hover a plot or a table for its tools (expand, pin for comparison, copy, download).",
        "The sun/moon button in the header switches between light and dark mode; your browser remembers the choice."
      ),
      "Info about input data source" = switch(teal_neue_source$source,
        bundled = paste(
          "This app uses the synthetic CDISC ADaM datasets bundled with the `random.cdisc.data` R package.",
          "Adverse event terms were mapped from placeholder codes to illustrative MedDRA-style names."
        ),
        synthetic = paste0(
          "This app uses synthetic CDISC ADaM datasets freshly generated with the `random.cdisc.data` R package ",
          "(", teal_neue_source$synthetic$N, " subjects, seed ", teal_neue_source$synthetic$seed, "). ",
          "Adverse event terms were mapped from placeholder codes to illustrative MedDRA-style names."
        ),
        parquet = paste0("This app uses ADaM datasets read from the parquet files in `", teal_neue_source$parquet_dir, "`.")
      )
    ),
    tables = list(
      `App sections` = data.frame(
        Section = c("TLG Catalog", "Exploratory Analysis", "Safety Analysis", "Efficacy Analysis"),
        `Default population` = c(
          "As in the TLG Catalog (safety or intent-to-treat population, per output)",
          "All subjects", "Safety population (SAFFL = Y)", "Intent-to-treat (ITTFL = Y)"
        ),
        Datasets = c(
          "All datasets, plus ADPC, ADPP, ADAB, ADMH, ADHY examples",
          "ADSL, ADRS, ADLB, ADLBPCA",
          "ADSL, ADAE, ADAETTE, ADEX, ADLB, ADEG, ADVS, ADCM",
          "ADSL, ADTTE, ADRS_EFF, ADQS"
        ),
        check.names = FALSE
      ),
      `Open-source packages used` = data.frame(
        Packages = c("teal.modules.general", "teal.modules.clinical", "random.cdisc.data")
      )
    )
  )
}

#' Files shown by the File viewer: the parquet data folder when that source is
#' used, otherwise the installed package files (always present).
#' @noRd
teal_neue_file_viewer_paths <- function(source) {
  if (identical(source$source, "parquet")) {
    list("Parquet data folder" = source$parquet_dir)
  } else {
    list("teal_neue package files" = system.file(package = "teal.neue"))
  }
}

#' Exploratory Analysis (from inst/templates/app_exploratory.R)
#' @noRd
modules_exploratory <- function(file_viewer_paths) {
  pick_adsl_age <- picks(
    datasets("ADSL", "ADSL"),
    variables(selected = "AGE", multiple = FALSE)
  )
  pick_adsl_bmrkr1 <- picks(
    datasets("ADSL", "ADSL"),
    variables(selected = "BMRKR1", multiple = FALSE)
  )
  pick_adsl_armcd <- picks(
    datasets("ADSL", "ADSL"),
    variables(selected = "ARMCD", multiple = FALSE)
  )
  pick_adsl_strata2 <- picks(
    datasets("ADSL", "ADSL"),
    variables(is.factor, selected = "STRATA2", multiple = FALSE)
  )
  pick_adsl_armcd_multi <- picks(
    datasets("ADSL", "ADSL"),
    variables(selected = "ARMCD", multiple = TRUE)
  )
  pick_adsl_numeric_bmrkr1 <- picks(
    datasets("ADSL", "ADSL"),
    variables(is.numeric, selected = "BMRKR1", multiple = FALSE)
  )
  pick_adsl_factor <- picks(
    datasets("ADSL", "ADSL"),
    variables(is.factor, selected = NULL, multiple = FALSE)
  )
  pick_adsl_multi <- picks(
    datasets("ADSL", "ADSL"),
    variables(selected = c("AGE", "BMRKR1"), multiple = TRUE)
  )

  pick_adrs_response <- picks(
    datasets("ADRS", "ADRS"),
    variables(choices = c("AVALC", "AVAL"), selected = "AVALC", multiple = FALSE)
  )
  pick_adrs_response_fct <- picks(
    datasets("ADRS", "ADRS"),
    variables(choices = is.factor, selected = "AVALC", multiple = FALSE)
  )

  pick_adlb_aval <- picks(
    datasets("ADLB", "ADLB"),
    variables(choices = c("AVAL", "CHG", "PCHG", "ANRIND", "BASE"), selected = "AVAL", multiple = FALSE)
  )
  pick_adlb_outlier <- picks(
    datasets("ADLB", "ADLB"),
    variables(choices = c("AVAL", "CHG", "PCHG", "BASE"), selected = "AVAL", multiple = FALSE)
  )
  pick_adlb_categorical <- picks(
    datasets("ADLB", "ADLB"),
    variables(choices = c("PARAM", "PARAMCD"), selected = NULL, multiple = FALSE)
  )

  pick_adlbpca <- picks(
    datasets("ADLBPCA", "ADLBPCA"),
    variables(
      choices = is.numeric,
      selected = c("ALT - WEEK 5 DAY 36", "CRP - WEEK 5 DAY 36", "IGA - WEEK 5 DAY 36"),
      multiple = TRUE
    )
  )

  adrs_endpoint_filter <- teal_transform_filter(
    picks(
      datasets("ADRS", "ADRS"),
      variables(choices = "PARAMCD", selected = "PARAMCD", multiple = FALSE, fixed = TRUE),
      values(choices = c("BESRSPI", "INVET"), selected = "BESRSPI", multiple = FALSE)
    ),
    label = "Choose endpoint"
  )
  adlb_lab_filter <- teal_transform_filter(
    picks(
      datasets("ADLB", "ADLB"),
      variables(choices = "PARAMCD", selected = "PARAMCD", multiple = FALSE, fixed = TRUE),
      values(selected = "ALT", multiple = FALSE)
    ),
    label = "Select lab"
  )
  adlb_visit_filter <- teal_transform_filter(
    picks(
      datasets("ADLB", "ADLB"),
      variables(choices = "AVISIT", selected = "AVISIT", multiple = FALSE, fixed = TRUE),
      values(selected = "SCREENING", multiple = FALSE)
    ),
    label = "Select visit"
  )

  modules(
    label = "Exploratory Analysis",
    # NOTE: the template pointed at 3 remote demo files (checked over the network
    # at every start-up) and a non-existent ./packrat/desc/ folder.
    tm_file_viewer(
      label = "File viewer",
      input_path = file_viewer_paths
    ),
    tm_missing_data("Missing Data"),
    teal_neue_plot_module(
      tm_g_distribution,
      "Distribution",
      dist_var = pick_adsl_numeric_bmrkr1,
      strata_var = pick_adsl_factor,
      group_var = pick_adsl_factor
    ),
    teal_neue_plot_module(
      tm_outliers,
      "Outliers",
      outlier_var = pick_adlb_outlier,
      categorical_var = pick_adlb_categorical
    ),
    teal_neue_plot_module(
      tm_g_association,
      label = "Association",
      ref = pick_adsl_age,
      vars = pick_adsl_armcd_multi
    ),
    # NOTE: the template fixed ggtheme = "gray"; the app-wide default is used instead
    teal_neue_plot_module(
      tm_g_bivariate,
      label = "Bivariate Plots",
      x = pick_adsl_age,
      y = pick_adlb_aval,
      row_facet = pick_adsl_factor,
      col_facet = pick_adsl_factor,
      use_density = FALSE,
      plot_height = c(600L, 200L, 2000L),
      transformators = list(adlb_lab_filter, adlb_visit_filter)
    ),
    teal_neue_plot_module(
      tm_a_regression,
      label = "Regression",
      response = pick_adsl_numeric_bmrkr1,
      regressor = pick_adrs_response,
      transformators = list(adrs_endpoint_filter)
    ),
    teal_neue_plot_module(
      tm_g_response,
      label = "Response Plot",
      response = pick_adrs_response_fct,
      x = pick_adsl_strata2,
      row_facet = pick_adsl_factor,
      col_facet = pick_adsl_factor,
      coord_flip = FALSE,
      transformators = list(adrs_endpoint_filter)
    ),
    tm_g_scatterplotmatrix(
      label = "Scatterplot Matrix",
      variables = list(pick_adsl_multi)
    ),
    # NOTE: smaller, slightly transparent points (template: size = 3, alpha = 1)
    # so overlapping subjects stay visible
    teal_neue_plot_module(
      tm_g_scatterplot,
      "Scatterplot",
      x = pick_adsl_age,
      y = pick_adsl_bmrkr1,
      row_facet = pick_adsl_factor,
      col_facet = pick_adsl_factor,
      color_by = pick_adsl_factor,
      size = 2.5, alpha = 0.8,
      plot_height = c(600L, 200L, 2000L)
    ),
    tm_t_crosstable(
      "Table Choices",
      x = pick_adsl_strata2,
      y = pick_adsl_armcd
    ),
    teal_neue_plot_module(
      tm_a_pca,
      "Principal Component Analysis",
      dat = pick_adlbpca,
      plot_height = c(600L, 200L, 2000L),
      plot_width = c(600L, 200L, 2000L)
    )
  )
}

#' Safety Analysis (from inst/templates/app_safety.R)
#' @noRd
modules_safety <- function(data) {
  ADSL <- data[["ADSL"]]
  ADAE <- data[["ADAE"]]

  # Safety uses the *actual* arm
  arm_vars_safety <- c("ACTARMCD", "ACTARM")
  date_vars_adsl <- names(ADSL)[vapply(ADSL, function(x) inherits(x, c("Date", "POSIXct", "POSIXlt")), logical(1))]
  demog_vars_adsl <- names(ADSL)[!(names(ADSL) %in% c("USUBJID", "STUDYID", date_vars_adsl))]

  ae_anl_vars <- names(ADAE)[startsWith(names(ADAE), "TMPFL_")]
  # flag variables for AE baskets; set to NULL if not applicable to study
  aesi_vars <- names(ADAE)[startsWith(names(ADAE), "TMP_SMQ") | startsWith(names(ADAE), "TMP_CQ")]

  modules(
    label = "Safety Analysis",
    tm_t_summary(
      label = "Demographic Table (Safety)",
      dataname = "ADSL",
      arm_var = variables(arm_vars_safety, "ACTARM"),
      summarize_vars = variables(demog_vars_adsl, c("SEX", "AGE", "RACE"))
    ),
    modules(
      label = "Adverse Events",
      tm_t_events_summary(
        label = "AE Summary",
        dataname = "ADAE",
        arm_var = variables(arm_vars_safety, "ACTARM"),
        flag_var_anl = variables(ae_anl_vars, ae_anl_vars, multiple = TRUE),
        flag_var_aesi = variables(aesi_vars, aesi_vars, multiple = TRUE),
        add_total = TRUE
      ),
      tm_t_events(
        label = "AE by Term",
        dataname = "ADAE",
        arm_var = variables(arm_vars_safety, "ACTARM"),
        llt = variables(c("AETERM", "AEDECOD"), "AEDECOD"),
        hlt = variables(c("AEBODSYS", "AESOC"), "AEBODSYS"),
        add_total = TRUE,
        event_type = "adverse event"
      ),
      tm_t_events_by_grade(
        label = "AE Table by Grade",
        dataname = "ADAE",
        arm_var = variables(arm_vars_safety, "ACTARM"),
        llt = variables("AEDECOD", "AEDECOD"),
        hlt = variables(c("AEBODSYS", "AESOC"), "AEBODSYS"),
        grade = variables("AETOXGR", "AETOXGR"),
        add_total = TRUE
      ),
      tm_t_events_patyear(
        label = "AE Rates Adjusted for Patient-Years at Risk",
        dataname = "ADAETTE",
        arm_var = variables(arm_vars_safety, "ACTARM"),
        paramcd = picks(
          variables("PARAMCD", "PARAMCD"),
          values(selected = "AETTE1", multiple = FALSE),
          check_dataset = FALSE
        ),
        events_var = variables("n_events", "n_events")
      ),
      tm_t_smq(
        label = "Adverse Events by SMQ Table",
        dataname = "ADAE",
        arm_var = variables(c(arm_vars_safety, "SEX"), "ACTARM"),
        add_total = FALSE,
        baskets = variables(
          function(x) grepl("^(SMQ|CQ).*NAM$", names(parent.frame()$X)[[parent.frame()$i]]),
          dplyr::everything(),
          multiple = TRUE
        ),
        scopes = variables(
          function(x) grepl("^SMQ.*SC$", names(parent.frame()$X)[[parent.frame()$i]]),
          dplyr::everything(),
          multiple = TRUE,
          fixed = TRUE
        ),
        llt = variables("AEDECOD", "AEDECOD")
      )
    ),
    modules(
      label = "Lab Tables",
      tm_t_summary_by(
        label = "Labs Summary",
        dataname = "ADLB",
        arm_var = variables(arm_vars_safety, "ACTARM"),
        by_vars = variables(c("PARAM", "AVISIT"), c("PARAM", "AVISIT"), multiple = TRUE, fixed = TRUE),
        summarize_vars = variables(c("AVAL", "CHG"), "AVAL"),
        paramcd = picks(
          variables("PARAMCD", "PARAMCD"),
          values(selected = "ALT", multiple = TRUE),
          check_dataset = FALSE
        )
      ),
      tm_t_shift_by_grade(
        label = "Grade Laboratory Abnormality Table",
        dataname = "ADLB",
        arm_var = variables(c("ACTARMCD", "ACTARM"), "ACTARM"),
        paramcd = picks(
          variables("PARAMCD", "PARAMCD"),
          values(selected = "ALT", multiple = TRUE),
          check_dataset = FALSE
        ),
        worst_flag_var = variables(c("WGRLOVFL", "WGRLOFL", "WGRHIVFL", "WGRHIFL"), "WGRLOVFL"),
        worst_flag_indicator = teal.picks::values("Y", "Y", fixed = TRUE, multiple = FALSE),
        anl_toxgrade_var = variables("ATOXGR", "ATOXGR"),
        base_toxgrade_var = variables("BTOXGR", "BTOXGR"),
        add_total = FALSE
      ),
      tm_t_abnormality_by_worst_grade(
        label = "Laboratory test results with highest grade post-baseline",
        dataname = "ADLB",
        arm_var = variables(c("ARM", "ARMCD"), "ARM"),
        paramcd = picks(
          variables("PARAMCD", "PARAMCD"),
          values(selected = c("ALT", "CRP", "IGA")),
          check_dataset = FALSE
        ),
        add_total = FALSE
      )
    ),
    modules(
      label = "Exposure",
      tm_t_summary_by(
        label = "Exposure Summary",
        dataname = "ADEX",
        arm_var = variables(arm_vars_safety, "ACTARM"),
        by_vars = variables(c("PARCAT2", "PARAM"), c("PARCAT2", "PARAM"), fixed = TRUE),
        summarize_vars = variables("AVAL", "AVAL", fixed = TRUE),
        paramcd = picks(
          variables("PARAMCD", "PARAMCD"),
          values(selected = "TDOSE", multiple = TRUE),
          check_dataset = FALSE
        ),
        denominator = values(c("n", "N", "omit"), "n")
      ),
      tm_t_exposure(
        label = "Duration of Exposure Table",
        dataname = "ADEX",
        paramcd = picks(
          variables("PARAMCD", "PARAMCD"),
          values(selected = "TDURD", multiple = FALSE),
          check_dataset = FALSE
        ),
        col_by_var = variables(c(arm_vars_safety, "SEX"), "SEX"),
        row_by_var = variables(c("RACE", "REGION1", "STRATA1", "SEX"), "RACE"),
        parcat = picks(
          variables("PARCAT2", "PARCAT2"),
          values(selected = "Drug A"),
          check_dataset = FALSE
        ),
        add_total = FALSE
      )
    ),
    tm_t_abnormality(
      label = "Vital Signs Abnormality",
      dataname = "ADVS",
      arm_var = variables(arm_vars_safety, "ACTARM"),
      id_var = variables("USUBJID", "USUBJID", fixed = TRUE),
      by_vars = variables(c("PARAM", "AVISIT"), "PARAM", multiple = TRUE),
      grade = variables("ANRIND", "ANRIND", fixed = TRUE),
      abnormal = list(low = "LOW", high = "HIGH")
    ),
    tm_t_mult_events(
      label = "Concomitant Medication",
      dataname = "ADCM",
      arm_var = variables(arm_vars_safety, "ACTARM"),
      seq_var = variables("CMSEQ", "CMSEQ", fixed = TRUE),
      hlt = variables("ATC2", "ATC2", fixed = TRUE),
      llt = variables("CMDECOD", "CMDECOD", fixed = TRUE),
      add_total = TRUE,
      event_type = "treatment"
    ),
    tm_t_shift_by_arm(
      label = "ECG Shift Table by Arm",
      dataname = "ADEG",
      arm_var = variables(arm_vars_safety, "ACTARM"),
      paramcd = picks(
        variables("PARAMCD", "PARAMCD"),
        values(selected = "HR", multiple = FALSE),
        check_dataset = FALSE
      ),
      visit_var = picks(
        variables("AVISIT", "AVISIT"),
        values(selected = "POST-BASELINE MINIMUM"),
        check_dataset = FALSE
      ),
      aval_var = variables("ANRIND", "ANRIND", fixed = TRUE),
      baseline_var = variables("BNRIND", "BNRIND", fixed = TRUE)
    ),
    tm_g_lineplot(
      label = "Line Plot",
      dataname = "ADLB",
      group_var = variables(arm_vars_safety, "ACTARM"),
      x = variables("AVISIT", "AVISIT", fixed = TRUE),
      y = variables(c("AVAL", "BASE", "CHG", "PCHG"), "AVAL"),
      y_unit = variables("AVALU", "AVALU", fixed = TRUE),
      paramcd = picks(
        variables("PARAMCD", "PARAMCD", fixed = TRUE),
        values(selected = "ALT", multiple = FALSE),
        check_dataset = FALSE
      ),
      plot_height = c(1000L, 200L, 4000L)
    )
  )
}

#' Efficacy Analysis (from inst/templates/app_efficacy.R)
#' @noRd
modules_efficacy <- function(data) {
  ADSL <- data[["ADSL"]]
  char_vars_asl <- data[[".teal_neue"]]$meta$adsl_char_vars

  # Efficacy uses the *planned* (randomised) arm
  arm_vars_efficacy <- c("ARMCD", "ARM")
  date_vars_adsl <- names(ADSL)[vapply(ADSL, function(x) inherits(x, c("Date", "POSIXct", "POSIXlt")), logical(1))]
  demog_vars_adsl <- names(ADSL)[!(names(ADSL) %in% c("USUBJID", "STUDYID", date_vars_adsl))]

  strata_vars <- c("STRATA1", "STRATA2")
  facet_vars <- c("AGEGR1", "BMRKR2", "SEX", "COUNTRY")
  cov_vars <- c("AGE", "SEX", "BMRKR1", "BMRKR2", "REGION1")
  visit_vars <- c("AVISIT", "AVISITN")

  picks_paramcd_tte <- picks(
    check_dataset = FALSE,
    variables("PARAMCD", "PARAMCD"),
    values(selected = "OS", multiple = FALSE)
  )
  picks_paramcd_rsp <- picks(
    check_dataset = FALSE,
    variables("PARAMCD", "PARAMCD"),
    values(selected = "BESRSPI", multiple = FALSE)
  )
  picks_paramcd_qs <- picks(
    check_dataset = FALSE,
    variables("PARAMCD", "PARAMCD"),
    values(selected = "FKSI-FWB", multiple = FALSE)
  )

  fact_vars_asl <- names(Filter(isTRUE, sapply(ADSL, is.factor)))
  fact_vars_asl_orig <- fact_vars_asl[!fact_vars_asl %in% char_vars_asl]

  # reference & comparison arm selection when switching the arm variable
  # ARMCD is given in a delayed fashion using value choices and
  # ARM is given with the ref and comp levels supplied explicitly
  arm_ref_comp <- list(
    ARMCD = list(ref = "ARM A", comp = c("ARM B", "ARM C")),
    ARM = list(ref = "A: Drug X", comp = c("B: Placebo", "C: Combination"))
  )

  modules(
    label = "Efficacy Analysis",
    tm_t_summary(
      label = "Demographic Table (Efficacy)",
      dataname = "ADSL",
      arm_var = variables(arm_vars_efficacy, "ARM"),
      summarize_vars = variables(demog_vars_adsl, c("SEX", "AGE", "RACE"), multiple = TRUE)
    ),
    modules(
      label = "Forest Plots",
      tm_g_forest_tte(
        label = "Survival Forest Plot",
        dataname = "ADTTE",
        arm_var = variables(arm_vars_efficacy, "ARM"),
        strata_var = variables(strata_vars, "STRATA1", multiple = TRUE),
        subgroup_var = variables(facet_vars, "AGEGR1", multiple = TRUE),
        paramcd = picks_paramcd_tte,
        plot_height = c(800L, 200L, 4000L)
      ),
      tm_g_forest_rsp(
        label = "Response Forest Plot",
        dataname = "ADRS_EFF",
        arm_var = variables(arm_vars_efficacy, "ARM"),
        strata_var = variables(strata_vars, "STRATA1", multiple = TRUE),
        subgroup_var = variables(facet_vars, "AGEGR1", multiple = TRUE),
        paramcd = picks_paramcd_rsp,
        plot_height = c(800L, 200L, 4000L)
      )
    ),
    tm_g_km(
      label = "Kaplan Meier Plot",
      dataname = "ADTTE",
      arm_var = variables(arm_vars_efficacy, "ARM"),
      arm_ref_comp = arm_ref_comp,
      paramcd = picks_paramcd_tte,
      facet_var = variables(facet_vars, "AGEGR1"),
      strata_var = variables(strata_vars, "STRATA1"),
      plot_height = c(1800L, 200L, 4000L)
    ),
    tm_t_binary_outcome(
      label = "Response Table",
      dataname = "ADRS_EFF",
      arm_var = variables(arm_vars_efficacy, "ARM"),
      arm_ref_comp = arm_ref_comp,
      paramcd = picks_paramcd_rsp,
      strata_var = variables(strata_vars, "STRATA1"),
      rsp_table = TRUE
    ),
    tm_t_tte(
      label = "Time To Event Table",
      dataname = "ADTTE",
      arm_var = variables(arm_vars_efficacy, "ARM"),
      paramcd = picks_paramcd_tte,
      strata_var = variables(strata_vars, "STRATA1"),
      time_points = values(c(182, 365, 547), 182),
      event_desc_var = variables("EVNTDESC", "EVNTDESC")
    ),
    tm_t_crosstable(
      "Cross Table",
      x = picks(datasets("ADSL", "ADSL"), variables(fact_vars_asl_orig, 1L)),
      y = picks(datasets("ADSL", "ADSL"), variables(fact_vars_asl_orig, 4L))
    ),
    tm_t_coxreg(
      label = "Cox Reg",
      dataname = "ADTTE",
      arm_var = variables(arm_vars_efficacy, "ARM"),
      arm_ref_comp = arm_ref_comp,
      paramcd = picks_paramcd_tte,
      strata_var = variables(strata_vars, "STRATA1"),
      cov_var = variables(cov_vars, "AGE")
    ),
    tm_t_logistic(
      label = "Logistic Reg",
      dataname = "ADRS_EFF",
      arm_var = variables(arm_vars_efficacy, "ARM"),
      arm_ref_comp = NULL,
      paramcd = picks_paramcd_rsp,
      cov_var = variables(cov_vars, "AGE")
    ),
    tm_a_mmrm(
      label = "MMRM",
      dataname = "ADQS",
      aval_var = variables(c("AVAL", "CHG"), "AVAL"),
      id_var = variables(c("USUBJID", "SUBJID"), "USUBJID"),
      arm_var = variables(arm_vars_efficacy, "ARM"),
      visit_var = variables(visit_vars, "AVISIT"),
      arm_ref_comp = arm_ref_comp,
      paramcd = picks_paramcd_qs,
      cov_var = variables(c("BASE", "AGE", "SEX", interaction_vars("BASE", "AVISIT")), NULL),
      conf_level = values(c(0.95, 0.9, 0.8), 0.95)
    ),
    tm_t_binary_outcome(
      label = "Binary Response",
      dataname = "ADRS_EFF",
      arm_var = variables(arm_vars_efficacy, "ARM"),
      paramcd = picks_paramcd_rsp,
      strata_var = variables(strata_vars, "STRATA1")
    ),
    tm_t_ancova(
      label = "ANCOVA",
      dataname = "ADQS",
      avisit = picks(variables("AVISIT", "AVISIT"), values(selected = "WEEK 1 DAY 8"), check_dataset = FALSE),
      arm_var = variables(arm_vars_efficacy, "ARM"),
      arm_ref_comp = arm_ref_comp,
      aval_var = variables(c("AVAL", "CHG", "PCHG"), "CHG"),
      cov_var = variables(c("BASE", "STRATA1", "SEX"), "STRATA1"),
      paramcd = picks(
        check_dataset = FALSE,
        variables("PARAMCD", "PARAMCD"),
        values(selected = "FKSI-FWB", multiple = TRUE)
      )
    )
  )
}

#' Labels of all leaf modules inside a (nested) teal_modules object
#' @noRd
leaf_labels <- function(x) {
  if (inherits(x, "teal_modules")) {
    unlist(lapply(x$children, leaf_labels), use.names = FALSE)
  } else {
    x$label
  }
}
