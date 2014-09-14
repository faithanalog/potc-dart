part of potc;

class Sound {

  static Sound altar;
  static Sound bosskill;
  static Sound click1;
  static Sound click2;
  static Sound hit;
  static Sound hurt;
  static Sound hurt2;
  static Sound kill;
  static Sound death;
  static Sound splash;
  static Sound key;
  static Sound pickup;
  static Sound roll;
  static Sound shoot;
  static Sound treasure;
  static Sound crumble;
  static Sound slide;
  static Sound cut;
  static Sound thud;
  static Sound ladder;
  static Sound potion;

  static dtmark.AudioEngine engine;

  dtmark.Sound dtSound;

  Sound(this.dtSound);

  void play() {
    if (dtSound != null) {
      dtSound.play();
    }
  }

  static Future load() {
    try {
      engine = new dtmark.AudioEngine();
      engine.volume = 0.35;
    } catch (e) {
      altar = bosskill = click1 = click2 = hit = hurt = hurt2 = kill =
        death = splash = key = pickup = roll = shoot = treasure =
        crumble = slide = cut = thud = ladder = potion = new Sound(null);
      print("Could not initialize WebAudio");
      return new Future.value(null);
    }

    var waitList = [];
    altar = loadSound("res/snd/altar", waitList);
    bosskill = loadSound("res/snd/bosskill", waitList);
    click1 = loadSound("res/snd/click", waitList);
    click2 = loadSound("res/snd/click2", waitList);
    hit = loadSound("res/snd/hit", waitList);
    hurt = loadSound("res/snd/hurt", waitList);
    hurt2 = loadSound("res/snd/hurt2", waitList);
    kill = loadSound("res/snd/kill", waitList);
    death = loadSound("res/snd/death", waitList);
    splash = loadSound("res/snd/splash", waitList);
    key = loadSound("res/snd/key", waitList);
    pickup = loadSound("res/snd/pickup", waitList);
    roll = loadSound("res/snd/roll", waitList);
    shoot = loadSound("res/snd/shoot", waitList);
    treasure = loadSound("res/snd/treasure", waitList);
    crumble = loadSound("res/snd/crumble", waitList);
    slide = loadSound("res/snd/slide", waitList);
    cut = loadSound("res/snd/cut", waitList);
    thud = loadSound("res/snd/thud", waitList);
    ladder = loadSound("res/snd/ladder", waitList);
    potion = loadSound("res/snd/potion", waitList);
    return Future.wait(waitList);
  }

  static Sound loadSound(String path, List<Future> waitList) {
    var dtSound = new dtmark.Sound.load(path, engine, true);
    waitList.add(dtSound.onLoad);
    return new Sound(dtSound);
  }

}
