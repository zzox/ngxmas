package squidzz.actors.snowman;

class Snowman extends Fighter {
	public function new(?Y:Float = 0, ?X:Float = 0) {
		super(X, Y, "snowman");

		fill_sprite_atlas(type);
		update_main_sheet("idle");

		maxVelocity.y = 960;
	}
}
