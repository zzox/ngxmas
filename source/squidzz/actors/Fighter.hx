package squidzz.actors;

import flixel.util.FlxDirection;
import squidzz.actors.ActorTypes.JumpDirection;
import squidzz.actors.ActorTypes.JumpingStyle;
import squidzz.rollback.FrameInput;

// This means we're translation enums to strings to enums,
// but it makes us feel safer.
enum abstract FInput(String) to String {
	var Left = 'LEFT';
	var Right = 'RIGHT';
	var Up = 'UP';
	var Down = 'DOWN';
	var A = 'A';
	var B = 'B';
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

	var air_speed:Int = 500;
	var ground_speed:Int = 1000;

	public function new(?Y:Float = 0, ?X:Float = 0, spritePath:String) {
		super(X, Y);

		loadAllFromAnimationSet(spritePath);

		hitbox = new FlxSpriteExt();
		hitbox.loadAllFromAnimationSet('${spritePath}-hitbox');
		hurtbox = new FlxSpriteExt();
		hurtbox.loadAllFromAnimationSet('${spritePath}-hitbox');

		prevInput = blankInput();

		update_offsets();
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		if (justPressed(input, Up) && touchingFloor) {
			start_jump(delta, input);
			velocity.y = -960;
		}

		if (touchingFloor && cast(JUMP_DIRECTION, Int) > JumpDirection.NONE) {
			JUMP_DIRECTION = JumpDirection.NONE;
			velocity.x = 0;
		}

		var acc:Float = 0.0;

		if (touchingFloor && JUMP_DIRECTION == JumpDirection.NONE) {
			if (pressed(input, Left)) {
				acc -= ground_speed;
			}

			if (pressed(input, Right)) {
				acc += ground_speed;
			}
		}

		acceleration.set(acc, 2000);

		do_jump(delta, input);

		if (touchingFloor) {
			if (acceleration.x != 0) {
				animation.play('walk');
			} else {
				animation.play('idle');
			}
		} else {
			animation.play('jump');
		}
		flipX = opponent.getMidpoint().x > getMidpoint().x;
		super.updateWithInputs(delta, input);
		prevInput = input;
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

	function update_offsets() {
		offset.set(flipX ? offset_left.x : offset_right.x, flipX ? offset_left.y : offset_right.y);
	}
}
