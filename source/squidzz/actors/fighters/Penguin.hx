package squidzz.actors.fighters;

import squidzz.actors.ActorTypes.ControlLock;

class Penguin extends Fighter {
	public function new(?Y:Float = 0, ?X:Float = 0) {
		super(X, Y, "penguin");

		loadAllFromAnimationSet(type);

		hitbox = new FlxSpriteExt();
		hitbox.loadAllFromAnimationSet('${type}-hitbox');
		hurtbox = new FlxSpriteExt();
		hurtbox.loadAllFromAnimationSet('${type}-hitbox');

		// maxVelocity.set(480, 960);
		maxVelocity.y = 960;
	}
}
