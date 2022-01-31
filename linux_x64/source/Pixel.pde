boolean rightMouseButtonUsed = false;

class Pixel {
  PVector loc;
  color c;
  //the perceptron it will move towards
  int perceptronIndex;
  PVector vel;

  Pixel(int x, int y, color c, int perceptronIndex_) {
    loc = new PVector(x, y);
    this.perceptronIndex = perceptronIndex_;
    this.c = c;
    vel = new PVector(random(1, 2), random(-2, 2));
    vel.setMag(1);
  }

  void show(PApplet p, boolean changeColor) {

    if (changeColor)
      p.stroke(changeColor(c));
    else
      p.stroke(c);
    p.point(loc.x, loc.y);
    //p.rect(loc.x, loc.y, 2,2);
    loc.add(vel);
  }

  void setMovement() {
    loc.set(0, height/2);
    vel.set(new PVector(nv.pos[0][perceptronIndex].x + nv.offset, nv.pos[0][perceptronIndex].y).sub(loc));
    if (rightMouseButtonUsed)
      vel.setMag(4);
    else
      vel.setMag(vel.mag()/50);
  }

  int changeColor(color col_) {
    if (col_ == -1)
      return color(0);
    else
      return color(255);
  }
}
