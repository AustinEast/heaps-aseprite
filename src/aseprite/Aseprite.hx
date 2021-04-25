package aseprite;

import ase.AnimationDirection;
import ase.Ase;
import ase.chunks.CelChunk;
import ase.chunks.CelType;
import ase.chunks.ChunkType;
import ase.chunks.LayerFlags;
import ase.chunks.TagsChunk;
import aseprite.Frame;
import aseprite.Palette;
import aseprite.Slice;
import aseprite.Tag;
import h2d.Object;
import h2d.ScaleGrid;
import h2d.Tile;
import h3d.mat.Texture;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hxd.BytesBuffer;
import hxd.Pixels;

using hxd.Math;

class Aseprite {
  public var frames(default, null):Array<Frame> = [];
  public var layers(default, null):Array<Layer> = [];
  public var tags(default, null):Map<String, Tag> = [];
  public var slices(default, null):Map<String, Slice> = [];
  public var palette(default, null):Palette;
  /**
   * The total duration of all frames.
   */
  public var duration(default, null):Float = 0;
  /**
   * Width of the Aseprite file's canvas.
   */
  public var width(default, null):Int;
  /**
   * Height of the Aseprite file's canvas.
   */
  public var height(default, null):Int;

  var texture:Texture;
  var tiles:Array<Tile>;
  var widthInTiles:Int;
  var heightInTiles:Int;

  public static function fromBytes(bytes:Bytes):Aseprite {
    var aseprite = new Aseprite();
    aseprite.loadBytes(bytes);
    return aseprite;
  }

  public static function fromData(data:AsepriteData, texture:Texture) {
    var aseprite = new Aseprite();
    aseprite.loadData(data, texture);
    return aseprite;
  }

  function new() {}

  public function toTile():Tile {
    return Tile.fromTexture(getTexture());
  }

  public function toTiles():Array<Tile> {
    if (tiles != null) return tiles;

    var tile = toTile();
    tiles = [
      for (i in 0...frames.length) {
        var x = i % widthInTiles;
        var y = Math.floor(i / widthInTiles);
        tile.sub(x * width, y * height, width, height);
      }
    ];

    return tiles;
  }

  public function toScaleGrid(name:String, frame:Int = 0, ?parent:Object) {
    var slice = slices.get(name);
    if (slice == null) {
      trace('WARNING: A slice named "$name" does not exist on this Aseprite.');
      return null;
    }

    if (!slice.has9Slices) {
      trace('WARNING: Slice "$name" does not have 9-Slices enabled.');
      return null;
    }

    var sliceKey = slice.keys[frame];

    return new ScaleGrid(toTile().sub(sliceKey.xOrigin, sliceKey.yOrigin, sliceKey.width, sliceKey.height, -sliceKey.xPivot, -sliceKey.yPivot),
      sliceKey.xCenter, sliceKey.yCenter, parent);
  }

  public function toData():AsepriteData {
    return {
      frames: frames,
      layers: layers,
      tags: [for (tag in tags) tag],
      slices: [for (slice in slices) slice],
      palette: palette,
      duration: duration,
      width: width,
      height: height
    }
  }

  public inline function getTexture():Texture {
    return texture;
  }

  public function getFrames():Array<AsepriteFrame> {
    var tiles = toTiles();
    return [
      for (frame in frames) {index: frame.index, tile: tiles[frame.index], duration: frame.duration}
    ];
  }

  public function getFrame(index:Int):AsepriteFrame {
    return {index: index, tile: toTiles()[index], duration: frames[index].duration};
  }

  public function getTag(name:String, direction:Int = -1, ?sliceName:String):Array<AsepriteFrame> {
    var tag = tags.get(name);
    if (tag == null) {
      trace('WARNING: A tag named "$name" does not exist on this Aseprite.');
      return null;
    }

    var slice:Slice = null;
    if (sliceName != null) {
      slice = slices.get(sliceName);
      if (slice == null) trace('WARNING: A slice named "$sliceName" does not exist on this Aseprite.');
    }

    var tiles = toTiles();
    var animation = [];

    function addAnimation(frame:Int) {
      var sliceKey = slice == null ? null : getSliceKey(slice, frame);
      animation.push({
        index: frame,
        tile: sliceKey == null ? tiles[frame] : tiles[frame].sub(sliceKey.xOrigin, sliceKey.yOrigin, sliceKey.width, sliceKey.height, -sliceKey.xPivot,
          -sliceKey.yPivot),
        duration: frames[frame].duration
      });
    }

    if (tag.endFrame == tag.startFrame) addAnimation(tag.startFrame);
    else switch (direction < 0 ? tag.animationDirection : direction) {
      case AnimationDirection.FORWARD:
        for (i in tag.startFrame...tag.endFrame + 1) addAnimation(i);
      case AnimationDirection.REVERSE:
        var i = tag.endFrame;
        while (i >= tag.startFrame) {
          addAnimation(i);
          i--;
        }
      case AnimationDirection.PING_PONG:
        var i = tag.startFrame;
        var advance = true;
        while (i > tag.startFrame || advance) {
          addAnimation(i);
          if (advance && i >= tag.endFrame) advance = false;
          i += advance ? 1 : -1;
        }
    }
    return animation;
  }

