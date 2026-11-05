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
