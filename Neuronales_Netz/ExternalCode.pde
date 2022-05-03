//ScriptEngine wäre kürzer, allerdings kriege ich (neben der Lösung) diesen Output:
//Warning: Nashorn engine is planned to be removed from a future JDK release
//deshalb nutze ich lieber diesen code (was auch sicherer ist als user input auszuführen):

//from https://stackoverflow.com/questions/3422673/how-to-evaluate-a-math-expression-given-in-string-form (9.1.2022, 16:36)
public static double eval(final String str) {
  return new Object() {
    int pos = -1, ch;

    void nextChar() {
      ch = (++pos < str.length()) ? str.charAt(pos) : -1;
    }

    boolean eat(int charToEat) {
      while (ch == ' ') nextChar();
      if (ch == charToEat) {
        nextChar();
        return true;
      }
      return false;
    }

    double parse() {
      nextChar();
      double x = parseExpression();
      if (pos < str.length()) throw new RuntimeException("Unexpected: " + (char)ch);
      return x;
    }

    // Grammar:
    // expression = term | expression `+` term | expression `-` term
    // term = factor | term `*` factor | term `/` factor
    // factor = `+` factor | `-` factor | `(` expression `)`
    //        | number | functionName factor | factor `^` factor

    double parseExpression() {
      double x = parseTerm();
      for (;; ) {
        if      (eat('+')) x += parseTerm(); // addition
        else if (eat('-')) x -= parseTerm(); // subtraction
        else return x;
      }
    }

    double parseTerm() {
      double x = parseFactor();
      for (;; ) {
        if      (eat('*')) x *= parseFactor(); // multiplication
        else if (eat('/')) x /= parseFactor(); // division
        else return x;
      }
    }

    double parseFactor() {
      if (eat('+')) return parseFactor(); // unary plus
      if (eat('-')) return -parseFactor(); // unary minus

      double x;
      int startPos = this.pos;
      if (eat('(')) { // parentheses
        x = parseExpression();
        eat(')');
      } else if ((ch >= '0' && ch <= '9') || ch == '.') { // numbers
        while ((ch >= '0' && ch <= '9') || ch == '.') nextChar();
        x = Double.parseDouble(str.substring(startPos, this.pos));
      } else if (ch >= 'a' && ch <= 'z') { // functions
        while (ch >= 'a' && ch <= 'z') nextChar();
        String func = str.substring(startPos, this.pos);
        x = parseFactor();
        if (func.equals("sqrt")) x = Math.sqrt(x);
        else if (func.equals("sin")) x = Math.sin(Math.toRadians(x));
        else if (func.equals("cos")) x = Math.cos(Math.toRadians(x));
        else if (func.equals("tan")) x = Math.tan(Math.toRadians(x));
        else throw new RuntimeException("Unknown function: " + func);
      } else {
        throw new RuntimeException("Unexpected: " + (char)ch);
      }

      if (eat('^')) x = Math.pow(x, parseFactor()); // exponentiation

      return x;
    }
  }
  .parse();
}


// das von mir programmierte Python-Script:

/*
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torchvision import transforms
import torchvision
from os import listdir
import random
from PIL import Image, ImageOps
import sys
import math
import time

img_size = 28
transforms = transforms.Compose([
    transforms.Resize((img_size, img_size)),
    transforms.ToTensor(),
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
# Bildnamen von jedem Trainingsbeispiel. Bilder die bereits geladen wurden, werden entfernt.
available_train_files = []
available_test_files = []

batch_size = 32
examples = 50000
epochs = 40
SAVE_WEIGHTS = True
LOAD_WEIGHTS = True
TRAIN = True
# Trace model um es für C++ LibTorch zu speichern
TRACE = True

# ob eine NVidia Grafikkarte verfügbar ist
USE_GPU = torch.cuda.is_available()


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
        img_tensor = img_tensor.numpy()

        for i in range(img_size):
            for j in range(img_size):
                if img_tensor[0, i, j] > 0.6:
                    # weiß
                    img_tensor[0, i, j] = 1
                else:
                    # schwarz
                    img_tensor[0, i, j] = 0
        img_tensor = torch.Tensor(img_tensor)

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
        self.fc1 = nn.Linear(320, 100)
        self.fc2 = nn.Linear(100, 13)

    def forward(self, x):

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
        return torch.sigmoid(x)


model = Netz()

if USE_GPU:
    model = model.cuda()

#optimizer" = optim.Adam(model.parameters(), lr=0.05)
optimizer = optim.SGD(model.parameters(), lr=0.007, momentum=0.7)

def train(curr_epoch):
    model.train()
    batch_id = 0
    for data, label in train_data:

        if USE_GPU:
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
        if LOAD_WEIGHTS:
            # Path nur in meinem Fall
            model.load_state_dict(torch.load('/home/jakob/Schreibtisch/Neuronales_Netz/data/weights.pth'))

        if TRAIN:
            for epoch in range(epochs):
                train(epoch)

            if SAVE_WEIGHTS:
                # Path nur in meinem Fall
                torch.save(model.state_dict(), '/home/jakob/Schreibtisch/Neuronales_Netz/data/weights.pth')

        test(len(charset)*1)

        # Netz + Gewichte für LibTorch speichern
        if TRACE:
            example = torch.ones(1, 1, img_size, img_size)
            traced_script_module = torch.jit.trace(model, example)
            # Path nur in meinem Fall
            traced_script_module.save("/home/jakob/Schreibtisch/Neuronales_Netz/data/traced_digit_model.pt")
*/


// das von mir programmierte C++:

/*
#include <torch/script.h> // One-stop header.

#include <iostream>
#include <memory>

// added von Jakob
#include <fstream>

torch::Tensor loadExample(const char *path)
{

  // lade das Bild
  std::ifstream myfile(path);

  // alternativ sqrt(pixels)
  const int size = 28;

  // 1D char Array mit den Bild-Pixeln
  char pixels[size * size];

  if (myfile.is_open())
  {
    myfile.getline(pixels, sizeof(pixels));
    myfile.close();
  }

  // 280 pixel auf x Achse, 280 auf y
  int picture[size][size];

  // von 1D auf 2D
  for (int y = 0; y < size; y++)
  {
    for (int x = 0; x < size; x++)
    {
      picture[x][y] = (int)(pixels[x + y * size] - '0');
    }
  }

  // torch::Tensor t = torch::from_blob(picture, {size, size}, torch::kFloat32);
  torch::Tensor t = torch::ones({size, size});
  // gray-channel dim, batch-dim
  t = t.unsqueeze(0).unsqueeze(0);

  // die Werte in den Tensor kopieren
  for (int y = 0; y < size; y++)
  {
    for (int x = 0; x < size; x++)
    {
      t[0][0][x][y] = picture[x][y];
    }
  }
  return t;
}

int main(int argc, const char *argv[])
{

  if (argc != 3)
  {
    std::cerr << "usage: app <path-to-exported-script-module> <path-to-data>\n";
    return -1;
  }

  torch::jit::script::Module module;
  try
  {
    // Deserialize the ScriptModule from a file using torch::jit::load().
    module = torch::jit::load(argv[1]);
  }
  catch (const c10::Error &e)
  {
    std::cerr << "error loading the model\n";
    return -1;
  }

  // // Create a vector of inputs.
  std::vector<torch::jit::IValue> inputs;
  inputs.push_back(loadExample(argv[2]));

  torch::Tensor output = module.forward(inputs).toTensor();

  output = output.squeeze();
  for (int i = 0; i < output.size(0); i++)
  {
    std::cout << output[i].item<float>() << " ";
  }
  std::cout << std::endl;
}
*/
