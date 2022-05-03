//normalerweise sollte es 784 sein //<>//
int trainExampleData;
float[] failure;
//byte, da es in diesem Beispiel nur 0 und 1 gibt
byte[][] trainData, testData;

//byte da labels nur von 0-9 sind
int[] labels;
//all characters a loaded font will have
final char[] charset = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '=', '+', '-'};
//zu viele "komische" dabei
//String[] fontNames = PFont.list();

String[] fontNames;

CalculatingThread[] threads;

//Objekt da für synchronized
Integer generatedTrainExamples = 0;
Integer generatedTestExamples = 0;
//wird nur benutzt wenn diese aus der examples.txt Datei gelesen werden
byte[] examples;

class LayerManager {

  float[] deltaList, ergebnis, desired;
  float[][] outputsH;
  int failures = 0;

  LayerManager() {

    if (trainExamples <= 1) {
      consoleText.add("Die angegebene Anzahl an Trainingsbeispielen ist ungültig");
      kill = true;
      noLoop();
    }

    outL = new OutputLayer(charset.length, outL.outNs[0].function, outL.outNs[0].error);

    trainExampleData = F.createNumber('0').length;
    generatedTestExamples = 0;
    generatedTrainExamples = 0;

    //negative lr (-> siehe Ableitung der Backpropagation)
    lr = -lr;


    testData = new byte [testExamples][trainExampleData];
    labels = new int[trainExamples];
    failure = new float[epochs];

    if (train) {
      if (loadExamples && examples == null)
        examples = loadBytes(loadFile("examples.txt"));


      threads = new CalculatingThread[threadCount];
      trainData = new byte [trainExamples][trainExampleData];

      start = false;
      kill = false;
      for (int i = 0; i < threadCount; i++)
      try {
        threads[i] = new CalculatingThread(i);
        threads[i].start();
        threads[i].setPriority(threadPriority);
      }
      catch(IllegalThreadStateException e) {
        consoleText.add("Ein Fehler ist bei dem Starten des " + i + "ten Thrads aufgetreten:");
        e.printStackTrace();
      }
      //die Threads beginnen mit dem Training
      beginTime = millis();

      //die Threads beginnen mit dem erstellen von Beispielen
      if (testExamples > 0)
        consoleText.add("Erstelle Testbeispiele...");

      //solange noch Trainingsbeispiele erstellt werden
      while (generatedTrainExamples != trainExamples) {
        int created = 0;
        //ob alle Threads fertig sind
        for (int i=0; i < threads.length; i++) {
          if (threads[i].created)
            created++;
        }

        //falls etwas schief gegangen ist und die Threads "fertig" sind aber noch einige Beispiele fehlen
        if (created == threadCount && generatedTrainExamples != trainExamples)
          for (int i = generatedTrainExamples; i < trainExamples; i++) {

            //if (!F.array_null(trainData[i])) continue;

            if (loadExamples && i < examples.length/(trainExampleData/7))
              loadExample(i);
            else
              trainData[i] = F.createNumber(charset[i%charset.length]);

            labels[i] = i%charset.length;
            generatedTrainExamples++;
            if (!loadExamples)
              consoleText.set(examplesTextIndex, "created " + generatedTrainExamples + "/" + trainExamples + " examples");
            else
              consoleText.set(examplesTextIndex, "loaded " + generatedTrainExamples + "/" + trainExamples + " examples");
          }
      }

      //große Ressourcen löschen die nicht mehr gebraucht werden
      if (!saveExamples) {
        examples = null;
        System.gc();
      }
      //der Fehler wird nie 200% sein, es ist also ein Signal dass das Training unterbrochen wurde
      for (int i=0; i < failure.length; i++)
        failure[i] = 2;

      if (saveExamples)
        saveExamples();
    }

    if (!train)
      loadWeightsLayers();

    for (int i = hiddenLayers.length-1; i >= 0; i--) {
      //wenn es der erste Layer ist
      if (i == 0)
        //der erste Hidden-Layer bekommt die Trainingsbeispiele
        hiddenLayers[i].createWeights(trainExampleData);
      else
        //so viele Inputs wie der Layer davor Neuronen hat
        hiddenLayers[i].createWeights(hiddenLayers[i-1].hiddenNs.length);
    }

    if (loadWeights) {
      loadWeights();
      consoleText.add("weights are loaded");
    } else {
      setWeightsRandom();
      consoleText.add("weights set");
    }

    int size = 0;
    for (int i = 0; i < hiddenLayers.length; i++) {
      HiddenN[] a = hiddenLayers[i].hiddenNs;
      if (a.length > size)
        size = a.length;
    }

    //wie viele Neuronen hat die größte Schicht
    int deltaListSize = 0;
    for (int i=0; i < hiddenLayers.length; i++)
      if (hiddenLayers[i].hiddenNs.length > deltaListSize)
        deltaListSize = hiddenLayers[i].hiddenNs.length;

    if (outL.outNs.length > deltaListSize)
      deltaListSize = outL.outNs.length;

    deltaList = new float[deltaListSize];
    ergebnis = new float[outL.outNs.length];
    outputsH = new float [hiddenLayers.length][];
    for (int i = 0; i < outputsH.length; i++)
      outputsH[i] = new float[hiddenLayers[i].hiddenNs.length];
  }


