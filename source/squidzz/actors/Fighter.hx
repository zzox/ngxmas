package squidzz.actors;

import flixel.animation.FlxAnimationController;
import flixel.math.FlxMath;
import flixel.util.FlxDirectionFlags;
import squidzz.actors.ActorTypes.ControlLock;
import squidzz.actors.ActorTypes.JumpDirection;
import squidzz.actors.ActorTypes.JumpingStyle;
import squidzz.actors.ActorTypes.WalkDirection;
import squidzz.display.FightingStage;
import squidzz.display.MatchUi;
import squidzz.ext.AttackData;
import squidzz.ext.ListTypes.HitboxType;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;

using Math;

// This means we're translation enums to strings to enums,
// but it makes us feel safer.
enum abstract FInput(String) to String {
	var Left = 'LEFT';
	var Right = 'RIGHT';
	var Up = 'UP';
	var Down = 'DOWN';
	var Jump = 'A';
	var Attack = 'B';
	var Special = '';
}

class Fighter extends FightableObject {
	var prevInput:FrameInput;

	public var opponent:Fighter;

	var JUMPING_STYLE:JumpingStyle = JumpingStyle.TRADITIONAL;
	var JUMP_DIRECTION:JumpDirection = JumpDirection.NONE;
	var WALKING_DIRECTION:WalkDirection = WalkDirection.NONE;

	var CONTROL_LOCK:ControlLock = ControlLock.FULL_CONTROL;

	var kb_resistance:FlxPoint = new FlxPoint(1, 1);

	var air_speed:Int = 125;
	var backwards_air_multiplier:Float = 1.25;

	var ground_speed:Int = 350;
	var backwards_ground_multiplier:Float = 1.25;

	var ground_rate:Int = 15;
	var gravity:Int = 2000;
	var traction:Int = 750;

	var max_health:Int = 1000;

	var jump_height:Int = 960;

	var attacking(get, default):Bool;
	var can_attack(get, default):Bool;

	public var attack_hit_success:Bool = false;

	public var ai_mode:FighterAIMode = FighterAIMode.IDLE;

	var ai_tick:Int = 0;

	var block_input:Bool = false;

	public function new(?Y:Float = 0, ?X:Float = 0, type:String) {
		super(X, Y);

		this.type = type;

		fill_sprite_atlas(type);

		prevInput = blankInput();

		state = FighterState.IDLE;

		CONTROL_LOCK = ControlLock.FULL_CONTROL;

		visual = new FlxRollbackActor();
		hurtbox = new FlxRollbackActor();
		hitbox = new FlxRollbackActor();

		visual.immovable = hurtbox.immovable = hitbox.immovable = true;

		visual.moves = hurtbox.moves = hitbox.moves = false;

		visible = false;

		reset_gravity();
	}

	function ai_control(input:FrameInput):FrameInput {
		if (ai_mode == FighterAIMode.IDLE)
			return input;

		input = blankInput();
		ai_tick++;

		switch (ai_mode) {
			case FighterAIMode.JUMP:
				if (ai_tick % 2 == 0)
					input.set("A", true);
			case FighterAIMode.JAB:
				if (ai_tick % 2 == 0)
					input.set("B", true);
			case FighterAIMode.WALK_BACKWARDS:
			case FighterAIMode.WALK_FORWARDS:
			default:
		}
		return input;
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		update_offsets();

		input = ai_control(input);
		drag.set(touchingFloor ? traction : 0, 0);

		block_input = !flipX && pressed(input, Left) || flipX && pressed(input, Right);
		block_input = block_input && !(pressed(input, Right) && pressed(input, Left));

		inv--;
		if (touchingFloor) // remove if too much stun
			if (state != FighterState.BLOCKING || cur_anim.name == "block-loop")
				stun--;

		hitbox.visible = hurtbox.visible = Main.SHOW_HITBOX;

		if (touchingFloor && cast(JUMP_DIRECTION, Int) > JumpDirection.NONE) {
			JUMP_DIRECTION = JumpDirection.NONE;
			velocity.x = 0;
		}

		WALKING_DIRECTION = WalkDirection.NONE;

		handle_fighter_states(delta, input);

		update_graphics(delta, input);
		super.updateWithInputs(delta, input);
		prevInput = input;
	}

