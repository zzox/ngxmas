package squidzz.actors;

import flixel.animation.FlxAnimationController;
import flixel.util.FlxDirection;
import flixel.util.FlxDirectionFlags;
import squidzz.actors.ActorTypes.ControlLock;
import squidzz.actors.ActorTypes.JumpDirection;
import squidzz.actors.ActorTypes.JumpingStyle;
import squidzz.actors.ActorTypes.WalkDirection;
import squidzz.ext.AttackData;
import squidzz.rollback.FrameInput;

// This means we're translation enums to strings to enums,
// but it makes us feel safer.
enum abstract FInput(String) to String {
	var Left = 'LEFT';
	var Right = 'RIGHT';
	var Up = 'UP';
	var Down = 'DOWN';
	var Attack = 'A';
	var Special = 'B';
}

class Fighter extends FlxRollbackActor {
	var prevInput:FrameInput;

	public var opponent:Fighter;

	/**A seperated hitbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hitbox:FlxSpriteExt;

	/**A seperated hurtbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hurtbox:FlxSpriteExt;

	var JUMPING_STYLE:JumpingStyle = JumpingStyle.TRADITIONAL;
	var JUMP_DIRECTION:JumpDirection = JumpDirection.NONE;
	var WALKING_DIRECTION:WalkDirection = WalkDirection.NONE;

	var CONTROL_LOCK:ControlLock = ControlLock.FULL_CONTROL;

	var air_speed:Int = 250;
	var ground_speed:Int = 1000;

	public var is_touching_floor(get, default):Bool;
	public var is_touching_wall(get, default):Bool;

	var current_attack_data:AttackDataType;

	var cur_anim(get, default):FlxAnimationController;
	var attacking(get, default):Bool;
	var can_attack(get, default):Bool;

	public function new(?Y:Float = 0, ?X:Float = 0, type:String) {
		super(X, Y);

		this.type = type;

		prevInput = blankInput();

		state = FighterState.IDLE;

		CONTROL_LOCK = ControlLock.FULL_CONTROL;
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		update_offsets();

		if (justPressed(input, Up) && touchingFloor) {
			start_jump(delta, input);
			velocity.y = -960;
		}

		if (touchingFloor && cast(JUMP_DIRECTION, Int) > JumpDirection.NONE) {
			JUMP_DIRECTION = JumpDirection.NONE;
			velocity.x = 0;
		}

		var acc:Float = 0.0;

		WALKING_DIRECTION = WalkDirection.NONE;

		if (touchingFloor && JUMP_DIRECTION == JumpDirection.NONE) {
			if (pressed(input, Left)) {
				acc -= ground_speed;
			}

			if (pressed(input, Right)) {
				acc += ground_speed;
			}

			WALKING_DIRECTION = acc > 0 && flipX ? WalkDirection.FORWARDS : WalkDirection.BACKWARDS;
		}

		acceleration.set(acc, 2000);

		do_jump(delta, input);

		if (state == FighterState.IDLE || state == FighterState.JUMPING)
			if (CONTROL_LOCK == ControlLock.FULL_CONTROL)
				if (touchingFloor) {
					if (acceleration.x != 0)
						anim(WALKING_DIRECTION == WalkDirection.FORWARDS ? 'walk-forwards' : 'walk-backwards');
					else
						anim('idle');
				} else
					anim('jump');

		flipX = opponent.getMidpoint().x > getMidpoint().x;

		if (state == FighterState.ATTACKING) {
			if (current_attack_data != null) {
				if (animation.finished && cur_anim.name == current_attack_data.name) {
					current_attack_data = null;
					state = FighterState.IDLE;
				}
			}
		}

		if (pressed(input, Attack))
			choose_attack(delta, input);

		super.updateWithInputs(delta, input);
		prevInput = input;
	}

	function choose_attack(delta:Float, input:FrameInput) {
		if (current_attack_data == null && can_attack)
			current_attack_data = get_base_attack_data(current_attack_data != null && cur_anim.name == current_attack_data.name);
		var input_result:AttackDataInputCheckResult = get_attack_from_input(current_attack_data, input);

		if (input_result.inputMatched) {
			current_attack_data = input_result.attackData;
			if (current_attack_data.name != "ground" && current_attack_data.name != "air") {
				animProtect(current_attack_data.name);
				state = FighterState.ATTACKING;
			}
		}
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
						var FORWARD_INPUT = inputToCheck.input == "forward"
							&& (pressed(input, Right) && !flipX || pressed(input, Left) && flipX);
						var BACKWARD_INPUT = inputToCheck.input == "backward"
							&& (pressed(input, Right) && flipX || pressed(input, Left) && !flipX);
						var SIDEWAYS_INPUT = inputToCheck.input == "sideways" && (pressed(input, Right) || pressed(input, Left));
						var ATTACK_INPUT = inputToCheck.input == "attack" && (pressed(input, Attack)); // this is a duplicate but here for futureproofing

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
		if (JUMP_DIRECTION == JumpDirection.NONE)
			return;

		var acc:Float = 0.0;

		if (JUMP_DIRECTION == JumpDirection.FORWARDS) {
			acc += !flipX ? -air_speed : air_speed;
		}
		if (JUMP_DIRECTION == JumpDirection.BACKWARDS) {
			acc += !flipX ? air_speed : -air_speed;
		}

		acceleration.set(acc, 2000);
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

	function update_offsets()
		offset.set(flipX ? offset_left.x : offset_right.x, flipX ? offset_left.y : offset_right.y);

	function get_is_touching_floor():Bool
		return touchingFloor;

	function get_is_touching_wall():Bool
		return isTouching(FlxDirectionFlags.LEFT) || isTouching(FlxDirectionFlags.RIGHT);

	function get_cur_anim():FlxAnimationController
		return animation;

	function get_attacking():Bool
		return state == FighterState.ATTACKING;

	function get_can_attack():Bool
		return !attacking && (state == FighterState.IDLE || state == FighterState.JUMPING);
}

typedef AttackDataInputCheckResult = {
	var attackData:AttackDataType;
	var inputMatched:Bool;
}

enum abstract FighterState(String) to String {
	var IDLE = "IDLE";
	var JUMPING = "JUMPING";
	var ATTACKING = "ATTACKING";
	var HIT = "HIT";
	var KNOCKDOWN = "KNOCKDOWN";
}
