package aseprite;

import ase.chunks.PaletteChunk;
import haxe.io.Bytes;

@:structInit
class Palette {
  public var entries(default, null):Map<Int, UInt>;
  public var firstColorIndex:Int;
  public var lastColorIndex:Int;
  public var size(default, null):Int;

  public static function fromChunk(chunk:PaletteChunk):Palette {
    var entries = new Map();
    for (index in chunk.entries.keys()) {
      var entry = chunk.entries[index];
      var color:Bytes = Bytes.alloc(4);
      color.set(0, entry.red);
      color.set(1, entry.green);
      color.set(2, entry.blue);
      color.set(3, entry.alpha);
      entries[index] = color.getInt32(0);
    }

    return {
      entries: entries,
      firstColorIndex: chunk.firstColorIndex,
      lastColorIndex: chunk.lastColorIndex,
      size: chunk.paletteSize
    }
  }
}
