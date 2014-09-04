part of potc;

class Colors {

  static Map<int, Vector4> usedColors = new Map();

  static Vector4 WHITE = new Vector4(1.0, 1.0, 1.0, 1.0);

  static Vector4 create(int rgb) {
    if (usedColors.containsKey(rgb)) {
      return usedColors[rgb];
    }
    rgb &= 0xFFFFFF;
    int r = (rgb >> 16) & 0xFF;
    int g = (rgb >> 8) & 0xFF;
    int b = (rgb) & 0xFF;
    var col = new Vector4(r / 255, g / 255, b / 255, 1.0);
    usedColors[rgb] = col;
    return col;
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
    batch.shader.bindAttribLocation(0, "a_position");
    batch.shader.bindAttribLocation(1, "a_texCoord");
    batch.shader.bindAttribLocation(2, "a_color");
    batch.shader.link();
  }

  void drawBitmap(dtmark.Texture bmp, double x, double y, [int color = null]) {
    Vector4 colVec = color == null ? Colors.WHITE : Colors.create(color);
    batch.color.setFrom(colVec);
    batch.begin();
    batch.drawTexRegionUV(bmp, x, y, bmp.width.toDouble(), bmp.height.toDouble(), 0.0, 1.0, 1.0, 0.0);
    batch.end();
  }

  void drawBitmapPart(dtmark.Texture bmp, double x, double y, int xo, int yo, int w, int h, [int color = null]) {
    Vector4 colVec = color == null ? Colors.WHITE : Colors.create(color);
    batch.color.setFrom(colVec);
    batch.begin();
    //Upside down texture on Y axis
    batch.drawTexRegion(bmp, x, y, w.toDouble(), h.toDouble(), xo, yo + h, w, -h);
    batch.end();
  }

  void drawBitmapPartScaled(dtmark.Texture bmp, int scale, double x, double y, int xo, int yo, int w, int h, [int color = null]) {
    Vector4 colVec = color == null ? Colors.WHITE : Colors.create(color);
    batch.color.setFrom(colVec);
    batch.begin();
    //Upside down texture on Y axis
    batch.drawTexRegion(bmp, x, y, w.toDouble() * scale, h.toDouble() * scale, xo, yo + h, w, -h);
    batch.end();
  }


  static String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ.,!?\"'/\\<>()[]{}" +
  "abcdefghijklmnopqrstuvwxyz_               " +
  "0123456789+-=*:;ÖÅÄå                      ";
  void drawString(String string, double x, double y, [int color = null]) {
    Vector4 colVec = color == null ? Colors.WHITE : Colors.create(color);
    batch.color.setFrom(colVec);
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

class Viewport extends Blitter {

  final Float32List verts = new Float32List(9 * 65536);

  webgl.Buffer vertBuff;
  webgl.Buffer indBuff;

  webgl.Framebuffer fbo;
  dtmark.Texture fboTex;

  dtmark.Shader shader;
  dtmark.Shader hurtShader;

  dtmark.Texture _lastTex = null;

  Matrix4 projection = new Matrix4.identity();
  Matrix4 modelView = new Matrix4.identity();
  Matrix4 transform = new Matrix4.identity();
  Vector4 color = new Vector4(1.0, 1.0, 1.0, 1.0);

  int _vOff = 0;
  int _vOffMax = 9 * 65536;
  bool _rendering = false;

  bool _texChanged = false;

  double rot;
  double xCam;
  double yCam;
  double zCam;
  double rCos;
  double rSin;

  Viewport(webgl.RenderingContext gl) : super(gl) {
    vertBuff = gl.createBuffer();
    shader = new dtmark.Shader(vertShader3dSrc, fragShader3dSrc, gl);
    setupBatchShader(shader);

    hurtShader = new dtmark.Shader(vertShaderSrc, fragShaderHurtSrc, gl);
    setupBatchShader(hurtShader);

    //Setup framebuffer
    fbo = gl.createFramebuffer();

    fboTex = new dtmark.Texture(null, gl);
    fboTex.setSize(Game.WIDTH, Game.VIEWPORT_HEIGHT);

    var fboDepth = gl.createRenderbuffer();
    gl.bindRenderbuffer(webgl.RENDERBUFFER, fboDepth);
    gl.renderbufferStorage(webgl.RENDERBUFFER, webgl.DEPTH_COMPONENT16, fboTex.width, fboTex.height);

    gl.bindFramebuffer(webgl.FRAMEBUFFER, fbo);
    gl.framebufferTexture2D(webgl.FRAMEBUFFER, webgl.COLOR_ATTACHMENT0, webgl.TEXTURE_2D, fboTex.glTex, 0);
    gl.framebufferRenderbuffer(webgl.FRAMEBUFFER, webgl.DEPTH_ATTACHMENT, webgl.RENDERBUFFER, fboDepth);

    gl.bindFramebuffer(webgl.FRAMEBUFFER, null);
    gl.bindRenderbuffer(webgl.RENDERBUFFER, null);

    //Generate indices
    var indData = new Uint16List(6 * 65536 ~/ 4);
    var index = 0;
    for (var i = 0; i < indData.length; i += 6) {
      indData[i + 0] = index;
      indData[i + 1] = index + 1;
      indData[i + 2] = index + 2;
      indData[i + 3] = index + 2;
      indData[i + 4] = index + 3;
      indData[i + 5] = index;
      index += 4;
    }
    indBuff = gl.createBuffer();
    gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, indBuff);
    gl.bufferDataTyped(webgl.ELEMENT_ARRAY_BUFFER, indData, webgl.STATIC_DRAW);
    gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, null);

    projection = makePerspectiveMatrix(60 * Math.PI / 180, Game.WIDTH / Game.VIEWPORT_HEIGHT, 0.01, 100.0);
    modelView = new Matrix4.identity();
    _lastTex;
  }

