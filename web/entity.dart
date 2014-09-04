part of potc;

class Entity {

  List<Sprite> sprites = new List();

  double x = 0.0, z = 0.0, rot = 0.0;
  double xa = 0.0, za = 0.0, rota = 0.0;
  double r = 0.4;

  Level level;
  int xTileO = -1;
  int zTileO = -1;
  bool flying = false;

  bool removed = false;

  void updatePos() {
    int xTile = (x + 0.5).floor();
    int zTile = (z + 0.5).floor();
    if (xTile != xTileO || zTile != zTileO) {
      level.getBlock(xTileO, zTileO).removeEntity(this);
      xTileO = xTile;
      zTileO = zTile;

      if (!removed) level.getBlock(xTileO, zTileO).addEntity(this);
    }
  }

  void remove() {
    level.getBlock(xTileO, zTileO).removeEntity(this);
    removed = true;
  }

  void move() {
    int xSteps = ((xa * 100).abs() + 1).floor();
    for (int i = xSteps; i > 0; i--) {
      double xxa = xa;
      if (isFree(x + xxa * i / xSteps, z)) {
        x += xxa * i / xSteps;
        break;
      } else {
        xa = 0.0;
      }
    }

    int zSteps = ((za * 100).abs() + 1).floor();
    for (int i = zSteps; i > 0; i--) {
      double zza = za;
      if (isFree(x, z + zza * i / zSteps)) {
        z += zza * i / zSteps;
        break;
      } else {
        za = 0.0;
      }
    }
  }

  bool isFree(double xx, double yy) {
    int x0 = (xx + 0.5 - r).floor();
    int x1 = (xx + 0.5 + r).floor();
    int y0 = (yy + 0.5 - r).floor();
    int y1 = (yy + 0.5 + r).floor();

    if (level.getBlock(x0, y0).blocks(this)) return false;
    if (level.getBlock(x1, y0).blocks(this)) return false;
    if (level.getBlock(x0, y1).blocks(this)) return false;
    if (level.getBlock(x1, y1).blocks(this)) return false;

    int xc = (xx + 0.5).floor();
    int zc = (yy + 0.5).floor();
    int rr = 2;
    for (int z = zc - rr; z <= zc + rr; z++) {
      for (int x = xc - rr; x <= xc + rr; x++) {
        for (var entity in level.getBlock(x, z).entities) {
          if (entity == this) continue;

          if (!entity.blocks(this, this.x, this.z, r) && entity.blocks(this, xx, yy, r)) {
            entity.collide(this);
            this.collide(entity);
            return false;
          }
        }
      }
    }
    return true;
  }

  void collide(Entity entity) {}

  bool blocks(Entity entity, double x2, double z2, double r2) {
    if (entity is Bullet) {
      if (entity.owner == this) return false;
    }
    if (x + r <= x2 - r2) return false;
    if (x - r >= x2 + r2) return false;

    if (z + r <= z2 - r2) return false;
    if (z - r >= z2 + r2) return false;

    return true;
  }

  bool contains(double x2, double z2) {
    if (x + r <= x2) return false;
    if (x - r >= x2) return false;

    if (z + r <= z2) return false;
    if (z - r >= z2) return false;

    return true;
  }

  bool isInside(double x0, double z0, double x1, double z1) {
    if (x + r <= x0) return false;
    if (x - r >= x1) return false;

    if (z + r <= z0) return false;
    if (z - r >= z1) return false;

    return true;
  }

  bool use(Entity source, Item item) => false;

  void tick() {}
}

class Player extends Entity {

  double bob = 0.0, bobPhase = 0.0, turnBob = 0.0;
  int selectedSlot = 0;
  int itemUseTime = 0;
  double y = 0.0, ya = 0.0;
  int hurtTime = 0;
  int health = 20;
  int keys = 0;
  int loot = 0;
  bool dead = false;
  int deadTime = 0;
  int ammo = 0;
  int potions = 0;
  Block lastBlock;
  List<Item> items = new List(8);

  bool sliding = false;
  int time = 0;

  Player() {
    r = 0.3;
    for (int i = 0; i < items.length; i++) {
      items[i] = Item.none;
    }
  }

