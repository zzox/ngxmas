package squidzz.states;

import flixel.text.FlxText;
import flixel.FlxState;

class GameOverState extends FlxState {
	override function create () {
		super.create();

		final info = new FlxText();
		info.alignment = "center";
		info.text = "This is the GAME OVER state.\n"
			+ "I'm sure you did your best.\n"
			+ "Press Z to play again.\n\n"
			+ "Game by\nlil' georgie\n\n"
			+ "Coded by\nyour mom\n\n"
			+ "Music by\nbrandy's nose-flute";
		Global.screenCenter(info);
		add(info);
	}

	override function update (elapsed:Float) {
		super.update(elapsed);
		
		if (Controls.justPressed.A) {
			Global.switchState(new LobbyState());
        }
	}
}