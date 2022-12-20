package squidzz.actors;

import flixel.animation.FlxAnimationController;
import flixel.math.FlxMath;
import flixel.util.FlxDirectionFlags;
import squidzz.actors.ActorTypes.ControlLock;
import squidzz.actors.ActorTypes.JumpDirection;
import squidzz.actors.ActorTypes.JumpingStyle;
import squidzz.actors.ActorTypes.WalkDirection;
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

class Fighter extends FlxRollbackActor {
	var prevInput:FrameInput;

	public var opponent:Fighter;

	// team 1 = player 1, team 2 = player 2, team 0 = neutral (not used)
	public var team:Int = 0;

	/**A seperated hurtbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hurtbox:FlxRollbackActor;

	/**A seperated hitbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hitbox:FlxRollbackActor;

	/**A seperated graphic sheet, this is the only visible sheet*/
	public var visual:FlxRollbackActor;

	public var hurtbox_sheet:FlxRollbackActor;
	public var hitbox_sheet:FlxRollbackActor;
	public var cur_sheet(get, default):FlxRollbackActor;

	var cur_anim(get, default):FlxAnimationController;

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

	var match_ui:MatchUi;

	/**Can't take damage inv > 0*/
	var inv:Int = 0;

	/**Can't act while stun > 0*/
	var stun:Int = 0;

	public var is_touching_floor(get, default):Bool;
	public var is_touching_wall(get, default):Bool;

	public var current_attack_data:AttackDataType;

	var attacking(get, default):Bool;
	var can_attack(get, default):Bool;

	/**No hit animation while active, but takes damage*/
	var SUPER_ARMORED:Bool = false;

	public var sprite_atlas:Map<String, FlxRollbackActor> = new Map<String, FlxRollbackActor>();

	public var attack_hit_success:Bool = false;

	public var ai_mode:FighterAIMode = FighterAIMode.IDLE;

	var ai_tick:Int = 0;

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

		inv--;
		stun--;

		hitbox.visible = hurtbox.visible = Main.SHOW_HITBOX;

		if (touchingFloor && cast(JUMP_DIRECTION, Int) > JumpDirection.NONE) {
			JUMP_DIRECTION = JumpDirection.NONE;
			velocity.x = 0;
		}

		WALKING_DIRECTION = WalkDirection.NONE;

		switch (cast(state, FighterState)) {
			case FighterState.IDLE | FighterState.JUMPING:
				var acl:Float = 0.0;

				if (justPressed(input, Jump) && touchingFloor) {
					sstate(FighterState.JUMP_SQUAT);
				}

				flipX = opponent.getMidpoint().x < getMidpoint().x;

				if (touchingFloor && JUMP_DIRECTION == JumpDirection.NONE) {
					if (pressed(input, Left))
						acl -= ground_speed / ground_rate;

					if (pressed(input, Right))
						acl += ground_speed / ground_rate;

					if (acl != 0)
						WALKING_DIRECTION = acl > 0 && !flipX ? WalkDirection.FORWARDS : WalkDirection.BACKWARDS;

					var dir_multiplier:Float = WALKING_DIRECTION == WalkDirection.BACKWARDS ? backwards_ground_multiplier : 1;

					velocity.x += acl * dir_multiplier;
					velocity.x = FlxMath.bound(velocity.x, -ground_speed * dir_multiplier, ground_speed * dir_multiplier);
				}

				do_jump(delta, input);

				if (CONTROL_LOCK == ControlLock.FULL_CONTROL) {
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
				if (attack_cancellable_check(current_attack_data) && pressed(input, Attack))
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
				if (stun <= 0 && touchingFloor)
					sstate(FighterState.IDLE);
			case FighterState.KNOCKDOWN:
				// pass, not sure if we'll have this in the advent version, but this is a unique fall down state where you cannot take any damage but can't act
		}

		update_graphics(delta, input);
		super.updateWithInputs(delta, input);
		prevInput = input;
	}

