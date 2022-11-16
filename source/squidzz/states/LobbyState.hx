package squidzz.states;

import flixel.FlxState;
import flixel.text.FlxText;
import squidzz.conn.Connection;

class LobbyState extends FlxState {
    var roomId:FlxText;
    var ping:FlxText;

	override function create () {
		super.create();

		final info = new FlxText(0, 0, 0, '', 32);
		info.alignment = CENTER;
		info.text = "Connecting...";
		Global.screenCenter(info);
		add(info);

        roomId = new FlxText(16, 16, 0, '', 32);
        add(roomId);

        ping = new FlxText(16, 32, 0, '', 32);
        add(ping);

        if (!Connection.inst.isServerConnected) {
            Connection.inst.init(
                () -> {
                    info.text = 'Connected!';
                },
                () -> { trace('Disconnected!'); },
                () -> { 
                    Global.switchState(new MatchState());
                },
                (message) -> { trace('peer disconnected :(', message); }
            );
        } else {
            trace('warning, server already connected');
            // TODO: add new listeners?
        }
	}

	override function update (elapsed:Float) {
		super.update(elapsed);

        if (Connection.inst.isServerConnected) {
            if (Controls.justPressed.A) {
                createRoom();
            } else if (Controls.justPressed.B) {
                joinRoom();
            }
        }

        if (Connection.inst.roomId != null) {
            roomId.text = 'room: ' + Connection.inst.roomId;
        }

        if (Connection.inst.pingTime != null) {
            ping.text = 'ping: ${Connection.inst.pingTime}ms';
        }
	}

    function createRoom () {
        Connection.inst.createRoom();
    }

    function joinRoom () {
        Connection.inst.joinAnyRoom();
    }
}
