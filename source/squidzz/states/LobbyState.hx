package squidzz.states;

import squidzz.conn.Connection;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxState;

class LobbyState extends FlxState {
	override function create () {
		super.create();

		final info = new FlxText();
		info.alignment = CENTER;
		info.text = "Connecting...";
		Global.screenCenter(info);
		add(info);

        if (!Connection.inst.isServerConnected) {
            Connection.inst.init(
                () -> { trace('connected!'); },
                () -> { trace('disconnected!'); },
                (message) -> { trace('peer connected!', message); },
                (message) -> { trace('peer disconnected :(', message); }
            );
        }
	}

	override function update (elapsed:Float) {
		super.update(elapsed);
		
		if (Controls.justPressed.A)
			Global.switchState(new GameOverState());
	}
}
