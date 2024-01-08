package squidzz.states;

import flixel.FlxCamera;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxAssets.FlxShader;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.util.FlxAxes;
import openfl.display.BitmapData;
import openfl.display.StageQuality;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
#if sys
import openfl.Lib;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import sys.io.FileOutput;
#end

class BaseState extends FlxState {
	var auto_start_gif:Bool = #if auto_start_gif true #else false #end;

	override function update(elapsed:Float) {
		#if gif
		if (FlxG.keys.anyJustPressed([FlxKey.F11]) || auto_start_gif) {
			start_snapping(30 * snap_seconds);
		}
		snap();
		#end

		super.update(elapsed);
	}

	#if gif
	public static var snap_state:SnapState = IDLE;

	private var snap_frames:Array<BitmapData> = [];

	/**How many frames left to capture*/
	private var snaps_remaining:Int = 0;

	private var snap_tick:Int = 0;

	/**60/snap_rate = gif capture rate*/
	private var snap_rate:Int = 2;

	/**Timestamp for file*/
	private var snap_timestamp:String = "";

	private var snap_shake:Map<Int, {x:Float, y:Float}> = [];

	private var snap_seconds:Int = haxe.macro.Compiler.getDefine("gif_time") == null ? 10 : Std.parseInt(haxe.macro.Compiler.getDefine("gif_time"));

	/**
		🫰
		(Starts snapping a gif)
	 */
	function start_snapping(frames_to_snap:Int) {
		if (snap_state != IDLE)
			return;

		snap_tick = 0;
		snap_frames = [];
		snaps_remaining = frames_to_snap;
		snap_state = SNAPPING;
		snap_shake.clear();

		var date:Date = Date.now();
		snap_timestamp = 'renaine_${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}_${date.getHours()}-${date.getMinutes()}-${date.getSeconds()}';

		#if gif_debug
		trace("START RECORDING GIF FOR " + snaps_remaining + "FRAMES");
		#end
	}

	function snap() {
		if (snap_state != SNAPPING)
			return;

		snap_tick++;
		if (snap_tick % snap_rate != 1)
			return;

		try {
			var image:BitmapData = new BitmapData(Math.floor(FlxG.camera.width), Math.floor(FlxG.camera.height), false, 0);
			image.draw(FlxG.camera.canvas);
			snap_frames.push(image);

			snap_shake.set(snap_frames.length - 1, {x: 0, y: 0}); // {x: FlxG.camera.flashSprite.x, y: FlxG.camera.flashSprite.y});
		} catch (e) {
			trace(e);
		}
		snaps_remaining--;

		//	trace('SNAPS REMAINING ' + snaps_remaining);

		if (snaps_remaining == 0)
			stop_snapping();
	}

	function stop_snapping() {
		#if gif_debug
		trace("GIF CAPTURED");
		#end

		#if sys
		var dir:String = get_gif_directory();
		sys.FileSystem.createDirectory('$dir/raw');
		sys.FileSystem.createDirectory('../../../export/gifs');
		sys.FileSystem.createDirectory('../../../export/gifs/mp4');

		for (frame in 0...snap_frames.length) {
			// trace('saving frame $frame to ' + getScreenGrabName(dir, frame));
			var b:ByteArray = snap_frames[frame].encode(new Rectangle(snap_shake.get(frame).x, snap_shake.get(frame).y, FlxG.camera.width,
				FlxG.camera.height), new openfl.display.PNGEncoderOptions());
			var fo:FileOutput = sys.io.File.write('$dir/raw/${snap_timestamp}_$frame.png', true);
			fo.writeBytes(b, 0, b.length);
			fo.close();
		}

		compile_gifs(33);

		while (sys.FileSystem.exists('$dir/raw'))
			command('rmdir "$dir/raw" /s /q');

		while (sys.FileSystem.exists(dir))
			command('rmdir "$dir" /s /q');

		// sys.FileSystem.deleteDirectory('$dir/raw'); (crashes for some reason welp)

		snap_state = IDLE;
		#end
	}

	function compile_gifs(fps:Int) {
		var file_name:String = '${snap_timestamp}';

		var cmd = "";

		cmd = 'ffmpeg -framerate ${fps} -i "gifs/raw/${snap_timestamp}_%d.png" -c:v libx264 -crf 0 ../../../export/gifs/mp4/$file_name.mp4';
		command(cmd);

		cmd = 'ffmpeg -i ../../../export/gifs/mp4/${file_name}.mp4 -vf "fps=${fps},scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "gifs/${file_name}_raw.gif"';
		command(cmd);

		cmd = 'gifsicle -O2 gifs/${file_name}_raw.gif -o ../../../export/gifs/${file_name}.gif';
		command(cmd);

		// magic = 'ffmpeg -i "gifs/raw/${snap_timestamp}_%d.png" -vf "fps=${fps},scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$output.gif"';
	}

	function command(cmd:String) {
		#if sys
		trace(cmd);
		Sys.command(cmd);
		#end
	}

	function get_gif_directory():String
		return "gifs";
	#end
}

private enum abstract SnapState(String) from String to String {
	var IDLE;
	var SNAPPING;
}
