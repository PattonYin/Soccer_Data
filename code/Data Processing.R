# Set up ----
# Change Directory
setwd("/Users/pattoyin/Desktop/2023-Spring/QAC-211/Project/Data")

# Read file
library(readr)
library(tidyverse)
library(tidyr)
library(descr)
library(dplyr)
library(ggplot2)
library(jsonlite)
library(cluster)
library(factoextra)
library(gridExtra)
library(e1071)
library(fmsb)
X3773457 <- read.csv("3773457.csv")
df <- read.csv("3773457.csv")
indexing_pass_before_shot <- function (df) {
  df$passbinary = 0
  x = 1
  for (i in (1:nrow(df))) {
    if (df$type[i] == "{'id': 16, 'name': 'Shot'}") {
      for (u in (0:49)) {
        if (df$passbinary[i-u] == 0) {
          df$passbinary[i-u] = x
        }
      }
      x=x+1
    }
  }
  return(df)
}
df_2 <- indexing_pass_before_shot(df)
data_treatment <- function (df,team) {
  indexing_pass_before_shot <- function (df) {
    df$passbinary = 0
    x = 1
    for (i in (1:nrow(df))) {
      if (df$type[i] == "{'id': 16, 'name': 'Shot'}") {
        for (u in (0:49)) {
          if (df$passbinary[i-u] == 0) {
            df$passbinary[i-u] = x
          }
        }
        x=x+1
      }
    }
    return(df)
  }
  df <- indexing_pass_before_shot(df)
  df_pass = df %>%
    filter (type %in% c("{'id': 30, 'name': 'Pass'}","{'id': 42, 'name': 'Ball Receipt*'}"))
  v1<-c("typeid","typename")
  v1 <- data.frame(do.call("rbind",strsplit(as.character(df_pass$type), ",", fixed = TRUE)))
  v2 <- data.frame(do.call("rbind",strsplit(as.character(v1$X1), " ", fixed = TRUE)))
  v3 <- data.frame(do.call("rbind",strsplit(as.character(v1$X2), " ", fixed = TRUE)))
  v4 <- data.frame(do.call("rbind",strsplit(as.character(v3$X3), "}", fixed = TRUE)))
  df_pass = cbind(df_pass, v2$X2, v4)
  
  # Section 2 Location info (input df; output: df_distance_rawdata with coordinates) ----
  location <- function(df) {
    df_distance <- data.frame(location = df_pass$location)
    df_distance$location <- gsub("\\[|\\]", "", df_distance$location)
    values <- strsplit(df_distance$location, ", ")
    df_distance$col1 <- as.numeric(sapply(values, "[[", 1))
    df_distance$col2 <- as.numeric(sapply(values, "[[", 2))
    df_distance <- cbind(df_distance, df_pass$v2)
    df_distance <- cbind(df_distance, df_pass$id)
    df_distance <- cbind(df_distance, df_pass$related_events)
    df_distance <- cbind(df_distance, df_pass$timestamp)
    df_distance <- cbind(df_distance, df_pass$duration)
    df_distance <- cbind(df_distance, df_pass$period)
    df_distance <- cbind(df_distance, df_pass$passbinary)
    return(df_distance)
  }
  df_distance_rawdata <- location(df_pass)
  # Section 3 Filtering the different teams ----
  df_pass_A = df_distance_rawdata %>%
    filter(df_pass$possession_team %in% c(team))
  
  # Section 4 Filtering the initiation of pass and the completion of pass ------
  # df_ini = df_distance_rawdata %>% 
  #   filter(df_pass$`v2$X2` %in% c(30))
  # df_end = df_distance_rawdata %>%
  #   filter(df_pass$`v2$X2` %in% c(42))
  # There is a difference between the row numebr of two different dataframes. So I'm thinking about filtering those initiation of passes failed.
  
  # For this part of the code, if the initiation of pass has a related event which is in the df_end, we pick these out.
  # No this would be too much work
  
  # Section 4.(*) ----
  df_ini_A = df_pass_A %>% 
    filter(df_pass_A$`df_pass$v2` %in% c(30))
  df_end_A = df_pass_A %>%
    filter(df_pass_A$`df_pass$v2` %in% c(42))
  # There is a difference between the row numebr of two different dataframes. So I'm thinking about filtering those initiation of passes failed.
  
  # For this part of the code, if the initiation of pass has a related event which is in the df_end, we pick these out.
  # No this would be too much work
  
  
  # Section 5 Filter the passes that are completed ------
  # Section 5.1 string of array -> 2 columns ----
  # df_end <- separate(df_end, col = `df$related_events`,into=c('related_event_1','related_event_2'),sep=", ")
  # df_end$related_event_1 <- gsub("\\[", "", df_end$related_event_1)
  # df_end$related_event_1 <- gsub("'", "", df_end$related_event_1)
  # df_end$related_event_1 <- gsub("\\]", "", df_end$related_event_1)
  # df_end$related_event_2 <- gsub("\\]", "", df_end$related_event_2)
  # df_end$related_event_2 <- gsub("'", "", df_end$related_event_2)
  # 
  # Section 5.1.(*) ----
  replace_na_with_empty_string <- function(x) {
    if (is.na(x)) {
      return("")
    } else {
      return(x)
    }
  }
  eventid_treatment <- function(df_x) {
    df_x <- separate(df_x, col=`df_pass$related_events`,into=c('related_event_1','related_event_2'),sep=", ")
    df_x$related_event_1 <- gsub("\\[", "", df_x$related_event_1)
    df_x$related_event_1 <- gsub("'", "", df_x$related_event_1)
    df_x$related_event_1 <- gsub("\\]", "", df_x$related_event_1)
    df_x$related_event_2 <- gsub("\\]", "", df_x$related_event_2)
    df_x$related_event_2 <- gsub("'", "", df_x$related_event_2)
    df_x <- as.data.frame(apply(df_x, 2, function(x) sapply(x, replace_na_with_empty_string)))
    return(df_x)
  }
  # trial code
  df_end_A = eventid_treatment(df_end_A)
  
  
  # Section 5.2 find the completed passes ----
  # df_end$ini_x <- c(NA)
  # df_end$ini_y <- c(NA)
  # for (i in (1:nrow(df_ini))) {
  #   for (u in (1:nrow(df_end))) {
  #     if (df_ini$`df_pass$id`[i] %in% df_end$related_event_1[u] || df_ini$`df_pass$id`[i] %in% df_end$related_event_2[u]) {
  #       df_end$ini_x[u] = df_ini$col1[i]
  #       df_end$ini_y[u] = df_ini$col2[i]
  #     }
  #   }
  # }
  
  # Section 5.2.(*) ----
  completed_pass <- function (df_i, df_e) {
    for (i in (1:nrow(df_i))) {
      for (u in (1:nrow(df_e))) {
        if (df_i$`df_pass$id`[i] %in% df_e$related_event_1[u] || df_i$`df_pass$id`[i] %in% df_e$related_event_2[u]) {
          df_e$ini_x[u] = df_i$col1[i]
          df_e$ini_y[u] = df_i$col2[i]
          df_e$duration[u] = df_i$`df$duration`[i]
        }
      }
    }
    return(df_e)
  }
  df_end_A = completed_pass(df_ini_A,df_end_A)
  
  # Section 5.3 Renaming ----
  # colnames(df_end)[2] <- "end_x"
  # colnames(df_end)[3] <- "end_y"
  # colnames(df_end)[4] <- "event_id"
  # 
  # Section 5.3.(*) ----
  rename_end <- function(df_end){
    colnames(df_end)[2] <- "end_x"
    colnames(df_end)[3] <- "end_y"
    colnames(df_end)[4] <- "event_id"
    df_end <- df_end[,-9]
    df_end$end_x <- as.numeric(df_end$end_x)
    df_end$end_y <- as.numeric(df_end$end_y)
    return(df_end)
  }
  df_end_A <- rename_end(df_end_A)
  
  
  # Leading / lagging - Estab Attack (logistic?) (team-based)
  # Score -> column + ratio of pass -> column => different score means different observation
  # Clustering Specific Score - Estab Attack (team-based) (Graphical representation)
  # 
  
  # Section 5.4.(*) compute the distance of passing ----
  distance <- function(df) {
    df$diff_x = abs(df$ini_x - df$end_x)
    df$diff_y = abs(df$ini_y - df$end_y)
    return(df)
  }
  df_end_A = distance(df_end_A)
  return (df_end_A)
}
A <- data_treatment(df,"{'id': 217, 'name': 'Barcelona'}") # passes completed for team Barcelona
B <- data_treatment(df, "{'id': 209, 'name': 'Celta Vigo'}") # passes completed for team Celta
A$index = 1:nrow(A)
B$index = 1:nrow(B)
# 1 output: ratio A_cross_ratio; A_through_pass_ratio; B_cross_ratio; B_through_pass_ratio (Variable) ----
A_pass_total <- df %>%
  filter(type %in% "{'id': 30, 'name': 'Pass'}") %>%
  filter(possession_team %in% "{'id': 217, 'name': 'Barcelona'}")
