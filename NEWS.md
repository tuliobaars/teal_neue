# teal.neue 0.2.0

A modernised take on the app: same structure, modules and analyses, with an
interactive layer (command bar, breadcrumb, deep links, shortcuts, plot and
table tools, pins with visual comparison), a new look ("Instrument"), a fixed
dark mode, faster self-contained loading and a new TLG Catalog tab. Renamed from *lumen* to **teal_neue** (R package
`teal.neue`; R package names cannot contain `_`).

## TLG Catalog

* New **TLG Catalog** tab next to Data Table with every output of the TLG
  Catalog (stable): 87 tables, 29 listings and 19 graphs, one page per topic
  (16 pages). Each page has an index column with a searchable,
  keyboard-navigable list of the outputs (Tables / Listings / Graphs
  sections, IDs in mono) and the output sheet with its title and actions.
  Every output is also reachable from the command bar and has its own link.
* Outputs run on the app's filtered data through teal's `eval_code()`, so
  "Show R code" gives the complete, reproducible code; each output links to
  its catalog page. Results are cached per output until the filters change.
* Outputs needing datasets the app does not load use the random.cdisc.data
  examples restricted to the filtered patients (`tlg_example_data()`).
* A failing output (or a missing package, e.g. *rbmi* for RBMIT01) shows a
  clear message with the code instead of breaking the page.

## Breaking changes (rename)

* Package `lumen` -> `teal.neue`; project file `teal_neue.Rproj`.
* Functions: `lumen_app()` -> `teal_neue_app()`, `load_lumen_data()` ->
  `load_teal_neue_data()`, `build_lumen_teal_data()` -> `build_teal_neue_data()`,
  `lumen_clear_cache()` -> `teal_neue_clear_cache()`, `lumen_join_keys()` ->
  `teal_neue_join_keys()`. `run_app()` and the pipeline functions keep their names.
* Options: `lumen.*` -> `teal_neue.*` (see `?teal_neue_options`).
* Disk cache: `teal_neue_adam.rds` in `tools::R_user_dir("teal.neue", "cache")`.
  The old cache (`tools::R_user_dir("lumen", "cache")`) is no longer used and
  can be deleted.

## Interaction

teal_neue adds an interactive layer over teal's unchanged structure (nothing
is moved; every module works as before, with or without it):

* **Command bar** (`Ctrl+K` / `Cmd+K`, or `/`, or the search field in the
  header): fuzzy search over every module (with its full path, e.g.
  *Safety Analysis / Adverse Events / AE Summary*), all 135 TLG Catalog
  outputs (by ID or title, e.g. `aet02` or `ae grade`) and every action.
  Recent views come first, then *Where to?*: every module in its category
  and sub-group, as cards nested like the menus (each category with its
  tint); typing switches to ranked results. Scopes (All, Where to?, TLG
  outputs, Actions; `Tab` cycles them) and prefixes (`>` actions, `#` outputs); `Ctrl/Cmd+Enter`
  opens the result in a new browser tab. Deeply nested modules are one
  search away instead of two or three menus.
* **Where am I**: a breadcrumb of the current module (and TLG output) in the
  header; each crumb lists its group's modules. The browser tab shows the
  module name.
* **Deep links and history**: every view has its own address
  (`#/safety-analysis/adverse-events/ae-summary`, also
  `#/tlg-catalog/adverse-events/aet02`), so views can be bookmarked and
  shared, and the browser's back and forward buttons move between views.
* **Home page**: the App Info page opens with *Study at a glance*. The logo
  and the app name in the header lead home (so does `H`).
  * *Study at a glance*: key figures (subjects, median age, female share,
    serious adverse events, median overall survival, response rate), each
    with a small chart, and three widgets: **Demographics** (age histogram
    with the median, median age by arm, sex, race), **Safety** (subjects with
    any, serious, grade 3 or higher, withdrawal-causing adverse events and
    deaths, and the most frequent adverse events, as one dot per arm on a
    common scale) and **Efficacy** (Kaplan-Meier curves of overall survival
    with a crosshair that reads survival by arm at any time, medians by arm,
    response rates with 95% Wilson intervals). Each arm has one colour
    everywhere (placebo in grey); pointing at an arm highlights it across
    all widgets, clicking its chip keeps it highlighted. Each widget links to
    the module that goes into detail. The figures describe the whole study
    (safety or intent-to-treat population, before any filter) and are
    computed once when the app is built (`R/overview.R`); parts whose data
    are missing are left out.
  * A *Where to?* button opens the command bar on every module, grouped as
    in the menus.
