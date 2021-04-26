package aseprite.res;

import haxe.Unserializer;
import hxd.res.Image;
import hxd.res.Resource;

class Aseprite extends Resource {
  static var ENABLE_AUTO_WATCH = true;

  var ase:aseprite.Aseprite;

  public function toAseprite() {
    if (ase == null) {
      if (entry.isAvailable) {
        ase = usingConvert() ? aseprite.Aseprite.fromData(Unserializer.run(entry.getText()),
          toImage().toTexture()) : aseprite.Aseprite.fromBytes(entry.getBytes());
      }
      if (ENABLE_AUTO_WATCH) watch(updateData);
    }

    return ase;
  }

  public function toImage() {
    if (usingConvert()) return hxd.res.Loader.currentInstance.loadCache(haxe.io.Path.withExtension(".tmp/" + entry.path, "png"), Image);

    throw '`toImage() is only supported when using aseprite.fs.Convert.AsepriteConvert';
  }

  public function updateData() {
    if (usingConvert()) ase.loadData(Unserializer.run(entry.getText()));
    else ase.loadBytes(entry.getBytes());
  }

  private function usingConvert():Bool {
    return @:privateAccess hxd.fs.Convert.converts.get('asedata') != null;
  }
}
