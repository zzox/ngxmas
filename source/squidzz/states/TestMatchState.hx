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
import squidzz.actors.Fighter;
import squidzz.actors.FlxRollbackActor;
import squidzz.display.CameraController;
import squidzz.display.DebugUi;
import squidzz.display.FightingStage;
import squidzz.display.GuardBreakFX;
import squidzz.display.MatchUi;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;
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

	var player1:Fighter;
	var player2:Fighter;

	var stage:FightingStage;

	var ai_modes:Array<FighterAIMode> = [
		FighterAIMode.IDLE,
		FighterAIMode.JUMP,
		FighterAIMode.JAB,
		FighterAIMode.WALK_BACKWARDS,
		FighterAIMode.WALK_FORWARDS
	];

	static var current_ai_mode:FighterAIMode = FighterAIMode.WALK_BACKWARDS;

	var guard_break_fx:FlxRollbackActor;

	override function create() {
		super.create();

		camera.bgColor = 0xff415d66;
		LogStyle.ERROR.errorSound = null;

		// add(new FlxSprite(0, 456).makeGraphic(960, 84, 0xffa8a8a8));

		stage = new FightingStage("pub");

		for (layer in stage.layers)
			add(layer);

		player1 = new Donkey(112, 328);
		player2 = new Snowman(768, 328);

		player1.opponent = player2;
		player2.opponent = player1;

		player2.aiControlled = true;

		stateGroup = new FlxRollbackGroup(player1, player2);
		add(stateGroup);

		new GuardBreakFX(stateGroup);

		add(match_ui = new MatchUi());

		var count:Int = 0;
		for (p in [player1, player2]) {
			count++;
			p.set_group(stateGroup);
			p.set_team(count);
			p.set_match_ui(match_ui);
			p.reset_new_round();
		}

		add(new CameraController(player1, player2));

		for (_ in 0...Rollback.INPUT_DELAY_FRAMES) {
			localInputs.push(blankInput());
		}

		switch_ai_mode();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// simulate input delay
		localInputs.push(getLocalInput());
		stateGroup.step([localInputs.shift(), blankInput()], elapsed);

		if (Controls.justPressed.PAUSE) {
			debugUi.visible = !debugUi.visible;
		}

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

	function createTileLayer(map:TiledMap, layerName:String, offset:FlxPoint):Null<FlxTilemap> {
		final layerData = map.getLayer(layerName);
		if (layerData != null) {
			final layer = new FlxTilemap();
			final tileArray = cast(layerData, TiledTileLayer).tileArray;
			layer.loadMapFromArray(tileArray, map.width, map.height, Global.asset('assets/images/tiles.png'), map.tileWidth, map.tileHeight,
				FlxTilemapAutoTiling.OFF, 1, 1, 1)
				.setPosition(offset.x, offset.y);
			add(layer);

			return layer;
		}
		return null;
	}

	function switch_ai_mode()
		player2.ai_mode = current_ai_mode;
}
