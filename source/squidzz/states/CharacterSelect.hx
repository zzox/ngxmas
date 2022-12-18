package squidzz.states;

import flixel.FlxSprite;
import flixel.FlxState;

class CharacterSelect extends FlxState {
    var charPos:Int = 0;
    var chars:Array<FlxSprite> = [];

    override function create () {
        add(new FlxSprite(0, 0, 'assets/images/ui/character-select-bg.png'));
        add(chars[0] = new FlxSprite(247, 22, 'assets/images/ui/poot-icon.png'));
        add(chars[1] = new FlxSprite(473, 22, 'assets/images/ui/ketu-icon.png'));
        add(chars[2] = new FlxSprite(247, 248, 'assets/images/ui/joe-icon.png'));
        add(chars[3] = new FlxSprite(473, 248, 'assets/images/ui/dom-icon.png'));
        add(new FlxSprite(0, 0, 'assets/images/ui/character-select-fg.png'));

        for (char in chars) char.visible = false;
    }

    override function update (delta:Float) {
        super.update(delta);

        // bad but it works
        if (Controls.justPressed.LEFT) {
            charPos -= 1;
            if (charPos == 1) charPos = 3;
            if (charPos == -1) charPos = 1;
        }

        if (Controls.justPressed.RIGHT) {
            charPos += 1;
            if (charPos == 2) charPos = 0;
            if (charPos == 4) charPos = 2;
        }

        if (Controls.justPressed.UP) {
            charPos -= 2;
            if (charPos == -2) charPos = 2;
            if (charPos == -1) charPos = 3;
        }

        if (Controls.justPressed.DOWN) {
            charPos += 2;
            if (charPos == 4) charPos = 0;
            if (charPos == 5) charPos = 1;
        }

        for (i in 0...chars.length) chars[i].visible = i == charPos;
    }
}
