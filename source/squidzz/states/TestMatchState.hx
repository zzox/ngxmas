package squidzz.states;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;
import squidzz.actors.Fighter;
import squidzz.display.DebugUi;
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
    var collisionGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	var debugUi:DebugUi;

	override function create() {
		super.create();

		camera.bgColor = 0xff415d66;

        collisionGroup.add(new FlxSprite(0, 456).makeGraphic(960, 84, 0xffa8a8a8));
        collisionGroup.add(new FlxSprite(-64, -100).makeGraphic(64, 640, 0xffa8a8a8));
        collisionGroup.add(new FlxSprite(960, -100).makeGraphic(64, 640, 0xffa8a8a8));
        collisionGroup.forEach((spr) -> spr.immovable = true);
        add(collisionGroup);

		final player1 = new Penguin(7 * 16, 328);
		// TODO: punching bag opponent
		final player2 = new Penguin(768, 328);

		player1.opponent = player2;
		player2.opponent = player1;

        stateGroup = new FlxRollbackGroup(player1, player2, collisionGroup);
        add(stateGroup);

		for (_ in 0...Rollback.INPUT_DELAY_FRAMES) {
			localInputs.push(blankInput());
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

        // simulate input delay
        localInputs.push(getLocalInput());
        stateGroup.step([localInputs.shift(), blankInput()], elapsed);
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
