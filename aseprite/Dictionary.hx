package aseprite;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end


/**
	This class extracts various identifiers from an Aseprite file on compilation time. This creates a typed structure that allows some type-safety: if an identifier changes in your Aseprite file (eg. a tag), your compilation will show errors on every places you used this identifier. Example:
		```haxe
		var tagsDictionary = aseprite.Dictionary.getTags("assets/myCharacter.aseprite");
		trace(tagsDictionary); // { run:"run", idle:"idle", attackA:"attackA" }
		someAnimManager.play( tagsDictionary.run );
		```
**/
class Dictionary {
	/**
		Build an anonymous object containing all "tags" names found in given Aseprite file.
		Example: `{  run:"run",  idle:"idle",  attackA:"attackA"  }`
	**/
	macro public static function getTags(asepritePath:String) {
		var pos = Context.currentPos();
		var ase = readAseprite(asepritePath);

		// List all tags
		final magicId = 0x2018;
		var all : Map<String,Bool> = new Map(); // "Map" type avoids duplicates
		for(f in ase.frames) {
			if( !f.chunkTypes.exists(magicId) )
				continue;
			var tags : Array<ase.chunks.TagsChunk> = cast f.chunkTypes.get(magicId);
			for( tc in tags )
			for( t in tc.tags )
				all.set(t.tagName, true);
		}

		// Create "tags" anonymous structure
		var tagFields : Array<ObjectField> = [];
		for( tag in all.keys() )
			tagFields.push({ field: cleanUpIdentifier(tag),  expr: macro $v{tag} });

		// Return anonymous structure
		return { expr:EObjectDecl(tagFields), pos:pos }
	}


	/**
		Build an anonymous object containing all "slices" names found in given Aseprite file.
		Example: `{  mySlice:"mySlice",  grass1:"grass1",  stoneBlock:"stoneBlock"  }`
	**/
	macro public static function getSlices(asepritePath:String) {
		var pos = Context.currentPos();
		var ase = readAseprite(asepritePath);

		// List all slices
		final magicId = 0x2022;
		var all : Map<String,Bool> = new Map(); // "Map" type avoids duplicates
		for(f in ase.frames) {
			if( !f.chunkTypes.exists(magicId) )
				continue;
			var chunk : Array<ase.chunks.SliceChunk> = cast f.chunkTypes.get(magicId);
			for( s in chunk )
				all.set(s.name, true);
		}

		// Create anonymous structure fields
		var fields : Array<ObjectField> = [];
		for( e in all.keys() )
			fields.push({ field: cleanUpIdentifier(e),  expr: macro $v{e} });

		// Return anonymous structure
		return { expr:EObjectDecl(fields), pos:pos }
	}




	#if macro

	/** Cleanup a string to make a valid Haxe identifier **/
	static inline function cleanUpIdentifier(v:String) {
		return ( ~/[^a-z0-9_]/gi ).replace(v, "_");
	}


	/** Parse Aseprite file from path **/
	static function readAseprite(filePath:String) : ase.Ase {
		var pos = Context.currentPos();

		// Check file existence
		if( !sys.FileSystem.exists(filePath) ) {
			filePath = try Context.resolvePath(filePath)
				catch(_) haxe.macro.Context.fatalError('File not found: $filePath', pos);
		}

		// Break cache if file changes
		Context.registerModuleDependency(Context.getLocalModule(), filePath);

		// Parse file
		var bytes = sys.io.File.getBytes(filePath);
		var ase = try ase.Ase.fromBytes(bytes)
			catch(err:Dynamic) Context.fatalError("Failed to read Aseprite file: "+err, pos);
		return ase;
	}

	#end
}