import pandas as pd

class Analysis:
    def __init__(self):
        self.sample_data = pd.read_csv("../data/3773457.csv", low_memory=False)
        
    def index_passes_before_shots(self, data=self.sample_data):
        return None
    
    
