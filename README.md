# heaps-aseprite
Load and render sprites and animations in Aseprite format. Based on the [ase](https://github.com/miriti/ase) and [openfl-aseprite](https://github.com/miriti/openfl-aseprite) libraries. Sample Aseprite files all borrowed from `openfl-aseprite`.

## Features
* Hooks into the Heaps Engine's resource management to automatically handle any `.aseprite` or `.ase` file
* Supports all Color Modes, Animation Tags, Layers, and Slices (including 9-Slices!)
* Includes the `AseAnim` Class to easily render Animations (based on the Heaps Engine's `Anim` Class)

## Getting Started

heaps-aseprite requires [Haxe 4](https://haxe.org/download/) and the [Heaps Engine](https://heaps.io) to run.

Install the library from haxelib:
```
haxelib install heaps-aseprite
```
Alternatively the dev version of the library can be installed from github:
```
haxelib git heaps-aseprite https://github.com/AustinEast/heaps-aseprite.git
```

Install heaps-aseprite's dependency, [ase](https://github.com/miriti/ase).
```
haxelib install ase
```

Then include the library in your project's `.hxml`:
```hxml
-lib heaps-aseprite
```

## Example

```haxe
package;

import aseprite.AseAnim;
import h2d.Bitmap;
import h2d.Flow;
import hxd.App;
import hxd.Key;
import hxd.Res;

class Main extends App {
  var flow:Flow;
  var scrollSpeed = 250;

  override function init() {
    #if hl
    Res.initLocal();
    #else
    Res.initEmbed();
    #end

    engine.backgroundColor = 0x403750;

    s2d.scaleMode = ScaleMode.LetterBox(engine.width, engine.height);

    flow = new Flow(s2d);
    flow.multiline = true;
    flow.maxWidth = engine.width;

    // RBG Color Mode
    new Bitmap(Res._128x128_rgba.toTile(), flow);
    // Grayscale Color Mode
    new Bitmap(Res.grayscale.toTile(), flow);
    // Indexed Color Mode
    new Bitmap(Res.indexed_multi_layer.toTile(), flow);

    // Tagged animations
    new AseAnim(Res.tags.getTag('walk'), flow).loop = true;
    new AseAnim(Res.tags.getTag('hit_face'), flow).loop = true;
    new AseAnim(Res.tags.getTag('fall'), flow).loop = true;

    // Ping-Pong animation
    new AseAnim(Res.pong.getTag('pong'), flow).loop = true;

    // Linked Cells
    new AseAnim(Res.anim_linked_cels.getFrames(), flow).loop = true;

    // Slice
    new Bitmap(Res.slices.getSlice('Slice 1').tile, flow);
    // 9 Slice
    Res.slices.toScaleGrid('9-Slices', 0, flow);

    // Animated Slices
    new AseAnim(Res.slices2.getSlices('Slice 1'), flow).loop = true;
    new AseAnim(Res.slices2.getSlices('Slice 2'), flow).loop = true;
    new AseAnim(Res.slices2.getSlices('Slice 3'), flow).loop = true;
    new AseAnim(Res.slices2.getSlices('Slice 4'), flow).loop = true;
  }

  override function update(dt:Float) {
    if (Key.isPressed(Key.MOUSE_WHEEL_UP)) flow.scale(1.1);
    if (Key.isPressed(Key.MOUSE_WHEEL_DOWN)) flow.scale(.9);
    if (Key.isDown(Key.UP)) s2d.camera.move(0, -scrollSpeed * dt);
    if (Key.isDown(Key.DOWN)) s2d.camera.move(0, scrollSpeed * dt);
    if (Key.isDown(Key.RIGHT)) s2d.camera.move(scrollSpeed * dt, 0);
    if (Key.isDown(Key.LEFT)) s2d.camera.move(-scrollSpeed * dt, 0);
    if (Key.isPressed(Key.SPACE)) flow.debug = !flow.debug;

    flow.scaleX = Math.max(1, flow.scaleX);
    flow.scaleY = Math.max(1, flow.scaleY);
    flow.reflow();
  }

  static function main() {
    new Main();
  }
}
```

## Roadmap
### Sooner
* Improve Readme
* Document codebase
### Later
* Utilize Heaps Engine's `Convert` functionality
* Support Live File Reloading
