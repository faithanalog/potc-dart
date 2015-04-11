library potc;

import 'dart:html';
import 'dart:web_gl' as webgl;
// import 'dart:web_audio';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as Math;

import 'package:vector_math/vector_math.dart';
import 'package:dtmark/dtmark.dart' as dtmark;

import 'package:image/image.dart';

part 'art.dart';
part 'menu.dart';
part 'sound.dart';
part 'level.dart';
part 'block.dart';
part 'entity.dart';
part 'sprite.dart';
part 'item.dart';
part 'shaders.dart';

Game game;
Blitter blitter;
Viewport viewport;
Math.Random rand = new Math.Random();

void main() {
  game = new Game();
  game.launchGame();
  game.canvas.focus();
}

//TODO: Consider preloading levels
class Game extends dtmark.BaseGame {

  int time = 0;
  Level level = null;
  Player player = null;
  int pauseTime = 0;
  Menu menu = null;

  static const int width = 160;
  static const int height = 120;

  static const int WIDTH = width;
  static const int HEIGHT = height;
  static const int PANEL_HEIGHT = 29;
  static const int VIEWPORT_HEIGHT = height - PANEL_HEIGHT;

  Game(): super(document.getElementById("disp_canvas"));

  @override
  webgl.RenderingContext createContext3d() {
    return canvas.getContext3d(alpha: false, antialias: false);
  }

  @override
  void launchGame() {
    blitter = new Blitter(gl);
    viewport = new Viewport(gl);

    Future.wait([Art.load(gl), Sound.load()]).then((_) {
      print("Loaded!");
      menu = new TitleMenu();
      super.launchGame();
    });
  }

  @override
  void render() {
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT);
    if (level != null) {

      if (pauseTime > 0 || level.loading) {
        gl.clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT);
        String msg = "Entering ${level.name}";
        blitter.drawString(msg, ((width - msg.length * 6) ~/ 2).toDouble(), (VIEWPORT_HEIGHT - 8) ~/ 2 + 1.0, 0x111111);
        blitter.drawString(msg, ((width - msg.length * 6) ~/ 2).toDouble(), ((VIEWPORT_HEIGHT - 8) ~/ 2).toDouble(), 0x555544);
      } else if (player != null) {
        viewport.renderGame(game);

        int xx = (player.turnBob * 32).floor();
        int yy = (Math.sin(player.bobPhase * 0.4) * 1 * player.bob + player.bob * 2).floor();

        bool itemUsed = player.itemUseTime > 0;
        Item item = player.items[player.selectedSlot];

        if (itemUsed) xx = yy = 0;
        xx += width ~/ 2;
        yy += height - PANEL_HEIGHT - 15 * 3;
        if (item != Item.none) {
          blitter.drawBitmapPartScaled(Art.items, 3, xx.toDouble(), yy.toDouble(), 16 * item.icon + 1, 16 + 1 + (itemUsed ? 16 : 0), 15, 15, item.color);
        }
      }

      blitter.drawBitmapPart(Art.panel, 0.0, (height - PANEL_HEIGHT).toDouble(), 0, 0, width, PANEL_HEIGHT, 0x707070);

      if (player == null) {
        return;
      }

      bool itemUsed = player.itemUseTime > 0;
      Item item = player.items[player.selectedSlot];

      blitter.drawString("å", 3.0, height - 26 + 0.0, 0x00FFFF);
      blitter.drawString("${player.keys}/4", 10.0, height - 26 + 0.0, 0xffffff);
      blitter.drawString("Ä", 3.0, height - 26 + 8.0, 0xffff00);
      blitter.drawString(player.loot.toString(), 10.0, height - 26 + 8.0, 0xffffff);
      blitter.drawString("Å", 3.0, height - 26 + 16.0, 0xff0000);
      blitter.drawString(player.health.toString(), 10.0, height - 26 + 16.0, 0xffffff);

      for (int i = 0; i < 8; i++) {
        Item slotItem = player.items[i];
        if (slotItem != Item.none) {
          blitter.drawBitmapPart(Art.items, 30 + i * 16.0, height - PANEL_HEIGHT + 2.0, slotItem.icon * 16, 0, 16, 16, slotItem.color);
          if (slotItem == Item.pistol) {
            String str = player.ammo.toString();
            blitter.drawString(str, 30 + i * 16 + 17 - str.length * 6.0, height - PANEL_HEIGHT + 1 + 10.0, 0x555555);
          }
          if (slotItem == Item.potion) {
            String str = player.potions.toString();
            blitter.drawString(str, 30 + i * 16 + 17 - str.length * 6.0, height - PANEL_HEIGHT + 1 + 10.0, 0x555555);
          }
        }
      }

      blitter.drawBitmapPart(Art.items, 30.0 + game.player.selectedSlot * 16, height - PANEL_HEIGHT + 2.0, 0, 48, 17, 17, 0xFFFFFF);

