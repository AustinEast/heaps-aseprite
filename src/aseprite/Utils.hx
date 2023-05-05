package aseprite;

import ase.Ase;
import ase.chunks.CelChunk;
import ase.chunks.LayerChunk.LayerFlags;
import ase.chunks.TagsChunk;
import ase.chunks.TilesetChunk;
import ase.types.ChunkType;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.UInt32Array;
import hxd.BytesBuffer;
import hxd.Math;
import hxd.Pixels;

class Utils {
  public static function parseAse(ase:Ase):{data:AsepriteData, pixels:Pixels} {
    var data = {
      frames: [],
      layers: [],
      tags: new Map(),
      slices: new Map(),
      palette: null,
      duration: 0.,
      width: ase.header.width,
      height: ase.header.height,
      widthInTiles: 1,
      heightInTiles: 1
    }

    // Parse all the chunk data
    for (chunk in ase.frames[0].chunks) {
      switch (chunk.header.type) {
        case LAYER:
          data.layers.push(Layer.fromChunk(cast chunk));
        case PALETTE:
          data.palette = Palette.fromChunk(cast chunk);
        case TAGS:
          var frameTags:TagsChunk = cast chunk;

          for (frameTagData in frameTags.tags) {
            var animationTag = aseprite.Tag.fromChunk(frameTagData);

            if (data.tags.exists(frameTagData.tagName)) {
              var num:Int = 1;
              var newName:String = '${frameTagData.tagName}_$num';
              while (data.tags.exists(newName)) {
                num++;
                newName = '${frameTagData.tagName}_$num';
              }
              trace('WARNING: This file already contains tag named "${frameTagData.tagName}". It will be automatically reanamed to "$newName"');
              data.tags[newName] = animationTag;
            }
            else {
              data.tags[frameTagData.tagName] = animationTag;
            }
          }
        case SLICE:
          var newSlice = Slice.fromChunk(cast chunk);
          data.slices[newSlice.name] = newSlice;
        case _:
      }
    }
    // Parse all the frame data
    for (i in 0...ase.frames.length) {
      // Add a new frame
      var frame:Frame = {index: i, duration: ase.frames[i].header.duration};
      data.duration += frame.duration;
      data.frames.push(frame);

      // Increment the width/height in tiles
      var y = Math.floor(i / data.widthInTiles);
      if (y >= data.heightInTiles) {
        data.heightInTiles++;
        data.widthInTiles++;
      }
    }

    // Add tags to the frames
    for (tag in data.tags) {
      for (i in tag.startFrame...tag.endFrame + 1) {
        data.frames[i].tags.push(tag.name);
      }
    }

    // Prepare the Pixels for processing
    var textureWidth = data.width * data.widthInTiles;
    var textureHeight = data.height * data.heightInTiles;
    var pixels = Pixels.alloc(textureWidth, textureHeight, RGBA);

    var frameLayers = new Vector<Vector<FrameLayer>>(data.frames.length);
    var framePixels = new Vector<Pixels>(data.frames.length);

    // Get the pixels for each frame
    for (i in 0...data.frames.length) {
      frameLayers[i] = new Vector(data.layers.length);
      for (j in 0...data.layers.length) {
        frameLayers[i][j] = {
          layer: data.layers[j],
          celChunk: null,
          pixels: null
        };
      }
      framePixels[i] = getFramePixels(data.frames[i], ase, data.palette, frameLayers);
    }

    // Blit all frame pixels into the main pixels instance
    for (i in 0...framePixels.length) {
      var x = i % data.widthInTiles;
      var y = Math.floor(i / data.widthInTiles);
      pixels.blit(data.width * x, data.height * y, framePixels[i], 0, 0, framePixels[i].width, framePixels[i].height);
    }

    // Dispose of parsed pixels
    for (p in framePixels) p.dispose();
    for (i in frameLayers) for (j in i) if (j.pixels != null) j.pixels.dispose();

    return {data: data, pixels: pixels};
  }

  static function getFramePixels(frame:Frame, ase:Ase, palette:Palette, frameLayers:Vector<Vector<FrameLayer>>):Pixels {
    var pixels = Pixels.alloc(ase.header.width, ase.header.height, RGBA);
    var currentFrameLayers = frameLayers[frame.index];
    var data = ase.frames[frame.index];

    for (chunk in data.chunks) {
      // Parse all the cel chunks - either get new pixels or create links to prior cel chunks (for linked cel animations)
      if (chunk.header.type == CEL) {
        var celChunk:CelChunk = cast chunk;
        switch (celChunk.celType) {
          case Linked:
            currentFrameLayers[celChunk.layerIndex].celChunk = frameLayers[celChunk.linkedFrame][celChunk.layerIndex].celChunk;
            currentFrameLayers[celChunk.layerIndex].pixels = frameLayers[celChunk.linkedFrame][celChunk.layerIndex].pixels;
          case CompressedImage | Raw:
            currentFrameLayers[celChunk.layerIndex].celChunk = celChunk;
            currentFrameLayers[celChunk.layerIndex].pixels = getCelPixels(ase, palette, celChunk);
          case CompressedTilemap:
            var tilesetChunk:TilesetChunk = getTilemapFromCel(celChunk, ase, frame);
            currentFrameLayers[celChunk.layerIndex].celChunk = celChunk;
            currentFrameLayers[celChunk.layerIndex].pixels = getCelPixelsFromTilemap(ase, palette, celChunk, tilesetChunk);
          case _: throw "Unknown CelType " + Std.string(celChunk.celType);
        }
      }

      // Copy all cel chunk pixels to the frame
      for (layer in currentFrameLayers) {
        if (layer.celChunk != null && (layer.layer.flags & LayerFlags.Visible != 0)) {
          // Get the rect of pixels to grab from the cel chunk
          // If a cel chunk starts off-canvas (ie has an x/y below zero), ignore those pixels
          var minX = layer.celChunk.xPosition < 0 ? -layer.celChunk.xPosition : 0;
          var minY = layer.celChunk.yPosition < 0 ? -layer.celChunk.yPosition : 0;
          var maxWidth = layer.celChunk.width;
          var maxHeight = layer.celChunk.height;

          if (layer.celChunk.celType == CompressedTilemap) {
            // celChunk width and height is in tiles - convert to pixel width and height
            var tilesetChunk:TilesetChunk = getTilemapFromCel(layer.celChunk, ase, frame);
            maxWidth *= tilesetChunk.width;
            maxHeight *= tilesetChunk.height;
          }

          // Iterate through the cel chunk's pixels and copy them to the frame's pixels
          for (y in minY...maxHeight) for (x in minX...maxWidth) {
            // Get the relative position of the cel chunk's pixel VS the canvas
            var xOffset = x + layer.celChunk.xPosition;
            var yOffset = y + layer.celChunk.yPosition;

            // If the relative position is off canvas, skip it
            if (xOffset >= pixels.width || yOffset >= pixels.height || xOffset < 0 || yOffset < 0) continue;

            var pixel = layer.pixels.getPixel(x, y);
            if (pixel != 0) pixels.setPixel(xOffset, yOffset, pixel);
          }
        }
      }
    }
    return pixels;
  }

