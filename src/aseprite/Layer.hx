package aseprite;

@:structInit
class Layer {
  public var name:String;
  public var flags:Int;
  public var layerType:Int;
  public var blendMode:Int;
  public var opacity:Int;

  public static function fromChunk(chunk:ase.chunks.LayerChunk):Layer {
    return {
      name: chunk.name,
      flags: chunk.flags,
      layerType: chunk.layerType,
      blendMode: chunk.blendMode,
      opacity: chunk.opacity
    }
  }
}
