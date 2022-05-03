import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torchvision import transforms
from os import listdir
import random
from PIL import Image, ImageOps
import sys
import math
import time

# normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406],
#                                std=[0.229, 0.224, 0.225]  # maximale Abweichung vom mean
#                                 )

transforms = transforms.Compose([
    transforms.Resize((280, 280)),
    transforms.ToTensor()  # damit das Netz damit arbeiten kann
])

# enthält später die Batches aus den BildTenosren
train_data = []
# enthält zu jedem Element aus jedem Batch das Label
labels = []

# in welchem Ordner die Trainingsdaten sind (in diesem befindet sich für jede Klase ein weiterer Ordner)
train_path = "/home/jakob/Schreibtisch/training/"
test_path = "/home/jakob/Schreibtisch/testing/"

# welche Klassen es gibt
charset = listdir(train_path)

# einfach alle train Daten
ALL_TRAIN_FILES = []
# Bildnamen von jedem Trainingsbeispiel. Bilder die bereits geladen wurden werden entfernt.
available_train_files = []
available_test_files = []

batch_size = 16
examples = 30000
epochs = 30
saveWeights = True
loadWeights = True
trainAI = True
# Trace model um es für C++ nutzbar zu machen
trace = True

# ob eine NVidia Grafikkarte verfügbar ist
use_gpu = torch.cuda.is_available()


def load_examples():

    # damit die Ziffern zuerst kommen und dann alle anderen Zeichen
    charset.sort()
    index0 = -1
    for i in range(len(charset)):
        if charset[i] == '0':
            index0 = i
            break

    for i in range(index0):
        c = charset[0]
        charset.remove(c)
        charset.append(c)

    # ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '=', '+', '-']
    #print(charset)

    for i in charset:
        available_train_files.append(listdir(train_path + i))
        try:
            available_test_files.append(listdir(test_path + i))
        # wenn der Ordner nicht existiert
        except FileNotFoundError:
            print("no test-dic: " +  i)

    train_batch = []
    for i in available_train_files:
        ALL_TRAIN_FILES.append(i.copy())

    for i in range(examples):  # für jedes Bild:

        number = i % len(charset)

        if(len(available_train_files[number]) > 0):
            pic = random.choice(available_train_files[number])
            available_train_files[number].remove(pic)  # keine Mehrfachziehung
            img = Image.open(train_path + charset[number]+ '/' + pic)
        else:
            # einfach irgendein Bild doppelt nehmen damit das Verhältnis passt
            pic = random.choice(ALL_TRAIN_FILES[number])
            img = Image.open(train_path + charset[number] + '/' + pic)

        # oder .convert("RGB"). L ist grayscale.
        # man könnte die grayscale dim (1) entfernen (squeeze), ist so aber einfacher wenn man
        # aus irgendwelchen Gründen lieber mit RGB (dm=3) arbeiten möchte
        img = img.convert('L')
        # schwarz zu weiß, weiß zu schwarz
        if number <= 9:
            img = ImageOps.invert(img)

        # 1 == weiß, 0 == schwarz, dazwischen grau
        img_tensor = transforms(img)
        img.close()

        train_batch.append(img_tensor)
        label = []
        for n in range(len(charset)):
            if n == number:
                label.append(1)
            else:
                label.append(0)

        labels.append(label)
        if len(train_batch) >= batch_size:
            train_data.append((torch.stack(train_batch),  # stack macht aus der Liste einen Tensor
                               torch.Tensor(labels)))
            train_batch.clear()  # damit sie wieder die nächsten aufnehmen kann
            labels.clear()
            print('Loaded batch ', len(train_data), 'of ', int(examples / batch_size))


