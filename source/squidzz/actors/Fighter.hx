package squidzz.actors;

import flixel.animation.FlxAnimationController;
import flixel.math.FlxMath;
import flixel.util.FlxDirectionFlags;
import squidzz.actors.ActorTypes.ControlLock;
import squidzz.actors.ActorTypes.JumpDirection;
import squidzz.actors.ActorTypes.JumpingStyle;
import squidzz.actors.ActorTypes.WalkDirection;
import squidzz.actors.projectiles.PenguinSummon;
import squidzz.display.FightingStage;
import squidzz.display.GuardBreakFX;
import squidzz.display.KO;
import squidzz.display.MatchUi;
import squidzz.display.RoundStartUI;
import squidzz.ext.AttackData;
import squidzz.ext.ListTypes.HitboxType;
import squidzz.ext.UUid.Uuid;
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

	var fighter_scale:FlxPoint = new FlxPoint();

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

	public var ai_mode:FighterAIMode = FighterAIMode.IDLE;

	var ai_state:FighterAIState = FighterAIState.STILL;
	var ai_tick:Int = 0;
	var ai_state_tick:Int = 0;

	var block_input:Bool = false;

	public static var SHIELD_BREAK_MAX:Int = 150;

	var shield_break:Int = 0;
	var shield_break_recovery_cd:Int = 0;

	var blocked_hitbox_ids:Array<String> = [];

	public var aiControlled:Bool = false;

	var round_control_locked:Bool = false;

	var original_position:FlxPoint;

	public function new(?X:Float, ?Y:Float, prefix:String) {
		super(X, Y, prefix);

		original_position = new FlxPoint(X, Y);

		visible = false;
	}

	public function reset_round() {
		setPosition(original_position.x, original_position.y);

		health = max_health;
		inv = 15;
		stun = 0;

		anim("idle");

		state = FighterState.IDLE;

		CONTROL_LOCK = ControlLock.FULL_CONTROL;

		prevInput = blankInput();

		reset_gravity();
		update_match_ui();
	}

	function ai_control(input:FrameInput):FrameInput {
		if (!aiControlled)
			return input;

		input = blankInput();
		ai_tick++;

		final oppDistance = Utils.getDistance(getMidpoint(), opponent.getMidpoint());

		final opponentLeft = getMidpoint().x > opponent.getMidpoint().x;

		if (--ai_state_tick < 0) {
			/*
				final rand = Math.random();

				if (rand < 0.75) {
					ai_state = FighterAIState.AGGRO;
				} else {
					ai_state = FighterAIState.RETREAT;
				}
			 */

			ai_state = oppDistance > 50 ? FighterAIState.AGGRO : FighterAIState.RETREAT;

			// new decisions every 30-90 frames
			ai_state_tick = Std.int(30 + Math.random() * 60);
		}

		switch (ai_state) {
			case FighterAIState.AGGRO:
				if (oppDistance < 50) {
					ai_mode = FighterAIMode.JAB;
				} else if (oppDistance < 250) {
					ai_mode = FighterAIMode.JAB;
					if (ran != null && ran.int(1, 2) == 1)
						input.set(opponentLeft ? "LEFT" : "RIGHT", true);
					else
						input.set(opponentLeft ? "RIGHT" : "LEFT", true);
				} else {
					ai_mode = FighterAIMode.WALK_FORWARDS;
				}
			case FighterAIState.RETREAT:
				ai_mode = FighterAIMode.WALK_BACKWARDS;
				if (oppDistance < 200) {
					ai_mode = FighterAIMode.JUMP;
				}

				// walk backwards always on rereat
				input.set(opponentLeft ? "RIGHT" : "LEFT", true);
			case FighterAIState.STILL:
				if (oppDistance < 150) {
					ai_state = FighterAIState.AGGRO;
				}
				return input;
		}

		switch (ai_mode) {
			case FighterAIMode.JUMP:
				if (ai_tick % 2 == 0)
					input.set("A", true);
			case FighterAIMode.JAB:
				if (ai_tick % 2 == 0)
					input.set("B", true);
			case FighterAIMode.WALK_BACKWARDS:
				input.set(opponentLeft ? "RIGHT" : "LEFT", true);
			case FighterAIMode.WALK_FORWARDS:
				input.set(opponentLeft ? "LEFT" : "RIGHT", true);
			default:
		}
		return input;
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		if (RoundStartUI.ref.ROUND_START_HOLD) {
			CONTROL_LOCK = ControlLock.ALL_LOCKED;
			round_control_locked = true;
		}

		if (round_control_locked && !RoundStartUI.ref.ROUND_START_HOLD) {
			CONTROL_LOCK = ControlLock.FULL_CONTROL;
		}

		update_offsets();

		input = ai_control(input);
		drag.set(touchingFloor ? traction : 0, 0);

		block_input = !flipX && pressed(input, Left) || flipX && pressed(input, Right);
		block_input = block_input && !(pressed(input, Right) && pressed(input, Left));

		inv--;
		if (touchingFloor) // remove if too much stun
			if (state != FighterState.BLOCKING || cur_anim.name == "block-loop")
				stun--;

		if (touchingFloor && cast(JUMP_DIRECTION, Int) > JumpDirection.NONE) {
			JUMP_DIRECTION = JumpDirection.NONE;
			velocity.x = 0;
		}

		WALKING_DIRECTION = WalkDirection.NONE;

		handle_fighter_states(delta, input);

		super.updateWithInputs(delta, input);
		prevInput = input;

		shield_break_recovery_cd--;
		if (shield_break_recovery_cd <= 0 && shield_break > 0) {
			shield_break--;
			update_match_ui();
		}
	}

	function jump_input_check(input:FrameInput, attack_cancelling:Bool = false)
		if (justPressed(input, Jump) && touchingFloor) {
			sstate(FighterState.JUMP_SQUAT);
			if (attack_cancelling)
				animProtect("jump-squat-attack-cancel");
		}

	function handle_fighter_states(delta:Float, input:FrameInput) {
		switch (cast(state, FighterState)) {
			case FighterState.IDLE | FighterState.JUMPING:
				current_attack_data = null;

				var acl:Float = 0.0;

				var hit_recovery:Bool = cur_anim.name == "hit-recover" && !cur_anim.finished;

				if (!hit_recovery)
					jump_input_check(input);

				if (touchingFloor && JUMP_DIRECTION == JumpDirection.NONE && !hit_recovery) {
					if (CONTROL_LOCK == ControlLock.FULL_CONTROL || CONTROL_LOCK == ControlLock.MOVE_OK) {
						if (pressed(input, Left))
							acl -= ground_speed / ground_rate;

						if (pressed(input, Right))
							acl += ground_speed / ground_rate;
					}

					if (acl != 0)
						WALKING_DIRECTION = acl > 0 && !flipX ? WalkDirection.FORWARDS : WalkDirection.BACKWARDS;

					var dir_multiplier:Float = WALKING_DIRECTION == WalkDirection.BACKWARDS ? backwards_ground_multiplier : 1;

					velocity.x += acl * dir_multiplier;
					velocity.x = FlxMath.bound(velocity.x, -ground_speed * dir_multiplier, ground_speed * dir_multiplier);

					flipX = opponent.getMidpoint().x < getMidpoint().x;
				}

				do_jump(delta, input);

				if (CONTROL_LOCK == ControlLock.FULL_CONTROL && !hit_recovery) {
					if (touchingFloor && cur_anim.name == "jump-down") {
						anim("jump-land");
						jump_land_sound();
						sstate(JUMP_LAND);
					}
					if (touchingFloor && (cur_anim.name != "jump-land" || cur_anim.finished)) {
						if (cast(WALKING_DIRECTION, Int) > WalkDirection.NEUTRAL)
							anim(WALKING_DIRECTION == WalkDirection.FORWARDS ? 'walk-forwards' : 'walk-backwards');
						else
							animProtect('idle');
					} else {
						var mid_jump_limit:Int = 10;

						var GOING_UP:Bool = velocity.y < -mid_jump_limit;
						var GOING_DOWN:Bool = velocity.y > mid_jump_limit;

						if (GOING_UP)
							animProtect('jump-up');
						else if (!GOING_UP && cur_anim.name != "jump-mid" && cur_anim.name != "jump-down")
							animProtect("jump-mid");
						else if (GOING_DOWN && cur_anim.name == "jump-mid" && cur_anim.finished)
							animProtect("jump-down");
					}
				}

				if (pressed(input, Attack))
					choose_attack(delta, input);

			case FighterState.JUMP_SQUAT:
				if (cur_anim.name.indexOf("jump-squat") < 0)
					animProtect("jump-squat");
				if (cur_anim.finished) {
					sstate(FighterState.JUMPING);
					add_jump_height();
					start_jump(delta, input);
					jump_sound();
				}

			case FighterState.JUMP_LAND:
				animProtect("jump-land");
				if (cur_anim.finished)
					sstate(FighterState.IDLE);

			case FighterState.ATTACKING:
				if ((attack_cancellable_check(current_attack_data) || current_attack_data.input_cancel_attack) && pressed(input, Attack))
					choose_attack(delta, input);

				if (attack_cancellable_check(current_attack_data) && current_attack_data.groundOnly)
					jump_input_check(input, true);

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
				do_block();

			case FighterState.DEFEATED:
				do_defeat();
		}
	}

	override public function fighter_hit_check(fighter:FightableObject, shield_broken:Bool = false) {
		if (fighter.team == team)
			return;

		var fighter_hitbox_data:HitboxType = fighter.current_hitbox_data();

		if (fighter_hitbox_data == null || blocked_hitbox_ids.indexOf(fighter_hitbox_data.melee_id) > -1)
			return;

		overlaps_fighter = collide_overlaps_fighter || FlxG.pixelPerfectOverlap(hurtbox_sheet, fighter.hurtbox_sheet, 10);

		var blocking:Bool = can_block() && block_input && !opponent_on_opposite_side() && state != FighterState.HIT;
		blocking = blocking && !shield_broken;

		if (FlxG.pixelPerfectOverlap(hurtbox_sheet, fighter.hitbox_sheet, 10) && inv <= 0) {
			make_hit_circle((mp().x + fighter.mp().x) / 2, (mp().y + fighter.mp().y) / 2, blocking);
			if (blocking) {
				sstate(FighterState.BLOCKING);

				stun = fighter_hitbox_data.stun;
				inv = fighter_hitbox_data.inv;

				velocity.copyFrom(get_appropriate_kb(fighter_hitbox_data).clone().scalePoint(kb_resistance));
				velocity.x *= -Utils.flipMod(this);
				velocity.y *= 0.5;

				fighter.velocity.scale(-1, 1);
				shield_break += Math.floor(fighter_hitbox_data.stun / 3 + fighter_hitbox_data.str);
				shield_break_recovery_cd = 60;
				group.hit_stop = 10;

				if (shield_break >= SHIELD_BREAK_MAX) {
					inv = 0;
					shield_break = 0;
					shield_break_recovery_cd = 0;
					blocking = false;
					fighter_hit_check(fighter, true);
					GuardBreakFX.ref.make_lightning(this);
				} else {
					blocked_hitbox_ids.push(fighter_hitbox_data.melee_id);
				}

				update_match_ui();
			} else {
				group.hit_stop = 15;

				sstate(FighterState.HIT);
				handle_fighter_states(0, blankInput());

				stun = fighter_hitbox_data.stun;
				inv = fighter_hitbox_data.inv;

				velocity.copyFrom(get_appropriate_kb(fighter_hitbox_data).clone().scalePoint(kb_resistance));
				velocity.x *= -Utils.flipMod(this);
				fighter.attack_hit_success = true;
				health -= fighter_hitbox_data.str;
				inv = 10;

				if (health < 0)
					health = 0;

				sstate(FighterState.HIT);
				anim("hit");
				update_match_ui();

				hit_sound();
				blocked_hitbox_ids = [];
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
		if (current_attack_data != null) {
			var input_result:AttackDataInputCheckResult = get_attack_from_input(current_attack_data, input);

			if (input_result.inputMatched)
				load_attack(input_result.attackData);
		}
	}

	public function load_attack(attack_data_to_load:AttackDataType):AttackDataType {
		attack_hit_success = false;
		if (attack_data_to_load.name != "ground" && attack_data_to_load.name != "air") {
			animProtect(attack_data_to_load.name);
			state = FighterState.ATTACKING;
			current_attack_data = attack_data_to_load;
			for (hitbox_data in current_attack_data.hitboxes)
				hitbox_data.melee_id = Uuid.short(); // potentially overkill
			return current_attack_data;
		}
		return null;
	}

	function can_block():Bool {
		return true;
	}

	function do_block() {
		if (cur_anim.name.indexOf("block") <= -1)
			anim("block-start");
		if (cur_anim.finished)
			anim("block-loop");
		if (stun <= 0 && cur_anim.name == "block-loop")
			sstate(FighterState.IDLE);
	}

	function do_defeat() {
		inv = 999;
		if (touchingFloor) {
			animProtect("defeated");
			if (animation.finished) {
				KO.ref.fighter_defeat_animation_finished = true;
			}
		}
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

		for (summon in attackData.summons) {
			if (cur_sheet.isOnNewFrame
				&& summon.frames.indexOf(cur_anim.frameIndex) > -1
				&& (get_object_count(summon.name, team) < summon.max || summon.max == 0))
				make_projectile(summon.name);
		}

		for (sound in attackData.sounds)
			if (cur_sheet.isOnNewFrame && sound.frame == cur_anim.frameIndex)
				SoundPlayer.random_sound(sound.name, sound.min, sound.max);

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
						if (inputToCheck.flag_req != null
							&& (internal_flags.get(inputToCheck.flag_req) == false || internal_flags.get(inputToCheck.flag_req) == null)) {
							validInput = false;
							break;
						}
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

	/**Makes a projectile, override in characters*/
	function make_projectile(projectile_type:String)
		return;

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
		// never used but if it's in an old group, remove it
		super.set_group(group);

		for (sprite in sprite_atlas)
			sprite.set_group(group);
	}

	override public function animProtect(animation_name:String = ""):Bool {
		if (cur_anim.name != animation_name) {
			anim(animation_name);
			return true;
		}
		return false;
	}

	public function update_match_ui() {
		match_ui.healths[team - 1] = health;
		match_ui.max_healths[team - 1] = max_health;
		match_ui.shield_breaks[team - 1] = shield_break;
	}

	function add_jump_height()
		velocity.y = -jump_height;

	function opponent_on_opposite_side()
		return flipX && opponent.mp().x > mp().x || !flipX && opponent.mp().x < mp().x;

	function jump_sound()
		return;

	function hit_sound()
		return;

	function jump_land_sound()
		return;

	function block_sound()
		return;

	function css_sound()
		return;

	function ko_sound()
		return;

	function intro_sound()
		return;

	function win_sound(round:Int)
		return;
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
	var DEFEATED = "DEFEATED";
}

enum abstract FighterAIMode(String) to String {
	var IDLE = "IDLE";
	var JUMP = "JUMP";
	var WALK_BACKWARDS = "WALK-FORWARDS";
	var WALK_FORWARDS = "WALK-BACKWARDS";
	var JAB = "JAB";
}

enum abstract FighterAIState(String) to String {
	var STILL = "STILL";
	var AGGRO = "AGGRO";
	var RETREAT = "RETREAT";
}
