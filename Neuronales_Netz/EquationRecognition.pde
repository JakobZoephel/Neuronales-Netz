class EquationRecognition {

  EquationRecognition(PImage equation, boolean slow) {
    if (slow)
      slowRecognition(equation);
    else
      fastRecognition(equation);
  }

  PImage normalizeImage(PImage picture) {

    //alles was nicht weiß (255) ist, soll schwarz sein
    picture.loadPixels();
    for (int i = 0; i < picture.pixels.length; i++)
      //if (picture.pixels[i] != color(255))
      if (F.isColor(picture.pixels[i]))
        picture.pixels[i] = color(0);
    picture.updatePixels();

    int marginWidth = 1;
    // das Gleiche wie picture nur mit weißen Rändern
    PImage newImage = createImage(picture.width+marginWidth*2, picture.height+marginWidth*2, RGB);

    newImage.loadPixels();
    for (int i = 0; i < newImage.pixels.length; i++)
      newImage.pixels[i] = color(255);

    //Rand einfügen
    for (int x = marginWidth; x < newImage.width-marginWidth; x++)
      for (int y = marginWidth; y < newImage.height-marginWidth; y++)
        newImage.pixels[F.index1D(x, y, newImage)] =  picture.pixels[F.index1D(x-marginWidth, y-marginWidth, picture)];

    newImage.updatePixels();

    return newImage;
  }
  //schneller == (in diesem Fall) schlechter
  void fastRecognition(PImage picture) {

    consoleText.clear();
    picture = normalizeImage(picture);
    //Positionen der einzelnen Ziffern/Verknüpfungen
    ArrayList<ArrayList<Integer>> posList = new ArrayList<ArrayList<Integer>>();
    //Positionen der einzelnen Gleichungen
    ArrayList<Integer> equationPositions = new ArrayList<Integer>();
    //Bilder der einzelnen Gleichungen
    ArrayList<PImage> equationImages = new ArrayList<PImage>();
    ArrayList<ArrayList<PImage>> pictureList = new ArrayList<ArrayList<PImage>>();


    /*
     zuerst wird das Bild horizontal in Gleichungen geteilt.
     Dazu wird eine neue (erste) Gleichung erstellt
     Die posList enthält dabei Informationen wo die Gleichungen aufhören/anfangen
     */
    pictureList.add(new ArrayList<PImage>());
    posList.add(new ArrayList<Integer>());


    //dort fängt die erste Gleichung an: y=0
    equationPositions.add(0);
    picture.loadPixels();

    //dort wo als letztes ein Bild vermutet wurde
    int lastY = -1;
    //Anzahl an schwarzen Pixeln in einer Reihe
    int pixelCount = 0;
    //Pixelindex von 2D zu 1D
    int index;
    //Bild einer Gleichung
    PImage equation;
    //so viele Pixel sollte ein Strich mindestens haben
    int minPixles = 3;

    for (int y = 0; y < picture.height; y++) {
      //die Anzhal der Pixel in dieser Reihe
      pixelCount = 0;
      for (int x = 0; x < picture.width; x++) {

        index = F.index1D(x, y, picture);
        if (picture.pixels[index] == color(0))
          pixelCount++;
      }

      //wenn dort viele schwarze Pixel sind und das Bild nicht schon
      //hinzugefügt wurde
      if (pixelCount >= minPixles && y != ++lastY) {

        //neue Gleichung entdeckt, dessen Ziffer-Positionen/Bilder
        //gespeichert werden müssen
        posList.add(new ArrayList<Integer>());
        pictureList.add(new ArrayList<PImage>());
        //dort hört demnach die als letztes entdeckte Gleichung auf
        int posy = equationPositions.get(equationPositions.size()-1);
        //so groß ist die Gleichung
        int yw = y-posy;
        //dort wo die Gleichung anfängt speichern
        equationPositions.add(y);

        //die Gleichung hinzufügen
        equation = createImage(picture.width, yw, RGB);
        equation.copy(picture, 0, posy, picture.width, yw, 0, 0, equation.width, equation.height);
        equationImages.add(equation);

        //damit solange geskippt wird bis die gerade entdeckte Gleichung zuende ist
        lastY = y;
      }
    }

    //dort hört die letzte Gleichung auf
    equationPositions.add(picture.height);
    //letzte Gleichung hinzufügen
    int posy = equationPositions.get(equationPositions.size()-2);
    int yw = equationPositions.get(equationPositions.size()-1)-posy;
    equation = createImage(picture.width, yw, RGB);
    equation.copy(picture, 0, posy, equation.width, yw, 0, 0, equation.width, equation.height);
    equationImages.add(equation);

    //ist immer ein leeres Bild, da es der Rand am Anfang ist
    equationImages.remove(0);

    //eine Ziffer, +, - oder = etc.
    PImage singleNumber;
    //nun werden die entdeckten Gleichungen in die Bestandteile aufgeteilt
    for (int currRow = 0; currRow < equationImages.size(); currRow++) {
      //die zu analysierende Gleichung
      equation = equationImages.get(currRow);

      // da wo der erste Bestandteil anfängt
      posList.get(currRow).add(0);

      equation.loadPixels();

      //das Gleiche wie mit dem Entdecken der Gleichungen, nur nicht horizontal sondern vertikal
      int lastX = -1;
      for (int x = 0; x < equation.width; x++) {
        pixelCount = 0;
        for (int y = 0; y < equation.height; y++) {
          index = F.index1D(x, y, equation);
          if (equation.pixels[index] == color(0))
            pixelCount++;
        }

        if (pixelCount >= minPixles && x != ++lastX) {
          posList.get(currRow).add(x);
          int posx = posList.get(currRow).get(posList.get(currRow).size()-2);
          int xw = posList.get(currRow).get(posList.get(currRow).size()-1)-posx;

          singleNumber = createImage(xw, equation.height, RGB);
          singleNumber.copy(equation, posx, 0, xw, equation.height, 0, 0, singleNumber.width, singleNumber.height);

          pictureList.get(currRow).add(singleNumber);
          lastX = x;
        }
      }

      equation.updatePixels();

      int posx = posList.get(currRow).get(posList.get(currRow).size()-1);
      int xw = equation.width-posx;
      singleNumber = createImage(xw, equation.height, RGB);
      singleNumber.copy(equation, posx, 0, xw, equation.height, 0, 0, singleNumber.width, singleNumber.height);
      pictureList.get(currRow).add(singleNumber);
      pictureList.get(currRow).remove(0);
    }
    //leer
    pictureList.remove(pictureList.size()-1);
    //ArrayList ist leer, da diese nur bei slowRecognition genutzt wird
    recognize(pictureList, new ArrayList<PVector>(0));
  }

  //langsamer == besser
  void slowRecognition(PImage picture) {

    consoleText.clear();

    picture = normalizeImage(picture);
    //ArrayList aus den Mittel-Punkten der Bilder
    ArrayList<ArrayList<PVector>> center = new ArrayList<ArrayList<PVector>>();
    //shortcut für die letzte ArrayList von Center
    ArrayList<PVector> centerRow = new ArrayList<PVector>();

    //welche Pixel zu einer Ziffer gehören
    ArrayList<String> positions = new ArrayList<String>();
    //die extrahierten Bilder
    ArrayList<ArrayList<PImage>> pictureList = new ArrayList<ArrayList<PImage>>();

    picture.loadPixels();
    for (int i = 0; i < picture.pixels.length; i++) {
      //Anfang einer Ziffer
      if (picture.pixels[i] == color(0)) {

        positions.clear();
        PVector pos = F.index2D(i, picture);
        positions.add(pos.x + " " + pos.y);
        int currIndex = positions.size()-1;
        int  lastIndex = currIndex;
        do {
          //getNeighbors(pos, picture, positions);
          for (int j = lastIndex; j < positions.size(); j++)
            getNeighbors(new PVector(int(positions.get(j).split(" ")[0]), int(positions.get(j).split(" ")[1])), picture, positions);

          lastIndex = currIndex;
          currIndex = positions.size()-1;
        } while (currIndex != lastIndex);

        consoleText.add("found object...");
        PVector centerPoint = new PVector(-1, -1);
        //anahnd der centerPoints das Bild aus der Gleichung schneiden
        PImage extractedImage = makeImage(positions, centerPoint);

        //eine ArrayList für die erste Gleichung hinzufügen
        if (pictureList.size() == 0) {
          pictureList.add(new ArrayList<PImage>());
          pictureList.get(0).add(extractedImage);
          center.add(new ArrayList<PVector>());
          center.get(0).add(centerPoint);
          continue;
        }
        //shortcut
        centerRow = center.get(center.size()-1);

        //an welche Position die Ziffer in einer Gleichung gehört (Reihenfolge auf x-Achse)
        int centerIndex = 0;
        while (centerIndex < centerRow.size() && centerRow.get(centerIndex).x < centerPoint.x) {
          centerIndex++;
        }
        // die Ziffer-Koordinaten an diese Stelle hinzufügen
        F.insertElement(centerRow, centerPoint, centerIndex-1);
        // aktualisieren
        center.set(center.size()-1, centerRow);

        //y des jetzigen Bildes
        int currCenterY = int(centerPoint.y);

        int currSizeY = extractedImage.height;

        //Durchschnitt wo die Ziffern davor alle waren (y-Position)
        //zum Testen ob die Ziffer zu der Gleichung gehört oder zu einer anderen
        int lastCenterY = 0;
        for (int j = 0; j < centerRow.size(); j++)
          lastCenterY += centerRow.get(j).y;

        lastCenterY /= centerRow.size();

        //funktioniert sonst nicht mit - oder =. Nachteil, wenn die erste Zahl negativ ist (- Zeichen)
        int lastSizeY = pictureList.get(pictureList.size()-1).get(0).height;

        //wenn es in der selben Reihe ist wie das Bild davor
        if (currCenterY-currSizeY/4 < lastCenterY+lastSizeY/2 && currCenterY+currSizeY/4 > lastCenterY-lastSizeY/2) {

          F.insertElement(pictureList.get(pictureList.size()-1), extractedImage, centerIndex-1);
        } else {
          //neue Gleichung
          pictureList.add(new ArrayList<PImage>());
          pictureList.get(pictureList.size()-1).add(extractedImage);
          center.get(center.size()-1).remove(centerIndex);
          center.add(new ArrayList<PVector>());
          center.get(center.size()-1).add(centerPoint);
        }
      }
    }
    picture.updatePixels();
    //welche Bilder = sind
    ArrayList<PVector> equalSigns = new ArrayList<PVector>();

    //überprüfe ob einige Elemente eigentlich ein = sind
    for (int i = 0; i < pictureList.size(); i++) {
      for (int j = 0; j < pictureList.get(i).size(); j++) {
        int centerIndex = j;

        int currCenterX = int(center.get(i).get(centerIndex).x);
        int currSizeX = pictureList.get(i).get(centerIndex).width;

        int lastCenterX = 0;
        int lastSizeX = 0;

        if (centerIndex > 0) {
          lastCenterX = int(center.get(i).get(centerIndex-1).x);
          lastSizeX = pictureList.get(i).get(centerIndex-1).width;
        }

        //wenn die beiden Bilder übereinander sind (bei = der Fall)
        if ((currCenterX-currSizeX/2 <= lastCenterX+lastSizeX/2 && currCenterX+currSizeX/2 >= lastCenterX-lastSizeX/2) ) {
          //aus zwei Elementen (--) eins machen (=)
          pictureList.get(i).remove(centerIndex-1);
          //vermerken dass dieses - eigentlich ein = sein soll (bei der Erkennung)
          equalSigns.add(new PVector(i, centerIndex-1));
        }
      }
    }
    recognize(pictureList, equalSigns);
  }

  PImage makeImage(ArrayList<String> positions, PVector center) {

    int xmax = 0;
    int ymax = 0;
    int xmin = int(Float.POSITIVE_INFINITY);
    int ymin = int(Float.POSITIVE_INFINITY);
    for (int i = 0; i < positions.size(); i++) {
      int x = int(positions.get(i).split(" ")[0]);
      int y = int(positions.get(i).split(" ")[1]);
      if (x > xmax)xmax = x;
      if (x < xmin)xmin = x;
      if (y > ymax)ymax = y;
      if (y < ymin)ymin = y;
    }

    //Mitte des Bildes (im Originalbild). Ändert den pointer
    center.set(xmin+(xmax-xmin+1)/2, ymin+(ymax-ymin+1)/2);

    PImage created = createImage(xmax-xmin+1, ymax-ymin+1, RGB);
    created.loadPixels();

    for (int i = 0; i < created.pixels.length; i++)
      created.pixels[i] = color(255);

    for (int i = 0; i < positions.size(); i++) {
      int x = int(positions.get(i).split(" ")[0]);
      int y = int(positions.get(i).split(" ")[1]);
      x -= xmin;
      y -= ymin;
      created.pixels[F.index1D(x, y, created)] = color(0);
    }
    created.updatePixels();
    return created;
  }


  void getNeighbors(PVector pos, PImage equations, ArrayList<String> posList) {

    equations.loadPixels();
    int radius = 1;
    int pixelCount = 0;
    for (int x = -radius; x <= radius; x++) {
      for (int y = -radius; y <= radius; y++) {
        if (x+y == 0)continue;
        if (pos.x+x >= equations.width || pos.y+y >= equations.height || pos.x+x < 0 || pos.y+y < 0)continue;

        if (equations.pixels[F.index1D(int(pos.x+x), int(pos.y+y), equations)] == color(0))
          if (posList.indexOf(int(pos.x+x) + " " + int(pos.y+y)) == -1) {

            posList.add(int(pos.x+x) + " " + int(pos.y+y));
            pixelCount++;
            //den Pixel löschen
            equations.pixels[F.index1D(int(pos.x+x), int(pos.y+y), equations)] = color(255);
            //getNeighbors(new PVector(pos.x+x, pos.y+y), equations, posList);
          }
      }
    }
    equations.updatePixels();
  }

  void recognize(ArrayList<ArrayList<PImage>> pictureList, ArrayList<PVector> equalSigns) {

    for (int currRow = 0; currRow < pictureList.size(); currRow++) {
      for (int i = 0; i < pictureList.get(currRow).size(); i++) {
        pictureList.get(currRow).set(i, F.cut(pictureList.get(currRow).get(i)));
        pictureList.get(currRow).set(i, F.pooling(pictureList.get(currRow).get(i), kernel_size, x -> max(x)));
        pictureList.get(currRow).set(i, F.blackWhite(pictureList.get(currRow).get(i)));
      }
    }

    // zum Speichern der Gleichungen
    String[] computerEquations = new String[pictureList.size()];
    for (int i = 0; i < computerEquations.length; i++)
      computerEquations[i] = "";

    for (int i = 0; i < computerEquations.length; i++) {
      for (int j = 0; j < pictureList.get(i).size(); j++) {
        //wenn es kein = ist
        if (equalSigns.indexOf(new PVector(i, j)) == -1) {
          lm.feedForward(float(F.imageToVector(pictureList.get(i).get(j))));

          //wenn es schon alle = erkannt hat (slowRecognition) ist es wahrscheinlich eher ein -
          if (equalSigns.size() > 0 && charset[int(F.max_pool_array(lm.ergebnis))] == '=')
            computerEquations[i] += '-';
          else
            computerEquations[i] += charset[int(F.max_pool_array(lm.ergebnis))];
        } else
          computerEquations[i] += "=";
      }
    }

    int corrects = 0;
    consoleText.clear();
    for (int i = 0; i < computerEquations.length; i++) {
      boolean correctEquation = correct(computerEquations[i]);
      consoleText.add(computerEquations[i] + " " + correctEquation);
      println("equation:", computerEquations[i], correctEquation);
      if (correctEquation)
        corrects++;
    }

    consoleText.add(corrects + "/" + computerEquations.length);
    println(corrects + "/" + computerEquations.length);
  }

  boolean correct(String equation) {

    try {
      String[] split = split(equation, '=');
      //keine Gleichung
      if (split.length < 2)return false;

      double solution = eval(split[0]);
      for (int i = 1; i < split.length; i++)
        if (eval(split[i]) != solution)
          return false;

      return true;
    }
    catch (Exception e) {
      return false;
    }
  }
}
