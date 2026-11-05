# Header (with dark mode toggle) and footer.

lumen_favicon <- "https://raw.githubusercontent.com/insightsengineering/hex-stickers/main/PNG/nest.png"

#' App header: title + dark mode toggle
#'
#' bslib's toggle switches Bootstrap 5.3 colour modes (data-bs-theme). Starts
#' in light mode. Plots are rendered server-side as light images, so in dark
#' mode they are framed as light "cards" rather than left as white blocks.
#' @noRd
lumen_header <- function() {
  dark_mode_css <- htmltools::tags$style(htmltools::HTML("
    [data-bs-theme='dark'] .shiny-plot-output img {
      background-color: #fff;
      border-radius: 0.5rem;
      padding: 0.25rem;
    }
    [data-bs-theme='dark'] table { color: var(--bs-body-color); }
  "))

  htmltools::tags$span(
    style = "display: flex; align-items: center; justify-content: space-between; margin: 10px 0 10px 0;",
    dark_mode_css,
    htmltools::tags$span("Lumen: Clinical Trial Analysis", style = "font-size: 30px;"),
    htmltools::tags$span(
      style = "display: flex; align-items: center; gap: 8px;",
      htmltools::tags$span("Dark mode", class = "text-body-secondary", style = "font-size: 14px;"),
      bslib::input_dark_mode(id = "lumen_dark_mode", mode = "light")
    )
  )
}

#' App footer
#' @noRd
lumen_footer <- function() {
  gallery_source <- "https://github.com/insightsengineering/teal.gallery/tree/main"
  htmltools::tags$p(
    "Built with the open-source teal framework, based on the teal.gallery templates:",
    htmltools::tags$a(href = file.path(gallery_source, "exploratory"), target = "_blank", "Exploratory"), ", ",
    htmltools::tags$a(href = file.path(gallery_source, "safety"), target = "_blank", "Safety"), ", ",
    htmltools::tags$a(href = file.path(gallery_source, "efficacy"), target = "_blank", "Efficacy")
  )
}
