# ============================================================
# 04_figures.R
# Main event-study figures
# ============================================================

library(dplyr)
library(ggplot2)
library(fixest)

# This script assumes that 03_event_study.R has already been run.

if (!exists("model_income_tw") || !exists("model_hours_tw")) {
  stop("Main models not found. Run 03_event_study.R first.")
}


# ------------------------------------------------------------
# Output directory
# ------------------------------------------------------------

dir.create(
  "outputs",
  showWarnings = FALSE
)


# ============================================================
# 1. Function to extract teleworkability interaction effects
# ============================================================

extract_telework_effect <- function(model) {

  b <- coef(model)
  V <- vcov(model)

  # Interaction coefficients:
  # event time × high pre-birth teleworkability
  idx <- grep(
    "^event_time::-?[0-9]+:high_teleworkability$",
    names(b)
  )

  event_time <- as.numeric(
    gsub(
      "event_time::|:high_teleworkability",
      "",
      names(b)[idx]
    )
  )

  estimates <- b[idx]
  standard_errors <- sqrt(diag(V)[idx])

  df <- tibble(
    event_time = event_time,
    estimate = estimates,
    se = standard_errors
  ) %>%
    mutate(
      ci_low = estimate - 1.96 * se,
      ci_high = estimate + 1.96 * se,

      # PPML coefficients are transformed into percentage effects
      effect_pct = 100 * (exp(estimate) - 1),
      ci_low_pct = 100 * (exp(ci_low) - 1),
      ci_high_pct = 100 * (exp(ci_high) - 1)
    )

  # Add reference period t = -1
  bind_rows(
    df,
    tibble(
      event_time = -1,
      estimate = 0,
      se = 0,
      ci_low = 0,
      ci_high = 0,
      effect_pct = 0,
      ci_low_pct = 0,
      ci_high_pct = 0
    )
  ) %>%
    arrange(event_time)
}


# ============================================================
# 2. Extract estimates
# ============================================================

income_effect <- extract_telework_effect(
  model_income_tw
)

hours_effect <- extract_telework_effect(
  model_hours_tw
)


# ============================================================
# 3. Generic plotting function
# ============================================================

plot_event_study <- function(data, title, y_label) {

  ggplot(
    data,
    aes(
      x = event_time,
      y = effect_pct
    )
  ) +

    geom_ribbon(
      aes(
        ymin = ci_low_pct,
        ymax = ci_high_pct
      ),
      alpha = 0.15
    ) +

    geom_line(
      linewidth = 0.8
    ) +

    geom_point(
      size = 2.4
    ) +

    geom_hline(
      yintercept = 0,
      linetype = "dotted",
      linewidth = 0.5
    ) +

    geom_vline(
      xintercept = -0.5,
      linetype = "dashed",
      linewidth = 0.6
    ) +

    annotate(
      "text",
      x = -0.65,
      y = Inf,
      label = "First birth",
      hjust = 1,
      vjust = 1.5,
      size = 3.5
    ) +

    scale_x_continuous(
      breaks = seq(-5, 10, 1)
    ) +

    labs(
      title = title,
      subtitle = "High vs. low pre-birth occupational teleworkability",
      x = "Years relative to first birth",
      y = y_label,
      caption = paste(
        "Reference period: t = -1.",
        "Individual, year and age fixed effects.",
        "95% confidence intervals; standard errors clustered at the individual level."
      )
    ) +

    theme_bw(
      base_size = 12
    ) +

    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(
        face = "bold"
      ),
      plot.caption = element_text(
        size = 8,
        hjust = 0
      )
    )
}


# ============================================================
# 4. Labour income
# ============================================================

plot_income <- plot_event_study(
  data = income_effect,
  title = "Teleworkability and the motherhood penalty in labour income",
  y_label = "Differential effect (%)"
)

plot_income


# ============================================================
# 5. Hours worked
# ============================================================

plot_hours <- plot_event_study(
  data = hours_effect,
  title = "Teleworkability and the motherhood penalty in hours worked",
  y_label = "Differential effect (%)"
)

plot_hours


# ============================================================
# 6. Save figures
# ============================================================

ggsave(
  filename = "outputs/teleworkability_income.png",
  plot = plot_income,
  width = 8,
  height = 5,
  dpi = 300
)

ggsave(
  filename = "outputs/teleworkability_hours.png",
  plot = plot_hours,
  width = 8,
  height = 5,
  dpi = 300
)