  void tickPlayer(bool up, bool down, bool left, bool right, bool turnLeft, bool turnRight) {
    if (dead) {
      up = down = left = right = turnLeft = turnRight = false;
      deadTime++;
      if (deadTime > 60 * 2) {
        level.lose();
      }
    } else {
      time++;
    }
    if (itemUseTime > 0) itemUseTime--;
    if (hurtTime > 0) hurtTime--;

    Block onBlock = level.getBlock((x + 0.5).floor(), (z + 0.5).floor());

    double fh = onBlock.getFloorHeight(this);
    if (onBlock is WaterBlock && !(lastBlock is WaterBlock)) {
      Sound.splash.play();
    }

    lastBlock = onBlock;

    if (dead) fh = -0.6;
    if (fh > y) {
      y += (fh - y) * 0.2;
      ya = 0.0;
    } else {
      ya -= 0.01;
      y += ya;
      if (y < fh) {
        y = fh;
        ya = 0.0;
      }
    }

    double rotSpeed = 0.05;
    double walkSpeed = 0.03 * onBlock.getWalkSpeed(this);

    if (turnLeft) rota += rotSpeed;
    if (turnRight) rota -= rotSpeed;

    double xm = 0.0;
    double zm = 0.0;
    if (up) zm--;
    if (down) zm++;
    if (left) xm--;
    if (right) xm++;
    double dd = xm * xm + zm * zm;
    if (dd > 0) dd = Math.sqrt(dd);
    else dd = 1.0;
    xm /= dd;
    zm /= dd;

    bob *= 0.6;
    turnBob *= 0.8;
    turnBob += rota;
    bob += Math.sqrt(xm * xm + zm * zm);
    bobPhase += Math.sqrt(xm * xm + zm * zm) * onBlock.getWalkSpeed(this);
    bool wasSliding = sliding;
    sliding = false;

    if (onBlock is IceBlock && getSelectedItem() != Item.skates) {
      if (xa * xa > za * za) {
        sliding = true;
        za = 0.0;
        if (xa > 0) xa = 0.08;
        else xa = -0.08;
        z += ((z + 0.5).floor() - z) * 0.2;
      } else if (xa * xa < za * za) {
        sliding = true;
        xa = 0.0;
        if (za > 0) za = 0.08;
        else za = -0.08;
        x += ((x + 0.5).floor() - x) * 0.2;
      } else {
        xa -= (xm * Math.cos(rot) + zm * Math.sin(rot)) * 0.1;
        za -= (zm * Math.cos(rot) - xm * Math.sin(rot)) * 0.1;
      }

      if (!wasSliding && sliding) {
        Sound.slide.play();
      }
    } else {
      xa -= (xm * Math.cos(rot) + zm * Math.sin(rot)) * walkSpeed;
      za -= (zm * Math.cos(rot) - xm * Math.sin(rot)) * walkSpeed;
    }

    move();

    double friction = onBlock.getFriction(this);
    xa *= friction;
    za *= friction;
    rot += rota;
    rota *= 0.4;
  }

  void activate() {
    if (dead) return;
    if (itemUseTime > 0) return;
    Item item = items[selectedSlot];
    if (item == Item.pistol) {
      if (ammo > 0) {
        Sound.shoot.play();
        itemUseTime = 10;
        level.addEntity(new Bullet(this, x, z, rot, 1.0, 0, 0xffffff));
        ammo--;
      }
      return;
    }
    if (item == Item.potion) {
      if (potions > 0 && health < 20) {
        Sound.potion.play();
        itemUseTime = 20;
        health += 5 + rand.nextInt(6);
        if (health > 20) health = 20;
        potions--;
      }
      return;
    }
    if (item == Item.key) itemUseTime = 10;
    if (item == Item.powerGlove) itemUseTime = 10;
    if (item == Item.cutters) itemUseTime = 10;

    double xa = (2 * Math.sin(rot));
    double za = (2 * Math.cos(rot));

    int rr = 3;
    int xc = (x + 0.5).floor();
    int zc = (z + 0.5).floor();
    List<Entity> possibleHits = new List();
    for (int z = zc - rr; z <= zc + rr; z++) {
      for (int x = xc - rr; x <= xc + rr; x++) {
        for (var entity in level.getBlock(x, z).entities) {
          if (entity == this) continue;
          possibleHits.add(entity);
        }
      }
    }

    int divs = 100;
    for (int i = 0; i < divs; i++) {
      double xx = x + xa * i / divs;
      double zz = z + za * i / divs;
      for (var entity in possibleHits) {
        if (entity.contains(xx, zz) && entity.use(this, items[selectedSlot])) {
          return;
        }
      }
      int xt = (xx + 0.5).floor();
      int zt = (zz + 0.5).floor();
      if (xt != (x + 0.5).floor() || zt != (z + 0.5).floor()) {
        Block block = level.getBlock(xt, zt);
        if (block.use(level, items[selectedSlot])) {
          return;
        }
        if (block.blocks(this)) return;
      }
    }
  }

