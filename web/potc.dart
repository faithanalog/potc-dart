library potc;

import 'dart:html';
import 'dart:web_gl' as webgl;
import 'dart:web_audio';
import 'dart:typed_data';
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
  game.start();
  game.canvas.focus();
}

class Game {

  webgl.RenderingContext gl;

  List<bool> keys = new List(256);
  Menu curMenu = null;

  CanvasElement canvas;

  static const int width = 160;
  static const int height = 120;

  Game() {

  }

  void start() {
    canvas = document.getElementById("disp_canvas");
    gl = canvas.getContext3d(alpha: false, antialias: false);

    blitter = new Blitter(gl);

    Future.wait([Art.load(gl), Sound.load()]).then((_) {
      print("Loaded!");
      curMenu = new TitleMenu();

      canvas.onKeyDown.listen((evt) {
        evt.preventDefault();
        keys[evt.keyCode] = true;
      });

      canvas.onKeyUp.listen((evt) {
        evt.preventDefault();
        keys[evt.keyCode] = false;
      });

      window.animationFrame.then(render);
    });
  }

  void render(double time) {
    window.animationFrame.then(render);

    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT);

    if (curMenu != null) {
      curMenu.render(gl);
      curMenu.tick(this, keys[38], keys[40], keys[37], keys[39], keys[32]);

      keys[38] = false;
      keys[40] = false;
      keys[37] = false;
      keys[39] = false;
      keys[32] = false;
    }

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