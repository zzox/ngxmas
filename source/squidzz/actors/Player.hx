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
    public var opponent:Player;
    public var hitFrames:Int = 0;

    public function new (x:Float, y:Float, spritePath:String) {
        super(x, y);

        loadGraphic(spritePath, true, 128, 128);
        offset.set(40, 24);
        setSize(48, 96);

        addAnimation('stand', [0]);
        addAnimation('run', [0, 1, 1, 2, 2], 2);
        addAnimation('in-air', [1, 1, 2, 2, 2], 5);
        addAnimation('teetering', [3, 4], 4);

        maxVelocity.set(480, 960);
        drag.set(2000, 0);

        prevInput = blankInput();
    }

    override function updateWithInputs (delta:Float, input:FrameInput) {
        drag.x = touchingFloor ? 2000 : 1000;
        if (hitFrames-- > 0) {
            acceleration.y = 2000;
        } else {
            if (justPressed(input, Up) && touchingFloor) {
                velocity.y = -960;
            }

            var acc = 0.0;
            if (pressed(input, Left)) {
                acc -= 4000;
            }

            if (pressed(input, Right)) {
                acc += 4000;
            }

            acceleration.set(acc, 2000);
        }

        if (touchingFloor) {
            if (acceleration.x != 0) {
                playAnimation('run');
            } else {
                playAnimation('stand');
            }
        } else {
            playAnimation('in-air');
        }

        flipX = opponent.getMidpoint().x > getMidpoint().x;

        super.updateWithInputs(delta, input);

        prevInput = input;
    }

    public function hit (xVel:Float, yVel:Float, damage:Int) {
        velocity.set(xVel, yVel);
        hitFrames = 10;
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
