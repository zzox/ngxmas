package squidzz.rollback;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import squidzz.actors.FlxRollbackActor;
import squidzz.actors.Player;
import squidzz.rollback.Rollback;

typedef RollbackState = {
    var p1Pos:FlxPoint;
    var p1Acc:FlxPoint;
    var p1Vel:FlxPoint;
    var p2Pos:FlxPoint;
    var p2Acc:FlxPoint;
    var p2Vel:FlxPoint;
}

class FlxRollbackGroup extends FlxTypedGroup<FlxRollbackActor> implements AbsSerialize<RollbackState> {
    var collision:FlxTilemap;
    var player1:Player;
    var player2:Player;

    public function new (player1:Player, player2:Player, collision:FlxTilemap) {
        super();
        // path to collision
        this.collision = collision;
        this.player1 = player1;
        this.player2 = player2;

        add(player1);
        add(player2);
    }

    // don't update.
    override function update (delta:Float) {}

    public function step (input:Array<FrameInput>, delta:Float):FlxRollbackGroup {
        // forEach(spr -> spr.u) where they arent a player, update
            // should be 0 right now
        player1.updateWithInputs(delta, input[0]);
        player2.updateWithInputs(delta, input[1]);

        super.update(delta);
        if (delta != Rollback.GLOBAL_DELTA) {
            throw 'bad delta $delta';
        }

        forEach(actor -> FlxG.collide(actor, collision));

        FlxG.collide(player1, player2);

        return this;
    }

    public function serialize():RollbackState {
        return {
            p1Pos: new FlxPoint(player1.x, player1.y),
            p1Acc: player1.acceleration.clone(),
            p1Vel: player1.velocity.clone(),
            p2Pos: new FlxPoint(player2.x, player2.y),
            p2Acc: player2.acceleration.clone(),
            p2Vel: player2.velocity.clone()
        };
    }

    public function unserialize(state:RollbackState) {
        player1.setPosition(state.p1Pos.x, state.p1Pos.y);
        player1.acceleration.set(state.p1Acc.x, state.p1Acc.y);
        player1.velocity.set(state.p1Vel.x, state.p1Vel.y);
        player2.setPosition(state.p2Pos.x, state.p2Pos.y);
        player2.acceleration.set(state.p2Acc.x, state.p2Acc.y);
        player2.velocity.set(state.p2Vel.x, state.p2Vel.y);
    }
}
