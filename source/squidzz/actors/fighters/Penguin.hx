package squidzz.actors.fighters;

class Penguin extends Fighter {
	public function new(?Y:Float = 0, ?X:Float = 0) {
		super(X, Y, "penguin");

		update_cur_sheet("idle");

		// maxVelocity.set(480, 960);
		maxVelocity.y = 960;
	}
}
