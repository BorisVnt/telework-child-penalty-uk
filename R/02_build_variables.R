# ============================================================
# 02_build_variables.R
# Build childbirth, employment and teleworkability variables
# ============================================================

library(dplyr)
library(readr)

# This script assumes that 01_prepare_data.R has already been run
# and that the object `panel` is available.

if (!exists("panel")) {
  stop("Object `panel` not found. Run 01_prepare_data.R first.")
}


# ------------------------------------------------------------
# 1. Identify the first childbirth event
# ------------------------------------------------------------

panel_birth <- panel %>%
  mutate(
    nchild_dv = as.numeric(nchild_dv),
    wave = as.numeric(wave)
  ) %>%
  filter(
    !is.na(pidp),
    !is.na(nchild_dv),
    !is.na(wave)
  ) %>%
  arrange(pidp, wave) %>%
  group_by(pidp) %>%
  mutate(
    first_obs_children = first(nchild_dv),
    lag_children = lag(nchild_dv),

    # First observed transition from no child to at least one child
    birth_event =
      first_obs_children == 0 &
      !is.na(lag_children) &
      lag_children == 0 &
      nchild_dv >= 1
  ) %>%
  mutate(
    first_birth_wave = if_else(
      any(birth_event, na.rm = TRUE),
      min(wave[birth_event], na.rm = TRUE),
      NA_real_
    )
  ) %>%
  ungroup() %>%
  filter(!is.na(first_birth_wave)) %>%
  mutate(
    # t = 0 corresponds to the wave in which the first birth is observed
    event_time = wave - first_birth_wave
  )


# ------------------------------------------------------------
# 2. Teleworkability score
# ------------------------------------------------------------

# The occupational teleworkability file is not distributed
# with this repository.
#
# It should contain:
# - isco88: occupational ISCO-88 code
# - teleworkable: teleworkability score

telework_file <- "path/to/occupations_by_remote_workability.csv"

remote_raw <- read_csv(
  telework_file,
  show_col_types = FALSE
)


# Convert the occupational crosswalk to 3-digit ISCO-88 codes
remote_clean <- remote_raw %>%
  transmute(
    isco88 = as.integer(isco88),
    teleworkable = as.numeric(teleworkable)
  ) %>%
  filter(
    !is.na(isco88),
    !is.na(teleworkable),
    isco88 > 0
  )


telework_crosswalk <- remote_clean %>%
  mutate(
    isco88_3d = floor(isco88 / 10)
  ) %>%
  group_by(isco88_3d) %>%
  summarise(
    telework_score = mean(teleworkable, na.rm = TRUE),
    .groups = "drop"
  )


# ------------------------------------------------------------
# 3. Define pre-birth occupation
# ------------------------------------------------------------

panel_birth <- panel_birth %>%
  mutate(
    jbisco = suppressWarnings(as.integer(jbisco)),
    jlisco = suppressWarnings(as.integer(jlisco)),

    jbisco = if_else(
      !is.na(jbisco) & jbisco > 0,
      jbisco,
      NA_integer_
    ),

    jlisco = if_else(
      !is.na(jlisco) & jlisco > 0,
      jlisco,
      NA_integer_
    )
  )


# Priority:
# 1. Current occupation at t = -1
# 2. Last occupation at t = -1
# 3. Most recent current occupation observed before t = -1

prebirth_occupation <- panel_birth %>%
  filter(
    event_time >= -10,
    event_time <= -1
  ) %>%
  arrange(pidp, desc(event_time)) %>%
  group_by(pidp) %>%
  summarise(

    jb_t1 = first(
      jbisco[event_time == -1],
      default = NA_integer_
    ),

    jl_t1 = first(
      jlisco[event_time == -1],
      default = NA_integer_
    ),

    jb_prior = {
      x <- jbisco[event_time < -1]
      x <- x[!is.na(x)]

      if (length(x) == 0) {
        NA_integer_
      } else {
        x[1]
      }
    },

    isco88_prebirth = coalesce(
      jb_t1,
      jl_t1,
      jb_prior
    ),

    occupation_source = case_when(
      !is.na(jb_t1) ~ "current occupation at t-1",
      !is.na(jl_t1) ~ "last occupation at t-1",
      !is.na(jb_prior) ~ "previous occupation",
      TRUE ~ NA_character_
    ),

    .groups = "drop"
  )