  void feedForward(float[] input) {

    for (int j = 0; j < hiddenLayers.length; j++) {
      for (int i = 0; i < hiddenLayers[j].hiddenNs.length; i++)
        outputsH[j][i] = hiddenLayers[j].hiddenNs[i].function[0].f(
          hiddenLayers[j].hiddenNs[i].feedForward(input));

      //0 da alle die gleich Aktivierungsfunktion haben
      if (hiddenLayers[j].hiddenNs[0].function.equals(F.softmax))
        //softmax ist speziell und braucht daher eine spezielle Behandlung
        F.softmax(outputsH[j]);

      input = outputsH[j].clone();
    }

    for (int i = 0; i < outL.outNs.length; i++)
      ergebnis[i] = outL.outNs[i].function[0].f(
        outL.outNs[i].feedForward(input));

    //0 da alle die gleich Aktivierungsfunktion haben
    if (outL.outNs[0].function.equals(F.softmax))
      //softmax ist speziell und braucht daher eine spezielle Behandlung
      F.softmax(ergebnis);

    consoleText.add("--Ergebnis--");
    for (int i = 0; i < ergebnis.length; i++)
      consoleText.add(floor(ergebnis[i]*100) + " % eine " + charset[i]);

    consoleText.add("-----------\n" + charset[int(F.max_pool_array(ergebnis))]);
  }

  float[] PyTorchForward(PImage pic) {

    String args = "";

    pic.resize(28, 28);
    //remove gray
    pic.loadPixels();
    for (int i = 0; i < pic.pixels.length; i++) {
      if (pic.pixels[i] != color(255))
        pic.pixels[i] = color(0);
    }
    pic.updatePixels();


    pic.loadPixels();
    for (int i = 0; i < pic.pixels.length; i++)
      args += int(byte(pic.pixels[i]));

    //in python pillow ist 0 == schwarz, 1 == weiß, dazwischen grau
    args = args.replace("255", "1");

    try {

      String dataPath = loadFile("digit.txt");
      String fileName = "PyTorch-AI";


      PrintWriter w = createWriter(dataPath);
      w.print(args);
      w.flush();
      w.close();

      Process process;
      if (PyTorch_py) {
        // Windows
        if (slash == '\\')
          process = Runtime.getRuntime().exec("python "  + loadFile(fileName) + ".py " + loadFile("weights.pth") + " " + dataPath);
        else
          process = Runtime.getRuntime().exec("python3 "  + loadFile(fileName) + ".py " + loadFile("weights.pth") + " " + dataPath);
      } else
        process = Runtime.getRuntime().exec(loadFile(fileName) + " " + loadFile("traced_digit_model.pt") + " " + dataPath);

      BufferedReader pyTorchOutput = new BufferedReader(new java.io.InputStreamReader(process.getInputStream(), "UTF-8"));
      //BufferedReader pyTorchError = new BufferedReader(new java.io.InputStreamReader(process.getErrorStream()));
      //String s = "";

      //while ((s = pyTorchError.readLine()) != null) {
      //  println(s);
      //}

      String outputLine = pyTorchOutput.readLine();
      pyTorchOutput.close();

      String[] outputs = outputLine.split(" ");
      // falls irgendwelche Wörter ausgegeben wurden
      ArrayList<String> filtered = F.filterNumerics(outputs);

      float[] floatOutputs = new float[filtered.size()];
      for (int i = 0; i < floatOutputs.length; i++)
        floatOutputs[i] = float(filtered.get(i));

      println("PyTorch result: " + charset[F.max_pool_array(floatOutputs)]);

      return floatOutputs;
    }
    catch(Exception e) {
      e.printStackTrace();
      println("Die PyTorch AI ist nicht installiert worden.");
      return null;
    }
  }

