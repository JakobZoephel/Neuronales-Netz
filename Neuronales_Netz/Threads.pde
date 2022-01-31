//Index von arraylist wo "loading x/y examples..." ist
int examplesTextIndex = -1;

class CalculatingThread extends Thread {

  float[] deltaList, deltaListPuffer, ergebnis, desired;
  int label, index;
  byte[] batch = new byte[trainExampleData];
  boolean waiting = false;

  //schon alle Trainigsbeispiele generiert
  boolean created = false;
  int id;
  float[] netzinputO;
  float[][] netzinputH, outputsH;
  //welche Beispiele schon trainiert wurden
  boolean[] trained;

  CalculatingThread(int _id) {
    int deltaListSize = 0;
    for (int i=0; i < hiddenLayers.length; i++)
      if (hiddenLayers[i].hiddenNs.length > deltaListSize)deltaListSize = hiddenLayers[i].hiddenNs.length;

    if (outL.outNs.length > deltaListSize)
      deltaListSize = outL.outNs.length;

    deltaList = new float[deltaListSize];
    deltaListPuffer = new float[deltaListSize];
    ergebnis = new float[outL.outNs.length];
    netzinputO = new float[ergebnis.length];

    outputsH = new float [hiddenLayers.length][];
    netzinputH = new float[hiddenLayers.length][];

    trained = new boolean[trainData.length];
    for (int i = 0; i < trained.length; i++)
      trained[i] = false;

    for (int i = 0; i < outputsH.length; i++) {
      outputsH[i] = new float[hiddenLayers[i].hiddenNs.length];
      netzinputH[i] = new float[outputsH[i].length];
    }

    this.id = _id;
  }

  @Override
    void run() {

    //die Testbeispiele erstellen
    int exampleBegin = (testExamples/threadCount)*id;
    for (int i = exampleBegin; i < exampleBegin + testExamples/threadCount; i++) {
      //wenn schon mal erstellt
      if (!F.array_null(testData[i])) continue;

      testData[i] = F.createNumber(charset[i%charset.length]);
      synchronized(generatedTestExamples) {
        generatedTestExamples++;
      }
    }

    //die Trainingsbeispiele erstellen/laden
    exampleBegin = (trainExamples/threadCount)*id;
    for (int i = exampleBegin; i < exampleBegin + trainExamples/threadCount; i++) {
      //wenn schon mal erstellt
      if (!F.array_null(trainData[i]))continue;

      if (loadExamples && i < examples.length/(trainExampleData/7))
        F.loadExample(i);
      else
        trainData[i] = F.createNumber(charset[i%charset.length]);


      labels[i] = i%charset.length;
      synchronized(generatedTrainExamples) {
        generatedTrainExamples++;
      }
      //wenn noch nicht definiert
      if (examplesTextIndex == -1)
        examplesTextIndex = consoleText.size()-1;


      if (!loadExamples || generatedTrainExamples > F.savedExamples())
        consoleText.set(examplesTextIndex, "created " + generatedTrainExamples + "/" + trainExamples + " train-examples");
      else
        consoleText.set(examplesTextIndex, "loaded " + generatedTrainExamples + "/" + trainExamples + " train-examples");
    }

    created = true;
    //warte bis das Training beginnt
    while (!start && !kill)
      delay(1);


    while (!kill && currEpoch < epochs && millis()/1000 < 60*timeOut) {

      //wenn etwas gerade geupdated wird (Fehler oder Gewichte)
      while (update)
        waiting = true;
      if (lm == null)
        println("hmmm...");
      //das Training geht zu schnell als dass der Main-Thread übersicht behalten würde
      if (currExample % batchSize == 0) {
        waiting = true;
        synchronized(lm.updateWeights) {
          //falls ein anderer Thread schon damit fertig ist
          if (currExample % batchSize == 0)
            lm.updateWeights.f();
        }
      }

      //neue Epoche
      if (currExample >= trainExamples && currEpoch < failure.length) {
        waiting = true;
        for (int i = 0; i < trained.length; i++)
          trained[i] = false;

        synchronized(lm.calcError) {
          //falls ein anderer Thread schon damit fertig ist
          if (currExample >= trainExamples && currEpoch < failure.length)
            lm.calcError.f();
        }
      }

      while (update)
        waiting = true;

      waiting = false;
      loadBatches();
      feedForward(float(batch), label);
      backpropagation(label, index);
      currExample++;
    }
    //falls ein Thread zum Schluss noch was updated
    waiting = true;
  }

