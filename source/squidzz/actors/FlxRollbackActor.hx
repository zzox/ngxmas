package squidzz.actors;

import flixel.FlxSprite;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;

class FlxRollbackActor extends FlxSpriteExt {
	public var touchingFloor:Bool = false;
	public var touchingWall:Bool = false;

	var group:FlxRollbackGroup;

	public function new(?X:Float, ?Y:Float, ?group:FlxRollbackGroup) {
		super(X, Y);
	}

	// remove the update method called by the scene.
	// weird that the input isn't being used here, but the child classes will.
	override function update(delta:Float) {}

	public function updateWithInputs(delta:Float, input:FrameInput) {
		super.update(delta);
	}

	public function set_group(group:FlxRollbackGroup)
		this.group = group;

	override function kill() {
		if (group != null)
			group.remove(this, true);
		super.kill();
	}
}
