package aseprite;

#if macro
import haxe.macro.Compiler;
#end

class Macros {
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
  #end
}
