package squidzz.actors.fighters;

import squidzz.actors.projectiles.PenguinSummon;

class Penguin extends Fighter {
	public function new(?X:Float = 0, ?Y:Float = 0) {
		super(X, Y, "penguin");

		update_cur_sheet("idle");

		jump_height = 850; // aight jump height
	}

	override function make_projectile(projectile_type:String) {
		switch (projectile_type) {
			case "penguin-summon":
				new PenguinSummon(x, y, this);
		}
		super.make_projectile(projectile_type);
	}
}
