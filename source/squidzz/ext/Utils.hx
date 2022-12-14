package squidzz.ext;

import Array;
import Type.ValueType;
import Type.ValueType;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import haxe.Constraints.IMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import lime.utils.Assets;
import squidzz.ext.ListTypes.PathCacheType;

using flixel.util.FlxArrayUtil;

class Utils {
	public static function XMLloadAssist(path:String):Xml {
		var text:String = Assets.getText(path);
		text = StringTools.replace(text, "/n", "&#xA;");
		text = StringTools.replace(text, "<&#xA;", "</n");
		return Xml.parse(text);
	}

	/*
	 * Animation int array created using string of comma seperated frames
	 * xTy = from x to y, takes r as optional form xTyRz to repeat z times
	 * xHy = hold x, y times
	 * ex: "0t2r2, 3h2" returns [0, 1, 2, 0, 1, 2, 3, 3, 3]
	 */
	public static function animFromString(animString:String):Array<Int> {
		if (animString == null || animString == "")
			return null;
		var frames:Array<Int> = [];
		var framesGroup:Array<String> = StringTools.replace(animString, " ", "").toLowerCase().split(",");
		if (framesGroup.length <= 0)
			framesGroup = [animString];
		for (f in framesGroup) {
			if (f.indexOf("h") > -1) { // hold/repeat frames
				var split:Array<String> = f.split("h"); // 0 = frame, 1 = hold frame multiplier so 1h5 is 1 hold 5 i.e. repeat 5 times
				frames = frames.concat(Utils.arrayR([Std.parseInt(split[0])], Std.parseInt(split[1])));
			} else if (f.indexOf("t") > -1) { // from x to y frames
				var repeats:Int = 1;
				if (f.indexOf("r") != -1)
					repeats = Std.parseInt(f.substring(f.indexOf("r") + 1, f.length)); // add rInt at the end to repeat Int times
				f = StringTools.replace(f, "r", "t");
				for (i in 0...repeats) {
					var split:Array<String> = f.split("t"); // 0 = first frame, 1 = last frame so 1t5 is 1 to 5
					frames = frames.concat(Utils.array(Std.parseInt(split[0]), Std.parseInt(split[1])));
				}
			} else {
				frames.push(Std.parseInt(f));
			}
		}
		return frames;
	}

	/*
	 * Alias for animFromString
	 */
	public static function anim(animString:String):Array<Int> {
		return animFromString(animString);
	}

	/*
	 * Creates FlxSpriteExt, attaches animation, and plays it automatically if autoPlay == true
	 */
	public static function animSprite(?X:Int = 0, Y:Int = 0, graphic:FlxGraphicAsset, animString:String, fps:Int, looped:Bool = true,
			autoPlay:Bool = true):FlxSpriteExt {
		var frames:Array<Int> = anim(animString);
		var maxFrame:Int = 0;

		for (f in frames) {
			if (f >= maxFrame)
				maxFrame = f + 1;
		}

		var sprite:FlxSpriteExt = new FlxSpriteExt(X, Y);
		sprite.loadGraphic(graphic);
		sprite.loadGraphic(graphic, true, Math.floor(sprite.width / maxFrame), Math.floor(sprite.height));
		sprite.animation.add("play", frames, fps, looped);

		if (autoPlay)
			sprite.animation.play("play");

		return sprite;
	}

	public static function ms_to_frames_per_second(input:String):Int
		return input.indexOf("ms") > -1 ? Math.round(1000 / Std.parseInt(input.split("ms")[0])) : Std.parseInt(input);

	public static function array(start:Int, end:Int):Array<Int> {
		var a:Array<Int> = [];
		if (start < end) {
			for (i in start...(end + 1)) {
				a.push(i);
			}
		} else {
			for (i in(end + 1)...start) {
				a.push(i);
			}
		}
		return a;
	}

	/*
	 * Creates repeating array that duplicates 'toRepeat', 'repeat' times
	 */
	public static function arrayR(toRepeat:Array<Int>, repeats:Int):Array<Int> {
		var a:Array<Int> = [];
		for (i in 0...repeats) {
			for (c in toRepeat) {
				a.push(c);
			}
		}
		return a;
	}

