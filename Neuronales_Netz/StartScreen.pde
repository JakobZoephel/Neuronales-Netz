import java.lang.reflect.Field;
import java.net.URI;
import java.awt.Desktop;

import drop.SDrop;
import drop.DropEvent;

SDrop drop;
//das Bild der Gleichungen
PImage equations;
//Größe der Navigier-Pfeile
int arrowSize = 3;

enum States {


  TRAINorSHOW, LAYERS, VARIABLES, RUN;

  static States lastState(States state) {

    //index des States
    int index = getIndex(state);

    if (getState(index-1) != null)
      return values()[index-1];
    else
      return state;
  }

  static States nextState(States state) {

    //index des States
    int index = getIndex(state);

    if (getState(index+1) != null)
      return values()[index+1];
    else
      return state;
  }

  static States getState(int i) {
    if (i < values().length && i >= 0)
      return values()[i];
    else
      return null;
  }

  static int getIndex(States state) {
    for (int i = 0; i < values().length; i++)
      if (state == values()[i])
        return i;

    return -1;
  }
};

String[] data;
// Path von diesem file
String path;

class StartScreen {

  TextField[] text = new TextField[16];
  ArrayList<TextField> layerFields;

  //Abstand zu anderen Elementen
  static final int rand = 20;
  int x, y;
  int sizex, sizey;
  //Abstand der Layerübersicht zu y = 0
  int layerOffset = 100;
  //scrolling
  float wheel = 0;
  String methodNameText, methodNameTextError;
  //hier sind z.B. die help-strings etc.
  String[] helpDocumentation;

  States state;
  //um die Funktionen festzulegen
  TextField errorFunctionField;
  TextField outputFunctionField;

