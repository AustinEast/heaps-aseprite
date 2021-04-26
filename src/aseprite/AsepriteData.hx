package aseprite;

typedef AsepriteData = {
  frames:Array<Frame>,
  layers:Array<Layer>,
  tags:Map<String, Tag>,
  slices:Map<String, Slice>,
  palette:Palette,
  duration:Float,
  width:Int,
  height:Int,
  widthInTiles:Int,
  heightInTiles:Int
}
