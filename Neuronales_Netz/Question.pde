class Question extends PApplet {


  void settings() {
    size(400, 200);
  }

  int sizex = 100;
  int sizey = 50;
  String question;

  void setup() {
    surface.setTitle("Question");
  }

  void draw() {

    background(backgroundColor);

    push();

    stroke(30);
    fill(contrast);
    textAlign(CENTER, CENTER);
    rectMode(CENTER);
    rect(width/4, height/2, sizex, sizey);
    rect(width/1.5, height/2, sizex, sizey);

    fill(textColor);
    textSize(21);
    text(question, width/2, 30);
    text("yes", width/4, height/2);
    text("no", width/1.5, height/2);

    pop();
  }

  boolean getDecision(String _question) {

    question = _question;
    //Entscheidung resetten
    decision = null;
    //wenn unsichtbar wieder sichtbar
    loop();
    surface.setVisible(true);

    while (decision == null)
      if (millis()%500 == 0)
        //damit mouse-events nicht ignoriert werden
        redraw();

    noLoop();
    surface.setVisible(false);
    return decision;
  }

  Boolean decision;
  void mouseReleased() {

    if (mouseX < width/4+sizex/2 && mouseX > width/4-sizex/2 && mouseY < height/2+sizey/2 && mouseY > height/2-sizey/2)
      decision = true;
    else if (mouseX < width/1.5+sizex/2 && mouseX > width/1.5-sizex/2 && mouseY < height/2+sizey/2 && mouseY > height/2-sizey/2)
      decision = false;
  }
}
