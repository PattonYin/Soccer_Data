import pandas as pd
from selenium import webdriver
# options = webdriver.ChromeOptions()
# options.add_argument("--headless")
# driver = webdriver.Chrome(options=options)
from requests_html import HTMLSession
import json
from tqdm import trange 
import os
import time 

class SoccerDataScraper:
    def __init__(self):
        self.json_path = r'X:\code\Soccer_Data\code\After_game_Prediction\config.json'
        
        with open(self.json_path, 'r') as config_file:
            config = json.load(config_file)
            self.sample_url = config["SAMPLE_URL"]
            self.premier_league_table_url = config["PREMIER_LEAGUE_TABLE_URL"]
            self.base_url = config["BASE_URL"]
            # self.sample_teams = config["TEAMS"]["PREMIER_LEAGUE_TEAMS"]
            self.metrics = config["METRICS"]
        
        self.headers_win = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"}

        # self.driver = webdriver.Chrome()

    def get_data(self, url, num):
        r = session.get(url, headers=self.headers_win)
        r.html.render()
        table = r.html.find('table', first=True)
        headers = [header.text for header in table.find('thead tr th')]
        columns = headers[num:]
        data_rows = []
        for row in table.find('tbody tr'):
            date = [row.find('th', first=True).text]
            row_data = [td.text for td in row.find('td')]
            data_rows.append(date + row_data)
        df_sample = pd.DataFrame(data_rows, columns=columns)
        # Drop the 22th and 23th rows
        df_sample = df_sample.drop([20, 21])
        return df_sample

    def scraper_prep(self, url):
        print("Rendering")
        r = session.get(url, headers=self.headers_win)
        r.html.render()
        print("Scraping")
        table = r.html.find('table', first=True)
        
        try:
            headers = [header.text for header in table.find('thead tr th')]
            columns = headers[1:]
            data_rows = []
            df_scrape = pd.DataFrame(columns=['team_name', 'url'])
            url_team_list = []
            
            for row in table.find('tbody tr'):
                # Get the url of the team
                a_tag = row.find('a', first=True)
                url_team_list.append(a_tag.attrs['href'])
                # Get the other data
                row_data = [td.text for td in row.find('td')]
                data_rows.append(row_data)
            df_teams = pd.DataFrame(data_rows, columns=columns)
            # Subset Squad column
            teams_list = df_teams["Squad"].tolist()   
            
            df_scrape = pd.DataFrame({'team_name': teams_list, 'url': url_team_list})
            return df_scrape
        except Exception as e:
            print(f"Error: {e}")
            print(f"table: {table}")

    def scrape(self, season, league, info_df, start_index=0, end_index=None):
        '''
        
        info_df: DataFrame with the following columns:
            - team_name: str
            - url: str
        '''
        league = league.replace(" ", "-")
        
        # Path Prep
        if not os.path.exists("../../data"):
            print("Error: data folder does not exist")
            return None
        the_folder = league + "-" + season
        if not os.path.exists("../../data/After_game_Prediction/" + the_folder):
            os.makedirs("../../data/After_game_Prediction/" + the_folder)
            print(f"folder {the_folder} created")
        else:
            print(f"the folder: {the_folder} exists")
            
        # Loop through the teams
        for i in trange(start_index, end_index if end_index else len(info_df)):
            # String prep
            team_name = info_df.iloc[i]['team_name']
            team_url = "/".join(info_df.iloc[i]['url'].split("/")[:5])
            team_name_todo = team_name.replace(" ", "-")
            
            # Check if team folder exists
            team_folder_path = "../../data/After_game_Prediction/" + the_folder + "/" + team_name_todo
            if not os.path.exists(team_folder_path):
                os.makedirs(team_folder_path)
            
            for metric in self.metrics:
                columns_to_ignore = int(self.metrics[metric])
                url_todo = self.base_url + team_url + "/matchlogs/c9/" + metric + "/" + team_name_todo + "-" + "Match-logs-" + league
                
                # print("-----debug-----")
                # print(f"url to scrape: {url_todo} for metric: {metric} for team: {team_name_todo}")
                # time.sleep(1)
                # print("-----debug-----")
                try:
                    df_out = self.get_data(url_todo, columns_to_ignore)
                    time.sleep(10)
                except Exception as e:
                    self.log_error(team_folder_path + ": " + url_todo)
                    print(f"Error: {e}")
                    continue
                
                df_out.to_csv(team_folder_path + "/" + metric + ".csv", index=False)
                print(f"metric: {metric} completed for team: {team_name_todo}")
    
        print("All metrics completed") 
        
    def scrape_one_metric(self, season, league, info_df, metric, start_index=0, end_index=None):
        league = league.replace(" ", "-")
        
        # Path Prep
        if not os.path.exists("../../data"):
            print("Error: data folder does not exist")
            return None
        the_folder = league + "-" + season
        if not os.path.exists("../../data/After_game_Prediction/" + the_folder):
            os.makedirs("../../data/After_game_Prediction/" + the_folder)
            print(f"folder {the_folder} created")
        else:
            print(f"the folder: {the_folder} exists")
            
        # Loop through the teams
        for i in trange(start_index, end_index if end_index else len(info_df)):
            # String prep
            team_name = info_df.iloc[i]['team_name']
            team_url = "/".join(info_df.iloc[i]['url'].split("/")[:5])
            team_name_todo = team_name.replace(" ", "-")
            
            # Check if team folder exists
            team_folder_path = "../../data/After_game_Prediction/" + the_folder + "/" + team_name_todo
            if not os.path.exists(team_folder_path):
                os.makedirs(team_folder_path)
            
            columns_to_ignore = int(self.metrics[metric])
            url_todo = self.base_url + team_url + "/matchlogs/c9/" + metric + "/" + team_name_todo + "-" + "Match-logs-" + league
            
            # print("-----debug-----")
            # print(f"url to scrape: {url_todo} for metric: {metric} for team: {team_name_todo}")
            # time.sleep(1)
            # print("-----debug-----")
            try:
                df_out = self.get_data(url_todo, columns_to_ignore)
                # time.sleep(10)
            except Exception as e:
                self.log_error(team_folder_path + ": " + url_todo)
                print(f"Error: {e}")
                continue
            
            df_out.to_csv(team_folder_path + "/" + metric + ".csv", index=False)
            print(f"metric: {metric} completed for team: {team_name_todo}")
        print("all templates are completed")
    
    def log_error(self, content):
        with open("log.txt", "a") as file:
            file.write(content)
            file.write("\n")
            file.close()
        return None
    
