part of potc;

class Sprite {

  double x, y, z;
  int tex;
  int col = 0x606060;
  bool removed = false;

  Sprite(this.x, this.y, this.z, this.tex, this.col);

  void tick() {}
}

class RubbleSprite extends Sprite {
  double xa, ya, za;

  RubbleSprite() : super(rand.nextDouble() - 0.5, rand.nextDouble() * 0.8, rand.nextDouble() - 0.5, 2, 0x555555) {
    xa = rand.nextDouble() - 0.5;
    ya = rand.nextDouble();
    za = rand.nextDouble() - 0.5;
  }

  @override
  void tick() {
    x += xa * 0.03;
    y += ya * 0.03;
    z += za * 0.03;
    ya -= 0.1;
    if (y < 0) {
      y = 0.0;
      xa *= 0.8;
      za *= 0.8;
      if (rand.nextDouble() < 0.04) {
        removed = true;
      }
    }
  }
}

class PoofSprite extends Sprite {
  int life = 20;

  PoofSprite(double x, double y, double z) : super(x, y, z, 5, 0x222222);

  void tick() {
    if (life-- <= 0) removed = true;
  }
}
