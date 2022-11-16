package squidzz.states;

import flixel.FlxG;
import flixel.text.FlxText;
import ui.Controls;
import utils.Global;

class MenuState extends flixel.FlxState {
	override function create () {
		super.create();
		
		// Only needs to be called once
		Controls.init();
        FlxG.autoPause = false;

		final info = new FlxText(0, 0, 0, '', 32);
		info.alignment = CENTER;
		info.text = "Menu";
		Global.screenCenter(info);
		add(info);
	}
	
	override function update(elapsed:Float) {
		super.update(elapsed);
		
		if (Controls.justPressed.A) {
			Global.switchState(new squidzz.states.LobbyState());
        }

        if (Controls.justPressed.PAUSE) {
            Global.switchState(new TestMatchState());
        }
	}
}
