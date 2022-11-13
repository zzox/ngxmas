package squidzz.actors;

import squidzz.rollback.FrameInput;

class Player extends FlxRollbackActor {
    public function new (x:Float, y:Float, spritePath:String) {
        super(x, y);

        loadGraphic(spritePath, true, 16, 16);
        offset.set(5, 3);
        setSize(6, 12);
    }

    override function updateWithInputs (delta:Float, inputs:FrameInput) {
        super.update(delta);
    }
}
