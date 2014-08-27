part of potc;

Future<Sound> loadSound(String path) {
  Completer<Sound> comp = new Completer();

  HttpRequest req = new HttpRequest();
  req.open('GET', path);
  req.responseType = "arraybuffer";
  req.onLoad.first.then((evt) {
    Sound.ctx.decodeAudioData(req.response).then((buffer) {
      comp.complete(new Sound(buffer));
    });
  });
  req.send();
  return comp.future;
}

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

  static AudioContext ctx;

  AudioBuffer buffer;

  Sound(this.buffer);

  factory Sound.load(String url) {
    var snd = new Sound(null);

  }

  void play() {
    if (buffer != null) {
      var src = ctx.createBufferSource();
      src.buffer = buffer;
      src.connectNode(ctx.destination);
      src.start(0);
    }
  }

  static Future load() {
    Completer comp = new Completer();
    try {
      ctx = new AudioContext();
    } catch (e) {
      altar = bosskill = click1 = click2 = hit = hurt = hurt2 = kill =
        death = splash = key = pickup = roll = shoot = treasure =
        crumble = slide = cut = thud = ladder = potion = new Sound(null);
      print("Could not initialize WebAudio");
      return new Future.value(null);
    }
    Future.wait([
        loadSound("res/snd/altar.wav"),
        loadSound("res/snd/bosskill.wav"),
        loadSound("res/snd/click.wav"),
        loadSound("res/snd/click2.wav"),
        loadSound("res/snd/hit.wav"),
        loadSound("res/snd/hurt.wav"),
        loadSound("res/snd/hurt2.wav"),
        loadSound("res/snd/kill.wav"),
        loadSound("res/snd/death.wav"),
        loadSound("res/snd/splash.wav"),
        loadSound("res/snd/key.wav"),
        loadSound("res/snd/pickup.wav"),
        loadSound("res/snd/roll.wav"),
        loadSound("res/snd/shoot.wav"),
        loadSound("res/snd/treasure.wav"),
        loadSound("res/snd/crumble.wav"),
        loadSound("res/snd/slide.wav"),
        loadSound("res/snd/cut.wav"),
        loadSound("res/snd/thud.wav"),
        loadSound("res/snd/ladder.wav"),
        loadSound("res/snd/potion.wav"),
    ]).then((snds) {
      altar = snds[0];
      bosskill = snds[1];
      click1 = snds[2];
      click2 = snds[3];
      hit = snds[4];
      hurt = snds[5];
      hurt2 = snds[6];
      kill = snds[7];
      death = snds[8];
      splash = snds[9];
      key = snds[10];
      pickup = snds[11];
      roll = snds[12];
      shoot = snds[13];
      treasure = snds[14];
      crumble = snds[15];
      slide = snds[16];
      cut = snds[17];
      thud = snds[18];
      ladder = snds[19];
      potion = snds[20];
      comp.complete();
    });
    return comp.future;
  }

}