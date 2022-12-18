package squidzz.display;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;

class MatchUi extends FlxGroup {
    static inline final NEEDED_WINS:Int = 2;
    static inline final HEALTH_WIDTH:Float = 337.0;
    static inline final POWER_WIDTH:Float = 237.0;

    var p1HealthBar:FlxSprite;
    var p2HealthBar:FlxSprite;
    var p1PowerBar:FlxSprite;
    var p2PowerBar:FlxSprite;
    var p1Presents:Array<FlxSprite>;
    var p2Presents:Array<FlxSprite>;

    // TEMP:
    var p1Health:Float = 95;
    var p2Health:Float = 25;
    var p1Wins:Int = 0;
    var p2Wins:Int = 2;
    var p1Power:Float = 50;
    var p2Power:Float = 0;

    public function new () {
        super();

        add(new FlxSprite(0, 0, 'assets/images/ui/p1HealthBg.png'));
        add(new FlxSprite(0, 0, 'assets/images/ui/wreath.png'));
        add(p1HealthBar = new FlxSprite(16, 80, 'assets/images/ui/p1Health.png'));
        add(new FlxSprite(16, 448, 'assets/images/ui/p1PowerBg.png'));
        add(p1PowerBar = new FlxSprite(16, 448, 'assets/images/ui/p1Power.png'));
        add(new FlxSprite(32, 496, 'assets/images/ui/p1PowerMeter.png'));

        p1Presents = [
            new FlxSprite(256, 32, 'assets/images/ui/present.png'),
            new FlxSprite(288, 32, 'assets/images/ui/present.png')
        ];
        add(p1Presents[0]);
        add(p1Presents[1]);

        add(new FlxSprite(576, 0, 'assets/images/ui/p2HealthBg.png'));
        add(new FlxSprite(768, 0, 'assets/images/ui/wreath.png'));
        add(p2HealthBar = new FlxSprite(576, 80, 'assets/images/ui/p2Health.png'));
        add(new FlxSprite(672, 448, 'assets/images/ui/p2PowerBg.png'));
        add(p2PowerBar = new FlxSprite(672, 448, 'assets/images/ui/p2Power.png'));
        add(new FlxSprite(688, 496, 'assets/images/ui/p2PowerMeter.png'));

        p2Presents = [
            new FlxSprite(592, 32, 'assets/images/ui/present.png'),
            new FlxSprite(624, 32, 'assets/images/ui/present.png')
        ];
        add(p2Presents[0]);
        add(p2Presents[1]);

        add(new FlxSprite(416, 0, 'assets/images/ui/timerBg.png'));
    }

    override function update (delta:Float) {
        super.update(delta);

        p1HealthBar.clipRect = new FlxRect(0, 0, 15 + (HEALTH_WIDTH * (p1Health / 100)), 64);
        p2HealthBar.clipRect = new FlxRect(7 + (HEALTH_WIDTH * (p2Health / 100)), 0, 352, 64);

        p1PowerBar.clipRect = new FlxRect(0, 0, 11 + (POWER_WIDTH * (p1Power / 100)), 64);
        p2PowerBar.clipRect = new FlxRect(25 + (POWER_WIDTH * (p2Power / 100)), 0, 272, 64);

        // TEMP:
        p1Health -= (1 / 10);
        p2Health -= (1 / 30);
        p1Power += (1 / 60);
        p2Power += (1 / 60);

        for (i in 0...NEEDED_WINS) {
            p1Presents[i].visible = i + 1 <= p1Wins;
            p2Presents[i].visible = i + 1 <= p2Wins;
        }
    }
}
