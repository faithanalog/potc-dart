part of potc;

class Item {

  static const Item none       = const Item(-1, 0xFFC363, "",               "");
  static const Item powerGlove = const Item(0,  0xFFC363, "Power Glove",    "Smaaaash!!");
  static const Item pistol     = const Item(1,  0xEAEAEA, "Pistol",         "Pew, pew, pew!");
  static const Item flippers   = const Item(2,  0x7CBBFF, "Flippers",       "Splish splash!");
  static const Item cutters    = const Item(3,  0xCCCCCC, "Cutters",        "Snip, snip!");
  static const Item skates     = const Item(4,  0xAE70FF, "Skates",         "Sharp");
  static const Item key        = const Item(5,  0xFF4040, "Key",            "How did you get this?");
  static const Item potion     = const Item(6,  0x4AFF47, "Potion",         "Healthy!");

  final int icon;
  final int color;
  final String name;
  final String description;

  const Item(this.icon, this.color, this.name, this.description);

}