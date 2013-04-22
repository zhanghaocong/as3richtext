package
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.TextEvent;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	import as3richtext.RichText;

	[SWF(width="400", height="600")]
	public class as3richtext extends Sprite
	{

		[Embed(source="/assets/emo1.jpg", mimeType="image/jpeg")]
		public static var emo1:Class;

		public function as3richtext()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			var richText:RichText = new RichText();
			richText.emotionCreator = function(node:XML):DisplayObject
			{
				return new emo1();
			}
			richText.addEventListener(TextEvent.LINK, richText_onLink);
			addChild(richText);
			richText.runTest();
		}

		protected function richText_onLink(event:TextEvent):void
		{
			trace(event.text);
		}

		public function test():void
		{
			var text:String = "中国智造，慧及全球 The quick brown fox jumps over a lazy dog";
			// 字体
			var font:FontDescription = new FontDescription("微软雅黑");
			// 格式
			var format:ElementFormat = new ElementFormat(font, 12);
			// 内容
			var element:TextElement = new TextElement(text, format);
			// 段落
			var block:TextBlock = new TextBlock(element);
			// 产生渲染行
			var line:TextLine = block.createTextLine();
			// 微调坐标
			line.y = line.totalAscent;
			addChild(line);
		}
	}
}