  StartScreen() {

    helpDocumentation = loadStrings(loadFile("help.txt"));
    data = loadStrings(loadFile("data.txt"));
    surface.setTitle("control panel");
    x = width-2*rand;
    y = height-2*rand;
    //6 Felder jedes y
    sizex = x/6-rand;
    //3 Felder für jedes x
    sizey = y/3-rand;

    layerFields = new ArrayList<TextField>();

    int numberOfLayers = 0;
    for (int i = 0; i < data.length; i++) {
      String string = split(data[i], ":::")[0];
      if (string.substring(1, string.length()).equals("hiddenLayers"))
        numberOfLayers++;
    }

    for (int i = 0; i < numberOfLayers; i++) {
      Object value;
      //wenn es noch nicht gespeichert wurde
      if (F.getValue(i + "hiddenLayers").length() == 0) {
        if (hiddenLayers.length > i) {
          value =  hiddenLayers[i].hiddenNs.length + ":relu";
        } else
          value = ":";
      } else
        value = F.getValue(i + "hiddenLayers");

      layerFields.add(new TextField(width/2-sizex, layerOffset+i*sizey/2, sizex*2, sizey/2,
        "[HiddenL", "hiddenLayers", value));
    }


    Class mainClass = main.getClass();
    Field[] allVariables = mainClass.getFields();
    Field[] variables = new Field[text.length];

    for (int i = 0; i < variables.length; i++)
      //vieleicht wenn es nicht protected ist??
      variables[i] = allVariables[i];

    //nur public Variablen sind in dem Array, welche geändert werden dürfen
    for (int i = 0; i < text.length; i++)
    try {
      //wird sowieso weg optimiert, sieht aber schöner aus
      int posx = i*(sizex+rand);
      Object value;
      String name = variables[i].getName();
      //etwas kürzer für den Benutzer
      if (name.equals("momentumWeakness"))
        name = "momentum";


      if (F.getValue(name).equals(""))
        value = variables[i].get(main);
      else
        value = F.getValue(name);

      text[i] = new TextField((posx+rand)%x, (int(posx/x)*(sizey+rand)+rand)%y, sizex, sizey,
        variables[i].getType().toString(), name, value);
    }
    catch(IllegalAccessException e) {
      consoleText.add("Einige Variablen wurden gelöscht. Das Programm wird beendet.");
      e.printStackTrace();
      noLoop();
    }

    for (TextField f : text)
      f.ignore = true;

    state =  States.TRAINorSHOW;

    Field[] methods = F.getClass().getFields();

    String[] methodNames = new String[methods.length];
    String[] methodTypes = new String[methods.length];
    for (int i = 0; i < methodNames.length; i++) {
      methodNames[i] = split(split(methods[i].toString(), '$')[2], '.')[1];
      methodTypes[i] = split(split(methods[i].toString(), '$')[1], ' ')[0];
    }

    // Info welche Funktionen verfügbar sind (Aktivierung, Fehler)
    methodNameText = "";
    methodNameTextError = "";
    String value;

    //wenn es nicht gespeichert ist
    if (F.getValue("errorFunction").length() == 0)
      value = F.getInstanceName(F, loss);
    else
      value = F.getValue("errorFunction");

    errorFunctionField = new TextField(150, 100, sizex, sizey, "errorFunction", "loss", value);

    //wenn es nicht gespeichert ist
    if (F.getValue("outputFunction").length() == 0)
      value = F.getInstanceName(F, outL.outNs[0].function[0]);
    else
      value = F.getValue("outputFunction");

    outputFunctionField = new TextField(width-150-sizex, 100, sizex, sizey, "outputFunction", "outL", value);//outL.outNs[0].function
    errorFunctionField.ignore = true;
    outputFunctionField.ignore = true;

    //für textWidth()
    textSize(21);
    for (int i = 0; i < methodNames.length; i++) {

      //wenn es eine Aktivierungsfunktion ist
      if (methodTypes[i].equals("Function[]")) {

        //wenn es nicht über den Rand hinaus geht
        if (textWidth(methodNameText + ", " + methodNames[i]) < width)
          methodNameText += ", " + methodNames[i];

        //wenn noch kein "..." am Ende ist
        else if (!methodNameText.substring(methodNameText.length()-3, methodNameText.length()).equals("..."))
          methodNameText += "...";
      } else if (methodTypes[i].equals("ErrorFunction")) {

        //wenn es nicht über den Rand hinaus geht
        if (textWidth(methodNameTextError + ", " + methodNames[i]) < width)
          methodNameTextError += ", " + methodNames[i];

        //wenn noch kein "..." am Ende ist
        else if (!methodNameTextError.substring(methodNameTextError.length()-3, methodNameTextError.length()).equals("..."))
          methodNameTextError += "...";
      }
    }
    // ", " entfernen
    methodNameText = methodNameText.substring(2, methodNameText.length());
    methodNameTextError = methodNameTextError.substring(2, methodNameTextError.length());
  }

  //der String der in dem Help-Field gezeigt wird
  String helpString = "";
  int sx;
  int sy;
  int px;
  int py;

