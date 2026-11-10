# Module-specific filters: each module starts with the population of its
# source template.
#   all modules      : ADSL SEX, ADSL AGE
#   Safety modules   : + SAFFL == "Y", ADLB/ADEX/ADEG AVAL
#   Efficacy modules : + ITTFL == "Y"

#' Filter set for the app
#' @param modules The app's modules (see teal_neue_modules()).
#' @noRd
teal_neue_filters <- function(modules) {
  group <- function(label) {
    Filter(function(x) identical(x$label, label), modules$children)[[1]]
  }
  global_filter_ids <- c("ADSL SEX", "ADSL AGE")
  safety_filter_ids <- c("ADSL SAFFL", "ADLB AVAL", "ADEX AVAL", "ADEG AVAL")
  efficacy_filter_ids <- c("ADSL ITTFL")

  teal::teal_slices(
    count_type = "all",
    # shared by every module (all three source apps)
    teal.slice::teal_slice(dataname = "ADSL", varname = "SEX", id = "ADSL SEX"),
    teal.slice::teal_slice(dataname = "ADSL", varname = "AGE", id = "ADSL AGE"),
    # safety-evaluable population + default safety filters
    teal.slice::teal_slice(dataname = "ADSL", varname = "SAFFL", selected = "Y", id = "ADSL SAFFL"),
    teal.slice::teal_slice(dataname = "ADLB", varname = "AVAL", id = "ADLB AVAL"),
    teal.slice::teal_slice(dataname = "ADEX", varname = "AVAL", id = "ADEX AVAL"),
    teal.slice::teal_slice(dataname = "ADEG", varname = "AVAL", id = "ADEG AVAL"),
    # intent-to-treat population
    teal.slice::teal_slice(dataname = "ADSL", varname = "ITTFL", selected = "Y", id = "ADSL ITTFL"),
    module_specific = TRUE,
    mapping = c(
      list(global_filters = global_filter_ids),
      sapply(leaf_labels(group("Safety Analysis")), function(x) safety_filter_ids, simplify = FALSE),
      sapply(leaf_labels(group("Efficacy Analysis")), function(x) efficacy_filter_ids, simplify = FALSE)
    )
  )
}
