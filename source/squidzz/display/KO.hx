package squidzz.display;

import squidzz.actors.FlxRollbackActor;
import squidzz.states.TestMatchState;

class KO extends FlxRollbackActor {
	public static var ref:KO;

	public var fighter_defeat_animation_finished:Bool = false;

	public function new(group:FlxRollbackGroup) {
		super();

		loadAllFromAnimationSet("ko");

		ref = this;

		set_group(group);
		group.add(this);

		sstate(WAIT_FOR_KO);

		scrollFactor.set(0, 0);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		fsm();
		offset.set(x, y);

		super.updateWithInputs(delta, input);
	}

	public function start_ko() {
		sstate(IN);
	}

	function fsm()
		switch (cast(state, State)) {
			default:
			case WAIT_FOR_KO:
				visible = false;
			case IN:
				visible = true;
				animProtect("in");
				if (animation.finished)
					sstate(OUT);
			case OUT:
				visible = true;
				animProtect("out");
				if (animation.finished)
					sstate(END);
			case END:
				visible = false;
				if (ttick() > 30)
					Global.switchState(new TestMatchState());
		}

	override function kill() {
		ref = null;
		super.kill();
	}
}

private enum abstract State(String) from String to String {
	var WAIT_FOR_KO;
	var IN;
	var OUT;
	var END;
}