B_pass_total <- df %>%
  filter(type %in% "{'id': 30, 'name': 'Pass'}") %>%
  filter(possession_team %in% "{'id': 209, 'name': 'Celta Vigo'}")
plot_arrow_pass = function(df) {
  ggplot(df) +
    xlim(0, 120) + ylim(0, 80) +
    xlab("X-axis") + ylab("Y-axis") +
    theme_bw() +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank()) +
    geom_segment(aes(x = ini_x, y = ini_y,
                     xend = end_x, yend = end_y),
                 arrow = arrow(length = unit(0.2, "cm")), color = "red", linewidth = 0.6) +
    theme_minimal()
}

A_cross <- A %>%
  filter (ini_x > 70 & end_y > 18 & end_y < 62 & end_x > 95 & diff_y > 10 & (ini_y < 18 | ini_y > 62))
plot_arrow_pass(A_cross)
A_through_pass <- A %>%
  filter(end_x - ini_x > 10 & ini_x > 80 & ini_y > 18 & ini_y < 62 & end_y > 18 & end_y < 62)
plot_arrow_pass(A_through_pass)
B_cross <- B %>%
  filter(diff_x < 20 & ini_x > 70 & end_y > 18 & end_y < 62 & end_x > 102 & diff_y > 15 & (ini_y < 18 | ini_y > 62))
plot_arrow_pass(B_cross)
B_through_pass <- B %>%
  filter(end_x - ini_x > 10 & ini_x > 80 & ini_y > 18 & ini_y < 62 & end_y > 18 & end_y < 62)
plot_arrow_pass(B_through_pass)
A_cross_ratio = nrow(A_cross)/nrow(A)
A_through_pass_ratio = nrow(A_through_pass)/nrow(A)
B_cross_ratio = nrow(B_cross)/nrow(B)
B_through_pass_ratio = nrow(B_through_pass)/nrow(B)

plot_pass_analysis = function(df,compared) {
  ggplot(df) +
    xlab("X-axis") + ylab("Y-axis") +
    theme_bw() +
    geom_point(data = df, aes(x = end_x, y = diff_y), size = 1, color = 'black') + 
    geom_point(data = compared, aes(x = end_x, y = diff_y), size = 3, color = 'red') +
    theme_minimal()
}
plot_pass_analysis(A, A_cross)

# 2 output: A_xG B_xG (Dataframe) (elaborate/not) ----
A_shot <- df %>%
  filter(type %in% "{'id': 16, 'name': 'Shot'}") %>%
  filter(possession_team %in% "{'id': 217, 'name': 'Barcelona'}")
A_shot_xG <- data.frame(a=rep(1, nrow(A_shot)))
A_shot_xG$xG <- A_shot$shot
A_shot_xG$location <- A_shot$location
B_shot <- df %>%
  filter(type %in% "{'id': 16, 'name': 'Shot'}") %>%
  filter(possession_team %in% "{'id': 209, 'name': 'Celta Vigo'}")
B_shot_xG <- data.frame(a=rep(1, nrow(B_shot)))
B_shot_xG$xG <- B_shot$shot
B_shot_xG$location <- B_shot$location




A_xG <- data.frame(xG = c(A_shot_xG$xG))
A_xG$location <- A_shot$location
A_xG$xG <- gsub("True", "true", A_xG$xG)
A_xG$xG <- gsub("False", "false", A_xG$xG)
A_xG$xG <- gsub("'", '"', A_xG$xG)
A_xG <- A_xG %>%
  group_by(xG) %>%
  mutate(statsbomb_xg = fromJSON(xG)$statsbomb_xg,
         outcome_id = fromJSON(xG)$outcome$id,
         outcome_name = fromJSON(xG)$outcome$name)
for (n in (1:nrow(A_xG))) {
  name = fromJSON(A_xG$xG[n])
  if ("key_pass_id" %in% names(name)) {
    A_xG$key_pass_id[n] = name$key_pass_id
  } else {
    A_xG$key_pass_id[n] = ''
  }
}
B_xG <- data.frame(xG = c(B_shot_xG$xG))
B_xG$location <- B_shot$location
B_xG$xG <- gsub("True", "true", B_xG$xG)
B_xG$xG <- gsub("False", "false", B_xG$xG)
B_xG$xG <- gsub("'", '"', B_xG$xG)
B_xG <- B_xG %>%
  group_by(xG) %>%
  mutate(statsbomb_xg = fromJSON(xG)$statsbomb_xg,
         outcome_id = fromJSON(xG)$outcome$id,
         outcome_name = fromJSON(xG)$outcome$name)
for (n in (1:nrow(B_xG))) {
  name = fromJSON(B_xG$xG[n])
  if ("key_pass_id" %in% names(name)) {
    B_xG$key_pass_id[n] = name$key_pass_id
  } else {
    B_xG$key_pass_id[n] = ''
  }
}
# Exploration
A_key_pass_index = c()
for (n in (1:nrow(A_xG))) {
  row_num = which(A$related_event_1 == A_xG$key_pass_id[n])
  as.numeric(row_num)
  if (length(row_num) == 0) {
    row_num = which(A$related_event_2 == A_xG$key_pass_id[n])
  }
  if (length(row_num) > 1) {
    row_num = 0
  }
  A_key_pass_index <- c(A_key_pass_index, row_num)
}
# plot_5_before_shot = function(df,shot) {
#   ggplot(df) +
#     xlim(0, 120) + ylim(0, 80) +
#     xlab("X-axis") + ylab("Y-axis") +
#     theme_bw() +
#     theme(panel.grid.major = element_blank(),
#           panel.grid.minor = element_blank()) +
#     geom_point(data = shot, aes(x = shot_x, y = shot_y), size = 4, color = 'black') + 
#     geom_segment(data = df, aes(x = ini_x, y = ini_y,
#                      xend = end_x, yend = end_y),
#                  arrow = arrow(length = unit(0.6, "cm")), color = "red", linewidth = 2) +
#     geom_point(data = shot, aes(x = shot_x, y = shot_y), size = 10, color = 'blue') +
#     geom_text(data = df, aes(x = ini_x, y = ini_y, label = index), size = 8, color = 'black') +
#     geom_text(data = shot, aes(x = shot_x, y = shot_y+3.5, label = statsbomb_xg), size = 10, color = 'blue') +
#     theme_minimal()
# }
# 
# plot_A_5_before_shot_general <- function(i) {
#   plot_5_before_shot(A[((A_key_pass_index[i]-3):A_key_pass_index[i]),], A_xG[i,])
# }
# plot_A_5_before_shot_general(2)