* **Keyboard shortcuts** (`?` shows them all): `H` home, `[` / `]` previous
  / next module, `T` light / dark, `A` appearance, `D` spacing, `F` focus mode, `\` filter
  panel, `C` "Show R code", `P` pins, `L` copy a link to this view.
* **Plot tools** (hover a plot): *Expand* into a full-screen viewer (zoom at
  the pointer with the wheel, drag to pan, `0` fit, `1` actual size),
  *Pin*, *Compare*, *Copy* (image to the clipboard) and *PNG* download.
  Clicking a plot opens the viewer too, except on plots that use clicks
  themselves (brushing).
* **Table tools** (hover a table): *Copy* for Excel (the layout is kept),
  *CSV* download, *Pin*.
* **Pins and comparison**: pin a plot, change a filter, then *Compare*: the
  viewer shows the pinned and the current plot with a swipe divider, side
  by side, or as a **difference** (unchanged pixels turn white, what changed
  keeps its colour). Pins are kept in a tray for the session (`P`); any two
  can be compared.
* **Status**: a progress line while the server computes (only after 180 ms, so
  fast updates do not flicker), an amber status dot, and the duration of the
  last update next to the data source and number of subjects.
* **Appearance** (the sliders button in the header, or `A`): colour mode
  (light, dark, or following the system), text size (S, M, L, XL), spacing
  (compact, comfortable, roomy; `D` cycles it), accent (by section, or one of
  teal, ocean, iris, graphite for the whole app), corners (soft or crisp),
  contrast (standard or high), canvas (dot grid or plain) and motion.
  Remembered by the browser and applied before the first paint.
* **Section tints**: each main category has its own quiet accent: teal for the
  general pages, blue for Exploratory, terracotta for Safety, green for
  Efficacy, violet for the TLG Catalog. The selected tab, buttons, focus
  rings, selections and a breath of the canvas take it, so moving between
  categories is felt without being loud; the breadcrumb, the *Where to?*
  cards and the home widgets carry the same colour marks. The brand stays
  teal.
* **Focus mode**: the header and footer step aside for the module.
* Everything is keyboard accessible (the command bar is an ARIA combobox,
  dialogs trap focus and return it) and respects reduced motion.

## Look and feel

"Instrument": a look for people who read clinical data all day.

* White, hairline-ruled panels on a faint dot-grid canvas (lab-notebook
  paper). Colour only where it means something: teal for where you are and
  what acts, amber for work in progress.
* Two typefaces with distinct jobs: the system font (SF Pro on Apple
  devices, no download) or Inter for reading; JetBrains Mono for machine
  facts (dataset and variable names such as `ADSL · AGE` in the filter
  cards, output IDs, counts, timings, keys, section labels).
* Top-level tabs are a rail with a sliding teal indicator; nested tabs are a
  compact segmented control; menus, dialogs and notifications are crisp
  sheets; code is shown on an ink "terminal" in both modes.
* New app icon: a survival (Kaplan-Meier) step curve on teal.
* Fast by construction: no blur, no background images, no ambient animation;
  transitions are 120-260 ms and only on transform, opacity and colour.
  `options(teal_neue.motion = FALSE)` turns animations off.
* Light mode is the default (`teal_neue.color_mode = "light"`).
* The look is a CSS layer over teal's default Bootstrap 5 theme (it redefines
  Bootstrap's CSS variables) plus one script, so the app stays recognisably
  teal and needs no Sass compilation at start-up.
* `options(teal_neue.style = FALSE)` restores the plain teal look (and turns
  the interactive layer off).

## Dark mode

* New dark palette: an instrument panel at night: ink-blue blacks, hairlines
  that stay visible, a luminous teal accent (`#2cc5b4`) and amber for work in
  progress.
* Switching modes is a circular reveal from the toggle (View Transitions; an
  instant switch in browsers without them).
* Fixed widgets that kept light-mode colours in dark mode: neutral/light/outline
  buttons, `.bg-light`/`.bg-white` surfaces, `.text-dark`, `.table-light`,
  selectize inputs and dropdowns, native selects, DataTables (rows, paging,
  search), plotly axis text (filter panel histograms), notifications,
  tooltips.
