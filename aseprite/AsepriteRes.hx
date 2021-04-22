package aseprite;

import hxd.fs.FileEntry;
import hxd.res.Resource;

class AsepriteRes extends Resource {

  public function new(entry:FileEntry) {
    super(entry);
  }

  /** Create an Aseprite instance from this resource **/
  public inline function toAseprite() : Aseprite {
    return new Aseprite( entry.getBytes() );
  }
}
