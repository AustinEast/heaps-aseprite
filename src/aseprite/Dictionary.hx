package aseprite;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end


/**
  This class extracts various identifiers from an Aseprite file on *compilation* time. This creates a typed structure that allows some type-safety: if an identifier changes in your Aseprite file (for example a tag), your compilation will show errors wherever this identifier was used. Example:

  ```haxe
  var tagsDictionary = aseprite.Dictionary.getTags( hxd.Res.myFile );
  trace(tagsDictionary);  // { run:"run", idle:"idle", attackA:"attackA" }
  someAnimManager.play( tagsDictionary.run ); // if "run" tag is renamed in Aseprite, this will show an error here
  ```
**/

class Dictionary {

  /**
    Build an anonymous object containing all "tags" names found in given Aseprite file.
    Example: `{  run:"run",  idle:"idle",  attackA:"attackA"  }`
  **/
  macro public static function getTags(asepriteRes:ExprOf<hxd.res.Resource>) {
    var pos = Context.currentPos();
    var path = resolveResToPath(asepriteRes);
    var ase = readAseprite(path);

    // List all tags
    final magicId = 0x2018;
    var all:Map<String, Bool> = new Map(); // "Map" type avoids duplicates
    for (f in ase.frames) {
      if (!f.chunkTypes.exists(magicId)) continue;
      var tags:Array<ase.chunks.TagsChunk> = cast f.chunkTypes.get(magicId);
      for (tc in tags) for (t in tc.tags) all.set(t.tagName, true);
    }

    // Create "tags" anonymous structure
    var tagFields:Array<ObjectField> = [];
    for (tag in all.keys()) tagFields.push({field: cleanUpIdentifier(tag), expr: macro $v{tag}});

    // Return anonymous structure
    return {expr: EObjectDecl(tagFields), pos: pos}
  }



  /**
    Build an anonymous object containing all "slices" names found in given Aseprite file.
    Example: `{  mySlice:"mySlice",  grass1:"grass1",  stoneBlock:"stoneBlock"  }`
  **/
  macro public static function getSlices(asepriteRes:ExprOf<hxd.res.Resource>) {
    var pos = Context.currentPos();
    var path = resolveResToPath(asepriteRes);
    var ase = readAseprite(path);

    // List all slices
    final magicId = 0x2022;
    var all:Map<String, Bool> = new Map(); // "Map" type avoids duplicates
    for (f in ase.frames) {
      if (!f.chunkTypes.exists(magicId)) continue;
      var chunk:Array<ase.chunks.SliceChunk> = cast f.chunkTypes.get(magicId);
      for (s in chunk) all.set(s.name, true);
    }

    // Create anonymous structure fields
    var fields:Array<ObjectField> = [];
    for (e in all.keys()) fields.push({field: cleanUpIdentifier(e), expr: macro $v{e}});

    // Return anonymous structure
    return {expr: EObjectDecl(fields), pos: pos}
  }




  #if macro


  /** Cleanup a string to make a valid Haxe identifier **/
  static inline function cleanUpIdentifier(v:String) {
    return (~/[^a-z0-9_]/gi).replace(v, "_");
  }


  /** Parse Aseprite file from path **/
  static function readAseprite(filePath:String):ase.Ase {
    var pos = Context.currentPos();

    // Check file existence
    if (!sys.FileSystem.exists(filePath)) {
      filePath = try Context.resolvePath(filePath) catch (_) haxe.macro.Context.fatalError('File not found: $filePath', pos);
    }

    // Break cache if file changes
    Context.registerModuleDependency(Context.getLocalModule(), filePath);

    // Parse file
    var bytes = sys.io.File.getBytes(filePath);
    var ase = try ase.Ase.fromBytes(bytes) catch (err:Dynamic) Context.fatalError("Failed to read Aseprite file: " + err, pos);
    return ase;
  }


  /**
    Try to resolve a `hxd.Res` expression (eg. hxd.Res.dir.myFile) to an actual file path (eg. "res/dir/myFile.aseprite").
    The approach is a bit dirty but it should work in 99% non-exotic cases.
  **/
  static function resolveResToPath(resExpr:Expr) : Null<String> {
    switch resExpr.expr {
      case EField(_):
      case _:
        Context.fatalError("Expected Resource identifier (eg. hxd.Res.myResource)", resExpr.pos);
    }

    // Turn Res expression to a string (eg. "hxd.Res.dir.myFile")
    var idents = new haxe.macro.Printer("").printExpr( resExpr ).split(".");
    if( idents[0]=="hxd" )
      idents.shift(); // remove hxd package
    if( idents.length==0 || !( ~/^_*[A-Z]/g ).match(idents[0]) )
      Context.fatalError("Expected Resource identifier (eg. hxd.Res.myResource)", resExpr.pos);
    idents.shift(); // remove Res class, whatever it is called
    if( idents.length==0 )
      Context.fatalError("Expected Resource identifier (eg. hxd.Res.myResource)", resExpr.pos);

    // Guess "res" dir
    var resPath = Context.definedValue("resourcesPath");
    if( resPath==null )
      resPath = "res";
    if( !sys.FileSystem.exists(resPath) )
      Context.fatalError("Res dir not found: "+resPath, Context.currentPos());

    // Look for file
    for(ext in [ "ase", "aseprite" ]) {
      var path = resPath+"/"+idents.join("/")+"."+ext;
      if( sys.FileSystem.exists(path) )
        return path;
    }

    // If everything fails, check if Res ident was renamed due to duplicate names
    var path = resPath+"/"+idents.join("/");
    var extensionReg = ~/(.+)_([a-z0-9]*)$/gi;
    extensionReg.replace(path,"$1.$2");
    if( sys.FileSystem.exists(path) )
      return path;

    Context.fatalError("Couldn't locate file for resource: "+idents.join("."), resExpr.pos);
    return null;
  }

  #end

}
