package aseprite;

#if macro
import haxe.macro.Compiler;
#end

class Macros {
  static var _usingConvert = false;

  #if macro
  public static function init() {
    hxd.res.Config.extensions.set('aseprite,ase', 'aseprite.res.Aseprite');

    Compiler.include('aseprite.res.Aseprite');
    Compiler.keep('aseprite.res.Aseprite');

    // trace(@:privateAccess hxd.fs.Convert.converts);
    // trace(@:privateAccess hxd.fs.FileConverter.extraConfigs);
    // trace(hxd.res.Config.extensions);
    // trace(hxd.res.Config.pairedExtensions);
  }

  public static function convert() {
    // hxd.fs.FileConverter.addConfig({
    //   "fs.convert": {
    //     "ase": "asedata",
    //     "aseprite": "asedata"
    //   }
    // });

    hxd.fs.Convert.register(new aseprite.fs.Convert.AsepriteConvert());

    hxd.res.Config.pairedExtensions.set("asedata", "png");

    _usingConvert = true;
  }
  #end

  public static macro function usingConvert()
    return macro $v{_usingConvert};
}
