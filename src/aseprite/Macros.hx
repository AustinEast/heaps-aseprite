package aseprite;

#if macro
import haxe.macro.Compiler;
#end

class Macros {
  #if macro
  public static function init() {
    hxd.res.Config.extensions.set('aseprite,ase', 'aseprite.res.Aseprite');
    hxd.res.Config.pairedExtensions.set("asedata", "png");

    Compiler.include("aseprite.res.Aseprite");
    Compiler.keep("aseprite.res.Aseprite");
  }
  #end
}