	/**
	 * Get distance between two points
	 * @param P1 point 1
	 * @param P2 point 2
	 * @return distance between two points
	 */
	public static function getDistance(P1:FlxPoint, P2:FlxPoint):Float {
		var XX:Float = P2.x - P1.x;
		var YY:Float = P2.y - P1.y;
		return Math.sqrt(XX * XX + YY * YY);
	}

	/**
	 * Get distance between two sprite midpoints
	 * @param S1 sprite 1
	 * @param S2 sprite 2
	 * @return distance between two points
	 */
	public static function getDistanceM(S1:FlxSprite, S2:FlxSprite):Float {
		return getDistance(S1.getMidpoint(FlxPoint.weak()), S2.getMidpoint(FlxPoint.weak()));
	}

	/**
	 * Shakes the camera according to some handy presets
	 * @param preset 
	 */
	public static function shake(preset:String = "damage") {
		if (Main.DISABLE_SCREENSHAKE)
			return;

		var intensity:Float = 0;
		var time:Float = 0;

		switch (preset) {
			case "damage":
				intensity = 0.025;
				time = 0.1;
			case "damagelight":
				intensity = 0.01;
				time = 0.025;
			case "groundpound":
				intensity = 0.03;
				time = 0.2;
			case "explosion":
				intensity = 0.025;
				time = 0.225;
			case "light":
				shake("damagelight");
		}

		if (intensity != 0 && time != 0)
			FlxG.camera.shake(intensity, time);
	}

	/**
	 * Takes text and auto formats it
	 * @param text the FlxText to format
	 * @param alignment alignment i.e. 'center' 'left' 'right'
	 * @param color text color
	 * @param outline use an outline or not
	 * @return FlxText formatted text
	 */
	public static function formatText(text:FlxText, alignment:String = "left", color:Int = FlxColor.WHITE, outline:Bool = false, ?font_path:String,
			?font_size:Int):FlxText {
		var font:String = font_path != null ? "assets/fonts/6px-Normal.ttf" : font_path;
		var font_size:Int = font_size != null ? font_size : 36;

		if (outline)
			text.setFormat(font, font_size, color, alignment, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		else
			text.setFormat(font, font_size, color, alignment);

		#if flash
		text.x += 1;
		text.y += 1;
		#end

		return text;
	}

	/**
	 * converts time in frames to minute, second, and frames (not nano seconds)
	 * @param time input time in frames
	 * @return String time formatted as 00:00:00
	 */
	public static function toTimer(time:Int):String {
		var minute:Int = Math.floor(time / (60 * 60));
		var second:Int = Math.floor((time / 60) % 60);
		var nano:Int = Math.floor(time % 60 / 60 * 100);
		var minutes:String = minute + "";
		var seconds:String = second + "";
		var nanos:String = nano + "";
		if (minute < 10)
			minutes = "0" + minutes;
		if (second < 10)
			seconds = "0" + seconds;
		if (nano < 10)
			nanos = "0" + nanos;
		return minutes + ":" + seconds + ":" + nanos;
	}

	static var current_id_total:Int = 25600;

	/**
	 * Just gets an unused id
	 * @return Int a new id
	 */
	public static function get_unused_id():Int {
		current_id_total++;
		return current_id_total;
	}

	/**
	 * Good for UI aligning, moves and traces the position, just toss this in update()
	 * @param object object to move around
	 */
	public static function move_and_trace(?name:String, object:FlxObject, ?relative_object:FlxObject) {
		var old_position:FlxPoint = object.getPosition(FlxPoint.weak());

		if (FlxG.keys.anyJustPressed(["LEFT"]))
			object.x--;
		if (FlxG.keys.anyJustPressed(["RIGHT"]))
			object.x++;
		if (FlxG.keys.anyJustPressed(["UP"]))
			object.y--;
		if (FlxG.keys.anyJustPressed(["DOWN"]))
			object.y++;

		var pos:FlxPoint = object.getPosition(FlxPoint.weak());
		if (relative_object != null)
			pos.subtract(relative_object.x, relative_object.y);

		if (old_position.x != object.x || old_position.y != object.y)
			trace('New \'{$name}\' position: (${pos.x} , ${pos.y})');
	}

	public static function loadAssistString(path:String):String
		return Assets.getText(path);

	/*returns a multiplier based on whether v is flipped*/
	public static function flipMod(v:FlxSprite):Int
		return v.flipX ? -1 : 1;
}

/**
 * credits to thomasuster
 */
class Cloner {
	var cache:ObjectMap<Dynamic, Dynamic>;
	var classHandles:Map<String, Dynamic->Dynamic>;
	var stringMapCloner:MapCloner<String>;
	var intMapCloner:MapCloner<Int>;