	public function fighter_hit_check(fighter:Fighter) {
		var fighter_hitbox_data:HitboxType = fighter.current_hitbox_data();

		if (fighter_hitbox_data == null)
			return;

		if (FlxG.pixelPerfectOverlap(hurtbox, fighter.hitbox, 10) && inv <= 0) {
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

	function get_appropriate_kb(fighter_hitbox_data:HitboxType):FlxPoint {
		if (touchingFloor && (fighter_hitbox_data.kb_ground.x != 0 || fighter_hitbox_data.kb_ground.y != 0))
			return fighter_hitbox_data.kb_ground;

		if (!touchingFloor && (fighter_hitbox_data.kb_air.x != 0 || fighter_hitbox_data.kb_air.y != 0))
			return fighter_hitbox_data.kb_air;

		return fighter_hitbox_data.kb;
	}

	function update_graphics(delta:Float, input:FrameInput) {
		cur_sheet.updateWithInputs(delta, input);

		hitbox_sheet.animation.frameIndex = cur_anim.frameIndex;
		hurtbox_sheet.animation.frameIndex = cur_anim.frameIndex;

		for (box in [visual, hitbox, hurtbox]) {
			box.velocity.copyFrom(velocity);
			box.acceleration.copyFrom(acceleration);
			box.flipX = flipX;
			box.alpha = box == visual ? 1 : 0.5;
		}

		hitbox_sheet.updateWithInputs(delta, input);
		hurtbox_sheet.updateWithInputs(delta, input);

		stamp_ext(visual, cur_sheet);
		stamp_ext(hitbox, hitbox_sheet);
		stamp_ext(hurtbox, hurtbox_sheet);

		update_offsets();
	}

	function attack_cancellable_check(attackData:AttackDataType):Bool {
		if (!attack_hit_success || attackData == null)
			return false;
		if (attackData.cancellableFrames.indexOf(cur_anim.frameIndex) > -1)
			return true;
		return false;
	}

	function stamp_ext(target_sprite:FlxSpriteExt, stamp_sprite:FlxSpriteExt) {
		if (target_sprite.graphic == null)
			target_sprite.makeGraphic(stamp_sprite.frameWidth, stamp_sprite.frameHeight, FlxColor.TRANSPARENT, true);
		else
			target_sprite.graphic.bitmap.fillRect(target_sprite.graphic.bitmap.rect, FlxColor.TRANSPARENT);

		target_sprite.stamp(stamp_sprite);
	}

	function update_offsets() {
		for (box in [visual, hitbox, hurtbox]) {
			box.offset.copyFrom(!flipX ? cur_sheet.offset_left : cur_sheet.offset_right);
			box.setPosition(x, y);
		}
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
				velocity.set(velocity.x + thrust_x * Utils.flipMod(this), velocity.y + thrust.y);
			}
		}

		for (attack_drag in attackData.drag)
			if (attack_drag.frames.indexOf(cur_anim.frameIndex) > -1)
				velocity.set(velocity.x * attack_drag.x, velocity.y * attack_drag.y);

		SUPER_ARMORED = attackData.super_armor.indexOf(cur_anim.frameIndex) > -1;

		// ground interrupt attack
		if (attackData.ground_cancel_attack != "" && touchingFloor) {
			var new_attack:AttackDataType = AttackData.get_attack_by_name(type, attackData.ground_cancel_attack);
			load_attack(new_attack);
			simulate_attack(new_attack, delta, input);
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

		if (is_touching_floor) {
			currentAttackName = "ground";
			if (change_animation)
				anim("idle");
		} else if (!is_touching_floor) {
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
			if (linkedAttackData.airOnly && !is_touching_floor || linkedAttackData.groundOnly && is_touching_floor) {
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
					if (validInput) {
						for (inputToRemove in inputArray)
							buffRemove(inputToRemove.input);
						break;
					}
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

	function buffRemove(input:String) {}

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

		if (JUMP_DIRECTION == JumpDirection.FORWARDS) {
			acl += !flipX ? -air_speed : air_speed;
		}
		if (JUMP_DIRECTION == JumpDirection.BACKWARDS) {
			acl += !flipX ? air_speed : -air_speed;
		}

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

	override function anim(s:String) {
		var prev_sheet:FlxSpriteExt = cur_sheet;

		update_cur_sheet(s);

		if (prev_sheet != cur_sheet) {
			if (cur_anim != null) {
				cur_anim.reset();
				hitbox_sheet.animation.reset();
				hurtbox_sheet.animation.reset();
			}
		}

		cur_sheet.anim(s);
	}

	function get_is_touching_floor():Bool
		return touchingFloor;

	function get_is_touching_wall():Bool
		return isTouching(FlxDirectionFlags.LEFT) || isTouching(FlxDirectionFlags.RIGHT);

	function get_cur_anim():FlxAnimationController
		return cur_sheet.animation;

	function get_cur_sheet():FlxRollbackActor
		return cur_sheet;

	function get_attacking():Bool
		return state == FighterState.ATTACKING;

	function get_can_attack():Bool
		return !attacking && (state == FighterState.IDLE || state == FighterState.JUMPING);

	function fill_sprite_atlas(prefix:String)
		for (animSet in Lists.animSets)
			if (animSet.image.indexOf(prefix) == 0)
				for (image in [animSet.image, '${animSet.image}-hitbox', '${animSet.image}-hurtbox']) {
					var sprite:FlxRollbackActor = new FlxRollbackActor();
					sprite.loadAllFromAnimationSet(image, animSet.image);
					sprite_atlas.set(image, sprite);
				}

	function find_anim_in_sprite_atlas(anim_name:String):FlxRollbackActor {
		for (sprite in sprite_atlas)
			for (anim in sprite.animation.getNameList())
				if (anim == anim_name)
					return sprite;
		return null;
	}

	function update_cur_sheet(anim_name:String) {
		cur_sheet = find_anim_in_sprite_atlas(anim_name);
		hitbox_sheet = sprite_atlas.get('${cur_sheet.loaded_image}-hitbox');
		hurtbox_sheet = sprite_atlas.get('${cur_sheet.loaded_image}-hurtbox');

		cur_sheet = find_anim_in_sprite_atlas(anim_name);

		if (graphic == null) {
			makeGraphic(cur_sheet.width.floor(), cur_sheet.height.floor(), FlxColor.WHITE);
		}
	}

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

	public function set_team(team:Int)
		this.team = team;

	public function set_match_ui(match_ui:MatchUi)
		this.match_ui = match_ui;

	public function reset_new_round() {
		health = max_health;
		update_match_ui();
	}

	public function update_match_ui() {
		match_ui.healths[team - 1] = health;
		match_ui.max_healths[team - 1] = max_health;
	}
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
}

enum abstract FighterAIMode(String) to String {
	var IDLE = "IDLE";
	var JUMP = "JUMP";
	var WALK_BACKWARDS = "WALK-FORWARDS";
	var WALK_FORWARDS = "WALK-BACKWARDS";
	var JAB = "JAB";
}
