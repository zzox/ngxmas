package squidzz.display;


class GuardBreakFX extends FlxRollbackActor {
	var lightning:FlxRollbackActor;

	public static var ref:GuardBreakFX;

	public function new(?X:Float, ?Y:Float, group:FlxRollbackGroup) {
		super(X, Y, group);

		ref = this;

		makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		immovable = true;

		scrollFactor.set(0, 0);

		set_group(group);
		group.add(this);

		alpha = 0;
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		if (lightning != null) {
			lightning.alpha -= 0.025;
			if (lightning.alpha <= 0) {
				lightning.kill();
				lightning = null;
			}

			if (lightning != null && lightning.alpha <= 0.5)
				alpha -= 0.075;
		}

		super.updateWithInputs(delta, input);
	}

	public function make_lightning(fighter:FlxRollbackActor) {
		lightning = new FlxRollbackActor(fighter.mp().x, 64, group);
		lightning.loadAllFromAnimationSet("guard-break-fx");
		lightning.x -= lightning.width / 2 + fighter.width / 2;
		lightning.scrollFactor.y = 0;

		group.add(lightning);

		SoundPlayer.sound("lightning");

		alpha = 0.5;
	}
}
