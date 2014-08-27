part of potc;

class Menu {
  void render(webgl.RenderingContext gl) {
  }

  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
  }
}

class TitleMenu extends Menu {

  List<String> options = [ "New game", "Instructions", "About" ];
  int selected = 0;
  static bool firstTick = true;

  @override
  void render(webgl.RenderingContext gl) {
    blitter.drawBitmapPart(Art.logo, 0.0, 8.0, 0, 0, 160, 36);

    for (int i = 0; i < options.length; i++) {
      String msg = options[i];
      int col = 0x909090;
      if (selected == i) {
        msg = "-> " + msg;
        col = 0xffff80;
      }
      blitter.drawString(msg, 40.0, 60.0 + i * 10, Colors.create(col));
    }
    blitter.drawString("Copyright (C) 2011 Mojang", 1.0 + 4.0, 120.0 - 9.0, Colors.create(0x303030));
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
    if (firstTick) {
      firstTick = false;
      Sound.altar.play();
    }
    if (up || down) Sound.click2.play();
    if (up) selected--;
    if (down) selected++;
    if (selected < 0) selected = 0;
    if (selected >= options.length) selected = options.length - 1;
    if (use) {
      Sound.click1.play();
      if (selected == 0) {
//        game.setMenu(null);
//        game.newGame();
      }
      if (selected == 1) {
        game.curMenu = new InstructionsMenu();
      }
      if (selected == 2) {
        game.curMenu = new AboutMenu();
      }
    }
  }
}

class InstructionsMenu extends Menu {
  int tickDelay = 30;
  List<String> lines = [
    "Use W,A,S,D to move, and",
    "the arrow keys to turn.",
    "",
    "The 1-8 keys select",
    "items from the inventory",
    "",
    "Space uses items",
  ];

  @override
  void render(webgl.RenderingContext gl) {
    blitter.drawString("Instructions", 40.0, 8.0, Colors.WHITE);
    for (int i=0; i<lines.length; i++) {
      blitter.drawString(lines[i], 4.0, 32.0 + i * 8.0, Colors.create(0xa0a0a0));
    }
    if (tickDelay == 0) blitter.drawString("-> Continue", 40.0, Game.height - 16.0, Colors.create(0xffff80));
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
    if (tickDelay > 0) tickDelay--;
    else if (use) {
      Sound.click1.play();
      game.curMenu = new TitleMenu();
    }
  }
}

class AboutMenu extends Menu {
  int tickDelay = 30;
  List<String> lines = [
      "Prelude of the Chambered",
      "by Markus Persson.",
      "Made Aug 2011 for the",
      "21'st Ludum Dare compo.",
      "",
      "This game is freeware,",
      "and was made from scratch",
      "in just 48 hours.",
      "Dart port by unknownloner."
  ];

  @override
  void render(webgl.RenderingContext gl) {
    blitter.drawString("About", 60.0, 8.0, Colors.WHITE);
    for (int i=0; i<lines.length; i++) {
      blitter.drawString(lines[i], 4.0, 28.0 + i * 8.0, Colors.create(0xa0a0a0));
    }

    if (tickDelay == 0) blitter.drawString("-> Continue", 40.0, Game.height - 16.0, Colors.create(0xFFFF80));
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
    if (tickDelay > 0) tickDelay--;
    else if (use) {
      Sound.click1.play();
      game.curMenu = new TitleMenu();
    }
  }
}
