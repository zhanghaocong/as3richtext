package as3richtext
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.engine.TextBlock;

	/**
	 * RichText
	 * @author KK Zhang
	 *
	 */
	public class RichText extends Sprite
	{
		/**
		 * 储存所有的 TextBlock
		 */
		protected var blocks:Vector.<TextBlock> = new Vector.<TextBlock>;

		/**
		 * 储存所有 TextBlockRenderer
		 */
		protected var blockRenderers:Vector.<TextBlockRenderer> = new Vector.<TextBlockRenderer>;

		public function RichText()
		{
			super();
		}

		private var contentChanged:Boolean;

		private var _content:XML;

		/**
		 * 设置或获取内容
		 * @return
		 *
		 */
		public function get content():XML
		{
			return _content;
		}

		public function set content(value:XML):void
		{
			contentChanged = true;
			_content = value;
			invalidate();
		}

		private var _width:int;

		/**
		 * 设置或获取文本框的宽度
		 * @return
		 *
		 */
		override public function get width():Number
		{
			return _width;
		}

		override public function set width(value:Number):void
		{
			_width = value;
		}

		/**
		 * 要求渲染
		 *
		 */
		public function invalidate():void
		{
			addEventListener(Event.RENDER, onRender);
			stage.invalidate();
		}

		/**
		 * 渲染
		 * @param event
		 *
		 */
		protected function onRender(event:Event):void
		{
			removeEventListener(Event.RENDER, onRender);

			if (contentChanged)
			{
				trace("[RichText] 渲染新内容");
			}
		}

		/**
		 * 测试
		 *
		 */
		public function runTest():void
		{
			content = <body spacing="5"><p>中国智造，慧及全球</p><p>The quick brown fox jumps over a lazy dog</p></body>;
		}

		/**
		* 转换 body 到 TextBlock
		* @param node
		* @param styles
		* @return
		*
		*/
		protected function parseBody(node:XML, styles:XML):Vector.<TextBlock>
		{
			var result:Vector.<TextBlock> = new Vector.<TextBlock>;
			return result;
		}
	}
}
