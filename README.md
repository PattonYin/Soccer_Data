# Soccer_Data

Patton's independent Data Analysis Project

# ML models-Outcome Prediction

## 1. After_game_Prediction

Predicting the outcome of the game with Statistics of the players / teams in a whole match.

### Methods:

1. Decision Tree
2. Random Forest
3. Linear Neural Nets

### Data Cleaning:

list of variables dropped:

```
columns_to_drop: [
    "Gls", "gca", "GA", "G/SoT", "G/sh", "CS", "Save%", "Ast", "PassLive", "PassLive.1", "np:G-xG", "G-xG", "npxG/Sh", "xG", "npxG", "PSxG", "PSxG+/-", "xAG", "PassDead", "PassDead.1", "Sh", "SoT", "SoT%"
]
```

These variables were excluded from the analysis as they closely mimic the goal-scoring statistics themselves. Including them would introduce redundancy and could distort the analysis, as they vary in sync with the number of goals.

```
"columns_to_subset_X": [
    "Venue", "Tkl", "TklW", "Def 3rd", "Mid 3rd", "Att 3rd", "Tkl.1", "Att", "Tkl%", "Lost", "Blocks", "Sh", "Pass", "Int", "Tkl+Int", "Clr", "Err", "SCA", "TO", "Sh", "Fld", "Def", "TO.1", "Sh.1", "Fld.1", "Def.1", "SoTA", "Saves", "PKatt", "PKA", "PKsv", "PKm", "Cmp", "Att", "Cmp%", "Att (GK)", "Thr", "Launch%", "AvgLen", "Att.1", "Launch%.1", "AvgLen.1", "Opp", "Stp", "Stp%", "#OPA", "AvgDist", "CrdY", "CrdR", "2CrdY", "Fls", "Fld", "Off", "Crs", "Int", "TklW", "PKwon", "PKcon", "OG", "Recov", "Won", "Lost", "Won%", "Cmp", "Att", "Cmp%", "TotDist", "PrgDist", "Cmp.1", "Att.1", "Cmp%.1", "Cmp.2", "Att.2", "Cmp%.2", "Cmp.3", "Att.3", "Cmp%.3", "xA", "KP", "1/3", "PPA", "CrsPA", "PrgP", "Att", "Live", "Dead", "FK", "TB", "Sw", "Crs", "TI", "CK", "In", "Out", "Str", "Cmp", "Off", "Blocks", "Poss", "Touches", "Def Pen", "Def 3rd", "Mid 3rd", "Att 3rd", "Att Pen", "Live", "Att", "Succ", "Succ%", "Tkld", "Tkld%", "Carries", "TotDist", "PrgDist", "PrgC", "1/3", "CPA", "Mis", "Dis", "Rec", "PrgR", "Dist", "FK", "PK", "PKatt"
]
```

These are the columns kept; stored in the `config.json` file.

### Decision Tree Model:

## 2. In_game_Prediction

How about using the performance of the players in the first 65 minutes to predict the outcome of the game?

```
input:

```

```
output:
outcome of the game
```
