package squidzz.actors;

import flixel.FlxSprite;
import squidzz.rollback.FrameInput;

class FlxRollbackActor extends FlxSprite {
    public function new (x:Float, y:Float) {
        super(x, y);
    }

    // remove the update method called by the scene.
    // weird that the input isn't being used here, but the child classes will.
    override function update (delta:Float) {}
    public function updateWithInputs (delta:Float, input:FrameInput) {
        super.update(delta);
    }
}