  void show() {

    background(backgroundColor);

    switch(state) {

    case TRAINorSHOW:

      textSize(21);
      fill(contrast);
      stroke(30);
      rectMode(CENTER);
      sx = 150;
      sy = 50;
      px = width/4;
      py = height/2;
      rect(px, py, sx, sy);

      //train
      if (mousePressed && mouseX < px + sx/2 && mouseX > px - sx/2 && mouseY < py+sy/2 && mouseY > py-sy/2) {
        //einfaches mouseReleased
        mousePressed = false;
        state = States.LAYERS;

        for (int i = 0; i < layerFields.size(); i++)
          layerFields.get(i).ignore = false;

        errorFunctionField.ignore = false;
        outputFunctionField.ignore = false;
      }

      //show
      px += width/2;
      stroke(30);
      fill(contrast);
      rect(px, py, sx, sy);
      if (mousePressed && mouseX < px + sx/2 && mouseX > px - sx/2 && mouseY < py+sy/2 && mouseY > py-sy/2) {
        //einfaches mouseReleased
        mousePressed = false;
        showSettings();
        task = Tasks.AI;
        taskSetup(task);
        return;
      }

      //help
      px = width-50;
      py = height-35;
      sx /= 2;
      sy /= 2;
      stroke(30);
      fill(contrast);
      rect(px, py, sx, sy+10);
      if (mousePressed && mouseX < px + sx/2 && mouseX > px - sx/2 && mouseY < py+sy/2 && mouseY > py-sy/2) {
        //einfaches mouseReleased
        mousePressed = false;
        try {
          if (latest)
            openURL("https://github.com/JakobZoephel/Neuronales-Netz/blob/main/README.md");
          else
            openURL("https://github.com/JakobZoephel/Neuronales-Netz");
        }
        catch(Exception e) {
          if (visualConsole == null) {
            String[] args = {"console"};
            visualConsole = new Console();
            PApplet.runSketch(args, visualConsole);
          }
          consoleText.add("Browser konnte nicht geöffnet werden.");
          consoleText.add("URL: https://github.com/JakobZoephel/Neuronales-Netz/blob/main/README.md");
        }
      }

      //wenn das Bild geladen wurde
      if (equations != null) {

        if (visualConsole == null) {
          String[] args = {"console"};
          visualConsole = new Console();
          PApplet.runSketch(args, visualConsole);
        }

        showSettings();
        show = false;
        showConsole = true;
        if (lm == null)
          lm = new LayerManager();

        if (q == null) {
          String[] args = {""};
          q =  new Question();
          PApplet.runSketch(args, q);
        }

        if (equationRecognizer == null)
          equationRecognizer = new EquationRecognition(equations, q.getDecision("Slower but better?"));
        else
          if (q.getDecision("Slower but better?"))
            equationRecognizer.slowRecognition(equations);
          else
            equationRecognizer.fastRecognition(equations);

        equations = null;
      }

      fill(textColor);
      textAlign(CENTER, CENTER);
      text("train AI", width/4, height/2);
      text("use AI", width/2+width/4, height/2);
      text("or drag in an image", width/2, height*0.8);
      if (latest)
        text("help", width-50, height-40);
      else
        text("update", width-50, height-40);


      if (!latest) {
        fill(red(textColor)-100, green(textColor), blue(textColor)-100);
        text("please update this program >>", width/1.3, height-40);
      }

      break;

    case LAYERS:

      rectMode(CENTER);
      pushMatrix();
      //wheel++ == scrolling
      translate(0, wheel);

      for (int t = 0; t < layerFields.size(); t++)
        layerFields.get(t).show();

      textAlign(CENTER, CENTER);
      fill(255, 100, 80);
      text("Hidden-Layers", width/2, layerOffset-20);

      popMatrix();

      fill(contrast);
      stroke(30);
      rectMode(CORNER);

      //Übersicht welche Funktionen es gibt
      rect(0, 0, width, 25);
      rect(0, 25, width, 25);

      textSize(21);
      fill(textColor);
      textAlign(LEFT, TOP);

      text("  Aktivierungsfunktionen: " + methodNameText, 0, 0);
      text("  Fehlerfunktionen: " + methodNameTextError, 0, 25);

      //Fehlerfunktion und Output-Funktion
      errorFunctionField.show();
      outputFunctionField.show();
      break;

    case VARIABLES:

      for (TextField t : text)
        t.show();
      break;

    case RUN:

      hiddenLayers = new HiddenL[layerFields.size()];

      for (TextField t : text)
        t.setValue();

      for (TextField f : layerFields)
        f.setValue();

      errorFunctionField.setValue();
      outputFunctionField.setValue();

      //start
      task = Tasks.AI;
      taskSetup(task);
      state = States.lastState(state);
    }

    if (state != States.TRAINorSHOW) {

      //Pfeile

      int px = width-sizex/4;
      int py = height-sizey/2;

      noFill();
      stroke(30);
      rectMode(CORNER);
      rect(width-sizex, height-sizey, sizex, sizey, 5);

      textAlign(CENTER, CENTER);

      fill(60, 170, 50);
      beginShape();
      vertex(px, py-2*arrowSize);
      vertex(px, py-6*arrowSize);

      //Spitze
      vertex(px+6*arrowSize, py);

      vertex(px, py+6*arrowSize);
      vertex(px, py+2*arrowSize);

      vertex(px-9*arrowSize, py+2*arrowSize);
      vertex(px-9*arrowSize, py-2*arrowSize);

      vertex(px, py-2*arrowSize);
      endShape();

      fill(170, 60, 50);

      px = width-sizex+30;
      py = floor(height-sizey/2);
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

      //help menu
      rectMode(CORNER);
      fill(contrast);
      stroke(20);
      rect(0, height-30, width-sizex, 30);
      textAlign(LEFT, TOP);
      //textAlign(CENTER, CENTER);

      textSize(20);
      fill(textColor);
      text(helpString, 20, height-27);
    }
  }

