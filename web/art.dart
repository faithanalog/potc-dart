part of potc;

class Colors {
  static Vector4 WHITE = new Vector4(1.0, 1.0, 1.0, 1.0);

  static Vector4 create(int rgb) {
    int r = (rgb >> 16) & 0xFF;
    int g = (rgb >> 8) & 0xFF;
    int b = (rgb) & 0xFF;
    return new Vector4(r / 255, g / 255, b / 255, 1.0);
  }
}

class Blitter {
  webgl.RenderingContext gl;
  dtmark.SpriteBatch batch;

  Blitter(this.gl) {
    batch = new dtmark.SpriteBatch(gl, width: 1, height: 1);
    //Upside down ortho matrix
    batch.projection = makeOrthographicMatrix(0, Game.width, Game.height, 0, -1, 1);
    batch.shader = new dtmark.Shader(vertShaderSrc, fragShaderSrc, gl);
  }

  void drawBitmap(dtmark.Texture bmp, double x, double y, [Vector4 color = null]) {
    if (color == null) {
      color = Colors.WHITE;
    }
    batch.color.setFrom(color);
    batch.begin();
    batch.drawTexRegionUV(bmp, x, y, bmp.width.toDouble(), bmp.height.toDouble(), 0.0, 1.0, 1.0, 0.0);
    batch.end();
  }

  void drawBitmapPart(dtmark.Texture bmp, double x, double y, int xo, int yo, int w, int h, [Vector4 color = null]) {
    if (color == null) {
      color = Colors.WHITE;
    }
    batch.color.setFrom(color);
    batch.begin();
    //Upside down texture on Y axis
    batch.drawTexRegion(bmp, x, y, w.toDouble(), h.toDouble(), xo, yo + h, w, -h);
    batch.end();
  }


  static String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ.,!?\"'/\\<>()[]{}" +
  "abcdefghijklmnopqrstuvwxyz_               " +
  "0123456789+-=*:;ÖÅÄå                      ";
  void drawString(String string, double x, double y, [Vector4 col = null]) {
    if (col == null) {
      col = Colors.WHITE;
    }
    batch.color.setFrom(col);
    batch.begin();
    for (int i = 0; i < string.length; i++) {
      int ch = chars.codeUnits.indexOf(string.codeUnitAt(i));
      if (ch < 0) continue;

      int xx = ch % 42;
      int yy = ch ~/ 42;
      //Upside down texture on Y axis
      batch.drawTexRegion(Art.font, x + i * 6.0, y, 5.0, 8.0, xx * 6, yy * 8 + 8, 5, -8);
    }
    batch.end();
  }


}

class Art {
  static dtmark.Texture floors;
  static dtmark.Texture font;
  static dtmark.Texture gamepanel;
  static dtmark.Texture items;
  static dtmark.Texture sky;
  static dtmark.Texture sprites;
  static dtmark.Texture walls;

  static dtmark.Texture logo;

  static Future load(webgl.RenderingContext gl) {
    var waitList = [];
    floors = loadTex("res/tex/floors.png", gl, waitList);
    font = loadTex("res/tex/font.png", gl, waitList);
    gamepanel = loadTex("res/tex/gamepanel.png", gl, waitList);
    items = loadTex("res/tex/items.png", gl, waitList);
    sky = loadTex("res/tex/sky.png", gl, waitList);
    sprites = loadTex("res/tex/sprites.png", gl, waitList);
    walls = loadTex("res/tex/walls.png", gl, waitList);
    logo = loadTex("res/gui/logo.png", gl, waitList);
    return Future.wait(waitList);

  }

  static dtmark.Texture loadTex(String path, webgl.RenderingContext gl, List<Future> waitList) {
    var tex = new dtmark.Texture.load(path, gl);
    waitList.add(tex.onLoad);
    return tex;
  }
}