	function handle_fighter_states(delta:Float, input:FrameInput) {
		switch (cast(state, FighterState)) {
			case FighterState.IDLE | FighterState.JUMPING:
				var acl:Float = 0.0;

				var hit_recovery:Bool = cur_anim.name == "hit-recover" && !cur_anim.finished;

				if (justPressed(input, Jump) && touchingFloor && !hit_recovery) {
					sstate(FighterState.JUMP_SQUAT);
				}

				if (touchingFloor && JUMP_DIRECTION == JumpDirection.NONE && !hit_recovery) {
					if (pressed(input, Left))
						acl -= ground_speed / ground_rate;

					if (pressed(input, Right))
						acl += ground_speed / ground_rate;

					if (acl != 0)
						WALKING_DIRECTION = acl > 0 && !flipX ? WalkDirection.FORWARDS : WalkDirection.BACKWARDS;

					var dir_multiplier:Float = WALKING_DIRECTION == WalkDirection.BACKWARDS ? backwards_ground_multiplier : 1;

					velocity.x += acl * dir_multiplier;
					velocity.x = FlxMath.bound(velocity.x, -ground_speed * dir_multiplier, ground_speed * dir_multiplier);

					flipX = opponent.getMidpoint().x < getMidpoint().x;
				}

				do_jump(delta, input);

				if (CONTROL_LOCK == ControlLock.FULL_CONTROL && !hit_recovery) {
					if (touchingFloor && cur_anim.name == "jump-down")
						anim("jump-land");
					if (touchingFloor && (cur_anim.name != "jump-land" || cur_anim.finished)) {
						if (cast(WALKING_DIRECTION, Int) > WalkDirection.NEUTRAL)
							anim(WALKING_DIRECTION == WalkDirection.FORWARDS ? 'walk-forwards' : 'walk-backwards');
						else
							anim('idle');
					} else {
						var mid_jump_limit:Int = 10;
						if (velocity.y < -mid_jump_limit)
							anim('jump-up');
						else if (Math.abs(velocity.y) < mid_jump_limit)
							anim("jump-mid");
						else if (velocity.y > mid_jump_limit && cur_anim.finished)
							anim("jump-down");
					}
				}

				if (pressed(input, Attack))
					choose_attack(delta, input);

			case FighterState.JUMP_SQUAT:
				animProtect("jump-squat");
				if (cur_anim.finished) {
					sstate(FighterState.JUMPING);
					velocity.y = -jump_height;
					start_jump(delta, input);
				}

			case FighterState.JUMP_LAND:
				animProtect("jump-land");
				if (cur_anim.finished)
					sstate(FighterState.IDLE);

			case FighterState.ATTACKING:
				if ((attack_cancellable_check(current_attack_data) || current_attack_data.input_cancel_attack) && pressed(input, Attack))
					choose_attack(delta, input);

				if (current_attack_data != null) {
					var attack_finished:Bool = cur_anim.finished && cur_anim.name == current_attack_data.name;
					if (attack_finished && !auto_continuing_attack_check(current_attack_data)) {
						current_attack_data = null;
						state = FighterState.IDLE;
					} else {
						simulate_attack(current_attack_data, delta, input);
					}
				}

			case FighterState.HIT:
				anim("hit");
				if (stun <= 0 && touchingFloor) {
					anim("hit-recover");
					sstate(FighterState.IDLE);
				}
			case FighterState.KNOCKDOWN:
			// pass, not sure if we'll have this in the advent version, but this is a unique fall down state where you cannot take any damage but can't act
			case FighterState.BLOCKING:
				if (cur_anim.name.indexOf("block") <= -1)
					anim("block-start");
				if (cur_anim.finished)
					anim("block-loop");
				if (stun <= 0 && cur_anim.name == "block-loop")
					sstate(FighterState.IDLE);
		}
	}