# 
# for (n in (1:nrow(B_xG))) {
#   if (B_xG$xG[n] %in% B_through_pass$`df_pass$id` || B_xG$xG[n] %in% B_through_pass$related_event_1 || B_xG$xG[n] %in% B_through_pass$related_event_2) {
#     B_xG$key_pass_type[n] = 'through_pass'
#   } else if (B_xG$xG[n] %in% B_cross$`df_pass$id` || B_xG$xG[n] %in% B_cross$related_event_1 || B_xG$xG[n] %in% B_cross$related_event_2) {
#     B_xG$key_pass_type[n] = 'cross'
#   } else {
#     B_xG$key_pass_type[n] = ''
#   }
# }


B_xG$elaborate_ornot <- c(NA)
A_xG = data.frame(A_xG)
B_xG = data.frame(B_xG)
# define a function to extract the desired information from each JSON string
extract_players <- function(df) {
  for (i in (1:nrow(df))) {
  json_str <- df$xG[i]
  data <- fromJSON(json_str)$freeze_frame
  x = data.frame(data)
  c = 0
   for (u in (1:nrow(x))) {
     if (x[[u,4]] == FALSE) {
       if (x[[u,1]][[2]]>18 & x[[u,1]][[2]] < 62 & x[[u,1]][[1]]>102)
       c = c + 1
     }
   }
  print(i)
  print(c)
  if (c>=6) {
    df[i,6] = 1
  } else {
    df[i,6] = 0
  }
  }
  return(df)
}
A_xG = extract_players(A_xG)
B_xG = extract_players(B_xG)


A_xG$location <- gsub("\\[|\\]", "", A_xG$location)
values <- strsplit(A_xG$location, ", ")
A_xG$shot_x <- as.numeric(sapply(values, "[[", 1))
A_xG$shot_y <- as.numeric(sapply(values, "[[", 2))

testfunction <- function(df, index) {
  json_str <- df$xG[index]
  data <- fromJSON(json_str)$freeze_frame
  X <- tibble(data)
  X_defend <- X %>%
    mutate(
      X = sapply(location, function(coord) coord[1]),
      Y = sapply(location, function(coord) coord[2])
    ) %>%
    filter(teammate == FALSE)
  X_attack <- X %>%
    mutate(
      X = sapply(location, function(coord) coord[1]),
      Y = sapply(location, function(coord) coord[2])
    ) %>%
    filter(teammate == TRUE)
  plot <- ggplot() +
    geom_point(data = X_defend, aes(x = X, y = Y), size = 2, color = 'black') +
    geom_point(data = X_attack, aes(x = X, y = Y), size = 2, color = 'red') +
    geom_point(data = A_xG[index,], aes(x = shot_x, y = shot_y), size = 4, color = 'blue') +
    xlim(0, 120) + ylim(0, 80) +
    theme_minimal() +
    labs(title = "Player distribution at the instant of shooting",
         x = "X Coordinate",
         y = "Y Coordinate")
  plot
}
testfunction(A_xG, 11)

# Determine if this is elaborate attack or counter attack
classification <- function(df) {
  for (u in (1:nrow(df))) {
  c = 0
    for(i in (1:22)) {
      if (!is.na(df[u,6 + 3 * i]) & df[u,6+3*i] == TRUE) {
        c = c + 1
      }
    }
  print(c)
  if (c<5) {
    df[u,6] = 0
  } else {
    df[u,6] = 1
  }
  }
  return(df)
}

x = classification(A_xG)
y = classification(B_xG)



# 3 team_data_analysis -----

# Arsenal_analysis <- team_analysis("Arsenal")
# AstonVilla_analysis <- team_analysis("AstonVilla")
# Bournemouth_analysis <- team_analysis("Bournemouth")
# Brentford_analysis <- team_analysis("Brentford")
# Brighton_analysis <- team_analysis("Brighton")
# Chelsea_analysis <- team_analysis("Chelsea")
# Everton_analysis <- team_analysis("Everton")
# Fulham_analysis <- team_analysis("Fulham")
# LeedsUnited_analysis <- team_analysis("LeedsUnited")
# LeicesterCity_analysis <- team_analysis("LeicesterCity")
# Liverpool_analysis <- team_analysis("Liverpool")
# ManchesterCity_analysis <- team_analysis("ManchesterCity")
# ManchesterUnited_analysis <- team_analysis("ManchesterUnited")
# NewcastleUnited_analysis <- team_analysis("NewcastleUnited")
# NottinghamForest_analysis <- team_analysis("NottinghamForest")
# Southampton_analysis <- team_analysis("Southampton")
# TottenhamHotspur_analysis <- team_analysis("TottenhamHotspur")
# WestHamUnited_analysis <- team_analysis("WestHamUnited")
# Wolverhampton_analysis <- team_analysis("Wolverhampton")

team_analysis <- function (teamname) {
  Team <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", teamname))
  Team_Pass_Type <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Pass_Type")))
  Team_Passing <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Passing")))
  Team_Possession <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Possession")))
  Team_analysis <- data.frame(Team[,1])
  for (i in (5:9)) {
    Team_analysis <- cbind(Team_analysis, Team[,i])
  }
  names(Team_analysis)[1] <- c("Date")
  names(Team_analysis)[2:6] <- c("Venue","Result","GF","GA","Opponent")
  for (n in (1:nrow(Team_analysis))) {
    if (Team_analysis$Result[n] == 'W') {
      Team_analysis$Result[n] = 3
    } else if (Team_analysis$Result[n] == 'D') {
      Team_analysis$Result[n] = 1
    } else {
      Team_analysis$Result[n] = 0
    }
  }
  Team_analysis$Result <- as.numeric(Team_analysis$Result)
  Team_analysis <- cbind(Team_analysis, Team$Crs)
  Team_analysis <- cbind(Team_analysis, Team_Pass_Type$Att)
  Team_analysis$`Team$Crs` = Team_analysis$`Team$Crs`/Team_analysis$`Team_Pass_Type$Att`
  Team_analysis <- cbind(Team_analysis, Team_Pass_Type$TB)
  Team_analysis$`Team_Pass_Type$TB` = Team_analysis$`Team_Pass_Type$TB`/Team_analysis$`Team_Pass_Type$Att`
  Team_analysis$Date <- as.Date(Team_analysis$Date)
  Team_analysis$Touches <- Team_Possession$Touches
  Team_analysis$Att.3rd <- Team_Possession$Att.3rd/Team_analysis$Touches
  Team_analysis$Mid.3rd <- Team_Possession$Mid.3rd/Team_analysis$Touches
  Team_analysis$Def.3rd <- Team_Possession$Def.3rd/Team_analysis$Touches
  Team_analysis$PrgC.R <- Team_Possession$PrgC/Team_Possession$Carries
  Team_analysis$PrgP.R <- Team_Passing$PrgP/Team_Passing$Att
  Team_analysis$Possession.R <- Team_Possession$Poss
  Team_analysis$P3rd <- Team_Passing$X1.3/Team_Passing$Att
  Team_analysis$PPA.R <- Team_Passing$PPA/Team_Passing$Att
  Team_analysis$Cross.R <- Team_Pass_Type$Crs/Team_Passing$Att
  Team_analysis$TB.R <- Team_Pass_Type$TB/Team_Passing$Att
  Team_analysis$Takeon <- Team_Possession$Att
  return(Team_analysis)
}
ManchesterCity_analysis <- team_analysis("ManchesterCity")
teamnames <- c("Arsenal", "AstonVilla", "Bournemouth", "Brentford", "Brighton", "Chelsea", "CrystalPalace", "Everton", "Fulham", "LeedsUnited", "LeicesterCity", "Liverpool",  "ManchesterCity", "ManchesterUnited", "NewcastleUnited", "NottinghamForest", "Southampton", "TottenhamHotspur", "WestHamUnited", "Wolverhampton")



