package squidzz.states;

import flixel.FlxSprite;
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

class MatchState extends FlxState {
    var collisionLayer:FlxTilemap;
    var stateGroup:FlxRollbackGroup;
    public var rollback:Rollback<RollbackState>;
    public var player1:Player;
    public var player2:Player;

    var debugUi:DebugUi;

	override function create () {
		super.create();

        camera.bgColor = 0xff415d66;

        add(new FlxSprite(0, 456).makeGraphic(960, 84, 0xffa8a8a8));

        player1 = new Player(64, 328, 'assets/images/player-pink.png');
        player2 = new Player(768, 328, 'assets/images/player-blue.png');

        player1.opponent = player2;
        player2.opponent = player1;

        final playerIndex = Connection.inst.isHost ? 0 : 1;
        stateGroup = new FlxRollbackGroup(player1, player2);
        add(stateGroup);

        rollback = new Rollback(
            playerIndex,
            stateGroup,
            [ 'up' => false, 'left' => false, 'right' => false ],
            stateGroup.step,
            stateGroup.unserialize
        );

        Connection.inst.addListeners(
            () -> { trace('Connected in MatchState'); },
            () -> { trace('Disconnected in MatchState'); },
            () -> { trace('Peer Connected in MatchState'); },
            (message) -> { trace('Peer disconnected in MatchState', message); },
            rollback.handleRemoteInput
        );

        add(debugUi = new DebugUi(this));
	}

	override function update (elapsed:Float) {
		super.update(elapsed);

        rollback.tick(
            getLocalInput(),
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