  void savePanel() {

    PrintWriter w = createWriter(loadFile("data.txt"));

    for (int i = 0; i < layerFields.size(); i++)
      w.println(i + "hiddenLayers:::" + layerFields.get(i).userInput);

    w.println("outputFunction:::" + outputFunctionField.userInput);
    w.println("errorFunction:::" + errorFunctionField.userInput);


    for (TextField f : text)
      w.println(f.name + ":::" + f.userInput);
    w.flush();
    w.close();
  }

  void stateSetup(States state) {
    if (start)return;

    switch(state) {

    case TRAINorSHOW:
    case RUN:
      for (TextField t : text)
        t.ignore = true;
      for (int t = 0; t < layerFields.size(); t++)
        layerFields.get(t).ignore = true;
      errorFunctionField.ignore = true;
      outputFunctionField.ignore = true;
      break;

    case LAYERS:
      for (TextField t : text)
        t.ignore = true;
      for (int t = 0; t < layerFields.size(); t++)
        layerFields.get(t).ignore = false;
      errorFunctionField.ignore = false;
      outputFunctionField.ignore = false;
      break;

    case VARIABLES:
      for (TextField t : text)
        t.ignore = false;
      for (int t = 0; t < layerFields.size(); t++)
        layerFields.get(t).ignore = true;
      errorFunctionField.ignore = true;
      outputFunctionField.ignore = true;
      break;
    }
  }

  void showSettings() {

    show = true;
    train = false;
    loadWeights = true;
    saveWeights = false;
    loadExamples = false;
    saveExamples = false;
    showConsole = false;
  }


  void mousePressed() {
    if (ignorePanel)return;

    for (TextField t : text)
      t.mousePressed();

    for (int t = 0; t < layerFields.size(); t++)
      layerFields.get(t).mousePressed();

    errorFunctionField.mousePressed();
    outputFunctionField.mousePressed();
  }

  void mouseReleased() {
    if (ignorePanel || state == States.TRAINorSHOW)return;

    //wenn es der rechte Pfeil ist
    if (mouseX > width-sizex/2 && mouseX < width && mouseY > height-sizey && mouseY < height && !(start && States.getIndex(state) == States.values().length-2)) {
      state = States.nextState(state);
      stateSetup(state);
      //wenn es der linke Pfeil ist
    } else if (mouseX > width-sizex && mouseX < width-sizex/2 && mouseY > height-sizey && mouseY < height && !(start && States.getIndex(state) == 1)) {
      state = States.lastState(state);
      stateSetup(state);
    }

    for (TextField t : text)
      if (!t.TYPE.equals("boolean"))
        t.mouseReleased();
    for (int t = 0; t < layerFields.size(); t++)
      layerFields.get(t).mouseReleased();

    errorFunctionField.mouseReleased();
    outputFunctionField.mouseReleased();
  }

  void keyTyped() {
    if (ignorePanel)return;

    for (TextField t : text)
      if (!t.TYPE.equals("boolean"))
        t.keyTyped();
    for (int t = 0; t < layerFields.size(); t++)
      layerFields.get(t).keyTyped();

    errorFunctionField.keyTyped();
    outputFunctionField.keyTyped();
  }

