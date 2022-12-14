package squidzz.ext;

import flixel.math.FlxRandom;
import flixel.system.FlxSound;

using StringTools;

class SoundPlayer {
	static var ran:FlxRandom = new FlxRandom();

	public static function sound(name:String) {
		// trace("Playing " + name);
		#if hl
		var sound:FlxSound = FlxG.sound.play(Paths.get(name + ".ogg"));
		#elseif js
		var sound:FlxSound = FlxG.sound.play(Paths.get(name + ".mp3"));
		#end
		sound.play();
		// trace(sound);
	}

	public static function random_sound(name:String, min:Int, max:Int)
		sound(name.replace("$", Std.string(ran.int(min, max))));
}