  Item getSelectedItem() => items[selectedSlot];

  void addLoot(Item item) {
    if (item == Item.pistol) ammo += 20;
    if (item == Item.potion) potions += 1;
    for (var invItem in items) {
      if (invItem == item) {
        if (level != null) {
          level.showLootScreen(item);
        }
        return;
      }
    }

    for (int i = 0; i < items.length; i++) {
      if (items[i] == Item.none) {
        items[i] = item;
        selectedSlot = i;
        itemUseTime = 0;
        if (level != null) {
          level.showLootScreen(item);
        }
        return;
      }
    }
  }

  void hurt(Entity enemy, int dmg) {
    if (hurtTime > 0 || dead) return;

    hurtTime = 40;
    health -= dmg;

    if (health <= 0) {
      health = 0;
      Sound.death.play();
      dead = true;
    }

    Sound.hurt.play();

    double xd = enemy.x - x;
    double zd = enemy.z - z;
    double dd = Math.sqrt(xd * xd + zd * zd);
    xa -= xd / dd * 0.1;
    za -= zd / dd * 0.1;
    rota += (rand.nextDouble() - 0.5) * 0.2;
  }

  @override
  void collide(Entity entity) {
    if (entity is Bullet) {
      if (entity.owner is Player) {
        return;
      }
      if (hurtTime > 0) return;
      entity.remove();
      hurt(entity, 1);
    }
  }

  void win() {
    level.win();
  }

}

class Bullet extends Entity {
  Entity owner;

  Bullet(this.owner, double x, double z, double rot, double pow, int sprite, int col) {
    xa = Math.sin(rot) * 0.2 * pow;
    za = Math.cos(rot) * 0.2 * pow;
    this.x = x - za / 2;
    this.z = z + xa / 2;

    sprites.add(new Sprite(0.0, 0.0, 0.0, 8 * 3 + sprite, col));

    flying = true;
  }

  @override
  void tick() {
    double xao = xa;
    double zao = za;
    move();

    if ((xa == 0 && za == 0) || xa != xao || za != zao) {
      remove();
    }
  }

  @override
  bool blocks(Entity entity, double x2, double z2, double r2) {
    if (entity is Bullet) {
      return false;
    }
    if (entity == owner) {
      return false;
    }

    return super.blocks(entity, x2, z2, r2);
  }
}

class BoulderEntity extends Entity {
  static final int COLOR = 0xAFA293;

  Sprite sprite;
  double rollDist = 0.0;

  BoulderEntity(double x, double z) {
    this.x = x;
    this.z = z;
    sprite = new Sprite(0.0, 0.0, 0.0, 16, COLOR);
    sprites.add(sprite);
  }

  @override
  void tick() {
    rollDist += Math.sqrt(xa * xa + za * za);
    sprite.tex = 8 + ((rollDist * 4).floor() & 1);
    double xao = xa;
    double zao = za;
    move();
    if (xa == 0 && xao != 0) xa = -xao * 0.3;
    if (za == 0 && zao != 0) za = -zao * 0.3;
    xa *= 0.98;
    za *= 0.98;
    if (xa * xa + za * za < 0.0001) {
      xa = za = 0.0;
    }
  }

  @override
  bool use(Entity source, Item item) {
    if (item != Item.powerGlove) return false;
    Sound.roll.play();

    xa += Math.sin(source.rot) * 0.1;
    za += Math.cos(source.rot) * 0.1;
    return true;
  }
}

class EnemyEntity extends Entity {
  Sprite sprite;
  double rot = 0.0;
  double rota = 0.0;
  int defaultTex = 0;
  int defaultColor = 0;
  int hurtTime = 0;
  int animTime = 0;
  int health = 3;
  double spinSpeed = 0.1;
  double runSpeed = 1.0;

  EnemyEntity(double x, double z, int defaultTex, int defaultColor) {
    this.x = x;
    this.z = z;
    this.defaultColor = defaultColor;
    this.defaultTex = defaultTex;
    sprite = new Sprite(0.0, 0.0, 0.0, 4 * 8, defaultColor);
    sprites.add(sprite);
    r = 0.3;
  }

