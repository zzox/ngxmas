package squidzz.actors;

import flixel.FlxSprite;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;

class HitFX extends FlxRollbackActor {
	public function new(?X:Float, ?Y:Float, group:FlxRollbackGroup, blocked:Bool = false) {
		super(X, Y, group);

		set_group(group);

		if (!blocked)
			loadAllFromAnimationSet("hit-fx");
		else
			loadAllFromAnimationSet("snow-fx");

		anim("idle");

		group.add(this);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		if (animation.finished)
			kill();

		super.updateWithInputs(delta, input);
	}
}