      blitter.drawString(item.name, 26.0 + (8 * 16 - item.name.length * 4) ~/ 2, height - 9.0, 0xffffff);

    }

    if (menu != null) {
      darkenScreen();
      menu.render(gl);
    }

    if (document.activeElement != canvas) {
      darkenScreen();
      if (dtmark.BaseGame.frameTime ~/ 450 % 2 != 0) {
        String msg = "Click to focus!";
        blitter.drawString(msg, ((width - msg.length * 6) ~/ 2).toDouble(), height ~/ 3 + 4.0, 0xffffff);
      }
    }
  }

  /**
   * Draws a black rectangle with 80% transparency on the screen
   */
  void darkenScreen() {
    gl.enable(webgl.BLEND);
    gl.blendFunc(webgl.SRC_ALPHA, webgl.ONE_MINUS_SRC_ALPHA);
    //Darken the game
    var batch = blitter.batch;
    batch.begin();
    batch.color.setValues(0.0, 0.0, 0.0, 0.8);
    batch.fillRect(0.0, 0.0, Game.width.toDouble(), Game.height.toDouble());
    batch.end();
    batch.color.setValues(1.0, 1.0, 1.0, 1.0);
    gl.disable(webgl.BLEND);
  }

  @override
  void tick() {
    if (pauseTime > 0 && (level == null || !level.loading)) {
      pauseTime--;
      return;
    }

    time++;

    //SHIFT, ALT, CTRL
    bool strafe = isKeyDown(17) || isKeyDown(16);

    //Left key or numpad 4
    bool leftKey = isKeyDown(37) || isKeyDown(100);

    //Right key or numpad 6
    bool rightKey = isKeyDown(39) || isKeyDown(102);

    //W or up arrow or numpad 8
    bool up = isKeyDown(87) || isKeyDown(38) || isKeyDown(104);

    //S or down arrow or numpad 2
    bool down = isKeyDown(83) || isKeyDown(40) || isKeyDown(98);

    //A or leftKey
    bool left = isKeyDown(65) || (strafe && leftKey);

    //D or rightKey
    bool right = isKeyDown(68) || (strafe && rightKey);

    //Q or leftKey
    bool turnLeft = isKeyDown(81) || (!strafe && leftKey);

    //E or rightKey
    bool turnRight = isKeyDown(69) || (!strafe && rightKey);

    //Space bar
    bool use = isKeyDown(32);

    for (int i = 0; i < 8; i++) {
      //1 key + i
      if (isKeyDown(49 + i) && player != null) {
        setKey(49 + i, false);
        player.selectedSlot = i;
        player.itemUseTime = 0;
      }
    }

    //Escape key
    if (isKeyDown(27)) {
      setKey(27, false);
      if (menu == null) {
        menu = new PauseMenu();
      }
    }

    if (use) {
      //Space b ar
      setKey(32, false);
    }

    if (menu != null) {
      //Up
      setKey(87, false);
      setKey(38, false);
      setKey(104, false);

      //Down
      setKey(83, false);
      setKey(40, false);
      setKey(98, false);

      //A,D
      setKey(65, false);
      setKey(68, false);

      menu.tick(this, up, down, left, right, use);
    } else if (player != null && !level.loading) {
      player.tickPlayer(up, down, left, right, turnLeft, turnRight);
      if (use) {
        player.activate();
      }

      level.tick();
    }
  }

  /**
   * Launches a new game of PotC
   */
  void newGame() {
    Level._loadedLevels.clear();
    level = new Level.load(this, "start");
    level.onLoad.then((_) {
      player = new Player();
      player.level = level;
      level.player = player;
      player.x = level.xSpawn.toDouble();
      player.z = level.ySpawn.toDouble();
      level.addEntity(player);
      player.rot = Math.PI + 0.4;
    });
  }

  void switchLevel(String name, int id) {
    pauseTime = 30;
    level.removeEntityImmediately(player);
    level = new Level.load(this, name);
    level.onLoad.then((_) {
      level.findSpawn(id);
      player.x = level.xSpawn.toDouble();
      player.z = level.ySpawn.toDouble();
      (level.getBlock(level.xSpawn, level.ySpawn) as LadderBlock).wait = true;
      player.x += Math.sin(player.rot) * 0.2;
      player.z += Math.cos(player.rot) * 0.2;
      level.addEntity(player);
    });
  }

  void getLoot(Item item) { player.addLoot(item); }

  void win(Player player) { menu = new WinMenu(player); }

  void lose(Player player) { menu = new LoseMenu(player); }

}

//===Code copied from java's Random#nextGaussian()===
double nextNextGaussian;
bool haveNextNextGaussian = false;

double nextGaussian() {
   if (haveNextNextGaussian) {
     haveNextNextGaussian = false;
     return nextNextGaussian;
   } else {
     double v1, v2, s;
     do {
       v1 = 2 * rand.nextDouble() - 1;   // between -1.0 and 1.0
       v2 = 2 * rand.nextDouble() - 1;   // between -1.0 and 1.0
       s = v1 * v1 + v2 * v2;
     } while (s >= 1 || s == 0);
     double multiplier = Math.sqrt(-2 * Math.log(s)/s);
     nextNextGaussian = v2 * multiplier;
     haveNextNextGaussian = true;
     return v1 * multiplier;
   }
 }
 //===End copied code===