  static function getCelPixels(ase:Ase, palette:Palette, celChunk:CelChunk):Pixels {
    if (ase.header.colorDepth == 32) return new Pixels(celChunk.width, celChunk.height, celChunk.rawData, RGBA);
    else {
      var bytesInput:BytesInput = new BytesInput(celChunk.rawData);
      var bytes:BytesBuffer = new BytesBuffer();

      switch (ase.header.colorDepth) {
        case BPP16:
          for (y in 0...celChunk.height) for (x in 0...celChunk.width) {
            var pixel = grayscaleToRgba(bytesInput.read(2));
            bytes.writeInt32(pixel);
          }
        case INDEXED:
          for (y in 0...celChunk.height) for (x in 0...celChunk.width) {
            var pixel = indexedToRgba(ase, palette, bytesInput.readByte());
            bytes.writeInt32(pixel);
          }
        case _:
      }
      return new Pixels(celChunk.width, celChunk.height, bytes.getBytes(), RGBA);
    }
  }

  static function getCelPixelsFromTilemap(ase:Ase, palette:Palette, celChunk:CelChunk, tilesetChunk:TilesetChunk) {
    var bytesInput = new BytesInput(tilesetChunk.uncompressedTilesetImage);
    var allTilePixels:Array<Pixels> = [];

    // Read from uncompressedTilesetImage into an Array<Pixels> where each entry is a tile
    for (i in 0...tilesetChunk.numTiles) {
      var tile:BytesBuffer = new BytesBuffer();
      switch (ase.header.colorDepth) {
        case BPP32:
          for (y in 0...tilesetChunk.height) for (x in 0...tilesetChunk.width) {
            tile.writeInt32(bytesInput.readInt32());
          };
        case BPP16:
          for (y in 0...tilesetChunk.height) for (x in 0...tilesetChunk.width) {
            tile.writeInt32(grayscaleToRgba(bytesInput.read(2)));
          };
        case INDEXED:
          for (y in 0...tilesetChunk.height) for (x in 0...tilesetChunk.width) {
            tile.writeInt32(indexedToRgba(ase, palette, bytesInput.readByte()));
          };
      }

      allTilePixels.push(new Pixels(tilesetChunk.width, tilesetChunk.height, tile.getBytes(), RGBA));
    }

    // alloc for total chunk pixels
    var resultBytes:Bytes = Bytes.alloc(Std.int((celChunk.width * tilesetChunk.width * celChunk.height * tilesetChunk.height) * 4));
    resultBytes.fill(0, resultBytes.length, 0);
    var resultPixels:Pixels = new Pixels(celChunk.width * tilesetChunk.width, celChunk.height * tilesetChunk.height, resultBytes, RGBA);

    // Blit the tiles onto the result pixels
    var tileIndices = UInt32Array.fromBytes(celChunk.tilemapData);

    for (y in 0...celChunk.height) for (x in 0...celChunk.width) {
      var idx = tileIndices[y * celChunk.width + x];
      var pixels:Pixels = allTilePixels[idx];

      resultPixels.blit(x * tilesetChunk.width, y * tilesetChunk.height, pixels, 0, 0, tilesetChunk.width, tilesetChunk.height);
    }

    return resultPixels;
  }

  static function getTilemapFromCel(celChunk:CelChunk, ase:Ase, frame:Frame) {
    var tilesetIndex:Int = ase.layers[celChunk.layerIndex].chunk.tilesetIndex;
    var tilesetChunk:TilesetChunk = cast ase.frames[frame.index].chunkTypes[TILESET][tilesetIndex];
    return tilesetChunk;
  }

  static inline function grayscaleToRgba(bytes:Bytes) {
    var rgba = Bytes.alloc(4);
    var c = bytes.get(0);
    rgba.set(0, c);
    rgba.set(1, c);
    rgba.set(2, c);
    rgba.set(3, bytes.get(1));
    return rgba.getInt32(0);
  }

  static inline function indexedToRgba(ase:Ase, palette:Palette, index:Int):Null<Int> {
    return index == ase.header.paletteEntry ? 0x00000000 : (palette.entries.exists(index) ? palette.entries[index] : 0x00000000);
  }

  static inline function nextPowerOfTwo(v:Int) {
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    return v;
  }
}

typedef FrameLayer = {
  layer:Layer,
  celChunk:CelChunk,
  pixels:Pixels
};