  void _switchTexture(dtmark.Texture tex) {
    if (_lastTex != tex) {
      flush();
      _texChanged = true;
      _lastTex = tex;
    }
  }

  void addVert(double x, double y, double z, double u, double v) {
    if (_vOff >= _vOffMax) {
      flush();
    }
    verts[_vOff + 0] = x;
    verts[_vOff + 1] = y;
    verts[_vOff + 2] = z;
    verts[_vOff + 3] = u;
    verts[_vOff + 4] = v;
    verts[_vOff + 5] = color.r;
    verts[_vOff + 6] = color.g;
    verts[_vOff + 7] = color.b;
    verts[_vOff + 8] = color.a;
    _vOff += 9;
  }

  void renderSprite(double x, double y, double z, int tex, int color) {
    double u0 = (tex % 8) / 8;
    double v0 = (tex ~/ 8) / 8;
    double u1 = u0 + 1 / 8;
    double v1 = v0 + 1 / 8;

    double cos = Math.cos(rot + Math.PI / 2);
    double sin = Math.sin(rot + Math.PI / 2);

    x += 0.5;
    y += 0.5;
    z += 0.5;

    double x0 = x - 0.5 * sin;
    double z0 = z - 0.5 * cos;
    double x1 = x + 0.5 * sin;
    double z1 = z + 0.5 * cos;
    double y0 = y - 0.5;
    double y1 = y + 0.5;

    this.color.setFrom(color == null ? Colors.WHITE : Colors.create(color));
    _switchTexture(Art.sprites);
    addVert(x1, y1, z1, u1, v0);
    addVert(x0, y1, z0, u0, v0);
    addVert(x0, y0, z0, u0, v1);
    addVert(x1, y0, z1, u1, v1);


    // drawTexRegion(Art.sprites, x, y, 0.5, 0.5, texX, texY, 16, 16);
  }

  void renderWall(double x0, double z0, double x1, double z1, int tex, int color) {
    renderWallPart(x0, z0, x1, z1, tex, color, 0.0, 1.0);
  }

