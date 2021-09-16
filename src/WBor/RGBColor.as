package WBor 
{
	/**
	 * RGBColor to prosta klasa pomocnicza służąca rozbijaniu koloru RGB na składowe,
	 * udostępniąjąca je do manipulacji, a potem składająca kolor z powrotem.
	 * Nie mogłem znaleźć w dokumentacji czegoś takiego więc zrobiłem
	 * @author WBorkowski
	 */
	public final class RGBColor 
	{
		public var a:uint, r:uint, g:uint, b:uint;
		
		public 	function RGBColor(color:uint):void
		{
			toRGB(color);
		//	trace(color, ' ', r, ' ', g, ' ', b);
		}
	
		public function toRGB(color:uint):void
		{
			a = (color & 0xff000000)>>24; //Alpha
			r = (color & 0x00ff0000)>>16; //Red
			g = (color & 0x0000ff00)>>8;  //Green
			b = (color & 0x000000ff);	  //Blue
		}
		
		public function toColor():uint //RGB without alpha channel
		{
			var pom:uint = 0;
			if (r > 255) r = 255;
			if (g > 255) g = 255;
			if (b > 255) b = 255;
			pom = (r << 16) + (g << 8) + b;
			return pom;
		}
		
		public function toColor32():uint //RGB with alpha channel
		{
			var pom:uint;
			if (a > 255) a = 255;
			if (r > 255) r = 255;
			if (g > 255) g = 255;
			if (b > 255) b = 255;
			pom = (a<<24) + (r << 16) + (g << 8) + b;
			return pom;
		}
	}
}