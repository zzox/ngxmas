package squidzz.ext;

import flixel.system.FlxAssets;
import lime.utils.AssetManifest;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import squidzz.ext.ListTypes;
#if deprecated
import sys.FileSystem;
#end

class Paths {
	public static var path_cache:Map<String, String> = new Map<String, String>();

	public static var extensions:Array<String> = [
		".json", ".png", ".xml", ".txt", ".ogg", ".ttf", ".world", ".tasc", ".ldtkl", ".aseprite", ".fnt"
	];

	public static function fill_path_cache() {
		#if old_paths
		var path_cache_json:PathCacheType = haxe.Json.parse(Utils.loadAssistString("assets/entries/file-paths.json"));
		for (key in path_cache_json.paths)
			path_cache.set(key.file, key.path);
		#end
	}

	public static function get(name:String, starting_path:String = "assets", safe:Bool = false):String {
		#if old_paths
		if (path_cache.get("chompy.png") == null)
			fill_path_cache();
		#end

		var clean_name:String = name.split("/")[name.split("/").length - 1];
		if (path_cache.exists(clean_name))
			return '${path_cache.get(clean_name)}/$clean_name';

		if (!safe)
			throw 'could not find ${name} from starting path ${starting_path}';

		return null;
	}

	public static function get_every_file_of_type(extension:String, path:String = "assets", ?file_must_contain:String = ""):Array<String> {
		var return_files:Array<String> = [];

		#if deprecated
		var dirs:Array<String> = [path];

		for (dir in dirs)
			for (file in FileSystem.readDirectory(dir)) {
				var file_path:String = '${dir}/${file}';
				if (file.indexOf(extension) != -1)
					return_files.push(file_path);
				if (FileSystem.isDirectory(file_path))
					dirs.push(file_path);
			}
		#else
		for (file in Paths.path_cache.keys()) {
			var file_must_contain_req:Bool = file_must_contain == "" || file.indexOf(file_must_contain) > -1;

			if (path_cache.get(file).indexOf(path) > -1 && file.indexOf(extension) > -1 && file_must_contain_req)
				return_files.push(file);
		}
		#end

		return return_files;
	}

	public static function file_exists(name:String):Bool
		#if deprecated
		return FileSystem.exists(name);
		#else
		return path_cache.get(name.split("/").last()) != null;
		#end

	public static function ldtk_filepath(path:String, extension:String):String
		return path.replace(extension, "").split("/").last();

	public static function find_nearest(name:String, extension:String, safe:Bool = false):String {
		var name_segments:Array<String> = name.split("-");

		for (n in 0...name_segments.length) {
			var test_name:String = name_segments.slice(0, n).join("-");
			var success:Bool = Paths.get(test_name + extension, true) != null;

			if (success)
				return test_name;
		}

		if (!safe)
			throw "no nearest for " + name;

		return null;
	}

	public static function recursive_file_operation(path:String, ext:String, file_operation) {
		#if old_paths
		for (file in Paths.path_cache.keys())
			if (file.indexOf(ext) > -1)
				if (Paths.path_cache.get(file).indexOf(path) > -1)
					file_operation('${Paths.path_cache.get(file)}/${file}');
		#else
		for (file in Paths.path_cache.keys()) {
			var file_path:String = Paths.path_cache.get(file);
			if (file_path != null && file_path.indexOf(path) == 0 && file.indexOf(ext) > -1)
				file_operation('${file_path}/${file}');
		}
		#end
	}
}

private typedef AssetData = {
	path:String,
	size:Int,
	type:AssetType,
	id:String,
	preload:Bool
};

class Manifest {
	static public var paths = new Array<String>();

	static public function init(onComplete:() -> Void):Void {
		#if html5
		final manifestHttp = new haxe.Http("manifest/default.json");
		manifestHttp.onError = function(msg) throw msg;
		manifestHttp.onData = function(data) {
			final lib = AssetManifest.parse(data, "./");
			for (asset in (cast lib.assets : Array<AssetData>))
				paths.push(asset.path);
			onComplete();
		}
		manifestHttp.request();
		#else
		for (asset in Assets.getLibrary("default").list(null))
			for (extension in Paths.extensions)
				if (asset.indexOf(extension) == -1) {
					var asset_name:String = asset.split("/").last();
					Paths.path_cache.set(asset_name, asset.substr(0, asset.length - asset_name.length - 1));
					break;
				}
		onComplete();
		#end
	}
}