  void test() {

    consoleText.add("testing...");
    if (loadExamples)
      examples = loadBytes(loadFile("examples.txt"));

    if (examples.length == 0)
      loadExamples = false;

    //falls noch ein Beispiel fehlt, soll es erstellt werden
    for (int i = generatedTestExamples; i < testData.length; i++)
      if (!loadExamples || i >= testData.length)
        testData[i] = F.createNumber(charset[i%charset.length]);
      else {

        //ein Trainingsbeispiel  (examples.length*7)/trainExampleData
        for (int j=0; j < trainExampleData/7; j++) {
          String bits = F.Bytes2Bits(examples[(i*trainExampleData/7)+j]);
          for (int k = 0; k < 7; k++)
            //den char in einen byte convertieren
            testData[i][j*7+k] = byte(int(str(bits.charAt(k))));
        }
      }

    int errors = 0;
    float[] input;

    for (int t = 0; t < testData.length; t++) {
      input = float(testData[t]);

      for (int j = 0; j < hiddenLayers.length; j++) {
        for (int i = 0; i < hiddenLayers[j].hiddenNs.length; i++)
          outputsH[j][i] = hiddenLayers[j].hiddenNs[i].function[0].f(
            hiddenLayers[j].hiddenNs[i].feedForward(input));

        //0 da alle die gleich Aktivierungsfunktion haben
        if (hiddenLayers[j].hiddenNs[0].function.equals(F.softmax))
          //softmax ist speziell und braucht daher eine spezielle Behandlung
          F.softmax(outputsH[j]);

        input = outputsH[j].clone();
      }
      for (int i = 0; i < outL.outNs.length; i++)
        ergebnis[i]   = outL.outNs[i].function[0].f(
          outL.outNs[i].feedForward(input));

      //0 da alle die gleich Aktivierungsfunktion haben
      if (outL.outNs[0].function.equals(F.softmax))
        //softmax ist speziell und braucht daher eine spezielle Behandlung
        F.softmax(ergebnis);

      if (F.max_pool_array(ergebnis) != t%charset.length)
        errors++;
    }
    consoleText.add("Durchschnittlicher Fehler nach dem Training: " + errors/1.0/testData.length);
  }

  //Functional Interfaces, damit die Funktion auch als Lock benutzt werden kann (synchronized)
  ErrorFunction updateWeights = x -> {

    update = true;
    for (int i=0; i < threads.length; i++)
      while (!threads[i].waiting)
        delay(1);

    for (int j=0; j < hiddenLayers.length; j++)
      for (int i = 0; i < hiddenLayers[j].hiddenNs.length; i++)
        //das von den Threads berechnete Delta der Gewichte hinzufügen
        hiddenLayers[j].hiddenNs[i].applyBatch();

    for (int i = 0; i < outL.outNs.length; i++)
      outL.outNs[i].applyBatch();
    update = false;
    return 0;
  };

  ErrorFunction calcError = x -> {

    update = true;
    for (int i=0; i < threads.length; i++)
      while (!threads[i].waiting)
        delay(1);

    consoleText.add("Error of epoch " + currEpoch +": " + failures/1.0/currExample);
    failure[currEpoch] = failures/1.0/currExample;
    failures = 0;
    currExample = 0;
    currEpoch++;

    update = false;
    return 0;
  };

