package squidzz.ext;

import squidzz.ext.ListTypes.AnimDef;

class Lists {
	/**Every anim file*/
	static var anim_files:Array<String> = ["penguin_anims"];

	/** All the animation data*/
	public static var animSets:Map<String, AnimSetData> = new Map<String, AnimSetData>();

	static var base_animation_fps:Int = 12;

	function new() {}

	public static function init() {
		loadAnimationSets();
	}

	public static function recursive_file_operation(path:String, ext:String, file_operation) {
		#if sys
		for (file in FileSystem.readDirectory(path)) {
			var file_path:String = '${path}/${file}';
			if (file_path.indexOf(ext) > -1)
				file_operation(file_path);
			else
				FileSystem.isDirectory(file_path) ? recursive_file_operation(file_path, ext, file_operation) : false;
		}
		#elseif js
		for (file in Utils.path_cache.keys()) {
			trace(file, file.indexOf(ext), ext);
			if (file.indexOf(ext) > -1) {
				trace(Utils.path_cache.get(file));
				trace(Utils.path_cache.get(file).indexOf(path));
				if (Utils.path_cache.get(file).indexOf(path) > -1)
					file_operation(Utils.path_cache.get(file));
			}
		}
		#end
	}

	/***
	 * Animation Set Loading and Usage
	***/
	/**Loads all the animations from several xml files**/
	public static function loadAnimationSets() {
		recursive_file_operation("assets/data", "anims.xml", loadAnimationSet);
		#if sys
		var content:String = haxe.Json.stringify(animSets);
		sys.io.File.saveContent('animSets.json', content);
		#end
	}

	public static function loadAnimationSet(path:String) {
		var xml:Xml = Utils.XMLloadAssist(path);
		for (sset in xml.elementsNamed("root").next().elementsNamed("animSet")) {
			function create_set_with_image(image:String) {
				var allFrames:String = "";
				var animSet:AnimSetData = {
					image: image,
					animations: [],
					dimensions: new FlxPoint(),
					offset: new FlxPoint(-999, -999), // offset is now redundent
					offset_right: null,
					offset_left: null,
					flipOffset: new FlxPoint(-999, -999),
					hitbox: new FlxPoint(),
					maxFrame: 0,
					path: "",
					reverse_mod: false
				};

				var default_FPS:Int = sset.get("fps") == null ? 14 : Utils.ms_to_frames_per_second(sset.get("fps"));

				for (aanim in sset.elementsNamed("anim")) {
					var animDef:AnimDef = {
						name: "",
						frames: "",
						fps: default_FPS,
						looping: true,
						linked: ""
					};

					if (aanim.get("fps") != null)
						animDef.fps = Utils.ms_to_frames_per_second(aanim.get("fps"));
					if (aanim.get("looping") != null)
						animDef.looping = aanim.get("looping") == "true";
					if (aanim.get("linked") != null)
						animDef.linked = aanim.get("linked");
					if (aanim.get("link") != null)
						animDef.linked = aanim.get("link");

					animDef.name = aanim.get("name");
					animDef.frames = aanim.firstChild().toString();
					allFrames = allFrames + animDef.frames + ",";

					animSet.animations.push(animDef);
				}

				animSet.path = sset.get("path") != null ? StringTools.replace(sset.get("path"), "\\", "/") : "";

				if (sset.get("x") != null)
					animSet.offset.x = Std.parseFloat(sset.get("x"));

				if (sset.get("y") != null)
					animSet.offset.y = Std.parseFloat(sset.get("y"));

				if (sset.get("offset_left") != null) {
					var off:Array<String> = sset.get("offset_left").split(",");
					animSet.offset_left = new FlxPoint(Std.parseFloat(off[0]), Std.parseFloat(off[1]));
				}

				if (sset.get("offset_right") != null) {
					var off:Array<String> = sset.get("offset_right").split(",");
					animSet.offset_right = new FlxPoint(Std.parseFloat(off[0]), Std.parseFloat(off[1]));
				}

				if (sset.get("reverse") != null)
					animSet.reverse_mod = sset.get("reverse") == "true";

				if (sset.get("width") != null)
					animSet.dimensions.x = Std.parseFloat(sset.get("width"));

				if (sset.get("height") != null)
					animSet.dimensions.y = Std.parseFloat(sset.get("height"));

				if (sset.get("hitbox") != null) {
					var hitbox:Array<String> = sset.get("hitbox").split(",");
					animSet.hitbox.set(Std.parseFloat(hitbox[0]), Std.parseFloat(hitbox[1]));
				}

				if (sset.get("flipOffset") != null) {
					var flipOffset:Array<String> = sset.get("flipOffset").split(",");
					animSet.flipOffset.set(Std.parseFloat(flipOffset[0]), Std.parseFloat(flipOffset[1]));
				}

				var maxFrame:Int = 0;

				allFrames = StringTools.replace(allFrames, "t", ",");

				for (frame in allFrames.split(",")) {
					if (frame.indexOf("h") > -1)
						frame = frame.substring(0, frame.indexOf("h"));

					var compFrame:Int = Std.parseInt(frame);

					if (compFrame > maxFrame) {
						maxFrame = compFrame;
					}
				}
				animSet.maxFrame = maxFrame;
				animSets.set(animSet.image, animSet);
			}

			for (image in sset.get("image").split("||"))
				create_set_with_image(image);
		}
	}

	public static function getAnimationSet(image:String):AnimSetData {
		return animSets.get(image);
	}
}
