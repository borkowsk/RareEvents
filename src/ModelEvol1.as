package  
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import WBor.RGBColor;
	import WBor.Scenka;
	import WBor.Slupek;
	
	/**
	 * Model ewolucji 1: "Im kolor bliższy białego tym lepszy"
	 * @author WBorkowski
	 */
	public class ModelEvol1 extends Scenka
	{
		//Rozmiary inicjalne muszą być zapamiętane bo width i height zmienia się przy zmianie skali
		public var IniWidth:Number = 0;
		public var IniHeight:Number = 0;
		
		public function ModelEvol1(iwidth:Number,iheight:Number,ititle:String="Model ewolucji #1") 
		{
			super(iwidth, iheight, ititle);
			IniWidth = iwidth;
			IniHeight = iheight;
			//...
			Initialise();
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOverMy);
		}
		
		protected function onMouseOverMy(e:MouseEvent):void
		{
			Title.textColor = Math.random() * 0xffffff;
			super.onMouseOver(e);
		}
		
		private var Obszar:BitmapData;
		private var Wyswietlacz:Bitmap;
		
		private function Initialise():void
		//Inicjalizacja musi być tak zrobiona, żeby można było ją ponownie użyć, jak symulacja się zakończy!
		{
			Obszar = new BitmapData(IniWidth/2, IniHeight/2,true, 0xffffff);
			//Obszar.noise(5);
			Obszar.fillRect(Obszar.rect, 0x00000000);//		BitmapDataChannel.ALPHA
			Obszar.setPixel32(Obszar.width / 2, Obszar.height / 2, 0xff000100);
			Wyswietlacz = new Bitmap(Obszar);
			Wyswietlacz.scaleX = 2;
			Wyswietlacz.scaleY = 2;
			Wyswietlacz.x = 0;
			Wyswietlacz.y = 0;// IniHeight / 3;
			//Wyswietlacz.height = (IniHeight / 3) * 2;
			addChild(Wyswietlacz);
			
			Title.alpha = 1;
			addChild(Title);
			
			//Gotowe, można uruchamiać symulowanie
			addEventListener(Event.ENTER_FRAME, SimulationStep);
		}
		
		private var Moves:Array = [[1,  1], [0,  1], [ -1,  1],
								   [1, -1], [0, -1], [ -1, -1],
								   [ -1, 0], [1,  0], [ 0, 0]];//Ostatni dla bezpieczenstwa
								   
		private static function MozeMutuj(parent:uint):uint
		{
			var gens:uint = parent;//Geny do ewentualnego zmutowania
			var poz:uint = Math.random() * 240*1000;//Nie częściej niż co dziesiąty możę mutować. Albo lepiej rzadziej
			if (poz > 23) //Nie ma mutacji. Kanal alpha jest chroniony (mam nadzieję)
			{
				return gens;
			}
			else //Niestety jest, trzeba pokombinować :-)
			{
				var mask:uint = 0x00000001 << poz;
				gens ^= mask; //Do magic :-))))
				//trace(parent,' ', gens);
				//if ((gens & 0xff000000) != 0xff000000) trace('Bląd algorytmu - mutacja kanału alpha');
				return gens;
			}
		}
		
		private static var Bits:Array = FillBitNumber();
		
		private static function FillBitNumber():Array
		{
			var Bits:Array = new Array();
			
			for (var i:uint = 0; i < 256; i++)
			{
				var b:uint = i;
				var licz:uint = 0;
				for (var j:uint = 0; j < 8; j++)
				{
					if (b & 0x1) licz++;//Dolicz jesli ostatni bit jest jedynką
					b >>= 1;//Przesuń bity
				}
				Bits[i] = licz;
				//trace(i, ' -> ', licz);
			}
			
			return Bits;
		}
		
		private static var firstRGB:RGBColor = new RGBColor(0);
		private static var seconRGB:RGBColor = new RGBColor(0);
		
		private static function Lepsze(f:uint, s:uint):int
		{
			firstRGB.toRGB(f);
			seconRGB.toRGB(s);
			var ilewF:int = Bits[firstRGB.r] + Bits[firstRGB.g] + Bits[firstRGB.b];
			var ilewS:int = Bits[seconRGB.r] + Bits[seconRGB.g] + Bits[seconRGB.b];
			//trace(ilewF, ilewS);
			return  ilewF-ilewS;//Jak pierwszy ma więcej jedynek to wynik dodatni, jak drugi to ujemny
		}
		
		private function SimulationStep(e:Event):void
		//Wykonuje kroki symulacji tak dlugo jak się da, a potem podmienia na zakończenie (AfterLastStep)
		//Populacje ewoluują w kierunku białego, a potem od nowa.
		{
			Title.alpha *= 0.95;
			
			var ile_bialych:uint = 0;
			var FullSize:uint = Obszar.width * Obszar.height; 
			var MC:uint = (Obszar.width * Obszar.height) / 5;//20% obszaru probkowania na klatkę
			
			for (var i:uint = 0; i < MC; i++) //Głowna pętla symulacji
			{
				var pos:uint = Math.random() * FullSize;
				var x:uint = pos % Obszar.width;
				var y:uint = pos / Obszar.width;
				var dir:uint = Math.random()*7.99999;
				var vx:int = Moves[dir][0];
				var vy:int = Moves[dir][1];
				var nx:int = (Obszar.width + x + vx) % Obszar.width;
				var ny:int = (Obszar.height + y + vy) % Obszar.height;
				var first:uint=Obszar.getPixel32(x, y);
				var second:uint = Obszar.getPixel32(nx, ny);
				var first_a:uint = first & 0xff000000; //Extract alpha channel
				var second_a:uint = second & 0xff000000; //Extract alpha channel
				
				
				if(first_a!=0 && (first-first_a)==0x00ffffff) //Próbkowanie na populację zdominowaną przez białe
						ile_bialych++;
						
				if (first_a == 0 && second_a ==0)//Oba puste - nie rób nic
				{
					continue; 
				}
				else 
				if (first_a != 0 && second_a == 0)//Pelny na pusty - przemieść lub rozmnóz
				{
					Obszar.setPixel32(nx, ny, first);//Zywy na nowe miejsce
					if (Math.random() < 0.75) //Jak jest wolne miejsce to trzeba korzystać!
						Obszar.setPixel32(x, y, MozeMutuj(first))//Rozmnazanie
					else
						Obszar.setPixel32(x, y, second);//Zamiana
				}
				else 
				if (first_a == 0 && second_a != 0)//Pusty na pełny - przemieść lub rozmnóz
				{
					Obszar.setPixel32(x, y, second);//Zywy na nowe miejsce
					if (Math.random() < 0.75)  //Jak jest wolne miejsce to trzeba korzystać!
						Obszar.setPixel32(nx, ny, MozeMutuj(second))//Rozmnazanie
					else
						Obszar.setPixel32(nx, ny, first);//Zamiana
				}
				else //Oba pełne - mogłyby walczyć
				{
					//Lepsze są te bliższe białego
					//////////////////////////////
	
					//Z OSTRĄ SELEKCJĄ DUŻO SZYBCIEJ
					if (first == second) //Jak równe to interakcja wewnątrzgatunkowa - musi być szansa na rozmnażanie w srodku
					{
						Obszar.setPixel32(nx, ny, MozeMutuj(second));//Niby miłość, choć potomek kosztem jednego z rodziców
					}
					else //Nierówne - walka
					{
						var FvS:int = Lepsze(first, second);
						if (FvS>0)
							Obszar.setPixel32(nx, ny, 0x00000000);
							else
							if (FvS<0)
								Obszar.setPixel32(x, y, 0x00000000);
								else
								{
									//Równowazne - nie rób nic
								}
					}		
				}
			}
			
			//if (ile_bialych > 0) trace(ile_bialych, '/', MC);//Gdy białe zaczynają ostatnia walkę o panowanie
			
			if(ile_bialych>MC*0.75)//Jak białych jest więcej niż 75% 
			{
				trace(Title.text, ' successed');
				removeEventListener(Event.ENTER_FRAME, SimulationStep);
				addEventListener(Event.ENTER_FRAME, AfterLastStep);//Nowy sposób zmian stanu klatki
			}
		}
		
		private function AfterLastStep(e:Event):void
		//Wizualne powolne sprzątanie po symulacji, aż będzie można uruchomić ponownie
		{	
			Wyswietlacz.alpha -= 0.02;
					
			if (Wyswietlacz.alpha<=0)
			{
				removeEventListener(Event.ENTER_FRAME, AfterLastStep);//Chwilowo nie ma czego robić w nowej klatce
		
				for (var j:int = numChildren - 1; j >= 0 ; j--)//I bardziej ogólne usuwanie...
				{
					removeChildAt(j); //Usuwa wszystko z listy wyświetlania scenki
				}
				
				Obszar.dispose(); //Niby wymuszenie zwalniania
				Obszar = null;
				Wyswietlacz = null;
				
				Initialise();//Ponownie przygotowuje dane i startuje nową symulację
			}
		}
	}
	
}