	public function fighter_hit_check(fighter:Fighter) {
		var fighter_hitbox_data:HitboxType = fighter.current_hitbox_data();

		overlaps_fighter = FlxG.pixelPerfectOverlap(hurtbox, fighter.hurtbox, 10);

		if (fighter_hitbox_data == null)
			return;

		var blocking:Bool = block_input && !opponent_on_opposite_side() && state != FighterState.HIT;

		if (FlxG.pixelPerfectOverlap(hurtbox, fighter.hitbox, 10) && inv <= 0) {
			make_hit_circle((mp().x + fighter.mp().x) / 2, (mp().y + fighter.mp().y) / 2, blocking);
			if (blocking) {
				sstate(FighterState.BLOCKING);
				stun = fighter.current_attack_data.stun;
				velocity.copyFrom(get_appropriate_kb(fighter_hitbox_data).clone().scalePoint(kb_resistance));
				velocity.x *= -Utils.flipMod(this);

				fighter.velocity.scale(-1, 1);
				inv = 10;
			} else {
				stun = fighter.current_attack_data.stun;
				velocity.copyFrom(get_appropriate_kb(fighter_hitbox_data).clone().scalePoint(kb_resistance));
				velocity.x *= -Utils.flipMod(this);
				fighter.attack_hit_success = true;
				health -= fighter_hitbox_data.str;
				inv = 10;

				if (health < 0)
					health = 0;

				sstate(FighterState.HIT);
				update_match_ui();
			}
		}
	}

	function get_appropriate_kb(fighter_hitbox_data:HitboxType):FlxPoint {
		if (touchingFloor && (fighter_hitbox_data.kb_ground.x != 0 || fighter_hitbox_data.kb_ground.y != 0))
			return fighter_hitbox_data.kb_ground;

		if (!touchingFloor && (fighter_hitbox_data.kb_air.x != 0 || fighter_hitbox_data.kb_air.y != 0))
			return fighter_hitbox_data.kb_air;

		return fighter_hitbox_data.kb;
	}

	function attack_cancellable_check(attackData:AttackDataType):Bool {
		if (!attack_hit_success || attackData == null)
			return false;
		if (attackData.cancellableFrames.indexOf(cur_anim.frameIndex) > -1)
			return true;
		return false;
	}

	function reset_gravity()
		acceleration.y = gravity;

	function choose_attack(delta:Float, input:FrameInput) {
		if (current_attack_data == null && can_attack)
			current_attack_data = get_base_attack_data(current_attack_data != null && cur_anim.name == current_attack_data.name);
		var input_result:AttackDataInputCheckResult = get_attack_from_input(current_attack_data, input);

		if (input_result.inputMatched)
			load_attack(input_result.attackData);
	}

	function load_attack(attack_data_to_load:AttackDataType):AttackDataType {
		attack_hit_success = false;
		if (attack_data_to_load.name != "ground" && attack_data_to_load.name != "air") {
			animProtect(attack_data_to_load.name);
			state = FighterState.ATTACKING;
			current_attack_data = attack_data_to_load;
			return current_attack_data;
		}
		return null;
	}

	/**
	 * Handles most attack attributes/thrust/hitbox stuff
	 * @param attackData 
	 * @param delta 
	 * @param input 
	 */
	function simulate_attack(attackData:AttackDataType, delta:Float, input:FrameInput) {
		// velocity adjustments for directional holding
		var multi:Float = calculate_thrust_multiplier(input);

		for (thrust in attackData.thrust) {
			if (thrust.frames.indexOf(cur_anim.frameIndex) > -1 && (thrust.once && cur_sheet.isOnNewFrame || !thrust.once)) {
				var thrust_x:Float = thrust.x * multi;
				if (thrust.fixed.x != 0 || thrust.fixed.y != 0)
					velocity.scalePoint(thrust.fixed);
				velocity.set(velocity.x + thrust_x * Utils.flipMod(this), velocity.y + thrust.y);
				if (velocity.y < 0) {
					y--;
					touchingFloor = false;
				}
			}
		}

		for (attack_drag in attackData.drag)
			if (attack_drag.frames.indexOf(cur_anim.frameIndex) > -1)
				velocity.set(velocity.x * attack_drag.x, velocity.y * attack_drag.y);

		SUPER_ARMORED = attackData.super_armor.indexOf(cur_anim.frameIndex) > -1;

		// ground interrupt attack
		if (attackData.ground_cancel_attack.name != "" && touchingFloor) {
			if (attackData.ground_cancel_attack.frames == null
				|| attackData.ground_cancel_attack.frames.indexOf(cur_anim.frameIndex) > -1) {
				var new_attack:AttackDataType = AttackData.get_attack_by_name(type, attackData.ground_cancel_attack.name);
				load_attack(new_attack);
				simulate_attack(new_attack, delta, input);
			}
		}

		// wall interrupt attack
		if (attackData.wall_cancel_attack.name != "" && touchingWall) {
			if (attackData.wall_cancel_attack.frames == null || attackData.wall_cancel_attack.frames.indexOf(cur_anim.frameIndex) > -1) {
				var new_attack:AttackDataType = AttackData.get_attack_by_name(type, attackData.wall_cancel_attack.name);
				load_attack(new_attack);
				simulate_attack(new_attack, delta, input);
			}
		}

		// wall interrupt attack
		if (attackData.opponent_cancel_attack.name != "" && overlaps_fighter) {
			if (attackData.opponent_cancel_attack.frames == null
				|| attackData.opponent_cancel_attack.frames.indexOf(cur_anim.frameIndex) > -1) {
				var new_attack:AttackDataType = AttackData.get_attack_by_name(type, attackData.opponent_cancel_attack.name);
				load_attack(new_attack);
				simulate_attack(new_attack, delta, input);
			}
		}
	}

