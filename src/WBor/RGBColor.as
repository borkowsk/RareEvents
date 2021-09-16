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
		public var r:uint, g:uint, b:uint;
		public 	function RGBColor(color:uint):void
		{
			r = (color & 0xff0000)>>16;
			g = (color & 0x00ff00)>>8;
			b = (color & 0x0000ff);
		//	trace(color, ' ', r, ' ', g, ' ', b);
		}
	
		public function toUint():uint
		{
			var pom:uint;
			if (r > 255) r = 255;
			if (g > 255) g = 255;
			if (b > 255) b = 255;
			pom = (r << 16) + (g << 8) + b;
			return pom;
		}
	}
}