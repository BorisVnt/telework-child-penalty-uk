# ============================================================
# 03_event_study.R
# Event-study estimations and teleworkability heterogeneity
# ============================================================

library(dplyr)
library(fixest)

# This script assumes that 01_prepare_data.R and
# 02_build_variables.R have already been run.

if (!exists("analysis_sample")) {
  stop("Object `analysis_sample` not found. Run the previous scripts first.")
}


# ------------------------------------------------------------
# 1. Prepare estimation sample
# ------------------------------------------------------------

estimation_sample <- analysis_sample %>%
  mutate(
    intdaty_dv = as.numeric(intdaty_dv),
    age_dv = as.numeric(age_dv),
    sex = as.numeric(sex),
    high_teleworkability = as.numeric(high_teleworkability)
  ) %>%
  filter(
    !is.na(pidp),
    !is.na(event_time)
  )


# ============================================================
# 2. Main event study: motherhood penalty
# ============================================================

# ------------------------------------------------------------
# Labour income
# ------------------------------------------------------------
#
# PPML is used because labour income includes zero values.
# t = -1 is the reference period.

model_income <- fepois(
  labour_income ~ i(event_time, ref = -1) |
    pidp + intdaty_dv + age_dv,
  data = estimation_sample %>%
    filter(
      sex == 2,
      event_time >= -5,
      event_time <= 10
    ),
  cluster = ~pidp
)

summary(model_income)


# ------------------------------------------------------------
# Hours worked
# ------------------------------------------------------------

model_hours <- fepois(
  hours_worked ~ i(event_time, ref = -1) |
    pidp + intdaty_dv + age_dv,
  data = estimation_sample %>%
    filter(
      sex == 2,
      event_time >= -5,
      event_time <= 10
    ),
  cluster = ~pidp
)

summary(model_hours)


# ============================================================
# 3. Heterogeneity by pre-birth teleworkability
# ============================================================

# The interaction coefficients measure whether the evolution
# after childbirth differs between women whose pre-birth
# occupations have high versus low teleworkability.


# ------------------------------------------------------------
# Labour income
# ------------------------------------------------------------

model_income_tw <- fepois(
  labour_income ~
    i(event_time, ref = -1) +
    i(
      event_time,
      high_teleworkability,
      ref = -1
    ) |
    pidp + intdaty_dv + age_dv,
  data = estimation_sample %>%
    filter(
      sex == 2,
      !is.na(high_teleworkability),
      event_time >= -5,
      event_time <= 10
    ),
  cluster = ~pidp
)

summary(model_income_tw)


# ------------------------------------------------------------
# Hours worked
# ------------------------------------------------------------

model_hours_tw <- fepois(
  hours_worked ~
    i(event_time, ref = -1) +
    i(
      event_time,
      high_teleworkability,
      ref = -1
    ) |
    pidp + intdaty_dv + age_dv,
  data = estimation_sample %>%
    filter(
      sex == 2,
      !is.na(high_teleworkability),
      event_time >= -5,
      event_time <= 10
    ),
  cluster = ~pidp
)

summary(model_hours_tw)


# ============================================================
# 4. Employment participation
# ============================================================

# Participation is binary, so a linear probability model
# with individual, year and age fixed effects is estimated.

model_participation_tw <- feols(
  participation ~
    i(event_time, ref = -1) +
    i(
      event_time,
      high_teleworkability,
      ref = -1
    ) |
    pidp + intdaty_dv + age_dv,
  data = estimation_sample %>%
    filter(
      sex == 2,
      !is.na(high_teleworkability),
      event_time >= -5,
      event_time <= 10
    ),
  cluster = ~pidp
)

summary(model_participation_tw)


# ============================================================
# 5. Hourly wage conditional on employment
# ============================================================

model_hourly_wage_tw <- feols(
  hourly_wage ~
    i(event_time, ref = -1) +
    i(
      event_time,
      high_teleworkability,
      ref = -1
    ) |
    pidp + intdaty_dv + age_dv,
  data = estimation_sample %>%
    filter(
      sex == 2,
      !is.na(high_teleworkability),
      !is.na(hourly_wage),
      event_time >= -5,
      event_time <= 10
    ),
  cluster = ~pidp
)

summary(model_hourly_wage_tw)


# ============================================================
# 6. Covid-19 as an activation shock of remote work
# ============================================================

# The pandemic substantially increased the effective use of
# remote work. This complementary specification tests whether
# the differential motherhood penalty associated with
# teleworkability became stronger once remote work became
# widely available.

covid_sample <- estimation_sample %>%
  mutate(
    post_covid = as.numeric(intdaty_dv >= 2021)
  ) %>%
  filter(
    sex == 2,
    !is.na(high_teleworkability),
    intdaty_dv >= 2015,
    event_time >= -3,
    event_time <= 2
  )


# ------------------------------------------------------------
# Covid interaction: labour income
# ------------------------------------------------------------

model_covid_income <- fepois(
  labour_income ~
    i(event_time, ref = -1) +
    i(
      event_time,
      high_teleworkability,
      ref = -1
    ) +
    i(
      event_time,
      post_covid,
      ref = -1
    ) +
    i(
      event_time,
      I(high_teleworkability * post_covid),
      ref = -1
    ) |
    pidp + intdaty_dv,
  data = covid_sample,
  cluster = ~pidp
)

summary(model_covid_income)


# ------------------------------------------------------------
# Covid interaction: hours worked
# ------------------------------------------------------------

model_covid_hours <- fepois(
  hours_worked ~
    i(event_time, ref = -1) +
    i(
      event_time,
      high_teleworkability,
      ref = -1
    ) +
    i(
      event_time,
      post_covid,
      ref = -1
    ) +
    i(
      event_time,
      I(high_teleworkability * post_covid),
      ref = -1
    ) |
    pidp + intdaty_dv,
  data = covid_sample,
  cluster = ~pidp
)

summary(model_covid_hours)


# ============================================================
# 7. Model overview
# ============================================================

etable(
  model_income_tw,
  model_hours_tw,
  model_participation_tw,
  model_hourly_wage_tw,
  headers = c(
    "Labour income",
    "Hours worked",
    "Employment",
    "Hourly wage"
  ),
  fitstat = ~n
)
