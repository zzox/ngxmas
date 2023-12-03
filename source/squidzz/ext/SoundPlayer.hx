package squidzz.ext;

import flixel.math.FlxRandom;
import flixel.sound.FlxSound;

using StringTools;

class SoundPlayer {
	static var ran:FlxRandom = new FlxRandom();

	public static function sound(name:String, volume:Float = 1) {
		// trace("Playing " + name);
		#if !js
		var sound:FlxSound = FlxG.sound.play(Paths.get(name + ".ogg"), volume);
		#elseif js
		var sound:FlxSound = FlxG.sound.play(Paths.get(name + ".mp3"), volume);
		#end
		sound.play();
		// trace(sound);
	}

	public static function random_sound(name:String, min:Int, max:Int)
		sound(name.replace("$", Std.string(ran.int(min, max))));
}
