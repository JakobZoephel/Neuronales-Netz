@FunctionalInterface
  public interface Function {

  float f (float x);
}

@FunctionalInterface
  public interface ErrorFunction {
  //einige Funktionen wie z.B. Fehlerfunktionen brauchen mehrere Variablen
  float f(float ... x);
}

class Functions {

  public Function[] relu = {
    //normale Funktion
    x -> x < 0 ?  0 : x,
    //Ableitung der Funktion
    x -> x < 0 ? 0 : 1
  };

  public Function[] sigmoid = {
    x -> Double.valueOf(1/(1+exp(-x))).floatValue(),
    x -> Double.valueOf(1/(1+exp(-x))).floatValue() *
    (1-Double.valueOf(1/(1+exp(-x))).floatValue())
  };

  public Function[] tanh  = {
    x -> (exp(x)-exp(-x))/(exp(x)+exp(-x)),
    x -> 1 - pow((exp(x)-exp(-x))/(exp(x)+exp(-x))-1, 2)
  };

  public Function[] softmax = {
    //das Ergebnis der Funtion wird erst im nachhinein berechnet.
    x -> x,
    x -> x
  };

  public float[] softmax(float[] outputs) {

    for (int i = 0; i < outputs.length; i++)
      outputs[i] = constrain(outputs[i], -30, 30);


    float sum = 0;
    //outptus sind in diesem Fall immer noch das Gleiche wie der netzinput
    for (int i=0; i < outputs.length; i++)
      // epx(88.7) == infinity
      // if (outputs[i] < 86)
      sum += exp(outputs[i]);

    //for (int i=0; i < outputs.length; i++)
    //  if (outputs[i] != outputs[i]) {
    //    printArray(lastOutputs);
    //    printArray(outputs);
    //    println(1);
    //    //System.exit(0);
    //  }

    if (sum == 0) {
      //  sum = 1;
      println("no valid sum");
    }

    for (int i=0; i < outputs.length; i++) {
      float result = exp(outputs[i])/sum;
      if (result != Float.POSITIVE_INFINITY && result != Float.NEGATIVE_INFINITY && result == result && result < 10 && result > -10)
        outputs[i] = exp(outputs[i])/sum;
    }

    return outputs;
  }

  public float[] softmaxAbleitung(float[] netzinput) {

    netzinput = softmax(netzinput);
    for (int i=0; i < netzinput.length; i++)
      netzinput[i] = netzinput[i]-pow(netzinput[i], 2);
    return netzinput;
  }


  //bei den Fehlerfunktionen nur eine,
  //da wir nur die Ableitung brauchen
  //x[0] = ist, x[1] = desired
  public ErrorFunction MSE = x -> x[0] - x[1];

  public ErrorFunction XEntropy = x -> {
    float returnValue = x[1] * Double.valueOf(Math.log(x[0])).floatValue();
    if (returnValue == Float.POSITIVE_INFINITY)
      return 100;
    else if (returnValue == Float.NEGATIVE_INFINITY)
      return -100;
    //wenn es NaN ist, ist das Ergebnis richtig
    else if (returnValue != returnValue)
      return 0;
    return returnValue;
  };

  // ErrorFunction BinaryXEntropy = (x) -> -1 * (-x[1] * Double.valueOf(Math.log(x[0])).floatValue() + (1-x[1]) * Double.valueOf(Math.log(1-x[0])).floatValue());
  public ErrorFunction BinaryXEntropy = x -> {
    float returnValue = -1 * (-x[1] * Double.valueOf(Math.log(x[0])).floatValue() + (1-x[1]) * Double.valueOf(Math.log(1-x[0])).floatValue());
    if (returnValue == Float.POSITIVE_INFINITY)
      return 100;
    else if (returnValue == Float.NEGATIVE_INFINITY)
      return -100;
    //wenn es NaN ist, ist das Ergebnis richtig
    else if (returnValue != returnValue)
      return 0;
    return returnValue;
  };

  //viel Platz für weitere Funktionen, die man wenn man sie braucht hinzufügen kann