  public function getSlice(name:String, frame:Int = 0):AsepriteFrame {
    var slice = slices.get(name);
    if (slice == null) {
      trace('WARNING: A slice named "$name" does not exist on this Aseprite.');
      return null;
    }

    var sliceKey = getSliceKey(slice, frame);
    var x = frame % widthInTiles;
    var y = Math.floor(frame / widthInTiles);

    return {
      index: frame,
      tile: toTile().sub(x * width
        + sliceKey.xOrigin, y * height
        + sliceKey.yOrigin, sliceKey.width, sliceKey.height,
        -sliceKey.xPivot,
        -sliceKey.yPivot),
      duration: frames[frame].duration
    }
  }

  public function getSlices(name:String):Array<AsepriteFrame> {
    var slice = slices.get(name);
    if (slice == null) {
      trace('WARNING: A slice named "$name" does not exist on this Aseprite.');
      return null;
    }

    var tile = toTile();

    return [
      for (i in 0...frames.length) {
        var sliceKey = getSliceKey(slice, i);
        var x = i % widthInTiles;
        var y = Math.floor(i / widthInTiles);
        {
          index: i,
          tile: tile.sub(x * width + sliceKey.xOrigin, y * height + sliceKey.yOrigin, sliceKey.width, sliceKey.height, slice.hasPivot ? -sliceKey.xPivot : 0,
            slice.hasPivot ? -sliceKey.yPivot : 0),
          duration: frames[i].duration
        }
      }
    ];
  }

  public function loadBytes(bytes:Bytes) {
    tiles = null;

    var ase = Ase.fromBytes(bytes);

    width = ase.header.width;
    height = ase.header.height;

    // Parse all the chunk data
    for (chunk in ase.frames[0].chunks) {
      switch (chunk.header.type) {
        case ChunkType.LAYER:
          layers.push(Layer.fromChunk(cast chunk));
        case ChunkType.PALETTE:
          palette = Palette.fromChunk(cast chunk);
        case ChunkType.TAGS:
          var frameTags:TagsChunk = cast chunk;

          for (frameTagData in frameTags.tags) {
            var animationTag = Tag.fromChunk(frameTagData);

            if (tags.exists(frameTagData.tagName)) {
              var num:Int = 1;
              var newName:String = '${frameTagData.tagName}_$num';
              while (tags.exists(newName)) {
                num++;
                newName = '${frameTagData.tagName}_$num';
              }
              trace('WARNING: This file already contains tag named "${frameTagData.tagName}". It will be automatically reanamed to "$newName"');
              tags[newName] = animationTag;
            }
            else {
              tags[frameTagData.tagName] = animationTag;
            }
          }
        case ChunkType.SLICE:
          var newSlice = Slice.fromChunk(cast chunk);
          slices[newSlice.name] = newSlice;
      }
    }

    widthInTiles = 1;
    heightInTiles = 1;

    // Parse all the frame data
    for (i in 0...ase.frames.length) {
      // Add a new frame
      var frame:Frame = {index: i, duration: ase.frames[i].header.duration};
      duration += frame.duration;
      frames.push(frame);

      // Increment the width/height in tiles
      var y = Math.floor(i / widthInTiles);
      if (y >= heightInTiles) {
        heightInTiles++;
        widthInTiles++;
      }
    }

    // Add tags to the frames
    for (tag in tags) {
      for (i in tag.startFrame...tag.endFrame + 1) {
        frames[i].tags.push(tag.name);
      }
    }

    var textureWidth = width * widthInTiles;
    var textureHeight = height * heightInTiles;

    var pixels = Pixels.alloc(textureWidth, textureHeight, RGBA);

    var frameLayers = new Vector<Vector<FrameLayer>>(frames.length);
    var framePixels = new Vector<Pixels>(frames.length);

    // Get the pixels for each frame
    for (i in 0...frames.length) {
      frameLayers[i] = new Vector(layers.length);
      for (j in 0...layers.length) {
        frameLayers[i][j] = {
          layer: layers[j],
          celChunk: null,
          pixels: null
        };
      }

      framePixels[i] = getFramePixels(frames[i], ase, palette, frameLayers);
    }

    // Blit all frame pixels into the main pixels instance
    for (i in 0...framePixels.length) {
      var x = i % widthInTiles;
      var y = Math.floor(i / widthInTiles);
      pixels.blit(width * x, height * y, framePixels[i], 0, 0, framePixels[i].width, framePixels[i].height);
    }

    // Update the texture
    if (texture == null) {
      texture = Texture.fromPixels(pixels);
    }
    else {
      var t = Texture.fromPixels(pixels);
      texture.swapTexture(t);
      texture.alloc();
      t.dispose();
    }

    // Dispose of parsed pixels
    pixels.dispose();
    for (p in framePixels) p.dispose();
    for (i in frameLayers) for (j in i) if (j.pixels != null) j.pixels.dispose();
  }

