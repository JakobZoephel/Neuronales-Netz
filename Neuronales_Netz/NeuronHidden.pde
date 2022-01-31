class HiddenL { //<>//

  HiddenN[] hiddenNs;
  HiddenL(int numberOfPerceptrons, Function[] func) {
    //Array aus Neuronen, die die Schicht hat
    hiddenNs = new HiddenN[numberOfPerceptrons];
    for (int i=0; i < numberOfPerceptrons; i++)
      hiddenNs[i] = new HiddenN(func);
  }

  void createWeights(int numberOfWeigths) {
    for (int i=0; i < hiddenNs.length; i++) {
      hiddenNs[i].createWeights(numberOfWeigths);
    }
  }
}

class HiddenN extends Functions {

  float[] weights, meanweights;
  float[] summe = new float[2];
  float bias, meanBias, loss, sum, momentum;
  Function[] function;

  HiddenN(Function[] function_) {
    function = function_;
  }

  void createWeights(int numberOfWeigths) {
    weights= new float[numberOfWeigths];
    meanweights= new float[numberOfWeigths];
  }

  float feedForward(float[] input) {
    
    sum = 0;
    for (int i = 0; i < weights.length; i++) {
      sum += weights[i] * input[i];
    }
    sum += bias;
    return sum;
  }

  //aj sind die Outputs der Neurons aus der Schicht davor, hier die Input-schicht
  float backward(int neuronNumber, float[] deltaList, float netzinput, float[] aj, int layerNumber) {
    
    loss = 0;
    //wenn es die letzte Schicht ist
    if (layerNumber == hiddenLayers.length-1) {
      for (int i = 0; i < outL.outNs.length; i++) {
        //deltaList ist ein Array aus dem loss der einzelnen Outputneuronen
        loss += deltaList[i] * outL.outNs[i].weightsOH[neuronNumber];
      }
    } else {
      for (int i = 0; i < hiddenLayers[layerNumber+1].hiddenNs.length; i++) {
        loss += deltaList[i] * hiddenLayers[layerNumber+1].hiddenNs[i].weights[neuronNumber];
      }
    }
    loss *= function[1].f(netzinput);
    for (int i = 0; i < weights.length; i++) {
      meanweights[i] += loss * lr * aj[i];
    }
    meanBias += lr * loss;

    return loss;
  }
  
  void reset_own_weights() {
    for (int i=0; i < weights.length; i++) weights[i] = random(-weigthsValue, weigthsValue);
  }

  void applyBatch() {
    
    for (int i = 0; i < weights.length; i++) {
      momentum += meanweights[i];
      //der Betrag der Gewichtsänderung hängt damit auch davon ab, wie hoch er in den Durchläufen davor war. Dieser Einfluss nimmt aber ab.
      momentum *= momentumWeakness;
      weights[i] += meanweights[i] + momentum;
      meanweights[i] = 0;
    }
    bias += meanBias + momentum;
    meanBias = 0;
  }
}
