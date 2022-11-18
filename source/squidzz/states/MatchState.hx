package squidzz.states;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;
import squidzz.actors.DamageSource;
import squidzz.actors.Fighter;
import squidzz.display.DebugUi;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;
import squidzz.rollback.Rollback;

class MatchState extends BaseState {
	public static var self:MatchState;

    var collisionGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

    var debugUi:DebugUi;

	public var rollback:Rollback<RollbackState>;
	public var player1:Fighter;
	public var player2:Fighter;

	var debugUi:DebugUi;

	public var damage:FlxTypedGroup<DamageSource> = new FlxTypedGroup<DamageSource>();

	override function create() {
		super.create();
		self = this;

		camera.bgColor = 0xff415d66;

        collisionGroup.add(new FlxSprite(0, 456).makeGraphic(960, 84, 0xffa8a8a8));
        collisionGroup.add(new FlxSprite(-64, -100).makeGraphic(64, 640, 0xffa8a8a8));
        collisionGroup.add(new FlxSprite(960, -100).makeGraphic(64, 640, 0xffa8a8a8));
        collisionGroup.forEach((spr) -> spr.immovable = true);
        add(collisionGroup);

		player1 = new Fighter(64, 328, 'assets/images/player-pink.png');
		player2 = new Fighter(768, 328, 'assets/images/player-blue.png');

		player1.opponent = player2;
		player2.opponent = player1;

        #if js
		final playerIndex = Connection.inst.isHost ? 0 : 1;
		#else
		final playerIndex = 0;
		#end
		
        stateGroup = new FlxRollbackGroup(player1, player2, collisionGroup);
        add(stateGroup);

        rollback = new Rollback(
            playerIndex,
            stateGroup,
            blankInput(),
            stateGroup.step,
            stateGroup.unserialize
        );

		rollback = new Rollback(playerIndex, stateGroup, ['up' => false, 'left' => false, 'right' => false], stateGroup.step, stateGroup.unserialize);

		#if js
		Connection.inst.addListeners(() -> {
			trace('Connected in MatchState');
		}, () -> {
			trace('Disconnected in MatchState');
		}, () -> {
			trace('Peer Connected in MatchState');
		}, (message) -> {
			trace('Peer disconnected in MatchState', message);
		}, rollback.handleRemoteInput);
		#end

		add(debugUi = new DebugUi(this));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		rollback.tick(getLocalInput(), elapsed);

		if (Controls.justPressed.PAUSE) {
			debugUi.visible = !debugUi.visible;
		}
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

	override function kill() {
		self = null;
		super.kill();
	}
}