  String Bytes2Bits(byte b) {

    String bits =  String.format("%8s", Integer.toBinaryString(b & 0xFF))
      .replace(' ', '0');
    return bits.substring(1, bits.length());
  }

  byte bits2Bytes(String bitString) {

    byte ret = 0;
    for (int i = 0; i < bitString.length(); i++)
      if (bitString.charAt(i) == '1')
        ret |= 1 << (bitString.length()-1-i);

    return ret;
  }

  <T> void insertElement(ArrayList<T> list, T object, int index) {

    //erstmal nur damit ein weiteres Element da ist
    list.add(object);
    for (int i = list.size()-1; i > index+1; i--)
      list.set(i, list.get(i-1));

    list.set(index+1, object);
  }

  //holdingClass ist das Object in dem das gesuchte Field ist
  String getInstanceName(Object holdingObject, ErrorFunction f) {

    //extract index des Fields
    int number = int(split(split(f.toString(), "Lambda$")[1], '/')[0]);
    /*uns interessiert nicht welchen Index das Field hat wenn man
     die publics von main berücksichtigt */
    number -= getLambdaIndex();

    //die Aktivierungsfunktionen sollen nicht berücksichtigt werden
    number -= numberOfLambdaArrays(holdingObject);

    //extrahiere den einfachen Namen
    return split(holdingObject.getClass().getFields()[number].toString(), '.')[1];
  }

  int numberOfLambdaArrays(Object holdingObject) {

    Field[] fields = holdingObject.getClass().getFields();
    //Anzahl der gefundenen Arrays
    int arrays = 0;

    for (int i = 0; i < fields.length; i++)
      for (int j = 0; j < fields[i].toString().length(); j++)
        // wenn der String ein '[' enthält ist er ein Array
        if (fields[i].toString().charAt(j) == '[') {
          arrays++;
          break;
        }
    return arrays;
  }

  String getInstanceName(Object holdingObject, Function f) {

    //extract index des Fields
    int number = int(split(split(f.toString(), "Lambda$")[1], '/')[0]);
    //uns interessiert nicht welchen Index das Field hat wenn man
    //die publics von main berücksichtigt
    number -= getLambdaIndex();
    //in einem Array sind zwei Funktionen
    number /= 2;
    //Der Outputlayer bekommt am Anfang eine Funktion
    number--;
    //extrahiere den einfachen Namen
    return split(holdingObject.getClass().getFields()[number].toString(), '.')[1];
  }

  int getLambdaIndex() {

    Field[] fields = main.getClass().getFields();
    //nach wie vielen Variablen die von Functions anfangen
    int index = 0;

    for (int i = 0; i < fields.length; i++) {

      //wenn die Variable nich aus dieser Klasse stammt
      if (match(fields[i].toString(), main.getClass().getSimpleName()) == null) {
        index = --i;
        break;
      }
    }
    //für loss was am Anfang initialisiert wird
    index--;
    //für die HiddenLayer Funktionen
    index -= hiddenLayers.length;
    return index;
  }

  String getValue(String name) {

    for (int i = 0; i < data.length; i++) {
      if (split(data[i], ":::")[0].equals(name))
        return split(data[i], ":::")[1];
    }
    return "";
  }

  boolean availibleFunction (Object c, String s) {
    Field[] fields = c.getClass().getDeclaredFields();
    for (int i = 0; i < fields.length; i++)
      if (fields[i].getName().equals(s))
        return true;

    return false;
  }

  int savedExamples() {

      if (examples == null)
        examples = loadBytes(loadFile("examples.txt"));
      return examples.length/(trainExampleData/7);
  }

  float max_pool_array(float[] array) {
    float a = max(array);
    for (int i=0; i < array.length; i++)
      if (array[i] == a)
        return i;

    //irgendein Fehler, z.B. NaN
    return -1;
  }

  boolean array_null(byte[] array) {
    for (int i = 0; i < array.length; i++)
      if (array[i] != 0)
        return false;

    return true;
  }

