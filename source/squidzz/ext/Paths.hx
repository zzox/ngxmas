package squidzz.ext;

import squidzz.ext.ListTypes.PathCacheType;

using StringTools;
using flixel.util.FlxArrayUtil;

#if sys
import sys.FileSystem;
#end

class Paths {
	public static var path_cache:Map<String, String> = new Map<String, String>();

	public static function fill_path_cache() {
		var path_cache_json:PathCacheType = haxe.Json.parse(Utils.loadAssistString("assets/entries/file-paths.json"));
		for (key in path_cache_json.paths)
			path_cache.set(key.file, key.path);
	}

	public static function get(name:String, starting_path:String = "assets", safe:Bool = false):String {
		var clean_name:String = name.split("/")[name.split("/").length - 1];
		if (path_cache.exists(clean_name))
			return '${path_cache.get(name)}/$name';

		var dirs:Array<String> = [starting_path];

		if (!safe)
			throw 'could not find ${name} from starting path ${starting_path}';

		return null;
	}

	public static function get_every_file_of_type(extension:String, path:String = "assets"):Array<String> {
		var return_files:Array<String> = [];

		#if sys
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
		for (file in path_cache.keys())
			if (path_cache.get(file).indexOf(path) > -1 && path_cache.get(file).indexOf(extension) > -1)
				return_files.push(file);
		#end

		return return_files;
	}

	public static function recursive_file_operation(path:String, ext:String, file_operation)
		for (file in path_cache.keys()) {
			if (file.indexOf(ext) > -1)
				if (path_cache.get(file).indexOf(path) > -1) {
					var full_path:String = path_cache.get(file) + "/" + file;
					file_operation(full_path);
				}
		}

	public static function file_exists(file_path:String):Bool {
		for (file in path_cache.keys())
			if (file_path == path_cache.get(file))
				return true;
		return false;
	}
}
