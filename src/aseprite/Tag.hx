package aseprite;

@:structInit
class Tag {
  public var name(default, null):String;
  public var startFrame(default, null):Int;
  public var endFrame(default, null):Int;
  public var animationDirection(default, null):Int;

  public static function fromChunk(chunk:ase.chunks.TagsChunk.Tag):Tag {
    return {
      name: chunk.tagName,
      startFrame: chunk.fromFrame,
      endFrame: chunk.toFrame,
      animationDirection: chunk.animDirection
    }
  }
}