  public function loadData(data:AsepriteData, ?tex:Texture) {
    tiles = null;

    frames = data.frames;
    layers = data.layers;
    palette = data.palette;
    duration = data.duration;
    width = data.width;
    height = data.height;

    tags.clear();
    slices.clear();

    for (tag in data.tags) tags.set(tag.name, tag);
    for (slice in data.slices) slices.set(slice.name, slice);

    widthInTiles = 1;
    heightInTiles = 1;

    // Increment the width/height in tiles
    for (i in 0...frames.length) {
      var y = Math.floor(i / widthInTiles);
      if (y >= heightInTiles) {
        heightInTiles++;
        widthInTiles++;
      }
    }

    if (tex == null) return;

    // Update the Texture
    if (texture == null) {
      texture = tex;
    }
    else {
      texture.swapTexture(tex);
      texture.alloc();
      tex.dispose();
    }
  }

  inline function getSliceKey(slice:Slice, frame:Int) {
    var sliceKey = null;
    var i = slice.keys.length;
    while (i > 0) {
      i--;
      if (frame >= slice.keys[i].frameNumber) {
        sliceKey = slice.keys[i];
        break;
      }
    }
    return sliceKey;
  }

  static function getFramePixels(frame:Frame, ase:Ase, palette:Palette, frameLayers:Vector<Vector<FrameLayer>>):Pixels {
    var pixels = Pixels.alloc(ase.header.width, ase.header.height, RGBA);
    var currentFrameLayers = frameLayers[frame.index];
    var data = ase.frames[frame.index];

    for (chunk in data.chunks) {
      if (chunk.header.type == ChunkType.CEL) {
        var celChunk:CelChunk = cast chunk;
        if (celChunk.celType == CelType.LINKED) {
          currentFrameLayers[celChunk.layerIndex].celChunk = frameLayers[celChunk.linkedFrame][celChunk.layerIndex].celChunk;
          currentFrameLayers[celChunk.layerIndex].pixels = frameLayers[celChunk.linkedFrame][celChunk.layerIndex].pixels;
        }
        else {
          currentFrameLayers[celChunk.layerIndex].celChunk = celChunk;
          currentFrameLayers[celChunk.layerIndex].pixels = getCelPixels(ase, palette, celChunk);
        }
      }
      for (layer in currentFrameLayers) {
        if (layer.celChunk != null && (layer.layer.flags & LayerFlags.VISIBLE != 0)) {
          var minX = layer.celChunk.xPosition < 0 ? -layer.celChunk.xPosition : 0;
          var minY = layer.celChunk.yPosition < 0 ? -layer.celChunk.yPosition : 0;
          var maxWidth = Math.imin(layer.celChunk.width, pixels.width);
          var maxHeight = Math.imin(layer.celChunk.height, pixels.height);
          for (y in 0...maxHeight) for (x in 0...maxWidth) {
            var xPos = x + minX;
            var yPos = y + minY;
            var pixel = layer.pixels.getPixel(xPos, yPos);
            if (pixel != 0) {
              var xOffset = Math.imin(xPos + layer.celChunk.xPosition, pixels.width - 1);
              var yOffset = Math.imin(yPos + layer.celChunk.yPosition, pixels.height - 1);
              pixels.setPixel(xOffset, yOffset, pixel);
            }
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
        case 16:
          for (y in 0...celChunk.height) for (x in 0...celChunk.width) {
            var pixel = grayscaleToRgba(bytesInput.read(2));
            bytes.writeInt32(pixel);
          }
        case 8:
          for (y in 0...celChunk.height) for (x in 0...celChunk.width) {
            var pixel = indexedToRgba(ase, palette, bytesInput.readByte());
            bytes.writeInt32(pixel);
          }
      }
      return new Pixels(celChunk.width, celChunk.height, bytes.getBytes(), RGBA);
    }
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

typedef AsepriteData = {
  frames:Array<Frame>,
  layers:Array<Layer>,
  tags:Array<Tag>,
  slices:Array<Slice>,
  palette:Palette,
  duration:Float,
  width:Int,
  height:Int
}

typedef AsepriteFrame = {index:Int, tile:Tile, duration:Int}

typedef FrameLayer = {
  layer:Layer,
  celChunk:CelChunk,
  pixels:Pixels
};
