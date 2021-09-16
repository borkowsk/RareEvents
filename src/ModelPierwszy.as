package  
{
	import flash.events.Event;
	import WBor.RGBColor;
	import WBor.Scenka;
	import WBor.Slupek;
	
	/**
	 * Model 1: "Kto pierwszy ten lepszy"
	 * @author WBorkowski
	 */
	public class ModelPierwszy extends Scenka
	{
		//Rozmiary inicjalne muszą być zapamiętane bo width i height zmienia się przy zmianie skali
		public var IniWidth:Number = 0;
		public var IniHeight:Number = 0;
		
		public function ModelPierwszy(iwidth:Number,iheight:Number,ititle:String="Model #1") 
		{
			super(iwidth, iheight, ititle);
			IniWidth = iwidth;
			IniHeight = iheight;
			graphics.beginFill(0x22CC00);
			graphics.lineStyle(0, 0x22CC00);
			graphics.drawRect(0, (height / 3) * 2, width , (height / 3));
			graphics.endFill();
			slupki = new Array();
			graphics.lineStyle(0, 0x00FF00);//DEBUG
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
				  {
					//trace('Ups...', pos);//DEBUG
					return false;//Znalazła użycie tej wartości
				  }
				}
				
			return true;//Jak nie znalazła takiej wartości w użyciu	
		}
		
		private function Initialise():void
		//Inicjalizacja musi być tak zrobiona, żeby można było ją ponownie użyć, jak symulacja się zakończy!
		{
			const SzerokoscSlupka:Number = 10;
			const KonieczneMiejsce:Number = SzerokoscSlupka + 4; //Żeby słupki nie były za blisko
			const N:uint = 10; //ile realnie słupków
			var ypos:Number = IniHeight - IniHeight/7;
			var Miejsc:Number = (IniWidth - 20) / KonieczneMiejsce;//Ile jest pozycji na słupki
			var xkrok:Number = (IniWidth - 20) / Miejsc;//Ile miejsca na każdą pozycję
			var Kolejny:Slupek; //Pomocnicza zmienna na kolejne slupki
			limit = ypos-2*Slupek.vert_deph;//Jak wysokość jakiegoś slupka dojdzie do limitu to zwijamy symulacje
		
			for (var i:uint = 0; i < N; i++)
			{
				do{
				var RandPos:uint = 10+uint(Math.random() * Miejsc) * xkrok;//Czasem pozycja może być już w użyciu!
				//trace(RandPos);graphics.drawRect(RandPos, ypos-xkrok, xkrok, xkrok);//DEBUG
				}while (!PositionFree(RandPos));
				//trace('OK');//DEBUG
				
				var RandKolor:RGBColor = new RGBColor(0);
				RandKolor.r = 100 + Math.random() * 100;
				RandKolor.g = 100 + Math.random() * 100;
				Kolejny = new Slupek(RandPos, ypos, SzerokoscSlupka, 1, RandKolor.toUint());	
				slupki[i] = Kolejny;
				addChild(Kolejny);
				Kolejny.visible = false;
			}
			
			//Teraz trzeba wybrać tego pierwszego
			var LosowyIndeks:uint = uint(Math.random() * N);//Mam nadzieję że to obcina częśc ułamkową, a nie zaokragla
			Kolejny = Slupek(slupki[LosowyIndeks]);
			Kolejny.visible = true;
			
			//Gotowe, można uruchamiać symulowanie
			addEventListener(Event.ENTER_FRAME, SimulationStep);
		}
		
		private function SimulationStep(e:Event):void
		//Wykonuje kroki symulacji tak dlugo jak się da, a potem podmienia na zakończenie (AfterLastStep)
		//Generalnie słupki rosną w tym samym tempie, ale te co wcześniej zaczęły przyrastają bardziej.
		{
			var bedzie_koniec:Boolean = false;
			
			for (var i:uint = 0; i < slupki.length; i++)
				with( Slupek(slupki[i]) )
				{
					if (visible)
					{
						BarHeight *= 1.03; //WZROST SŁUPKÓW: x:=r*x
					
						if (BarHeight >= limit) //Jak pierwsza osiągnie limit to zwijamy
							bedzie_koniec = true;
					}
					else
					{
						//Szansa na uwidocznienie, ale nie może być za duża
						if (Math.random() < 0.004)
							visible = true;
					}
				}
				
				if(bedzie_koniec)
				{
					removeEventListener(Event.ENTER_FRAME, SimulationStep);
					addEventListener(Event.ENTER_FRAME, AfterLastStep);//Nowy sposób zmian stanu klatki
				}
		}
		
		private function AfterLastStep(e:Event):void
		//Wizualne powolne sprzątanie po symulacji, aż będzie można uruchomić ponownie
		{
			var bedzie_koniec:Boolean = false;
			
			for (var i:uint = 0; i < slupki.length; i++)
				with ( Slupek(slupki[i]) )
					if(visible) //Ma sens tylko dla uwidocznionych
					{
						alpha -= 0.05;//Przy dziesieciu klatkach na sekundę będzie to trwało 2 sek.
						if (alpha <= 0)
							bedzie_koniec = true;
					}
					
			if (bedzie_koniec)
			{
				removeEventListener(Event.ENTER_FRAME, AfterLastStep);//Chwilowo nie ma czego robić w nowej klatce
				for (var j:uint = 0; j < slupki.length; j++)
					removeChild(Slupek(slupki[j])); //Usuwa slupki z listy wyświetlania scenki
					
				slupki = new Array();//Tworzy nową pustą tablicę (starą z zawartością usuwa Garbage Collector, jak rozumiem) 
				Initialise();//Ponownie wypełnia ją danymi i startuje nową symulację
			}
		}
	}
	
}