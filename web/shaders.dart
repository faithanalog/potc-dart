part of potc;

//Normal vertex shader
const String vertShaderSrc = '''
uniform mat4 u_transform;

attribute vec2 a_pos;
attribute vec2 a_texCoord;
attribute vec4 a_color;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  v_texCoord = a_texCoord;
  v_color = a_color;
  gl_Position = u_transform * vec4(a_pos, 0.0, 1.0);
}
''';

//Fragment shader for POTC textures (magenta is transparent)
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

//3D shader for 3d world rendering
const String vertShader3dSrc = '''
uniform mat4 u_transform;

attribute vec3 a_pos;
attribute vec2 a_texCoord;
attribute vec4 a_color;

varying vec2 v_texCoord;
varying vec4 v_color;
varying float brightness;

void main() {
  v_texCoord = a_texCoord;
  // v_color = a_color;
  vec4 pos = u_transform * vec4(a_pos, 1.0);
  v_color = a_color;

  //Fog
  brightness = max(0.0, (6.0 - pos.z) / 5.0);

  gl_Position = pos;
}
''';

//Frag shader for doing the original 'post processing' effects
const String fragShader3dSrc = '''
precision mediump float;
uniform sampler2D u_texture;

varying vec2 v_texCoord;
varying vec4 v_color;
varying float brightness;

void main() {
  vec4 color = texture2D(u_texture, v_texCoord);
  if (color.rgb == vec3(1.0, 0.0, 1.0) || color.a * v_color.a == 0.0) {
    discard;
  }
  float x = floor(gl_FragCoord.x);
  float y = (90.0 - floor(gl_FragCoord.y)) * 14.0;
  float bright = ceil(brightness * 255.0) + mod(x + y, 4.0) * 4.0;
  bright = min(255.0, max(0.0, bright - mod(bright, 16.0)));
  gl_FragColor = color * v_color * (bright / 255.0);
}
''';

//Frag shader for rendering the hurt texture
const String fragShaderHurtSrc = '''
precision mediump float;
uniform sampler2D u_texture;
uniform float hurt_time;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  vec4 color = texture2D(u_texture, v_texCoord);
  if (color.a < hurt_time) {
    discard;
  }
  gl_FragColor = vec4(color.xyz, 1.0) * v_color;
}
''';
