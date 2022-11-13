package squidzz.states;

import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;
import squidzz.conn.Connection;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.Rollback;

class MatchState extends FlxState {
    var roomId:FlxText;
    var ping:FlxText;
    var frameNum:FlxText;
    var numFrames:FlxText;

    var collisionLayer:FlxTilemap;
    var stateGroup:FlxRollbackGroup;
    var rollback:Rollback<FlxRollbackGroup>;

	override function create () {
		super.create();

        final map = new TiledMap(Global.asset('assets/data/map1.tmx'));
        collisionLayer = createTileLayer(map, 'collision', new FlxPoint(0, -2));
        add(collisionLayer);

        roomId = new FlxText(16, 16);
        add(roomId);

        ping = new FlxText(16, 32);
        add(ping);

        frameNum = new FlxText(16, 48);
        add(frameNum);

        numFrames = new FlxText(16, 64);
        add(numFrames);

        final playerIndex = Connection.inst.isHost ? 0 : 1;
        stateGroup = new FlxRollbackGroup();

        rollback = new Rollback<FlxRollbackGroup>(
            playerIndex,
            stateGroup,
            [ 'up' => false, 'left' => false, 'right' => false ],
            stateGroup.step
        );

        Connection.inst.addListeners(
            () -> { trace('connected here???'); },
            () -> { trace('disconnected!'); },
            () -> { trace('peer connected here???'); },
            (message) -> { trace('peer disconnected :(', message); },
            rollback.handleRemoteInput
        );
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

        // move to debug ui class
        roomId.text = 'room: ' + Connection.inst.roomId;
        ping.text = 'ping: ${Connection.inst.pingTime}ms';
        frameNum.text = 'frames: ' + rollback.currentFrame;
        numFrames.text = 'unconfirmed frames: ' + rollback.frames.length;
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
