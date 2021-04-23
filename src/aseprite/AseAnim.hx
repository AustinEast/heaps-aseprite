package aseprite;

import aseprite.Aseprite;
import h2d.Drawable;
import h2d.RenderContext;

class AseAnim extends Drawable {
  public var frames:Array<AsepriteFrame>;
  public var pause:Bool = false;
  public var loop:Bool = false;
  public var timeScale:Float = 1;
  public var currentFrame(get, set):Int;

  var curFrame:Int;

  var remainingDuration:Float;

  public function new(?frames:Array<AsepriteFrame>, ?parent:h2d.Object) {
    super(parent);
    this.frames = frames == null ? [] : frames;
    this.currentFrame = 0;
  }

  public function play(frames:Array<AsepriteFrame>, atFrame:Int = 0) {
    this.frames = frames == null ? [] : frames;
    currentFrame = atFrame;
    pause = false;
  }

  public dynamic function onAnimEnd() {}

  public function getFrame():AsepriteFrame {
    if (currentFrame == frames.length) currentFrame--;
    return frames[currentFrame];
  }

  override function getBoundsRec(relativeTo:h2d.Object, out:h2d.col.Bounds, forSize:Bool) {
    super.getBoundsRec(relativeTo, out, forSize);
    var frame = getFrame();
    if (frame != null) addBounds(relativeTo, out, frame.tile.dx, frame.tile.dy, frame.tile.width, frame.tile.height);
  }

  override function sync(ctx:RenderContext) {
    super.sync(ctx);
    var frame = getFrame();
    if (frame == null) return;
    var prev = curFrame;
    if (!pause) {
      remainingDuration -= timeScale * ctx.elapsedTime;
      if (remainingDuration <= 0) {
        curFrame++;
        var newFrame = frames[currentFrame];
        if (newFrame != null) remainingDuration = newFrame.duration / 1000;
      }
    }
    if (curFrame < frames.length && remainingDuration > 0) return;
    if (loop) {
      if (frames.length == 0) curFrame = 0;
      else curFrame %= frames.length;
      var newFrame = getFrame();
      remainingDuration = newFrame.duration / 1000;
      onAnimEnd();
    }
    else if (curFrame >= frames.length) {
      curFrame = frames.length;
      if (curFrame != prev) onAnimEnd();
    }
  }

  override function draw(ctx:RenderContext) {
    var frame = getFrame();
    if (frame != null) emitTile(ctx, frame.tile);
  }

  inline function get_currentFrame() {
    return curFrame;
  }

  function set_currentFrame(frame:Float) {
    curFrame = frames.length == 0 ? 0 : Math.floor(frame % frames.length);
    if (curFrame < 0) curFrame += frames.length;
    remainingDuration = frames.length == 0 ? 0 : frames[curFrame].duration / 1000;
    return curFrame;
  }
}
