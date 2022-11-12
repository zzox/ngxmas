package squidzz.conn;

import squidzz.conn.Ws;
import squidzz.conn.Rtc;

class Connection {
    public static var inst:Conn = new Conn();
}

class Conn {
    public function new () {}

    var ws:Ws;
    var rtc:Rtc;

    /** server stuff **/
    public var isServerConnected:Bool = false;
    public var onServerConnect:String -> Void;
    public var onServerDisconnect:String -> Void;

    /** p2p stuff **/
    public var isHost:Bool;
    public var isPeerConnected:Bool = false;
    public var onPeerConnect:String -> Void;
    public var onPeerDisconnect:String -> Void;

    public function init (
        onServerConnect:Void -> Void,
        onServerDisconnect:Void -> Void,
        onPeerConnect:String -> Void,
        onPeerDisconnect:String -> Void
    ) {
        if (isServerConnected || isPeerConnected) {
            trace('connection already exists!');
            return;
        }

        ws = new Ws(
            'ws://localhost:6969',
            onServerConnect,
            onServerDisconnect,
            handleWebsocketMessage
        );

        // create peer connection
    }

    public function joinOrCreateRoom () {}
    public function createRoom () {}
    public function joinRoom () {}
    public function handleWebsocketMessage (message:Dynamic) {}
    public function handlePeerMessage (message:Dynamic) {}
}
