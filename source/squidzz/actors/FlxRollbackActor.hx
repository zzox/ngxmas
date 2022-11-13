package squidzz.actors;

import flixel.FlxSprite;
import squidzz.rollback.FrameInput;

class FlxRollbackActor extends FlxSprite {
    public function new (x:Float, y:Float) {
        super(x, y);
    }

    override function update (delta:Float) {}

    function updateWithInputs (delta:Float, input:FrameInput) {
        super.update(delta);
    }
}