class Netz(nn.Module):

    def __init__(self):
        super(Netz, self).__init__()

        self.conv1 = nn.Conv2d(1, 10, kernel_size=5)
        self.conv2 = nn.Conv2d(10, 20, kernel_size=5)
        self.conv2_drop = nn.Dropout2d()
        self.fc1 = nn.Linear(320, 50)
        self.fc2 = nn.Linear(50, 13)

    def forward(self, x):

        x = F.max_pool2d(x, 10)
        x = self.conv1(x)
        x = F.max_pool2d(x, 2)
        x = F.relu(x)

        x = self.conv2(x)
        x = self.conv2_drop(x)
        x = F.max_pool2d(x, 2)
        x = F.relu(x)

        x = x.view(-1, 320)
        x = self.fc1(x)
        x = F.relu(x)
        x = F.dropout(x, training=self.training)
        x = self.fc2(x)
        return F.sigmoid(x)


model = Netz()

if use_gpu:
    model = model.cuda()

optimizer = optim.SGD(model.parameters(), lr=0.005, momentum=0.3)

def train(curr_epoch):
    model.train()
    batch_id = 0
    for data, label in train_data:

        if use_gpu:
            data = data.cuda()
            label = label.cuda()

        optimizer.zero_grad()
        out = model(data)

        loss = F.binary_cross_entropy(out, label)
        loss.backward()
        optimizer.step()
        print('Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}'.format(
            curr_epoch, batch_id * batch_size, examples, 100. * batch_id / (examples / batch_size), loss.item()))
        batch_id = batch_id + 1


def test(examples):
    model.eval()
    for i in range(examples):
        number = i % len(available_test_files)
        pic = random.choice(available_test_files[number])
        img = Image.open(test_path + str(number) + '/' + pic)

        img = img.convert('L')
        if number <= 9:
            img = ImageOps.invert(img)

        img_tensor = transforms(img)
        # es muss eine batch-dimension angehangen werden
        img_tensor.unsqueeze_(0)

        out = model(img_tensor)
        # print(out.data)
        # (1) == zweite Dimension, [1] ist der Index ( [0] wäre nur der Wert)
        max = out.data.max(1)[1]
        print(charset[max.item()])

        img.show()
        # kurz warten
        time.sleep(1)
        img.close()


def getDecision(pixels):
    model.eval()
    size = int(math.sqrt(len(pixels)))
    picture = [[]]

    # die Daten in das Format torch.Size([1, 280, 280]) bringen
    for x in range(size):
        picture[0].append([])
        for y in range(size):
            picture[0][x].append(int(pixels[x+y*size]))

    img_tensor = torch.FloatTensor(picture)
    out = model(img_tensor)

    # (1) == zweite Dimension, [1] ist der Index ( [0] wäre nur der Wert)
    # max = out.data.max(1)[1]
    #print(out.data.max(1)[1].item())

    returnString = ""

    results = out.data.numpy()[0]

    for i in results:
        returnString += str(i) + " "

    return returnString.strip()


# Name des Programmes ist unwichtig
args = sys.argv[1:]

if __name__ == "__main__":

    if len(args) > 0:

        if(len(args) != 2):
            print("usage: python3 PyTorch-KI.py <path-to-weights> <path-to-data>\n")
            exit()

        weightsPath = args[0]
        s = ""
        with open(args[1], "r") as f:
            s = f.read()

        model.load_state_dict(torch.load(weightsPath))
        print(getDecision(s))
        exit()

    else:

        load_examples()
        if loadWeights:
            # Path nur in meinem Fall
            model.load_state_dict(torch.load('/home/jakob/Schreibtisch/Neuronales_Netz/data/weights.pth'))

        if trainAI:
            for epoch in range(epochs):
                train(epoch)

            if saveWeights:
                # Path nur in meinem Fall
                torch.save(model.state_dict(), '/home/jakob/Schreibtisch/Neuronales_Netz/data/weights.pth')

        test(len(charset)*1)

        # Netz + Gewichte für LibTorch speichern
        if trace:
            example = torch.ones(1, 1, 280, 280)
            traced_script_module = torch.jit.trace(model, example)
            # Path nur in meinem Fall
            traced_script_module.save("/home/jakob/Schreibtisch/Neuronales_Netz/data/traced_digit_model.pt")
