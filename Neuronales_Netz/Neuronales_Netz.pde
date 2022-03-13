/*
 * Dies ist ein Beispiel eines Neuronalen Netzes,
 * lernend mithilfe von Backpropagation und mini-batch Optimierung.
 *
 * Programmiert von Jakob Zöphel.
 * 13 März 2022
 */

LayerManager lm;
NeuronalNetworkVisualization nv;
Digit digit;
Functions F = new Functions();
//pointer zu der "main" Klasse, für reflections etc.
Neuronales_Netz main = this;
StartScreen panel;
Diagramm diagram;
Console visualConsole;
EquationRecognition equationRecognizer;
Question q;

////////Anfang Parameter können geändert werden////////
public boolean
  show = false,
  train = false,

  loadWeights = false,
  saveWeights = false,

  loadExamples = false,
  saveExamples = false;


//nach wie vielen Minuten das Training unterbrochen werden soll
public int timeOut = 60;

//nach dem die Trainingsbeipsiele durch sind, wird epochs mal von vorne angefangen.
//(ein Durchlauf aller Trainigsbeispiele == eine Epoche)
public int epochs = 100;

//die Anzahl der zu erstellenden Trainingsbeispiele
public int trainExamples = 1000;
//die Anzahl der zu erstellenden Testbeispiele
public int testExamples = 200;

//Anzahl der zu benutzenden Threads. Diese muss am beste gerade sein.
//Maximum: Runtime.getRuntime().availableProcessors()
public int threadCount = 4;

//bestimmt ob die threads anderen gegenüber Vorrang haben.
//1 == niedrigste, 10 == höchste. Standard ist 5
public int threadPriority = 9;

//Größe eines Trainingsstapels
public int batchSize = 4;

//lernrate
public float lr = 0.01;

//um den Faktor wird das Momentum multipliziert
public float momentumWeakness = 0.8;

//maximum des Betrages welchen ein Gewicht am Anfang annehmen kann
//(die Gewichte werden am Anfang zufällig gewählt)
public float weigthsValue = 0.02;

//Anzahl der Layer und die Anzahl ihrer Neuronen
public HiddenL[] hiddenLayers ={
  new HiddenL(8, F.relu),
  new HiddenL(10, F.relu),
};

//mit dieser Funktion wird der Fehler berechnet
public ErrorFunction loss = F.MSE;
//10 Neuronen, eines für jede Ziffer. Aktivierungsfunktion, Fehlerfunktion. Im
//layerManager wird die Anzahl der Neuronen dann auf die charset.length aktualisiert
public OutputLayer outL = new OutputLayer(10, F.sigmoid, loss);

////////Ende Parameter können geändert werden////////
boolean finishedDrawing = false;
boolean showConsole = true;
final int drawWindowSize = 280;
int currEpoch = 0;
int currExample = 0;
float scale = 1;
//ob die Gewichte ge-updated werden sollen
boolean update = false;
//kills threads
boolean kill = false;
//für pooling
int kernel_size = 10;
//startet Threads
boolean start = false;
//wenn das Panel auf nichts reagieren soll
boolean ignorePanel = false;
//ob es die aktuellste Version
boolean latest;
//der Text der in der visuellen Konsole gezeigt wird
ArrayList<String> consoleText = new ArrayList<String>();
color textColor = color(85, 189, 130);
color backgroundColor = color(36, 48, 40);
color contrast = color(56);
//die Aufgabe die das Programm gerade hat
enum Tasks {
  CONTROL_PANEL, AI, DIAGRAM
};

Tasks task;

void setup() {

  size(1000, 300);
  fontNames = loadStrings(loadFile("fonts.txt"));
  task = Tasks.CONTROL_PANEL;
  panel =  new StartScreen();
  //um Bilder in das Fenster zu ziehen
  drop = new SDrop(this);

  try {

    Process process = Runtime.getRuntime().exec("curl https://raw.githubusercontent.com/JakobZoephel/Neuronales-Netz/main/Neuronales_Netz/Neuronales_Netz.pde");
    BufferedReader input = new BufferedReader(new java.io.InputStreamReader(process.getInputStream()));

    String[] content = loadStrings(sketchPath("source/Neuronales_Netz.pde"));
    //wenn es in der IDE gestartet wurde
    if (content == null)
      content = loadStrings(sketchPath("Neuronales_Netz.pde"));

    String currProgramm = "";
    //Array aufsummieren
    for (int i = 0; i < content.length; i++)
      currProgramm += content[i];

    String line;
    // Anzahl der Linien die curl ausgibt
    int lineCounter = 0;
    String latestProgramm = "";
    while ((line = input.readLine()) != null) {
      lineCounter++;
      latestProgramm += line;
    }

    //wenn es keine Fehlermeldung ist z.B. kein Internet
    if (lineCounter > 300)
      latest = latestProgramm.equals(currProgramm);
    else
      latest = true;
  }
  catch (IOException e) {
    e.printStackTrace();
    latest = true;
  }
}

