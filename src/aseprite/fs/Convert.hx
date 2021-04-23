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
    var aseprite = Aseprite.fromBytes(srcBytes);
    sys.io.File.saveBytes(haxe.io.Path.withExtension(dstPath, "png"), Aseprite.fromBytes(srcBytes).getTexture().capturePixels().toPNG());

    var serializer = new Serializer();
    serializer.serialize(aseprite.toData());
    save(Bytes.ofString(serializer.toString()));
    #else
    throw "Not implemented";
    #end
  }
}