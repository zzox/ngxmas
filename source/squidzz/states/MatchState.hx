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
import squidzz.rollback.Rollback;

class MatchState extends FlxState {
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
        final player2 = new Player(22 * 16, 8 * 16, 'assets/images/player-blue.png');

        final playerIndex = Connection.inst.isHost ? 0 : 1;
        stateGroup = new FlxRollbackGroup(player1, player2, collisionLayer);
        add(stateGroup);

        rollback = new Rollback(
            playerIndex,
            stateGroup,
            [ 'up' => false, 'left' => false, 'right' => false ],
            stateGroup.step,
            stateGroup.unserialize
        );

        Connection.inst.addListeners(
            () -> { trace('connected here???'); },
            () -> { trace('disconnected!'); },
            () -> { trace('peer connected here???'); },
            (message) -> { trace('peer disconnected :(', message); },
            rollback.handleRemoteInput
        );

        add(debugUi = new DebugUi(this));
	}

	override function update (elapsed:Float) {
		super.update(elapsed);

        rollback.tick(
            [
                'up' => Controls.pressed.UP,
                'left' => Controls.pressed.LEFT,
                'right' => Controls.pressed.RIGHT,
            ],
            elapsed
        );

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
