package squidzz.states;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;
import squidzz.actors.Fighter;
import squidzz.actors.snowman.Snowman;
import squidzz.display.DebugUi;
import squidzz.display.FightingStage;
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

	var debugUi:DebugUi;

	var player1:Fighter;
	var player2:Fighter;

	var stage:FightingStage;

	override function create() {
		super.create();

		camera.bgColor = 0xff415d66;

		// add(new FlxSprite(0, 456).makeGraphic(960, 84, 0xffa8a8a8));

		stage = new FightingStage("pub");

		for (layer in stage.layers)
			add(layer);

		player1 = new Snowman(7 * 16, 328);
		player2 = new Penguin(768, 328);

		player1.opponent = player2;
		player2.opponent = player1;

		player1.x += 300;
		player2.x -= 200;

		stateGroup = new FlxRollbackGroup(player1, player2);
		add(stateGroup);

		player1.set_group(stateGroup);
		player2.set_group(stateGroup);

		for (_ in 0...Rollback.INPUT_DELAY_FRAMES) {
			localInputs.push(blankInput());
		}

		add(new MatchUi());
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// simulate input delay
		localInputs.push(getLocalInput());
		stateGroup.step([localInputs.shift(), blankInput()], elapsed);

		player1.fighter_hit_check(player2);
		player2.fighter_hit_check(player1);

		if (Controls.justPressed.PAUSE) {
			debugUi.visible = !debugUi.visible;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.R]))
			Global.switchState(new TestMatchState());
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
}
