package;

import flixel.FlxGame;
import squidzz.ext.AttackData;
import squidzz.ext.Lists;
import squidzz.ext.Paths;
import squidzz.states.MatchState;
import squidzz.states.MenuState;
import squidzz.states.TestMatchState;

class Main extends openfl.display.Sprite {
	public static var DISABLE_SCREENSHAKE:Bool = false;
	public static var SKIP_MENU:Bool = true;

	public function new() {
		super();
		Lists.init();
		AttackData.init();
		Paths.fill_path_cache();
		addChild(new FlxGame(960, 540, BootState, 60, 60, true));
	}
}

class BootState extends flixel.FlxState {
	override function create() {
		super.create();

		// Only needs to be called once
		Controls.init();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		Global.switchState(!Main.SKIP_MENU ? new MenuState() : new TestMatchState());
	}
}