  void show() {
    if (spacePressed)
      return;

    background(0);
    if (scale != 1) {
      translate(width/2, height/2);
      scale(scale);
      translate(-width/2, -height/2);
    }
    //update
    nv.show();
    textSize(22);
    fill(255);
    textAlign(CORNER);
    text("Sekunden seit Start: " + millis()/1000, width-textWidth("Sekunden seit Start: " + millis()/1000)-20, height-30);
  }


  float n = 0;
  float factor = 0.1;

  void setWeightsNosie() {

    if (loadWeights) return;
    for (int k=0; k < hiddenLayers.length; k++) {
      //reset hiddenWeights with noise
      for (int j = 0; j < hiddenLayers[k].hiddenNs.length; j++) {
        for (int i = 0; i < hiddenLayers[k].hiddenNs[j].weights.length; i++) {
          hiddenLayers[k].hiddenNs[j].weights[i] = map(noise(n), 0, 1, -weigthsValue, weigthsValue);
          n += factor;
        }
        hiddenLayers[k].hiddenNs[j].bias = map(noise(n), 0, 1, -weigthsValue, weigthsValue);
        n += factor;
      }
    }

    for (int j = 0; j < outL.outNs.length; j++) {//reset outWeights mit noise
      for (int i = 0; i < outL.outNs[j].weightsOH.length; i++) {
        outL.outNs[j].weightsOH[i] = map(noise(n), 0, 1, -weigthsValue, weigthsValue);
        n += factor;
      }
      outL.outNs[j].bias = map(noise(n), 0, 1, -weigthsValue, weigthsValue);
      n += factor;
    }

    for (int i=0; i < hiddenLayers.length; i++) {//reset momentum für hidden
      for (int j=0; j <  hiddenLayers[i].hiddenNs.length; j++) {
        hiddenLayers[i].hiddenNs[j].momentum = 0;
      }
    }
    for (int i=0; i < outL.outNs.length; i++) {//reset momentum für output
      outL.outNs[i].momentum = 0;
    }
  }

  void setWeightsRandom() {

    for (int k=0; k < hiddenLayers.length; k++) {
      //reset hiddenWeights with noise
      for (int j = 0; j < hiddenLayers[k].hiddenNs.length; j++) {
        for (int i = 0; i < hiddenLayers[k].hiddenNs[j].weights.length; i++)
          hiddenLayers[k].hiddenNs[j].weights[i] = random(-weigthsValue, weigthsValue);

        hiddenLayers[k].hiddenNs[j].bias =  random(-weigthsValue, weigthsValue);
      }
    }

    for (int j = 0; j < outL.outNs.length; j++) {//reset outWeights with noise
      for (int i = 0; i < outL.outNs[j].weightsOH.length; i++)
        outL.outNs[j].weightsOH[i] = random(-weigthsValue, weigthsValue);

      outL.outNs[j].bias =  random(-weigthsValue, weigthsValue);
    }

    for (int i=0; i < hiddenLayers.length; i++) //reset momentum for hidden
      for (int j=0; j <  hiddenLayers[i].hiddenNs.length; j++)
        hiddenLayers[i].hiddenNs[j].momentum = 0;

    for (int i=0; i < outL.outNs.length; i++) //reset momentum für output
      outL.outNs[i].momentum = 0;
  }

  void saveWeights() {

    PrintWriter w = createWriter(loadFile("weights.txt"));

    for (int i = 0; i < hiddenLayers.length; i++) {//für jeden Hiddenlayer
      for (int j = 0; j < hiddenLayers[i].hiddenNs.length; j++) {//für jedes Neuron
        for (int k = 0; k < hiddenLayers[i].hiddenNs[j].weights.length; k++) {//für jedes Gewicht
          w.println(hiddenLayers[i].hiddenNs[j].weights[k]);
        }
        w.println(hiddenLayers[i].hiddenNs[j].bias);
      }
    }

    for (int j = 0; j < outL.outNs.length; j++) {
      for (int k = 0; k < outL.outNs[j].weightsOH.length; k++) {
        w.println(outL.outNs[j].weightsOH[k]);
      }
      w.println(outL.outNs[j].bias);
    }
    w.println("---Info---");
    w.println(trainExampleData + " Inputs");
    for (int i = 0; i < hiddenLayers.length; i++)
      w.println("Hidden-Layer " + i + " hat " + hiddenLayers[i].hiddenNs.length +" Neuronen:" +
        F.getInstanceName(F, hiddenLayers[i].hiddenNs[0].function[0]));


    w.println(outL.outNs.length + " Output-Neuronen:" + F.getInstanceName(F, outL.outNs[0].function[0]));
    w.flush();
    w.close();
    println("save");
  }

