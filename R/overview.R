# Study overview for the home page: a compact summary of demographics,
# safety and efficacy, computed once when the app is built and rendered by
# teal_neue.js as widgets on the App Info page (see inst/www/teal_neue.js,
# "Overview").
#
# It describes the whole study (no filters): a fixed point of reference. The
# modules remain the place for filtered, reproducible analyses; each widget
# links to the module that goes into detail. Every part is optional: if a
# dataset or variable is missing (e.g. parquet data from another study), that
# part is left out and the others are still shown.

#' Study overview of the app's data, with links to the matching modules
#' @param data The app's `teal_data`.
#' @param modules The app's modules (for the link targets).
#' @noRd
teal_neue_app_overview <- function(data, modules) {
  get <- function(name) tryCatch(data[[name]], error = function(e) NULL)
  labels <- leaf_labels(modules)
  pick <- function(pattern) {
    hit <- grep(pattern, labels, value = TRUE, ignore.case = TRUE)
    if (length(hit)) hit[[1]]
  }
  tryCatch(
    teal_neue_overview(
      get("ADSL"), get("ADAE"), get("ADTTE"), get("ADRS"),
      links = list(
        demographics = pick("^demographic"),
        safety = pick("^ae summary$|adverse event.*summary"),
        efficacy = pick("kaplan"),
        response = pick("^response table$")
      )
    ),
    error = function(e) NULL
  )
}

#' Study overview for the home page
#'
#' @param adsl,adae,adtte,adrs Analysis datasets (`ADAE`, `ADTTE` and `ADRS`
#'   may be `NULL`).
#' @param links Module labels the widgets link to (named: `demographics`,
#'   `safety`, `efficacy`, `response`); `NULL` entries are left out.
#' @return A list ready for JSON: `population`, `demographics`, `safety`,
#'   `efficacy` (each may be `NULL`) and `links`.
#' @noRd
teal_neue_overview <- function(adsl, adae = NULL, adtte = NULL, adrs = NULL, links = list()) {
  part <- function(expr) tryCatch(expr, error = function(e) NULL)
  adsl <- as.data.frame(adsl)
  arm_var <- overview_arm_var(adsl)
  arms <- overview_levels(adsl[[arm_var]])
  list(
    population = part(overview_population(adsl, arm_var, arms)),
    demographics = part(overview_demographics(adsl, arm_var, arms)),
    safety = if (!is.null(adae)) part(overview_safety(adsl, as.data.frame(adae), arm_var, arms)),
    efficacy = part(overview_efficacy(adsl, adtte, adrs, arm_var, arms)),
    links = Filter(Negate(is.null), links)
  )
}

#' "BLACK OR AFRICAN AMERICAN" -> "Black or African American" (for labels
#' stored in capitals; fast, unlike tools::toTitleCase())
#' @noRd
overview_title_case <- function(x) {
  small <- c("or", "of", "and", "the", "in", "to")
  x <- as.character(x)
  out <- vapply(strsplit(tolower(x), " ", fixed = TRUE), function(w) {
    cap <- !(w %in% small) | seq_along(w) == 1
    w[cap] <- paste0(toupper(substr(w[cap], 1, 1)), substr(w[cap], 2, nchar(w[cap])))
    paste(w, collapse = " ")
  }, character(1))
  out[is.na(x)] <- NA_character_
  out
}

#' @noRd
overview_arm_var <- function(adsl) {
  hit <- intersect(c("ARM", "ACTARM", "TRT01P", "TRT01A"), names(adsl))
  if (!length(hit)) stop("no arm variable")
  hit[[1]]
}

#' @noRd
overview_levels <- function(x) {
  if (is.factor(x)) {
    lv <- levels(droplevels(x))
  } else {
    lv <- sort(unique(as.character(x)))
  }
  lv[!is.na(lv) & nzchar(lv)]
}

#' Share in percent, one decimal
#' @noRd
overview_pct <- function(n, total) if (total > 0) round(100 * n / total, 1) else 0

#' @noRd
overview_population <- function(adsl, arm_var, arms) {
  n_arm <- vapply(arms, function(a) sum(adsl[[arm_var]] == a, na.rm = TRUE), numeric(1))
  list(
    n = nrow(adsl),
    arms = lapply(seq_along(arms), function(i) list(name = arms[[i]], n = n_arm[[i]])),
    countries = if ("COUNTRY" %in% names(adsl)) length(unique(stats::na.omit(as.character(adsl$COUNTRY))))
  )
}

