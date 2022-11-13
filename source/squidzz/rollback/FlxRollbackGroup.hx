package squidzz.rollback;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import squidzz.actors.FlxRollbackActor;
import squidzz.actors.Player;
import squidzz.rollback.Rollback;

typedef RollbackState = {
    var it:String;
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
        if (delta != 0.016666666666666666) {
            throw 'bad delta $delta';
        }

        trace(player1.velocity.x);

        forEach(actor -> FlxG.collide(actor, collision));

        return this;
    }

    public function serialize():RollbackState {
        return { it: '' };
    }

    public function unserialize():Void {}
}
