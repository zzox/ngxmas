package squidzz.actors.fighters;

import squidzz.actors.projectiles.YetiDuoSnowball;
import squidzz.rollback.FlxRollbackGroup;

class YetiDuoGirl extends Fighter {
	var yeti:YetiDuoYeti;

	public function new(?X:Float = 0, ?Y:Float = 0) {
		super(X, Y, "duoYeti-girl");

		update_cur_sheet("idle");

		ground_speed = 250;
		backwards_ground_multiplier = 1;
		air_speed = 175;
		traction = 750;

		jump_height = 750; // bad jump height

		yeti = new YetiDuoYeti(X, Y, this);
	}

	override function simulate_attack(attackData:AttackDataType, delta:Float, input:FrameInput) {
		switch (attackData.name) {
			case "ground-neutral-yeti-jab":
				yeti.current_attack_data = yeti.load_attack(AttackData.get_attack_by_name(yeti.prefix, "ground-neutral-near"));
			case "ground-forward-yeti-send":
				yeti.go_to_point(new FlxPoint(x + 500, y));
			case "ground-forward-yeti-jab":
				yeti.current_attack_data = yeti.load_attack(AttackData.get_attack_by_name(yeti.prefix, "ground-neutral-near"));
			case "ground-backward-yeti-recall":
				yeti.follow_girl();
			case "ground-backward-yeti-kick":
				yeti.current_attack_data = yeti.load_attack(AttackData.get_attack_by_name(yeti.prefix, "back-kick"));
			case "ground-up-yeti-jump":
				yeti.force_jump(true);
			case "ground-down-yeti-yeet-success":
				if (yeti.current_attack_data == null || yeti.current_attack_data.name.indexOf("yeti-yeet") < -1)
					yeti.current_attack_data = yeti.load_attack(AttackData.get_attack_by_name(yeti.prefix, "yeti-yeet-success-grab-1"));
				if (yeti.current_attack_data.name != "yeti-yeet-success-grab-1")
					visual.visible = false;
				if (yeti.current_attack_data.name == "yeti-yeet-success-throw-2") {
					load_attack(AttackData.get_attack_by_name(prefix, "yeet-thrown"));
					visual.visible = true;
					if (!flipX)
						setPosition(yeti.visual.x - yeti.offset.x + 311, yeti.visual.y - yeti.offset.y - 32);
					else
						setPosition(yeti.visual.x - yeti.offset.x - 98, yeti.visual.y - yeti.offset.y - 32);
				}
			case "ground-down-yeti-yeet-fail":
				yeti.current_attack_data = yeti.load_attack(AttackData.get_attack_by_name(yeti.prefix, "yeti-yeet-fail"));
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

		if (justPressed(input, Jump))
			yeti.force_jump();

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
	var girl:YetiDuoGirl;
	var target_point:FlxPoint = new FlxPoint();
	var puppet_mode:String = PuppetControlMode.IDLE;

	var jump_command:Bool = false;
	var super_jump:Bool = false;

	public function new(?X:Float = 0, ?Y:Float = 0, girl:YetiDuoGirl) {
		super(X, Y, "duoYeti-yeti");
		update_cur_sheet("idle");

		visible = false;

		this.girl = girl;

		jump_height = 550; // shitty jump height
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		input = blankInput();
		switch (puppet_mode) {
			case PuppetControlMode.IDLE:
			// pass
			case PuppetControlMode.FOLLOW:
				girl.mp().x < mp().x ? input.set("LEFT", true) : input.set("RIGHT", true);
				if (Utils.getDistance(girl.mp(), mp()) < 64)
					puppet_mode = PuppetControlMode.IDLE;
			case PuppetControlMode.MOVE_TO_POINT:
				target_point.x < mp().x ? input.set("LEFT", true) : input.set("RIGHT", true);
				if (Utils.getDistance(target_point, mp()) < 32)
					puppet_mode = PuppetControlMode.IDLE;
		}
		if (jump_command) {
			jump_command = false;
			input.set("A", true);
		}
		super.updateWithInputs(delta, input);
	}

	public function go_to_point(new_point:FlxPoint) {
		target_point.copyFrom(new_point);
		puppet_mode = PuppetControlMode.MOVE_TO_POINT;
	}

	public function follow_girl() {
		puppet_mode = PuppetControlMode.FOLLOW;
	}

	override function update_match_ui()
		return;

	public function force_jump(super_jump:Bool = false) {
		jump_command = true;
		this.super_jump = super_jump;
	}

	override function add_jump_height() {
		velocity.y = -jump_height;
		if (super_jump)
			velocity.y *= 1.5;
		return;
	}
}

enum abstract PuppetControlMode(String) to String {
	var IDLE = "idle";
	var FOLLOW = "follow";
	var MOVE_TO_POINT = "move-to-point";
}
