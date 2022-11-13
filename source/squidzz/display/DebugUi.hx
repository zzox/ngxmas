package squidzz.display;

import flixel.group.FlxGroup;
import flixel.text.FlxText;
import squidzz.conn.Connection;
import squidzz.states.MatchState;

class DebugUi extends FlxGroup {
    var roomId:FlxText;
    var ping:FlxText;
    var frameNum:FlxText;
    var numFrames:FlxText;
    var numFramesBehind:FlxText;
    var isHalted:FlxText;
    var scene:MatchState;

    public function new (scene:MatchState) {
        super();

        add(roomId = new FlxText(16, 16));
        add(ping = new FlxText(16, 32));
        add(frameNum = new FlxText(16, 48));
        add(numFrames = new FlxText(16, 64));
        add(numFramesBehind = new FlxText(16, 80));
        add(isHalted = new FlxText(16, 96));

        this.scene = scene;
    }

    override function update (delta:Float) {
        roomId.text = 'room: ' + Connection.inst.roomId;
        ping.text = 'ping: ${Connection.inst.pingTime}ms';
        frameNum.text = 'frame: ' + scene.rollback.currentFrame;
        numFrames.text = 'unconfirmed frames: ' + scene.rollback.frames.length;
        numFramesBehind.text = 'frames behind: ' + scene.rollback.futureRemotes.length;
        isHalted.text = 'frames behind: ' + scene.rollback.isHalted;
    }
}
