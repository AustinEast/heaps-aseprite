package aseprite.fs;

import haxe.Serializer;
import haxe.io.Bytes;
import hxd.fs.Convert;

class AsepriteConvert extends Convert {
  public function new() {
    super('aseprite,ase', 'asedata');
  }

  override function convert() {
    #if (sys || nodejs)
    var parsedAse = Utils.parseAse(ase.Ase.fromBytes(srcBytes));
    // Save pixels as `.png`
    hxd.File.saveBytes(haxe.io.Path.withExtension(dstPath, "png"), parsedAse.pixels.toPNG());
    // Save data as `.asedata`
    save(Bytes.ofString(Serializer.run(parsedAse.data)));
    // Clean up
    parsedAse.pixels.dispose();
    #else
    throw "Not implemented";
    #end
  }
}
