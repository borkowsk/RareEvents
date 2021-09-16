package 
{
	import flash.display.*; //Wszystkie elementy dotyczące wyślwietlania
	import flash.events.Event;
	import WBor.*;
	
	/**
	 * ...
	 * @author WBorkowski
	 */
	public class Main extends Sprite 
	{
		//352x288 - PAL VCD
		//480x576 - PALS SVCD ?
		//720x576 - PAL DVD !!!
		//720x480 - NTSC DVD
		//640x480 - YouTube 4:3
		//1280x720 - YouTube 16:9
		public const Default_width:uint = 720;//Muszą być zgodne z ustawieniami w projekcie
		public const Default_height:uint = 576;//Bo sprite.with i sprite.height zwraca użyte rozmiary a nie calkowite
		
		//Scenki czyli różne modele. Powinien być Vector<Scenka> ale nie mogę znaleźć dokumentacji do niego
		private var Model1:Scenka;
		private var Model2:Scenka;
		private var Model3:Scenka;
		private var Model4:Scenka;
		private var Model5:Scenka;
		private var Model6:Scenka;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//trace("Stage: ",stage.width, '*', stage.height);//Scena jest pusta więc...
			//trace("Main:  ", this.width, 'x', this.height);//...tu wychodzą zawsze same zera!!!
			
			// entry point
			//Wstępne wymuszenie rozmiarów uzytecznego okna
			graphics.lineStyle(0, 0xeeeeee);
			graphics.drawRect(0, 0, 2,2);
			graphics.drawRect(Default_width - 2, Default_height - 2, 2,2);
			//this.opaqueBackground = 0xFFFF00;//Do testowania używanych rozmiarów okna na scenie
			trace("Stage: ",stage.width, '*', stage.height);
			trace("Main:  ",this.width, 'x', this.height);
			
			//Umieszczanie scenek
			Scenka.Default_height = this.Default_height; //Zadbanie żeby się domyślne rozmiary zgadzały
			Scenka.Default_width = this.Default_width;
			
			var SWidth:Number = Default_width / 2;
			var SHeight:Number = Default_height / 3;
			
			Scenka.BackGradientType = GradientType.LINEAR;
			Model1 = new ModelPierwszy(SWidth - 6, SHeight - 6, "Model 1: Kto pierwszy ten lepszy");
			Model1.Title.textColor = 0x00ffff;
			Model1.x = 3;
			Model1.y = 3;
			Model1.KeepRatio = true;
			addChild(Model1);
			
			Scenka.BackGradientType = GradientType.RADIAL;
			Model2 = new ModelDrugi(SWidth - 6, SHeight - 6, "Model 2: Lepiej mieć lepsze miejsce");
			Model2.Title.textColor = 0xffff00;
			Model2.x = SWidth+3;
			Model2.y = 3;
			//Model2.KeepRatio = true;
			addChild(Model2);
			
			Scenka.BackColors = [0x00DDFF, 0x0000FF];//Kolorki inne niż domyślne
			Model3 = new Scenka(SWidth-6,SHeight-6,"Model 3");
			Model3.x = 3;
			Model3.y = SHeight+3;
			addChild(Model3);
			
			Model4 = new Scenka(SWidth-6,SHeight-6,"Model 4");
			Model4.x = SWidth+3;
			Model4.y = SHeight+3;
			addChild(Model4);
			
			Model5 = new Scenka(SWidth-6,SHeight-6,"Model 5");
			Model5.x = 3;
			Model5.y = 2*SHeight+3;
			addChild(Model5);
			
			Model6 = new Scenka(SWidth-6,SHeight-6,"Model 6");
			Model6.x = SWidth+3;
			Model6.y = 2*SHeight+3;
			addChild(Model6);
			
			//Testowa zawartość
			var pom:Number = Model6.height;
			Model6.addChild(new Slupek(1,pom, 10, 70, 0x000066));
			Model6.addChild(new Slupek(31,pom, 10, 80, 0x996600));
			Model6.addChild(new Slupek(61,pom, 10, 90, 0x006699));
			
			//Uruchomienie osobnej animacji dla całości - gdyby było potrzebne
			addEventListener(Event.ENTER_FRAME, timeStep);
		}
		
		public function timeStep(e:Event):void
		{
			//Testowa animacja dla głównego Sprite'a			
			Slupek(Model6.getChildAt(0)).BarColor ++;
			//Slupek(Model6.getChildAt(1)).BarHeight *= 1.0005;
			//Slupek(Model6.getChildAt(2)).BarWidth += 0.05;
		}
	}
	
}