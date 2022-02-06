class Console extends PApplet {

  //für scrolling
  int consoleIndex = 0;

  void settings() {
    size(600, 400);
  }

  void setup() {
    consoleText.clear();
    surface.setResizable(true);
  }

  void draw() {
    consoleIndex = constrain(consoleIndex, 0, consoleText.size());

    textSize(21);
    background(contrast);
    fill(textColor);
    textAlign(LEFT, TOP);
    for (int i = consoleIndex; i < consoleText.size(); i++) {

      text(consoleText.get(i), 10, (i-consoleIndex)*25);

      //wenn auch noch gerade trainiert wird
      if (((i+1)-consoleIndex)*25 > height && task != Tasks.DIAGRAM)
        consoleIndex++;
    }
  }

  void mouseWheel(MouseEvent event) {
    if (consoleText.size() * 25 > height)
      consoleIndex += event.getCount();
  }
  
  void exit() {

    if (task == Tasks.AI || task == Tasks.DIAGRAM) {

      kill = true;
      start = false;
      ignorePanel = false;
      task = Tasks.CONTROL_PANEL;
      panel.stateSetup(panel.state);
      exitSave();
    }
    visualConsole = null;
  }
}
