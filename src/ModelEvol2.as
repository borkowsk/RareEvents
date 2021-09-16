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
			StopRequest++; trace("Stop requested on '", Title.text, "'");
			e.stopPropagation();
		}
		
		private var Srodowisko:BitmapData;//Intensywność światła w środowisku
		private var WyswieSrod:Bitmap;
		
		private var ObszarAutot:BitmapData;//Wyświetla autotrofy, ale nie nadaje się do przechowywania ich danych bo gdy alfa<>ff to zmienia niskie bity
		private var Wyswietlacz:Bitmap;
		private var DaneAutot:Array;//prawdziwe dane autotrofów
		
		private var ObszarHetero:BitmapData;//Wyswietla heterotrofy, ale nie przechowuje ich danych
		private var WyswieHetero:Bitmap;
		private var DaneHetero:Array;//Prawdziwe dane heterotrofów
		
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
			var pom:RGBColor = new RGBColor(0x00aaaa00);//Żółty jak słońce, ale nie za mocny
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
			
			ObszarAutot = new BitmapData(IniWidth / 2, IniHeight / 2, true, 0x00000000);
			DaneAutot = new Array;
			var posy:uint = ObszarAutot.height / 2;
			var posx:uint = posy; //ObszarAutot.width / 2;
			ObszarAutot.setPixel32(posx, posy, 0x5508ffff);//To samo wpisane, ale nie koniecznie to samo zapamiętane!!!
			
			var pos:uint = posx + (posy * ObszarAutot.width);
			DaneAutot[pos] = 0x5508ffff;	trace('!!![', posx, ',', posy, ']=', pos);
			
			Wyswietlacz = new Bitmap(ObszarAutot);
			Wyswietlacz.scaleX = 2;
			Wyswietlacz.scaleY = 2;
			Wyswietlacz.x = 0;
			Wyswietlacz.y = 0;
			addChild(Wyswietlacz);
			
			ObszarHetero = new BitmapData(IniWidth, IniHeight, true, 0x00000000);//Wyswietla heterotrofy, ale nie przechowuje ich danych
			DaneHetero = new Array();//Prawdziwe dane heterotrofów
			posy = ObszarHetero.height / 2 + 2;
			posx = posy; // Obszar.width / 2;
			ObszarHetero.setPixel32(posx, posy, 0x77ff08ff);//To samo wpisane, ale nie koniecznie to samo zapamiętane!!!
			
			pos = posx + (posy * ObszarHetero.width);
			DaneHetero[pos] = 0x77ff08ff;	trace('???[', posx, ',', posy, ']=', pos);
			
			WyswieHetero = new Bitmap(ObszarHetero);
			WyswieHetero.x = 0;
			WyswieHetero.y = 0;
			addChild(WyswieHetero);
			
			Title.alpha = 1;
			addChild(Title);
			StopRequest = 0;
			addEventListener(MouseEvent.DOUBLE_CLICK, RestartOnDClick);
			
			//Gotowe, można uruchamiać symulowanie
			ChangeOnEnterHandle(SimulationStep);//addEventListener(Event.ENTER_FRAME, SimulationStep);
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
			var pom:uint = (8 - Bits[genypot.b]);//blue to maska obrony - tym lepsza im mniej bitów
			if (pom == 8) //za dobra - nikt nie może nic uszczknąć
			   pom = 256;//Blokująca kara za taką maskę
			else
				pom *= pom;//Kwadrat kosztów obrony - nie więcej niż 7*7
			pom = pom + (Bits[genypot.g] * Bits[genypot.g]) / 2;//Za chlorofil nie więcej niż 32	
			return pom + Bits[genypot.r];//Koszty ataku/uposazenia autotrofa liczone normalnie
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
		
		private static function MozeMutujHetero(parent:uint):uint
		{
			var gens:uint = 0x00ffffff & parent;//Geny do ewentualnego zmutowania
			var poz:uint = Math.random() * 240*10;//Nie częściej niż co dziesiąty możę mutować. Albo lepiej rzadziej
			if (poz > 23) //Nie ma mutacji.
			{
				return gens;
			}
			else //Niestety jest, trzeba pokombinować :-)
			{
				var mask:uint = 0x00000001 << poz;
				gens ^= mask; //Do magic :-))))
				//trace(parent.toString(16),'->',gens.toString(16));
				//if ((gens & 0xff000000) != 0) trace('Bląd algorytmu - mutacja kanału alpha: ',gens.toString(16));
				return gens;
			}
		}
		
		private static function fotosynteza(en:Number, ch:Number, lht:Number):uint
		{
			//if (en > 255 || ch > 255 || lht > 255)
			//		trace('foto: e=', en.toString(16), ' ch=', ch.toString(16), ' lht=', lht.toString(16));
			if (en > 255)
					return 255;
			var pom:Number =//(255.0 - Math.abs(ch - lht)) / 512.0;//
							(ch / 255.0) * (lht / 255.0);
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
			
			//Obsluga obszaru autotrofów
			///////////////////////////////////
			var zlicz_pustki:uint = 0;
			var FullSize:uint = ObszarAutot.width * ObszarAutot.height; 
			var MC:uint = FullSize / 10;//10% obszaru probkowania na klatkę
			var Width:uint = ObszarAutot.width;
			var Height:uint = ObszarAutot.height;
			ObszarAutot.lock();
			
			for (var i:uint = 0; i < MC; i++) //Głowna pętla symulacji dla autotrofów
			{
				var opos:uint = Math.random() * FullSize;
				var ox:uint = opos % Width;
				var oy:uint = opos / Width;
				var dir:uint = Math.random()*7.99999;
				var nx:int = (Width + ox + Moves[dir][0]) % Width;
				var ny:int = oy + Moves[dir][1];
				if (ny < 0) 
				{
					ny = 0;
					if (oy == 0 && nx == ny) //Wpadła sam na siebie
						ny = oy + 1; //Wtedy bezpiecznie o jeden w dół
				}
				else 
				if (ny >= Height) 
				{ 
					ny = Height - 1;
					if ( ny == oy && nx == ny)//Tez wpadła sam na siebie
					   ny = oy - 1;//Bezpiecznie o jeden w górę 
				}
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
							ObszarAutot.setPixel32(nx, ny, potomek.toColor32());//Rozmnazanie
							
							//if (Obszar.getPixel32(nx, ny) != potomek.toColor32())//Niestety często prawda, zwałszcza jak alfa jest mała
							//	trace("Chala POTOMEK po updacie",Obszar.getPixel32(nx, ny).toString(16),'<>',potomek.toColor32().toString(16));
							
							firstRGB.a -= uposazenie;
						}
						
													//trace('F:', firstRGB.toColor32().toString(16));//TEST CO WYSZLO			
						firstRGB.a -= 1;//Koszty metaboliczne							
						DaneAutot[opos] = firstRGB.toColor32();//Aktualizacja
						ObszarAutot.setPixel32(ox, oy,  firstRGB.toColor32() );//Aktualizacja c.d.
				
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
							ObszarAutot.setPixel32(x, y, potomek.toColor32());//Rozmnazanie
							
							seconRGB.a -= uposazenie;
						}
										
						seconRGB.a -= 1;//Koszty metaboliczne		
						DaneAutot[npos] = seconRGB.toColor32();//Aktualizacja
						ObszarAutot.setPixel32(nx, ny,  seconRGB.toColor32() );//Aktualizacja c.d.
					}
					else //Oba pełne - mogłyby walczyć
					{
					//Lepsze są które mają większy zapas energii
					/////////////////////////////////////////////
						
						firstRGB.a = fotosynteza(firstRGB.a, firstRGB.g, light_f);//Green as chlorophyl factor
						seconRGB.a = fotosynteza(seconRGB.a, seconRGB.g, light_s);//Green as chlorophyl factor
						
						if (firstRGB.a == seconRGB.a || firstRGB.a < 235 || seconRGB.a < 235) 		
						{
							//Jak słabe lub równe to pierwszy próbuje dalekiego wysiewu
							var r:Number = 5 + Math.random() * Math.random() * Math.random() * Math.random() * (Height / 2);
							var k:Number = Math.random() * 2 * Math.PI;
							
							var mx:uint = (Width + ox + r*Math.sin(k)) % Width;//Zawiniety po torusie
							var my:uint = oy + r * Math.cos(k);//... a to nie
							if (my < 0) my = 0;
							else if (my >= Height) my = Height - 1;
							var mpos:uint =  mx + my * Width;
							
							potomek.toRGB(MozeMutuj(firstRGB.toColor()));
							uposazenie = firstRGB.r + 2; //Ile energii ma dostać potomek
							potomek.a = uposazenie; //Bezposrednie uposażanie potomka
							uposazenie+=LiczKosztPotomka(potomek);//Koszty budowy potomka
																
							if (uposazenie < firstRGB.a) //Tylko jeśli go stać
							{
												//	trace('[',ox,'->',mx, ',',oy,'->', my, ']=', mpos, ': ', firstRGB.a.toString(16),'.', firstRGB.r.toString(16),'.', firstRGB.g.toString(16),'.', firstRGB.b.toString(16));
								DaneAutot[mpos] = potomek.toColor32();
								ObszarAutot.setPixel32(mx, my, potomek.toColor32());//Rozmnazanie
								firstRGB.a -= uposazenie;
							}
						}
						else //Nierówne lecz w obszarze dobrobytu - walka o miejsce
						{
							if (firstRGB.a > seconRGB.a)
							{
								firstRGB.a = firstRGB.a*0.9;//Koszt ataku 20%
								seconRGB.a = seconRGB.a*0.5;//Straty po ataku 50%
							}
							else
							{
								firstRGB.a = firstRGB.a*0.5;//Straty po ataku 50%
								seconRGB.a = seconRGB.a*0.9;//Koszt ataku 20%
							}
						}
						
						firstRGB.a = firstRGB.a*0.997;//Koszty metaboliczne.
						seconRGB.a = seconRGB.a*0.997;//W tlumie inne koszty (ale warto pamietac, że część ułamkow wyniku jest obcinana!!!
						
						DaneAutot[opos] = firstRGB.toColor32();//Aktualizacja
						DaneAutot[npos] = seconRGB.toColor32();//Aktualizacja
						ObszarAutot.setPixel32(ox, oy,  firstRGB.toColor32() );//Aktualizacja
						ObszarAutot.setPixel32(nx, ny,  seconRGB.toColor32() );//Aktualizacja
					}
				}	
			}
			
			
			var zlicz_pustki_hetero:uint = 0;
			FullSize = ObszarHetero.width * ObszarHetero.height; 
			MC = (ObszarHetero.width * ObszarHetero.height) / 10;//10% obszaru probkowania na klatkę
			//Rozmiary obszaru symulacji heterotrofów
			Width= ObszarHetero.width;
			Height = ObszarHetero.height;
			ObszarHetero.lock();
			
			for (i = 0; i < MC; i++) //Głowna pętla symulacji dla autotrofów (i zadeklarowane wcześniej)
			{	
				
				//Losowanie pierwszej pozycji
				opos = Math.random() * FullSize;//Zmienne AS mają zasięg funkcji a nie bloku, więc nie trzeba ich tu ponownie deklarować
				ox = opos % Width; 				//Co jest trochę niebezpieczne, bo trzeba bardziej uważać... 
				oy = opos / Width;
				first = DaneHetero[opos];//Obszar.getPixel32(x, y);
				if ((first & 0xff000000) == 0) //Puste pole
				{
					zlicz_pustki_hetero++;
						continue;			  //Po prostu wychodzimy z tego obrotu pętli
				}
				
				firstRGB.toRGB(first);
				var Zjadl:Number = 0;//Zapamietuje energię uzyskaną na tym polu, żeby podjąć decyzję o ruchu
				//Trzeba sprawdzić, czy pod nogami jest coś do zjedzenia
				nx = ox / 2;
				ny = oy / 2;
				npos = nx + ny * ObszarAutot.width;//Pozycja z obszaru autotrofów
				second = DaneAutot[npos];
				
				if ((second & 0xff000000) != 0)//Coś jest pod nogami, co można posmakować
				{
					seconRGB.toRGB(second);
					if ((firstRGB.r & seconRGB.b) != 0) //Mozna coś uszczknąć
					{
						var Eksp:Number = Number(firstRGB.r & seconRGB.b) / Number(firstRGB.r) *
										  Number(firstRGB.r & seconRGB.b) / Number(seconRGB.b);
						//trace("Trawa dla niego ", nx, ' ', ny, ' : ', second.toString(16), 'E:', Eksp);
						Eksp *= seconRGB.a;
						Zjadl += Eksp;
						firstRGB.a += Eksp;
						seconRGB.a -= Eksp / 4; //Bo jest cztery razy większy
						DaneAutot[npos] = seconRGB.toColor32();//Aktualizacja ofiary
						ObszarAutot.setPixel32(nx, ny, seconRGB.toColor32());//Wizualizacja
					}
				}
						
				//Teraz potrzebne losowanie drugiej pozycji w warstwie heterotrofów
				dir = Math.random()*7.99999;
				nx = (Width + ox + Moves[dir][0]) % Width;
				ny = oy + Moves[dir][1];
				if (ny < 0) 
				{
					ny = 0;
					if (oy == 0 && nx == ny) //Wpadła sama na siebie
						ny = oy + 1; //Wtedy bezpiecznie o jeden w dół
				}
				else 
				if (ny >= Height) 
				{ 
					ny = Height - 1;
					if ( ny == oy && nx == ny)//Tez wpadła sama na siebie
					   ny = oy - 1;//Bezpiecznie o jeden w górę 
				}
				npos = nx + ny * Width;
				second = DaneHetero[npos];//Obszar.getPixel32(nx, ny);
				
				if ((second & 0xff000000) != 0)//Pozycja obok nie jest pusta - to komplikuje życie ale daje szanse
				{
					//trace('pełna');
					seconRGB.toRGB(second);
					//Tu szansa na kolejne polowanie
					if ((firstRGB.r & seconRGB.b) != 0) //Mozna coś uszczknąć - atakujący ma przewagę zaskoczenia
					{
						Eksp/*:Number*/ = Number(firstRGB.r & seconRGB.b) / Number(firstRGB.r) *
										  Number(firstRGB.r & seconRGB.b) / Number(seconRGB.b);
						Eksp *= seconRGB.a;
						Zjadl += Eksp;
						firstRGB.a += Eksp;//... reszta energii jest tracona, choć mogłaby może zasilać autotrofy
						
						DaneHetero[npos] = firstRGB.toColor32();//Przeniesienie na miejsce po ofierze
						ObszarHetero.setPixel32(nx, ny, firstRGB.toColor32());//Wizualizacja
						DaneHetero[opos] = 0; //Stare miejsce jest teraz puste
						ObszarHetero.setPixel32(ox, oy, 0);//Co tu widać
						
						second = 0;//second tez trzeba aktualizować jak polowanie się uda!!!
						seconRGB.toRGB(0);
						mx = nx; nx = ox; ox = mx;//Zamiana współrzednych - teraz first jest na miejscu zjedzonego second
						my = ny; ny = oy; oy = my;//Zamiana współrzednych 
						mpos = npos; npos = opos; opos = mpos;//I pozycji w tablicy
					}
				}
				
				if ((second & 0xff000000) == 0)//Pozycja obok jest pusta, jak miło...
				{
					//trace('pusta');
					if (Zjadl > (1+firstRGB.g * Math.random()) )
					{ //Zostaje i próbuje się rozmnażać 
						firstRGB.a = firstRGB.a * 0.997;//Koszty metaboliczne
						uposazenie = LiczKosztPotomka(firstRGB);//Liczy koszty bez mutacji
						if ((uposazenie+firstRGB.a * 0.1) < firstRGB.a) //Stać go na potomka wraz z energia na poczatek
						{ //To go robi... 
							potomek.toRGB( MozeMutujHetero(firstRGB.toColor()) );
							potomek.a = firstRGB.a * 0.1;
							firstRGB.a -= potomek.a;//Koszty uposarzenia
							firstRGB.a -= uposazenie;
							DaneHetero[npos] = potomek.toColor32();//Pojawia się potomek na wolnej pozycji
							ObszarHetero.setPixel32(nx, ny, potomek.toColor32());//...i to wizualizuje
						}
						//Sam tak czy inaczej sam zostaje na miejscu
						DaneHetero[opos] = firstRGB.toColor32();//Pozostaje u siebie, tylko zmienia stan
						ObszarHetero.setPixel32(ox, oy, firstRGB.toColor32());//...i to wizualizuje
					}
					else //Przenosi się na nową pozycje, może lepszą
					{
						DaneHetero[opos] = 0;//Znika ze starej pozycji
						ObszarHetero.setPixel32(ox, oy, 0);//...i to wizualizuje
						firstRGB.a = firstRGB.a * 0.997;//Koszty metaboliczne
						DaneHetero[npos] = firstRGB.toColor32();//Pojawia się na nowej
						ObszarHetero.setPixel32(nx, ny, firstRGB.toColor32());//...i to wizualizuje
					}
				}
				else //Nadal nowa pozycja nie jest pusta - zostaje
				{
					if (Math.random() < 0.005)
						firstRGB.a = 0; //Raz na sto/dwiescie/tysiąc nudnych klatek umiera
						else
						firstRGB.a = firstRGB.a * 0.995;//Koszty metaboliczne większe w tłoku
					DaneHetero[opos] = firstRGB.toColor32();//Pozostaje u siebie, tylko zmienia stan
					ObszarHetero.setPixel32(ox, oy, firstRGB.toColor32());//...i to wizualizuje
				}				
			}
			
			ObszarAutot.unlock();
			ObszarHetero.unlock();
			
			if(StopRequest>1/*zlicz_pustki==2*MC*/)//Jak same puste to coś by trzeba zrobić, choć może nie od razu
			{
				//trace('pustek: ', zlicz_pustki);
				//trace(Title.text, ' successed');
				removeEventListener(MouseEvent.DOUBLE_CLICK, RestartOnDClick);
				//removeEventListener(Event.ENTER_FRAME, SimulationStep);
				ChangeOnEnterHandle(AfterLastStep);//addEventListener(Event.ENTER_FRAME, AfterLastStep);//Nowy sposób zmian stanu klatki
			}
		}
		
		private function AfterLastStep(e:Event):void
		//Wizualne powolne sprzątanie po symulacji, aż będzie można uruchomić ponownie
		{	
			Wyswietlacz.alpha -= 0.02;
					
			if (Wyswietlacz.alpha<=0)
			{
				ChangeOnEnterHandle(null);//removeEventListener(Event.ENTER_FRAME, AfterLastStep);//Chwilowo nie ma czego robić w nowej klatce
		
				for (var j:int = numChildren - 1; j >= 0 ; j--)//I bardziej ogólne usuwanie...
				{
					removeChildAt(j); //Usuwa wszystko z listy wyświetlania scenki
				}
				
				ObszarAutot.dispose(); //Niby wymuszenie zwalniania
				ObszarHetero.dispose();
				ObszarAutot = null;
				ObszarHetero = null;
				Wyswietlacz = null;
				WyswieHetero = null;
				
				Initialise();//Ponownie przygotowuje dane i startuje nową symulację
			}
		}
	}
	
}