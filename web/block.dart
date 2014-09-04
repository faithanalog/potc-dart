part of potc;

class Block {

  bool blocksMotion = false;
  bool solidRender = false;

  List<String> messages;

  List<Sprite> sprites = new List();
  List<Entity> entities = new List();

  int tex = -1;
  int col = -1;

  int floorCol = -1;
  int ceilCol = -1;

  int floorTex = -1;
  int ceilTex = -1;

  Level level;
  int x, y;

  int id;

  Block() {}

  factory Block.fromColor(int color) {
    switch(color) {
    case 0x93FF9B: return new SolidBlock();
    case 0x009300: return new PitBlock();
    case 0xFFFFFF: return new SolidBlock();
    case 0x00FFFF: return new VanishBlock();
    case 0xFFFF64: return new ChestBlock();
    case 0x0000FF: return new WaterBlock();
    case 0xFF3A02: return new TorchBlock();
    case 0x4C4C4C: return new BarsBlock();
    case 0xFF66FF: return new LadderBlock(false);
    case 0x9E009E: return new LadderBlock(true);
    case 0xC1C14D: return new LootBlock();
    case 0xC6C6C6: return new DoorBlock();
    case 0x00FFA7: return new SwitchBlock();
    case 0x009380: return new PressurePlateBlock();
    case 0xFF0005: return new IceBlock();
    case 0x3F3F60: return new IceBlock();
    case 0xC6C697: return new LockedDoorBlock();
    case 0xFFBA02: return new AltarBlock();
    case 0x749327: return new SpiritWallBlock();
    case 0x1A2108: return new Block();
    case 0x00C2A7: return new FinalUnlockBlock();
    case 0x000056: return new WinBlock();
    default: return new Block();
    }
  }

  void addSprite(Sprite sprite) => sprites.add(sprite);

  bool use(Level level, Item item) => false;

  void tick() {
    for (int i = 0; i < sprites.length; i++) {
      Sprite sprite = sprites[i];
      sprite.tick();
      if (sprite.removed) {
        sprites.removeAt(i--);
      }
    }
  }

  void removeEntity(Entity entity) { entities.remove(entity); }

  void addEntity(Entity entity) { entities.add(entity); }

  bool blocks(Entity entity) => blocksMotion;

  void decorate(Level level, int x, int y) {}

  double getFloorHeight(Entity entity) => 0.0;

  double getWalkSpeed(Player player) => 1.0;

  double getFriction(Player player) => 0.6;

  void trigger(bool pressed) {}


}

class SolidBlock extends Block {
  SolidBlock() {
    solidRender = true;
    blocksMotion = true;
  }
}

class PitBlock extends Block {
  bool filled = false;

  PitBlock() {
    floorTex = 1;
    blocksMotion = true;
  }

  @override
  void addEntity(Entity entity) {
    super.addEntity(entity);
    if (!filled && entity is BoulderEntity) {
      entity.remove();
      filled = true;
      blocksMotion = false;
      addSprite(new Sprite(0.0, 0.0, 0.0, 8 + 2, BoulderEntity.COLOR));
      Sound.thud.play();
    }
  }

  @override
  bool blocks(Entity entity) {
    if (entity is BoulderEntity) return false;
    return blocksMotion;
  }
}

class VanishBlock extends SolidBlock {
  bool gone = false;
  VanishBlock() {
    tex = 1;
  }

  @override
  bool use(Level level, Item item) {
    if (gone) return false;

    gone = true;
    blocksMotion = false;
    solidRender = false;
    Sound.crumble.play();

    for (int i = 0; i < 32; i++) {
      var sprite = new RubbleSprite();
      sprite.col = col;
      addSprite(sprite);
    }

    return true;
  }
}

class ChestBlock extends Block {
  bool open = false;
  Sprite chestSprite;

  ChestBlock() {
    tex = 1;
    blocksMotion = true;

    chestSprite = new Sprite(0.0, 0.0, 0.0, 8 * 2 + 0, 0xFFFF00);
    addSprite(chestSprite);
  }

  @override
  bool use(Level level, Item item) {
    if (open) return false;

    chestSprite.tex++;
    open = true;

    level.getLoot(id);
    Sound.treasure.play();

    return true;
  }
}

class WaterBlock extends Block {
  int steps = 0;

  WaterBlock() {
    blocksMotion = true;
  }

  @override
  void tick() {
    super.tick();
    steps--;
    if (steps <= 0) {
      floorTex = 8 + rand.nextInt(3);
      floorCol = 0x0000FF;
      steps = 16;
    }
  }

