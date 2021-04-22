package aseprite;

class Macros {
  #if macro
  public static function init() {
    hxd.res.Config.extensions.set('aseprite', 'aseprite.AsepriteRes');
    hxd.res.Config.extensions.set('ase', 'aseprite.AsepriteRes');
  }
  #end
}
