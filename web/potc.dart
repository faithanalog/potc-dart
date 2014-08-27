library potc;

import 'dart:html';
import 'dart:web_gl' as webgl;
// import 'dart:web_audio';
// import 'dart:typed_data';
import 'dart:async';

import 'package:vector_math/vector_math.dart';
import 'package:dtmark/dtmark.dart' as dtmark;

part 'art.dart';
part 'menu.dart';
part 'sound.dart';

Game game;

Blitter blitter;

void main() {
  game = new Game();
  game.launchGame();
  game.canvas.focus();
}

class Game extends dtmark.BaseGame {

  Menu curMenu = null;

  static const int width = 160;
  static const int height = 120;

  Game(): super(document.getElementById("disp_canvas"));

  @override
  webgl.RenderingContext createContext3d() {
    return canvas.getContext3d(alpha: false, antialias: false);
  }

  @override
  void launchGame() {
    blitter = new Blitter(gl);

    Future.wait([Art.load(gl), Sound.load()]).then((_) {
      print("Loaded!");
      curMenu = new TitleMenu();
      super.launchGame();
    });
  }

  @override
  void render() {
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT);

    if (curMenu != null) {
      curMenu.render(gl);
    }
  }

  @override
  void tick() {
    if (curMenu != null) {
      curMenu.tick(this, isKeyDown(38), isKeyDown(40), isKeyDown(37), isKeyDown(39), isKeyDown(32));

      setKey(38, false);
      setKey(40, false);
      setKey(37, false);
      setKey(39, false);
      setKey(32, false);
    }
  }

  /**
   * Launches a new game of PotC
   */
  void newGame() {

  }

}

const String vertShaderSrc = '''
uniform mat4 u_transform;

attribute vec3 a_pos;
attribute vec2 a_texCoord;
attribute vec4 a_color;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  v_texCoord = a_texCoord;
  v_color = a_color;
  gl_Position = u_transform * vec4(a_pos, 1.0);
}
''';

const String fragShaderSrc = '''
precision mediump float;
uniform sampler2D u_texture;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  vec4 color = texture2D(u_texture, v_texCoord);
  if (color.rgb == vec3(1.0, 0.0, 1.0) || color.a * v_color.a == 0.0) {
    discard;
  }
  gl_FragColor = color * v_color;
}
''';