  @override
  void tick() {
    if (hurtTime > 0) {
      hurtTime--;
      if (hurtTime == 0) {
        sprite.col = defaultColor;
      }
    }
    animTime++;
    sprite.tex = defaultTex + animTime ~/ 10 % 2;
    move();
    if (xa == 0 || za == 0) {
      rota += (nextGaussian() * rand.nextDouble()) * 0.3;
    }

    rota += (nextGaussian() * rand.nextDouble()) * spinSpeed;
    rot += rota;
    rota *= 0.8;
    xa *= 0.8;
    za *= 0.8;
    xa += Math.sin(rot) * 0.004 * runSpeed;
    za += Math.cos(rot) * 0.004 * runSpeed;
  }

  @override
  bool use(Entity source, Item item) {
    if (hurtTime > 0) return false;
    if (item != Item.powerGlove) return false;

    hurt(Math.sin(source.rot), Math.cos(source.rot));

    return true;
  }

  void hurt(double xd, double zd) {
    sprite.col = 0xFF0000;
    hurtTime = 15;

    double dd = Math.sqrt(xd * xd + zd * zd);
    xa += xd / dd * 0.2;
    za += zd / dd * 0.2;
    Sound.hurt2.play();
    health--;
    if (health <= 0) {
      int xt = (x + 0.5).floor();
      int zt = (z + 0.5).floor();
      level.getBlock(xt, zt).addSprite(new PoofSprite(x - xt, 0.0, z - zt));
      die();
      remove();
      Sound.kill.play();
    }
  }

  void die() {}

  void collide(Entity entity) {
    if (entity is Bullet) {
      if (entity.owner.runtimeType == this.runtimeType) {
        return;
      }
      if (hurtTime > 0) return;
      entity.remove();
      hurt(entity.xa, entity.za);
    }
    if (entity is Player) {
      entity.hurt(this, 1);
    }
  }
}

class BatEntity extends EnemyEntity {
  BatEntity(double x, double z) : super(x, z, 4 * 8, 0x82666E) {
    health = 2;
    r = 0.3;
    flying = true;
  }
}

class BatBossEntity extends EnemyEntity {
  BatBossEntity(double x, double z) : super(x, z, 4 * 8, 0xFFFF00) {
    health = 5;
    r = 0.3;
    flying = true;
  }

  @override
  void die() {
    Sound.bosskill.play();
    level.addEntity(new KeyEntity(x, z));
  }

  @override
  void tick() {
    super.tick();
    if (rand.nextInt(20) == 0) {
      double xx = x + (rand.nextDouble() - 0.5) * 2;
      double zz = z + (rand.nextDouble() - 0.5) * 2;
      var batEntity = new BatEntity(xx, zz);
      batEntity.level = level;

      batEntity.x = -999;
      batEntity.z = -999;

      if (batEntity.isFree(xx, zz)) {
        level.addEntity(batEntity);
      }
    }
  }
}

class OgreEntity extends EnemyEntity {
  int shootDelay = 0;

  OgreEntity(double x, double z) : super(x, z, 4 * 8 + 2, 0x82A821) {
    health = 6;
    r = 0.4;
    spinSpeed = 0.05;
  }

  @override
  void hurt(double xd, double zd) {
    super.hurt(xd, zd);
    shootDelay = 50;
  }

  @override
  void tick() {
    super.tick();
    if (shootDelay > 0) {
      shootDelay--;
    } else if (rand.nextInt(40) == 0) {
      shootDelay = 40;
      level.addEntity(new Bullet(this, x, z, Math.atan2(level.player.x - x, level.player.z - z), 0.3, 1, defaultColor));
    }
  }
}

class BossOgre extends EnemyEntity {
  int shootDelay = 0;
  int shootPhase = 0;

  BossOgre(double x, double z) : super(x, z, 4 * 8 + 2, 0xFFFF00) {
    health = 10;
    r = 0.4;
    spinSpeed = 0.05;
  }

  @override
  void die() {
    Sound.bosskill.play();
    level.addEntity(new KeyEntity(x, z));
  }

