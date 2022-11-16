package squidzz.states;

import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;
import squidzz.actors.Player;
import squidzz.conn.Connection;
import squidzz.display.DebugUi;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;
import squidzz.rollback.Rollback;

// TODO: add updates alongside MatchState.
class TestMatchState extends FlxState {
    var collisionLayer:FlxTilemap;
    var stateGroup:FlxRollbackGroup;
    public var rollback:Rollback<RollbackState>;

    var debugUi:DebugUi;

	override function create () {
		super.create();

        camera.bgColor = 0xff415d66;

        final map = new TiledMap(Global.asset('assets/data/map1.tmx'));
        collisionLayer = createTileLayer(map, 'collision', new FlxPoint(0, -2));
        add(collisionLayer);

        final player1 = new Player(7 * 16, 8 * 16, 'assets/images/player-pink.png');
        // TODO: punching bag opponent
        final player2 = new Player(22 * 16, 8 * 16, 'assets/images/player-blue.png');

        stateGroup = new FlxRollbackGroup(player1, player2, collisionLayer);
        add(stateGroup);
	}

	override function update (elapsed:Float) {
		super.update(elapsed);

        // TODO: simulate input delay
        stateGroup.step([getLocalInput(), blankInput()], elapsed);

        if (Controls.justPressed.PAUSE) {
            debugUi.visible = !debugUi.visible;
        }
	}

    function createTileLayer (map:TiledMap, layerName:String, offset:FlxPoint):Null<FlxTilemap> {
        final layerData = map.getLayer(layerName);
        if (layerData != null) {
            final layer = new FlxTilemap();
            final tileArray = cast(layerData, TiledTileLayer).tileArray;
            layer.loadMapFromArray(tileArray, map.width, map.height, Global.asset('assets/images/tiles.png'),
                map.tileWidth, map.tileHeight, FlxTilemapAutoTiling.OFF, 1, 1, 1)
                .setPosition(offset.x, offset.y);
            add(layer);

            return layer;
        }
        return null;
    }
}
