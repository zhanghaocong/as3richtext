package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	import as3richtext.RichText;

	public class as3richtext extends Sprite
	{
		public function as3richtext()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			var rta:RichText = new RichText();
			rta.width = 400;
			addChild(rta);
			rta.runTest();
		}

		public function test():void
		{
			var format:ElementFormat = new ElementFormat(new FontDescription("微软雅黑"), 12);
			var content:TextElement = new TextElement("中国智造，慧及全球 The quick brown fox jumps over a lazy dog", format);
			var block:TextBlock = new TextBlock(content);
			var line:TextLine = block.createTextLine();
			line.y = line.totalAscent;
			addChild(line);
		}
	}
}
