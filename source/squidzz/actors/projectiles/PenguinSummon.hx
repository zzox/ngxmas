package squidzz.actors.projectiles;

import squidzz.rollback.FlxRollbackGroup;

class PenguinSummon extends Projectile {
	var speed:Int = 500;

	var camera_offset:Int = 8;

	public function new(?X:Float, ?Y:Float, owner:Fighter) {
		super(X, Y, "penguin", owner);

		type = "penguin-summon";

		// flip based on side owner is of the stage NOT what dir they're facing - EDIT: nvm
		// flipX = owner.mp().x >= FlxG.camera.scroll.x + FlxG.camera.width / 2;
		flipX = owner.flipX;

		anim("summon-walk");

		add_self_to_group();

		acceleration.set(0, 1000);

		current_attack_data = AttackData.get_attack_by_name(prefix, "summon-walk");

		sstate(PenguinSummonState.IDLE);

		setPosition(!flipX ? FlxG.camera.minScrollX + camera_offset : FlxG.camera.maxScrollX - width - camera_offset, FlxRollbackGroup.FLOOR_Y - height);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		switch (cast(state, PenguinSummonState)) {
			case PenguinSummonState.IDLE:
				velocity.x = speed * Utils.flipMod(this);
				if (touchingWall && ttick() > 30)
					sstate(PenguinSummonState.BUMPED);
			case PenguinSummonState.BUMPED:
				anim('summon-hit');
				if (ttick() == 1) {
					velocity.set(-200 * Utils.flipMod(this), -500);
					y -= 20;
				}
				immovable = true;
				if (!isOnScreen()) {
					kill();
					visual.kill();
				}
		}

		super.updateWithInputs(delta, input);
	}

	override function fighter_hit_check(fighter:FightableObject, shield_broken:Bool = false) {
		if (state == PenguinSummonState.BUMPED || fighter.team == team)
			return;

		if (FlxG.pixelPerfectOverlap(hurtbox_sheet, fighter.hitbox_sheet, 10) || FlxG.pixelPerfectOverlap(hurtbox, fighter.hurtbox, 10)) {
			sstate(PenguinSummonState.BUMPED);
		}
	}
}

enum abstract PenguinSummonState(String) to String {
	var IDLE = "IDLE";
	var BUMPED = "BUMPED";
}
