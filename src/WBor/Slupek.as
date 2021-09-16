package WBor
{
	import flash.display.Shape;
	
	/**
	 * Klasa trójwymiarowego słupka o zadanej wysokości i frontowej szerokości.
	 * "Prymityw graficzny" - rozszerza prostszą klasę Shape a nie złożoną: Sprite
	 * Głębokość boczna i górna są wspólne dla wszystkich obiektów klasy Slupek
	 * @author WBorkowski
	 */
	public class Slupek extends Shape
	{
		public static var vert_deph:Number = 4;
		public static var hori_deph:Number = 3;
		
		private var iwidth:Number;
		private var iheight:Number;
		private var color:uint;
		
		public function get BarColor():uint		
		{
			return color;
		}
		
		public function set BarColor(setValue:uint):void
		{
			color = setValue;
			ReDraw();
			//stage
		}
		
		public function get BarWidth():Number
		{
			return iwidth;
		}
		
		public function set BarWidth(setValue:Number):void
		{
			iwidth = setValue;
			ReDraw();
			//stage
		}
		
		public function get BarHeight():Number
		{
			return iheight;
		}
		
		public function set BarHeight(setValue:Number):void
		{
			iheight = setValue;
			ReDraw();
			//stage
		}
		
		//Rysuje słupek zaczynając od punktu x,y na samym dole
		public function Slupek(x:Number, y:Number, pwidth:Number, pheight:Number,pcolor:uint):void 
		{
			this.x = x;
			this.y = y;
			this.iwidth = pwidth;
			this.iheight = pheight;
			this.color = pcolor;	
			ReDraw();
			//graphics.drawCircle(0, 0, 5);//DEBUG
		}
		
		public function ReDraw():void
		{
			graphics.clear();//Usuwamy stary wygląd jak jest
			//Slupek umieszczony jest w obrębie własnego obszaru i wlasnych współrzędnych
			//stąd x i y zoatały zamienione na zera (0)
			var pom:RGBColor = new RGBColor(color);
			graphics.beginFill(color);
			graphics.drawRect(0, 0 - iheight, iwidth, iheight);
			graphics.endFill();
			pom.r /= 2;
			pom.g /= 2;
			pom.b /= 2;
			graphics.moveTo(0 + iwidth, 0 - iheight);
			//graphics.lineStyle(1, 0);
			graphics.beginFill(pom.toColor());
			graphics.lineTo(0 + iwidth + hori_deph, 0 - iheight - vert_deph);
			graphics.lineTo(0 + iwidth + hori_deph, 0 - vert_deph);
			graphics.lineTo(0 + iwidth , 0 );
			graphics.endFill();
			pom.r *= 3;
			pom.g *= 3;
			pom.b *= 3;
			graphics.moveTo(0 , 0 - iheight);
			graphics.lineStyle(0, 0xffffff);
			graphics.beginFill(pom.toColor());
			graphics.lineTo(0 + hori_deph, 0 - iheight - vert_deph);
			graphics.lineTo(0 + hori_deph + iwidth, 0 - iheight - vert_deph);
			graphics.lineTo(0 + iwidth, 0 - iheight);
			graphics.endFill();
		}
	}
}
