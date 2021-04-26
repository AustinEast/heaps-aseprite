package aseprite;

class Reg {
  public static function init() {
    hxd.fs.Convert.register(new aseprite.fs.Convert.AsepriteConvert());
  }
}
