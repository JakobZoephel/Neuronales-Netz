class Digit extends PApplet {

  final int drawSize = 38;
  float[] example;
  ArrayList<Pixel> pigments= new ArrayList<Pixel>(width*height);//pixels.length

  Digit() {
    super();
  }

  void settings() {
    size(drawWindowSize, drawWindowSize);
  }

  void setup() {
    surface.setTitle("please draw a digit");
    background(255);
    fill(0);
    allOutOfScreen = false;
    finishedDrawing = false;
  }

  void draw() {

    //wenn "again?" gedrückt wird
    if (!mousePressed && !finishedDrawing)
      background(255);

    if (finishedDrawing && !allOutOfScreen)
      animation();
  }

  void mousePressed() {
    if (train || finishedDrawing) return;
    ellipse(mouseX, mouseY, drawSize, drawSize);
  }

  void mouseDragged() {
    if (train || finishedDrawing) return;
    ellipse(mouseX, mouseY, drawSize, drawSize);
  }

  void mouseReleased() {

    if (train || finishedDrawing) return;
    finishedDrawing = true;
    number = F.copyWindowIntoImage(this);
    F.dimImage(number, 80);

    if (mouseButton == RIGHT)rightMouseButtonUsed = true;
    else if (mouseButton == LEFT)rightMouseButtonUsed = false;
    PGraphics number = F.copyWindowIntoPGraphics(this);
    number = F.cut(number);
    //max pooling
    number = F.pooling(number, kernel_size, x -> max(x));
    number = F.blackWhite(number);
    example = float(F.graphicsToVector(number));
    lm.feedForward(example);
    println(charset[int(F.max_pool_array(lm.ergebnis))]);

    loadPixels();
    int perceptronIndex = 0;
    for (int y = 0; y < height; y += kernel_size) {
      for (int x = 0; x < width; x += kernel_size) {
        for (int i = x; i < kernel_size + x; i++) {
          for (int j = y; j < kernel_size + y; j++) {
            int pix = index(i, j);
            if (pixels[pix] != color(0) || i%2 == 0 || j%2 == 0 || random(1) > 0.5|| random(1) > 0.5) continue;
            else pigments.add(new Pixel(pix%width, pix/height, pixels[pix], perceptronIndex));
          }
        }
        perceptronIndex++;
      }
    }
    updatePixels();
    surface.setLocation(50, 300);

    main.surface.setLocation(600, 100);
    main.surface.setSize(nv.pg.width, nv.pg.height);
    main. surface.setVisible(true);
    nv.showResult();
  }

  int index(int x, int y) {
    return (x + y * width);
  }

  boolean allOutOfScreen = false;
  int inScreen = 0;
  PImage number;

  void animation() {

    background(255);
    for (int i = pigments.size()-1; i >= 0; i--)
      if (pigments.get(i).loc.x < width) {
        pigments.get(i).show(this, false);
        inScreen++;
      }
    // wenn die meisten Partikel aus dem Bildschirm sind
    if (inScreen < 50) allOutOfScreen = true;
    else inScreen = 0;

    if (!allOutOfScreen) return;
    background(number);

    for (int i=0; i < pigments.size(); i++)
      pigments.get(i).setMovement();
  }

  void setDigitLocation(int x, int y) {
    surface.setLocation(x, y);
  }

  void exit() {

    freeze();
  }

  void freeze() {

    ignorePanel = false;
    //um sicher zu gehem
    if (panel != null)
      panel.state = States.TRAINorSHOW;

    task = Tasks.CONTROL_PANEL;

    taskSetup(task);
    this.surface.setVisible(false);
    //falls es auf false ist
    main.surface.setVisible(true);
    this.noLoop();
  }

  void deFreeze() {

    inScreen = 0;
    pigments.clear();
    allOutOfScreen = false;
    finishedDrawing = false;

    surface.setLocation(displayWidth/2-this.width/2, displayHeight/2-this.height/2);
    this.surface.setVisible(true);
    this.loop();
  }
}
