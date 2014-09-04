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
    gl.clear(webgl.COLOR_BUFFER_BIT);
    blitter.drawBitmapPart(Art.logo, 0.0, 8.0, 0, 0, 160, 36);

    for (int i = 0; i < options.length; i++) {
      String msg = options[i];
      int col = 0x909090;
      if (selected == i) {
        msg = "-> " + msg;
        col = 0xffff80;
      }
      blitter.drawString(msg, 40.0, 60.0 + i * 10, col);
    }
    blitter.drawString("Copyright (C) 2011 Mojang", 1.0 + 4.0, 120.0 - 9.0, 0x303030);
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
        game.menu = null;
        game.newGame();
      }
      if (selected == 1) {
        game.menu = new InstructionsMenu();
      }
      if (selected == 2) {
        game.menu = new AboutMenu();
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
    gl.clear(webgl.COLOR_BUFFER_BIT);
    blitter.drawString("Instructions", 40.0, 8.0, 0xFFFFFF);
    for (int i=0; i<lines.length; i++) {
      blitter.drawString(lines[i], 4.0, 32.0 + i * 8.0, 0xa0a0a0);
    }
    if (tickDelay == 0) blitter.drawString("-> Continue", 40.0, Game.height - 16.0, 0xffff80);
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
    if (tickDelay > 0) tickDelay--;
    else if (use) {
      Sound.click1.play();
      game.menu = new TitleMenu();
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
    gl.clear(webgl.COLOR_BUFFER_BIT);
    blitter.drawString("About", 60.0, 8.0, 0xFFFFFF);
    for (int i=0; i<lines.length; i++) {
      blitter.drawString(lines[i], 4.0, 28.0 + i * 8.0, 0xA0A0A0);
    }

    if (tickDelay == 0) blitter.drawString("-> Continue", 40.0, Game.height - 16.0, 0xFFFF80);
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
    if (tickDelay > 0) tickDelay--;
    else if (use) {
      Sound.click1.play();
      game.menu = new TitleMenu();
    }
  }
}

class GotLootMenu extends Menu {
  int tickDelay = 30;
  Item item;

  GotLootMenu(this.item);

  @override
  void render(webgl.RenderingContext gl) {
		String str = "You found the " + item.name + "!";
		blitter.drawBitmapPartScaled(Art.items, 3, Game.width / 2 - 8 * 3, 2.0, item.icon * 16, 0, 16, 16, item.color);
		blitter.drawString(str, (Game.width - str.length * 6) / 2 + 2, 60.0 - 10, 0xffff80);

		str = item.description;
		blitter.drawString(str, (Game.width - str.length * 6) / 2 + 2, 60.0, 0xa0a0a0);

		if (tickDelay == 0) blitter.drawString("-> Continue", 40.0, Game.height - 40.0, 0xffff80);
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
		if (tickDelay > 0) {
      tickDelay--;
    } else if (use) {
			game.menu = null;
		}
	}
}

class LoseMenu extends Menu {
	int tickDelay = 30;

	Player player;

	LoseMenu(this.player);

  @override
	void render(webgl.RenderingContext gl) {
		blitter.drawBitmapPart(Art.logo, 0.0, 10.0, 0, 39, 160, 23, 0xffffff);

		int seconds = player.time ~/ 60;
		int minutes = seconds ~/ 60;
		seconds %= 60;
		String timeString = "$minutes:";
		if (seconds < 10) timeString += "0";
		timeString += seconds.toString();
		blitter.drawString("Trinkets: ${player.loot}/12", 40.0, 45.0, 0x909090);
		blitter.drawString("Time: $timeString", 40.0, 45.0 + 10, 0x909090);

		if (tickDelay == 0) blitter.drawString("-> Continue", 40.0, Game.height - 40.0, 0xffff80);
	}

  @override
	void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
		if (tickDelay > 0) tickDelay--;
		else if (use) {
			Sound.click1.play();
			game.menu = new TitleMenu();
		}
	}
}

class PauseMenu extends Menu {
  List<String> options = ["Abort Game", "Continue"];
  int selected = 1;

  @override
  void render(webgl.RenderingContext gl) {
		blitter.drawBitmapPart(Art.logo, 0.0, 8.0, 0, 0, 160, 36, 0xffffff);

		for (int i = 0; i < options.length; i++) {
			String msg = options[i];
			int col = 0x909090;
			if (selected == i) {
				msg = "-> " + msg;
				col = 0xffff80;
			}
			blitter.drawString(msg, 40.0, 60.0 + i * 10, col);
		}
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
		if (up || down) Sound.click2.play();
		if (up) selected--;
		if (down) selected++;
		if (selected < 0) selected = 0;
		if (selected >= options.length) selected = options.length - 1;
		if (use) {
			Sound.click1.play();
			if (selected == 0) {
				game.menu = new TitleMenu();
			}
			if (selected == 1) {
				game.menu = null;
			}
		}
  }
}

class WinMenu extends Menu {
  int tickDelay = 30;
  Player player;

  WinMenu(this.player);

  @override
  void render(webgl.RenderingContext gl) {
		blitter.drawBitmapPart(Art.logo, 0.0, 10.0, 0, 65, 160, 23, 0xffffff);

		int seconds = player.time ~/ 60;
		int minutes = seconds ~/ 60;
		seconds %= 60;
		String timeString = "$minutes:";
		if (seconds < 10) timeString += "0";
		timeString += seconds.toString();
		blitter.drawString("Trinkets: ${player.loot}/12", 40.0, 45.0, 0x909090);
		blitter.drawString("Time: $timeString", 40.0, 45.0 + 10 * 1, 0x909090);

		if (tickDelay == 0) blitter.drawString("-> Continue", 40.0, Game.height - 40.0, 0xffff80);
  }

  @override
  void tick(Game game, bool up, bool down, bool left, bool right, bool use) {
    if (tickDelay > 0) {
      tickDelay--;
    } else if (use) {
      Sound.click1.play();
      game.menu = new TitleMenu();
    }
  }
}