  byte[] createNumber(char desired) {

    //100 Pixel als Puffer, da die Zahlen in y oft größer sind als drawWindowSize
    PGraphics picture = createGraphics(drawWindowSize, drawWindowSize+100);
    picture.beginDraw();
    picture.textAlign(CENTER, CENTER);
    picture.background(255);
    picture.fill(0);
    picture.stroke(0);
    int size = (int)random(420, 444);
    picture.textSize(size);//400
    PFont font = createFont(fontNames[floor(random(fontNames.length))], size, false, charset);
    picture.textFont(font);

    picture.text(desired, picture.width/2, (picture.height-100)/2);
    picture = F.cut(picture);
    picture = F.pooling(picture, kernel_size, (x) -> max(x));
    picture = F.blackWhite(picture);
    picture.endDraw();

    return byte(F.graphicsToVector(picture));
  }

  void loadExample(int index) {
    //ein Trainingsbeispiel  (examples.length*7)/trainExampleData
    for (int j = 0; j < trainExampleData/7; j++) {
      String bits = Bytes2Bits(examples[index*(trainExampleData/7)+j]);
      for (int k = 0; k < 7; k++)
        //den char in einen byte convertieren
        trainData[index][j*7+k] = byte(int(str(bits.charAt(k))));
    }
  }

  boolean isColor(color c) {

    int amount = 20;
    int red = int(red(c));
    int green = int(green(c));
    int blue = int(blue(c));

    int mean = (red+green+blue)/3;

    //schwarze Tinte
    if (abs(red-mean) < amount && abs(green-mean) < amount && abs(blue-mean) < amount && red < 100)
      return true;

    //grauer Hintergrund
    if (abs(red-mean) < amount && abs(green-mean) < amount && abs(blue-mean) < amount)
      return false;

    //irgendeine Farbe
    return true;
  }


  int thickness(PImage img) {

    ArrayList<Integer> smallestList = new ArrayList<Integer>();

    int pixelCount;
    int index;

    int rand = 20;
    img.loadPixels();

    for (int y = rand; y < img.height-rand; y++) {
      //die Anzhal der Pixel in dieser Reihe
      pixelCount = 0;
      for (int x = 0; x < img.width; x++) {
        index = index1D(x, y, img);
        while (img.pixels[index] == color(0)) {
          pixelCount++;
          //wenn der Rand kommt, break;
          if (x+1 < img.width)
            x++;
          else
            break;
          index = index1D(x, y, img);
        }
        //wenn Pixel gefunden wurden und es weniger sind als zuvor
        if (pixelCount > 0 ) {
          if (pixelCount < height/4.5)
            smallestList.add(pixelCount);
          pixelCount = 0;
        }
      }
    }

    for (int x = rand; x < img.width-rand; x++) {
      //die Anzhal der Pixel in dieser Reihe
      pixelCount = 0;
      for (int y = 0; y < img.height; y++) {
        index = index1D(x, y, img);
        while (img.pixels[index] == color(0)) {
          pixelCount++;
          //wenn der Rand kommt, break;
          if (y+1 < img.height)
            y++;
          else
            break;
          index = index1D(x, y, img);
        }
        //wenn Pixel gefunden wurden und es weniger sind als zuvor
        if (pixelCount > 0 ) {
          if (pixelCount < height/4)
            smallestList.add(pixelCount);
          pixelCount = 0;
        }
      }
    }
    img.updatePixels();

    //for (int i = 1; i < smallestList.size()-1; i++) {
    //  int currValue = smallestList.get(i);
    //  if (abs(smallestList.get(i-1) - currValue) > 0 || abs(smallestList.get(i+1) - currValue)  > 0)
    //    smallestList.remove(i);
    //  //println("removing");
    //}


    int[] sortList = new int[smallestList.size()];
    for (int i = 0; i < smallestList.size(); i++)
      sortList[i] = smallestList.get(i);
    sortList = sort(sortList);


    //for (int i = 0; i < sortList.length-1; i++)
    //  if (sortList[i] == sortList[i+1])
    //    sortList[i] = -1;

    ArrayList<Integer> anzahl = new ArrayList<Integer>();
    ArrayList<Integer> type = new ArrayList<Integer>();

    for (int i = 0; i < sortList.length-1; i++)
      if (sortList[i] == sortList[i+1])
        if (type.indexOf(sortList[i]) != -1) {
          int valueIndex = type.indexOf(sortList[i]);
          anzahl.set(valueIndex, anzahl.get(valueIndex)+1);
        } else {
          anzahl.add(1);
          type.add(sortList[i]);
        }


    //for(int i = 1; i < type.size();i++){
    //    if (abs(type.get(i-1) - type.get(i)) < 5){
    //    anzahl.set(i, anzahl.get(i) + anzahl.get(i-1));
    //    anzahl.remove(anzahl.get(i-1));
    //    type.remove(anzahl.get(i-1));
    //    }
    //}

    int mean = 0;
    int meanCounter = 10;
    //for (int a = 0; a < 20; a++) {

    //  int[] anzahlArray = new int[anzahl.size()];
    //  for (int i = 0; i < anzahl.size(); i++)
    //    anzahlArray[i] = anzahl.get(i);
    //  int max = max(anzahlArray);
    //  int maxIndex = anzahl.indexOf(max);
    //  anzahl.remove(maxIndex);
    //  mean += max;
    //}


    for (int i = 0; i < anzahl.size(); i++)
      if (anzahl.get(i) > constrain(img.height/20, 1, img.height)) {
        meanCounter += anzahl.get(i);
        mean += anzahl.get(i) * type.get(i);
        println(anzahl.get(i), type.get(i));
      }

    return mean/meanCounter;
  }

