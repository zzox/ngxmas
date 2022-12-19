package squidzz.actors.snowman;

class Snowman extends Fighter {
	public function new(?Y:Float = 0, ?X:Float = 0) {
		super(X, Y, "snowman");

		fill_sprite_atlas(type);
		update_cur_sheet("idle");

		ground_speed = 250;
		air_speed = 175;

		backwards_air_multiplier = backwards_ground_multiplier = 1;

		maxVelocity.y = 960;
	}
}