  @override
  bool blocks(Entity entity) {
    if (entity is Player) {
      if (entity.getSelectedItem() == Item.flippers) return false;
    }
    if (entity is Bullet) {
      return false;
    }
    return blocksMotion;
  }

  @override
  double getFloorHeight(Entity entity) {
    return -0.5;
  }

  @override
  double getWalkSpeed(Player player) {
    return 0.4;
  }
}

class TorchBlock extends Block {
  Sprite torchSprite;

  TorchBlock() {
    torchSprite = new Sprite(0.0, 0.0, 0.0, 3, 0xFFFF00);
    sprites.add(torchSprite);
  }

  @override
  void decorate(Level level, int x, int y) {
    var torchRand = new Math.Random((x + y * 1000) * 341871231);
    double r = 0.4;
    for (int i = 0; i < 1000; i++) {
      int face = torchRand.nextInt(4);
      if (face == 0 && level.getBlock(x - 1, y).solidRender) {
        torchSprite.x -= r;
        break;
      }
      if (face == 1 && level.getBlock(x, y - 1).solidRender) {
        torchSprite.z -= r;
        break;
      }
      if (face == 2 && level.getBlock(x + 1, y).solidRender) {
        torchSprite.x += r;
        break;
      }
      if (face == 3 && level.getBlock(x, y + 1).solidRender) {
        torchSprite.z += r;
        break;
      }
    }
  }

  @override
  void tick() {
    super.tick();
    if (rand.nextInt(4) == 0) {
      torchSprite.tex = 3 + rand.nextInt(2);
    }
  }
}

class BarsBlock extends Block {

  Sprite sprite;
  bool open = false;
  BarsBlock() {
    sprite = new Sprite(0.0, 0.0, 0.0, 0, 0x606060);
    addSprite(sprite);
    blocksMotion = true;
  }

  @override
  bool use(Level level, Item item) {
    if (open) return false;

    if (item == Item.cutters) {
      Sound.cut.play();
      sprite.tex = 1;
      open = true;
    }

    return true;
  }

  @override
  bool blocks(Entity entity) {
    if (open && entity is Player) return false;
    if (open && entity is Bullet) return false;
    return blocksMotion;
  }

}

class LadderBlock extends Block {

  static final int LADDER_COLOR = 0xDB8E53;
  bool wait = false;

  LadderBlock(bool down) {
    if (down) {
      floorTex = 1;
      addSprite(new Sprite(0.0, 0.0, 0.0, 8 + 3, LADDER_COLOR));
    } else {
      ceilTex = 1;
      addSprite(new Sprite(0.0, 0.0, 0.0, 8 + 4, LADDER_COLOR));
    }
  }

  @override
  void removeEntity(Entity entity) {
    super.removeEntity(entity);
    if (entity is Player) {
      wait = false;
    }
  }

  @override
  void addEntity(Entity entity) {
    super.addEntity(entity);
    if (!wait && entity is Player) {
      level.switchLevel(id);
      Sound.ladder.play();
    }
  }

}

class LootBlock extends Block {
  bool taken = false;
  Sprite sprite;

  LootBlock() {
    sprite = new Sprite(0.0, 0.0, 0.0, 16 + 2, 0xFFFF80);
    addSprite(sprite);
    blocksMotion = true;
  }

  @override
  void addEntity(Entity entity) {
    super.addEntity(entity);
    if (!taken && entity is Player) {
      sprite.removed = true;
      taken = true;
      blocksMotion = false;
      entity.loot++;
      Sound.pickup.play();
    }
  }

  @override
  bool blocks(Entity entity) {
    if (entity is Player) return false;
    return blocksMotion;
  }
}

class DoorBlock extends SolidBlock {
  bool open = false;
  double openness = 0.0;

  DoorBlock() {
    tex = 4;
    solidRender = false;
  }

  @override
  bool use(Level level, Item item) {
    open = !open;
    if (open) {
      Sound.click1.play();
    } else {
      Sound.click2.play();
    }
    return true;
  }

  @override
  void tick() {
    super.tick();

    openness = Math.min(1.0, Math.max(0.0, openness + (open ? 0.2 : -0.2)));

    double openLimit = 7 / 8;
    if (openness < openLimit && !open && !blocksMotion) {
      if (level.containsBlockingEntity(x - 0.5, y - 0.5, x + 0.5, y + 0.5)) {
        openness = openLimit;
        return;
      }
    }

    blocksMotion = openness < openLimit;
  }