  int index1D(int x, int y, PImage image) {
    return x + y * image.width;
  }

  PVector index2D(int i, PImage image) {
    return new PVector(i%image.width, int(i/image.width));
  }

  PImage cut(PImage original) {

    int[] margins =  getMargins(original);
    //rand x oben, rand x unten, rand y links, rand y rechts
    int rx0 = margins[0], rx1 = margins[1];
    int ry0 = margins[2], ry1 = margins[3];

    //copy des pictures
    PImage pic = createImage(drawWindowSize, drawWindowSize, RGB);
    pic.loadPixels();
    for (int i = 0; i < pic.pixels.length; i++)
      pic.pixels[i] = color(255);
    pic.updatePixels();

    int originalSizeX = rx1-rx0;
    int originalSizeY = ry1-ry0;

    int resize;
    if (originalSizeX > originalSizeY)
      resize = drawWindowSize-originalSizeX;
    else
      resize = drawWindowSize-originalSizeY;


    //Kopieren der Zahl
    int sizex = originalSizeX+resize;
    int sizey = originalSizeY+resize;
    int offsetx = drawWindowSize/2 - sizex/2;
    int offsety = drawWindowSize/2 - sizey/2;

    pic.copy(original, rx0, ry0, originalSizeX, originalSizeY,
      offsetx, offsety, sizex, sizey);
    return pic;
  }

  PGraphics cut(PGraphics picture) {

    int[] margins =  getMargins(picture);
    //rand x oben, rand x unten, rand y links, rand y rechts
    int rx0 = margins[0], rx1 = margins[1];
    int ry0 = margins[2], ry1 = margins[3];


    //ein PGraphics das die Größe des Fensters hat
    PGraphics returnPicture = createGraphics(drawWindowSize, drawWindowSize);

    int originalSizeX = rx1-rx0;
    int originalSizeY = ry1-ry0;

    int resize;
    if (originalSizeX > originalSizeY)
      resize = drawWindowSize-originalSizeX;
    else
      resize = drawWindowSize-originalSizeY;


    //Kopieren der Zahl
    int sizex = originalSizeX+resize;
    int sizey = originalSizeY+resize;
    int offsetx = drawWindowSize/2 - sizex/2;
    int offsety = drawWindowSize/2 - sizey/2;

    //kopieren der Zahl
    returnPicture.beginDraw();
    returnPicture.background(255);

    returnPicture.copy(picture.get(), rx0, ry0, originalSizeX, originalSizeY,
      offsetx, offsety, sizex, sizey);
    returnPicture.endDraw();

    return returnPicture;
  }

