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
	public class ModelEvol2 extends Scenka
	{
		//Rozmiary inicjalne muszą być zapamiętane bo width i height zmienia się przy zmianie skali
		public var IniWidth:Number = 0;
		public var IniHeight:Number = 0;
		
		public function ModelEvol2(iwidth:Number,iheight:Number,ititle:String="Model ewolucji #2") 
		{
			super(iwidth, iheight, ititle);
			IniWidth = iwidth;
			IniHeight = iheight;
			//...
			Initialise();
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOverMy);
			this.doubleClickEnabled = true;
		}
		
		protected function onMouseOverMy(e:MouseEvent):void
		{
			Title.textColor = Math.random() * 0xffffff;
			super.onMouseOver(e);
		}
		
		private var StopRequest:uint = 0; //Dla usera szansa na zatrzymanie i restart
		protected function RestartOnDClick(e:MouseEvent):void
		{
			StopRequest++; trace("Stop requested on '", Title.text,"'");
		}
		
		private var Srodowisko:BitmapData;//Intensywność światła w środowisku
		private var WyswieSrod:Bitmap;
		
		private var Obszar:BitmapData;//Wyświetla autotrofy, ale nie nadaje się do przechowywania ich danych bo gdy alfa<>ff to zmienia niskie bity
		private var Wyswietlacz:Bitmap;
		
		private var DaneAutot:Array;//prawdziwe dane autotrofów
		
		private function Initialise():void
		//Inicjalizacja musi być tak zrobiona, żeby można było ją ponownie użyć, jak symulacja się zakończy!
		{
			graphics.clear();//Czy nie za dużo tego dobrego? Tło i trzy zmienne bitmapy?
			graphics.lineStyle(0,0);
			graphics.beginFill(0);
			graphics.drawRect(0, 0, IniWidth, IniHeight);//Aktywne "myszowo" tło scenki
			graphics.endFill();
			
			Srodowisko = new BitmapData(IniWidth / 2, IniHeight / 2, true, 0x00000000);
			//Srodowisko.colorTransform(0, 0, Srodowisko.width, Srodowisko.height, MyTransform);
			var pom:RGBColor = new RGBColor(0x00ffff00);//Żółty jak słońce
			for (var i:uint=0; i < Srodowisko.height; i++)//Ale gradient ALFY
			{
				pom.a = 255 * (Number(i) / Number(Srodowisko.height));
				for (var j:uint=0; j < Srodowisko.width; j++)
				 Srodowisko.setPixel32(j, i, pom.toColor32());
			}
			
			WyswieSrod = new Bitmap(Srodowisko, "auto", true);
			WyswieSrod.scaleX = 2;
			WyswieSrod.scaleY = 2;
			WyswieSrod.x = 0;
			WyswieSrod.y = 0;
			addChild(WyswieSrod);
			
			Obszar = new BitmapData(IniWidth / 2, IniHeight / 2, true, 0x00000000);
			DaneAutot = new Array;
			var posy:uint = Obszar.height / 2;
			var posx:uint = posy; // Obszar.width / 2;
			Obszar.setPixel32(posx, posy, 0x55087744);//To samo wpisane, ale nie koniecznie to samo zapamiętane!!!
			
			var pos:uint = posx + (posy * Obszar.width);
			DaneAutot[pos] = 0x55087744;	trace('!!![', posx, ',', posy, ']=', pos);
			
			
			Wyswietlacz = new Bitmap(Obszar);
			Wyswietlacz.scaleX = 2;
			Wyswietlacz.scaleY = 2;
			Wyswietlacz.x = 0;
			Wyswietlacz.y = 0;
			addChild(Wyswietlacz);
			
			Title.alpha = 1;
			addChild(Title);
			
			//Gotowe, można uruchamiać symulowanie
			addEventListener(Event.ENTER_FRAME, SimulationStep);
			StopRequest = 0;
			addEventListener(MouseEvent.DOUBLE_CLICK, RestartOnDClick);
		}
		
		private var Moves:Array = [[1,  1], [0,  1], [ -1,  1],
								   [1, -1], [0, -1], [ -1, -1],
								   [ -1, 0], [1,  0], [ 0, 0]];//Ostatni dla bezpieczenstwa
								   
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
		
		private static  function LiczKosztPotomka(genypot:RGBColor):uint
		{
			return Bits[genypot.r] + Bits[genypot.g] + (8 - Bits[genypot.b]);//blue to maska obrony - tym lepsza im mniej bitów
		}
		
		private static function MozeMutuj(parent:uint):uint
		{
			var gens:uint = parent;//Geny do ewentualnego zmutowania
			var poz:uint = Math.random() * 200*10;//Nie częściej niż co dziesiąty możę mutować. Albo lepiej rzadziej
			if (poz > 19) //Nie ma mutacji.
			{
				return gens;
			}
			else //Niestety jest, trzeba pokombinować :-)
			{
				var mask:uint = 0x00000001 << poz;
				gens ^= mask; //Do magic :-))))
				//trace(parent.toString(16),'->',gens.toString(16));
				//if ((gens & 0xff000000) != 0xff000000) trace('Bląd algorytmu - mutacja kanału alpha');
				return gens;
			}
		}
		
		private static function fotosynteza(en:Number, ch:Number, lht:Number):uint
		{
			if (en > 255 || ch > 255 || lht > 255)
					trace('foto: e=', en.toString(16), ' ch=', ch.toString(16), ' lht=', lht.toString(16));
			if (en > 255)
					return 255;
			var pom:Number = (255-Math.abs(ch - lht))/512;//(ch / 255) * (lht / 255);
			pom = 1 + pom;
			pom = en * pom;
			if (pom > 255) return 255;
			else
			return pom;
		}
		
		private static var firstRGB:RGBColor = new RGBColor(0);
		private static var seconRGB:RGBColor = new RGBColor(0);
		private static var potomek:RGBColor = new RGBColor(0);
		
		private function SimulationStep(e:Event):void
		//Wykonuje kroki symulacji tak dlugo jak się da, a potem podmienia na zakończenie (AfterLastStep)
		//Populacje ewoluują w kierunku białego, a potem od nowa.
		{
			Title.alpha *= 0.95;
			//Obszar.scroll(-1, 0);// Widowiskowe, ale wymaga więcej zachodu - trzeba by ręcznie zawinąć brzegi
			var zlicz_pustki:uint = 0;
			var FullSize:uint = Obszar.width * Obszar.height; 
			var MC:uint = (Obszar.width * Obszar.height) / 10;//20% obszaru probkowania na klatkę
			Obszar.lock();
			for (var i:uint = 0; i < MC; i++) //Głowna pętla symulacji
			{
				var Width:uint = Obszar.width;
				var Height:uint = Obszar.height;
				var opos:uint = Math.random() * FullSize;
				var ox:uint = opos % Width;
				var oy:uint = opos / Width;
				var dir:uint = Math.random()*7.99999;
				var nx:int = (Width + ox + Moves[dir][0]) % Width;
				var ny:int = (Height + oy + Moves[dir][1]) % Height;//???
				var npos:uint = nx + ny * Width;
				
				var first:uint=DaneAutot[opos];//Obszar.getPixel32(x, y);
				var second:uint = DaneAutot[npos];//Obszar.getPixel32(nx, ny);
				
				if ((first & 0xff000000) == 0 && (second & 0xff000000) ==0)//Oba puste - nie rób nic
				{
					zlicz_pustki += 2;
					continue; 
				}
				else 
				{
					var uposazenie:uint;
					var light_f:uint = Srodowisko.getPixel32(ox , oy ); //Tu chyba można bo chodzi o sam kanał alfa
					var light_s:uint = Srodowisko.getPixel32(nx , ny ); 
					//light_f = (light_f >> 24) & 0xff;//Extract alpha channel as light factor
					//light_s = (light_s >> 24) & 0xff;
					light_f = (Number(oy) / Height) * 255;
					light_s = (Number(ny) / Height) * 255;
											//trace(light_f.toString(16), ' ', light_s.toString(16));
					firstRGB.toRGB(first); 
					seconRGB.toRGB(second);
					
					if (firstRGB.a != 0 && seconRGB.a == 0)//Pelny na pusty - rozmnóz jak się uda
					{
						//trace('[',ox,',',oy,']=',opos,': ',first.toString(16), '==>', firstRGB.a.toString(16), ' ', firstRGB.r.toString(16), ' ', firstRGB.g.toString(16), ' ', firstRGB.b.toString(16));
						firstRGB.a = fotosynteza(firstRGB.a,firstRGB.g, light_f);//Green as chlorophyl factor
						//potomek.toRGB(first);
						potomek.toRGB(MozeMutuj(firstRGB.toColor()));
						uposazenie = firstRGB.r + 2; //Ile energii ma dostać potomek
						potomek.a = uposazenie; //Bezposrednie uposażanie potomka
						uposazenie+=LiczKosztPotomka(potomek);//Koszty budowy potomka
																
						if (uposazenie < firstRGB.a) //Tylko jeśli go stać
						{
													//trace('P:',potomek.toColor32().toString(16),' u:',uposazenie);//TEST CO WYSZLO
													//trace('[', nx, ',', ny, ']=', npos, ': ', firstRGB.a.toString(16),'.', firstRGB.r.toString(16),'.', firstRGB.g.toString(16),'.', firstRGB.b.toString(16));
							DaneAutot[npos] = potomek.toColor32();
							Obszar.setPixel32(nx, ny, potomek.toColor32());//Rozmnazanie
							
							//if (Obszar.getPixel32(nx, ny) != potomek.toColor32())//Niestety często prawda, zwałszcza jak alfa jest mała
							//	trace("Chala POTOMEK po updacie",Obszar.getPixel32(nx, ny).toString(16),'<>',potomek.toColor32().toString(16));
							
							firstRGB.a -= uposazenie;
						}
						
													//trace('F:', firstRGB.toColor32().toString(16));//TEST CO WYSZLO			
						firstRGB.a -= 1;							
						DaneAutot[opos] = firstRGB.toColor32();//Aktualizacja
						Obszar.setPixel32(ox, oy,  firstRGB.toColor32() );//Aktualizacja c.d.
				
						//if (Obszar.getPixel32(x, y) != firstRGB.toColor32())//Niestety często prawda, zwałszcza jak alfa jest mała
						//		trace("Chala FIRST po updacie",Obszar.getPixel32(x, y).toString(16),'<>',firstRGB.toColor32().toString(16));
					}
					else 
					if (firstRGB.a == 0 && seconRGB.a != 0)//Pusty na pełny - rozmnóz jak się uda
					{
						seconRGB.a = fotosynteza(seconRGB.a,seconRGB.g, light_s);//Green as chlorophyl factor
						//potomek.toRGB(first);
						potomek.toRGB(MozeMutuj(seconRGB.toColor()));
						uposazenie = seconRGB.r + 2; //Ile energii ma dostać potomek
						potomek.a = uposazenie; //Bezposrednie uposażanie potomka
						uposazenie+=LiczKosztPotomka(potomek);//Koszty budowy potomka
																
						if (uposazenie < seconRGB.a) //Tylko jeśli go stać
						{
							DaneAutot[opos] = potomek.toColor32();
							Obszar.setPixel32(x, y, potomek.toColor32());//Rozmnazanie
							
							seconRGB.a -= uposazenie;
						}
										
						seconRGB.a -= 1;	
						DaneAutot[npos] = seconRGB.toColor32();//Aktualizacja
						Obszar.setPixel32(nx, ny,  seconRGB.toColor32() );//Aktualizacja c.d.
					}
					else //Oba pełne - mogłyby walczyć
					{
					//Lepsze są które mają większy zapas energii
					/////////////////////////////////////////////
						
						firstRGB.a = fotosynteza(firstRGB.a, firstRGB.g, light_f);//Green as chlorophyl factor
						seconRGB.a = fotosynteza(seconRGB.a, seconRGB.g, light_s);//Green as chlorophyl factor
						
						if (firstRGB.a == seconRGB.a || firstRGB.a < 200 || seconRGB.a < 200) 		
						{
							//Jak słabe lub równe to pierwszy próbuje dalekiego wysiewu
							var r:Number = 5 + Math.random() * Math.random() * Math.random() * Math.random() * (Height / 2);
							var k:Number = Math.random() * 2 * Math.PI;
							
							var mx:uint = (Width + ox + r*Math.sin(k)) % Width;
							var my:uint = (Height + oy + r * Math.cos(k)) % Height;
							var mpos:uint =  nx + ny * Width;
							
							potomek.toRGB(MozeMutuj(firstRGB.toColor()));
							uposazenie = firstRGB.r + 2; //Ile energii ma dostać potomek
							potomek.a = uposazenie; //Bezposrednie uposażanie potomka
							uposazenie+=LiczKosztPotomka(potomek);//Koszty budowy potomka
																
							if (uposazenie < firstRGB.a) //Tylko jeśli go stać
							{
												//	trace('[',ox,'->',mx, ',',oy,'->', my, ']=', mpos, ': ', firstRGB.a.toString(16),'.', firstRGB.r.toString(16),'.', firstRGB.g.toString(16),'.', firstRGB.b.toString(16));
								DaneAutot[mpos] = potomek.toColor32();
								Obszar.setPixel32(mx, my, potomek.toColor32());//Rozmnazanie
								firstRGB.a -= uposazenie;
							}
						}
						else //Nierówne lecz w obszarze dobrobytu - walka
						{
							if (firstRGB.a > seconRGB.a)
							{
								firstRGB.a -= seconRGB.a;
								seconRGB.a = 0;
								//potomek = MozeMutuj(first);
								//Obszar.setPixel32(nx, ny, potomek);
							}
							else
							{
								seconRGB.a -= firstRGB.a;
								firstRGB.a = 0;
								//potomek = MozeMutuj(second);
								//Obszar.setPixel32(x, y, MozeMutuj(second));
							}
						}
						
						firstRGB.a -= 2;//W tlumie większe koszty
						seconRGB.a -= 2;
						
						DaneAutot[opos] = firstRGB.toColor32();//Aktualizacja
						DaneAutot[npos] = seconRGB.toColor32();//Aktualizacja
						Obszar.setPixel32(ox, oy,  firstRGB.toColor32() );//Aktualizacja
						Obszar.setPixel32(nx, ny,  seconRGB.toColor32() );//Aktualizacja
					}
				}	
			}
			Obszar.unlock();
			if(StopRequest>1/*zlicz_pustki==2*MC*/)//Jak same puste to coś by trzeba zrobić, choć może nie od razu
			{
				//trace('pustek: ', zlicz_pustki);
				//trace(Title.text, ' successed');
				removeEventListener(Event.ENTER_FRAME, SimulationStep);
				removeEventListener(MouseEvent.DOUBLE_CLICK, RestartOnDClick);
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