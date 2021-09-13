package aseprite.fs;

import haxe.Serializer;
import haxe.io.Bytes;

function init() {
  // #if (sys || nodejs)
  // hxd.fs.FileConverter.addConfig({
  //   "fs.convert": {
  //     "ase": "asedata",
  //     "aseprite": "asedata"
  //   }
  // });
  // #end

  // hxd.fs.Convert.register(new aseprite.fs.Convert.AsepriteConvert());
}

function register() {
  hxd.fs.Convert.register(new aseprite.fs.Convert.AsepriteConvert());
}

class AsepriteConvert extends hxd.fs.Convert {
  public function new() {
    super('aseprite,ase', 'asedata');
  }

  override function convert() {
    #if (sys || nodejs)
    var parsedAse = Utils.parseAse(ase.Ase.fromBytes(srcBytes));
    var parsedAseBytes = Bytes.ofString(Serializer.run(parsedAse.data));
    var parsedPng = parsedAse.pixels.toPNG();

    var png = format.png.Tools.build32BGRA(parsedAse.pixels.width, parsedAse.pixels.height, parsedPng);
    png.remove(CEnd);
    png.add(CUnknown("ASE", parsedAseBytes));
    png.add(CEnd);

    var imageOut = new haxe.io.BytesOutput();
    new format.png.Writer(imageOut).write(png);
    save(imageOut.getBytes());

    // // Save pixels as `.png`
    // hxd.File.saveBytes(haxe.io.Path.withExtension('ase-pngs/$srcPath', "png"), parsedPng);
    // // Save data as `.asedata`
    // save(Bytes.ofString(Serializer.run(parsedAse.data)));

    // Clean up
    parsedAse.pixels.dispose();
    #else
    throw "Not implemented";
    #end
  }

  // register the convert so it can be found
  // static var _ = Convert.register(new AsepriteConvert());
}
