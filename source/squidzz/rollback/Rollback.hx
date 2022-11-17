package squidzz.rollback;

import squidzz.rollback.FrameInput;

typedef Frame = {
	var frameNumber:Int;
	var input:Array<FrameInput>;
	var state:Dynamic;
}

interface AbsSerialize<T> {
	public function serialize():T;
	public function unserialize(state:T):Void;
}

final frameModulos = [1, 144, 89, 55, 34, 21, 13, 8, 5, 3];

// NOTE: will need to be reworked when more than two people are in a match
class Rollback<T> {
	public static inline final INPUT_DELAY_FRAMES:Int = 3;

	// ATTN: need something better.
	public static inline final GLOBAL_DELTA:Float = 0.016666666666666666;

	var playerIndex:Int;

	public var currentFrame:Int = 0;
	public var frames:Array<Frame> = [];
	public var futureRemotes:Array<RemoteInput> = [];
	// public var localInputs:Array<FrameInput> = [];
	public var isHalted:Bool = false;

	var onSimulateInput:Array<FrameInput>->Float->AbsSerialize<T>;
	var onRollbackState:T->Void;

	public function new(playerIndex:Int, initialState:AbsSerialize<T>, blankFrame:FrameInput, onSimulateInput:Array<FrameInput>->Float->AbsSerialize<T>,
			onRollbackState:T->Void) {
		this.playerIndex = playerIndex;
		this.onSimulateInput = onSimulateInput;
		this.onRollbackState = onRollbackState;

		frames.push({
			frameNumber: 0,
			input: [blankFrame.copy(), blankFrame.copy()],
			state: initialState.serialize()
		});

		// for (_ in 0...INPUT_DELAY_FRAMES) {
		//     localInputs.push(blankFrame.copy());
		//     frames.push({
		//         frameNumber: ++currentFrame,
		//         input: [blankFrame.copy(), blankFrame.copy()],
		//         state: initialState.serialize()
		//     });
		// }
	}

	// update the frame, add the frame
	public function tick(localInput:FrameInput, delta:Float) {
		if (frames.length > 10) {
			trace('should halt!!');
			isHalted = true;
			return;
		} else {
			isHalted = false;
		}

		currentFrame++;

		#if js
		// Connection.inst.sendInput(currentFrame + INPUT_DELAY_FRAMES, serializeInput(localInput))
		Connection.inst.sendInput(currentFrame, serializeInput(localInput));
		#end

		// HACK: input delay
		// localInputs.push(localInput);
		// final currentLocalInput = localInputs.shift();

		final currentLocalInput = localInput;

		var remoteInput:FrameInput;
		var behind:Bool = false;
		final futureFrame = futureRemotes[0];
		if (futureFrame != null) {
			// we are behind, add the local input to the frame
			// NOTE: this assumes ordered messages
			trace('behind!!!');
			behind = true;
			final fut = futureRemotes.shift();
			remoteInput = fut.input;
			if (currentFrame != fut.index) {
				trace(currentFrame, fut.index);
				throw 'bad future';
			}
		} else {
			remoteInput = getFrame(currentFrame - 1).input[oppIndex()];
		}

		// for now since we have only 2 players this kinda stuff is ok
		final frameInput = playerIndex == 0 ? [currentLocalInput, remoteInput] : [remoteInput, currentLocalInput];

		final state = onSimulateInput(frameInput, delta);

		final frame:Frame = {
			frameNumber: currentFrame,
			input: frameInput,
			state: state.serialize()
		}

		// update the head.
		frames.push(frame);

		// if we are behind, we can remove all frames since we know we are accurate.
		if (behind) {
			removeCorrectFrames(currentFrame);

			// Re-run based on frames behind.
			// The further behind, the more likely we re-run.
			final framesBehind = futureRemotes.length;
			if (framesBehind > 0 && currentFrame % frameModulos[framesBehind] == 0) {
				tick(localInput, delta);
			}
		}
	}

	// if > 2 players, this should come with an index from the connection
	public function handleRemoteInput(remote:RemoteInput) {
		// trace('remote input', input);

		// find input frame.
		final frame = getFrame(remote.index);
		if (frame == null) {
			futureRemotes.push(remote);
		} else {
			final wasPredictionCorrect = compareInput(remote.input, frame.input[oppIndex()]);

			// if it's right, shift() anything before it's index.
			// (besides the frame though, that's our confirm frame)
			// if it's wrong, do the rollback.
			if (wasPredictionCorrect) {
				removeCorrectFrames(remote.index);
			} else {
				doRollback(remote.index, remote.input);
			}
		}
	}

	// Remove all the frames we have certified remote input from.
	function removeCorrectFrames(frameIndex:Int) {
		for (frame in frames) {
			if (frame.frameNumber < frameIndex) {
				frames.shift();
			}
		}
	}

	// Rollback, this is it!
	function doRollback(toIndex:Int, remoteInput:FrameInput) {
		trace('rolling back!');
		var goodState = frames[0].state;
		onRollbackState(goodState);

		// Resimulate the state by restoring the true state, replacing the input,
		// and simulating the inputs up to the present.
		for (frameNum in 1...frames.length) {
			final frame = frames[frameNum];
			final frameInput = playerIndex == 0 ? [frame.input[0], remoteInput] : [remoteInput, frame.input[1]];
			frame.input = frameInput;
			final state = onSimulateInput(frameInput, GLOBAL_DELTA);
			frame.state = state.serialize();
		}

		removeCorrectFrames(toIndex);
	}

	// get frame from framequeue
	function getFrame(index:Int):Null<Frame> {
		for (f in frames) {
			if (f.frameNumber == index) {
				return f;
			}
		}

		return null;
	}

	// replace frame from framequeue
	function replaceAtIndex(frame:Frame, index:Int) {
		for (i in 0...frames.length) {
			if (frames[i].frameNumber == index) {
				frames[i] = frame;
			}
		}
	}

	// little hack to get the opponents index. won't work with more than 2 players.
	function oppIndex() {
		return playerIndex == 0 ? 1 : 0;
	}
}
