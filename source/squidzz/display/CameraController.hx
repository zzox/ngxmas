package squidzz.display;

import squidzz.rollback.FrameInput;

class CameraController extends FlxRollbackActor {
	var player1:FlxSpriteExt;
	var player2:FlxSpriteExt;

	var y_offset:Int = 128;

	public function new(player1:FlxSpriteExt, player2:FlxSpriteExt) {
		super(x, y);

		this.player1 = player1;
		this.player2 = player2;

		makeGraphic(2, 2, FlxColor.WHITE);

		FlxG.camera.follow(this);

		update_midpoint();
	}

	function update_midpoint() {
		setPosition((player1.mp().x + player2.mp().x) / 2, (player1.mp().y + player2.mp().y) / 2 - y_offset);
	}

	override function update(elapsed:Float) {
		update_midpoint();
		super.update(elapsed);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		update_midpoint();
		super.updateWithInputs(delta, input);
	}
}
