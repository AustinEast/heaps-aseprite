package aseprite;

import ase.chunks.CelChunk;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hxd.BytesBuffer;
import hxd.Pixels;

class Cel {
  public var pixels(default, null):Pixels;
  public var chunk(default, null):CelChunk;

  public function new(sprite:Aseprite, chunk:CelChunk) {
    this.chunk = chunk;

    if (sprite.ase.header.colorDepth == 32) pixels = new Pixels(chunk.width, chunk.height, chunk.rawData, RGBA);
    else {
      var bytesInput:BytesInput = new BytesInput(chunk.rawData);
      var bytes:BytesBuffer = new BytesBuffer();

      switch (sprite.ase.header.colorDepth) {
        case 16:
          for (y in 0...chunk.height) for (x in 0...chunk.width) {
            var pixel = grayscaleToRgba(bytesInput.read(2));
            bytes.writeInt32(pixel);
          }
        case 8:
          for (y in 0...chunk.height) for (x in 0...chunk.width) {
            var pixel = indexedToRgba(sprite, bytesInput.readByte());
            bytes.writeInt32(pixel);
          }
      }
      pixels = new Pixels(chunk.width, chunk.height, bytes.getBytes(), RGBA);
    }
  }

  public function dispose() {
    if (pixels != null) pixels.dispose();
  }

  private function grayscaleToRgba(bytes:Bytes) {
    var rgba = Bytes.alloc(4);
    var c = bytes.get(0);
    rgba.set(0, c);
    rgba.set(1, c);
    rgba.set(2, c);
    rgba.set(3, bytes.get(1));
    return rgba.getInt32(0);
  }

  private inline function indexedToRgba(sprite:Aseprite, index:Int):Null<Int> {
    return index == sprite.ase.header.paletteEntry ? 0x00000000 : (sprite.palette.entries.exists(index) ? sprite.palette.entries[index] : 0x00000000);
  }
}
