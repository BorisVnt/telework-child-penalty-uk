# Can telework mitigate the motherhood penalty? Evidence from the UK

This repository presents the main R code used for my Master 2 research project in Public Policy at Université Paris 1 Panthéon-Sorbonne.

## Research question

The project studies whether teleworkability can mitigate the motherhood penalty in the United Kingdom.

Using longitudinal data from the UK Household Longitudinal Study (UKHLS), I analyse how women's employment trajectories evolve around the birth of their first child and whether these effects differ according to the teleworkability of their occupation before childbirth.

## Data

- UK Household Longitudinal Study (UKHLS)
- Waves 1 to 15
- Period: 2009–2024
- Longitudinal individual data
- Main outcomes: labour income, hours worked, employment participation and hourly wage

The raw UKHLS data are not included in this repository due to access and redistribution restrictions.

## Methodology

The analysis includes:

- construction and cleaning of a longitudinal panel;
- identification of the first childbirth event;
- construction of relative event time;
- matching occupational ISCO-88 codes with a teleworkability score;
- event-study estimations;
- individual, year and age fixed effects;
- clustered standard errors;
- Poisson Pseudo-Maximum Likelihood models for outcomes including zero values;
- heterogeneity analysis according to pre-birth teleworkability.
- complementary analysis exploiting the Covid-19 pandemic as a large-scale activation shock of remote work.

## Main findings

The results indicate that women in highly teleworkable occupations experience a smaller motherhood penalty after the birth of their first child.

In the short run, high teleworkability is associated with an attenuation of approximately 6.5 percentage points in the earnings penalty and 7 percentage points in the reduction in hours worked. The difference also appears to persist over a longer horizon.

The results suggest that this attenuation operates mainly through the extensive margin, by limiting exits from employment after childbirth.

As a complementary analysis, I exploit the Covid-19 pandemic as a shock that substantially increased the effective use of remote work. The results become more pronounced once remote work became widely available, providing additional evidence that the estimated differences are not solely driven by pre-existing selection into teleworkable occupations.

## Repository structure

- `R/01_prepare_data.R`: import, harmonisation and construction of the longitudinal panel
- `R/02_build_variables.R`: construction of childbirth, employment and teleworkability variables
- `R/03_event_study.R`: econometric estimations
- `R/04_figures.R`: production of the main figures
- `outputs/`: selected graphical outputs

## Tools

R — dplyr — tidyverse — fixest — ggplot2 — haven

## Author

Boris Vincent  
Master 2 Politiques Publiques  
Université Paris 1 Panthéon-Sorbonne