void draw() {

  switch(task) {
  case CONTROL_PANEL:
    panel.show();
    break;

  case AI:

    if (train) {

      if (show)
        lm.show();
      else
        panel.show();

      if (currEpoch >= epochs || millis()/1000 >= 60*timeOut) {
        kill = true;
        consoleText.add("Loss in " + epochs + " epochs");
        consoleText.add("(0 = no failures, 1 = only failures)");
        for (int i=0; i < failure.length; i++)
          if (failure[i] == 2)break;
          else consoleText.add("epoch " + i + ": " + failure[i]);

        consoleText.add("minniumum error " + min(failure));
        consoleText.add("milliseconds: " + millis());

        surface.setVisible(true);
        if (epochs > 1) {
          task = Tasks.DIAGRAM;
          taskSetup(task);
        } else {
          task = Tasks.CONTROL_PANEL;
          taskSetup(task);
          mousePressed = false;
          exitSave();
        }
        if (testExamples > 0)
          lm.test();
      }
    } else {
      ignorePanel = true;
      surface.setTitle("Neural Network");
      translate(width/2, height/2);
      scale(scale);
      translate(-width/2, -height/2);

      if (finishedDrawing && digit.allOutOfScreen) {
        nv.showResult();
        showAnimation();
      }
    }
    break;

  case DIAGRAM:
    diagram.show();
  }
}

void taskSetup(Tasks task) {


  switch(task) {
  case CONTROL_PANEL:

    surface.setTitle("control panel");
    surface.setResizable(false);
    surface.setVisible(true);
    kill = true;
    start = false;
    ignorePanel = false;
    if (panel != null)
      panel.state = States.TRAINorSHOW;
    else
      panel = new StartScreen();

    surface.setSize(1000, 300);
    break;

  case AI:

    currEpoch = 0;
    currExample = 0;
    update = false;

    surface.setResizable(false);
    //constrain für Thread-Werte
    threadCount = constrain(threadCount, 0, Runtime.getRuntime().availableProcessors());
    threadPriority = constrain(threadPriority, 0, 10);


    if (train && show)
      surface.setSize(1200, 650);

    if (showConsole && visualConsole == null) {
      String[] args = {"console"};
      visualConsole = new Console();
      PApplet.runSketch(args, visualConsole);
    }

    if (train)
      consoleText.add("Trainiere auf " + threadCount + " Threads.");

    try {
      lm = new LayerManager();
    }
    catch(Exception e) {
      e.printStackTrace();
      consoleText.add("Ein Fehler ist aufgetreten. Das Programm wird beendet.");
      consoleText.add("Du solltest deine Einstellungen im Control-Panel bearbeiten.");
      noLoop();
    }

    if (show) {
      nv = new NeuronalNetworkVisualization(1200, 600);
      if (train)
        nv.show();

      stroke(255);
      fill(255);
      textSize(21);
      textAlign(CENTER, CENTER);

      if (!train) {
        surface.setVisible(false);
        if (digit == null) {
          String[] args2 = {"digit"};
          digit = new Digit();
          PApplet.runSketch(args2, digit);
        } else
          digit.deFreeze();
      }
    } else if (!train) {
      if (testExamples > 0)
        consoleText.add("Erstelle Testbeispiele...");
      loadWeights = true;
      loadExamples = true;
      lm = new LayerManager();
      lm.test();
    }

    if (train && visualConsole != null)
      //start threads
      start = true;
    break;

  case DIAGRAM:

    surface.setSize(600, 400);
    surface.setTitle("statistics");
    surface.setResizable(true);

    diagram = new Diagramm();
    break;
  }
}

void showAnimation() {
  int inputSize = (nv.pg.height-2*20)/trainExampleData;
  inputSize = constrain(inputSize, 1, 50);
  for (int i=0; i < digit.pigments.size(); i++) {
    digit.pigments.get(i).show(this, true);
    if (Vdist(digit.pigments.get(i).loc, new PVector(nv.pos[0][digit.pigments.get(i).perceptronIndex].x + nv.offset, nv.pos[0][digit.pigments.get(i).perceptronIndex].y))
      < inputSize || digit.pigments.get(i).loc.x >= nv.pos[0][digit.pigments.get(i).perceptronIndex].x + nv.offset)
      digit.pigments.remove(digit.pigments.get(i));
  }
}

static float Vdist(PVector a, PVector b) {
  return dist(a.x, a.y, b.x, b.y);
}

void dropEvent(DropEvent event) {
  if (event.isImage() && task == Tasks.CONTROL_PANEL && panel.state == States.TRAINorSHOW) {
    if (event.filePath() instanceof String)
      //event.loadImage() funktioniert auf Linux nicht :(
      equations = loadImage(event.filePath());
  }
}