  void loadWeights() {

    String[] weights = loadStrings(loadFile("weights.txt"));

    try {
      int iterator = 0;
      for (int i = 0; i < hiddenLayers.length; i++) {//für jeden Hiddenlayer
        for (int j = 0; j < hiddenLayers[i].hiddenNs.length; j++) {//für jedes Neuron
          for (int k = 0; k < hiddenLayers[i].hiddenNs[j].weights.length; k++) {//für jedes Gewicht
            hiddenLayers[i].hiddenNs[j].weights[k] = float(weights[iterator]);
            iterator++;
          }
          hiddenLayers[i].hiddenNs[j].bias = float(weights[iterator]);
          iterator++;
        }
      }

      for (int i = 0; i < outL.outNs.length; i++) {
        for (int j = 0; j < outL.outNs[i].weightsOH.length; j++) {
          outL.outNs[i].weightsOH[j] = float(weights[iterator]);
          iterator++;
        }
        outL.outNs[i].bias = float(weights[iterator]);
        iterator++;
      }
    }
    catch (Exception e) {
      consoleText.add("Die angegebenen Gewichte in der Datei weights.txt passen nicht zu den im Programm angegebenen Layern und ihren Neuronen.");
      consoleText.add("Eine Angabe für wie viele Layer und Neuronen die Gewichte gedacht sind findet sich am Ende der Datei weights.txt:");

      //index der Info
      int index = 0;
      for (int i = weights.length-1; i >= 0; i--)
        if (weights[i].equals("---Info---"))
          index = i;

      for (int i = index; i < weights.length; i++)
        consoleText.add(weights[i]);

      noLoop();
    }
  }

  void loadWeightsLayers() {

    String[] weights = loadStrings(loadFile("weights.txt"));
    //index der Info
    int index = 0;
    for (int i = weights.length-1; i >= 0; i--)
      if (weights[i].equals("---Info---"))
        index = i;

    /*
     Beispiel:
     ---Info---
     1600 Inputs
     Hidden-Layer 0 hat 12 Neuronen:relu
     Hidden-Layer 1 hat 10 Neuronen:relu
     13 Output-Neuronen:sigmoid
     */

    //skip das Unwichtige
    index += 2;
    hiddenLayers = new HiddenL[weights.length-(index+1)];
    Function[] f;
    try {

      for (int i = 0; i < hiddenLayers.length; i++) {
        f = (Function[]) F.getClass().getDeclaredField(split(weights[index+i], ':')[1]).get(F);
        int neurons = int(split(split(weights[index+i], "hat ")[1], ' ')[0]);
        hiddenLayers[i] = new HiddenL(neurons, f);
      }
      f = (Function[]) F.getClass().getDeclaredField(split(weights[weights.length-1], ':')[1]).get(F);
      //loss muss nicht aktualisiert werden, da nicht trainiert wird
      outL = new OutputLayer(charset.length, f, loss);
    }
    catch (NoSuchFieldException | IllegalAccessException e) {
      consoleText.add("Die in der Info von weigts.txt angegebene Funktion existiert nicht mehr.");
      noLoop();
    }
  }

