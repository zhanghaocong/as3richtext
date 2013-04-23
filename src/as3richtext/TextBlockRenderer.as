package as3richtext
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.engine.ContentElement;
	import flash.text.engine.FontMetrics;
	import flash.text.engine.GroupElement;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextLine;
	import flash.text.engine.TextLineValidity;

	/**
	 * 单个 TextBlock 的渲染器，也可以称作段落渲染器
	 * @author KK
	 *
	 */
	public class TextBlockRenderer extends Sprite
	{
		/**
		 * 默认的行间距
		 */
		private static const DefaultLineSpacing:int = 1;

		private var _block:TextBlock;

		public function get block():TextBlock
		{
			return _block;
		}

		public function set block(value:TextBlock):void
		{
			if (value != _block)
			{
				if (_block && numChildren > 0)
				{
					_block.releaseLines(block.firstLine, getChildAt(numChildren - 1) as TextLine);
				}
				_block = value;
				renderLines();
			}
		}

		private var _width:int;

		/**
		 * 创建一个新的 TextBlockRenderer
		 * @param width 段落的宽度
		 *
		 */
		public function TextBlockRenderer(width:int)
		{
			super();
			_width = width;
		}

		protected function renderLines():void
		{
			removeOrphanedLines();
			textWidth = 0;

			if (_block)
			{
				var lastLine:TextLine;
				var line:TextLine;
				// 确定行间距
				var lineSpacing:Number = DefaultLineSpacing;

				// 循环创建行，这里利用到了缓存，详见 createLine
				while (line = createLine(lastLine))
				{
					var rect:Rectangle = line.getRect(line);

					if (lastLine)
					{
						line.y = lastLine.getRect(this).y + lastLine.height - rect.y + lineSpacing;
					}
					else
					{
						line.y = -rect.y;
					}

					if (_width == 0)
					{
						if (textWidth < line.width)
						{
							textWidth = line.width
						}
					}
					addChild(line);
					lastLine = line;
				}

				// 根据最后一行的尺寸决定当前段落的高度
				if (lastLine)
				{
					_height = lastLine.getRect(this).bottom + lineSpacing;
				}
				// 绘制下划线
				lineIndex = 0;
				drawUnderline(block.content);
				// 因为渲染器是只读的，这里可以直接释放资源
				block.releaseLineCreationData();
			}
		}

		private function removeOrphanedLines():void
		{
			while (numChildren)
			{
				var line:TextLine = removeChildAt(0) as TextLine;
				line.removeChildren();

				if (contains(line))
				{
					removeChild(line);
				}

				if (line.validity === TextLineValidity.VALID)
				{
					continue;
				}
				orphans.push(line);
			}
		}

		/**
		 * 从缓存中取 TextLine，如果没有就新建
		 * @param previousLine
		 * @return
		 *
		 */
		private function createLine(previousLine:TextLine = null):TextLine
		{
			// 从缓存中提取已被回收的 TextLine
			var o:TextLine = getOrphan(previousLine);

			if (o)
			{
				return block.recreateTextLine(o, previousLine, _width > 0 ? _width : 1000000);
			}
			else
			{
				return block.createTextLine(previousLine, _width > 0 ? _width : 1000000);
			}
		}

		/**
		 * 为指定的 TextLine 装饰下划线
		 * @param line 指定的 TextLine
		 * @param element 指定的元素
		 *
		 */
		private function drawUnderline(element:ContentElement):void
		{
			if (element is GroupElement)
			{
				//trace("[group] lineIndex", lineIndex);
				// 遍历组里子元素，递归的调用 drawUnderline
				var g:GroupElement = element as GroupElement;

				for (var i:int = 0; i < g.elementCount; i++)
				{
					drawUnderline(g.getElementAt(i));
				}
			}
			else
			{
				// 遍历所有的行
				while (lineIndex < numChildren)
				{
					// trace("[check] lineIndex", lineIndex);
					var line:TextLine = getChildAt(lineIndex) as TextLine;
					var begin:int = line.getAtomIndexAtCharIndex(element.textBlockBeginIndex);
					var end:int = line.getAtomIndexAtCharIndex(element.textBlockBeginIndex + element.rawText.length - 1);
					var isContinue:Boolean = false;
					var isDraw:Boolean = element.userData && element.userData.underline;

					// trace(element.text, element.textBlockBeginIndex + ":" + begin, element.textBlockBeginIndex + element.rawText.length - 1 + ":" + end, line.atomCount, isDraw);
					// 确定开始位置：如果 begin 为 -1，表示当前 TextLine 正在渲染 element 的第 n+1 部分，可以取 0
					// n+1 是指上一个 TextLine 渲染剩余的部分
					if (begin == -1)
					{
						begin = 0;
					}

					// 确定结束位置：如果 end 为 -1，表示当前 TextLine 无法渲染 element 的全部字符（或图片），可以取 line.atomCount-1
					if (end == -1)
					{
						end = line.atomCount - 1;
						isContinue = true; // 跨行元素，需要确认后一行的状况
					}

					if (end == line.atomCount - 1)
					{
						// 当前元素跨行了
						lineIndex++;
					}

					// 使用 getAtomBounds 得到 begin 和 end 两处的矩形，然后合并得到线的长度
					// 此处扩展一下可以绘制诸如 backgroundColor 这样的属性
					if (isDraw)
					{
						// 获得 FontMetrics，这里记录了下划线应该画在什么位置
						var fontMetrics:FontMetrics = element.elementFormat.getFontMetrics();
						var rect:Rectangle = line.getAtomBounds(begin).union(line.getAtomBounds(end));
						line.addChild(createUnderline(rect.x, fontMetrics.underlineOffset, rect.width, fontMetrics.underlineThickness, element.elementFormat.color));
					}
					// 调试用
					function drawDebug():void
					{
						var bgColor:uint = isDraw ? 0x0000ff : 0x666666;
						var fontColor:uint = isDraw ? 0xffff00 : 0xff00ff;
						var fontMetrics:FontMetrics = element.elementFormat.getFontMetrics();
						var rect:Rectangle = line.getAtomBounds(begin).union(line.getAtomBounds(end));
						var result:Shape = new Shape();
						result.graphics.beginFill(bgColor, 0.5);
						result.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
						line.addChild(result);
						var tf:TextField = new TextField();
						tf.addEventListener(MouseEvent.CLICK, function(e:Event):void
						{
							e.currentTarget.visible = !e.currentTarget.visible;
						});
						tf.filters = [ new GlowFilter(0, 1, 2, 2, 10)];
						tf.x = rect.x;
						tf.y = rect.y;
						tf.autoSize = TextFieldAutoSize.LEFT;
						tf.selectable = false;
						tf.defaultTextFormat = new TextFormat("宋体", "12", fontColor);
						line.addChild(tf);
						tf.text = "[" + line.getAtomIndexAtCharIndex(element.textBlockBeginIndex) + ":" + line.getAtomIndexAtCharIndex(element.textBlockBeginIndex + element.rawText.length - 1) + "]";
					}

					if (true)
					{
						drawDebug();
					}

					if (!isContinue)
					{
						return;
					}
				}
			}
		}

		public override function get width():Number
		{
			return _width > 0 ? _width : textWidth;
		}

		private var _height:Number;

		public override function get height():Number
		{
			return _height;
		}

		private var textWidth:Number;

		private static function createUnderline(x:Number, y:Number, width:Number, thickness:Number, color:uint):Shape
		{
			trace(x, y, width, thickness, color.toString(16));
			var result:Shape = new Shape();
			result.graphics.lineStyle(thickness, color);
			result.graphics.moveTo(x, y);
			result.graphics.lineTo(x + width, y);
			return result;
		}

		private static const orphans:Vector.<TextLine> = new Vector.<TextLine>();

		private var lineIndex:int;

		private var debugIndent:int;

		private static function getOrphan(exclude:TextLine):TextLine
		{
			if (orphans.length == 0)
			{
				return null;
			}
			var orphan:TextLine = orphans.pop();

			while (orphan == exclude)
			{
				orphan = orphans.pop();
			}

			while (orphan && orphan.validity == TextLineValidity.VALID)
			{
				orphan = orphans.pop();
			}
			return orphan;
		}
	}
}