  int[] getMargins(PImage picture) {

    //rand x oben, rand x unten, rand y links, rand y rechts
    int rx0 = 0, rx1 = 0, ry0 = 0, ry1 = 0;

    //von oben nach unten
    for (int y = 0; y < picture.height; y++) {
      for (int x = 0; x < picture.width; x++) {
        //wenn dort die Ziffer beginnt
        if (isColor(color(picture.get(x, y)))) {
          ry0 = y;
          break;
        }
      }
      if (ry0 != 0)
        break;
    }

    //von unten nach oben
    for (int y = picture.height-1; y >= 0; y--) {
      for (int x = 0; x < picture.width; x++) {
        //wenn dort die Ziffer beginnt
        if (isColor((color)picture.get(x, y))) {
          ry1 = y;
          break;
        }
      }
      if (ry1 != 0)
        break;
    }

    //von links nach rechts
    for (int x = 0; x < picture.width; x++) {
      for (int y = 0; y < picture.height; y++) {
        //wenn dort die Ziffer beginnt
        if (isColor((color)picture.get(x, y))) {
          rx0 = x;
          break;
        }
      }
      if (rx0 != 0)
        break;
    }

    //von rechts nach links
    for (int x = picture.width-1; x >= 0; x--) {
      for (int y = 0; y < picture.height; y++) {
        //wenn dort die Ziffer beginnt
        if (isColor((color)picture.get(x, y))) {
          rx1 = x;
          break;
        }
      }
      if (rx1 != 0)
        break;
    }

    int[] margins = {rx0, rx1, ry0, ry1};
    return margins;
  }

  PGraphics copyWindowIntoPGraphics(PApplet p) {

    PGraphics r = createGraphics(p.width, p.height);
    r.beginDraw();
    r.loadPixels();
    p.loadPixels();
    for (int i=0; i < r.pixels.length; i++) {
      r.pixels[i]  = p.pixels[i];
    }

    p.updatePixels();
    r.updatePixels();
    r.endDraw();
    return r;
  }

  PImage copyWindowIntoImage(PApplet p) {

    PImage r = createImage(p.width, p.height, RGB);
    r.loadPixels();
    p.loadPixels();
    for (int i=0; i < r.pixels.length; i++) {
      r.pixels[i]  = p.pixels[i];
    }

    p.updatePixels();
    r.updatePixels();
    return r;
  }

  //funktioniert nur für schwarz weiß Bilder
  PImage dimImage(PImage img, int amount) {

    img.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      if (img.pixels[i] == color(255))
        continue;
      //  float r = red(img.pixels[i])-amount;
      //  float g = green(img.pixels[i])-amount;
      //  float b = blue(img.pixels[i])-amount;
      //  img.pixels[i] = color(r,g,b);
      img.pixels[i] = color(amount);
    }
    img.updatePixels();

