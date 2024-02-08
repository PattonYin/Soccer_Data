import pandas as pd
import json
import torch

class LoadData:
    def __init__(self):
        self.data_path = "../../data/After_game_Prediction/Premier-League-2022-2023/processed/all.csv"
        
        with open("config.json", 'r') as config_file:
            config = json.load(config_file)
            self.columns_to_subset_X = list(set(config["columns_to_subset_X"]))
            self.columns_to_subset_y = list(set(config["columns_to_subset_y"]))
            self.Venue_encode = config["VENUE_ENCODE"]
            self.Result_encode = config["RESULT_ENCODE"]
            
        self.df = self.read_df()
        self.normalize_features()
        
        self.features = torch.tensor(self.df[self.columns_to_subset_X].values, dtype=torch.float32)
        self.labels = torch.tensor(self.df[self.columns_to_subset_y].values.flatten(), dtype=torch.long)
        
    def normalize_features(self):
        self.feature_means = self.df[self.columns_to_subset_X].mean()
        self.feature_stds = self.df[self.columns_to_subset_X].std()
        
        self.df[self.columns_to_subset_X] = (self.df[self.columns_to_subset_X] - self.feature_means) / self.feature_stds
        
    def read_df(self):
        df = pd.read_csv(self.data_path)
        df["Venue"] = df["Venue"].map(self.Venue_encode)
        df["Result"] = df["Result"].map(self.Result_encode)
        df = df[self.columns_to_subset_X + self.columns_to_subset_y]
        df.dropna(inplace=True)
        return df
    
    def __getitem__(self, idx):
        return self.features[idx], self.labels[idx]
    
    def __len__(self):
        return len(self.features)

if __name__ == "__main__":
    LoadData = LoadData()
    Xs, ys = LoadData[:50]
    if torch.isnan(Xs).any():
        print("Input data contains nan values")
    if torch.isnan(ys).any():
        print("Labels contain nan values")    
    # print(f"Xs: {Xs[0]}, type: {type(Xs[0])}, ys: {ys[0]}, type: {type(ys[0])}")
    # print(LoadData[:10])