  void renderWallPart(double x0, double z0, double x1, double z1, int tex, int color, double xt0, double xt1) {

    double u0 = ((tex % 8) + xt0) / 8;
    double v0 = (tex ~/ 8) / 8;
    double u1 = u0 + (xt1 - xt0) / 8;
    double v1 = v0 + 1 / 8;

    this.color.setFrom(color == null ? Colors.WHITE : Colors.create(color));
    _switchTexture(Art.walls);
    addVert(x1, 1.0, z1, u1, v0);
    addVert(x0, 1.0, z0, u0, v0);
    addVert(x0, 0.0, z0, u0, v1);
    addVert(x1, 0.0, z1, u1, v1);
  }

  void renderTile(double x, double z, Block block, bool ceil) {
    int col = block.floorCol;
    int tex = block.floorTex;
    if (ceil) {
      col = block.ceilCol;
      tex = block.ceilTex;
    }
    if (tex < 0) {
      return;
    }

    this.color.setFrom(col == null ? Colors.WHITE : Colors.create(col));

    double u0 = (tex  % 8) / 8;
    double v0 = (tex ~/ 8) / 8;
    double u1 = u0 + 1 / 8;
    double v1 = v0 + 1 / 8;

    double x0 = x, z0 = z, x1 = x + 1.0, z1 = z + 1.0;
    double y = ceil ? 1.0 : 0.0;

    _switchTexture(Art.floors);
    addVert(x1, y, z0, u1, v0);
    addVert(x0, y, z0, u0, v0);
    addVert(x0, y, z1, u0, v1);
    addVert(x1, y, z1, u1, v1);
  }

  void begin() {
    _rendering = true;
    _texChanged = true;
    shader.use();
    transform.setFrom(projection);
    transform.multiply(modelView);
    shader.setUniformMatrix4fv("u_transform", false, transform);
    shader.setUniform1i("u_texture", 0);

    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);
    gl.enableVertexAttribArray(2);