    return img;
  }

  int[] copyWindowIntoVector() {

    int[]  r = new int [width * height];
    loadPixels();
    for (int i=0; i < r.length; i++) {
      r[i]  = pixels[i];
    }
    updatePixels();
    return r;
  }

  int[] imageToVector(PImage img) {

    img.loadPixels();
    int[] vector = new int[img.width*img.height];
    for (int i = 0; i < vector.length; i++)
      // x = byte(color(x))
      vector[i] = byte(img.pixels[i]);

    img.updatePixels();
    return vector;
  }

  int[] graphicsToVector(PGraphics img) {

    img.beginDraw();
    img.loadPixels();
    int[] vector = new int[img.width*img.height];
    for (int i = 0; i < vector.length; i++)
      // x = byte(color(x))
      vector[i] = byte(img.pixels[i]);

    img.updatePixels();
    img.endDraw();
    //return byte(img.pixels)
    return vector;
  }

  PGraphics pooling(PGraphics image, int kernel_size, ErrorFunction pool) {

    PGraphics returnGraphic = createGraphics(image.width/kernel_size, image.height/kernel_size);
    returnGraphic.beginDraw();
    float r = 0;
    float g = 0;
    float b = 0;
    int f = 0;
    image.loadPixels();
    returnGraphic.loadPixels();
    for (int y = 0; y < image.height; y += kernel_size) {
      for (int x = 0; x < image.width; x += kernel_size) {


        for (int i = x; i < kernel_size + x; i++) {
          for (int j = y; j < kernel_size + y; j++) {
            int pix = index1D(i, j, image);
            //es wird zwar kein Fehler berechnet, aber das Interface ErrorFunction
            //kann mehrere Werte annehmen...
            r = pool.f(red(image.pixels[pix]), r);
            g = pool.f(green(image.pixels[pix]), g);
            b = pool.f(blue(image.pixels[pix]), b);
          }
        }

        returnGraphic.pixels[f] = color(r, g, b);
        f++;
        r = 0;
        g = 0;
        b = 0;
      }
    }
    returnGraphic.updatePixels();
    returnGraphic.endDraw();
    image.updatePixels();
    return returnGraphic;
  }

  PImage pooling(PImage image, int kernel_size, ErrorFunction pool) {

    PImage returnImage = createImage(image.width/kernel_size, image.height/kernel_size, RGB);
    float r = 0;
    float g = 0;
    float b = 0;
    int f = 0;
    image.loadPixels();
    returnImage.loadPixels();
    for (int y = 0; y < image.height; y += kernel_size) {
      for (int x = 0; x < image.width; x += kernel_size) {

        for (int i = x; i < kernel_size + x; i++) {
          for (int j = y; j < kernel_size + y; j++) {
            int pix = index1D(i, j, image);
            //es wird zwar kein Fehler berechnet, aber das Interface ErrorFunction
            //kann mehrere Werte annehmen...
            r = pool.f(red(image.pixels[pix]), r);
            g = pool.f(green(image.pixels[pix]), g);
            b = pool.f(blue(image.pixels[pix]), b);
          }
        }

        returnImage.pixels[f] = color(r, g, b);
        f++;
        r = 0;
        g = 0;
        b = 0;
      }
    }
    returnImage.updatePixels();
    image.updatePixels();
    return returnImage;
  }

  PImage blackWhite(PImage picture) {
    picture.loadPixels();
    for (int i = 0; i < picture.pixels.length; i++)
      picture.pixels[i] = blackWhite(picture.pixels[i]);
    picture.updatePixels();

    return picture;
  }

  PGraphics blackWhite(PGraphics picture) {
    picture.beginDraw();
    picture.loadPixels();
    for (int i = 0; i < picture.pixels.length; i++)
      picture.pixels[i] = blackWhite(picture.pixels[i]);
    picture.updatePixels();
    picture.endDraw();

    return picture;
  }

  //blackWhite passt den Wert für das Netz etwas an
  color blackWhite(color c) {
    //welcher Wert nun für welche Farbe steht ist egal, Hauptsache
    //sie sind unterschiedlich
    color a = color(1);
    if (c == color(0))
      a = color(0);
    return a;
  }

  PImage convolution(PImage img, float[][] kernel_weights) {

    PImage filtered = createImage(img.width-2, img.height-2, RGB);
    filtered.loadPixels();
    img.loadPixels();
    int index1D = 0;
    for (int y = 1; y < img.height-1; y++) {
      for (int x = 1; x < img.width-1; x++) {
        color rgb = calculateConv(img, x, y, kernel_weights);
        //int pix = index1D(x, y, img);
        filtered.pixels[index1D] = rgb;
        index1D++;
      }
    }
    img.updatePixels();
    filtered.updatePixels();
    return filtered;
  }

  color calculateConv(PImage img, int x, int y, float[][] kernel_weights) {

    int sumR = 0;
    int sumG = 0;
    int sumB = 0;

    for (int i = -1; i < 2; i++) {
      for (int j = -1; j < 2; j++) {

        int pix = index1D(x + i, y + j, img);
        float filter = kernel_weights[j + 1][i + 1];

        sumR += red(img.pixels[pix]) * filter;
        sumG += green(img.pixels[pix]) * filter;
        sumB += blue(img.pixels[pix]) * filter;
      }
    }
    return color(sumR, sumG, sumB);
  }
}
