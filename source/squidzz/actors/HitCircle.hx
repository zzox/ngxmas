package squidzz.actors;

import flixel.FlxSprite;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;

class HitCircle extends FlxRollbackActor {
	public function new(?X:Float, ?Y:Float, ?group:FlxRollbackGroup) {
		super(X, Y);
		loadAllFromAnimationSet("hit-circle");
		alpha = 0.75;
	}

	override function update(elapsed:Float) {
		scale.scale(1.1, 1.1);
		alpha -= 0.05;
		if (alpha <= 0)
			kill();

		super.update(elapsed);
	}
}