    gl.bindBuffer(webgl.ARRAY_BUFFER, vertBuff);
    gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, indBuff);
    gl.vertexAttribPointer(0, 3, webgl.FLOAT, false, 36, 0);
    gl.vertexAttribPointer(1, 2, webgl.FLOAT, false, 36, 12);
    gl.vertexAttribPointer(2, 4, webgl.FLOAT, false, 36, 20);
  }

  void end() {
    flush();
    gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, null);
    gl.disableVertexAttribArray(0);
    gl.disableVertexAttribArray(1);
    gl.disableVertexAttribArray(2);
    _rendering = false;
  }

  void flush() {
    if (_vOff > 0) {
      if (_texChanged) {
        if (_lastTex != null) {
          _lastTex.bind();
        }
        _texChanged = false;
      }
      gl.bufferDataTyped(webgl.ARRAY_BUFFER, new Float32List.view(verts.buffer, 0, _vOff), webgl.STREAM_DRAW);
      gl.drawElements(webgl.TRIANGLES, (_vOff ~/ 9 ~/ 4 * 6), webgl.UNSIGNED_SHORT, 0);
    }
    _vOff = 0;
  }

  void renderGame(Game game) {

		rot = Math.PI + game.player.rot;
		xCam = game.player.x + 0.5;
		yCam = game.player.z + 0.5;
		// zCam = 0.57 + Math.sin(game.player.bobPhase * 0.4) * 0.01 * game.player.bob - game.player.y;
    zCam = -0.57 + Math.sin(game.player.bobPhase * 0.4) * 0.01 * game.player.bob - game.player.y;

		rCos = Math.cos(rot);
		rSin = Math.sin(rot);

		Level level = game.level;
		int r = 6;

		int xCenter = xCam.floor();
		int zCenter = yCam.floor();


    modelView = new Matrix4.identity();
    modelView.rotateY(rot).translate(-xCam, zCam, -yCam);

    gl.enable(webgl.DEPTH_TEST);
    // gl.disable(webgl.CULL_FACE);
    gl.bindFramebuffer(webgl.FRAMEBUFFER, fbo);
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.viewport(0, 0, fboTex.width, fboTex.height);
    gl.clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT);
    begin();
		for (int zb = zCenter - r; zb <= zCenter + r; zb++) {
			for (int xb = xCenter - r; xb <= xCenter + r; xb++) {
				Block c = level.getBlock(xb, zb);
				Block e = level.getBlock(xb + 1, zb);
				Block s = level.getBlock(xb, zb + 1);

				if (c is DoorBlock) {
					double rr = 1 / 8.0;
					double openness = 1 - c.openness * 7 / 8;
					if (e.solidRender) {
						renderWallPart(xb + openness, zb + 0.5 - rr, xb + 0.0, zb + 0.5 - rr, c.tex, (c.col & 0xfefefe) >> 1, 0.0, openness);
						renderWallPart(xb + 0.0, zb + 0.5 + rr, xb + openness, zb + 0.5 + rr, c.tex, (c.col & 0xfefefe) >> 1, openness, 0.0);
						renderWallPart(xb + openness, zb + 0.5 + rr, xb + openness, zb + 0.5 - rr, c.tex, c.col, 0.5 - rr, 0.5 + rr);
					} else {
						renderWallPart(xb + 0.5 - rr, zb + 0.0, xb + 0.5 - rr, zb + openness, c.tex, c.col, openness, 0.0);
						renderWallPart(xb + 0.5 + rr, zb + openness, xb + 0.5 + rr, zb + 0.0, c.tex, c.col, 0.0, openness);
						renderWallPart(xb + 0.5 - rr, zb + openness, xb + 0.5 + rr, zb + openness, c.tex, (c.col & 0xfefefe) >> 1, 0.5 - rr, 0.5 + rr);
					}

				}

				if (c.solidRender) {
					if (!e.solidRender) {
						renderWall(xb + 1.0, zb + 1.0, xb + 1.0, zb + 0.0, c.tex, c.col);
					}
					if (!s.solidRender) {
						renderWall(xb + 0.0, zb + 1.0, xb + 1.0, zb + 1.0, c.tex, (c.col & 0xfefefe) >> 1);
					}
				} else {
					if (e.solidRender) {
						renderWall(xb + 1.0, zb + 0.0, xb + 1.0, zb + 1.0, e.tex, e.col);
					}
					if (s.solidRender) {
						renderWall(xb + 1.0, zb + 1.0, xb + 0.0, zb + 1.0, s.tex, (s.col & 0xfefefe) >> 1);
					}
				}
			}
		}

    for (int zb = zCenter - r; zb <= zCenter + r; zb++) {
      for (int xb = xCenter - r; xb <= xCenter + r; xb++) {
        Block c = level.getBlock(xb, zb);
        renderTile(xb.toDouble(), zb.toDouble(), c, false);
        renderTile(xb.toDouble(), zb.toDouble(), c, true);
      }
    }

		for (int zb = zCenter - r; zb <= zCenter + r; zb++) {
			for (int xb = xCenter - r; xb <= xCenter + r; xb++) {
				Block c = level.getBlock(xb, zb);

				for (int j = 0; j < c.entities.length; j++) {
					Entity e = c.entities[j];
					for (int i = 0; i < e.sprites.length; i++) {
						Sprite sprite = e.sprites[i];
						renderSprite(e.x + sprite.x, sprite.y, e.z + sprite.z, sprite.tex, sprite.col);
					}
				}

				for (int i = 0; i < c.sprites.length; i++) {
					Sprite sprite = c.sprites[i];
					renderSprite(xb + sprite.x, sprite.y, zb + sprite.z, sprite.tex, sprite.col);
				}
			}
		}
    end();


    gl.bindFramebuffer(webgl.FRAMEBUFFER, null);
    gl.disable(webgl.DEPTH_TEST);
    gl.viewport(0, 0, game.canvas.width, game.canvas.height);

    batch.begin();
    //Sky
    int xOff = (-(rot + Math.PI) * 512 / (Math.PI * 2)).floor() & 511;
    batch.color.setFrom(Colors.create(0xCCCCFF));
    batch.drawTexRegion(Art.sky, 0.0, 0.0, Game.WIDTH + 0.0, Art.sky.height.toDouble(), xOff, Art.sky.height, Game.WIDTH, -Art.sky.height);


    //Viewport
    batch.color.setValues(1.0, 1.0, 1.0, 1.0);
    gl.enable(webgl.BLEND);
    gl.blendFunc(webgl.SRC_ALPHA, webgl.ONE_MINUS_SRC_ALPHA);
    batch.drawTexture(fboTex, 0.0, 0.0, Game.WIDTH + 0.0, Game.VIEWPORT_HEIGHT + 0.0);
    gl.disable(webgl.BLEND);
    batch.end();

    //Hurt tex
    if (game.player.hurtTime > 0 || game.player.dead) {
      batch.shader = hurtShader;
      batch.begin();
      hurtShader.setUniform1f("hurt_time", game.player.dead ? 0.5 : 1.5 - game.player.hurtTime / 30.0);
      batch.drawTexRegionUV(Art.hurttex, 0.0, 0.0, Art.hurttex.width.toDouble(), Art.hurttex.height.toDouble(), 0.0, 1.0, 1.0, 0.0);
      batch.end();
      batch.shader = null;
    }





		// renderFloor(level);
  }

}

