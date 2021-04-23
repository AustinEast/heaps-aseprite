# heaps-aseprite
Load and render sprites and animations in Aseprite format. Based on the [ase](https://github.com/miriti/ase) and [openfl-aseprite](https://github.com/miriti/openfl-aseprite) libraries. Sample Aseprite files all borrowed from `openfl-aseprite`.

## Features
* Hooks into the Heaps Engine's resource management to automatically handle any `.aseprite` or `.ase` file
* Optimizes runtime performance by parsing Aseprite files during compilation (generating `.png` and `.asedata` files)
* Supports all Color Modes, Animation Tags, Layers, and Slices (including 9-Slices!)
* Includes the `AseAnim` Class to easily render Animations (based on the Heaps Engine's `Anim` Class)
* Supports Live Resource Updating

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
// Get the whole sprite as a Tile
var spr1 = new Bitmap(Res.single_frame_sprite.toAseprite().toTile(), s2d);

// Alternatively get the sprite directly as an Image
var image = new Bitmap(Res.single_frame_sprite.toImage().toTile(), s2d);

// Get an animation from the sprite's tag
var spr2 = new AseAnim(Res.animated_sprite.toAseprite().getTag('walk'), s2d);
spr2.loop = true;

// Override the direction of a tagged animation
var spr3 = new AseAnim(Res.animated_sprite.toAseprite().getTag('walk', AnimationDirection.REVERSE), s2d);
spr3.loop = true;

// Get an animation based on tag and slice
var spr4 = new AseAnim(Res.animated_sprite.toAseprite().getTag('walk', -1, 'Head'), s2d);
spr4.loop = true;

// Get a single frame from a slice
var slice = new Bitmap(Res.slices.toAseprite().getSlice('Slice 1').tile, s2d);

// Get all frames from a slice
var slice2 = new AseAnim(Res.slices.toAseprite().getSlices('Slice 1'), s2d);
slice2.loop = true;

// Get a 9-Slice ScaleGrid from a slice
var nineSlice = Res.nine_slices.toAseprite().toScaleGrid('9-Slices', 0, s2d);

// Live Resource Updatng
var animation = new AseAnim(Res.animated_sprite.toAseprite().getTag('walk'), s2d);
animation.loop = true;
Res.animated_sprite.watch(() -> {
  // Make sure to call the default `watch()` callback!
  Res.animated_sprite.updateData();

  // Replay the animation to get the updated frames
  animation.play(Res.animated_sprite.toAseprite().getTag('walk'));
});
```

## Roadmap
* Document codebase (public fields and methods)
