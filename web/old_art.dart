part of potc;

Future<Texture> loadTexture(String path, webgl.RenderingContext gl) {
  Completer<Texture> comp = new Completer();
  var img = new ImageElement();
  img.onLoad.first.then((e) {
    var tex = new Texture(img, gl);
    comp.complete(tex);
  });
  img.src = path;
  return comp.future;
}

//class Bitmap {
//
//  //6 verts * 8 floats per vert
//  //1 vert:
//  //X Y
//  //U V
//  //R G B A
//  static Float32List verts = new Float32List(6 * 8);
//
//  int width, height;
//  webgl.Texture tex;
//
//  Bitmap(ImageElement img, webgl.RenderingContext gl) {
//    width = img.width;
//    height = img.height;
//    tex = gl.createTexture();
//    gl.bindTexture(webgl.TEXTURE_2D, tex);
//    gl.texParameteri(webgl.TEXTURE_2D, webgl.TEXTURE_MIN_FILTER, webgl.NEAREST);
//    gl.texParameteri(webgl.TEXTURE_2D, webgl.TEXTURE_MAG_FILTER, webgl.NEAREST);
//    gl.texParameteri(webgl.TEXTURE_2D, webgl.TEXTURE_WRAP_S, webgl.CLAMP_TO_EDGE);
//    gl.texParameteri(webgl.TEXTURE_2D, webgl.TEXTURE_WRAP_T, webgl.CLAMP_TO_EDGE);
//    gl.texImage2DImage(webgl.TEXTURE_2D, 0, webgl.RGBA, webgl.RGBA, webgl.UNSIGNED_BYTE, img);
//  }
//
//  Float32List drawVerts(double x, double y, Vector4 color) {
//    return drawPartVerts(x, y, 0.0, 0.0, width.toDouble(), height.toDouble(), color);
//  }
//
//  Float32List drawPartVerts(double x, double y, double xo, double yo, double w, double h, Vector4 color) {
//    Float32List verts = new Float32List(6 * 8);
//
//
//    double u0 = xo / width.toDouble();
//    double u1 = u0 + w / width.toDouble();
//    double v0 = yo / height.toDouble();
//    double v1 = v0 + h / height.toDouble();
//
//
//    //Top right
//    verts[0] = x + w; verts[1] = y;
//    verts[2] = u1; verts[3] = v0;
//    verts[4] = color.r; verts[5] = color.g; verts[6] = color.b; verts[7] = color.a;
//
//    //Top left
//    verts[8] = x; verts[0] = y;
//    verts[10] = u0; verts[11] = v0;
//    verts[12] = color.r; verts[13] = color.g; verts[14] = color.b; verts[15] = color.a;
//
//    //Bottom left
//    verts[16] = x; verts[17] = y + h;
//    verts[18] = u0; verts[19] = v1;
//    verts[20] = color.r; verts[21] = color.g; verts[22] = color.b; verts[23] = color.a;
//
//    //Bottom left
//    verts[24] = x; verts[25] = y + h;
//    verts[26] = u0; verts[27] = v1;
//    verts[28] = color.r; verts[29] = color.g; verts[30] = color.b; verts[31] = color.a;
//
//    //Bottom right
//    verts[32] = x + w; verts[33] = y + h;
//    verts[34] = u1; verts[34] = v1;
//    verts[36] = color.r; verts[37] = color.g; verts[38] = color.b; verts[39] = color.a;
//
//    //Top right
//    verts[40] = x + w; verts[41] = y;
//    verts[42] = u1; verts[43] = v0;
//    verts[44] = color.r; verts[45] = color.g; verts[46] = color.b; verts[47] = color.a;
//    return verts;
//  }
//
//  webgl.Buffer drawPartBuffer(double x, double y, double xo, double yo, double w, double h, Vector4 color, webgl.RenderingContext gl) {
//    Float32List verts = drawPartVerts(x, y, xo, yo, w, h, color);
//
//    var buff = gl.createBuffer();
//    gl.bindBuffer(webgl.ARRAY_BUFFER, buff);
//    gl.bufferDataTyped(webgl.ARRAY_BUFFER, verts, webgl.STATIC_DRAW);
//    return buff;
//  }
//
//}

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
  Float32List verts = new Float32List(6 * 8);

  webgl.RenderingContext gl;
  webgl.Buffer buffer;

  Blitter(this.gl) {
    buffer = gl.createBuffer();
  }

  void drawBitmap(Texture bmp, double x, double y, [Vector4 color = null]) {
    drawBitmapPart(bmp, x, y, 0.0, 0.0, bmp.width.toDouble(), bmp.height.toDouble(), color);
  }

  void drawBitmapPart(Texture bmp, double x, double y, double xo, double yo, double w, double h, [Vector4 color = null]) {
    if (color == null) {
      color = Colors.WHITE;
    }
    double u0 = xo / bmp.width.toDouble();
    double u1 = u0 + w / bmp.width.toDouble();
    double v0 = yo / bmp.height.toDouble();
    double v1 = v0 + h / bmp.height.toDouble();


    //Top right
    verts[0] = x + w; verts[1] = y;
    verts[2] = u1; verts[3] = v0;
    verts[4] = color.r; verts[5] = color.g; verts[6] = color.b; verts[7] = color.a;

    //Top left
    verts[8] = x; verts[9] = y;
    verts[10] = u0; verts[11] = v0;
    verts[12] = color.r; verts[13] = color.g; verts[14] = color.b; verts[15] = color.a;

    //Bottom left
    verts[16] = x; verts[17] = y + h;
    verts[18] = u0; verts[19] = v1;
    verts[20] = color.r; verts[21] = color.g; verts[22] = color.b; verts[23] = color.a;

    //Bottom left
    verts[24] = x; verts[25] = y + h;
    verts[26] = u0; verts[27] = v1;
    verts[28] = color.r; verts[29] = color.g; verts[30] = color.b; verts[31] = color.a;

    //Bottom right
    verts[32] = x + w; verts[33] = y + h;
    verts[34] = u1; verts[35] = v1;
    verts[36] = color.r; verts[37] = color.g; verts[38] = color.b; verts[39] = color.a;

    //Top right
    verts[40] = x + w; verts[41] = y;
    verts[42] = u1; verts[43] = v0;
    verts[44] = color.r; verts[45] = color.g; verts[46] = color.b; verts[47] = color.a;

    gl.bindBuffer(webgl.ARRAY_BUFFER, buffer);
    gl.bufferDataTyped(webgl.ARRAY_BUFFER, verts, webgl.STREAM_DRAW);
    gl.bindTexture(webgl.TEXTURE_2D, bmp.tex);

    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);
    gl.enableVertexAttribArray(2);

    gl.vertexAttribPointer(0, 2, webgl.FLOAT, false, 32, 0);
    gl.vertexAttribPointer(1, 2, webgl.FLOAT, false, 32, 8);
    gl.vertexAttribPointer(2, 4, webgl.FLOAT, false, 32, 16);

    gl.drawArrays(webgl.TRIANGLES, 0, 6);
    gl.disableVertexAttribArray(0);
    gl.disableVertexAttribArray(1);
    gl.disableVertexAttribArray(2);
  }


  static String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ.,!?\"'/\\<>()[]{}" +
  "abcdefghijklmnopqrstuvwxyz_               " +
  "0123456789+-=*:;ÖÅÄå                      ";
  void drawString(String string, double x, double y, [Vector4 col = null]) {
    for (int i = 0; i < string.length; i++) {
      int ch = chars.codeUnits.indexOf(string.codeUnitAt(i));
      if (ch < 0) continue;

      double xx = (ch % 42).toDouble();
      double yy = (ch ~/ 42).toDouble();
      drawBitmapPart(Art.font, x + i * 6.0, y, xx * 6.0, yy * 8.0, 5.0, 8.0, col);
    }
  }


}

class Art {
  static Bitmap floors;
  static Bitmap font;
  static Bitmap gamepanel;
  static Bitmap items;
  static Bitmap sky;
  static Bitmap sprites;
  static Bitmap walls;

  static Bitmap logo;

  static Future load(webgl.RenderingContext gl) {
    Completer comp = new Completer();
    Future.wait([
        loadTexture("res/tex/floors.png", gl),
        loadTexture("res/tex/font.png", gl),
        loadTexture("res/tex/gamepanel.png", gl),
        loadTexture("res/tex/items.png", gl),
        loadTexture("res/tex/sky.png", gl),
        loadTexture("res/tex/sprites.png", gl),
        loadTexture("res/tex/walls.png", gl),
        loadTexture("res/gui/logo.png", gl)
    ]).then((List<Bitmap> texList) {
      floors = texList[0];
      font = texList[1];
      gamepanel = texList[2];
      items = texList[3];
      sky = texList[4];
      sprites = texList[5];
      walls = texList[6];
      logo = texList[7];
      comp.complete();
    });
    return comp.future;

  }
}