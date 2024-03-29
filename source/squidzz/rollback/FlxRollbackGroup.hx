package squidzz.rollback;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import squidzz.actors.Fighter;
import squidzz.actors.HitFX;
import squidzz.rollback.Rollback;

// update this after adding more mutable state.
typedef RollbackState = {
	var p1Pos:FlxPoint;
	var p1Acc:FlxPoint;
	var p1Vel:FlxPoint;
	var p1TouchingFloor:Bool;
	var p2Pos:FlxPoint;
	var p2Acc:FlxPoint;
	var p2Vel:FlxPoint;
	var p2TouchingFloor:Bool;
}

class FlxRollbackGroup extends FlxTypedGroup<FlxRollbackActor> implements AbsSerialize<RollbackState> {
	public static inline final FLOOR_Y:Int = 456;

	var player1:Fighter;
	var player2:Fighter;

	public var hit_stop:Int = 0;

	public function new(player1:Fighter, player2:Fighter) {
		super();
		this.player1 = player1;
		this.player2 = player2;

		for (p in [player1, player2]) {
			p.set_group(this);
			p.add_self_to_group();
		}
	}

	// don't update.
	override function update(delta:Float) {}

	// given inputs and a delta, step through player input and run a frame of match simulation.
	public function step(input:Array<FrameInput>, delta:Float):FlxRollbackGroup {
		// forEach(spr -> spr.u) where they arent a player, update
		// should be 0 right now

		hit_stop--;

		if (hit_stop <= 0)
			for (sprite in members) {
				if (Std.isOfType(sprite, FightableObject)) {
					// update fightable objects
					var fighter:FightableObject = cast(sprite, FightableObject);
					fighter.updateWithInputs(delta, input[fighter.team > 0 ? fighter.team - 1 : 0]);
					// hit check other fightable objects
					for (other_sprite in members)
						if (other_sprite != sprite && Std.isOfType(other_sprite, FightableObject))
							fighter.fighter_hit_check(cast(other_sprite, FightableObject));
				} else {
					sprite.updateWithInputs(delta, blankInput());
				}
			}

		// TODO: consider using `Rollback.GLOBAL_DELTA` instead of from a parameter,
		super.update(delta);
		if (delta != Rollback.GLOBAL_DELTA) {
			throw 'bad delta: $delta';
		}
		forEach(actor -> {
			if (!actor.immovable) {
				actor.touchingWall = actor.touchingFloor = false;
				if (actor.x < FlxG.camera.scroll.x) {
					actor.x = FlxG.camera.scroll.x;
					actor.touchingWall = true;
				}
				if (actor.x + actor.width > FlxG.camera.width + FlxG.camera.scroll.x) {
					actor.x = FlxG.camera.scroll.x + FlxG.camera.width - actor.width;
					actor.touchingWall = true;
				}
				if (actor.y + actor.height > FLOOR_Y) {
					actor.y = FLOOR_Y - actor.height;
					actor.touchingFloor = true;
				}
			}
		});

		player1.collide_overlaps_fighter = player2.collide_overlaps_fighter = false;
		if (player1.touchingFloor && player2.touchingFloor)
			FlxG.collide(player1, player2, function(p1:FightableObject, p2:FightableObject) {
				p1.collide_overlaps_fighter = p2.collide_overlaps_fighter = true;
			});

		return this;
	}

	// Any values that change need to be serialized here.
	// Any mutable values need to be cloned to prevent reference errors.
	public function serialize():RollbackState {
		return {
			p1Pos: new FlxPoint(player1.x, player1.y),
			p1Acc: player1.acceleration.clone(),
			p1Vel: player1.velocity.clone(),
			p1TouchingFloor: player1.touchingFloor,
			p2Pos: new FlxPoint(player2.x, player2.y),
			p2Acc: player2.acceleration.clone(),
			p2Vel: player2.velocity.clone(),
			p2TouchingFloor: player2.touchingFloor,
		};
	}

	// Return all values from which they came.
	// Clone mutable values to avoid reference errors.
	public function unserialize(state:RollbackState) {
		player1.setPosition(state.p1Pos.x, state.p1Pos.y);
		player1.acceleration.copyFrom(state.p1Acc);
		player1.velocity.copyFrom(state.p1Vel);
		player1.touchingFloor = state.p1TouchingFloor;
		player2.setPosition(state.p2Pos.x, state.p2Pos.y);
		player2.acceleration.copyFrom(state.p2Acc);
		player2.velocity.copyFrom(state.p2Vel);
		player2.touchingFloor = state.p2TouchingFloor;
	}
}