  void keyReleased() {
    if (ignorePanel)return;

    for (TextField t : text)
      if (!t.TYPE.equals("boolean"))
        t.keyReleased();

    for (int t = 0; t < layerFields.size(); t++)
      layerFields.get(t).keyReleased();

    errorFunctionField.keyReleased();
    outputFunctionField.keyReleased();
  }

  void keyPressed() {
    if (ignorePanel)return;

    for (TextField t : text)
      if (!t.TYPE.equals("boolean"))
        t.keyPressed();

    for (int t = 0; t < layerFields.size(); t++)
      layerFields.get(t).keyPressed();

    errorFunctionField.keyPressed();
    outputFunctionField.keyPressed();
  }

  void mouseWheel(MouseEvent event) {
    if (state != States.LAYERS || ignorePanel)return;
    e = event.getCount();
    wheel += e*10;

    if (layerFields.get(layerFields.size()-1).pos.y + sizey > height)
      wheel = constrain(wheel, -layerFields.get(layerFields.size()-1).pos.y - sizey + height, 0);
    else
      wheel = 0;
  }


  class TextField {

    PVector pos, size;
    String userInput = "";
    String name = "";
    //help string wird gezeigt wenn das Feld ausgewählt ist
    String help = "";
    boolean userIsTyping = false;
    color strokeColor = color(255, 100);
    String TYPE;
    int writeIndex = 1;
    private Object value;

    <V> TextField(int px, int py, int sx, int sy, String type, String _name, V v, boolean typing) {
      this(px, py, sx, sy, type, _name, v);
      userIsTyping = typing;
    }

    <V> TextField(int px, int py, int sx, int sy, String type, String _name, V v) {

      this.TYPE = type;

      name = _name;

      for (int i = 0; i < helpDocumentation.length; i++)
        if (split(helpDocumentation[i], ":::")[0].equals(name)) {
          help = split(helpDocumentation[i], ":::")[1];
          break;
        }

      if (TYPE.equals("boolean"))
        value = Boolean.parseBoolean(v.toString());
      else
        value = v;

      // help = _help;
      pos = new PVector(px, py);
      size = new PVector(sx, sy);
      userInput = "" + v;

      if (TYPE.equals("float") || TYPE.equals("double"))
        writeIndex = userInput.length();

      textSize(21);
      noFill();
      stroke(strokeColor);
    }

    int x, y;
    //ob schon "|" gezeichnet wurde
    boolean strich;
    //damit der Strich viieel coooler ist
    boolean cool = false;
    //ob die events ignoriert werden sollen
    boolean ignore = false;
    //für einen Zyklus ignorieren, damit für eine kurze zeit die events deaktiviert werden
    boolean tempIgnore = false;