  @override
  bool blocks(Entity entity) {
    double openLimit = 7 / 8;
    if (openness >= openLimit && entity is Player) return blocksMotion;
    if (openness >= openLimit && entity is Bullet) return blocksMotion;
    if (openness >= openLimit && entity is OgreEntity) return blocksMotion;
    return true;
  }
}

class SwitchBlock extends SolidBlock {
  bool pressed = false;

  SwitchBlock() {
    tex = 2;
  }

  @override
  bool use(Level level, Item item) {
    pressed = !pressed;
    tex = pressed ? 3 : 2;

    level.trigger(id, pressed);
    if (pressed) {
      Sound.click1.play();
    } else {
      Sound.click2.play();
    }
    return true;
  }
}

class PressurePlateBlock extends Block {
  bool pressed = false;

  PressurePlateBlock() {
    floorTex = 2;
  }

  @override
  void tick() {
    super.tick();
    double r = 0.2;
    bool steppedOn = level.containsBlockingNonFlyingEntity(x - r, y - r, x + r, y + r);
    if (steppedOn != pressed) {
      pressed = steppedOn;
      floorTex = pressed ? 3 : 2;

      level.trigger(id, pressed);
      if (pressed) {
        Sound.click1.play();
      } else {
        Sound.click2.play();
      }
    }
  }

  @override
  double getFloorHeight(Entity entity) {
    return pressed ? -0.02 : 0.02;
  }
}

class IceBlock extends Block {
  IceBlock() {
    blocksMotion = false;
    floorTex = 16;
  }

  @override
  void tick() {
    super.tick();
    floorCol = 0x8080FF;
  }

  @override
  double getWalkSpeed(Player player) {
    return player.getSelectedItem() == Item.skates ? 0.05 : 1.4;
  }

  @override
  double getFriction(Player player) {
    return player.getSelectedItem() == Item.skates ? 0.98 : 1.0;
  }

  @override
  bool blocks(Entity entity) {
    if (entity is Player) return false;
    if (entity is Bullet) return false;
    if (entity is EyeBossEntity) return false;
    if (entity is EyeEntity) return false;
    return true;
  }
}

class LockedDoorBlock extends DoorBlock {
  LockedDoorBlock() {
    tex = 5;
  }

  @override
  bool use(Level level, Item item) => false;

  @override
  void trigger(bool pressed) {
    open = pressed;
  }
}

class AltarBlock extends Block {
  bool filled = false;
  Sprite sprite;

  AltarBlock() {
    blocksMotion = true;
    sprite = new Sprite(0.0, 0.0, 0.0, 16 + 4, 0xE2FFE4);
    addSprite(sprite);
  }

  @override
  void addEntity(Entity entity) {
    super.addEntity(entity);
    if (!filled && (entity is GhostEntity || entity is GhostBossEntity)) {
      entity.remove();
      filled = true;
      blocksMotion = false;
      sprite.removed = true;

      for (int i = 0; i < 8; i++) {
        RubbleSprite sprite = new RubbleSprite();
        sprite.col = this.sprite.col;
        addSprite(sprite);
      }

      if (entity is GhostBossEntity) {
        level.addEntity(new KeyEntity(x.toDouble(), y.toDouble()));
        Sound.bosskill.play();
      } else {
        Sound.altar.play();
      }
    }
  }
}

class SpiritWallBlock extends Block {

  SpiritWallBlock() {
    floorTex = 7;
    ceilTex = 7;
    blocksMotion = true;
    for (int i = 0; i < 6; i++) {
      var x = rand.nextDouble() - 0.5;
      var y = (rand.nextDouble() - 0.7) * 0.3;
      var z = rand.nextDouble() - 0.5;
      addSprite(new Sprite(x, y, z, 4 * 8 + 6 + rand.nextInt(2), 0x202020));
    }
  }

  @override
  bool blocks(Entity entity) {
    if (entity is Bullet) return false;
    return super.blocks(entity);
  }

}

class FinalUnlockBlock extends SolidBlock {
  bool pressed = false;

  FinalUnlockBlock() {
    tex = 8 + 3;
  }

  @override
  bool use(Level level, Item item) {
    if (pressed) return false;
    if (level.player.keys < 4) return false;

    Sound.click1.play();
    pressed = true;
    level.trigger(id, true);

    return true;
  }
}

class WinBlock extends Block {
  @override
  void addEntity(Entity entity) {
    super.addEntity(entity);
    if (entity is Player) {
      entity.win();
    }
  }
}
