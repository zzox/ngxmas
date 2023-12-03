package squidzz.display;

import squidzz.actors.FlxRollbackActor;
import squidzz.states.TestMatchState;

class RoundStartUI extends FlxRollbackActor {
	public static var ref:RoundStartUI;

	public var ROUND_START_HOLD:Bool = false;

	public var fighter_defeat_animation_finished:Bool = false;

	public function new(group:FlxRollbackGroup) {
		super();

		loadAllFromAnimationSet("round-start");

		set_group(group);
		group.add(this);

		ref = this;

		sstate(WAIT_FOR_ROUND_START);

		scrollFactor.set(0, 0);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		fsm();
		offset.set(x, y);

		super.updateWithInputs(delta, input);
	}

	public function start_round(round_number:Int) {
		animProtect("round-1");
		sstate(ROUND_START);
		ROUND_START_HOLD = true;
	}

	function fsm()
		switch (cast(state, State)) {
			default:
			case WAIT_FOR_ROUND_START:
				visible = false;
			case ROUND_START:
				visible = true;
				if (animation.finished) {
					sstate(OUT);
					fsm();
				}
			case OUT:
				ROUND_START_HOLD = false;
				sstate(WAIT_FOR_ROUND_START);
				fsm();
		}

	override function kill() {
		ref = null;
		super.kill();
	}
}

private enum abstract State(String) from String to String {
	var WAIT_FOR_ROUND_START;
	var ROUND_START;
	var OUT;
}
