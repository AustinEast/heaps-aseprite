package aseprite;

import ase.chunks.SliceChunk;

@:structInit
class Slice {
  public var name(default, null):String;
  public var keys(default, null):Array<SliceKey>;
  public var has9Slices(default, null):Bool;
  public var hasPivot(default, null):Bool;

  public static function fromChunk(chunk:SliceChunk):Slice {
    return {
      name: chunk.name,
      keys: chunk.sliceKeys,
      has9Slices: chunk.has9Slices,
      hasPivot: chunk.hasPivot
    }
  }
}
