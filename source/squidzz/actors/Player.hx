package squidzz.actors;

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

class Player extends FlxRollbackActor {
	var prevInput:FrameInput;

	public var opponent:Player;

	/**A seperated hitbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hitbox:FlxSpriteExt;

	/**A seperated hurtbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hurtbox:FlxSpriteExt;

	public function new(x:Float, y:Float, spritePath:String) {
		super(x, y);

		loadAllFromAnimationSet(spritePath);

		hitbox = new FlxSpriteExt();
		hitbox.loadAllFromAnimationSet('${spritePath}-hitbox');
		hurtbox = new FlxSpriteExt();
		hurtbox.loadAllFromAnimationSet('${spritePath}-hitbox');

		loadGraphic(spritePath, true, 128, 128);
		offset.set(40, 24);
		setSize(48, 96);

		animation.add('stand', [0]);
		animation.add('run', [0, 1, 1, 2, 2], 24);
		animation.add('in-air', [1, 1, 2, 2, 2], 12);
		animation.add('teetering', [3, s4], 4);

		maxVelocity.set(480, 960);
		drag.set(2000, 0);

		prevInput = blankInput();
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		if (justPressed(input, Up) && touchingFloor) {
			velocity.y = -960;
		}

		var acc = 0.0;
		if (pressed(input, Left)) {
			acc -= 4000;
		}

		if (pressed(input, Right)) {
			acc += 4000;
		}

		acceleration.set(acc, 2000);

		if (touchingFloor) {
			if (acceleration.x != 0) {
				animation.play('run');
			} else {
				animation.play('stand');
			}
		} else {
			animation.play('in-air');
		}

		flipX = opponent.getMidpoint().x > getMidpoint().x;

		super.updateWithInputs(delta, input);

		prevInput = input;
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
}