#' @noRd
overview_demographics <- function(adsl, arm_var, arms) {
  out <- list()
  if ("AGE" %in% names(adsl)) {
    age <- adsl$AGE[!is.na(adsl$AGE)]
    q <- stats::quantile(age, c(.25, .5, .75), names = FALSE)
    width <- 5
    lo <- floor(min(age) / width) * width
    hi <- ceiling((max(age) + 1) / width) * width
    breaks <- seq(lo, hi, by = width)
    counts <- as.integer(table(cut(age, breaks, right = FALSE)))
    out$age <- list(
      median = round(q[2], 1), q1 = round(q[1], 1), q3 = round(q[3], 1),
      min = min(age), max = max(age),
      bins = lapply(seq_along(counts), function(i) list(from = breaks[i], to = breaks[i + 1], n = counts[[i]])),
      by_arm = lapply(arms, function(a) {
        x <- adsl$AGE[adsl[[arm_var]] == a & !is.na(adsl$AGE)]
        list(arm = a, median = if (length(x)) round(stats::median(x), 1) else NA_real_)
      })
    )
  }
  count_levels <- function(x, top = Inf) {
    x <- as.character(x)
    x <- x[!is.na(x) & nzchar(x)]
    tab <- sort(table(x), decreasing = TRUE)
    keep <- utils::head(tab, top)
    rest <- sum(tab) - sum(keep)
    res <- lapply(names(keep), function(k) list(level = k, n = as.integer(keep[[k]]), pct = overview_pct(keep[[k]], length(x))))
    if (rest > 0) res <- c(res, list(list(level = "Other", n = as.integer(rest), pct = overview_pct(rest, length(x)))))
    res
  }
  if ("SEX" %in% names(adsl)) out$sex <- count_levels(adsl$SEX)
  if ("RACE" %in% names(adsl)) out$race <- count_levels(overview_title_case(adsl$RACE), top = 4)
  if ("COUNTRY" %in% names(adsl)) out$country <- count_levels(adsl$COUNTRY, top = 5)
  out
}

#' Safety summary on the safety population (SAFFL = "Y" when available):
#' subjects with an event, per arm, for a few key categories, and the most
#' frequent preferred terms
#' @noRd
overview_safety <- function(adsl, adae, arm_var, arms) {
  pop <- if ("SAFFL" %in% names(adsl)) adsl[adsl$SAFFL %in% "Y", , drop = FALSE] else adsl
  if (!nrow(pop)) stop("empty safety population")
  ae <- adae[adae$USUBJID %in% pop$USUBJID, , drop = FALSE]
  if ("TRTEMFL" %in% names(ae) && any(ae$TRTEMFL %in% "Y")) ae <- ae[ae$TRTEMFL %in% "Y", , drop = FALSE]
  arm_of <- stats::setNames(as.character(pop[[arm_var]]), pop$USUBJID)
  n_arm <- vapply(arms, function(a) sum(arm_of == a, na.rm = TRUE), numeric(1))

  by_arm <- function(subjects) {
    subjects <- unique(subjects)
    lapply(seq_along(arms), function(i) {
      n <- sum(arm_of[subjects] == arms[[i]], na.rm = TRUE)
      list(n = n, pct = overview_pct(n, n_arm[[i]]))
    })
  }
  metric <- function(id, label, subjects) list(id = id, label = label, by_arm = by_arm(subjects))
  metrics <- list(metric("any", "Any adverse event", ae$USUBJID))
  if ("AESER" %in% names(ae)) metrics <- c(metrics, list(metric("serious", "Serious", ae$USUBJID[ae$AESER %in% "Y"])))
  if ("AETOXGR" %in% names(ae)) {
    grade <- suppressWarnings(as.numeric(as.character(ae$AETOXGR)))
    metrics <- c(metrics, list(metric("grade3", "Grade \u2265 3", ae$USUBJID[!is.na(grade) & grade >= 3])))
  }
  if ("AEACN" %in% names(ae)) {
    metrics <- c(metrics, list(metric("withdrawn", "Led to withdrawal", ae$USUBJID[ae$AEACN %in% "DRUG WITHDRAWN"])))
  }
  if ("DTHFL" %in% names(pop)) {
    metrics <- c(metrics, list(metric("death", "Deaths", pop$USUBJID[pop$DTHFL %in% "Y"])))
  }

  terms <- NULL
  if ("AEDECOD" %in% names(ae)) {
    subj_term <- unique(ae[!is.na(ae$AEDECOD), c("USUBJID", "AEDECOD")])
    tab <- sort(table(as.character(subj_term$AEDECOD)), decreasing = TRUE)
    top <- names(utils::head(tab, 5))
    terms <- lapply(top, function(term) {
      subj <- subj_term$USUBJID[subj_term$AEDECOD == term]
      list(term = term, n = length(unique(subj)), pct = overview_pct(length(unique(subj)), nrow(pop)), by_arm = by_arm(subj))
    })
  }
  list(
    population = if ("SAFFL" %in% names(adsl)) "Safety population" else "All subjects",
    n = nrow(pop),
    n_by_arm = as.list(unname(n_arm)),
    metrics = metrics,
    terms = terms
  )
}

