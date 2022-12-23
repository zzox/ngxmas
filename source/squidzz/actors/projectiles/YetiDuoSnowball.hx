package squidzz.actors.projectiles;

import squidzz.rollback.FlxRollbackGroup;

class YetiDuoSnowball extends Projectile {
	var speed:Int = 500;

	public function new(?X:Float, ?Y:Float, owner:Fighter) {
		super(X, Y, "duoYeti-snowball", owner);

		flipX = owner.flipX;

		anim("idle");

		add_self_to_group();

		acceleration.set(0, 500);

		set_team(owner.team);

		current_attack_data = AttackData.get_attack_by_name(owner.prefix, "snowball");

		sstate(YetiDuoSnowballState.IDLE);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		switch (cast(state, YetiDuoSnowballState)) {
			case YetiDuoSnowballState.IDLE:
				velocity.x = speed * Utils.flipMod(this);
				if (ttick() >= 15 && (touchingWall || touchingFloor))
					sstate(YetiDuoSnowballState.HIT);
			case YetiDuoSnowballState.HIT:
				if (ttick() == 1) {
					velocity.set(-200 * Utils.flipMod(this), -500);
					y -= 20;
				}
				acceleration.set(0, 1000);
				immovable = true;
				if (!isOnScreen())
					kill();
		}

		super.updateWithInputs(delta, input);
	}

	override function fighter_hit_check(fighter:FightableObject, shield_break:Bool = false) {
		if (state == YetiDuoSnowballState.HIT || fighter.team == team)
			return;

		if (FlxG.pixelPerfectOverlap(hurtbox, fighter.hurtbox, 10)) {
			sstate(YetiDuoSnowballState.HIT);

			acceleration.set(0, 600);
		}
	}
}

enum abstract YetiDuoSnowballState(String) to String {
	var IDLE = "IDLE";
	var HIT = "HIT";
}
