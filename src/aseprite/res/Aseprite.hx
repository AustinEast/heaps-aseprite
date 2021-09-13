package aseprite.res;

import format.png.Data.Chunk;
import haxe.Unserializer;
import haxe.io.BytesInput;
import hxd.res.Image;
import hxd.res.Resource;

class Aseprite extends Image {
  static var ENABLE_AUTO_WATCH = true;

  var ase:aseprite.Aseprite;

  public function toAseprite() {
    if (ase == null) {
      if (entry.isAvailable) {
        // trace('using convert: ${usingConvert()}');
        // var data = Unserializer.run(entry.getText());
        // trace(data);
        // ase = usingConvert() ? aseprite.Aseprite.fromData(data, toTexture().capturePixels()) : aseprite.Aseprite.fromBytes(entry.getBytes());

        if (usingConvert()) {
          var png = new format.png.Reader(new BytesInput(entry.getBytes()));
          png.checkCRC = false;

          for (b in [137, 80, 78, 71, 13, 10, 26, 10]) if (@:privateAccess png.i.readByte() != b) throw "Invalid header";

          var chunk:Chunk;
          do {
            chunk = @:privateAccess png.readChunk();
            trace("CHUNKD");
            switch (chunk) {
              case CUnknown(id, data):
                if (id != "ASE") continue;
                var usd = Unserializer.run(data.toString());
                trace(usd);
                ase = aseprite.Aseprite.fromData(usd, toTexture().capturePixels());
                break;
              case _:
            }
          } while (chunk.getName() != 'CUnknown');
            // for (chunk in png.read()) {
            //   trace("CHUNKD");
            //   switch (chunk) {
            //     case CUnknown(id, data):
            //       if (id != "ASE") continue;
            //       var usd = Unserializer.run(data.toString());
            //       trace(usd);
            //       ase = aseprite.Aseprite.fromData(usd, toTexture().capturePixels());
            //       break;
            //     case _:
            //   }
            // }
        }
        else {
          ase = aseprite.Aseprite.fromBytes(entry.getBytes());
        }

        if (ENABLE_AUTO_WATCH) watch(updateData);
      }
    }

    return ase;
  }

  // public function toImage() {
  //   trace(hxd.res.Loader.currentInstance.fs.getRoot());
  //   if (usingConvert()) return hxd.res.Loader.currentInstance.load(haxe.io.Path.withExtension(".tmp/" + entry.path, "png")).toImage();
  //   throw '`toImage()` is only supported when using aseprite.fs.Convert.AsepriteConvert';
  // }

  public function updateData() {
    if (usingConvert()) ase.loadData(Unserializer.run(entry.getText()));
    else ase.loadBytes(entry.getBytes());
  }

  private function usingConvert():Bool {
    return @:privateAccess hxd.fs.Convert.converts.get('asedata') != null; // aseprite.Macros.usingConvert();
  }
}
