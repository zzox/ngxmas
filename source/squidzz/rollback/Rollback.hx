package squidzz.rollback;

import haxe.Serializer;
import haxe.Unserializer;
import squidzz.conn.Connection;
import squidzz.rollback.FrameInput;

typedef Frame = {
    var frameNumber:Int;
    var input:Array<FrameInput>;
    var state:Dynamic;
}

interface AbsSerialize<T> {
    public function serialize():T;
    public function unserialize():Void;
}

// NOTE: will need to be reworked when more than two people are in a match
class Rollback<T> {
    var playerIndex:Int;
    public var currentFrame:Int = 0;
    public var frames:Array<Frame>;
    var frameHeadIndex:Int = 0;

    var onSimulateInput:Array<FrameInput> -> Float -> AbsSerialize<T>;

    public function new (
        playerIndex:Int,
        initialState:AbsSerialize<T>,
        blankFrame:FrameInput,
        onSimulateInput:Array<FrameInput> -> Float -> AbsSerialize<T>
    ) {
        this.playerIndex = playerIndex;
        this.onSimulateInput = onSimulateInput;

        frames = [{
            frameNumber: 0,
            input: [blankFrame, blankFrame],
            state: initialState.serialize()
        }];
    }

    // update the frame, add the frame
    public function tick (localInput:FrameInput, delta:Float) {
        // check if we should stall.

        final curIndex = ++currentFrame;

        Connection.inst.sendInput(curIndex, serializeInput(localInput));

        // add to frame if it doesn't exist yet.
        var remoteInput:FrameInput;
        var behind:Bool = false;
        final foundFrame = getFrame(curIndex);
        if (foundFrame != null) {
            // we are behind, add the local input to the frame
            trace('behind!!!');
            remoteInput = foundFrame.input[playerIndex == 0 ? 1 : 0];
        } else {
            remoteInput = frames[frameHeadIndex].input[playerIndex == 0 ? 1 : 0];
        }

        // for now since we have only 2 players this kinda stuff is ok
        final frameInput = playerIndex == 0 ? [localInput, remoteInput] : [remoteInput, localInput];

        final state = onSimulateInput(frameInput, delta);

        final frame:Frame = {
            frameNumber: curIndex,
            input: frameInput,
            state: state.serialize()
        }

        // if we are behind, replace the frame with the updated
        if (behind) {
            replaceAtIndex(frame, curIndex);
        } else {
            // otherwise update the head.
            frames.push(frame);
            frameHeadIndex++;
        }
    }

    // if > 2 players, this should come with an index from the connection
    public function handleRemoteInput (input:RemoteInput) {
        // 
        // trace('remote input', input);

        // find input frame.
            // if it's right, unshift() anything before it off. (not it though, that's our confirm frame)
        // if it's wrong, do the rollback
    }

    // get frame from framequeue
    function getFrame (index:Int):Null<Frame> {
        for (f in frames) {
            if (f.frameNumber == index) {
                return f;
            }
        }

        return null;
    }

    // replace frame from framequeue
    function replaceAtIndex (frame:Frame, index:Int) {
        for (i in 0...frames.length) {
            if (frames[i].frameNumber == index) {
                frames[i] = frame;
            }
        }
    }
}
