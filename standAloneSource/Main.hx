package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.system.debug.log.LogStyle;
import squidzz.ext.AttackData;
import squidzz.ext.Lists;
import squidzz.ext.Paths;
import squidzz.states.CharacterSelect;
import squidzz.states.MatchState;
import squidzz.states.MenuState;
import squidzz.states.TestMatchState;

class Main extends openfl.display.Sprite {
	public static var DISABLE_SCREENSHAKE:Bool = false;
	public static var SKIP_MENU:Bool = true;
	public static var SHOW_HITBOX:Bool = true;

	#if volume
	static var base_volume:Int = Std.parseInt('${haxe.macro.Compiler.getDefine("volume")}');
	#else
	static var base_volume:Int = 50;
	#end

	public function new() {
		super();
		#if !old_paths
		Manifest.init(make_game);
		#else
		make_game();
		#end
	}

	function make_game() {
		Lists.init();
		AttackData.init();

		LogStyle.ERROR.errorSound = "assets/sounds/penguin says fuck";

		addChild(new FlxGame(960, 540, BootState, 60, 60, true));

		if (base_volume > -1)
			FlxG.sound.volume = base_volume / 100;
		base_volume = -1;

		LogStyle.ERROR.errorSound = null;
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

		#if test_cs
		Global.switchState(new CharacterSelect());
		#else
		Global.switchState(!Main.SKIP_MENU ? new MenuState() : new TestMatchState());
		#end
	}
}
