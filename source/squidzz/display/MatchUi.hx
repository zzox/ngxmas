package squidzz.display;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import squidzz.actors.Fighter;

class MatchUi extends FlxGroup {
	static inline final NEEDED_WINS:Int = 2;
	static inline final HEALTH_WIDTH:Float = 337.0;
	static inline final POWER_WIDTH:Float = 237.0;

	var p1HealthBar:FlxSpriteExt;
	var p2HealthBar:FlxSpriteExt;
	var p1PowerBar:FlxSprite;
	var p2PowerBar:FlxSprite;

	public var p1Presents:Array<FlxSprite>;
	public var p2Presents:Array<FlxSprite>;

	var p1CharPortrait:FlxSpriteExt;
	var p2CharPortrait:FlxSpriteExt;

	var wreaths:FlxSpriteExt;

	var power_bar_y:Int = 448 + 24;

	// Health defines
	public var healths:Array<Float> = [];
	public var max_healths:Array<Float> = [];

	// Wins defines
	public var p1Wins:Int = 0;
	public var p2Wins:Int = 0;

	var p1Power:Float = 0;
	var p2Power:Float = 0;

	public var shield_breaks:Array<Float> = [];

	public function new() {
		super();

		add(new FlxSprite(0, 0, 'assets/images/ui/p1HealthBg.png'));
		add(new FlxSprite(0, 0, 'assets/images/ui/wreaths.png'));
		add(p1HealthBar = new FlxSpriteExt(16, 80).loadAllFromAnimationSet("p1Health"));
		add(new FlxSpriteExt(16, power_bar_y, 'assets/images/ui/p1PowerBg.png'));
		add(p1PowerBar = new FlxSprite(16, power_bar_y, 'assets/images/ui/p1Power.png'));

		// add(new FlxSprite(32, 496, 'assets/images/ui/p1PowerMeter.png'));

		p1Presents = [
			new FlxSprite(256 - 24, 32, 'assets/images/ui/present.png'),
			new FlxSprite(288, 32, 'assets/images/ui/present.png')
		];

		add(p1Presents[0]);
		add(p1Presents[1]);

		for (present in p1Presents) {
			present.scrollFactor.set(0, 0);
			add(present);
		}

		add(new FlxSprite(576, 0, 'assets/images/ui/p2HealthBg.png'));
		add(p2HealthBar = new FlxSpriteExt(576, 80).loadAllFromAnimationSet("p2Health"));
		add(new FlxSprite(672, power_bar_y, 'assets/images/ui/p2PowerBg.png'));
		add(p2PowerBar = new FlxSprite(672, power_bar_y, 'assets/images/ui/p2Power.png'));

		// add(new FlxSprite(688, 496, 'assets/images/ui/p2PowerMeter.png'));

		p2Presents = [
			new FlxSprite(592, 32, 'assets/images/ui/present.png'),
			new FlxSprite(624 + 24, 32, 'assets/images/ui/present.png')
		];

		for (present in p2Presents) {
			add(present);
			present.scrollFactor.set(0, 0);
		}

		add(p1CharPortrait = new FlxSpriteExt());
		add(p2CharPortrait = new FlxSpriteExt());

		p1CharPortrait.loadAllFromAnimationSet("p1CharPortrait");
		p2CharPortrait.loadAllFromAnimationSet("p2CharPortrait");

		add(new FlxSprite(416, 0, 'assets/images/ui/timerBg.png'));

		forEach(function(basic:FlxBasic) {
			cast(basic, FlxSprite).scrollFactor.set(0, 0);
		});

		p1HealthBar.trace_new_anim = true;
		p2HealthBar.trace_new_anim = true;
	}

	public function update_players(player1:Fighter, player2:Fighter) {
		p1CharPortrait.anim(player1.prefix);
		p2CharPortrait.anim(player2.prefix);
	}

	override function update(delta:Float) {
		super.update(delta);

		for (bar in [p1HealthBar, p2HealthBar])
			if (bar.animation.name == "hit" && bar.animation.finished)
				bar.anim("idle");

		var p1_health_width:Float = p1HealthBar.clipRect == null ? 9999 : p1HealthBar.clipRect.width;
		var p2_health_width:Float = p2HealthBar.clipRect == null ? 9999 : p2HealthBar.clipRect.x;

		p1HealthBar.clipRect = new FlxRect(0, 0, 15 + (HEALTH_WIDTH * (healths[0] / max_healths[0])), 64);
		p2HealthBar.clipRect = new FlxRect(352 - (HEALTH_WIDTH * (healths[1] / max_healths[1])), 0, 352, 64);

		if (p1_health_width > p1HealthBar.clipRect.width)
			p1HealthBar.anim("hit");

		if (p2_health_width < p2HealthBar.clipRect.x)
			p2HealthBar.anim("hit");

		switch (p1HealthBar.animation.frameIndex) {
			case 1:
				p1CharPortrait.offset.y = 3;
			case 2:
				p1CharPortrait.offset.y = 1;
			case 0:
				p1CharPortrait.offset.y = 0;
		}

		switch (p2HealthBar.animation.frameIndex) {
			case 1:
				p2CharPortrait.offset.y = 3;
			case 2:
				p2CharPortrait.offset.y = 1;
			case 0:
				p2CharPortrait.offset.y = 0;
		}

		p1PowerBar.clipRect = new FlxRect(0, 0, 11 + (POWER_WIDTH * (shield_breaks[0] / Fighter.SHIELD_BREAK_MAX)), 64);
		p2PowerBar.clipRect = new FlxRect(260 - (POWER_WIDTH * (shield_breaks[1] / Fighter.SHIELD_BREAK_MAX)), 0, 272, 64);

		p1Power += (1 / 60);
		p2Power += (1 / 60);

		for (i in 0...NEEDED_WINS) {
			p1Presents[i].visible = i + 1 <= p1Wins;
			p2Presents[i].visible = i + 1 <= p2Wins;
		}
	}
}
