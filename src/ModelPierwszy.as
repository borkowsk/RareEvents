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
		
		public function ModelPierwszy(iwidth:Number,iheight:Number,ititle:String="Model #1 - const*A") 
		{
			super(iwidth, iheight, ititle);
			IniWidth = iwidth;
			IniHeight = iheight;
			graphics.beginFill(0x00CC00);
			graphics.lineStyle(0, 0x00CC00);
			graphics.drawRect(0, (height / 3) * 2, width , (height / 3));
			graphics.endFill();
			slupki = new Array();
			graphics.lineStyle(0, 0x00FF00);//DEBUG
			Initialise();
		}
		
		private var slupki:Array;
		private var limit:Number;
		
		private function PositionFree(posx:uint,posy:uint):Boolean
		{
			for (var i:uint = 0; i < slupki.length; i++)
				with ( Slupek(slupki[i]) )
				{
				  if (x == posx && y==posy)
				  {
					//trace('Ups...', pos);//DEBUG
					return false;//Znalazła użycie tej wartości
				  }
				}
				
			return true;//Jak nie znalazła takiej wartości w użyciu	
		}
		
		private var Szansa:Number = 0;//Szansa na uwidocznienie slupka w danym kroku, ale nie może być za duża
		
		private function Initialise():void
		//Inicjalizacja musi być tak zrobiona, żeby można było ją ponownie użyć, jak symulacja się zakończy!
		{
			const N:uint = 75; //ile słupków ma być
			const Rz:uint = 5; //w ilu rzędach
			const BegYpos:Number = IniHeight - IniHeight/5;//Najdalsze możliwe slupki
			const OdlegloscPionowa:Number = (IniHeight - 10 - BegYpos) / Rz;
			const SzerokoscSlupka:Number = 10;
			const KonieczneMiejsce:Number = SzerokoscSlupka + 3; //Żeby słupki nie były za blisko
			
			var Miejsc:Number = ((IniWidth - Rz*Slupek.vert_deph) / KonieczneMiejsce)-1;//Ile jest pozycji na słupki
			var xkrok:Number = (IniWidth - Rz*Slupek.vert_deph) / (Miejsc+1);//Ile miejsca na każdą pozycję
			var Kolejny:Slupek; //Pomocnicza zmienna na kolejne slupki
			var KolejnyNumer:uint = 0;
			
			limit = BegYpos-2*Slupek.vert_deph;//Jak wysokość jakiegoś slupka dojdzie do limitu to zwijamy symulacje
		    
			for (var j:uint = 0; j < Rz; j++)
			{
				var PosY:uint = BegYpos + j * OdlegloscPionowa;
				for (var i:uint = 0; i < N/Rz; i++)
				{
					do{
					var RandPosX:uint = (Rz-j)*Slupek.vert_deph+uint(Math.random() * Miejsc) * xkrok;//Czasem pozycja może być już w użyciu!
					//trace(RandPosX);graphics.drawRect(RandPosX,PosY-OdlegloscPionowa, xkrok, xkrok);//DEBUG
					}while (!PositionFree(RandPosX,PosY));
					//trace('OK');//DEBUG
				
					var Kolor:RGBColor = new RGBColor(0);
					Kolor.r = 100 + Math.random() * 100;
					Kolor.g = 0x00CC00;
					Kolejny = new Slupek(RandPosX, PosY, SzerokoscSlupka, 1, Kolor.toColor());	
					slupki[KolejnyNumer] = Kolejny;
					KolejnyNumer++;
					addChild(Kolejny);
					Kolejny.visible = false;
				}
			}
			
			//Teraz trzeba wybrać tego pierwszego albo wszystkie startują razem
			if (Math.random() < 0.8)
			{
				var LosowyIndeks:uint = uint(Math.random() * N);//uint() obcina część ułamkową, a nie zaokragla
				Kolejny = Slupek(slupki[LosowyIndeks]);
				Kolejny.visible = true;
				Kolejny.BarColor = 0xFFCC00;
			}
			else
			{
				for (j = 0; j < N; j++)
					Slupek(slupki[j]).visible = true;
			}
			
			
			Szansa = 0;
			
			Title.alpha = 1;
			addChild(Title);
			
			//Gotowe, można uruchamiać symulowanie
			ChangeOnEnterHandle(SimulationStep, -10);//addEventListener(Event.ENTER_FRAME, SimulationStep,false,-10);
		}
		
		private function SimulationStep(e:Event):void
		//Wykonuje kroki symulacji tak dlugo jak się da, a potem podmienia na zakończenie (AfterLastStep)
		//Generalnie słupki rosną w tym samym tempie, ale te co wcześniej zaczęły przyrastają bardziej.
		{
			var bedzie_koniec:Boolean = false;
			Title.alpha *= 0.95;
			
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
						
						if (Math.random() < Szansa)
							visible = true;
					}
				}
				
			Szansa += 0.00002;
			
				if(bedzie_koniec)
				{
					//trace(Title.text, ' successed');
					//removeEventListener(Event.ENTER_FRAME, SimulationStep);
					//addEventListener(Event.ENTER_FRAME, AfterLastStep);//Nowy sposób zmian stanu klatki
					ChangeOnEnterHandle(AfterLastStep);
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
				ChangeOnEnterHandle(null);// removeEventListener(Event.ENTER_FRAME, AfterLastStep);//Chwilowo nie ma czego robić w nowej klatce
				
				for (var j:uint = 0; j < slupki.length; j++)
					removeChild(Slupek(slupki[j])); //Usuwa slupki z listy wyświetlania scenki
					
				slupki = new Array();//Tworzy nową pustą tablicę (starą z zawartością usuwa Garbage Collector, jak rozumiem) 
				Initialise();//Ponownie wypełnia ją danymi i startuje nową symulację
			}
		}
	}
	
}