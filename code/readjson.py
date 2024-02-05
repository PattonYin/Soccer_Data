import json
import pandas as pd


def readjson(path):
    f = open(path)
    data = json.load(f)
    df = pd.DataFrame(data)
    df.to_csv(path+'.csv')