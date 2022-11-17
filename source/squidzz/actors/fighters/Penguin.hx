package squidzz.actors.fighters;

class Penguin extends Fighter {
	public function new(?Y:Float = 0, ?X:Float = 0) {
		super(X, Y, "penguin");
		maxVelocity.set(480, 960);
		drag.set(2000, 0);
	}
}
