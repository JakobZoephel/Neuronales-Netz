class Diagramm {

  int rand = 40;
  int offset = 0;
  //Abstand der Messwerte (in Pixeln). g für gap
  int g;
  // von wie vielen Messwerten der Durchschnitt berechnet wird
  int mean = 5;
  //durch den Durchschnitt ist der Graph "smoother"
  float[] smoothFailures;


  Diagramm() {

    smoothFailures = new float[failure.length/mean];

    for (int i = 0; i < smoothFailures.length; i++)
      smoothFailures[i] = mean(i*mean, mean, failure);
  }

  void show() {

    background(254);
    int size = (width-2*rand)/(failure.length-1);
    //wenn es resized wird
    g = size <= 1 ? 3 : size;

    // g += (width-2*rand)/failure.length/failure.length;

    if (mousePressed) {
      if (mouseButton == RIGHT && offset-10 > -(failure.length/g-1)*g*g+width-2*rand)
        offset -= 10;
      else if (mouseButton == LEFT && offset+10 <= 0)
        offset += 10;
    }
    createDiagram();

    int w = 55;
    int h = 40;
    int px = w/2;
    int py = height-h/2-10;

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

    if (mousePressed && mouseX > px-w/2 && mouseX < px+w/2 && mouseY > py-h/2 && mouseY < py+h/2) {

      task = Tasks.CONTROL_PANEL;
      taskSetup(task);
      mousePressed = false;
      exitSave();
    }
  }

  float mean(int index, int slice, float[] arr) {

    float sum = 0;
    for (int i = 0; i < slice; i++)
      if (i+index >= arr.length)
        return 2;
      else
        sum += arr[i+index];
    return sum/slice;
  }

  void createDiagram() {

    translate(offset, 0);

    stroke(0, 0, 255);
    noFill();

    beginShape();
    for (int x = 0; x < smoothFailures.length; x++)
      if (smoothFailures[x] != 2)
        vertex(rand+x*g*mean, map(smoothFailures[x], 0, 1, height-rand, rand));
    endShape();

    textAlign(CENTER, CENTER);
    fill(0);
    strokeWeight(1);
    textSize(20);
    text(epochs-1, width-rand, height-rand+10);

    if (epochs > 50)
      text((epochs-1)/2, (width-rand)/2, height-rand+10);
    text(1, rand-textWidth('1'), rand);
    text("error in percent", rand/2 + textWidth("error in percent")/2, rand/2);
    //text("epochs", width-rand, height-rand+10);

    stroke(255, 0, 0, 200);
    noFill();
    beginShape();
    for (int x = 0; x < failure.length; x++)
      if (failure[x] != 2)
        vertex(rand+x*g, map(failure[x], 0, 1, height-rand, rand));

    endShape();

    fill(0);
    stroke(0);
    //y
    line(rand, height-rand, rand, rand);
    //x
    line(rand, height-rand, width-rand, height-rand);
  }
}
