package aseprite;

import ase.chunks.SliceChunk;

class Slice {
  public var name(get, never):String;
  public var data:SliceChunk;

  public function new(data:SliceChunk) {
    this.data = data;
  }

  private inline function get_name() return data.name;
}
