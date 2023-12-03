package squidzz.states;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;
import squidzz.actors.DamageSource;
import squidzz.actors.Fighter;
import squidzz.actors.fighters.Snowman;
import squidzz.display.DebugUi;
import squidzz.display.FightingStage;
import squidzz.display.MatchUi;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;
import squidzz.rollback.Rollback;

class MatchState extends BaseState {
	var collisionLayer:FlxTilemap;
	var stateGroup:FlxRollbackGroup;

	public var rollback:Rollback<RollbackState>;
	public var player1:Fighter;
	public var player2:Fighter;

	var debugUi:DebugUi;
	var match_ui:MatchUi;

	public var damage:FlxTypedGroup<DamageSource> = new FlxTypedGroup<DamageSource>();

	var stage:FightingStage;

	var state:String;

	override function create() {
		super.create();

		camera.bgColor = 0xff415d66;

		// add(new FlxSprite(0, 456).makeGraphic(960, 84, 0xffa8a8a8));

		stage = new FightingStage("pub");

		player1 = new Penguin(7 * 16, 328);
		player2 = new Penguin(768, 328);

		player1.opponent = player2;
		player2.opponent = player1;

		#if js
		final playerIndex = Connection.inst.isHost ? 0 : 1;
		#else
		final playerIndex = 0;
		#end

		stateGroup = new FlxRollbackGroup(player1, player2);
		add(stateGroup);

		add(match_ui = new MatchUi());
		add(debugUi = new DebugUi(this));

		match_ui.update_players(player1, player2);

		var count:Int = 0;
		for (p in [player1, player2]) {
			count++;
			p.set_group(stateGroup);
			p.set_team(count);
			p.set_match_ui(match_ui);
			p.reset_round();
		}

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
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		rollback.tick(getLocalInput(), elapsed);

		// player1.fighter_hit_check(player2);
		// player2.fighter_hit_check(player1);

		if (Controls.justPressed.PAUSE) {
			debugUi.visible = !debugUi.visible;
		}

		// DELETE
		if (FlxG.keys.anyJustPressed([FlxKey.V]))
			Main.SHOW_HITBOX = !Main.SHOW_HITBOX;
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