  void loadBatches() {

    index = floor(random(trainData.length));

    //wenn dieses Beispiel in dieser Epoche bereits trainiert wurde
    if (trained[index])
      // finde das nächste nicht genutzte (rechts)
      for (int i = index+1; i < trainData.length; i++)
        if (!trained[i])
          index = i;

    if (trained[index])
      // finde das nächste nicht genutzte (links)
      for (int i = index-1; i >= 0; i--)
        if (!trained[i])
          index = i;

    //wurde schon einmal geladen
    trained[index] = true;


    batch = trainData[index];
    label = labels[index];
  }

  float netzinput_hidden;
  float netzinput_out;

  void feedForward(float[] input, int label) {
    for (int j = 0; j < hiddenLayers.length; j++) {
      for (int i = 0; i < hiddenLayers[j].hiddenNs.length; i++) {
        netzinput_hidden            = hiddenLayers[j].hiddenNs[i].feedForward(input);
        //der output eines Neurons ist y von der Aktivierungsfunktion (f), wenn x der netzinput ist
        outputsH[j][i] = hiddenLayers[j].hiddenNs[i].function[0].f(netzinput_hidden);
        netzinputH[j][i] = netzinput_hidden;//für backpropagation
      }
      //0 da alle die gleich Aktivierungsfunktion haben
      if (hiddenLayers[j].hiddenNs[0].function.equals(F.softmax))
        //softmax ist speziell und braucht daher eine spezielle Behandlung
        //es ist zwar sowieso call by reference, ich finde die Schreibweise aber besser
        outputsH[j] = F.softmax(outputsH[j]);

      input = outputsH[j].clone();
    }
    for (int i = 0; i < outL.outNs.length; i++) {
      netzinput_out = outL.outNs[i].feedForward(input);
      //der output eines Neurons ist y von der Aktivierungsfunktion (f), wenn x der netzinput ist
      ergebnis[i]   = outL.outNs[i].function[0].f(netzinput_out);
      netzinputO[i] = netzinput_out;//für backpropagation
    }
    //0 da alle die gleich Aktivierungsfunktion haben
    if (outL.outNs[0].function.equals(F.softmax))
      //softmax ist speziell und braucht daher eine spezielle Behandlung
      ergebnis = F.softmax(ergebnis);

    if (F.max_pool_array(ergebnis) != label)
      lm.failures++;
  }

  float[] aj;//output der Neuronen des Layers davor
  void backpropagation(int label, int inputNumber) {

    if (outL.outNs[0].function.equals(F.softmax))
      netzinputO = F.softmaxAbleitung(netzinputO);

    for (int i = 0; i < outL.outNs.length; i++) {//backpropagate out
      //die deltaList wird für die backpropagation der nächsten Schicht gebraucht
      deltaList[i] = outL.outNs[i].backward(i, label, ergebnis[i], netzinputO[i], outputsH[hiddenLayers.length-1]);
    }

    //backpropagate hidden
    for (int j = hiddenLayers.length-1; j >= 0; j--) {
      //wenn der Layer nicht nach Input kommt
      if (j != 0)  aj = outputsH[j-1].clone();
      //wenn derLayer nach Input kommt
      else  aj = float(trainData[inputNumber].clone());

      if (hiddenLayers[j].hiddenNs[0].function.equals(F.softmax))
        netzinputH[j] = F.softmaxAbleitung(netzinputH[j]);

      for (int i = 0; i < hiddenLayers[j].hiddenNs.length; i++) {
        deltaListPuffer[i] = hiddenLayers[j].hiddenNs[i].backward(i, deltaList, netzinputH[j][i], aj, j);
      }//                        int neuronNumber, float[] deltaList, float netzinput, float[] aj, int layerNumber
      deltaList = deltaListPuffer.clone();
    }
  }
}
