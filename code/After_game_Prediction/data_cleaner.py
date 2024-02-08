import pandas as pd
import json
import os

class DataCleanup:
    def __init__(self):
        self.json_path = r'X:\code\Soccer_Data\code\After_game_Prediction\config.json'
        self.folder_path = "../../data/After_game_Prediction/Premier-League-2022-2023/"
        
        with open(self.json_path, 'r') as config_file:
            config = json.load(config_file)
            self.team_list = config["TEAMS"]["PREMIER_LEAGUE_TEAMS"]
            self.metrics = config["METRICS"]
        
    def concat_df(self):
        output_path = self.folder_path + "processed"
        if not os.path.exists(output_path):
            os.makedirs(output_path)
        
        for category in self.metrics:
            df_all = pd.DataFrame()
            for x in self.team_list:
                df = pd.read_csv(self.folder_path + x.replace(" ", "-") + "/" + category + ".csv")
                # Add a column with the team name to the first column
                df.insert(0, "team_name", x)
                df_all = pd.concat([df_all, df])
            
            file_name = output_path + "/" + category + "_all.csv"
            df_all.to_csv(file_name, index=False)
            
    def check_missing(self):
        for team in self.team_list:
            # Check the number of files simply using os.listdir
            team_folder = self.folder_path + team.replace(" ", "-")
            files = os.listdir(team_folder)
            print(f"there are {len(files)} files, for team: {team}.")
            
    def cbind(self):
        df_all = pd.DataFrame()
        the_path = self.folder_path + "processed"
        for i in os.listdir(the_path):
            df = pd.read_csv(the_path + "/" + i)
            df_all = pd.concat([df_all, df], axis=1)
        df_all.to_csv(the_path + "/all.csv", index=False)

if __name__ == "__main__":
    data_cleanup = DataCleanup()
    
    # df_all = data_cleanup.concat_df()
    # data_cleanup.check_missing()
    data_cleanup.cbind()    