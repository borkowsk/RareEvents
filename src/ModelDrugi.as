package  
{
	import flash.display.*;
	import flash.events.Event;
	import flash.geom.Matrix;
	import WBor.RGBColor;
	import WBor.Scenka;
	import WBor.Slupek;
	
	/**
	 * Model 2: "Kto ma lepsze miejsce ten lepszy"
	 * @author WBorkowski
	 */
	public class ModelDrugi extends Scenka
	{
		//Rozmiary inicjalne muszą być zapamiętane bo width i height zmienia się przy zmianie skali
		public var IniWidth:Number = 0;
		public var IniHeight:Number = 0;
		
		public function ModelDrugi(iwidth:Number,iheight:Number,ititle:String="Model #2") 
		{
			super(iwidth, iheight, ititle);
			IniWidth = iwidth;
			IniHeight = iheight;
			var matr:Matrix = new Matrix();//Transformation matrix - ale to cosik nie działa
			//matr.identity();
			//matr.rotate(Math.PI/8);
			var spreadMethod:String = SpreadMethod.REFLECT;
			graphics.beginGradientFill(GradientType.RADIAL, [0xffff00, 0x44dd00], [1, 1], [0, 255],null,spreadMethod);
			graphics.lineStyle(0, 0x0099ff);
			graphics.drawRect(0, (height / 3) * 2, width , (height / 3));
			graphics.endFill();
			slupki = new Array();
			eRy = new Array();
			Initialise();
		}
		
		private var slupki:Array;
		private var limit:Number;
		private var eRy:Array;
		
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
		
		private function Initialise():void
		//Inicjalizacja musi być tak zrobiona, żeby można było ją ponownie użyć, jak symulacja się zakończy!
		{
			const SzerokoscSlupka:Number = 10;
			const KonieczneMiejsce:Number = SzerokoscSlupka + 8; //Żeby słupki nie były za blisko
			const N:uint = 10; //ile realnie słupków
			var ypos:Number = IniHeight - IniHeight/7;
			var Miejsc:Number = (IniWidth - 20) / KonieczneMiejsce;//Ile jest pozycji na słupki
			var xkrok:Number = (IniWidth - 20) / Miejsc;//Ile miejsca na każdą pozycję
			var Kolejny:Slupek; //Pomocnicza zmienna na kolejne slupki
			limit = ypos-3*Slupek.vert_deph;//Jak wysokość jakiegoś slupka dojdzie do limitu to zwijamy symulacje
		
			for (var i:uint = 0; i < N; i++)
			{
				do{
				var RandPos:uint = 10+uint(Math.random() * Miejsc) * xkrok;//Czasem pozycja może być już w użyciu!
				}while (!PositionFree(RandPos));
		
				var eR:Number = Math.random()* Math.random() * 0.07;//Nie więcej niż o 7% na klatkę
				eRy[i] = 1 + eR;
				
				var Elipsa:Shape = new Shape();
				var PositKolor:RGBColor = new RGBColor(0);
				PositKolor.r = 155;// 255 - eR * 10 * 200;
				PositKolor.g = 255 - eR * 10 * 200;
				Elipsa.graphics.beginFill(PositKolor.toColor());
				Elipsa.graphics.lineStyle(1,PositKolor.toColor());
				Elipsa.graphics.drawEllipse(-xkrok/2,-xkrok/4,xkrok,xkrok/2);
				Elipsa.graphics.endFill();
				//Elipsa.graphics.lineStyle(1, 0xffffff);//Kontrolny środek elipsy
				//Elipsa.graphics.drawRect(0, 0, 1, 1);
				Elipsa.x = RandPos+Elipsa.width / 3;
				Elipsa.y = ypos - Elipsa.height / 4;// ?
				addChild(Elipsa);
								
				var RandKolor:RGBColor = new RGBColor(0);
				RandKolor.r = 100 + Math.random() * 100;
				RandKolor.g = 100 + Math.random() * 100;
				RandKolor.b = 100 + Math.random() * 100;
				Kolejny = new Slupek(RandPos, ypos, SzerokoscSlupka, 1, RandKolor.toColor());	
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
						BarHeight *= eRy[i]; //WZROST SŁUPKÓW: x:=r[i]*x
					
						if (BarHeight >= limit) //Jak pierwsza osiągnie limit to zwijamy
							bedzie_koniec = true;
					}
					else
					{
						//Szansa na uwidocznienie, większa niż w Modelu 1, ale też nie może być za duża
						if (Math.random() < 0.01)
							visible = true;
					}
				}
				
				if(bedzie_koniec)
				{
					trace(Title.text, ' successed');
					removeEventListener(Event.ENTER_FRAME, SimulationStep);
					addEventListener(Event.ENTER_FRAME, AfterLastStep);//Nowy sposób zmian stanu klatki
				}
		}
		
		private function AfterLastStep(e:Event):void
		//Wizualne powolne sprzątanie po symulacji, aż będzie można uruchomić ponownie
		{
			var bedzie_koniec:Boolean = false;
			
			for (var i:uint = 0; i < numChildren; i++) //Rozmywanie bardziej ogólne...
				with ( getChildAt(i) )
					{
						alpha -= 0.05;//Przy dziesieciu klatkach na sekundę będzie to trwało 2 sek.
						if (alpha <= 0)
							bedzie_koniec = true;
					}
					
			if (bedzie_koniec)
			{
				removeEventListener(Event.ENTER_FRAME, AfterLastStep);//Chwilowo nie ma czego robić w nowej klatce
				
				for (var j:int = numChildren - 1; j >= 0 ; j--)//I bardziej ogólne usuwanie...
				{
					removeChildAt(j); //Usuwa wszystko z listy wyświetlania scenki
				}
				
				slupki = new Array();//Tworzy nową pustą tablicę (starą z zawartością usuwa Garbage Collector, jak rozumiem) 
				Initialise();//Ponownie wypełnia ją danymi i startuje nową symulację
			}
		}
	}
	
}