package aseprite;

import ase.chunks.PaletteChunk;
import haxe.io.Bytes;

class Palette {
  public var entries(default, null):Map<Int, UInt> = [];
  public var size(get, never):Int;

  var chunk:PaletteChunk;

  public function new(chunk:PaletteChunk) {
    this.chunk = chunk;

    for (index in chunk.entries.keys()) {
      var entry = chunk.entries[index];
      var color:Bytes = Bytes.alloc(4);
      color.set(0, entry.red);
      color.set(1, entry.green);
      color.set(2, entry.blue);
      color.set(3, entry.alpha);
      entries[index] = color.getInt32(0);
    }
  }

  inline function get_size():Int return chunk.paletteSize;
}
