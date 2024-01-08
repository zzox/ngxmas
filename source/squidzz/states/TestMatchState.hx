package squidzz.states;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.system.debug.log.LogStyle;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;
import squidzz.actors.ActorTypes.FighterPrefix;
import squidzz.actors.Fighter;
import squidzz.display.CameraController;
import squidzz.display.DebugUi;
import squidzz.display.FightingStage;
import squidzz.display.GuardBreakFX;
import squidzz.display.KO;
import squidzz.display.MatchUi;
import squidzz.display.RoundStartUI;
import squidzz.rollback.Rollback;

// TODO: add updates alongside MatchState.
class TestMatchState extends BaseState {
	var collisionLayer:FlxTilemap;
	var stateGroup:FlxRollbackGroup;

	public var rollback:Rollback<RollbackState>;

	// hack to simulate input delay
	var localInputs:Array<FrameInput> = [];

	var match_ui:MatchUi;
	var debugUi:DebugUi;

	var ko:KO;

	var player1:Fighter;
	var player2:Fighter;

	var stage:FightingStage;
	var round_start_ui:RoundStartUI;

	var current_round:Int = 1;

	var p1_rounds_won:Int = 0;
	var p2_rounds_won:Int = 0;

	var ai_modes:Array<FighterAIMode> = [
		FighterAIMode.IDLE,
		FighterAIMode.JUMP,
		FighterAIMode.JAB,
		FighterAIMode.WALK_BACKWARDS,
		FighterAIMode.WALK_FORWARDS
	];

	static var current_ai_mode:FighterAIMode = FighterAIMode.IDLE;

	var guard_break_fx:FlxRollbackActor;

	var p1_character_selected:FighterPrefix = FighterPrefix.DONKEY;
	var p2_character_selected:FighterPrefix = FighterPrefix.SNOWMAN;

	var p1_starting_position:FlxPoint = new FlxPoint(112, 328);
	var p2_starting_position:FlxPoint = new FlxPoint(768, 328);

	override function create() {
		super.create();

		camera.bgColor = 0xff415d66;
		LogStyle.ERROR.errorSound = null;

		// add(new FlxSprite(0, 456).makeGraphic(960, 84, 0xffa8a8a8));

		stage = new FightingStage("pub");

		for (layer in stage.layers)
			add(layer);

		player1 = make_fighter(p1_character_selected, p1_starting_position);
		player2 = make_fighter(p2_character_selected, p2_starting_position);

		#if test_p2_middle
		player2.x -= FlxG.width / 2;
		#end

		player1.opponent = player2;
		player2.opponent = player1;

		player2.aiControlled = true;
		#if disable_ai
		player2.aiControlled = false;
		#end

		stateGroup = new FlxRollbackGroup(player1, player2);
		add(stateGroup);

		new GuardBreakFX(stateGroup);
		ko = new KO(stateGroup);
		round_start_ui = new RoundStartUI(stateGroup);

		add(match_ui = new MatchUi());

		var count:Int = 0;
		for (p in [player1, player2]) {
			count++;
			p.set_team(count);
			p.set_match_ui(match_ui);
		}

		new_round();

		add(new CameraController(player1, player2));

		for (_ in 0...Rollback.INPUT_DELAY_FRAMES) {
			localInputs.push(blankInput());
		}

		switch_ai_mode();

		/*
			var wombo:FlxRollbackActor = new FlxRollbackActor();
			wombo.loadAllFromAnimationSet("snowman-air-back-hurtbox");
			wombo.setPosition();
			wombo.scrollFactor.set();

			stateGroup.add(wombo);
		 */
	}

	function make_fighter(prefix:FighterPrefix, pos:FlxPoint):Fighter {
		switch (prefix) {
			case FighterPrefix.PENGUIN:
				return new Penguin(pos.x, pos.y);
			case FighterPrefix.SNOWMAN:
				return new Snowman(pos.x, pos.y);
			case FighterPrefix.DONKEY:
				return new Donkey(pos.x, pos.y);
			case FighterPrefix.YETI_DUO:
				return new YetiDuoGirl(pos.x, pos.y);
		}
		throw "invalid fighter you dingus " + prefix;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// simulate input delay
		localInputs.push(getLocalInput());
		stateGroup.step([localInputs.shift(), blankInput()], elapsed);

		if (Controls.justPressed.PAUSE) {
			debugUi.visible = !debugUi.visible;
		}

		end_round_on_dead_hp();

		for (fighter in [player1, player2]) {
			if (fighter.health <= 0 && fighter.state != FighterState.DEFEATED) {
				ko.start_ko();
				fighter.sstate(FighterState.DEFEATED);

				if (player1.health > player2.health)
					match_ui.p1Wins++;
				if (player1.health < player2.health)
					match_ui.p2Wins++;
			}
		}

		// trace(p1_rounds_won, p2_rounds_won);

		#if dev
		if (FlxG.keys.anyJustPressed([FlxKey.R]))
			Global.switchState(new TestMatchState());

		if (FlxG.keys.anyJustPressed([FlxKey.V]))
			Main.SHOW_HITBOX = !Main.SHOW_HITBOX;

		if (FlxG.keys.anyJustPressed([FlxKey.Q])) {
			var index:Int = ai_modes.indexOf(current_ai_mode);
			index++;
			if (index >= ai_modes.length)
				index = 0;
			current_ai_mode = ai_modes[index];
			switch_ai_mode();
		}
		#end
	}

	function switch_ai_mode()
		player2.ai_mode = current_ai_mode;

	function end_round_on_dead_hp() {
		if (ko.state != "ENDED")
			return;

		current_round++;

		ko.sstate("WAIT_FOR_KO");

		new_round();
	}

	function new_round() {
		player1.reset_round();
		player2.reset_round();

		round_start_ui.start_round(current_round);

		match_ui.update_players(player1, player2);
	}
}
