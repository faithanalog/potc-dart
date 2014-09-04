part of potc;

abstract class Level {

  static Map<String, Level> _loadedLevels = new Map();

  List<Block> blocks = null;
  int width = 0;
  int height = 0;
  Block solidWall = new SolidBlock();

  int xSpawn = 0;
  int ySpawn = 0;

  //Rendering parameters
  int wallCol = 0xB3CEE2;
  int floorCol = 0x9CA09B;
  int ceilCol = 0x9CA09B;

  int wallTex = 0;
  int floorTex = 0;
  int ceilTex = 0;

  //If we're still loading the image
  bool loading = true;

  List<Entity> entities = new List();
  Game game;
  String name;

  Player player;

  Future<Level> _onLoad;

  Level();

  /**
   * Loads a level called [name] from the appropriate image file.
   */
  factory Level.load(Game game, String name) {
    if (_loadedLevels.containsKey(name)) {
      return _loadedLevels[name];
    }

    Completer<Level> comp = new Completer();

    Level level;
    switch (name) {
      case "crypt":
        level = new CryptLevel();
        break;
      case "dungeon":
        level = new DungeonLevel();
        break;
      case "ice":
        level = new IceLevel();
        break;
      case "overworld":
        level = new OverworldLevel();
        break;
      case "start":
        level = new StartLevel();
        break;
      case "temple":
        level = new TempleLevel();
        break;
    }
    level._onLoad = comp.future;

    var req = new HttpRequest();
    req.open("GET", "res/level/$name.png");
    req.responseType = "arraybuffer";
    req.onLoad.first.then((_) {

      //This is the only way to accurately get the pixel data with
      //the alpha encoded values, since drawing to a 2d canvas
      //with alpha screws up the colors
      var inData = new Uint8List.view(req.response);
      var img = decodePng(inData);
      var imgdata = img.getBytes();

      var pixels = new Int32List(img.width * img.height);
      for (int i = 0; i < pixels.length; i++) {
        int o = i * 4;

        int r = imgdata[o];
        int g = imgdata[o + 1];
        int b = imgdata[o + 2];
        int a = imgdata[o + 3];

        pixels[i] = (a << 24) | (r << 16) | (g << 8) | b;
      }
      level.init(game, name, img.width, img.height, pixels);
      _loadedLevels[name] = level;
      level.loading = false;
      comp.complete(level);
    });
    req.send();
    return level;
  }

  void init(Game game, String name, int w, int h, Int32List pixels) {
    this.game = game;
    player = game.player;

    solidWall.col = wallCol;
    solidWall.tex = wallTex;
    width = w;
    height = h;
    blocks = new List(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int off = x + y * w;
        int color = pixels[off] & 0xFFFFFF;
        int id = 255 - ((pixels[off] >> 24) & 0xFF);

        var block = new Block.fromColor(color);
        block.id = id;

        if (block.tex == -1) block.tex = wallTex;
        if (block.floorTex == -1) block.floorTex = floorTex;
        if (block.ceilTex == -1) block.ceilTex = ceilTex;
        if (block.col == -1) block.col = wallCol;
        if (block.floorCol == -1) block.floorCol = floorCol;
        if (block.ceilCol == -1) block.ceilCol = ceilCol;

        blocks[off] = block;
        block.level = this;
        block.x = x;
        block.y = y;
      }
    }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int off = x + y * w;
        int col = pixels[off] & 0xFFFFFF;
        decorateBlock(x, y, blocks[off], col);
      }
    }
  }

  void addEntity(Entity entity) {
    entities.add(entity);
    entity.level = this;
    entity.updatePos();
  }

  void removeEntityImmediately(Player player) {
    entities.remove(player);
    getBlock(player.xTileO, player.zTileO).removeEntity(player);
  }

  void decorateBlock(int x, int y, Block block, int col) {
    block.decorate(this, x, y);
    if (col == 0xFFFF00) {
      xSpawn = x;
      ySpawn = y;
    }

    double ex = x.toDouble();
    double ey = y.toDouble();
    if (col == 0xAA5500) addEntity(new BoulderEntity(ex, ey));
    if (col == 0xFF0000) addEntity(new BatEntity(ex, ey));
    if (col == 0xFF0001) addEntity(new BatBossEntity(ex, ey));
    if (col == 0xFF0002) addEntity(new OgreEntity(ex, ey));
    if (col == 0xFF0003) addEntity(new BossOgre(ex, ey));
    if (col == 0xFF0004) addEntity(new EyeEntity(ex, ey));
    if (col == 0xFF0005) addEntity(new EyeBossEntity(ex, ey));
    if (col == 0xFF0006) addEntity(new GhostEntity(ex, ey));
    if (col == 0xFF0007) addEntity(new GhostBossEntity(ex, ey));
    if (col == 0x1A2108 || col == 0xFF0007) {
      block.floorTex = 7;
      block.ceilTex = 7;
    }

    if (col == 0xC6C6C6) block.col = 0xA0A0A0;
    if (col == 0xC6C697) block.col = 0xA0A0A0;
    if (col == 0x653A00) {
      block.floorCol = 0xB56600;
      block.floorTex = 3 * 8 + 1;
    }

    if (col == 0x93FF9B) {
      block.col = 0x2AAF33;
      block.tex = 8;
    }

  }

  Block getBlock(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= width) {
      return solidWall;
    }
    return blocks[x + y * width];
  }

  bool containsBlockingEntity(double x0, double y0, double x1, double y1) {
    int xc = ((x1 + x0) / 2).floor();
    int zc = ((y1 + y0) / 2).floor();
    int rr = 2;
    for (int z = zc - rr; z <= zc + rr; z++) {
      for (int x = xc - rr; x <= xc + rr; x++) {
        List<Entity> es = getBlock(x, z).entities;
        for (int i = 0; i < es.length; i++) {
          Entity e = es[i];
          if (e.isInside(x0, y0, x1, y1)) return true;
        }
      }
    }
    return false;
  }

  bool containsBlockingNonFlyingEntity(double x0, double y0, double x1, double y1) {
    int xc = ((x1 + x0) / 2).floor();
    int zc = ((y1 + y0) / 2).floor();
    int rr = 2;
    for (int z = zc - rr; z <= zc + rr; z++) {
      for (int x = xc - rr; x <= xc + rr; x++) {
        for (var entity in getBlock(x, z).entities) {
          if (!entity.flying && entity.isInside(x0, y0, x1, y1)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void tick() {
    for (int i = 0; i < entities.length; i++) {
      var entity = entities[i];
      entity.tick();
      entity.updatePos();
      if (entity.removed) {
        entities.removeAt(i--);
      }
    }

    for (var block in blocks) {
      block.tick();
    }
  }

  void trigger(int id, bool pressed) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var block = blocks[x + y * width];
        if (block.id == id) {
          block.trigger(pressed);
        }
      }
    }
  }

  void switchLevel(int id) {

  }

  void findSpawn(int id) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var block = blocks[x + y * width];
        if (block.id == id && block is LadderBlock) {
          xSpawn = x;
          ySpawn = y;
        }
      }
    }
  }

  void getLoot(int id) {
    if (id == 20) game.getLoot(Item.pistol);
    if (id == 21) game.getLoot(Item.potion);
  }

  void win() { game.win(player); }

  void lose() { game.lose(player); }

  void showLootScreen(Item item) { game.menu = new GotLootMenu(item); }

  Future<Level> get onLoad => _onLoad;

}

