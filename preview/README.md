# Previews

Renderings of teal_neue. They come from a test bench, not from the full teal
app: a page built with the same bslib 0.12 / shiny components teal uses
(tabs and menus with nested tabs, sidebar filter panel, accordions,
selectize, sliders, DT, modal), with the package's real header, stylesheet,
script, module index, TLG Catalog page and plot settings (ggplot2 4.0.3).
"Before" is the same page with `options(teal_neue.style = FALSE)`.

| File | Shows |
|---|---|
| `home.gif` | The logo leads home; the study at a glance arrives (figures count up, curves draw); pointing at each arm highlights it in every widget; a crosshair reads the survival curves |
| `home.png` | Home page: study at a glance (key figures, demographics, safety, efficacy by arm) with the *Where to?* button, light and dark |
| `home-interaction.png` | An arm highlighted across the widgets; reading the survival curves |
| `interaction.gif` | The flow: command bar (type "kaplan", Enter) from the home page, pin a Kaplan-Meier plot, change a filter, compare the two versions (swipe, side by side, difference), switch to dark mode |
| `ui-light.png` | Before / after, light mode: header with breadcrumb, command field and status (data, subjects, last update time); tab rail; ruled panels; mono dataset names in the filter cards |
| `ui-dark.png` | Before / after, dark mode |
| `command-bar.png` | The command bar: recent views, *Where to?*, TLG outputs, actions; fuzzy search with highlighted matches |
| `compare.png` | Comparison of a pinned plot and the current one: swipe divider, and difference |
| `tools-pins.png` | Plot tools on hover, and the pins tray |
| `tlg-catalog.png` | A TLG Catalog page opened by its link (`#/tlg-catalog/adverse-events/aet01`), light and dark |
| `where-to-shortcuts.png` | *Where to?* in the command bar (every module, nested by category, each with its tint), and the keyboard shortcut sheet |
| `appearance.png` | The Appearance panel, and the app with large text, roomy spacing, the iris accent and crisp corners |
| `section-tints.png` | The quiet tint of each main category: Exploratory (blue), Safety (terracotta), Efficacy (green), TLG Catalog (violet) |
| `plots.png` | Plot defaults, before and after |

In the TLG Catalog images the table and code *contents* are stand-ins
computed with dplyr (tern cannot run on the test bench); in the app each page
shows the real tern/rtables/rlistings output and its code. The bench draws
without a graphics card, so the colour-mode reveal in the GIF is shorter than
in a browser.

This folder is not part of the package build (`.Rbuildignore`); delete it
whenever you like.
