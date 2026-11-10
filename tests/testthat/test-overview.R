# Study overview of the home page (R/overview.R)

tiny_adsl <- function() {
  data.frame(
    USUBJID = sprintf("S%02d", 1:8),
    ARM = factor(rep(c("A: Drug X", "B: Placebo"), each = 4), levels = c("A: Drug X", "B: Placebo")),
    SEX = c("F", "F", "M", "F", "M", "M", "F", "M"),
    AGE = c(21, 34, 35, 47, 52, 38, 29, 61),
    RACE = c("ASIAN", "WHITE", "ASIAN", "BLACK OR AFRICAN AMERICAN", "ASIAN", "WHITE", "ASIAN", NA),
    COUNTRY = c("CHN", "USA", "CHN", "BRA", "CHN", "USA", "JPN", "CHN"),
    SAFFL = c(rep("Y", 7), "N"),
    ITTFL = "Y",
    DTHFL = c("N", "N", "Y", "N", "N", "N", "N", "N"),
    stringsAsFactors = FALSE
  )
}
tiny_adae <- function() {
  data.frame(
    USUBJID = c("S01", "S01", "S02", "S05", "S05", "S06", "S08"),
    AEDECOD = c("Headache", "Nausea", "Headache", "Headache", "Fatigue", "Nausea", "Headache"),
    AESER = c("Y", "N", "N", "N", "Y", "N", "Y"),
    AETOXGR = c("3", "1", "2", "1", "4", "2", "5"),
    AEACN = c("DRUG WITHDRAWN", "DOSE NOT CHANGED", "DOSE NOT CHANGED", "DOSE NOT CHANGED", "DOSE NOT CHANGED", "DOSE NOT CHANGED", "DRUG WITHDRAWN"),
    stringsAsFactors = FALSE
  )
}

test_that("Kaplan-Meier estimate: product-limit steps and median", {
  km <- overview_km(time = c(1, 2, 3, 4, 5), event = c(1, 1, 0, 1, 0))
  s <- vapply(km$curve, `[`, numeric(1), 2)
  t <- vapply(km$curve, `[`, numeric(1), 1)
  # S(1) = 4/5, S(2) = 3/5, S(4) = 3/5 * 1/2
  expect_equal(s[t == 1], .8)
  expect_equal(s[t == 2], .6)
  expect_equal(s[t == 4], .3)
  expect_identical(km$median, 4)
  expect_identical(km$n, 5L)
  expect_identical(km$events, 3L)
  # not reached -> NA (null in JSON)
  expect_true(is.na(overview_km(c(1, 2, 3), c(1, 0, 0))$median))
  # long curves are thinned
  big <- overview_km(1:500, rep(1, 500), max_points = 40)
  expect_lte(length(big$curve), 40)
  expect_null(overview_km(numeric(0), numeric(0)))
})

test_that("Wilson interval", {
  ci <- overview_wilson(8, 10)
  expect_equal(ci, c(49.0, 94.3), tolerance = .1)
  expect_true(all(is.na(overview_wilson(0, 0))))
})

test_that("title case keeps small words and NA", {
  expect_identical(overview_title_case(c("BLACK OR AFRICAN AMERICAN", "WHITE", NA)), c("Black or African American", "White", NA))
})

test_that("population and demographics", {
  o <- teal_neue_overview(tiny_adsl())
  expect_identical(o$population$n, 8L)
  expect_identical(vapply(o$population$arms, `[[`, "", "name"), c("A: Drug X", "B: Placebo"))
  expect_identical(vapply(o$population$arms, `[[`, 1, "n"), c(4, 4))
  expect_identical(o$population$countries, 4L)
  age <- o$demographics$age
  expect_identical(age$median, 36.5)
  expect_identical(sum(vapply(age$bins, `[[`, 1L, "n")), 8L)
  expect_identical(age$bins[[1]]$from, 20)
  sex <- o$demographics$sex
  expect_identical(sex[[1]]$level, "F")
  expect_identical(sex[[1]]$pct, 50)
  expect_identical(o$demographics$race[[1]]$level, "Asian")
  # no AE data: no safety part; no TTE / RS: no efficacy part
  expect_null(o$safety)
  expect_null(o$efficacy)
})