	function auto_continuing_attack_check(attackData:AttackDataType):Bool {
		var attack_homing_target:Fighter = null; // not used
		var auto_continue_tick:Int = 999; // also not used

		if (attackData.auto_continue.length <= 0)
			return false;

		for (a_con in attackData.auto_continue) {
			var lock_valid:Bool = (a_con.lock && attack_homing_target != null || !a_con.lock);
			var auto_continue_time_valid:Bool = cur_sheet.animation.finished && a_con.time == 0 || a_con.time > 0 && auto_continue_tick > a_con.time;

			if (lock_valid && auto_continue_time_valid) {
				var new_attack:AttackDataType = AttackData.get_attack_by_name(type, a_con.on_complete);
				load_attack(new_attack);
				return true;
			}
		}
		return false;
	}

	public function current_hitbox_data():HitboxType {
		if (current_attack_data != null)
			for (hitbox_data in current_attack_data.hitboxes)
				if (hitbox_data.frames.indexOf(cur_anim.frameIndex) > -1)
					return hitbox_data;
		return null;
	}

	/**
	 * Optional - attack thrust multiplier depending on direction holding
	 * @param input 
	 * @return Float
	 */
	function calculate_thrust_multiplier(input:FrameInput):Float {
		if (pressed(input, Right) && !flipX || pressed(input, Left) && flipX) // holding forward
			return 1.25;

		if (pressed(input, Right) && flipX || pressed(input, Left) && !flipX) // holding backward
			return 0.75;

		return 1;
	}

	function get_base_attack_data(change_animation:Bool = false) {
		var currentAttackName:String = "";

		if (touchingFloor) {
			currentAttackName = "ground";
			if (change_animation)
				anim("idle");
		} else if (!touchingFloor) {
			currentAttackName = "air";
			if (change_animation)
				animProtect("jump");
		}

		return AttackData.get_attack_by_name(type, currentAttackName);
	}

	function get_attack_from_input(attackDataToSearch:AttackDataType, input:FrameInput):AttackDataInputCheckResult {
		for (linkedAttackName in attackDataToSearch.attack_links) {
			var linkedAttackData:AttackDataType = AttackData.get_attack_by_name(type, linkedAttackName);
			var validInput:Bool = false;

			// input data validity check
			if (linkedAttackData.airOnly && !touchingFloor || linkedAttackData.groundOnly && touchingFloor) {
				for (inputArray in linkedAttackData.inputs) {
					validInput = true;
					for (inputToCheck in inputArray) {
						var DOWN_INPUT = inputToCheck.input == "down" && pressed(input, Down);
						var UP_INPUT = inputToCheck.input == "up" && pressed(input, Up);
						var FORWARD_INPUT = (inputToCheck.input == "forward" || inputToCheck.input == "forwards")
							&& (pressed(input, Right) && !flipX || pressed(input, Left) && flipX);
						var BACKWARD_INPUT = (inputToCheck.input == "backward" || inputToCheck.input == "backwards")
							&& (pressed(input, Right) && flipX || pressed(input, Left) && !flipX);
						var SIDEWAYS_INPUT = inputToCheck.input == "sideways" && (pressed(input, Right) || pressed(input, Left));
						var ATTACK_INPUT = inputToCheck.input == "attack" && (justPressed(input, Attack)); // this is a duplicate but here for futureproofing

						if (!DOWN_INPUT && !UP_INPUT && !FORWARD_INPUT && !BACKWARD_INPUT && !SIDEWAYS_INPUT && !ATTACK_INPUT) {
							validInput = false;
							break;
						}
					}
					if (validInput)
						break;
				}
			}

			if (validInput) {
				attackDataToSearch = linkedAttackData;

				return {
					attackData: attackDataToSearch,
					inputMatched: validInput
				};
			}
		}
		return {
			attackData: attackDataToSearch,
			inputMatched: false
		};
	}