class CryptLevel extends Level {
  CryptLevel() {
    floorCol = 0x404040;
    ceilCol = 0x404040;
    wallCol = 0x404040;
    name = "The Crypt";
  }

  void switchLevel(int id) {
    if (id == 1) game.switchLevel("overworld", 2);
  }

  void getLoot(int id) {
    super.getLoot(id);
    if (id == 1) game.getLoot(Item.flippers);
  }
}

class DungeonLevel extends Level {
  DungeonLevel() {
    wallCol = 0xC64954;
    floorCol = 0x8E4A51;
    ceilCol = 0x8E4A51;
    name = "The Dungeons";
  }

  @override
  void init(Game game, String name, int w, int h, Int32List pixels) {
    super.init(game, name, w, h, pixels);
    super.trigger(6, true);
    super.trigger(7, true);
  }

  @override
  void switchLevel(int id) {
    if (id == 1) game.switchLevel("start", 2);
  }

  @override
  void getLoot(int id) {
    super.getLoot(id);
    if (id == 1) game.getLoot(Item.powerGlove);
  }

  @override
  void trigger(int id, bool pressed) {
    super.trigger(id, pressed);
    if (id == 5) super.trigger(6, !pressed);
    if (id == 4) super.trigger(7, !pressed);
  }
}

class IceLevel extends Level {
  IceLevel() {
    floorCol = 0xB8DBE0;
    ceilCol = 0xB8DBE0;
    wallCol = 0x6BE8FF;
    name = "The Frost Cave";
  }

  @override
  void switchLevel(int id) {
    if (id == 1) game.switchLevel("overworld", 5);
  }

  @override
  void getLoot(int id) {
    super.getLoot(id);
    if (id == 1) game.getLoot(Item.skates);
  }
}

class OverworldLevel extends Level {
  OverworldLevel() {
    ceilTex = -1;
    floorCol = 0x508253;
    floorTex = 8 * 3;
    wallCol = 0xA0A0A0;
    name = "The Island";
  }

  @override
  void switchLevel(int id) {
    if (id == 1) game.switchLevel("start", 1);
    if (id == 2) game.switchLevel("crypt", 1);
    if (id == 3) game.switchLevel("temple", 1);
    if (id == 5) game.switchLevel("ice", 1);
  }

  @override
  void getLoot(int id) {
    super.getLoot(id);
    if (id == 1) game.getLoot(Item.cutters);
  }
}

class StartLevel extends Level {
  StartLevel() {
    name = "The Prison";
  }

  @override
  void switchLevel(int id) {
    if (id == 1) game.switchLevel("overworld", 1);
    if (id == 2) game.switchLevel("dungeon", 1);
  }
}

class TempleLevel extends Level {
  int triggerMask = 0;

  TempleLevel() {
    floorCol = 0x8A6496;
    ceilCol = 0x8A6496;
    wallCol = 0xCFADDB;
    name = "The Temple";
  }

  @override
  void switchLevel(int id) {
    if (id == 1) game.switchLevel("overworld", 3);
  }

  @override
  void getLoot(int id) {
    super.getLoot(id);
    if (id == 1) game.getLoot(Item.skates);
  }

  @override
  void trigger(int id, bool pressed) {
    triggerMask |= 1 << id;
    if (!pressed) triggerMask ^= 1 << id;

    if (triggerMask == 14) {
      super.trigger(1, true);
    } else {
      super.trigger(1, false);
    }
  }
}