# ------------------------------------------------------------
# 4. Match occupation with teleworkability
# ------------------------------------------------------------

prebirth_occupation <- prebirth_occupation %>%
  left_join(
    telework_crosswalk,
    by = c("isco88_prebirth" = "isco88_3d")
  )


panel_birth <- panel_birth %>%
  left_join(
    prebirth_occupation %>%
      select(
        pidp,
        isco88_prebirth,
        telework_score,
        occupation_source
      ),
    by = "pidp"
  )


# ------------------------------------------------------------
# 5. High / low teleworkability
# ------------------------------------------------------------

telework_median <- median(
  panel_birth$telework_score,
  na.rm = TRUE
)


panel_birth <- panel_birth %>%
  mutate(
    high_teleworkability = case_when(
      is.na(telework_score) ~ NA,
      telework_score > telework_median ~ 1,
      telework_score <= telework_median ~ 0
    )
  )


# ------------------------------------------------------------
# 6. Employment participation
# ------------------------------------------------------------

# Employment status based on reported labour-market status

panel_birth <- panel_birth %>%
  mutate(
    employment_status = case_when(

      # Employed / attached to employment
      jbstat %in% c(1, 2, 5, 11, 12, 13, 14, 15) ~ 1,

      # Not employed
      jbstat %in% c(3, 4, 6, 7, 8, 9, 10, 97) ~ 0,

      TRUE ~ NA_real_
    )
  )


# Alternative participation measure used in the empirical analysis

panel_birth <- panel_birth %>%
  mutate(
    participation = case_when(
      pay_dv > 0 ~ 1,
      pay_dv == 0 ~ 0,
      TRUE ~ NA_real_
    )
  )


# ------------------------------------------------------------
# 7. Hours worked
# ------------------------------------------------------------

panel_birth <- panel_birth %>%
  mutate(
    jbhrs = as.numeric(jbhrs),
    jshrs = as.numeric(jshrs),

    hours_worked = case_when(
      jbhrs >= 0 ~ jbhrs,
      jshrs >= 0 ~ jshrs,
      employment_status == 0 ~ 0,
      TRUE ~ NA_real_
    )
  )


# ------------------------------------------------------------
# 8. Labour income
# ------------------------------------------------------------

panel_birth <- panel_birth %>%
  mutate(
    labour_income = case_when(
      pay_dv >= 0 ~ as.numeric(pay_dv),
      TRUE ~ NA_real_
    )
  )


# ------------------------------------------------------------
# 9. Hourly wage
# ------------------------------------------------------------

panel_birth <- panel_birth %>%
  mutate(
    monthly_hours = hours_worked * 4.33,

    hourly_wage = case_when(
      hours_worked > 0 & labour_income > 0 ~
        labour_income / monthly_hours,

      TRUE ~ NA_real_
    )
  )


# ------------------------------------------------------------
# 10. Restrict to the main event-study window
# ------------------------------------------------------------

analysis_sample <- panel_birth %>%
  filter(
    event_time >= -5,
    event_time <= 10
  )


# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------

cat(
  "Individuals with identified first birth:",
  n_distinct(panel_birth$pidp),
  "\n"
)

cat(
  "Individuals with teleworkability score:",
  n_distinct(panel_birth$pidp[!is.na(panel_birth$telework_score)]),
  "\n"
)

cat(
  "Median teleworkability score:",
  round(telework_median, 3),
  "\n"
)

print(
  table(
    panel_birth$high_teleworkability,
    useNA = "ifany"
  )
)