void openURL(String url) throws Exception {

  try {
    Desktop.getDesktop().browse(new URI(url));
  }
  catch (Exception e) {
    e.printStackTrace();
    System.exit(0);
  }
}

//MNIST = Modified National Institute of Standards and Technology
void createMNIST(int examplesPerNumber, String examplePath) {

  if (examplePath.charAt(examplePath.length()-1) != '/' && examplePath.charAt(examplePath.length()-1) != '\\')
    println("Du solltest an den MNIST-Path ein \\ (Windows) bzw. / (Linux) hinzufügen");

  show = false;
  train = false;

  loadWeights = false;
  saveWeights = false;

  loadExamples = false;
  saveExamples = false;
  lm = new LayerManager();


  //namen der Datein
  String[][] names = new String[10][];
  //damit die trainData wieder auf den Ursprung zurück gesetzt werden kann
  byte[][] buffer;

  if (trainData != null)
    buffer = trainData.clone();
  else
    buffer = null;

  trainData = new byte[charset.length*examplesPerNumber][28*28];
  trainExamples = trainData.length;
  trainExampleData = F.createNumber('+').length;


  // um auf die Ordner zugreifen zu können
  File path;

  //welches Bild aus dem Ordner genommen werden soll
  int[] indexes = new int[names.length];
  for (int i = 0; i < indexes.length; i++)
    indexes[i] = 0;

  for (int i = 0; i < indexes.length; i++) {
    path = new File(examplePath + i);
    names[i] = path.list();
  }

  int alreadyCreated = F.savedExamples();

  for (int i = 0; i < alreadyCreated; i++)
    F.loadExample(i);

  for (int i = alreadyCreated; i < trainData.length; i++) {
    if (i%charset.length <= 9) {

      //was für eine Ziffer
      int type = i%charset.length;
      PImage number = loadImage(examplePath + type + "/" + names[type][indexes[type]]);
      indexes[type]++;
      //MNIST ist weiß mit schwarzen Hintergrund. Das soll umgedreht werden
      number = MNIST_adjustment(number);
      //von 28*28 auf 280*280
      number.resize(drawWindowSize, drawWindowSize);
      number = F.cut(number);
      number = F.pooling(number, kernel_size, (x) -> max(x));
      number = F.blackWhite(number);
      trainData[i] = byte(F.imageToVector(number));
    } else
      trainData[i] = F.createNumber(charset[i%charset.length]);

    if (i % 100 == 0)
      println(i + "/" + trainData.length);
  }

  lm.saveExamples();

  if (buffer != null)
    //wieder auf Ursprung
    trainData = buffer.clone();
  else
    trainData = null;

  println("finished MNIST");
}

PImage MNIST_adjustment(PImage picture) {

  picture.loadPixels();
  for (int i = 0; i < picture.pixels.length; i++)
    if (picture.pixels[i] != color(0))
      picture.pixels[i] = color(255);

  picture.updatePixels();

  picture.loadPixels();
  for (int i = 0; i < picture.pixels.length; i++)
    if (picture.pixels[i] == color(0))
      picture.pixels[i] = color(255);
    else if (picture.pixels[i] == color(255))
      picture.pixels[i] = color(0);

  picture.updatePixels();
  return picture;
}

float e;

void mouseWheel(MouseEvent event) {

  panel.mouseWheel(event);

  if (!show)return;
  e = event.getCount();
  scale += e/10;
  scale = constrain(scale, 0.4, 5);
}

boolean strgIsPressed = false;
boolean keyIsPressed = false;
//bei key kombi's bedeuted ein 's' => 'S'
char key_ = 'S';

void keyReleased() {

  panel.keyReleased();

  if (keyCode == CONTROL)
    strgIsPressed = false;
  if (key_ == char(keyCode))
    keyIsPressed = false;

  if (keyIsPressed && strgIsPressed) {
    if (!train)
      return;
    if (saveWeights)
      lm.saveWeights();
  }
}

void keyTyped() {
  panel.keyTyped();
}

void mousePressed() {
  panel.mousePressed();
}

void mouseReleased() {
  panel.mouseReleased();
}

boolean spacePressed = false;

void keyPressed() {

  panel.keyPressed();

  if (key == ' ')
    spacePressed = !spacePressed;

  if (keyCode == CONTROL && strgIsPressed == false)
    strgIsPressed = true;
  if (key_ == char(keyCode))
    keyIsPressed = true;
}

String loadFile(String name) {
  return sketchPath("data/"+ name);
}

void exit() {

  if (visualConsole != null)
    visualConsole.exit();

  super.exit();
}

void exitSave() {


  if (saveWeights)
    lm.saveWeights();

  if (saveExamples)
    lm.saveExamples();

  panel.savePanel();
  kill = true;
}
