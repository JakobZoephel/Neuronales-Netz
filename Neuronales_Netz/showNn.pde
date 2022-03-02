class NeuronalNetworkVisualization {

  //size der Neuronen
  int size = 50;
  //wie hell die Gewichte sein sollen
  int alpha = 1500;
  long countdown = 0;
  //ob er mit der Animation fertig ist oder nicht
  boolean finished = false;
  //Positionen der Neuronen
  PVector[][] pos;
  //Processing Graphic
  PGraphics pg;

  NeuronalNetworkVisualization(int x, int y) {
    pg = createGraphics(x, y);

    // +2 für out und input Layer
    pos = new PVector[hiddenLayers.length+2][];

    pos[0] = new PVector[trainExampleData];
    for (int i=0; i < hiddenLayers.length; i++)
      pos[i+1] = new PVector[hiddenLayers[i].hiddenNs.length];

    pos[pos.length-1] = new PVector[outL.outNs.length];

    //Vectoren erstellen
    for (int i = 0; i < pos.length; i++)
      for (int j = 0; j < pos[i].length; j++)
        pos[i][j] = new PVector();

    calculatePosition();
  }

  void show() {
    if (spacePressed)
      return;

    pg.beginDraw();
    pg.background(0);
    drawConnections(5);
    drawEllipses();
    pg.endDraw();

    background(0);
    image(pg, offset, 0);
  }

  boolean drawedConnections = false;
  int offset = 100;

  void showResult() {

    if (spacePressed)
      return;

    //ob er mit der Animation fertig ist oder nicht
    if (finished) {
      //5 Sekunden nach dem die Animation fertig ist
      if (millis() >= countdown+3000 && countdown != 0) {
        background(0);
        int iterator = 0;
        for (int i=0; i < lm.ergebnis.length; i++) {
          if (lm.ergebnis[i] == max(lm.ergebnis)) {
            fill(255);
            textSize(60);
            textAlign(CENTER, CENTER);
            text(charset[i], width/2, height/2-100);
            textSize(15);
            text(str(lm.ergebnis[i]*100)+'%', width/2, height/2-50);
          } else {
            fill(155);
            textSize(20);
            textAlign(LEFT, CENTER);
            text(charset[i], width/(lm.ergebnis.length-1)*iterator+10, height/2+100);
            textSize(13);

            String s = str(lm.ergebnis[i]*100);
            //wenn er zu viele Stellen hat
            if (s.length() > 10)
              s = s.substring(0, s.length()-5) + s.substring(s.length()-4, s.length());

            s+= '%';
            text(s, width/(lm.ergebnis.length-1)*iterator+10, height/2+120);
            iterator++;
          }
        }
        fill(5);
        stroke(255);
        textAlign(CENTER, CENTER);
        rectMode(CENTER);
        int w = 2*int(textWidth("again?"));
        int h = 30;
        int px = width-w/2-10;
        int py = height-h/2-10;
        rect(px, py, w, h);
        fill(255);
        text("again?", px, py);
        //if mouse in rect
        if (mousePressed && mouseX > px-w/2 && mouseX < px+w/2 && mouseY > py-h/2 && mouseY < py+h/2) {
          //einfaches mouseReleased
          mousePressed = false;

          //reset to setup
          finishedDrawing = false;
          digit.allOutOfScreen = false;
          finished = false;
          drawedConnections = false;
          //clear
          countdown = 0;
          brightness = 0;
          for (int i=0; i <  lm.ergebnis.length; i++) lm.ergebnis[i] = 0;
          for (int j=0; j < hiddenLayers.length; j++) {
            for (int i=0; i < hiddenLayers[j].hiddenNs.length; i++) {
              hiddenLayers[j].hiddenNs[i].summe[0] = 0;
            }
          }
          pg.beginDraw();
          //reset fill
          drawLmEllipses();
          pg.endDraw();
          background(0);
          surface.setVisible(false);
          digit.setDigitLocation(displayWidth/2-digit.width, displayHeight/2-digit.height);
        }

        fill(backgroundColor);
        stroke(0);
        textAlign(CENTER, CENTER);
        rectMode(CENTER);

        w = 75;
        h = 60;
        px = w/2-10;
        py = height-h/2-10;
        rect(px, py, w, h);

        fill(170, 60, 50);

        beginShape();
        vertex(px, py-2*arrowSize);
        vertex(px, py-6*arrowSize);

        //Spitze
        vertex(px-6*arrowSize, py);

        vertex(px, py+6*arrowSize);
        vertex(px, py+2*arrowSize);

        vertex(px+9*arrowSize, py+2*arrowSize);
        vertex(px+9*arrowSize, py-2*arrowSize);

        vertex(px, py-2*arrowSize);
        endShape();

        //wenn auf dem Pfeil
        if (mousePressed && mouseX > px-w/2 && mouseX < px+w/2 && mouseY > py-h/2 && mouseY < py+h/2) {
          //einfaches mouseReleased
          mousePressed = false;
          showConsole = true;

          ignorePanel = false;
          //um sicher zu gehem
          if (panel != null) {
            panel.state = States.TRAINorSHOW;
            panel.stateSetup(panel.state);
          }

          task = Tasks.CONTROL_PANEL;
          taskSetup(task);

          digit.freeze();
        }

        //mach einfach irgendwas
      } else if (millis()%7 == 0) {
        loadPixels();
        for (int i=0; i < pixels.length; i++)
          pixels[i] += 8;
        updatePixels();
      }
      return;
    }
    if (!drawedConnections) {
      pg.beginDraw();

      pg.background(0);
      drawConnections(1);
      drawLmEllipses();

      pg.endDraw();

      drawedConnections = true;

      background(0);
      image(pg, offset, 0);
      showText();
    } else {
      pg.beginDraw();
      drawLmEllipses();
      pg.endDraw();

      background(0);
      image(pg, offset, 0);
      showText();
    }
  }

  void showText() {

    float decision = max(lm.ergebnis);
    textSize(11);
    //j == Neuronenindex
    textAlign(LEFT, CENTER);
    int j = 0;
    for (int i =0; i <  outL.outNs.length; i++) {

      if (lm.ergebnis[j] == decision) fill(190);
      else fill(70);
      text(lm.ergebnis[j], pos[pos.length-1][i].x + 140, pos[pos.length-1][i].y);
      j++;
    }
  }

  void drawConnections(int fastDraw) {
    //show connections von dem hidden Neuron zu dem input/hidden
    for (int j=0; j < hiddenLayers.length; j++) {
      for (int i=0; i < hiddenLayers[j].hiddenNs.length; i++) {
        for (int k=0; k < pos[j].length; k++) {
          //um schneller zu sein, ein paar Gewichte auslassen
          if (j == 0 && k%fastDraw != 0)
            continue;
          if (hiddenLayers[j].hiddenNs[i].weights[k] > 0) pg.stroke(0, 255, 0, hiddenLayers[j].hiddenNs[i].weights[k] * alpha);
          else pg.stroke(255, 0, 0, hiddenLayers[j].hiddenNs[i].weights[k] *-alpha);
          pg.line(pos[j+1][i].x, pos[j+1][i].y, pos[j][k].x, pos[j][k].y);
        }
      }
    }
    //show connections von den output Neuronen zu dem letzten hidden layer
    for (int i=0; i < outL.outNs.length; i++) {
      for (int k=0; k <pos[pos.length-2].length; k++) {
        if (outL.outNs[i].weightsOH[k] > 0)pg.stroke(0, 255, 0, outL.outNs[i].weightsOH[k] * alpha);
        else pg.stroke(255, 0, 0, outL.outNs[i].weightsOH[k] * -alpha);
        pg.line(pos[pos.length-1][i].x, pos[pos.length-1][i].y, pos[pos.length-2][k].x, pos[pos.length-2][k].y);
      }
    }
  }

  void drawEllipses() {
    //show input Layer
    size = (pg.height-2*20)/trainExampleData;
    size = constrain(size, 1, 50);
    pg.stroke(200);
    for (int i=0; i < trainExampleData; i++) {
      pg.fill(trainData[threads[0].index][i]*10);
      pg.ellipse(pos[0][i].x, pos[0][i].y, size, size);
    }

    //show hidden Layers
    for (int j=0; j < hiddenLayers.length; j++) {

      size = (pg.height-2*20)/hiddenLayers[j].hiddenNs.length;
      size = constrain(size, 1, 50);
      for (int i=0; i < hiddenLayers[j].hiddenNs.length; i++) {
        pg.fill(hiddenLayers[j].hiddenNs[i]. summe[0] * 100);
        pg.ellipse(pos[j+1][i].x, pos[j+1][i].y, size, size);
      }
    }
    size = (pg.height-2*20)/outL.outNs.length;
    size = constrain(size, 1, 50);
    //show output Layer
    for (int i=0; i < outL.outNs.length; i++) {
      pg.fill(threads[0].ergebnis[i] * 250);
      pg.ellipse(pos[pos.length-1][i].x, pos[pos.length-1][i].y, size, size);
    }
  }
  int maxColor = 100;
  int brightness = 0;

  void drawLmEllipses() {
    //show input Layer
    //wenn drawedConnections false ist, ist es das erste Mal dass die Methode aufgerufen wird
    if (digit.pigments.size() != 0 && drawedConnections) return;
    size = (pg.height-2*20)/trainExampleData;
    size = constrain(size, 1, 50);
    pg.stroke(200);
    for (int i=0; i < trainExampleData; i++) {
      pg.fill(digit.example[i]*100);
      pg.ellipse(pos[0][i].x, pos[0][i].y, size, size);
    }

    //show hidden Layers
    for (int j=0; j < hiddenLayers.length; j++) {
      size = (pg.height-2*20)/hiddenLayers[j].hiddenNs.length;
      size = constrain(size, 1, 50);
      for (int i=0; i < hiddenLayers[j].hiddenNs.length; i++) {
        pg.fill(hiddenLayers[j].hiddenNs[i].summe[0] * brightness);
        pg.ellipse(pos[j+1][i].x, pos[j+1][i].y, size, size);
      }
    }
    if (brightness < maxColor)
      brightness += 5;
    if (brightness != maxColor && drawedConnections)
      return;

    size = (pg.height-2*20)/outL.outNs.length;
    size = constrain(size, 1, 50);
    //show output Layer
    for (int i=0; i < outL.outNs.length; i++) {
      if (drawedConnections)
        pg.fill(lm.ergebnis[i] * 250);
      pg.ellipse(pos[pos.length-1][i].x, pos[pos.length-1][i].y, size, size);
    }
    if (!drawedConnections)
      return;
    finished = true;
    countdown = millis();
  }

  void calculatePosition() {
    int currentLayer = 0;
    int y;
    //calculate input Layer
    size = (pg.height-2*20)/trainExampleData;
    size = constrain(size, 1, 50);

    int iterator = 0;
    for (int i = trainExampleData-1; i >= 0; i--) {
      y = pg.height/2 + trainExampleData/2 * size -i*size -size/2;
      if (trainExampleData % 2 != 0)
        y += size/2;

      pos[0][iterator].x = pg.width/(hiddenLayers.length+2)*currentLayer + size;
      pos[0][iterator].y = y;
      iterator++;
    }
    currentLayer++;
    size = 50;
    iterator = 0;
    //calculate hidden Layers
    for (int j = 0; j < hiddenLayers.length; j++) {
      size = (pg.height-2*20)/hiddenLayers[j].hiddenNs.length;
      size = constrain(size, 1, 50);
      for (int i=hiddenLayers[j].hiddenNs.length-1; i >= 0; i--) {
        y = pg.height/2 + hiddenLayers[j].hiddenNs.length/2 * size -i*size -size/2;
        if (hiddenLayers[j].hiddenNs.length% 2 != 0)
          y += size/2;

        pos[j+1][iterator].x = pg.width/(hiddenLayers.length+2)*currentLayer+size;
        pos[j+1][iterator].y = y;
        iterator++;
      }
      currentLayer++;
      iterator = 0;
    }

    size = (pg.height-2*20)/outL.outNs.length;
    size = constrain(size, 1, 50);
    //calculate output Layer
    for (int i= outL.outNs.length-1; i >= 0; i--) {
      y = pg.height/2 + outL.outNs.length/2 * size -i*size - size/2;
      if (outL.outNs.length% 2 != 0)
        y += size/2;

      pos[pos.length-1][iterator].x = pg.width/(hiddenLayers.length+2)*currentLayer + size;
      pos[pos.length-1][iterator].y = y;
      iterator++;
    }
  }
}
