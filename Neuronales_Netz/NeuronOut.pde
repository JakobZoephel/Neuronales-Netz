class OutputLayer {

  OutN[] outNs;

  OutputLayer(int numberOfPerceptrons, Function[] function_, ErrorFunction error_) {

    outNs = new OutN[numberOfPerceptrons];
    for (int i = 0; i < outNs.length; i++) {
      outNs[i] = new OutN(function_, error_);
    }
  }
}

class OutN extends Functions {

  float[] weightsOH, meanWeightsOH;// OH da es die Verbindung zwischen -O-utput und -H-idden Layer ist
  float[] summe = new float[2];
  float bias, meanBias, sum, loss, desired, momentum;
  Function[] function;
  ErrorFunction error;

  OutN(Function[] function_, ErrorFunction error_) {
    this.function = function_;
    this.error = error_;
    weightsOH = new float[hiddenLayers[hiddenLayers.length-1].hiddenNs.length];
    meanWeightsOH= new float[weightsOH.length];
  }

  float feedForward(float[] input) {
    
    sum = 0;
    for (int i = 0; i < weightsOH.length; i++) {
      sum += weightsOH[i] * input[i];
    }
    sum += bias;
    return sum;
  }

  //aj sind die Outputs der Neurons aus der Schicht davor, hier die Hidden-schicht
  float backward(int numberOfNeuron, int label, float ist, float netzinput, float[] aj) {
    
    if (numberOfNeuron == label)
      desired = 1;
    else
      desired = 0;

    loss = error.f(ist, desired) * function[1].f(netzinput);

    for (int i = 0; i < weightsOH.length; i++) {
      meanWeightsOH[i] += lr * loss * aj[i];
    }
    meanBias += lr * loss;
    return loss;
  }
  
  void reset_own_weights() {
    for (int i=0; i < weightsOH.length; i++)
      weightsOH[i] = random(-weigthsValue, weigthsValue);
  }

  void applyBatch() {
    
    for (int i = 0; i < weightsOH.length; i++) {
      momentum +=  meanWeightsOH[i];
      //der Betrag der Gewichtsänderung hängt damit auch davon ab, wie hoch er in den Durchläufen davor war. Dieser Einfluss nimmt aber ab.
      momentum *= momentumWeakness;
      weightsOH[i] += meanWeightsOH[i] + momentum;
      meanWeightsOH[i] = 0;
    }
    bias += meanBias + momentum;
    meanBias = 0;
  }
}
