import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from tqdm import trange
import json
import os

from nn_model import LinearModel
from nn_load_data import LoadData

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, random_split
    
    
class train_model:
    def __init__(self):
        
        self.data = LoadData()
        self.trainset, self.testset = self.split_data()
        self.trainloader = DataLoader(self.trainset, batch_size=20, shuffle=True)
        self.testloader = DataLoader(self.testset, batch_size=20, shuffle=True)
        
        self.device = "cpu"
        
        self.model = LinearModel().to(self.device)
        self.criterion = nn.CrossEntropyLoss().to(self.device)
        self.learning_rate = 0.01
        self.optimizer = torch.optim.SGD(self.model.parameters(), lr=self.learning_rate)

        self.loss_count = []
        self.acc_count = []
        
        self.epoch = 200
        
    def split_data(self):
        total_length = len(self.data)
        train_length = int(total_length * 0.8)
        test_length = total_length - train_length 
        return random_split(self.data, [train_length, test_length])        
        
    def test(self):
        corr = 0
        total = 0
        with torch.no_grad():
            for (data,label) in self.testloader:
                data, label = data.to(self.device), label.to(self.device)
                output = self.model(data)
                _,pred = torch.max(output.data,dim=1)
                corr += (pred == label).sum().item()
                total += label.size(0)
        print(f'Accuracy on test set: {corr/total:.2%} ') 
        return corr/total
        
    def train(self):
        for e in range(self.epoch):    
            running_loss = 0.0
            for id, (data,labels) in enumerate(self.trainloader,0):
                data,labels = data.to(self.device), labels.to(self.device)
                self.optimizer.zero_grad()
                output = self.model(data)
                loss = self.criterion(output,labels)
                loss.backward()
                self.optimizer.step()
                running_loss += loss.item()
            print(f"Epoch {e} - Training loss: {running_loss/len(self.trainloader):.4f}")
            self.loss_count.append(running_loss/len(self.trainloader))
            acc = self.test()
            self.acc_count.append(acc)
        self.model = self.model.to('cpu')
        torch.save(self.model, f'model/linear_model.pt')
        print("Model saved")
        
    def plot(self):
        figure = plt.figure()
        plt.subplot(1,2,1)
        plt.plot(np.array(self.loss_count))
        plt.subplot(1,2,2)
        plt.plot(np.array(self.acc_count))
        plt.show()
        # export the plot to the images folder
        figure.savefig("../../result/After_game_Prediction/Premier-League-2022-2023/loss_acc_plot.png")
    
if __name__ == "__main__":
    train_model = train_model()
    train_model.train()
    train_model.plot()