	public function new():Void {
		stringMapCloner = new MapCloner(this, StringMap);
		intMapCloner = new MapCloner(this, IntMap);
		classHandles = new Map<String, Dynamic->Dynamic>();
		classHandles.set('String', returnString);
		classHandles.set('Array', cloneArray);
		classHandles.set('haxe.ds.StringMap', stringMapCloner.clone);
		classHandles.set('haxe.ds.IntMap', intMapCloner.clone);
	}

	function returnString(v:String):String {
		return v;
	}

	public function clone<T>(v:T):T {
		cache = new ObjectMap<Dynamic, Dynamic>();
		var outcome:T = _clone(v);
		cache = null;
		return outcome;
	}

	public function _clone<T>(v:T):T {
		#if js
		if (Std.is(v, String))
			return v;
		#end

		#if neko
		try {
			if (Type.getClassName(cast v) != null)
				return v;
		} catch (e:Dynamic) {}
		#else
		if (Type.getClassName(cast v) != null)
			return v;
		#end
		switch (Type.typeof(v)) {
			case TNull:
				return null;
			case TInt:
				return v;
			case TFloat:
				return v;
			case TBool:
				return v;
			case TObject:
				return handleAnonymous(v);
			case TFunction:
				return null;
			case TClass(c):
				if (!cache.exists(v))
					cache.set(v, handleClass(c, v));
				return cache.get(v);
			case TEnum(e):
				return v;
			case TUnknown:
				return null;
		}
	}

	function handleAnonymous(v:Dynamic):Dynamic {
		var properties:Array<String> = Reflect.fields(v);
		var anonymous:Dynamic = {};
		for (i in 0...properties.length) {
			var property:String = properties[i];
			Reflect.setField(anonymous, property, _clone(Reflect.getProperty(v, property)));
		}
		return anonymous;
	}

	function handleClass<T>(c:Class<T>, inValue:T):T {
		var handle:T->T = classHandles.get(Type.getClassName(c));
		if (handle == null)
			handle = cloneClass;
		return handle(inValue);
	}

	public function cloneArray<T>(inValue:Array<T>):Array<T> {
		var array:Array<T> = inValue.copy();
		for (i in 0...array.length)
			array[i] = Reflect.copy(array[i]);
		return array;
	}

	function cloneClass<T>(inValue:T):T {
		var outValue:T = Type.createEmptyInstance(Type.getClass(inValue));
		var fields:Array<String> = Reflect.fields(inValue);
		for (i in 0...fields.length) {
			var field = fields[i];
			var property = Reflect.getProperty(inValue, field);
			Reflect.setField(outValue, field, _clone(property));
		}
		return outValue;
	}
}

class MapCloner<K> {
	var cloner:Cloner;
	var type:Class<IMap<K, Dynamic>>;
	var noArgs:Array<Dynamic>;

	public function new(cloner:Cloner, type:Class<IMap<K, Dynamic>>):Void {
		this.cloner = cloner;
		this.type = type;
		noArgs = [];
	}

	public function clone<K, Dynamic>(inValue:IMap<K, Dynamic>):IMap<K, Dynamic> {
		var inMap:IMap<K, Dynamic> = inValue;
		var map:IMap<K, Dynamic> = cast Type.createInstance(type, noArgs);
		for (key in inMap.keys()) {
			map.set(key, cloner._clone(inMap.get(key)));
		}
		return map;
	}
}