    void show() {
      if (tempIgnore) {
        ignore = false;
        tempIgnore = false;
      }
      textSize(21);
      if (userIsTyping && !helpString.equals(help))
        helpString = this.help;

      pushMatrix();

      noFill();
      stroke(100, 100);
      rectMode(CORNER);
      rect(pos.x, pos.y, size.x, size.y, 5);
      fill(250, 100, 0);
      textAlign(LEFT, TOP);

      if (!TYPE.equals("[HiddenL"))
        text(name, pos.x + size.x/2-textWidth(name)/2, pos.y, size.x, size.y);

      fill(206, 39, 44);
      translate(size.x/2-textWidth(userInput)/2, 20);
      if (TYPE.equals("boolean"))
        text(userInput, pos.x, pos.y, size.x, size.y);

      //offset da size.y nur sizey/2, ist anstatt sizey
      else if (TYPE.equals("[HiddenL"))
        pos.y -= size.y/2;


      if (cool && !TYPE.equals("boolean")) {
        x = 0;
        y = 0;
        strich = false;

        color fadeColor = fade();
        for (int i=0; i <= userInput.length(); i++) {

          if (userIsTyping) {
            fill(fadeColor);
            if (i == writeIndex || i == userInput.length()) {
              if (i == userInput.length()) {
                if (!strich)
                  text("|", pos.x+x%(size.x-10), pos.y+y, size.x, size.y);
              } else {
                strich = true;
                text("|", pos.x+x%(size.x-10), pos.y+y, size.x, size.y);
                x += textWidth("|");
              }
            }
          }

          if (i != userInput.length()) {

            if (state == States.LAYERS) {
              String[] split =  split(userInput, ':');

              //wenn es ein hiddenLayer ist
              if (split.length == 2) {

                if (F.availibleActivationFunction(F, split[1]))
                  fill(textColor);
                else
                  fill(255, 0, 0);

                //wenn es eine out oder error function ist
              } else {
                if (name == "outL") {
                  if (F.availibleActivationFunction(F, userInput))
                    fill(textColor);
                  else fill(255, 0, 0);
                  //wenn es eine Fehlerfunktion ist
                } else
                  if (F.availibleErrorFunction(F, userInput))
                    fill(textColor);
                  else
                  fill(255, 0, 0);
              }
            } else
              fill(textColor);

            text(str(userInput.charAt(i)), pos.x+x%(size.x-10), pos.y+y, size.x, size.y);

            x += textWidth(userInput.charAt(i));
            y = int((x/(size.x-10)))*30;
          }
        }
      } else if (!TYPE.equals("boolean")) {
        if (state == States.LAYERS) {
          String[] split =  split(userInput, ':');

          //wenn es ein hiddenLayer ist
          if (split.length == 2) {

            if (F.availibleActivationFunction(F, split[1]))
              fill(textColor);

            //wenn es eine out oder error function ist
          } else {
            if (name == "outL") {
              if (F.availibleActivationFunction(F, userInput))
                fill(textColor);
              else fill(255, 0, 0);
              //wenn es eine Fehlerfunktion ist
            } else
              if (F.availibleErrorFunction(F, userInput))
                fill(textColor);
              else
              fill(255, 0, 0);
          }
        } else
          fill(textColor);

        textAlign(LEFT, TOP);

        text(userInput, pos.x, pos.y, size.x, size.y);

        if (userIsTyping) {
          fill(fade());

          String chars;
          if (writeIndex == userInput.length())
            chars = userInput;
          else
            chars = userInput.substring(0, writeIndex);

          x = (int)textWidth(chars);
          text("|", pos.x+x-2, pos.y, size.x, size.y);
        }
      }
      if (TYPE.equals("[HiddenL"))
        pos.y += size.y/2;

      popMatrix();
    }

    boolean dark = false;
    int fadeValue = 0;

    int fade() {
      if (keyPressed)
        return 255;
      //if(millis() %30 == 0)fadeValue = 0;
      //else fadeValue = 255;
      if (fadeValue <= 0)dark = false;
      if (fadeValue >= 255)dark = true;
      if (dark)
        fadeValue -= 4;
      else
        fadeValue += 4;

      return fadeValue;
    }

    void updateStrokeColor() {
      if (userIsTyping) {
        strokeColor = color(255, 0, 0);
      } else {
        strokeColor = color(255);
      }
    }

    void keyTyped() {

      if (!userIsTyping || ignore) return;
      if (textWidth(userInput)+10 >= size.x) {
        checkBackspace(1);
        return;
      }
      switch(TYPE) {
      case "long":
      case "int":
      case "char":
      case "byte":
        //vieleicht und dass der Wert nicht zu groß ist=
        if (key >= '0' && key <= '9') {
          addChar();
        }
        checkBackspace(1);

        break;
      case "double":
      case "float":
        if (((key >= '0' && key <= '9') || key == '.')) {
          addChar();
        }
        checkBackspace(1);
        break;

      case "boolean":
        break;

      case "[HiddenL":
        if (charOnSide(':', "right")) {
          if (key >= '0' && key <= '9')
            addChar();
        } else if (charOnSide(':', "left"))
          if (key >= 'a' && key <= 'z')
            addChar();

        checkBackspace(1);
        break;

      case "errorFunction":
        if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z'))
          addChar();
        checkBackspace(1);
        break;

      case "outputFunction":
        if (key >= 'a' && key <= 'z')
          addChar();
        checkBackspace(1);

        break;

      default:
        if (key != CODED)
          addChar();
      }
    }

