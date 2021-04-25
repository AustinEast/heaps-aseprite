package aseprite.res;

import haxe.Unserializer;
import hxd.res.Image;
import hxd.res.Resource;

class Aseprite extends Resource {
  static var ENABLE_AUTO_WATCH = true;

  var ase:aseprite.Aseprite;

  public function toAseprite() {
    if (ase == null) {
      if (entry.isAvailable) ase = aseprite.Aseprite.fromData(Unserializer.run(entry.getText()), toImage().toTexture());
      if (ENABLE_AUTO_WATCH) watch(updateData);
    }

    return ase;
  }

  public function toImage() {
    return hxd.res.Loader.currentInstance.loadCache(haxe.io.Path.withExtension(".tmp/" + entry.path, "png"), Image);
  }

  public function updateData() {
    ase.loadData(Unserializer.run(entry.getText()));
  }

  static var _ = hxd.fs.Convert.register(new aseprite.fs.Convert.AsepriteConvert());
  static var __ = hxd.fs.FileConverter.addConfig({
    "fs.convert": {
      "aseprite": "asedata",
      "ase": "asedata"
    }
  });
}