# Create a list of team analysis data frames
team_analysis_list <- lapply(teamnames, function(team) {
  team_analysis(team)
})

mean_df <- lapply(team_analysis_list, function(df) {
  a = c(mean(df[[7]]), mean(df[[8]]), mean(df[[9]]), mean(df[[10]]), mean(df[[11]]), mean(df[[12]]), mean(df[[13]]), mean(df[[14]]), mean(df[[15]]), mean(df[[16]]), mean(df[[17]]), mean(df[[18]]), mean(df[[21]]), sum(df[[3]]))
})

# Data clean & PCA
varname = c(names(ManchesterCity_analysis[,7:18]), "Take-on", "Result")
varname[1] <- "Cross"
varname[2] <- "Total_Passes"
varname[3] <- "Through_Ball"
varname[4] <- "Total_Touches"
varname[5] <- "Touches_in_attacking_region"
varname[6] <- "Touches_in_midfield_region"
varname[7] <- "Touches_in_defending_region"
varname[8] <- "Progressive_Carry"
varname[9] <- "Progressive_Pass"
varname[10] <- "Possession_Rate"
varname[11] <- "Passes_to_attacking_region"
varname[12] <- "Passes_to_penalty_area"
mean_df <- as.data.frame(mean_df)
names(mean_df) <- teamnames 
mean_df = t(mean_df)
classification_df <- data.frame(mean_df)
names(classification_df) <- varname
results <- prcomp(classification_df[, c(1,3:13)], scale = TRUE)
results
biplot(results, scale = 0)

