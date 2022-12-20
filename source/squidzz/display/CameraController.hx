package squidzz.display;

import squidzz.actors.FlxRollbackActor;
import squidzz.rollback.FrameInput;

class CameraController extends FlxRollbackActor {
	var player1:FlxSprite;
	var player2:FlxSprite;

	public function new(player1:FlxSprite, player2:FlxSprite) {
		super(x, y);

		this.player1 = player1;
		this.player2 = player2;

		makeGraphic(2, 2, FlxColor.WHITE);

		FlxG.camera.follow(this);

		update_midpoint();
	}

	function update_midpoint() {
		setPosition((player1.x + player2.x) / 2, (player1.y + player2.y) / 2);
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