    void checkBackspace(int amount) {
      if (key != BACKSPACE)return;

      if (TYPE.equals("[HiddenL") && layerFields.size() > 1)
        if (userInput.length() == 1) {
          if (layerFields.indexOf(this) != 0)
            layerFields.get(layerFields.indexOf(this)-1).userIsTyping = true;
          else
            layerFields.get(1).userIsTyping = true;

          //die anderen Felder sollen nachrücken
          for (int i = layerFields.indexOf(this); i < layerFields.size(); i++)
            layerFields.get(i).pos.y -= size.y;

          layerFields.remove(this);
        }

      if (userInput.length() > 0 && writeIndex > amount-1) {
        String begin = userInput.substring(0, writeIndex-amount);
        String end = userInput.substring(writeIndex, userInput.length());

        if (TYPE.equals("[HiddenL"))
          //':' darf nicht entfernt werden
          if (userInput.charAt(writeIndex-1) == ':' || userInput.equals(":"))
            return;

        userInput = begin + end;
        writeIndex -= amount;
      }
    }

    boolean charOnSide(char c, String side) {

      if (side.equals("left")) {
        for (int i = writeIndex-1; i >= 0; i--)
          if (userInput.charAt(i) == c)
            return true;
      } else if (side.equals("right")) {
        for (int i = writeIndex; i < userInput.length(); i++)
          if (userInput.charAt(i) == c)
            return true;
      }
      return false;
    }

    void addChar() {
      userInput = userInput.substring(0, writeIndex) + key + userInput.substring(writeIndex, userInput.length());
      if (userInput.length() == 0)
        userInput += key;
      writeIndex++;
    }

    void keyReleased() {
      if (!userIsTyping || ignore) return;

      if (key == ENTER && TYPE.equals("[HiddenL")) {
        String value;
        if (layerFields.size() < hiddenLayers.length)
          value = hiddenLayers[layerFields.size()-1].hiddenNs.length + ":";
        else
          value = ":";

        TextField t = new TextField(int(pos.x),
          //true setzt userIsTyping auf true
          int(pos.y+size.y), (int)size.x, (int)size.y, "[HiddenL", "hiddenLayers", value, true);

        insertElement(layerFields, t, layerFields.indexOf(this));

        //damit nicht rekursiv layer hinzugefügt werden
        layerFields.get(layerFields.indexOf(this)+1).ignore = true;
        layerFields.get(layerFields.indexOf(this)+1).tempIgnore = true;

        userIsTyping = false;
      }

      int wait = millis();
      if (wait+100 < millis())
        if (key == CODED && wait >= 4) {
          if (keyCode == RIGHT) writeIndex++;
          else if (keyCode == LEFT) writeIndex--;
          wait = 0;
        }
      writeIndex = constrain(writeIndex, 0, userInput.length());
    }


    void keyPressed() {
      if (!userIsTyping || ignore) return;

      if (key == CODED) {
        if (keyCode == RIGHT)
          writeIndex++;
        else if (keyCode == LEFT)
          writeIndex--;

        else if (TYPE.equals("[HiddenL")) {
          if (keyCode == UP && layerFields.indexOf(this)-1 >= 0) {
            layerFields.get(layerFields.indexOf(this)-1).userIsTyping = true;
            userIsTyping = false;
          }
          if (keyCode == DOWN && layerFields.indexOf(this)+1 < layerFields.size()) {
            layerFields.get(layerFields.indexOf(this)+1).userIsTyping = true;
            //damit nicht rekursiv mehr layer hinzugefügt werden
            layerFields.get(layerFields.indexOf(this)+1).tempIgnore = true;
            layerFields.get(layerFields.indexOf(this)+1).ignore = true;

            userIsTyping = false;
          }
        }
      }
      writeIndex = constrain(writeIndex, 0, userInput.length());
    }

