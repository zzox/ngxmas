package squidzz.actors.fighters;

class Snowman extends Fighter {
	public function new(?Y:Float = 0, ?X:Float = 0) {
		super(X, Y, "snowman");

		update_cur_sheet("idle");

		ground_speed = 350;
		air_speed = 175;
		traction = 1250;

		max_health = 1500;

		kb_resistance.set(0.9, 0.9);

		backwards_air_multiplier = backwards_ground_multiplier = 1;

		maxVelocity.y = 960;
	}
}