* Plots (rendered on the server as light images) stay white "paper" with a
  hairline frame and slightly dimmed glare; their colours stay identical to the
  reproducible R code.
* The colour mode starts light by default (`teal_neue.color_mode`: `"light"`,
  `"dark"` or `"auto"` to follow the operating system); dark mode is applied
  before the first paint (no white flash), and the user's choice is remembered
  by the browser.
* Works around a bslib toggle bug that wrote `data-bs-theme="undefined"` when the
  page started in light mode, which made the first click do nothing.

## Plots

* A cleaner, editorial look for every ggplot2 module through teal's
  `teal.ggplot2_args` option (`teal_neue_ggplot2_args()`), on top of whichever
  ggplot2 theme the user picks: large left-aligned bold titles; a graded ink
  scale (titles, axis and legend titles, axis labels, captions); facet labels
  as bold left-aligned headings instead of grey strips; no tick marks or minor
  grid lines; plain legend keys; more room between panels and around the
  plot. They appear in "Show R code", so reproduced plots match the app. Data
  colours (the NEST palette) are unchanged. Set the option yourself to
  override it.
* Exploratory plot modules default to `theme_minimal()` instead of the grey
  `theme_gray()` (option `teal_neue.ggtheme`; users can still change it per
  module). The theme is only passed to modules whose installed version
  supports it.
* Scatterplot: smaller, slightly transparent points (`size = 2.5`, `alpha = 0.8`)
  so overlapping subjects stay visible.
* Plots can be expanded, pinned, compared (swipe, side by side, difference),
  copied and downloaded from the app (see "Interaction").

## Loading

* **Instant relaunch**: the built app is kept for the R session; `run_app()`
  with the same settings and data reuses it (a fraction of a second instead
  of a full build). `options(teal_neue.app_cache = FALSE)` turns this off;
  `teal_neue_clear_cache()` forgets it.
* **Instant reloads and new sessions**: teal builds the page (the interface
  of every module) on each browser request; teal_neue keeps the first page
  and serves it again (requests with a query string, e.g. a bookmark, are
  still built afresh).
* The TLG Catalog registry is built once per session (it was built several
  times per app build).
* The script is loaded with `defer`, so it never delays the first paint;
  settings that affect the look (colour mode, appearance) are applied by a
  tiny inline script before the first paint.
* The build reports where its time goes, e.g. `App built in 2.1s (data 0.3s,
  modules 1.2s, overview 0.1s, teal 0.5s)`, and the status in the header
  shows how long the app took to be ready in the browser (`ready 1.8 s`).
* No third-party requests: the favicon (previously fetched from GitHub on
  every page load) is inlined, and fonts and scripts are served by the app
  itself, which also suits offline and firewalled deployments.
* No UI font download at all on Apple devices (system font); elsewhere one
  92 KB Inter file (every weight) instead of two Open Sans files, plus
  JetBrains Mono (2 x 32 KB) for machine facts. The italic face is
  deliberately not shipped, so icon tags do not trigger an extra download.
* The new look costs no Sass compilation (about 0.75 s per cold start for a
  custom `bslib::bs_theme()`): bslib's precompiled default theme is kept.
* The interactive layer is one dependency-free script; it does its work on
  demand (the command bar is built the first time it opens).

# lumen 0.1.0

* First release as an R package.
* Combines the exploratory, safety and efficacy teal.gallery templates in one
  app, with module-specific filters (safety population for safety modules,
  intent-to-treat for efficacy modules) and a dark mode toggle.
* Data pipeline `ingest_adam()` -> `validate_adam()` -> `preprocess_adam()`
  with session memory and disk caches (`load_lumen_data()`).
* Data sources: bundled *random.cdisc.data* datasets, freshly generated
  synthetic data (`N`, `seed`, per-dataset arguments) and ADaM parquet files
  (`export_adam_parquet()` writes them).
* Data contract (`adam_contract()`) and checks of the values the app
  pre-selects (`check_app_defaults()`).
* Readable, illustrative MedDRA-style adverse event names (`ae_dictionary()`).
* Reproducible "Show R code": calls `lumen::load_lumen_data()` with the
  resolved data-source settings.
* Fix: `ADLBPCA` now has join keys, so the ADSL filters (sex, age) also apply
  to the PCA module (the exploratory template silently lacked them).
