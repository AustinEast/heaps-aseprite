package aseprite;

class Tag {
  public var chunk(default, null):ase.chunks.TagsChunk.Tag;
  public var name(get, never):String;

  public function new(data:ase.chunks.TagsChunk.Tag) {
    chunk = data;
  }

  inline function get_name():String return chunk.tagName;
}