test_that("safety: safety population, subjects per arm and category, top terms", {
  o <- teal_neue_overview(tiny_adsl(), tiny_adae())
  saf <- o$safety
  expect_identical(saf$n, 7L) # S08 is not in the safety population
  ids <- vapply(saf$metrics, `[[`, "", "id")
  expect_identical(ids, c("any", "serious", "grade3", "withdrawn", "death"))
  any <- saf$metrics[[1]]$by_arm
  expect_identical(any[[1]]$n, 2L) # S01, S02
  expect_identical(any[[2]]$n, 2L) # S05, S06 (S08 excluded)
  expect_identical(any[[2]]$pct, 66.7) # of 3 placebo subjects in the safety population
  serious <- saf$metrics[[2]]$by_arm
  expect_identical(c(serious[[1]]$n, serious[[2]]$n), c(1L, 1L))
  grade3 <- saf$metrics[[3]]$by_arm
  expect_identical(c(grade3[[1]]$n, grade3[[2]]$n), c(1L, 1L))
  death <- saf$metrics[[5]]$by_arm
  expect_identical(c(death[[1]]$n, death[[2]]$n), c(1L, 0L))
  expect_identical(saf$terms[[1]]$term, "Headache")
  expect_identical(saf$terms[[1]]$n, 3L)
})

test_that("efficacy: survival by arm and response rate", {
  adsl <- tiny_adsl()
  adtte <- data.frame(USUBJID = adsl$USUBJID, PARAMCD = "OS", PARAM = "Overall Survival",
                      AVAL = c(10, 20, 30, 40, 5, 15, 25, 35), CNSR = c(0, 0, 1, 0, 0, 0, 0, 1), AVALU = "DAYS")
  adrs <- data.frame(USUBJID = adsl$USUBJID, PARAMCD = "BESRSPI", PARAM = "Best response",
                     AVALC = c("CR", "PR", "SD", "PD", "CR", "NE", "SD", "PR"))
  o <- teal_neue_overview(adsl, NULL, adtte, adrs)
  sv <- o$efficacy$survival
  expect_identical(sv$param, "OS")
  expect_identical(sv$unit, "days")
  expect_length(sv$arms, 2)
  expect_identical(sv$arms[[1]]$arm, "A: Drug X")
  expect_identical(sv$arms[[1]]$events, 3L)
  expect_identical(sv$overall$n, 8L)
  rs <- o$efficacy$response$arms
  expect_identical(c(rs[[1]]$responders, rs[[2]]$responders), c(2L, 2L))
  expect_identical(rs[[1]]$pct, 50)
  expect_true(rs[[1]]$lo < 50 && rs[[1]]$hi > 50)
})

test_that("a broken part is left out, the rest is kept", {
  adae <- tiny_adae()
  adae$USUBJID <- NULL # unusable
  o <- teal_neue_overview(tiny_adsl(), adae)
  expect_null(o$safety)
  expect_false(is.null(o$demographics))
  expect_null(tryCatch(teal_neue_overview(data.frame(x = 1)), error = function(e) NULL))
})

test_that("the overview travels in the header index as JSON", {
  o <- teal_neue_overview(tiny_adsl(), tiny_adae(), links = list(safety = "AE Summary", efficacy = NULL))
  expect_identical(o$links, list(safety = "AE Summary"))
  idx <- list(modules = list(list(path = list("App Info"), kind = "info")), tlg = list(), overview = o)
  html <- htmltools::renderTags(teal_neue_header("x", style = TRUE, index = idx))$html
  json <- sub('.*<script type="application/json" id="tn-index">(.*?)</script>.*', "\\1", html)
  back <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  expect_identical(back$overview$population$n, 8L)
  expect_identical(back$overview$safety$metrics[[1]]$id, "any")
})