# correlation matrix
classification.norm <- data.frame(scale(classification_df))
distance <- get_dist(classification.norm)
fviz_dist(distance, gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"))
set.seed(123)

# # Hierarchical
# clusters <- hclust(dist(classification_df),method = 'average')
# plot(clusters)
# clusterCut <- cutree(clusters, 3)
# table(clusterCut, classification_df$Possession.R)

# k-means
fviz_nbclust(classification.norm, kmeans, method = "wss")
classification.k2 <- kmeans(classification.norm, centers = 2,  nstart = 25)
classification.k3 <- kmeans(classification.norm, centers = 3,  nstart = 25)
classification.k4 <- kmeans(classification.norm, centers = 4,  nstart = 25)
classification.k5 <- kmeans(classification.norm, centers = 5,  nstart = 25)
p1 <- fviz_cluster(classification.k2, geom = "point", data = classification.norm) + ggtitle("k = 2")
p2 <- fviz_cluster(classification.k3, geom = "point", data = classification.norm) + ggtitle("k = 3")
p3 <- fviz_cluster(classification.k4, geom = "point", data = classification.norm) + ggtitle("k = 4")
p4 <- fviz_cluster(classification.k5, geom = "point", data = classification.norm) + ggtitle("k = 5")
grid.arrange(p1, p2, p3, p4, nrow = 2) # How to see which team is in which category

model <- svm(classification_df$Att.3rd, classification_df$Cross.R, type = "C-classification", kernel = "linear", cost = 0.1) # This is not working at all

# Regression & else
ggplot(classification_df, aes(x = Att.3rd, y = Cross.R, label = Teamname)) + 
  geom_point() + 
  geom_text(size = 3, vjust = -1)

team_classified <- classification.k2$cluster
att_team <- team_classified == 1

model1 <- lm(data = classification_df, TB.R ~ Possession.R)
summary(model1)
ggplot(classification_df, aes(x = TB.R, y = Possession.R, label = Teamname)) +
  geom_point(size = 2, color = 'red') +
  geom_text(hjust = 1.2) +
  labs(title = "TB-Possession",
       x = "TB.R",
       y = "Possession.R")
plot

# Radar graph
attacking_team <- classification_df[att_team, ]
att <- teamnames[att_team]
selected <- c(3,5,6,8:13)
attacking_team_featured <- attacking_team[,selected]
results <- prcomp(attacking_team_featured, scale = TRUE)
biplot(results, scale = 0)

M = c(max(attacking_team_featured[1]))
for (i in (2:9)) {
  M = c(M, max(attacking_team_featured[i]))
}

m = c(min(attacking_team_featured[1]))
for (i in (2:9)) {
  m = c(m, min(attacking_team_featured[i]))
}
attacking_team_featured <- rbind(m, attacking_team_featured)
attacking_team_featured <- rbind(M, attacking_team_featured)
radar1=radarchart(attacking_team_featured[c(1,2,3),], pcol = 'black', pfcol = scales::alpha('red', 0.5), plwd = 2, plty = 1,title=att[1])
radar2=radarchart(attacking_team_featured[c(1,2,4),], pcol = 'black', pfcol = scales::alpha('blue', 0.5), plwd = 2, plty = 1,title=att[2])
radar3=radarchart(attacking_team_featured[c(1,2,5),], pcol = 'black', pfcol = scales::alpha('blue3', 0.5), plwd = 2, plty = 1,title=att[3])
radar4=radarchart(attacking_team_featured[c(1,2,6),], pcol = 'black', pfcol = scales::alpha('red', 0.5), plwd = 2, plty = 1,title=att[4])
radar5=radarchart(attacking_team_featured[c(1,2,7),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=att[5])
radar6=radarchart(attacking_team_featured[c(1,2,8),], pcol = 'black', pfcol = scales::alpha('red', 0.5), plwd = 2, plty = 1,title=att[6])
radar7=radarchart(attacking_team_featured[c(1,2,9),], pcol = 'black', pfcol = scales::alpha('black', 0.5), plwd = 2, plty = 1,title=att[7])
radar8=radarchart(attacking_team_featured[c(1,2,10),], pcol = 'black', pfcol = scales::alpha('', 0.5), plwd = 2, plty = 1,title="NewcastleUnited")

grid.arrange(radar1,radar3,radar6,radar7, nrow = 2)

color <- c('red','blue','blue3','snow','red','lightskyblue','red','black')















plot <- ggplot() +
  geom_point(data = Arsenal_analysis, aes(Date, Mid.3rd), size = 2, color = 'red') +
  geom_point(data = Brentford_analysis, aes(Date, Mid.3rd), size = 2, color = 'green') +
  geom_point(data = ManchesterCity_analysis, aes(Date, Mid.3rd), size = 2, color = 'blue') +
  labs(title = "touches",
       x = "X Coordinate",
       y = "Y Coordinate")
plot

# Distribution of touches reflects the team's emphasis on different spot
results <- prcomp(ManchesterCity_analysis[,7:13], scale = TRUE)
results








Barcelona <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Barcelona")
Barcelona_Pass_Type <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Barcelona_Pass_Type")
Barcelona_Passing <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Barcelona_Passing")
Barcelona_Possession <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Barcelona_Possession")
ManchesterCity <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/ManchesterCity")
ManchesterCity_Pass_Type <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/ManchesterCity_Pass_Type")
ManchesterCity_Passing <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/ManchesterCity_Passing")
ManchesterCity_Possession <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/ManchesterCity_Possession")
Arsenal <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Arsenal")
Arsenal_Pass_Type <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Arsenal_Pass_Type")
Arsenal_Passing <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Arsenal_Passing")
Arsenal_Possession <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Arsenal_Possession")
Brentford <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Brentford")
Brentford_Pass_Type <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Brentford_Pass_Type")
Brentford_Passing <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Brentford_Passing")
Brentford_Possession <- read.csv("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/Brentford_Possession")
# 4 player_data_analysis ----
team_analysis2 <- function (teamname) {
  Team <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", teamname))
  Team_Pass_Type <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Pass_Type")))
  Team_Passing <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Passing")))
  Team_Possession <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Possession")))
  Team_analysis <- data.frame(Team[,1])
  for (i in (5:9)) {
    Team_analysis <- cbind(Team_analysis, Team[,i])
  }
  names(Team_analysis)[1] <- c("Date")
  names(Team_analysis)[2:6] <- c("Venue","Result","GF","GA","Opponent")
  for (n in (1:nrow(Team_analysis))) {
    if (Team_analysis$Result[n] == 'W') {
      Team_analysis$Result[n] = 3
    } else if (Team_analysis$Result[n] == 'D') {
      Team_analysis$Result[n] = 1
    } else {
      Team_analysis$Result[n] = 0
    }
  }
  Team_analysis$Result <- as.numeric(Team_analysis$Result)
  Team_analysis <- cbind(Team_analysis, Team_Pass_Type$TB)
  Team_analysis$Att.3rd <- Team_Possession$Att.3rd
  Team_analysis$Mid.3rd <- Team_Possession$Mid.3rd
  Team_analysis$PrgC <- Team_Possession$PrgC
  Team_analysis$PrgP <- Team_Passing$PrgP
  Team_analysis$P3rd <- Team_Passing$X1.3
  Team_analysis$PPA.R <- Team_Passing$PPA
  Team_analysis$Takeon <- Team_Possession$Att
  return(Team_analysis)
}
ManchesterCity_analysis_2 <- team_analysis2("ManchesterCity")
player_analysis <- function (player) {
  Player <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", player))
  Player_Pass_Type <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", paste0(player, "_Pass_Type")))
  Player_Passing <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", paste0(player, "_Passing")))
  Player_Possession <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", paste0(player, "_Possession")))
  Player_analysis <- data.frame(Player[,1])
  Player_analysis <- cbind(Player_analysis, Player[,5])
  Player_analysis <- cbind(Player_analysis, Player[,10])
  names(Player_analysis)[1] <- c("Date")
  names(Player_analysis)[2:3] <- c("Result","Onpitchtime")
  for (n in (1:nrow(Player_analysis))) {
    if (Player_analysis$Result[n] == 'W') {
      Player_analysis$Result[n] = 3
    } else if (Player_analysis$Result[n] == 'D') {
      Player_analysis$Result[n] = 1
    } else {
      Player_analysis$Result[n] = 0
    }
  }
  Player_analysis$Result <- as.numeric(Player_analysis$Result)
  Player_analysis <- cbind(Player_analysis, Player_Pass_Type$Att)
  Player_analysis <- cbind(Player_analysis, Player_Pass_Type$TB)
  Player_analysis$`Player_Pass_Type$TB` = Player_analysis$`Player_Pass_Type$TB`/Player_Possession$Min
  Player_analysis$Date <- as.Date(Player_analysis$Date)
  Player_analysis$Touches <- Player_Possession$Touches
  Player_analysis$Att.3rd <- Player_Possession$Att.3rd/Player_Possession$Min
  Player_analysis$Mid.3rd <- Player_Possession$Mid.3rd/Player_Possession$Min
  Player_analysis$Def.3rd <- Player_Possession$Def.3rd/Player_Possession$Min
  Player_analysis$PrgC.R <- Player_Possession$PrgC/Player_Possession$Min
  Player_analysis$PrgP.R <- Player_Passing$PrgP/Player_Possession$Min
  Player_analysis$P3rd <- Player_Passing$X1.3/Player_Possession$Min
  Player_analysis$PPA.R <- Player_Passing$PPA/Player_Possession$Min
  Player_analysis$Takeon <- Player_Possession$Att/Player_Possession$Min
  return(Player_analysis)
}
player_analysis_2 <- function (player) {
  Player <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", player))
  Player_Pass_Type <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", paste0(player, "_Pass_Type")))
  Player_Passing <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", paste0(player, "_Passing")))
  Player_Possession <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/ManchesterCity/", paste0(player, "_Possession")))
  Player_analysis <- data.frame(Player[,1])
  Player_analysis <- cbind(Player_analysis, Player[,5])
  Player_analysis <- cbind(Player_analysis, Player[,10])
  names(Player_analysis)[1] <- c("Date")
  names(Player_analysis)[2:3] <- c("Result","Onpitchtime")
  for (n in (1:nrow(Player_analysis))) {
    if (Player_analysis$Result[n] == 'W') {
      Player_analysis$Result[n] = 3
    } else if (Player_analysis$Result[n] == 'D') {
      Player_analysis$Result[n] = 1
    } else {
      Player_analysis$Result[n] = 0
    }
  }
  Player_analysis$Result <- as.numeric(Player_analysis$Result)
  Player_analysis <- cbind(Player_analysis, Player_Pass_Type$Att)
  Player_analysis <- cbind(Player_analysis, Player_Pass_Type$TB)
  Player_analysis$`Player_Pass_Type$TB` = Player_analysis$`Player_Pass_Type$TB`
  Player_analysis$Date <- as.Date(Player_analysis$Date)
  Player_analysis$Touches <- Player_Possession$Touches
  Player_analysis$Att.3rd <- Player_Possession$Att.3rd
  Player_analysis$Mid.3rd <- Player_Possession$Mid.3rd
  Player_analysis$Def.3rd <- Player_Possession$Def.3rd
  Player_analysis$PrgC <- Player_Possession$PrgC
  Player_analysis$PrgP <- Player_Passing$PrgP
  Player_analysis$P3rd <- Player_Passing$X1.3
  Player_analysis$PPA <- Player_Passing$PPA
  Player_analysis$Takeon <- Player_Possession$Att
  return(Player_analysis)
}
playernames <- c("BernardoSilva", "IlkayGundogan", "JackGrealish", "JulianAlvarez", "KevinDeBruyne", "NathanAke", "Rodri", "Stones", "PhilFoden")
BernardoSilva_analysis <- player_analysis(playernames[1])
debugggg <- player_analysis(playernames[10])


# Create a list of team analysis data frames
player_analysis_list_2 <- lapply(playernames, function(player) {
  player_analysis_2(player)
})

player_mean_df <- lapply(team_analysis_list, function(df) {
  a = c(mean(df[[5]]),mean(df[[7]]), mean(df[[8]]), mean(df[[10]]), mean(df[[11]]), mean(df[[12]]), mean(df[[13]]), mean(df[[14]]))
})


player_mean_df <- as.data.frame(player_mean_df)
names(player_mean_df) <- playernames 
player_mean_df = t(player_mean_df)
player_df <- data.frame(player_mean_df)
varname2 <- c("Through_Ball", "Touches_in_attacking_region", "Touches_in_midfield_region", "Progressive_Carry", "Progressive_Pass","Passes_to_attacking_area","Passes_to_penalty_area","Take_on")
names(player_df) <- varname2

M_p = c(max(player_df[1]))
for (i in (2:8)) {
  M_p = c(M_p, max(player_df[i]))
}

m_p = c(min(player_df[1]))
for (i in (2:9)) {
  m_p = c(m_p, min(player_df[i]))
}
player_df <- rbind(m_p, player_df)
player_df <- rbind(M_p, player_df)
radar1=radarchart(player_df[c(1,2,3),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[1])
radar2=radarchart(player_df[c(1,2,4),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[2])
radar3=radarchart(player_df[c(1,2,5),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[3])
radar4=radarchart(player_df[c(1,2,6),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[4])
radar5=radarchart(player_df[c(1,2,7),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[5])
radar6=radarchart(player_df[c(1,2,8),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[6])
radar7=radarchart(player_df[c(1,2,9),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[7])
radar8=radarchart(player_df[c(1,2,10),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[8])
radar9=radarchart(player_df[c(1,2,10),], pcol = 'black', pfcol = scales::alpha('lightskyblue1', 0.5), plwd = 2, plty = 1,title=playernames[9])


# Team specific analysis ----
Team_across_seazon <- function (teamname) {
  Team <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", teamname))
  Team_Pass_Type <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Pass_Type")))
  Team_Passing <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Passing")))
  Team_Possession <- read.csv(paste0("~/Desktop/2023-Spring/QAC-211/Project/Data/Teams/", paste0(teamname, "_Possession")))
  Team_analysis <- data.frame(Team[,1])
  for (i in (5:9)) {
    Team_analysis <- cbind(Team_analysis, Team[,i])
  }
  names(Team_analysis)[1] <- c("Date")
  names(Team_analysis)[2:6] <- c("Venue","Result","GF","GA","Opponent")
  for (n in (1:nrow(Team_analysis))) {
    if (Team_analysis$Result[n] == 'W') {
      Team_analysis$Result[n] = 3
    } else if (Team_analysis$Result[n] == 'D') {
      Team_analysis$Result[n] = 1
    } else {
      Team_analysis$Result[n] = 0
    }
  }
  Team_analysis$Result <- as.numeric(Team_analysis$Result)
  Team_analysis <- cbind(Team_analysis, Team$Crs)
  Team_analysis <- cbind(Team_analysis, Team_Pass_Type$Att)
  Team_analysis$`Team$Crs` = Team_analysis$`Team$Crs`/Team_analysis$`Team_Pass_Type$Att`
  Team_analysis <- cbind(Team_analysis, Team_Pass_Type$TB)
  Team_analysis$`Team_Pass_Type$TB` = Team_analysis$`Team_Pass_Type$TB`/Team_analysis$`Team_Pass_Type$Att`
  Team_analysis$Date <- as.Date(Team_analysis$Date)
  Team_analysis$Touches <- Team_Possession$Touches
  Team_analysis$Att.3rd <- Team_Possession$Att.3rd/Team_analysis$Touches
  Team_analysis$Mid.3rd <- Team_Possession$Mid.3rd/Team_analysis$Touches
  Team_analysis$Def.3rd <- Team_Possession$Def.3rd/Team_analysis$Touches
  Team_analysis$PrgC.R <- Team_Possession$PrgC/Team_Possession$Carries
  Team_analysis$PrgP.R <- Team_Passing$PrgP/Team_Passing$Att
  Team_analysis$Possession.R <- Team_Possession$Poss
  Team_analysis$P3rd <- Team_Passing$X1.3/Team_Passing$Att
  Team_analysis$PPA.R <- Team_Passing$PPA/Team_Passing$Att
  Team_analysis$Cross.R <- Team_Pass_Type$Crs/Team_Passing$Att
  Team_analysis$TB.R <- Team_Pass_Type$TB/Team_Passing$Att
  Team_analysis$Takeon <- Team_Possession$Att
  return(Team_analysis)
}
# other ----

ManchesterCity_analysis <- data.frame(ManchesterCity[,1])
for (i in (5:9)) {
  ManchesterCity_analysis <- cbind(ManchesterCity_analysis, ManchesterCity[,i])
}
names(ManchesterCity_analysis)[1] <- c("Date")
names(ManchesterCity_analysis)[2:6] <- c("Venue","Result","GF","GA","Opponent")
ManchesterCity_analysis <- cbind(ManchesterCity_analysis, ManchesterCity$Crs)
ManchesterCity_analysis <- cbind(ManchesterCity_analysis, ManchesterCity_Pass_Type$Att)
ManchesterCity_analysis$`ManchesterCity$Crs` = ManchesterCity_analysis$`ManchesterCity$Crs`/ManchesterCity_analysis$`ManchesterCity_Pass_Type$Att`
ManchesterCity_analysis <- cbind(ManchesterCity_analysis, ManchesterCity_Pass_Type$TB)
ManchesterCity_analysis$`ManchesterCity_Pass_Type$TB` = ManchesterCity_analysis$`ManchesterCity_Pass_Type$TB`/ManchesterCity_analysis$`ManchesterCity_Pass_Type$Att`
ManchesterCity_analysis$Date <- as.Date(ManchesterCity_analysis$Date)
plot <- ggplot() +
  geom_point(data = ManchesterCity_analysis, aes(Date, `ManchesterCity$Crs`), size = 2, color = 'red') +
  geom_point(data = ManchesterCity_analysis, aes(Date, `ManchesterCity_Pass_Type$TB`), size = 2, color = 'green') +
  labs(title = "Ratio change",
       x = "X Coordinate",
       y = "Y Coordinate")
plot

Brentford_analysis <- data.frame(Brentford[,1])
for (i in (5:9)) {
  Brentford_analysis <- cbind(Brentford_analysis, Brentford[,i])
}
names(Brentford_analysis)[1] <- c("Date")
names(Brentford_analysis)[2:6] <- c("Venue","Result","GF","GA","Opponent")
Brentford_analysis <- cbind(Brentford_analysis, Brentford$Crs)
Brentford_analysis <- cbind(Brentford_analysis, Brentford_Pass_Type$Att)
Brentford_analysis$`Brentford$Crs` = Brentford_analysis$`Brentford$Crs`/Brentford_analysis$`Brentford_Pass_Type$Att`
Brentford_analysis <- cbind(Brentford_analysis, Brentford_Pass_Type$TB)
Brentford_analysis$`Brentford_Pass_Type$TB` = Brentford_analysis$`Brentford_Pass_Type$TB`/Brentford_analysis$`Brentford_Pass_Type$Att`
Brentford_analysis$Date <- as.Date(Brentford_analysis$Date)


Arsenal_analysis <- data.frame(Arsenal[,1])
for (i in (5:9)) {
  Arsenal_analysis <- cbind(Arsenal_analysis, Arsenal[,i])
}
names(Arsenal_analysis)[1] <- c("Date")
names(Arsenal_analysis)[2:6] <- c("Venue","Result","GF","GA","Opponent")
Arsenal_analysis <- cbind(Arsenal_analysis, Arsenal$Crs)
Arsenal_analysis <- cbind(Arsenal_analysis, Arsenal_Pass_Type$Att)
Arsenal_analysis$`Arsenal$Crs` = Arsenal_analysis$`Arsenal$Crs`/Arsenal_analysis$`Arsenal_Pass_Type$Att`
Arsenal_analysis <- cbind(Arsenal_analysis, Arsenal_Pass_Type$TB)
Arsenal_analysis$`Arsenal_Pass_Type$TB` = Arsenal_analysis$`Arsenal_Pass_Type$TB`/Arsenal_analysis$`Arsenal_Pass_Type$Att`
Arsenal_analysis$Date <- as.Date(Arsenal_analysis$Date)



plot_cross <- ggplot() +
  geom_point(data = Arsenal_analysis, aes(Date, `Arsenal$Crs`), size = 2, color = 'red') +
  geom_point(data = ManchesterCity_analysis, aes(Date, `ManchesterCity$Crs`), size = 2, color = 'blue') +
  geom_point(data = Brentford_analysis, aes(Date, `Brentford$Crs`), size = 2, color = 'green') +
  labs(title = "Ratio change",
       x = "X Coordinate",
       y = "Y Coordinate")
plot_cross

plot_TB <- ggplot() +
  geom_point(data = Arsenal_analysis, aes(Date, `Arsenal_Pass_Type$TB`), size = 2, color = 'red') +
  geom_point(data = ManchesterCity_analysis, aes(Date, `ManchesterCity_Pass_Type$TB`), size = 2, color = 'blue') +
  geom_point(data = Brentford_analysis, aes(Date, `Brentford_Pass_Type$TB`), size = 2, color = 'green') +
  labs(title = "Ratio change",
       x = "X Coordinate",
       y = "Y Coordinate")
plot_TB

# shot_pass_diff ----








# Section 1 Event id (input: df; output: readable event id) ------
  # Section 1.1 Pass ----
  indexing_pass_before_shot <- function (df) {
    df$passbinary = 0
    x = 0
    for (i in (1:nrow(df))) {
      if (df$type[i] == "{'id': 16, 'name': 'Shot'}") {
        for (u in (0:29)) {
          df$passbinary[i-u] = x
        }
        x=x+1
      }
    }
    return(df)
  }

  df_pass = df %>%
    filter (type %in% c("{'id': 30, 'name': 'Pass'}","{'id': 42, 'name': 'Ball Receipt*'}"))
  v1<-c("typeid","typename")
  v1 <- data.frame(do.call("rbind",strsplit(as.character(df_pass$type), ",", fixed = TRUE)))
  v2 <- data.frame(do.call("rbind",strsplit(as.character(v1$X1), " ", fixed = TRUE)))
  v3 <- data.frame(do.call("rbind",strsplit(as.character(v1$X2), " ", fixed = TRUE)))
  v4 <- data.frame(do.call("rbind",strsplit(as.character(v3$X3), "}", fixed = TRUE)))
  df_pass = cbind(df_pass, v2$X2, v4)
  
  # Section 1.2 Shot ----
  df_shot = df %>%
    filter (type %in% c("{'id': 16, 'name': 'Shot'}"))
  df_pass <- indexing_pass_before_shot(df_pass)  
  v1<-c("typeid","typename")
  v1 <- data.frame(do.call("rbind",strsplit(as.character(df_shot$type), ",", fixed = TRUE)))
  v2 <- data.frame(do.call("rbind",strsplit(as.character(v1$X1), " ", fixed = TRUE)))
  v3 <- data.frame(do.call("rbind",strsplit(as.character(v1$X2), " ", fixed = TRUE)))
  v4 <- data.frame(do.call("rbind",strsplit(as.character(v3$X3), "}", fixed = TRUE)))
  df_shot = cbind(df_shot, v2$X2, v4)
  
  
# Section 2 Location info (input df; output: df_distance_rawdata with coordinates) ----
  location <- function(df) {
    df_distance <- data.frame(location = df_pass$location)
    df_distance$location <- gsub("\\[|\\]", "", df_distance$location)
    values <- strsplit(df_distance$location, ", ")
    df_distance$col1 <- as.numeric(sapply(values, "[[", 1))
    df_distance$col2 <- as.numeric(sapply(values, "[[", 2))
    df_distance <- cbind(df_distance, df_pass$v2)
    df_distance <- cbind(df_distance, df_pass$id)
    df_distance <- cbind(df_distance, df_pass$related_events)
    df_distance <- cbind(df_distance, df_pass$timestamp)
    df_distance <- cbind(df_distance, df_pass$duration)
    df_distance <- cbind(df_distance, df_pass$period)
    df_distance <- cbind(df_distance, df_pass$passbinary)
    return(df_distance)
  }
  df_distance_rawdata <- location(df_pass)
# Section 3 Filtering the different teams ----
df_pass_A = df_distance_rawdata %>%
  filter(df_pass$possession_team %in% c("{'id': 217, 'name': 'Barcelona'}"))

# Section 4 Filtering the initiation of pass and the completion of pass ------
# df_ini = df_distance_rawdata %>% 
#   filter(df_pass$`v2$X2` %in% c(30))
# df_end = df_distance_rawdata %>%
#   filter(df_pass$`v2$X2` %in% c(42))
  # There is a difference between the row numebr of two different dataframes. So I'm thinking about filtering those initiation of passes failed.

# For this part of the code, if the initiation of pass has a related event which is in the df_end, we pick these out.
    # No this would be too much work

  # Section 4.(*) ----
  df_ini_A = df_pass_A %>% 
    filter(df_pass_A$`df_pass$v2` %in% c(30))
  df_end_A = df_pass_A %>%
    filter(df_pass_A$`df_pass$v2` %in% c(42))
  # There is a difference between the row numebr of two different dataframes. So I'm thinking about filtering those initiation of passes failed.
  
  # For this part of the code, if the initiation of pass has a related event which is in the df_end, we pick these out.
  # No this would be too much work


# Section 5 Filter the passes that are completed ------
  # Section 5.1 string of array -> 2 columns ----
  # df_end <- separate(df_end, col = `df$related_events`,into=c('related_event_1','related_event_2'),sep=", ")
  # df_end$related_event_1 <- gsub("\\[", "", df_end$related_event_1)
  # df_end$related_event_1 <- gsub("'", "", df_end$related_event_1)
  # df_end$related_event_1 <- gsub("\\]", "", df_end$related_event_1)
  # df_end$related_event_2 <- gsub("\\]", "", df_end$related_event_2)
  # df_end$related_event_2 <- gsub("'", "", df_end$related_event_2)
  
  # Section 5.1.(*) ----
  replace_na_with_empty_string <- function(x) {
    if (is.na(x)) {
      return("")
    } else {
      return(x)
    }
  }
  eventid_treatment <- function(df_x) {
    df_x <- separate(df_x, col=`df_pass$related_events`,into=c('related_event_1','related_event_2'),sep=", ")
    df_x$related_event_1 <- gsub("\\[", "", df_x$related_event_1)
    df_x$related_event_1 <- gsub("'", "", df_x$related_event_1)
    df_x$related_event_1 <- gsub("\\]", "", df_x$related_event_1)
    df_x$related_event_2 <- gsub("\\]", "", df_x$related_event_2)
    df_x$related_event_2 <- gsub("'", "", df_x$related_event_2)
    df_x <- as.data.frame(apply(df_x, 2, function(x) sapply(x, replace_na_with_empty_string)))
    return(df_x)
  }
  # trial code
  df_end_A = eventid_treatment(df_end_A)
  
  
  # Section 5.2 find the completed passes ----
  # df_end$ini_x <- c(NA)
  # df_end$ini_y <- c(NA)
  # for (i in (1:nrow(df_ini))) {
  #   for (u in (1:nrow(df_end))) {
  #     if (df_ini$`df_pass$id`[i] %in% df_end$related_event_1[u] || df_ini$`df_pass$id`[i] %in% df_end$related_event_2[u]) {
  #       df_end$ini_x[u] = df_ini$col1[i]
  #       df_end$ini_y[u] = df_ini$col2[i]
  #     }
  #   }
  # }
  
  # Section 5.2.(*) ----
  completed_pass <- function (df_i, df_e) {
    for (i in (1:nrow(df_i))) {
      for (u in (1:nrow(df_e))) {
        if (df_i$`df_pass$id`[i] %in% df_e$related_event_1[u] || df_i$`df_pass$id`[i] %in% df_e$related_event_2[u]) {
          df_e$ini_x[u] = df_i$col1[i]
          df_e$ini_y[u] = df_i$col2[i]
          df_e$duration[u] = df_i$`df$duration`[i]
        }
      }
    }
    return(df_e)
  }
  df_end_A = completed_pass(df_ini_A,df_end_A)
  
  # Section 5.3 Renaming ----
  # colnames(df_end)[2] <- "end_x"
  # colnames(df_end)[3] <- "end_y"
  # colnames(df_end)[4] <- "event_id"
  
  # Section 5.3.(*) ----
  rename_end <- function(df_end){
    colnames(df_end)[2] <- "end_x"
    colnames(df_end)[3] <- "end_y"
    colnames(df_end)[4] <- "event_id"
    df_end <- df_end[,-9]
    df_end$end_x <- as.numeric(df_end$end_x)
    df_end$end_y <- as.numeric(df_end$end_y)
    return(df_end)
  }
  df_end_A <- rename_end(df_end_A)
  
  
# Leading / lagging - Estab Attack (logistic?) (team-based)
  # Score -> column + ratio of pass -> column => different score means different observation
# Clustering Specific Score - Estab Attack (team-based) (Graphical representation)
# 
  
  # Section 5.4.(*) compute the distance of passing ----
  distance <- function(df) {
    df$diff_x = abs(df$ini_x - df$end_x)
    df$diff_y = abs(df$ini_y - df$end_y)
    return(df)
  }
  df_end_A = distance(df_end_A)
  # Section 5.5.(*) Indexing the passes ----
  indexing <- function(df) {
    for (i in (1:nrow(df))) {
      df$index[i] = i 
    }
    return(df)
  }
  df_end_A = indexing(df_end_A)
# Section 6 Clustering/categorizing -------
  # Section 6.0 Graphing function ------
  plot_arrow = function(df) {
    ggplot(df) +
      xlim(0, 120) + ylim(0, 80) +
      xlab("X-axis") + ylab("Y-axis") +
      theme_bw() +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank()) +
      geom_segment(aes(x = ini_x, y = ini_y,
                       xend = end_x, yend = end_y),
                   arrow = arrow(length = unit(0.2, "cm")), color = "red", linewidth = 0.6) +
      theme_minimal()
  }
  # Section 6.1 Pass categorization ---------
    # Section 6.0 ------
      # 5-passes before -----
        # data treatment ----
        
        # data treatment ----
        # v1<-c("typeid","typename")
        # v1 <- data.frame(do.call("rbind",strsplit(as.character(df$type), ",", fixed = TRUE)))
        # v2 <- data.frame(do.call("rbind",strsplit(as.character(v1$X1), " ", fixed = TRUE)))
        # v3 <- data.frame(do.call("rbind",strsplit(as.character(v1$X2), " ", fixed = TRUE)))
        # v4 <- data.frame(do.call("rbind",strsplit(as.character(v3$X3), "}", fixed = TRUE)))
        # df = cbind(df, v2$X2, v4)

        # df_1 <- location (df)
  
        # five_passes_before_shots <- function(df, shot_id, n, n_pass) {
        #   raw_before_events <- df[(shot_id - n):(shot_id - 1)]  
        #   df_shot = X3773457 %>%
        #     filter (type %in% c("{'id': 16, 'name': 'Shot'}"))
        #   related_pass_ini <- raw_before_events %>% 
        #     filter (v2)[raw_before_events$`v2$X2` == 30]
        #   related_pass_end <- raw_before_events[raw_before_events$`v2$X2` == 42]
        #   
        #   for (i in (1:(nrow(related_pass)))) {
        #     df_new$location[i] = related_pass$location[i]
        #   }
        #   
        #   
        # }
        # graph treatment ----
        # five_graph <- function(df) {
        #   ggplot(df) +
        #     xlim(0, 120) + ylim(0, 80) +
        #     xlab("X-axis") + ylab("Y-axis") +
        #     theme_bw() +
        #     theme(panel.grid.major = element_blank(),
        #           panel.grid.minor = element_blank()) + 
        #     geom_segment(aes(x = ini_x_5, y = ini_y_5,
        #                      xend = end_x_5, yend = end_y_5),
        #                  arrow = arrow(length = unit(0.2, "cm")), color = "red", linewidth = 0.6) +
        #     theme_minimal() + 
        #     facet_wrap(~ index_)
        }
      # 5-passes before shot -----
      # df_shot_A <- 
    # Section 6.1.1 thorough_pass trait ----
    # df_A_thorough_pass <- df_end_A %>% 
    #   filter(end_x - ini_x > 10 & ini_x > 80 & end_y > 18 & end_y<62)
    # plot_arrow(df_A_thorough_pass)
    # df_A_thorough_pass <- five_before(df_A_thorough_pass, df_end_A)
    # five_graph(df_A_thorough_pass)
    # Section 6.1.1
    # for (u in (1:5)) {
    #   df_A_thorough_pass$ini_x_`u` =  
    #   df_A_thorough_pass$ini_y_`u` = 
    #   df_A_thorough_pass$end_x_`u` = 
    #   df_A_thorough_pass$end_y_`u` = 
    # }
    # Section 6.1.2.1 cut_back_pass trait ----
    # df_A_cross <- df_end_A %>%
    #   filter(diff_x < 15 & ini_x > 70 & end_y > 18 & end_y < 62 & end_x > 102 & diff_y > 15 & (ini_y < 18 | ini_y > 62))
    # plot_arrow(df_A_cross)
    # df_A_cross <- five_before(df_A_cross, df_end_A)
    # 
  
# df_end$diff_x <- c(abs(df_end$ini_x - df_end$end_x))
# df_end$diff_y <- c(abs(df_end$ini_y - df_end$end_y))
# df_progressive_pass <- df_end[df_end$diff_x > 15.0,]
# df_progressive_pass <- df_progressive_pass[df_progressive_pass$ini_y > 10.0 & df_progressive_pass$ini_y < 50.0, ]
# df_progressive_pass <- df_progressive_pass[df_progressive_pass$ini_x > 60.0, ]


# Radar Graph as an option

# Comparison among teams with different strategies at differnet score.
  # Using the normal equation and the matrix

# clustering

# Evolutionary gaming and game theory dynamic models
# strategy dynamics per team

# Logistic regression of teams with different strategy
  # How to? There are teams with traditional views of their style of playing

## RQ: A measure of how team's strategy change with different scores.

# Arrow plotting
library(ggplot2)
# base_plot <- ggplot() + 
#   xlim(0, 120) + ylim(0, 80) +
#   xlab("X-axis") + ylab("Y-axis") +
#   theme_bw() +
#   theme(panel.grid.major = element_blank(),
#         panel.grid.minor = element_blank())
# plot_function <- function(df,x,y) {
#   for (i in 1:(nrow(df)/2)) {
#     base_plot <- base_plot + geom_segment(aes(x = df[2*i-1, 2], y = df[2*i-1,3],
#                                               xend = df[i*2,2], yend = df[i*2,3]),
#                                           arrow = arrow(length = unit(0.3, "cm")), color = "red", linewidth = 1)
#   }
#   base_plot
# }
# plot_function(df_pass_Bar, col1, col2)
# 
# for (i in 1:2) {
#   base_plot <- base_plot + geom_segment(aes(x = df_pass_Bar[2*i-1, 2], y = df_pass_Bar[2*i-1,3],
#                                             xend = df_pass_Bar[i*2,2], yend = df_pass_Bar[i*2,3]),
#                                         arrow = arrow(length = unit(0.2, "cm")), color = "red", linewidth = 0.6)
# }
# base_plot
# 
# 
# 
# base_plot <- base_plot + geom_segment(aes(x = c(60,52.1), y = c(40,37.6)),
#                                           xend = c(49.4,49.4), yend = c(37.6,57.4),
#                                       arrow = arrow(length = unit(0.2, "cm")), color = "red", linewidth = 0.6)
# 
# base_plot <- base_plot + geom_segment(aes(x = 52.1, y = 37.6,
#                                           xend = 49.4, yend = 57.4),
#                                       arrow = arrow(length = unit(0.3, "cm")), color = "red", linewidth = 1)