    void mouseReleased() {

      //easter egg
      if (mouseX < 20  && mouseY < 20)
        cool = !cool;
    }

    void mousePressed() {

      if (ignore)return;

      if (onTextField(mouseX, mouseY)) {
        if (TYPE.equals("boolean")) {
          value = !(boolean) value;
          userInput = str((boolean) value);
        }
        userIsTyping = true;
      } else if (userIsTyping) {
        helpString = "";
        userIsTyping = false;
      }
      updateStrokeColor();
    }


    <T> void insertElement(ArrayList<T> list, T object, int index) {

      //erstmal nur damit ein weiteres Element da ist
      list.add(object);
      for (int i = list.size()-1; i > index+1; i--) {
        list.set(i, list.get(i-1));

        //die y-Koordinate muss verändert werden
        if (list.get(i) instanceof TextField) {
          TextField field = (TextField) list.get(i);
          field.pos.y += size.y;
        }
      }
      list.set(index+1, object);
    }

    void setValue() {

      //wurde umbenannt, jetzt wieder zurück zum original Namen
      if (name.equals("momentum"))
        name = "momentumWeakness";

      //irgendeine Variable, damit field irgendeinen Wert hat und es keine null-pointer Warnung gibt
      Field field = main.getClass().getDeclaredFields()[0];
      //Field field = null;
      try {
        field = main.getClass().getDeclaredField(name);
      }
      catch(Exception e) {
        consoleText.add("Error while setting values.");
        noLoop();
      }

      try {
        switch(TYPE) {
        case "boolean":
          //wird schon am Anfang geparsed
          field.setBoolean(main, (boolean) value);

          break;

        case "double":
          value = (Object)userInput;
          value = Double.parseDouble((value.toString()));
          field.setDouble(main, (double) value);
          break;

        case "float":
          value = (Object)userInput;
          value = float(value.toString());
          field.setFloat(main, (float) value);

          break;

        case "long":
          value = (Object)userInput;
          value = Long.parseLong((value.toString()));
          field.setLong(main, (long) value);
          break;

        case "int":
          value = (Object)userInput;
          value = int(value.toString());
          field.setInt(main, (int) value);
          break;

        case "byte":
          value = (Object)userInput;
          value = byte(int(value.toString()));
          field.setByte(main, (byte) value);
          break;

        case "errorFunction":
          loss = (ErrorFunction) F.getClass().getField(errorFunctionField.userInput).get(F);
          break;

        case "outputFunction":
          outL = new OutputLayer(charset.length, (Function[]) F.getClass().getField(outputFunctionField.userInput).get(F), loss);
          break;

        case "[HiddenL":

          int index = layerFields.indexOf(this);
          String[] split = split(trim(layerFields.get(index).userInput), ":");

          hiddenLayers[index] = new HiddenL(int(split[0]),
            (Function[]) F.getClass().getField(split[1]).get(F));

          //wenn es der erste Layer ist
          if (index == 0)
            //der erste Hidden-Layer bekommt die Trainingsbeispiele
            hiddenLayers[index].createWeights(trainExampleData);
          else
            //so viele Inputs wie der Layer davor Neuronen hat
            hiddenLayers[index].createWeights(hiddenLayers[index-1].hiddenNs.length);
          break;
        }
      }
      catch (Exception e) {
        consoleText.add("error on field " + field);
        noLoop();
      }
      if (name.equals("momentumWeakness"))
        name = "momentum";
    }

    boolean onTextField(float x, float y) {
      return (x > pos.x && x < pos.x+ + size.x &&
        y > pos.y+wheel && y < pos.y+wheel + size.y);
    }
  }
}
