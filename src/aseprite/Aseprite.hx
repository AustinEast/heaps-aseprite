package aseprite;

import ase.AnimationDirection;
import ase.Ase;
import aseprite.Frame;
import aseprite.Palette;
import aseprite.Slice;
import aseprite.Tag;
import h2d.Object;
import h2d.ScaleGrid;
import h2d.Tile;
import h3d.mat.Texture;
import haxe.io.Bytes;
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

  public static function fromData(data:AsepriteData, pixels:Pixels) {
    var aseprite = new Aseprite();
    aseprite.loadData(data, pixels);
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
      tags: tags,
      slices: slices,
      palette: palette,
      duration: duration,
      width: width,
      height: height,
      widthInTiles: widthInTiles,
      heightInTiles: heightInTiles
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
    var ase = Ase.fromBytes(bytes);
    var parsedAse = Utils.parseAse(ase);

    loadData(parsedAse.data, parsedAse.pixels);

    parsedAse.pixels.dispose();
  }

  public function loadData(data:AsepriteData, ?pixels:Pixels) {
    tiles = null;

    frames = data.frames;
    layers = data.layers;
    tags = data.tags;
    slices = data.slices;
    palette = data.palette;
    duration = data.duration;
    width = data.width;
    height = data.height;
    widthInTiles = data.widthInTiles;
    heightInTiles = data.heightInTiles;

    if (pixels == null) return;

    // Update the Texture
    if (texture == null) {
      texture = Texture.fromPixels(pixels);
    }
    else {
      texture.uploadPixels(pixels);
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
}

typedef AsepriteFrame = {index:Int, tile:Tile, duration:Int}