  void saveExamples() {

    //wenn z.B. schon 200 gespeichert sind und trainExamples = 50 ist,
    //sollen die 150 übrig bleibenden nicht gelöscht werden
    if (loadExamples && trainExamples <= examples.length/(trainExampleData/7))
      return;

    PrintWriter w = createWriter(loadFile("examples.txt"));
    ArrayList<Character> content = new ArrayList<Character>();
    ArrayList<Character> unusedChars = new ArrayList<Character>();

    for (int i = 0; i < pow(2, 7); i++)
      unusedChars.add(char(i));


    //die Beispiele werden hier auf eine einfache Art und Weise kodiert.
    //Man könnte später noch bessere (und kompliziertere) Verfahren wie die Huffman-Kodierung
    for (int i=0; i < trainExamples; i++) {
      for (int j=0; j < trainExampleData; j += 7) {

        //sollte das Beispiel nicht schon gespeichert sein
        if (loadExamples && i*(trainExampleData/7)+trainExampleData/7 < examples.length) {

          for (int jindx=0; jindx < trainExampleData/7; jindx++) {
            // w.print(char(examples[i*(trainExampleData/7)+jindx]));
            char c = char(examples[i*(trainExampleData/7)+jindx]);
            content.add(c);
            //der char wird benutzt. Er gehört also nicht zu den unusedChars
            if (unusedChars.indexOf(c) != -1)
              unusedChars.remove(unusedChars.indexOf(c));
          }
          break;
        } else {
          //chars haben 0 bis einschließlich 65535 == 2^16. ASCII hat 0 bis einschließlich 127, also 2^7

          String b = "";
          for (int k = 0; k  < 7; k++)
            b += trainData[i][j+k];

          //w.print(char(F.bits2Bytes(b)));
          char c = char(F.bits2Bytes(b));
          content.add(c);
          //der char wird benutzt. Er gehört also nicht zu den unusedChars
          if (unusedChars.indexOf(c) != -1)
            unusedChars.remove(unusedChars.indexOf(c));
        }
      }
    }


    //char[] unusedCharsArray = new char[unusedChars.size()];
    //for (int i = 0; i < unusedCharsArray.length; i++)
    //  unusedCharsArray[i] = unusedChars.get(i);


    //weiteres Verkleinern der Beispiele. Bis jetzt um Faktor 7, jetzt nochmal min. 20
    // content = advancedComrpession(content, unusedCharsArray);

    // System.exit(0);

    for (int i = 0; i < content.size(); i++)
      w.print(content.get(i));

    w.flush();
    w.close();
  }

