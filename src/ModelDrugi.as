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
		
		public function ModelDrugi(iwidth:Number,iheight:Number,ititle:String="Model #2 - AB") 
		{
			super(iwidth, iheight, ititle);
			IniWidth = iwidth;
			IniHeight = iheight;
			var matr:Matrix = new Matrix();//Transformation matrix - ale to cosik nie działa
			//matr.identity();
			//matr.rotate(Math.PI/8);
			var spreadMethod:String = SpreadMethod.REFLECT;
			graphics.beginGradientFill(GradientType.RADIAL, [0xffff00, 0x444400], [1, 1], [0, 255],null,spreadMethod);
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
			const N:uint = 75; //ile słupków ma być
			const Rz:uint = 5; //w ilu rzędach
			const BegYpos:Number = IniHeight - IniHeight/5;//Najdalsze możliwe slupki
			const OdlegloscPionowa:Number = (IniHeight - 10 - BegYpos) / Rz;
			const SzerokoscSlupka:Number = 9;
			const KonieczneMiejsce:Number = SzerokoscSlupka + 5; //Żeby słupki nie były za blisko
			
			var Miejsc:Number = ((IniWidth - Rz*Slupek.vert_deph) / KonieczneMiejsce)-1;//Ile jest pozycji na słupki
			var xkrok:Number = (IniWidth - Rz*Slupek.vert_deph) / (Miejsc+1);//Ile miejsca na każdą pozycję
			var Kolejny:Slupek; //Pomocnicza zmienna na kolejne slupki
			var KolejnyNumer:uint = 0;
			
			limit = BegYpos-3*Slupek.vert_deph;//Jak wysokość jakiegoś slupka dojdzie do limitu to zwijamy symulacje
		    
			for (var j:uint = 0; j < Rz; j++)
			{
				var PosY:uint = BegYpos + j * OdlegloscPionowa;
				for (var i:uint = 0; i < N/Rz; i++)
				{
					do{
					var RandPosX:uint = (Rz-j)*Slupek.vert_deph+uint(Math.random() * Miejsc) * xkrok;//Czasem pozycja może być już w użyciu!
					//trace(RandPosX);graphics.drawRect(RandPosX,PosY-OdlegloscPionowa, xkrok, xkrok);//DEBUG
					}while (!PositionFree(RandPosX/*,PosY*/));

					var eR:Number = Math.random()* Math.random()* Math.random() * 0.05;//Nie więcej niż o 5% na klatkę
					var Elipsa:Shape = new Shape();
					var PositKolor:RGBColor = new RGBColor(0);
					PositKolor.g = 255 - (eR * 20) * 200;
					Elipsa.graphics.beginFill(PositKolor.toColor());
					Elipsa.graphics.lineStyle(1,PositKolor.toColor(),0.25);
					Elipsa.graphics.drawEllipse(-xkrok/2,-xkrok/4,xkrok,OdlegloscPionowa);
					Elipsa.graphics.endFill();
					//Elipsa.graphics.lineStyle(1, 0xffffff);//Kontrolny środek elipsy
					//Elipsa.graphics.drawRect(0, 0, 1, 1);
					Elipsa.x = RandPosX+Elipsa.width / 3;
					Elipsa.y = PosY - Elipsa.height / 4;// ?
					Elipsa.alpha = 0.75;//?
					addChild(Elipsa);
								
					PositKolor.r = 255-PositKolor.g;
					PositKolor.b = 0;
					Kolejny = new Slupek(RandPosX, PosY, SzerokoscSlupka, 1,PositKolor.toColor());	
					slupki[KolejnyNumer] = Kolejny;
					eRy[KolejnyNumer] = 1 + eR;
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
			}
			else
			{
				for (j = 0; j < N; j++)
					Slupek(slupki[j]).visible = true;
			}
			
			Title.alpha = 1;
			addChild(Title);
			
			//Gotowe, można uruchamiać symulowanie
			addEventListener(Event.ENTER_FRAME, SimulationStep,false,-10);
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
						BarHeight *= eRy[i]; //WZROST SŁUPKÓW: x:=r[i]*x
					
						if (BarHeight >= limit) //Jak pierwsza osiągnie limit to zwijamy
						{
							bedzie_koniec = true;
							BarColor = 0xffff00;
						}
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
					//trace(Title.text, ' successed');
					removeEventListener(Event.ENTER_FRAME, SimulationStep);
					addEventListener(Event.ENTER_FRAME, AfterLastStep);//Nowy sposób zmian stanu klatki
				}
		}
		
		private function AfterLastStep(e:Event):void
		//Wizualne powolne sprzątanie po symulacji, aż będzie można uruchomić ponownie
		{
			
			for (var i:uint = 0; i < numChildren; i++) //Rozmywanie bardziej ogólne...
				getChildAt(i).alpha -= 0.05;//Przy dziesieciu klatkach na sekundę będzie to trwało 2 sek.
					
			if (getChildAt(0).alpha<=0)//Idą równo więc wystarczy sprawdzić zerowe dziecko
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