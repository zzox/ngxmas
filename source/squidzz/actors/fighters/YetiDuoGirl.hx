package squidzz.actors.fighters;

import squidzz.actors.projectiles.YetiDuoSnowball;
import squidzz.rollback.FlxRollbackGroup;

class YetiDuoGirl extends Fighter {
	var yeti:YetiDuoYeti;

	public function new(?X:Float = 0, ?Y:Float = 0) {
		super(X, Y, "duoYeti-girl");

		update_cur_sheet("idle");

		// maxVelocity.set(480, 960);
		ground_speed = 250;
		backwards_ground_multiplier = 1;
		air_speed = 175;
		traction = 750;

		maxVelocity.y = 750;

		yeti = new YetiDuoYeti(X, Y);
	}

	override function simulate_attack(attackData:AttackDataType, delta:Float, input:FrameInput) {
		switch (attackData.name) {
			case "ground-neutral-yeti-jab":
				yeti.current_attack_data = yeti.load_attack(AttackData.get_attack_by_name(yeti.prefix, "ground-neutral-near"));
		}
		super.simulate_attack(attackData, delta, input);
	}

	override function set_group(group:FlxRollbackGroup) {
		super.set_group(group);
		yeti.set_group(group);

		group.remove(visual, true);
		yeti.add_self_to_group();
		group.add(visual);
	}

	override function set_team(team:Int) {
		super.set_team(team);
		yeti.set_team(team);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		yeti.opponent = opponent;
		if (overlaps(yeti))
			internal_flags.set("YETI_OVERLAP", true);
		else
			internal_flags.set("YETI_OVERLAP", false);

		super.updateWithInputs(delta, input);
	}

	override function make_projectile(projectile_type:String) {
		switch (projectile_type) {
			case "duoYeti-snowball":
				new YetiDuoSnowball(visual.x + 205 - visual.offset.x, visual.y + 55 - visual.offset.y, this);
		}
		super.make_projectile(projectile_type);
	}
}

class YetiDuoYeti extends Fighter {
	public function new(?X:Float = 0, ?Y:Float = 0) {
		super(X, Y, "duoYeti-yeti");
		update_cur_sheet("idle");

		visible = false;
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		super.updateWithInputs(delta, blankInput());
	}
}