#' Kaplan-Meier (product-limit) estimate, as a step curve
#' @param time,event Follow-up time and event indicator (1 = event).
#' @return `list(curve = list(c(t, s), ...), median, n, events)`; at most
#'   `max_points` points, keeping every drop large enough to be visible.
#' @noRd
overview_km <- function(time, event, max_points = 80L) {
  ok <- !is.na(time) & !is.na(event)
  time <- time[ok]
  event <- event[ok]
  n <- length(time)
  if (!n) return(NULL)
  ev_times <- sort(unique(time[event == 1]))
  s <- 1
  pts <- list(c(0, 1))
  median <- NULL
  for (t in ev_times) {
    at_risk <- sum(time >= t)
    d <- sum(time == t & event == 1)
    s <- s * (1 - d / at_risk)
    pts[[length(pts) + 1]] <- c(t, s)
    if (is.null(median) && s <= .5) median <- t
  }
  pts[[length(pts) + 1]] <- c(max(time), s)
  if (length(pts) > max_points) {
    keep <- unique(round(seq(1, length(pts), length.out = max_points)))
    pts <- pts[keep]
  }
  list(
    curve = lapply(pts, function(p) round(p, 4)),
    median = if (!is.null(median)) round(median, 1) else NA_real_,
    n = n,
    events = sum(event == 1)
  )
}

#' Wilson score interval for a proportion, in percent
#' @noRd
overview_wilson <- function(x, n, z = 1.959964) {
  if (!n) return(c(NA_real_, NA_real_))
  p <- x / n
  den <- 1 + z^2 / n
  centre <- (p + z^2 / (2 * n)) / den
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  round(100 * c(max(0, centre - half), min(1, centre + half)), 1)
}

#' Efficacy summary on the intent-to-treat population (ITTFL = "Y" when
#' available): overall survival by arm and best overall response rate
#' @noRd
overview_efficacy <- function(adsl, adtte, adrs, arm_var, arms) {
  pop <- if ("ITTFL" %in% names(adsl)) adsl[adsl$ITTFL %in% "Y", , drop = FALSE] else adsl
  arm_of <- stats::setNames(as.character(pop[[arm_var]]), pop$USUBJID)
  out <- list(population = if ("ITTFL" %in% names(adsl)) "Intent-to-treat population" else "All subjects")

  if (!is.null(adtte)) {
    tte <- as.data.frame(adtte)
    params <- unique(as.character(tte$PARAMCD))
    param <- intersect(c("OS", "PFS", "EFS"), params)[1]
    if (!is.na(param) && all(c("AVAL", "CNSR") %in% names(tte))) {
      x <- tte[tte$PARAMCD == param & tte$USUBJID %in% pop$USUBJID, , drop = FALSE]
      label <- if ("PARAM" %in% names(x) && nrow(x)) as.character(x$PARAM[1]) else param
      unit <- if ("AVALU" %in% names(x) && nrow(x)) tolower(as.character(x$AVALU[1])) else ""
      all <- overview_km(x$AVAL, 1 - x$CNSR)
      out$survival <- list(
        param = param, label = label, unit = unit,
        overall = list(median = all$median, n = all$n, events = all$events),
        arms = lapply(arms, function(a) {
          y <- x[arm_of[x$USUBJID] %in% a, , drop = FALSE]
          km <- overview_km(y$AVAL, 1 - y$CNSR)
          c(list(arm = a), km)
        })
      )
    }
  }

  if (!is.null(adrs)) {
    rs <- as.data.frame(adrs)
    param <- intersect(c("BESRSPI", "BESRSP", "OVRINV"), unique(as.character(rs$PARAMCD)))[1]
    if (!is.na(param) && "AVALC" %in% names(rs)) {
      x <- rs[rs$PARAMCD == param & rs$USUBJID %in% pop$USUBJID, , drop = FALSE]
      x <- x[!duplicated(x$USUBJID), , drop = FALSE]
      label <- if ("PARAM" %in% names(x) && nrow(x)) as.character(x$PARAM[1]) else param
      out$response <- list(
        param = param, label = label, definition = "CR or PR",
        arms = lapply(arms, function(a) {
          y <- x[arm_of[x$USUBJID] %in% a, , drop = FALSE]
          r <- sum(y$AVALC %in% c("CR", "PR"))
          ci <- overview_wilson(r, nrow(y))
          list(arm = a, n = nrow(y), responders = r, pct = overview_pct(r, nrow(y)), lo = ci[1], hi = ci[2])
        })
      )
    }
  }
  if (is.null(out$survival) && is.null(out$response)) NULL else out
}
