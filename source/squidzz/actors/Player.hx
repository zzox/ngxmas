package squidzz.actors;

import squidzz.rollback.FrameInput;

class Player extends FlxRollbackActor {
    public function new (x:Float, y:Float, spritePath:String) {
        super(x, y);

        loadGraphic(spritePath, true, 16, 16);
        offset.set(5, 3);
        setSize(6, 12);

        animation.add('stand', [0]);
        animation.add('run', [0, 1, 1, 2, 2], 24);
        animation.add('in-air', [1, 1, 2, 2, 2], 12);
        animation.add('teetering', [3, 4], 4);

        maxVelocity.set(120, 240);
        drag.set(1000, 0);
    }

    override function updateWithInputs (delta:Float, inputs:FrameInput) {
        if (inputs['up']) {
            velocity.y = -120;
        }

        var acc = 0.0;
        if (inputs['left']) {
            acc -= 1000;
        }

        if (inputs['right']) {
            acc += 1000;
        }

        acceleration.set(acc, 800);

        if (isTouching(FLOOR)) {
            if (acceleration.x != 0) {
                animation.play('run');
            } else {
                animation.play('stand');
            }
        } else {
            animation.play('in-air');
        }

        if (acceleration.x > 0 && !flipX) {
            flipX = true;
        }

        if (acceleration.x < 0 && flipX) {
            flipX = false;
        }

        super.updateWithInputs(delta, inputs);
    }
}
