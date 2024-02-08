import torch
from torch import nn
import torch.nn.functional as F

class LinearModel(nn.Module):
    def __init__(self):
        super(LinearModel, self).__init__()
        self.linear1 = nn.Linear(100, 300)
        self.linear2 = nn.Linear(300, 150)
        self.linear3 = nn.Linear(150, 50)
        self.linear4 = nn.Linear(50, 3)
        
    def forward(self, x):
        batch_size = x.size(0)
        x = F.relu(self.linear1(x))
        x = F.relu(self.linear2(x))
        x = F.relu(self.linear3(x))
        x = self.linear4(x)
        return x
