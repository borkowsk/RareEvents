package 
{
	import flash.display.*; //Wszystkie elementy dotyczące wyślwietlania
	import flash.text.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import caurina.transitions.Tweener;
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
		//public const Default_width:uint = 800;//Muszą być zgodne z ustawieniami w projekcie
		//public const Default_height:uint = 600;//Bo sprite.with i sprite.height zwraca użyte rozmiary a nie calkowite
		
		public var Klatka:uint=0;//Licznik klatek
		
		//Scenki czyli różne modele. Powinien być Vector<Scenka> ale nie mogę znaleźć dokumentacji do niego
		private var Model1:Scenka;
		private var Model2:Scenka;
		private var Model3:Scenka;
		private var Model4:Scenka;
		private var Model5:Scenka;
		private var Model6:Scenka;
		
		[Embed(source = 'AboutRzadkie.jpg')]
		public static var clAbout:Class;
		private var About:Bitmap; 
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		  
		private var background:Sprite = null;//Potrzebne do lapania MouseEventów i klawiatury
		public var Status:TextField;//Pasek informacyjny statusu
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//trace("Stage: ",stage.width, '*', stage.height);//Scena jest pusta więc...
			//trace("Main:  ", this.width, 'x', this.height);//...tu wychodzą zawsze same zera!!!
			
			// entry point
			//Wstępne wymuszenie rozmiarów uzytecznego okna i klikalności marginesów dla okna About
			background = new Sprite();//Musi być Sprite bo ani Main.bacground ani Shape nie działają
			background.x = 0;
			background.y = 0;
			background.graphics.lineStyle(0, 0xaaaaaa);
			background.graphics.beginFill(0xaaaaaa);
			background.graphics.drawRect(0, 0, Default_width, Default_height);
			background.graphics.endFill();
			addChild(background);
			background.useHandCursor = true;
			background.doubleClickEnabled = true;
			background.focusRect = false;
			
			//this.opaqueBackground = 0xFFFF00;//Do testowania używanych rozmiarów okna na scenie
			trace("Stage: ",stage.width, '*', stage.height);
			trace("Main:  ",this.width, 'x', this.height);
			
			//Linia statusu
			Status = new TextField();
			Status.autoSize = TextFieldAutoSize.LEFT;			
			Status.text = "OK";	
			Status.x = 1;
			Status.y = this.height-Status.height;
			Status.alpha = 0;//Niewidoczny
			
			//"Okienko" About
			About = new clAbout();
			About.x = width/2-About.width / 2;
			About.y = height/2-About.height / 2;
			About.visible = false;
			
			//Umieszczanie scenek
			Scenka.Default_height = this.Default_height; //Zadbanie żeby się domyślne rozmiary zgadzały
			Scenka.Default_width = this.Default_width;
			
			var SWidth:Number = Default_width / 2;
			var SHeight:Number = Default_height / 3;
			
			Scenka.BackGradientType = GradientType.LINEAR;
			Model1 = new ModelPierwszy(SWidth - 6, SHeight - 6, "[1] A:=const*A czyli 'Kto pierwszy ten lepszy'");
			Model1.Title.textColor = 0x00ffff;
			Model1.x = 3;
			Model1.y = 3;
			addChild(Model1);
			
			Scenka.BackGradientType = GradientType.RADIAL;
			Model2 = new ModelDrugi(SWidth - 6, SHeight - 6, "[2] A:=b*A czyli 'Lepiej mieć lepsze miejsce'");
			Model2.Title.textColor = 0xffff00;
			Model2.x = SWidth+3;
			Model2.y = 3;
			//Model2.KeepRatio = true;
			addChild(Model2);
			
			Scenka.BackColors = [0xFFFFFF, 0x0000FF];//Kolorki inne niż domyślne
			Model3 = new ModelTrzeci(SWidth-6,SHeight-6,"[3] A:=A*b*c*d czyli 'Najlepiej być farciarzem'");
			Model3.x = 3;
			Model3.y = SHeight + 3;
			addChild(Model3);
			
			Model4 = new ModelCzwarty(SWidth-6,SHeight-6,"[4] Zmienne środowisko czyli 'chwytaj okazję'");
			Model4.x = SWidth+3;
			Model4.y = SHeight+3;
			addChild(Model4);
			
			Scenka.BackColors = [0x005588, 0x0000AA];//Kolorki inne niż domyślne
			Scenka.BackRatios = [127,255];
			Model5 = new ModelEvol1(SWidth - 6, SHeight - 6, "[5] Mikroewolucja: 'wygrywają lepsze pomysły'");
			Model5.Title.textColor = 0x999999;
			Model5.x = 3;
			Model5.y = 2 * SHeight + 3;
			//Model5.KeepRatio = true;
			addChild(Model5);
			
			Model6 = new ModelEvol2(SWidth - 6, SHeight - 6, //"[6] Makroewolucja: 'inni są twoim zmiennym środowiskiem'"
															 "[6] Makroewolucja: 'wszystko to środowisko'"
			);
			Model6.x = SWidth+3;
			Model6.y = 2 * SHeight + 3;
			//Model6.KeepRatio = true;
			addChild(Model6);
			
			//Ostatnie przygotowania
			addChild(About); // Jak się pojawia to przykrywa
			addChild(Status); //Powinien być na wierzchu!
			stage.focus = background;
			addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);//bacground sam nie obsluguje więc przekazuje wyżej	
			addEventListener(Event.ACTIVATE, GrabFocus);
			//addEventListener(MouseEvent.CLICK, GrabFocus);//Nie może być bo kłóci się z obslugą scenek
			addEventListener(MouseEvent.MOUSE_WHEEL, GrabFocus);
			
			//Uruchomienie osobnej animacji dla całości - gdyby było potrzebne
			addEventListener(Event.ENTER_FRAME, timeStep);//Tu zliczanie klatek
		}
		
		public function onDoubleClick(e:Event):void
		{
			trace('..... Main double clicked!!!!!!!!!!!');
			if (About.visible)
			{
			   About.visible = false;//Działa tylko w specyficznych miejscach
			}
			else
			{
				//Trzeba zapewnić, żeby About  był na wierzchu
				var last:DisplayObject = getChildAt(numChildren-1);
				swapChildren(About, last);
				About.visible = true;
				About.alpha = 1;
				Tweener.addTween(About, { alpha:0, delay:3, time:3, onComplete:function():void { this.visible = false; } } );
			}
			stage.focus = background;			
		}
		
		public function GrabFocus(e:Event):void
		{
			stage.focus = background;
			var last:DisplayObject = getChildAt(numChildren - 1);
			if (last != Status)
				swapChildren(Status, last);
			Status.text = stage.frameRate.toString() + ' frm/s ' + Klatka.toString() + ' frame ' 
						//+ Default_width.toString() + 'x' + Default_height.toString() + '(def) '
						+ width.toString() + 'x' + height.toString()  + ' (int. 100%)';	
			Status.visible = true;
			Status.textColor = Math.random() * 0xffffff;
			Status.alpha = 1;
			Status.scaleX = 1;
			Status.scaleY = 1;
			Status.y = height - Status.height;
			Tweener.addTween(Status, { y:(height - Status.height*2), time:1 } );
			Tweener.addTween(Status, { alpha:0,delay:1, time:0.5 } );
			Tweener.addTween(Status, { scaleX:2, time:1 } );
			Tweener.addTween(Status, { scaleY:2, time:1 } );
		}
		
		public function onKeyDown(e:KeyboardEvent):void 
		{
			//Trzeba zapewnić, żeby powiększany status był na wierzchu
			var last:DisplayObject = getChildAt(numChildren - 1);
			if (last != Status)
				swapChildren(Status, last);
			Status.visible = true;
			
					
			//trace(e.toString());
			if (e.charCode == 115 || e.charCode == 119)// s albo w
			{
				stage.frameRate--;
				if (stage.frameRate < 1.0)
					stage.frameRate = 1; //Najwolniej	
				Status.text = stage.frameRate.toString() + ' frm/s';	
				Status.textColor = Math.random() * 0xffffff;
				Status.alpha = 1;
				Status.scaleX = 1;
				Status.scaleY = 1;
				Status.y = height - Status.height;
				Tweener.addTween(Status, { y:(height - Status.height*3), time:1 } );
				Tweener.addTween(Status, { alpha:0,delay:0.5, time:1 } );
				Tweener.addTween(Status, { scaleX:3, time:1 } );
				Tweener.addTween(Status, { scaleY:3, time:1 } );
				
				trace("slover ", stage.frameRate);
			}
			else
			if (e.charCode == 102 || e.charCode == 112)//f albo p
			{
				stage.frameRate++;
				Status.text = stage.frameRate.toString() + ' frm/s';	
				Status.textColor = Math.random() * 0xffffff;
				Status.alpha = 1;
				Status.scaleX = 1;
				Status.scaleY = 1;
				Status.y = height - Status.height;
				Tweener.addTween(Status, { y:(height - Status.height*3), time:1 } );
				Tweener.addTween(Status, { alpha:0,delay:0.5, time:1 } );
				Tweener.addTween(Status, { scaleX:3, time:1 } );
				Tweener.addTween(Status, { scaleY:3, time:1 } );
				trace("faster ", stage.frameRate);
			}
		}
		
		public function timeStep(e:Event):void
		{
			++Klatka
			//Animacja dla głównego Sprite'a			
			trace(Klatka,' ',stage.frameRate);
		}
	}
	
}