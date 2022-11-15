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

        prevInput = blankInput();
    }

    override function updateWithInputs (delta:Float, input:FrameInput) {
        if (justPressed(input, Up)) {
            velocity.y = -120;
        }

        var acc = 0.0;
        if (pressed(input, Left)) {
            acc -= 1000;
        }

        if (pressed(input, Right)) {
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

        super.updateWithInputs(delta, input);

        prevInput = input;
    }

    function pressed (input:FrameInput, dir:FInput) {
        // NOTE: just for development, remove in prod.
        // bad inputs from the peer would trigger this.
#if dev
        if (!['LEFT','RIGHT','UP','DOWN','A','B'].contains(dir)) {
            throw 'bad input';
        }
#end
        return input[dir];
    }

    function justPressed (input:FrameInput, dir:FInput) {
#if dev
        if (!['LEFT','RIGHT','UP','DOWN','A','B'].contains(dir)) {
            throw 'bad input';
        }
#end
        return input[dir] && !prevInput[dir];
    }
}
