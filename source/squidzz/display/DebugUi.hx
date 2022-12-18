package squidzz.display;

import flixel.group.FlxGroup;
import flixel.text.FlxText;
import squidzz.states.MatchState;

class DebugUi extends FlxGroup {
	var roomId:FlxText;
	var ping:FlxText;
	var frameNum:FlxText;
	var numFrames:FlxText;
	var numFramesBehind:FlxText;
	var isHalted:FlxText;
	var pos:FlxText;
	var scene:MatchState;

	public function new(scene:MatchState) {
		super();

		add(roomId = new FlxText(16, 8, 0, '', 16));
		add(ping = new FlxText(16, 28, 0, '', 16));
		add(frameNum = new FlxText(16, 48, 0, '', 16));
		add(numFrames = new FlxText(16, 68, 0, '', 16));
		add(numFramesBehind = new FlxText(16, 88, 0, '', 16));
		add(isHalted = new FlxText(16, 108, 0, '', 16));
		add(pos = new FlxText(16, 128, 0, '', 16));

		forEachOfType(FlxText, (t) -> t.alpha = 0.5);

		this.scene = scene;
	}

	override function update(delta:Float) {
		#if js
		roomId.text = 'room: ' + Connection.inst.roomId;
		ping.text = 'ping: ${Connection.inst.pingTime}ms';
		#end
		frameNum.text = 'frame: ' + scene.rollback.currentFrame;
		numFrames.text = 'unconfirmed frames: ' + scene.rollback.frames.length;
		numFramesBehind.text = 'frames behind: ' + scene.rollback.futureRemotes.length;
		isHalted.text = 'halted: ' + scene.rollback.isHalted;
		pos.text = 'pos: p1 x:${scene.player1.x} y:${scene.player1.y} p2 x:${scene.player2.x} y:${scene.player2.y}';
	}
}
