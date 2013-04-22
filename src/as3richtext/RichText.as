package as3richtext
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.engine.ContentElement;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.FontWeight;
	import flash.text.engine.GraphicElement;
	import flash.text.engine.GroupElement;
	import flash.text.engine.TextBaseline;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	import flash.text.engine.TextLineMirrorRegion;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;

	/**
	 * RichText
	 * @author KK Zhang
	 *
	 */
	[Event(name="link", type="flash.events.TextEvent")]
	public class RichText extends Sprite
	{
		protected static const OverrideStyleAttributes:Array = [ "@color", "@underline",
																 "@bold" ];

		/**
		 * 默认字体尺寸和颜色<br/>
		 * 在所有 RichText 实例中共享
		 */
		protected static var defaultFormat:ElementFormat = new ElementFormat(new FontDescription("微软雅黑"));
		// 设置文字对齐方式，IDEOGRAPHIC_BOTTOM 表示无论文字还是图片，都使用底对齐
		defaultFormat.dominantBaseline = TextBaseline.IDEOGRAPHIC_BOTTOM;
		defaultFormat.alignmentBaseline = TextBaseline.IDEOGRAPHIC_BOTTOM;

		protected var blocks:Vector.<TextBlock> = new Vector.<TextBlock>;

		protected var blockRenderers:Vector.<TextBlockRenderer> = new Vector.<TextBlockRenderer>;

		protected var linkDispatcher:EventDispatcher;

		public function RichText(width:int = 400, maxLines:uint = 100)
		{
			super();
			this.width = width;
			this.maxLines = maxLines;
			init();
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

		protected function init():void
		{
			content = <body spacing="5"></body>;
			// 给链接元素使用的侦听镜像
			linkDispatcher = new EventDispatcher();
			linkDispatcher.addEventListener(MouseEvent.MOUSE_OVER, link_mouseOverHandler);
			linkDispatcher.addEventListener(MouseEvent.MOUSE_OUT, link_mouseOutHandler);
			linkDispatcher.addEventListener(MouseEvent.MOUSE_MOVE, link_mouseMoveHandler);
			linkDispatcher.addEventListener(MouseEvent.MOUSE_DOWN, link_mouseDownHandler);
			linkDispatcher.addEventListener(MouseEvent.CLICK, link_clickHandler);
		}

		public function runTest():void
		{
			content = <body spacing="5">
					<p>单行文本</p>
					<p>可以使用使用<span underline="true"><![CDATA[<br/>]]></span><br/>手动换行</p>
					<p color="0xff0000" bold="true">除了<span bold="false" color="0x00ff00" underline="true">我是绿色带下划线不加粗</span>，整个段落都是红色加粗，并且自然换行；除了<span bold="false" color="0x00ff00" underline="true">我是绿色带下划线不加粗</span>，整个段落都是红色加粗，并且自然换行；除了<span bold="false" color="0x00ff00" underline="true">我是绿色带下划线不加粗</span>，整个段落都是红色加粗，并且自然换行；</p>
					<p>表情下方应有<span underline="true" color="0xff0000">红色下划线<emo id="1"/></span></p>
					<p><emo id="1"/>图<emo id="1"/>文<emo id="1"/>混<emo id="1"/>排</p>;
					<p><a href="http://www.google.com" underline="true" color="0x0000ff">谷歌<emo id="1"/></a></p>
					<p><a href="event:custom_data">测试自定义数据<br/>也可手动换行</a></p>
				</body>;
			var i:int = 0;
			var id:int = setInterval(function():void
			{
				i++;
				append(<p>测试追加{i}</p>);

				if (i >= 20)
				{
					clearInterval(id);
				}
			}, 100);
			// 测试 link 事件
			function onLink(event:TextEvent):void
			{
				trace("[RichText] runTest", event.text);
			}
			addEventListener(TextEvent.LINK, onLink);
		}

		protected function link_mouseMoveHandler(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.BUTTON;
		}

		protected function link_mouseDownHandler(event:MouseEvent):void
		{
		}

		protected function link_clickHandler(event:MouseEvent):void
		{
			var line:TextLine = event.currentTarget as TextLine;

			for each (var region:TextLineMirrorRegion in line.mirrorRegions)
			{
				if (region.bounds.contains(line.mouseX, line.mouseY))
				{
					Mouse.cursor = MouseCursor.BUTTON;
					const sign:String = "event:";

					if (region.element.userData.href.indexOf(sign) == 0)
					{
						const text:String = region.element.userData.href.substr(sign.length);
						dispatchEvent(new TextEvent(TextEvent.LINK, false, false, text));
					}
					else
					{
						navigateToURL(new URLRequest(region.element.userData.href), "_blank");
					}
					break;
				}
			}
		}

		protected function link_mouseOutHandler(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
		}

		protected function link_mouseOverHandler(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.BUTTON;
		}

		private var appendContentChanged:Boolean;

		/**
		 * 追加时的内容缓存在这里
		 */
		private var appendContent:XML;

		/**
		 * 追加一行。该方法不会导致全局刷新，性能较好
		 * @param content
		 *
		 */
		public function append(p:XML):void
		{
			if (!appendContent)
			{
				appendContent = <body></body>;
			}
			appendContent.appendChild(p);
			appendContentChanged = true;
			invalidate();
		}

		/**
		 * 合并 appendContent 到 content
		 *
		 */
		private function mergeAppendContent():void
		{
			if (appendContent)
			{
				_content.appendChild(appendContent.children());
				appendContent = null;
			}
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

		private var _maxLines:uint = uint.MAX_VALUE;

		/**
		 * 设置或获取最大行数，该值越大性能越差<br/>
		 * @return
		 *
		 */
		public function get maxLines():uint
		{
			return _maxLines;
		}

		public function set maxLines(value:uint):void
		{
			if (_maxLines != value)
			{
				_maxLines = value;
				invalidate();
			}
		}

		/**
		 * 要求渲染
		 *
		 */
		public function invalidate():void
		{
			addEventListener(Event.RENDER, onRender);

			if (stage)
			{
				stage.invalidate();
			}
		}

		/**
		 * 渲染
		 * @param event
		 *
		 */
		protected function onRender(event:Event):void
		{
			removeEventListener(Event.RENDER, onRender);
			var bodyToParse:XML;
			const appendOnly:Boolean = appendContentChanged && !contentChanged;

			// 从数据层上合并追加了的内容
			// 只进行了追加操作
			if (appendOnly)
			{
				appendContentChanged = false;
				bodyToParse = appendContent;
			}
			else
			{
				contentChanged = false;
				bodyToParse = _content;
				blocks.length = 0;
			}

			if (bodyToParse)
			{
				// 把每个 <p> 转换成 TextBlock
				var newBlocks:Vector.<TextBlock> = parseBody(bodyToParse, _content);
				blocks = blocks.concat(newBlocks);

				if (appendContent)
				{
					mergeAppendContent();
				}

				// 接下来删除多余的 blocks：先确认 blocks 的长度是否已超过 maxLines，如果已超过就丢弃
				while (blocks.length > _maxLines)
				{
					delete content..p[0]; // 不要忘记删掉老的 content
					blocks.shift();

					// 取出第一个并放到队列的最后，这样可以重复利用 TextBlockRenderer
					// 最多只会有 n 个 TextBlockRenderer，n = maxLines
					if (blockRenderers.length > 1)
					{
						var renderer:TextBlockRenderer = blockRenderers.shift();
						renderer.block = null;
						blockRenderers.push(renderer);
					}
				}

				// 如果新的 content 行数比原来的小，则要把多出来的 blockRenderer 也删掉
				while (blocks.length < blockRenderers.length)
				{
					removeChild(blockRenderers.pop());
				}
				// 一切准备就绪，让 TextBlockRenderer 进行渲染
				renderBlocks();
			}
		}

		/**
		 * 渲染 TextBlockRenderer，该方法主要做排列操作，具体的渲染流程在 TextBlockRenderer 内部
		 *
		 */
		protected function renderBlocks():void
		{
			var lastRenderer:TextBlockRenderer;
			var n:int = blocks.length; // 先记一个 n 效率会更高

			for (var i:int = 0; i < n; i++)
			{
				var renderer:TextBlockRenderer;

				// 决定创建或重复利用 TextBlockRenderer
				if (blockRenderers.length - 1 >= i)
				{
					renderer = blockRenderers[i];
				}
				else
				{
					renderer = new TextBlockRenderer(_width);
					addChild(renderer);
					blockRenderers.push(renderer);
				}
				// 告诉 TextBlockRenderer 要渲染的 TextBlock
				renderer.block = blocks[i];

				// 重新排列位置
				if (lastRenderer)
				{
					renderer.y = lastRenderer.height + lastRenderer.y;
				}
				else
				{
					renderer.y = 0;
				}
				// 记录最后一个渲染器，以便下一循环排列
				lastRenderer = renderer;
			}
		}

		/**
		 * 转换节点到 TextBlock
		 * @param node
		 * @param styles
		 * @return
		 *
		 */
		protected function parseBody(node:XML, styles:XML):Vector.<TextBlock>
		{
			var result:Vector.<TextBlock> = new Vector.<TextBlock>;

			for each (var child:XML in node..p)
			{
				var block:TextBlock = new TextBlock(parseParagraph(child, styles));

				if (styles.@spacing)
				{
					if (!block.userData)
					{
						block.userData = {};
					}
					block.userData.spacing = int(styles.@spacing);
				}
				result.push(block);
			}
			return result;
		}

		protected function parseSpan(node:XML, styles:XML):GroupElement
		{
			var elements:Vector.<ContentElement> = new Vector.<ContentElement>;

			for each (var child:XML in node.children())
			{
				if (child.nodeKind() == "text") // 文本
				{
					elements.push(parseText(child, node));
				}
				else
				{
					overrideStyles(child, node);
					// TODO 找个 hash 存一下对应的分析方法以便扩展
					var nodeName:String = child.name();
					// modified by no4matrix, 统一转小写
					nodeName = nodeName.toLowerCase();

					if (nodeName == "a") // 超链接
					{
						elements.push(parseAnchor(child, node));
					}
					else if (nodeName == "emo") // 表情
					{
						// 确定需求后加回去
						if (emotionCreator != null)
						{
							elements.push(parseEmotion(child, node));
						}
					}
					// modified by no4matrix, 支持font标签
					else if (nodeName == "span" || nodeName == "font") // span or font
					{
						elements.push(parseSpan(child, node));
					}
					else if (nodeName == "br") // 换行
					{
						elements.push(parseBreak(child, node));
					}
					else if (nodeName == "p")
					{
						throw new Error("不支持嵌套的 <p>");
					}
					else
					{
						throw new Error("不支持的 tag" + nodeName);
					}
				}
			}
			return new GroupElement(elements, defaultFormat)
		}

		/**
		 * 转换 P 到 GroupElement
		 * @param node
		 * @param styles
		 * @return
		 *
		 */
		protected function parseParagraph(node:XML, styles:XML):GroupElement
		{
			// 本质上 <p> 也是 <span> 的一种，利用一下 parseSpan 处理嵌套的元素
			var result:GroupElement = parseSpan(node, styles);

			// 设置行间距
			if (node.hasOwnProperty("@lineSpacing"))
			{
				if (!result.userData)
				{
					result.userData = {};
				}
				result.userData.lineSpacing = Number(node.@lineSpacing);
			}
			return result;
		}

		/**
		 * 处理换行
		 * @param child
		 * @param node
		 * @return
		 *
		 */
		protected function parseBreak(child:XML, node:XML):ContentElement
		{
			// \n 表示换行
			// 另外在 flash 中 \r 也算一个换行
			// 由于控制台的 \r 是返回行首
			// 这里我们用的是 \n
			return parseText(child.copy().appendChild("\n"), node);
		}

		/**
		 * 处理 <a> 到 GroupElement
		 * @param node
		 * @param styles
		 * @return
		 *
		 */
		protected function parseAnchor(node:XML, styles:XML):GroupElement
		{
			// 本质上 <a> 也是 <span> 的一种，利用一下 parseSpan 处理嵌套的元素
			var result:GroupElement = parseSpan(node, styles);

			// 然后添加链接相关的属性
			if (!result.userData)
			{
				result.userData = {};
			}
			result.userData.href = node.@href;
			// 把 linkDispatcher 作为当前节点的事件镜像，以便可以接收到鼠标事件
			result.eventMirror = linkDispatcher;
			return result;
		}

		/**
		 * 传递该方法来实现表情分析<br>
		 * 正确的签名应为<br>
		 * function emotionCreator (node:XML):DisplayObject
		 * {
		 * 	...
		 * }
		 */
		public var emotionCreator:Function;

		/**
		 * 转换表情节点到 GraphicElement
		 * @param node
		 * @param styles
		 * @return
		 *
		 */
		protected function parseEmotion(node:XML, styles:XML):GraphicElement
		{
			// 得到表情的 DisplayObject
			var emo:DisplayObject = emotionCreator(node);
			// 通常表情是不需要设置属性的，但是考虑到可能会被添加下划线，此时颜色和字体有作用了，所以还是要处理一下
			var newFormat:ElementFormat;

			if (styles.hasOwnProperty("@color") || styles.hasOwnProperty("@bold"))
			{
				newFormat = defaultFormat.clone();

				if (styles.hasOwnProperty("@color"))
				{
					newFormat.color = styles.@color;
				}

				if (styles.@bold == "true")
				{
					var description:FontDescription = newFormat.fontDescription.clone();
					description.fontWeight = FontWeight.BOLD;
					newFormat.fontDescription = description;
				}
			}
			else
			{
				newFormat = defaultFormat;
			}
			// 创建 GraphicElement 并设置下划线一些属性
			var result:GraphicElement = new GraphicElement(emo, emo.width, emo.height, newFormat);

			if (styles.hasOwnProperty("@underline"))
			{
				if (!result.userData)
				{
					result.userData = {};
				}
				result.userData.underline = styles.@underline == "true";
			}
			return result;
		}

		/**
		 * 转换 node 到 TextElement
		 * @param node
		 * @param styles
		 * @return
		 *
		 */
		protected function parseText(node:XML, styles:XML):TextElement
		{
			var newFormat:ElementFormat;

			if (styles.hasOwnProperty("@color") || styles.hasOwnProperty("@bold") || styles.hasOwnProperty("@lineSpacing"))
			{
				newFormat = defaultFormat.clone();

				if (styles.hasOwnProperty("@color"))
				{
					newFormat.color = styles.@color;
				}

				if (styles.@bold == "true")
				{
					var description:FontDescription = newFormat.fontDescription.clone();
					description.fontWeight = FontWeight.BOLD;
					newFormat.fontDescription = description;
				}
			}
			else
			{
				newFormat = defaultFormat;
			}
			var result:TextElement = new TextElement(node, newFormat);

			if (styles.hasOwnProperty("@underline"))
			{
				if (!result.userData)
				{
					result.userData = {};
				}
				result.userData.underline = styles.@underline == "true";
			}
			return result;
		}

		/**
		 * 覆盖样式
		 * @param node
		 * @param styles
		 *
		 */
		private function overrideStyles(node:XML, styles:XML):void
		{
			for each (var attr:String in OverrideStyleAttributes)
			{
				if (!node.hasOwnProperty(attr) && styles.hasOwnProperty(attr))
				{
					node[attr] = styles[attr]; // 如果当前节点没有并且父节点有该属性就覆盖
				}
			}
		}
	}
}
