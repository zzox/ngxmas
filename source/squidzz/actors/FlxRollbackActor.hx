package squidzz.actors;

import flixel.FlxSprite;
import squidzz.rollback.FrameInput;

typedef AnimItem = {
    // var name:String;
    var frames:Array<Int>;
    var frameTime:Int;
    var repeats:Bool;
}

class FlxRollbackActor extends FlxSprite {
    var _animations:Map<String, AnimItem> = [];
    public var currentAnim:String; // our current animation
    public var animFrame:Int = -1; // number of frames we've been on this animation
    public var touchingFloor:Bool = false;

    public function new (x:Float, y:Float) {
        super(x, y);
    }

    // remove the update method called by the scene.
    // weird that the input isn't being used here, but the child classes will.
    override function update (delta:Float) {}
    public function updateWithInputs (delta:Float, input:FrameInput) {
        super.update(delta);
        updateAnims();
    }

    function addAnimation (name:String, frames:Array<Int>, frameTime:Int = 1, repeats:Bool = true) {
        _animations[name] = {
            frames: frames,
            frameTime: frameTime,
            repeats: repeats
        }
    }

    function playAnimation (name:String, force:Bool = false) {
        if (force || currentAnim == null || name != currentAnim) {
            animFrame = -1;
            currentAnim = name;
        }
    }

    function updateAnims () {
        animFrame++;
        final cur = _animations[currentAnim];
        final f = Math.floor(animFrame / cur.frameTime);
        if (cur.repeats) {
            animation.frameIndex = cur.frames[f % cur.frames.length];
        } else {
            animation.frameIndex = f >= cur.frames.length
                ? cur.frames[cur.frames.length - 1]
                : cur.frames[f];
        }
    }
}
