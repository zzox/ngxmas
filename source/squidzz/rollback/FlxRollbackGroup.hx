package squidzz.rollback;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import squidzz.actors.FlxRollbackActor;

class FlxRollbackGroup extends FlxTypedGroup<FlxRollbackActor> {
    // don't update.
    override function update (delta:Float) {}

    public function step (input:Array<FrameInput>, delta:Float):FlxRollbackGroup {
        // update player inputs
        // forEach(spr -> spr.u)

        // update player movement
        super.update(delta);
        if (delta != 0.016666666666666666) {
            throw 'bad delta $delta';
        }

        // collisions
        return this;
    }
}
