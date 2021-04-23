package;

import ase.AnimationDirection;
import aseprite.AseAnim;
import h2d.Bitmap;
import h2d.Flow;
import h2d.Text;
import haxe.Serializer;
import haxe.Unserializer;
import hxd.App;
import hxd.Key;
import hxd.Res;
import hxd.res.DefaultFont;

class Main extends App {
  var flow:Flow;
  var scrollSpeed = 250;
  var drawcalls:Text;
  var fps:Text;

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

    drawcalls = new Text(DefaultFont.get(), s2d);
    drawcalls.text = 'drawcalls: ${engine.drawCalls}';

    fps = new Text(DefaultFont.get(), s2d);
    fps.text = 'fps: ${engine.fps}';
    fps.y += drawcalls.textHeight;

    // RBG Color Mode
    new Bitmap(Res._128x128_rgba.toAseprite().toTile(), flow);
    // Grayscale Color Mode
    new Bitmap(Res.grayscale.toAseprite().toTile(), flow);
    // Indexed Color Mode
    new Bitmap(Res.indexed_multi_layer.toAseprite().toTile(), flow);

    // Tagged animations
    new AseAnim(Res.tags.toAseprite().getTag('walk'), flow).loop = true;
    new AseAnim(Res.tags.toAseprite().getTag('hit_face'), flow).loop = true;
    new AseAnim(Res.tags.toAseprite().getTag('fall'), flow).loop = true;

    // Tagged animation with direction override
    new AseAnim(Res.tags.toAseprite().getTag('walk', AnimationDirection.REVERSE), flow).loop = true;

    // Tagged animation with slices
    new AseAnim(Res.tags.toAseprite().getTag('fall', -1, 'Head'), flow).loop = true;

    // Ping-Pong animation
    new AseAnim(Res.pong.toAseprite().getTag('pong'), flow).loop = true;

    // Linked Cells
    new AseAnim(Res.anim_linked_cels.toAseprite().getFrames(), flow).loop = true;

    // Slice
    new Bitmap(Res.slices.toAseprite().getSlice('Slice 1').tile, flow);
    // 9 Slice
    Res.slices.toAseprite().toScaleGrid('9-Slices', 0, flow);

    // Animated Slices
    new AseAnim(Res.slices2.toAseprite().getSlices('Slice 1'), flow).loop = true;
    new AseAnim(Res.slices2.toAseprite().getSlices('Slice 2'), flow).loop = true;
    new AseAnim(Res.slices2.toAseprite().getSlices('Slice 3'), flow).loop = true;
    new AseAnim(Res.slices2.toAseprite().getSlices('Slice 4'), flow).loop = true;

    // Live Resource Updatng
    var animation = new AseAnim(Res.test.toAseprite().getTag('Idle'), flow);
    animation.loop = true;
    Res.test.watch(() -> {
      // Make sure to call the default `watch()` callback!
      Res.test.updateData();

      // Replay the animation to get the updated frames
      animation.play(Res.test.toAseprite().getTag('Idle'));
    });
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

    drawcalls.text = 'drawcalls: ${engine.drawCalls}';
    fps.text = 'fps: ${engine.fps}';

    drawcalls.setPosition(s2d.camera.x, s2d.camera.y);
    fps.setPosition(drawcalls.x, drawcalls.y + drawcalls.textHeight);
  }

  static function main() {
    new Main();
  }
}
