install.packages('tidyverse')
install.packages('devtools')
install.packages('ggplot2')
install.packages('StatsBombR')
install.packages("remotes")
remotes::install_version("SDMTools", "1.1-221")
devtools::install_github("statsbomb/StatsBombR")
library(tidyverse)
library(StatsBombR)

Comp <- FreeCompetitions() %>%
  filter(competition_id==37 & season_name=="2020/2021")

Matches <- FreeMatches(Comp)
StatsBombData <- free_allevents(MatchesDF = Matches, Parallel = T)
StatsBombData = allclean(StatsBombData)
                                