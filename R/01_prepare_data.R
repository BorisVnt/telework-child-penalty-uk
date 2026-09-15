# ============================================================
# 01_prepare_data.R
# Import and harmonise UKHLS waves 1–15
# ============================================================

library(haven)
library(dplyr)
library(purrr)
library(readr)

# ------------------------------------------------------------
# Data location
# ------------------------------------------------------------

# Raw UKHLS data are not distributed with this repository.
# Replace this path with the local directory containing the
# UKHLS individual response files.

data_dir <- "path/to/ukhls/stata14_se/ukhls"


# ------------------------------------------------------------
# Function used to import and harmonise one UKHLS wave
# ------------------------------------------------------------

load_wave <- function(path, prefix, wave_num) {

  variables <- c(
    "pidp",
    paste0(prefix, "_jbfxuse7"),
    paste0(prefix, "_jbflex7"),
    paste0(prefix, "_paygu_dv"),
    paste0(prefix, "_fimnlabgrs_dv"),
    paste0(prefix, "_jbhrs"),
    paste0(prefix, "_jshrs"),
    paste0(prefix, "_jbstat"),
    paste0(prefix, "_jboff"),
    paste0(prefix, "_sex"),
    paste0(prefix, "_nchild_dv"),
    paste0(prefix, "_age_dv"),
    paste0(prefix, "_intdaty_dv"),
    paste0(prefix, "_howlng"),
    paste0(prefix, "_jbisco88_cc"),
    paste0(prefix, "_jlisco88_cc"),
    paste0(prefix, "_jbttwt"),
    paste0(prefix, "_indinus_xw"),
    paste0(prefix, "_indinub_xw"),
    paste0(prefix, "_indinui_xw"),
    paste0(prefix, "_inding2_xw")
  )

  df <- read_dta(
    path,
    col_select = any_of(variables)
  )

  # Some variables are not available in every wave.
  # Missing variables are created as NA to keep a common structure.
  for (v in variables) {
    if (!v %in% names(df)) {
      df[[v]] <- NA
    }
  }

  df %>%
    rename(
      jbfxuse7   = !!sym(paste0(prefix, "_jbfxuse7")),
      jbflex7    = !!sym(paste0(prefix, "_jbflex7")),
      paygu_dv   = !!sym(paste0(prefix, "_paygu_dv")),
      pay_dv     = !!sym(paste0(prefix, "_fimnlabgrs_dv")),
      jbhrs      = !!sym(paste0(prefix, "_jbhrs")),
      jshrs      = !!sym(paste0(prefix, "_jshrs")),
      jbstat     = !!sym(paste0(prefix, "_jbstat")),
      jboff      = !!sym(paste0(prefix, "_jboff")),
      sex        = !!sym(paste0(prefix, "_sex")),
      nchild_dv  = !!sym(paste0(prefix, "_nchild_dv")),
      age_dv     = !!sym(paste0(prefix, "_age_dv")),
      intdaty_dv = !!sym(paste0(prefix, "_intdaty_dv")),
      howlng     = !!sym(paste0(prefix, "_howlng")),
      jbisco     = !!sym(paste0(prefix, "_jbisco88_cc")),
      jlisco     = !!sym(paste0(prefix, "_jlisco88_cc")),
      jbttwt     = !!sym(paste0(prefix, "_jbttwt")),
      indinus_xw = !!sym(paste0(prefix, "_indinus_xw")),
      indinub_xw = !!sym(paste0(prefix, "_indinub_xw")),
      indinui_xw = !!sym(paste0(prefix, "_indinui_xw")),
      inding2_xw = !!sym(paste0(prefix, "_inding2_xw"))
    ) %>%

    mutate(
      xswgt = case_when(
        wave_num == 1 ~ as.numeric(indinus_xw),
        wave_num >= 2 & wave_num <= 5 ~ as.numeric(indinub_xw),
        wave_num >= 6 & wave_num <= 13 ~ as.numeric(indinui_xw),
        wave_num >= 14 & wave_num <= 15 ~ as.numeric(inding2_xw),
        TRUE ~ NA_real_
      ),
      wave = wave_num
    ) %>%

    select(
      pidp,
      wave,
      jbfxuse7,
      jbflex7,
      paygu_dv,
      pay_dv,
      jbhrs,
      jshrs,
      jbstat,
      jboff,
      sex,
      nchild_dv,
      age_dv,
      intdaty_dv,
      howlng,
      jbisco,
      jlisco,
      jbttwt,
      xswgt
    )
}


# ------------------------------------------------------------
# Import waves 1–15
# ------------------------------------------------------------

wave_info <- tibble(
  wave = 1:15,
  prefix = letters[1:15],
  filename = paste0(letters[1:15], "_indresp.dta")
)

panel <- pmap_dfr(
  wave_info,
  function(wave, prefix, filename) {
    load_wave(
      path = file.path(data_dir, filename),
      prefix = prefix,
      wave_num = wave
    )
  }
)


# ------------------------------------------------------------
# Basic harmonisation
# ------------------------------------------------------------

panel <- panel %>%
  mutate(
    across(
      c(jbstat, jboff, jbfxuse7, jbflex7),
      as.numeric
    )
  )


# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------

print(dim(panel))
print(table(panel$wave))