  ArrayList<Character> advancedComrpession(ArrayList<Character> data, char[] unusedChars) {

    println("unusedchars:", unusedChars.length);

    return new Object() {

      ArrayList<Character> run(ArrayList<Character> data, char[] unusedChars) {

        //z.B. e8\n die sehr häufig auftreten und mit einem unusedChar ersetzt werden können (kürzer)
        ArrayList<char[]> combinations = new ArrayList<char[]>();
        //wie oft eine solche Kombination auftritt
        ArrayList<Integer> anzahl = new ArrayList<Integer>();
        // die gerade betrachtete Kombination
        char[] charPackage;
        // um das Kompimieren rückgängig zu machen
        String encodeInfo = "";


        //der Prozess wird wiederhohlt bis für alle unusedChars eine Kombi gefunden wurde
        for (int unusedChar = 0; unusedChar < unusedChars.length; unusedChar++) {

          // alle möglichen Kombis herrausfinden
          for (int range = 2; range < 50; range++) {
            for (int i = 0; i < data.size()-range; i += range) {

              charPackage = getPackage(i, range, data);
              //wenn diese Kombi schon mal gespeichert wurde
              if (contains(combinations, charPackage)) {
                int iindex = index(combinations, charPackage);
                anzahl.set(iindex, anzahl.get(iindex)+1);
              } else {
                combinations.add(charPackage);
                anzahl.add(1);
              }
            }
          }

          int bestIndex = 0;
          char[] bestTempCombi = combinations.get(bestIndex);

          //die beste Kombination ziehen
          for (int j = 1; j < combinations.size(); j++) {
            // wie viel damit abgekürzt wird
            if (anzahl.get(bestIndex) * combinations.get(bestIndex).length < anzahl.get(j) * combinations.get(j).length) {
              bestTempCombi = combinations.get(j).clone();
              bestIndex = j;
            }
          }

          if (anzahl.get(bestIndex) * combinations.get(bestIndex).length < 105) {
            anzahl.clear();
            combinations.clear();
            bestTempCombi = null;
            println("not enough");
            continue;
          }
          // printArray(anzahl);
          //System.exit(0);

          println("datenlänge:", data.size());
          // nachdem die beste Kombi gefunden wurde, wird diese angewendet
          data = comprimise(data, bestTempCombi, unusedChars[unusedChar]);
          println("datenlänge:", data.size(), '\n');


          encodeInfo += unusedChars[unusedChar];
          for (int cha = 0; cha < bestTempCombi.length; cha++)
            encodeInfo += bestTempCombi[cha];

          anzahl.clear();
          combinations.clear();
          bestTempCombi = null;
        }
        return data;
      }

      ArrayList<Character> comprimise(ArrayList<Character> data, char[] bestCombi, char unusedChar) {

        char[] charPackage;

        for (int i=0; i < bestCombi.length; i++) {
          print(int(bestCombi[i]) + " ");
        }
        println();

        for (int i = 0; i < data.size()-bestCombi.length; i += bestCombi.length) {
          charPackage = getPackage(i, bestCombi.length, data);
          if (equal(charPackage, bestCombi)) {
            data.set(i, unusedChar);
            for (int j = 1; j < bestCombi.length; j++) {
              data.remove(i+j);
            }
          }
        }
        println("contains", contains2(data, bestCombi));
        return data;
      }

      boolean equal(char[] arr1, char[] arr2) {

        if (arr1.length != arr2.length)
          return false;

        for (int i = 0; i < arr1.length; i++)
          if (arr1[i] != arr2[i]) {
            return false;
          }
        return true;
      }

      char[] getPackage(int index, int size, ArrayList<Character> data) {

        char[] charPackage = new char[size];

        for (int i = 0; i < size; i++)
          charPackage[i] = data.get(index+i);

        return charPackage;
      }

      boolean contains(ArrayList<char[]> list, char[] array) {

        // sollte ein Element nicht passen, geht es auf false
        boolean sameElement = true;

        for (int i = 0; i < list.size(); i++) {
          for (int j = 0; j < list.get(i).length; j++) {
            if (list.get(i)[j] != array[j]) {
              sameElement = false;
              break;
            }
          }
          if (sameElement)
            return true;
          else
            // sollte ein Element nicht passen, geht es auf false
            sameElement = true;
        }
        return false;
      }

      boolean contains2(ArrayList<Character> list, char[] array) {

        char[] charPackage;

        for (int i = 0; i < list.size()-array.length; i += array.length) {
          charPackage = getPackage(i, array.length, list);
          if (equal(charPackage, array))
            return true;
        }
        return false;
      }

      int index(ArrayList<char[]> list, char[] array) {

        boolean isElement = true;

        for (int i = 0; i < list.size(); i++) {
          for (int j = 0; j < list.get(i).length; j++)
            if (list.get(i)[j] != array[j]) {
              isElement = false;
              break;
            }

          if (isElement)
            return i;
          else
            isElement = true;
        }
        return -1;
      }
    }
    .run(data, unusedChars);
  }



  void loadExample(int index) {

    //ein Trainingsbeispiel  (examples.length*7)/trainExampleData
    for (int j=0; j < trainExampleData/7; j++) {
      String bits = F.Bytes2Bits(examples[(index*trainExampleData/7)+j]);
      for (int k = 0; k < 7; k++)
        //den char in einen byte convertieren
        trainData[index][j*7+k] = byte(int(str(bits.charAt(k))));
    }
  }

  //lädet ein Bild aus den Trainingsdaten. Vor allem zum debuggen
  PImage loadExampleAsImage(int index) {

    loadExample(index);
    byte[] copy = trainData[index].clone();
    PImage image = createImage(drawWindowSize/kernel_size, drawWindowSize/kernel_size, RGB);

    image.loadPixels();
    for (int i = 0; i < copy.length; i++)
      if (copy[i] == 1)
        image.pixels[i] = color(255);
      else
        image.pixels[i] = color(0);

    image.updatePixels();
    return image;
  }
}
