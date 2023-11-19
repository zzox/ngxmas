package squidzz.actors.fighters;

using StringTools;

class Snowman extends Fighter {
	public function new(?X:Float = 0, ?Y:Float = 0) {
		super(X, Y, "snowman");

		update_cur_sheet("idle");

		ground_speed = 350;
		air_speed = 175;
		traction = 1250;

		max_health = 1500;

		kb_resistance.set(0.9, 0.9);

		backwards_air_multiplier = backwards_ground_multiplier = 1;

		jump_height = 950; // good jump height
	}

	override function do_block() {
		super.do_block();
	}

	override function hit_sound()
		SoundPlayer.random_sound("joe schnoe getting hit grunt $", 1, 5);

	override function jump_sound()
		SoundPlayer.random_sound("joe schnoe jump $", 1, 3);

	override function jump_land_sound()
		SoundPlayer.random_sound("joe schnoe landing $", 1, 3);

	override function block_sound()
		SoundPlayer.sound("Joe_BLOCK");

	override function ko_sound()
		SoundPlayer.random_sound("joe schnoe ko % take $".replace("%", Std.string(ran.int(1, 2))), 1, 3);

	override function intro_sound()
		SoundPlayer.random_sound("joe schnoe intro % take $".replace("%", Std.string(ran.int(1, 2))), 1, 3);

	override function win_sound(round:Int)
		SoundPlayer.random_sound("joe schnoe round win % take $".replace("%", Std.string(round)), 1, 3);
}
