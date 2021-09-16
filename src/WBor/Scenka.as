package WBor 
{
	import flash.display.*;
	import flash.events.Event;
	import flash.text.*;
	import flash.events.MouseEvent;
	import caurina.transitions.Tweener;
	
	
	/**
	 * "Scenka" służy jako klasa bazowa dla wyświetlania dowolnego modelu
	 * Implementuje powiekszanie i znamniejszanie w reakcji na "click" myszki
	 * oraz tymczasowe wyświetlanie tytułu.
	 * @author WBorkowski
	 */
	public class Scenka extends Sprite
	{
		//Domyślne i jednocześnie maksymalne rozmiary scenki
		static public var Default_width:Number = 1024;//Trzeba ręcznie zadbac, żeby były zgodne z ustawieniami dla projektu
		static public var Default_height:Number = 600;//Bo sprite.with i sprite.height zwraca użyte rozmiary, a nie calkowite
		
		//Domyślne wlaściwości kolorystyki scenek
		static public var BorderColor:uint = 0x0099FF;//Kolor brzegowej ramki
		static public var BackGradientType:String = GradientType.RADIAL/*RADIAL or LINEAR*/;//Typ gradientu wypełnienia
		static public var BackSpreadMethod:String = SpreadMethod.REFLECT;//Sposób powtarzania gradientu
		static public var BackColors:Array = [0x00AAFF, 0x0055FF];//Koloru budujące gradient
		static public var BackRatios:Array = [0x11, 0xFF];//Sposób rozłożenia kolorów w gradiencie
		static public var BackAlphas:Array = [1, 1];//Powinno być tyle jedeynek ile kolorów
		
		//Obsługa powiększania
		public var KeepRatio:Boolean = false;//Albo powiększa na całość, albo na największe przy zachowaniu proporcji
		public var Sleepable:Boolean = false;//Czy scenkę można zatrzymać gdy jest załonięta
		protected var SaveOnEnterFrame:Function = null;//Trzeba tu zapamiętać adres procedury OnEnterFrame żeby można ją było zastopować
		static protected var WszystkieScenki:Array = new Array();//Żeby można było pomniejszyć zasłonięte scenki i uśpić

		//Obsługa tytułu/podpowiedzi dla danej scenki
		public var Title:TextField;//Nazwa/podpowiedź danej scenki
		public var TitleSec:Number=1.0;//Ile czasu nazwa jest widoczna po najechaniu
		
		public function Scenka(iwidth:Number=0,iheight:Number=0,ititle:String="...set title for this...") 
		{
			WszystkieScenki[WszystkieScenki.length] = this;
		
			if (iwidth <= 0) iwidth = Default_width;
			if (iheight <= 0) iheight = Default_height;
			
			this.opaqueBackground = 0xFF0000;//Tylko do pokazywanie, że obrazek wyszedł za scenkę!
			graphics.lineStyle(0,BorderColor);
			graphics.beginGradientFill(BackGradientType,BackColors,BackAlphas,BackRatios,null,BackSpreadMethod);
			graphics.drawRect(0, 0, iwidth, iheight);//Aktywne "myszowo" tło scenki
			graphics.endFill();
			trace(ititle,' ',width, 'x', height);
			
			Title = new TextField();
			Title.autoSize = TextFieldAutoSize.LEFT;			
			Title.text = ititle;	
			Title.x = 1;
			Title.y = 1;
			Title.alpha = 0;
			//addChild(Title); Tytuł uwidacznia się dopiero, gdy najedzie się myszką na scenę
			
			useHandCursor = true; //Łapka a ne strzałka?
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseClick);
			addEventListener(MouseEvent.DOUBLE_CLICK, onMouseClick);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			//addEventListener(MouseEvent.MOUSE_OUT, onMouseOut); Nic nie robi w tej systuacji, ale mógłby...
		}
		
		
		// Odtąd własności i pola prywatne
		/////////////////////////////////////////////////////////////
		private var orix:Number;
		private var oriy:Number;
		internal var TweenFinish:uint = 0;
		
		protected function onMouseOver(e:MouseEvent):void
		{
			//trace('Mouse over');			
			try {
			removeChild(Title);//Hmmm... cekawe co się wtedy dzieje z działającymi Tweenerami 
			}
			catch (e:ArgumentError)
			{
				;//Po prostu ignoruje jak jeszcze nie było takiego
			}
			addChild(Title); //W ten sposób tytuł zawsze na wierzchu, chociaz to chyba zbyt mocny sposób
			Tweener.addTween(Title, { alpha:1, time:TitleSec/2 } );
			Tweener.addTween(Title, { alpha:0, delay:TitleSec/2, time:TitleSec/2 } );
		}
		
		protected function onMouseOut(e:MouseEvent):void
		{			
			//trace('Mouse out');
			//Tweener.addTween(Title, { alpha:0, time:0.33 } );
		}
		
		//protected SaveOnEnterFrame:function = null;
		
		private function MaximizeTweenComplete():void 
		{ 
			trace('Resize tweener completed: ', width, 'x', height);
			for (var i:uint; i < WszystkieScenki.length; i++)
			 if (	WszystkieScenki[i] != this && 
					WszystkieScenki[i].visible && 
					WszystkieScenki[i].Sleepable)
					{
						WszystkieScenki[i].visible = false;
						//Scenka(WszystkieScenki[i]).
					}
			this.TweenFinish = 0; 			
		}
		
		private function RestoreTweenComplete():void 
		{ 
			trace('Resize tweener completed: ', width, 'x', height);
			for (var i:uint; i < WszystkieScenki.length; i++)
			 if (	WszystkieScenki[i] != this && 
					(!WszystkieScenki[i].visible) )
					{
						WszystkieScenki[i].visible = true;
						//Scenka(WszystkieScenki[i]).h
					}
			this.TweenFinish = 0; 			
		}
		
		protected function onMouseClick(e:MouseEvent):void
		{
			//trace('Mouse click');
			if (scaleX <= 1 || scaleY <= 1)//Normalny rozmiar czyli będzie powiększanie
			{
				if (width < Default_width && height < Default_height && TweenFinish==0)
				{
					//Trzeba zapamiętac pozycje do przywrócenia
					orix = x;
					oriy = y;
					//Trzeba policzyć o ile powiększyć
					var ScaleForY:Number = Default_height / height;
					var ScaleForX:Number = Default_width / width;
					if (KeepRatio) //Jeśli trzeba, to wybieramy mniejsze skalowanie
					{
						if ( ScaleForY <  ScaleForX)
							ScaleForX = ScaleForY
						else
							ScaleForY = ScaleForX;
					}
					//I w jakim miejscu umieścić nowy brzeg
					var newx:Number = 0;
					var newy:Number = 0;
					if (KeepRatio) //Tylko wtedy róg inny 0,0
					{
						newx = (Default_width - width * ScaleForX) / 2;
						newy = (Default_height - height * ScaleForY) / 2;
					}
					//Trzeba zapewnić, żeby powiększany był na wierzchu
					var last:DisplayObject = parent.getChildAt(parent.numChildren-1);
					if(this!=last)
						parent.swapChildren(this, last);
					//Teraz trzeba zaplanowac akcję powiększania	
					Tweener.addTween(this, { x:newx, time:0.33 } );
					Tweener.addTween(this, { y:newy, time:0.33 } );
					Tweener.addTween(this, { scaleX:ScaleForX, time:0.33 } );TweenFinish = 330;
					Tweener.addTween(this, { scaleY:ScaleForY, time:0.33, onComplete:MaximizeTweenComplete});				
					//trace('Maximize ',Scale,'times (orix:',orix,' oriy:',oriy,')');
				}
				else
				{
					trace('Mouse click failed of maximize');
				}
			}
			else
			{
				if (TweenFinish == 0)
				{
					//Trzeba zaplanowac akcję pomniejszania
					Tweener.addTween(this, { x:orix, time:0.33 } );
					Tweener.addTween(this, { y:oriy, time:0.33 } );
					Tweener.addTween(this, { scaleX:1, time:0.33 } );TweenFinish = 330;
					Tweener.addTween(this, { scaleY:1, time:0.33 , onComplete:RestoreTweenComplete});					
					//trace('Restore(orix:',orix,' oriy:',oriy,')');
				}
				else
				{
					trace('Mouse click failed of restore');
				}
			}
		}
	}	
}