  @override
  void tick() {
    super.tick();
    if (shootDelay > 0) {
      shootDelay--;
    } else {
      shootDelay = 5;
      int salva = 10;

      for (int i = 0; i < 4; i++) {
        double rot = Math.PI / 2 * (i + shootPhase / salva % 2 * 0.5);
        level.addEntity(new Bullet(this, x, z, rot, 0.4, 1, defaultColor));
      }

      shootPhase++;
      if (shootPhase % salva == 0) shootDelay = 40;
    }
  }

}

class EyeEntity extends EnemyEntity {
  EyeEntity(double x, double z) : super(x, z, 4 * 8 + 4, 0x84ECFF) {
    health = 4;
    r = 0.3;
    runSpeed = 2.0;
    spinSpeed *= 1.5;
    flying = true;
  }
}

class EyeBossEntity extends EnemyEntity {
  EyeBossEntity(double x, double z) : super(x, z, 4 * 8 + 4, 0xFFFF00) {
    health = 10;
    r = 0.3;
    runSpeed = 4.0;
    spinSpeed *= 1.5;
    flying = true;
  }

  @override
  void die() {
    Sound.bosskill.play();
    level.addEntity(new KeyEntity(x, z));
  }
}

class GhostEntity extends EnemyEntity {
  double rotatePos = 0.0;

  GhostEntity(double x, double z) : super(x, z, 4 * 8 + 6, 0xFFFFFF) {
    health = 4;
    r = 0.3;
    flying = true;
  }

  @override
  void tick() {
    animTime++;
    sprite.tex = defaultTex + animTime ~/ 10 % 2;

    double xd = (level.player.x + Math.sin(rotatePos)) - x;
    double zd = (level.player.z + Math.cos(rotatePos)) - z;
    double dd = xd * xd + zd * zd;

    if (dd < 4 * 4) {
      if (dd < 1) {
        rotatePos += 0.04;
      } else {
        rotatePos = level.player.rot;
        xa += (rand.nextDouble() - 0.5) * 0.02;
        za += (rand.nextDouble() - 0.5) * 0.02;
      }

      dd = Math.sqrt(dd);

      xd /= dd;
      zd /= dd;

      xa += xd * 0.004;
      za += zd * 0.004;
    }

    move();

    xa *= 0.9;
    za *= 0.9;
  }

  @override
  void hurt(double xd, double zd) {}

  @override
  void move() {
    x += xa;
    z += za;
  }
}

class GhostBossEntity extends EnemyEntity {
  double rotatePos = 0.0;
  int shootDelay = 0;

  GhostBossEntity(double x, double z) : super(x, z, 4 * 8 + 6, 0xFFFF00) {
    health = 10;
    flying = true;
  }

  @override
  void tick() {
    animTime++;
    sprite.tex = defaultTex + animTime ~/ 10 % 2;

    double xd = (level.player.x + Math.sin(rotatePos) * 2) - x;
    double zd = (level.player.z + Math.cos(rotatePos) * 2) - z;
    double dd = xd * xd + zd * zd;

    if (dd < 1) {
      rotatePos += 0.04;
    } else {
      rotatePos = level.player.rot;
    }
    if (dd < 4 * 4) {
      dd = Math.sqrt(dd);

      xd /= dd;
      zd /= dd;

      xa += xd * 0.006;
      za += zd * 0.006;

      if (shootDelay > 0) shootDelay--;
      else if (rand.nextInt(10) == 0) {
        shootDelay = 10;
        level.addEntity(new Bullet(this, x, z, Math.atan2(level.player.x - x, level.player.z - z), 0.20, 1, defaultColor));
      }

    }

    move();

    xa *= 0.9;
    za *= 0.9;
  }

  @override
  void hurt(double xd, double zd) {}

  @override
  void move() {
    x += xa;
    z += za;
  }
}

class KeyEntity extends Entity {
  static final int COLOR = 0x00FFFF;
  Sprite sprite;
  double y = 0.0, ya = 0.0;

  KeyEntity(double x, double z) {
    this.x = x;
    this.z = z;
    y = 0.5;
    ya = 0.025;
    sprite = new Sprite(0.0, 0.0, 0.0, 16 + 3, COLOR);
    sprites.add(sprite);
  }

  @override
  void tick() {
    move();
    y = Math.max(0.0, y + ya);
    ya -= 0.005;
    sprite.y = y;
  }

  @override
  void collide(Entity entity) {
    if (entity is Player) {
      Sound.key.play();
      entity.keys++;
      remove();
    }
  }
}
