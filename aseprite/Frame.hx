package aseprite;

import ase.chunks.CelChunk;
import ase.chunks.CelType;
import ase.chunks.ChunkType;
import ase.chunks.LayerChunk;
import ase.chunks.LayerFlags;
import hxd.Math;
import hxd.Pixels;

class Frame {
  public var data(default, null):ase.Frame;
  public var pixels(default, null):Pixels;
  public var duration(get, never):Int;
  public var index(default, null):Int;
  public var layers(default, null):Array<FrameLayer> = [];
  public var layersMap(default, null):Map<String, FrameLayer> = [];
  public var tags(default, null):Array<String> = [];

  public function new(data:FrameData) {
    index = data.index;
    if (data.pixels != null) {
      pixels = data.pixels;
    }
    else if (data.sprite != null) {
      pixels = Pixels.alloc(data.sprite.ase.header.width, data.sprite.ase.header.height, RGBA);

      this.data = data.frame;

      for (layer in data.sprite.layers) {
        var layerDef = {
          layerChunk: layer,
          cel: null
        };
        layers.push(layerDef);
        layersMap[layer.name] = layerDef;
      }

      for (chunk in data.frame.chunks) {
        if (chunk.header.type == ChunkType.CEL) {
          var cel:CelChunk = cast chunk;

          if (cel.celType == CelType.LINKED) {
            layers[cel.layerIndex].cel = data.sprite.frames[cel.linkedFrame].layers[cel.layerIndex].cel;
          }
          else {
            layers[cel.layerIndex].cel = new Cel(data.sprite, cel);
          }
        }

        for (layer in layers) {
          if (layer.cel != null && (layer.layerChunk.flags & LayerFlags.VISIBLE != 0)) {
            var minX = layer.cel.chunk.xPosition < 0 ? -layer.cel.chunk.xPosition : 0;
            var minY = layer.cel.chunk.yPosition < 0 ? -layer.cel.chunk.yPosition : 0;
            var maxWidth = Math.imin(layer.cel.chunk.width, pixels.width);
            var maxHeight = Math.imin(layer.cel.chunk.height, pixels.height);
            for (y in 0...maxHeight) for (x in 0...maxWidth) {
              var xPos = x + minX;
              var yPos = y + minY;
              var xOffset = Math.imin(xPos + layer.cel.chunk.xPosition, pixels.width - 1);
              var yOffset = Math.imin(yPos + layer.cel.chunk.yPosition, pixels.height - 1);
              var pixel = layer.cel.pixels.getPixel(xPos, yPos);
              if (pixel != 0) {
                pixels.setPixel(xOffset, yOffset, pixel);
              }
            }
          }
        }
      }
    }
  }

  inline function get_duration():Int return data.header.duration;
}

typedef FrameData = {
  index:Int,
  ?pixels:Pixels,
  ?sprite:Aseprite,
  ?frame:ase.Frame
}

typedef FrameLayer = {
  layerChunk:LayerChunk,
  cel:Cel
};