//I have to do this for all DTMark SpriteBatch shaders so why copy paste
void setupBatchShader(dtmark.Shader shader) {
  shader.bindAttribLocation(0, "a_position");
  shader.bindAttribLocation(1, "a_texCoord");
  shader.bindAttribLocation(2, "a_color");
  shader.link();
}

class Art {
  static dtmark.Texture floors;
  static dtmark.Texture font;
  static dtmark.Texture panel;
  static dtmark.Texture items;
  static dtmark.Texture sky;
  static dtmark.Texture sprites;
  static dtmark.Texture walls;

  static dtmark.Texture logo;

  static dtmark.Texture hurttex;

  static Future load(webgl.RenderingContext gl) {

    //Hurt texture. We set the hurt time offset as a uniform and use a custom frag shader to render.
    //(Original does some per pixel rand generation)
    //The alpha channel of each pixel is used to encode a value which is compared
    //with (1.5 - game.player.hurtTime / 30.0) at render. If the pixel's alpha is
    //greater than that value, the pixel is rendered. The resulting effect is
    //about the same as the original game
    hurttex = new dtmark.Texture.generate(gl, Game.WIDTH, Game.VIEWPORT_HEIGHT, (ctx, w, h) {

      var imgdata = ctx.createImageData(w, h);
      var data = imgdata.data;
      var pixrand = new Math.Random(111);

      for (int i = 0; i < w * h; i++) {
        double xp = ((i % w) - w / 2.0) / w * 2;
        double yp = ((i ~/ w) - h / 2.0) / h * 2;

        double alpha = Math.sqrt(xp * xp + yp * yp) - pixrand.nextDouble();
        int r = (rand.nextInt(5) ~/ 4) * 0x55;

        int o = i * 4;
        data[o] = r;
        data[o + 1] = 0;
        data[o + 2] = 0;
        data[o + 3] = Math.max(0, Math.min(0xFF, (alpha * 0xFF).floor()));
      }
      ctx.putImageData(imgdata, 0, 0);
    });

    var waitList = [];
    floors = loadTex("res/tex/floors.png", gl, waitList);
    font = loadTex("res/tex/font.png", gl, waitList);
    panel = loadTex("res/tex/gamepanel.png", gl, waitList);
    items = loadTex("res/tex/items.png", gl, waitList);
    sky = loadTex("res/tex/sky.png", gl, waitList, wrapS: webgl.REPEAT, wrapT: webgl.REPEAT);
    sprites = loadTex("res/tex/sprites.png", gl, waitList);
    walls = loadTex("res/tex/walls.png", gl, waitList);
    logo = loadTex("res/gui/logo.png", gl, waitList);
    return Future.wait(waitList);

  }

  static dtmark.Texture loadTex(String path, webgl.RenderingContext gl, List<Future> waitList,
    {int wrapS: webgl.CLAMP_TO_EDGE, int wrapT: webgl.CLAMP_TO_EDGE}) {
    var tex = new dtmark.Texture.load(path, gl,wrapS: wrapS, wrapT: wrapT);
    waitList.add(tex.onLoad);
    return tex;
  }
}
