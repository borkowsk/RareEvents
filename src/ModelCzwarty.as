package  
{
	import flash.display.*;
	import flash.events.Event;
	import flash.geom.Matrix;
	import WBor.RGBColor;
	import WBor.Scenka;
	import WBor.Slupek;
	
	/**
	 * Model 3: "Lepiej mieć najlepsze miejsce (Abcd)"
	 * @author WBorkowski
	 */
	public class ModelCzwarty extends Scenka
	{
		//Rozmiary inicjalne muszą być zapamiętane bo width i height zmienia się przy zmianie skali
		public var IniWidth:Number = 0;
		public var IniHeight:Number = 0;
		
		private var Obszar:BitmapData;
		private var Wyswietlacz:Bitmap;
		
		public function ModelCzwarty(iwidth:Number,iheight:Number,ititle:String="Model #3 A w zmiennym środowisku") 
		{
			super(iwidth, iheight, ititle);
			IniWidth = iwidth;
			IniHeight = iheight;
			
			Initialise();
		}
		
		private var slupki:Array;
		private var limit:Number;
		
		private function PositionFree(pos:uint):Boolean
		{
			for (var i:uint = 0; i < slupki.length; i++)
				with ( Slupek(slupki[i]) )
				{
				  if (x == pos)
					return false;//Znalazła użycie tej wartości
				}
				
			return true;//Jak nie znalazła takiej wartości w użyciu	
		}
		
		
		private function cub(x:Number):Number
		{
			return x * x *x;
		}
		
		private function trans(x:Number):Number
		{
			return x * x * x * x * x;
		}
		
		private var Wspolczynniki:Array = [[2,5,11],[2,7,11],[3,5,11],[3,7,11],[5,7,13],[5,11,23],//Wybrane najlepsze
										   [3, 5, 7], [5, 7, 11], [7, 11, 13], [11, 13, 17],
										   [3, 7, 11], [5 , 11, 13], [7, 13, 17], [11, 17, 19],
										   [3, 7, 13], [5 , 11, 17], [7, 13, 19], [11, 17, 23]];
										   
		private var wspi:uint=Math.random() * 8;
		
		private function FillBackground(TimeOffset:Number,modul:uint=1,rest:uint=0):void
		{
			//trace(TimeOffset,wspi,': ',Wspolczynniki[wspi]);
			var pom:RGBColor = new RGBColor(0);
			pom.a = 255;
			
			for (var i:uint = 0; i < Obszar.height; i++)
			  if(i%modul==rest)//Mozna wybrać co którąś linię
				for (var j:uint = 0; j < Obszar.width; j++)
				{
					var y:Number = i / Number(Obszar.height);
					var x:Number = j / Number(Obszar.width);
					//pom.g = 100 + 100 * Math.sin(-x * Math.PI * Wspolczynniki[wspi][0]);
					//pom.g = 100 + 100 * Math.sin((x + y)/2 * Math.PI * Wspolczynniki[wspi][0]);
					pom.g = 128 + 127 * (Math.sin( (x - y) * Math.PI * Wspolczynniki[wspi][0] +TimeOffset*2*Math.PI ) );
					pom.b = 128 + 127 * cub(Math.sin( y * -x * Math.PI * Wspolczynniki[wspi][1] +TimeOffset*4*Math.PI ) );
					pom.r = 128 + 127 * trans(Math.sin( x * -y  * Math.PI * Wspolczynniki[wspi][2] -TimeOffset*2*Math.PI) );
					Obszar.setPixel(j,i,pom.toColor());
				}
		}
		
		private function MeanBackground(x:uint, y:uint, lx:uint, MeanColor:RGBColor):void
		{
			MeanColor.toRGB(0);
			var pom:RGBColor = new RGBColor(0);
			
			for (var i:uint = 0; i < lx; i++)
			{
				var pix:uint = Obszar.getPixel32(x + i, y);
				pom.toRGB(pix);
				MeanColor.r += pom.r;
				MeanColor.g += pom.g;
				MeanColor.b += pom.b;
			}
			
			//trace(pix,' ',MeanColor.r, '.', MeanColor.g, '.', MeanColor.b);
			MeanColor.r /= lx;
			MeanColor.g /= lx;
			MeanColor.b /= lx;			
		}
		
		private var Step:uint = 0;//Licznik kroków - potrzebny dla zmian tła
		
		private function Initialise():void
		//Inicjalizacja musi być tak zrobiona, żeby można było ją ponownie użyć, jak symulacja się zakończy!
		{
			Obszar = new BitmapData(IniWidth, IniHeight/2,true, 0xffffff);
			Obszar.fillRect(Obszar.rect, 0xFF000000);//		BitmapDataChannel.ALPHA
			FillBackground(0);//Start time
			Step = 0;
			Wyswietlacz = new Bitmap(Obszar);
			Wyswietlacz.x = 0;
			Wyswietlacz.y = IniHeight / 2;
			addChild(Wyswietlacz);
					
			const Rz:uint = 10; //w ilu rzędach
			const BegYpos:Number = IniHeight - IniHeight/2.5;//Najdalsze możliwe slupki
			const OdlegloscPionowa:Number = (IniHeight - 10 - BegYpos) / Rz;
			const SzerokoscSlupka:Number = 9;
			const KonieczneMiejsce:Number = SzerokoscSlupka + 5; //Żeby słupki nie były za blisko
			
			var Miejsc:Number = ((IniWidth - Rz*Slupek.vert_deph) / KonieczneMiejsce)-1;//Ile jest pozycji na słupki
			var xkrok:Number = (IniWidth - Rz*Slupek.vert_deph) / (Miejsc+1);//Ile miejsca na każdą pozycję
			trace(Rz, 'x', Miejsc);
			
			var Kolejny:Slupek; //Pomocnicza zmienna na kolejne slupki
			var KolejnyNumer:uint = 0;
			
			slupki = new Array();
			
			var PositKolor:RGBColor = new RGBColor(0);
			limit = BegYpos-3*Slupek.vert_deph;//Jak wysokość jakiegoś slupka dojdzie do limitu to zwijamy symulacje
		    
			for (var j:uint = 0; j < Rz; j++)
			{
				var PosY:uint = BegYpos + j * OdlegloscPionowa;
				var PosX:uint = 0;
				
				for (var i:uint = 0; i < Miejsc; i++)
				{
					PosX = (Rz-j) * Slupek.vert_deph + i * xkrok;
										
					MeanBackground(PosX,PosY-Wyswietlacz.y,SzerokoscSlupka,PositKolor);
					Kolejny = new Slupek(PosX, PosY, SzerokoscSlupka, 1, PositKolor.toColor());	
	
					slupki[KolejnyNumer] = Kolejny;
					
					KolejnyNumer++;
					addChild(Kolejny);
					Kolejny.visible = false;
				}
			}
			
			//Teraz trzeba wybrać tego pierwszego albo wszystkie startują razem
			
			var LosowyIndeks:uint = uint(Math.random() * slupki.length);//uint() obcina część ułamkową, a nie zaokragla
			Kolejny = Slupek(slupki[LosowyIndeks]);
			Kolejny.visible = true;
			
			Title.alpha = 1;
			addChild(Title);
			
			//Gotowe, można uruchamiać symulowanie
			addEventListener(Event.ENTER_FRAME, SimulationStep);
		}
		
		private function SimulationStep(e:Event):void
		//Wykonuje kroki symulacji tak dlugo jak się da, a potem podmienia na zakończenie (AfterLastStep)
		//Generalnie słupki rosną w tym samym tempie, ale te co wcześniej zaczęły przyrastają bardziej.
		{
			Step++;//Odliczenie numeru kroku
			//Co dzieisątą linię, więć calość raz na sekundę
			FillBackground(Step / (600*2),10,Step%10);//Pełny cykl trwa minutę * N
				
			Title.alpha *= 0.95;
			
			var PositKolor:RGBColor = new RGBColor(0);
			var Ten:Slupek;
			for (var i:uint = 0; i < slupki.length; i++)
				{
					Ten = Slupek(slupki[i]);
					if (Ten.visible)
					{
						MeanBackground(Ten.x, Ten.y - Wyswietlacz.y, Ten.BarWidth, PositKolor);
						Ten.BarColor = PositKolor.toColor();
						var eR:Number = (PositKolor.b/255.0)*0.3*(PositKolor.g/255.0)*0.45*(PositKolor.r/255.0)*0.3;//Nie więcej niż o 5% na klatkę
						//trace(eR);
						eR = 1 + eR - 0.005;//0.05% kosztów stałych
						Ten.BarHeight *= eR; //WZROST SŁUPKÓW: x:=r[i]*x
					
						if (Ten.BarHeight >= limit) 
						{							
							//Ten.BarColor = 0xffff00;
							Ten.BarHeight = limit;
						}
						else
						if (Ten.BarHeight < 0.5)
						{
							Ten.visible = false;//Umarł
						}
					}
					else
					{
						//Szansa na uwidocznienie, większa niż w Modelu 1, ale też nie może być za duża
						if (Math.random() < 0.003333)
							Ten.visible = true;
					}
				}
				
				if(Step>1800)
				{
					trace(Title.text, ' successed');
					removeEventListener(Event.ENTER_FRAME, SimulationStep);
					addEventListener(Event.ENTER_FRAME, AfterLastStep);//Nowy sposób zmian stanu klatki
				}
		}
		
		private function AfterLastStep(e:Event):void
		//Wizualne powolne sprzątanie po symulacji, aż będzie można uruchomić ponownie
		{
			
			for (var i:uint = 1; i < numChildren; i++) //Rozmywanie bardziej ogólne...
				getChildAt(i).alpha -= 0.05;//Przy dziesieciu klatkach na sekundę będzie to trwało 2 sek.
					
			if (getChildAt(1).alpha<=0)//Idą równo więc wystarczy sprawdzić zerowe dziecko
			{
				removeEventListener(Event.ENTER_FRAME, AfterLastStep);//Chwilowo nie ma czego robić w nowej klatce
				
				for (var j:int = numChildren - 1; j >= 0 ; j--)//I bardziej ogólne usuwanie...
				{
					removeChildAt(j); //Usuwa wszystko z listy wyświetlania scenki
				}
				
				slupki = null;//Starą z zawartością usuwa Garbage Collector, jak rozumiem
				Obszar.dispose();
				Initialise();//Ponownie wypełnia struktury danych i startuje nową symulację
			}
		}
	}
	
}