if __name__ == "__main__":
    session = HTMLSession()
    scraper = SoccerDataScraper()

    # To Scrape Premier League's Basic Info
    # df_scrape = scraper.scraper_prep(scraper.premier_league_table_url)
    # df_scrape.to_csv("teams.csv", index=False)
    # print(df_scrape)
    
    # Get all the data
    # df_scrape = pd.read_csv("../../data/After_game_Prediction/Premier-League-2022-2023/teams.csv")
    # scraper.scrape("2022-2023", "Premier League", df_scrape, start_index=3)

    # Missing Metric - possession
    # df_scrape = pd.read_csv("../../data/After_game_Prediction/Premier-League-2022-2023/teams.csv")
    # scraper.scrape_one_metric("2022-2023", "Premier League", df_scrape, "possession", start_index=0)

    # Testing
    # scraper.get_data("https://fbref.com/en/squads/b8fd03ef/2022-2023/matchlogs/c9/shooting/Manchester-City-Match-Logs-Premier_League", 4)
    
    scraper.get_data("https://fbref.com/en/squads/33c895d4/2022-2023/matchlogs/c9/possession/Southampton-Match-Logs-Premier-League", scraper.metrics["possession"])
    
    # "https://fbref.com/en/squads/b8fd03ef/2022-2023/matchlogs/c9/misc/Manchester-City-Match-Logs-Premier-League"
    
    
    