	function start_jump(delta:Float, input:FrameInput) {
		if (JUMPING_STYLE == JumpingStyle.TRADITIONAL) {
			JUMP_DIRECTION = JumpDirection.NEUTRAL;
			if (pressed(input, Left))
				JUMP_DIRECTION = !flipX ? JumpDirection.FORWARDS : JumpDirection.BACKWARDS;
			else if (pressed(input, Right))
				JUMP_DIRECTION = !flipX ? JumpDirection.BACKWARDS : JumpDirection.FORWARDS;
		}
		touchingFloor = false;
	}

	function do_jump(delta:Float, input:FrameInput) {
		if (JUMP_DIRECTION == JumpDirection.NONE && state != FighterState.JUMP_SQUAT)
			return;

		var acl:Float = 0.0;

		if (JUMP_DIRECTION == JumpDirection.FORWARDS)
			acl += !flipX ? -air_speed : air_speed;

		if (JUMP_DIRECTION == JumpDirection.BACKWARDS)
			acl += !flipX ? air_speed : -air_speed;

		var dir_multiplier:Float = JUMP_DIRECTION == JumpDirection.BACKWARDS ? backwards_air_multiplier : 1;

		velocity.x += acl * dir_multiplier;
		velocity.x = FlxMath.bound(velocity.x, -air_speed * dir_multiplier, air_speed * dir_multiplier);
	}

	/**Receive a hit**/
	function get_hit(source:DamageSource)
		throw "Not implemented!";

	/**Spawns a damage source that matches -hitbox sprite**/
	function melee_damage_source()
		new DamageSource(x, y, hitbox);

	function pressed(input:FrameInput, dir:FInput) {
		// NOTE: just for development, remove in prod.
		// bad inputs from the peer would trigger this.
		#if dev
		if (!['LEFT', 'RIGHT', 'UP', 'DOWN', 'A', 'B'].contains(dir)) {
			throw 'bad input';
		}
		#end
		return input[dir];
	}

	function justPressed(input:FrameInput, dir:FInput) {
		#if dev
		if (!['LEFT', 'RIGHT', 'UP', 'DOWN', 'A', 'B'].contains(dir)) {
			throw 'bad input';
		}
		#end
		return input[dir] && !prevInput[dir];
	}

	function get_attacking():Bool
		return state == FighterState.ATTACKING;

	function get_can_attack():Bool
		return !attacking && (state == FighterState.IDLE || state == FighterState.JUMPING);

	override function set_group(group:FlxRollbackGroup) {
		for (h in [hitbox, hitbox_sheet, hurtbox, hurtbox_sheet])
			h.set_group(group);
		super.set_group(group);
	}

	override public function animProtect(animation_name:String = ""):Bool {
		if (cur_anim.name != animation_name) {
			anim(animation_name);
			return true;
		}
		return false;
	}

	public function reset_new_round() {
		health = max_health;
		update_match_ui();
	}

	public function update_match_ui() {
		match_ui.healths[team - 1] = health;
		match_ui.max_healths[team - 1] = max_health;
	}

	function opponent_on_opposite_side()
		return flipX && opponent.mp().x > mp().x || !flipX && opponent.mp().x < mp().x;
}

typedef AttackDataInputCheckResult = {
	var attackData:AttackDataType;
	var inputMatched:Bool;
}

enum abstract FighterState(String) to String {
	var IDLE = "IDLE";
	var JUMPING = "JUMPING";
	var JUMP_SQUAT = "JUMP-SQUAT";
	var JUMP_LAND = "JUMP-LAND";
	var ATTACKING = "ATTACKING";
	var HIT = "HIT";
	var KNOCKDOWN = "KNOCKDOWN";
	var BLOCKING = "BLOCKING";
}

enum abstract FighterAIMode(String) to String {
	var IDLE = "IDLE";
	var JUMP = "JUMP";
	var WALK_BACKWARDS = "WALK-FORWARDS";
	var WALK_FORWARDS = "WALK-BACKWARDS";
	var JAB = "JAB";
}
