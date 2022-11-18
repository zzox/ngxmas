package squidzz.actors.fighters;

import squidzz.actors.ActorTypes.ControlLock;

class Penguin extends Fighter {
	public function new(?Y:Float = 0, ?X:Float = 0) {
		super(X, Y, "penguin");
		maxVelocity.set(480, 960);
		drag.set(2000, 0);
	}

	override function jab() {
		if (touchingFloor) {
			animProtect("jab-ground-neutral");
		} else {
			animProtect("jab-air-neutral");
		}
		CONTROL_LOCK = ControlLock.ALL_LOCKED;
	}
}
