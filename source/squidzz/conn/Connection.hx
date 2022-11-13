package squidzz.conn;

import haxe.Timer;
import js.html.rtc.IceCandidate;
import js.html.rtc.SessionDescriptionInit;
import squidzz.conn.Rtc;
import squidzz.conn.Ws;

class Connection {
    public static var inst:Conn = new Conn();
}

class Conn {
    // connect to local version
    static inline final WS_URL:String = 'ws://localhost:6969';

    // connect to ngrok from from localhost (ws:// only)
    // static inline final WS_URL:String = 'ws://cf2c-2605-a601-ab03-5e00-c97-839c-cc39-31f6.ngrok.io';

    // connect to heroku
    // static inline final WS_URL:String = 'wss://squidzz.herokuapp.com';

    static inline final PING_INTERVAL:Int = 250;
    public function new () {}

    var ws:Ws;
    var rtc:Rtc;

    /** server stuff **/
    public var isServerConnected:Bool = false;
    public var onServerConnect:Void -> Void;
    public var onServerDisconnect:Void -> Void;

    /** p2p stuff **/
    public var isHost:Bool;
    public var isPeerConnected:Bool = false;
    public var onPeerConnect:Void -> Void;
    public var onPeerDisconnect:String -> Void;

    /** connection stuff **/
    public var roomId:Null<String> = null;

    public var pingTime:Int;
    var lastPingTime:Float;

    public function init (
        onServerConnect:Void -> Void,
        onServerDisconnect:Void -> Void,
        onPeerConnect:Void -> Void,
        onPeerDisconnect:String -> Void
    ) {
        if (isServerConnected || isPeerConnected) {
            trace('connection already exists!');
            return;
        }

        this.onServerConnect = onServerConnect;
        this.onServerDisconnect = onServerDisconnect;
        this.onPeerConnect = onPeerConnect;
        this.onPeerDisconnect = onPeerDisconnect;

        ws = new Ws(
            WS_URL,
            () -> {
                isServerConnected = true;
                this.onServerConnect();
            },
            () -> {
                isServerConnected = false;
                this.onServerDisconnect();
            },
            handleWebsocketMessage
        );

        rtc = new Rtc(
            handleIceCandidate,
            handlePeerMessage,
            () -> {
                startPing();
            }
        );

        // create peer connection
    }

    function handlePeerMessage (message:Dynamic) {
        final type:String = message.type;
        final payload:Dynamic = message.payload;

        switch (type) {
            case 'ping':
                rtc.sendMessage('pong');
            case 'pong':
                trace(Timer.stamp() - lastPingTime);
                pingTime = Math.round((Timer.stamp() - lastPingTime) * 1000);
            case 'confirm':
                if (!isPeerConnected) {
                    rtc.sendMessage('confirm-ack');
                    onPeerConnect();
                }
                isPeerConnected = true;
            case 'confirm-ack':
                if (!isPeerConnected) {
                    onPeerConnect();
                }
            default:
                trace('unhandled peer message', type, payload);
        }
    }

    function startPing () {
        new Timer(PING_INTERVAL).run = () -> {
            if (isHost && !isPeerConnected) {
                rtc.sendMessage('confirm');
            }
            lastPingTime = Timer.stamp();
            rtc.sendMessage('ping');
        };
    }

    public function joinOrCreateRoom () {}

    public function createRoom () {
        if (roomId == null) {
            // MAYBE: a joiningRoom var, OR a ConnectionStatus enum
            sendWsMessage('create-room');
        } else {
            trace('already in room');
        }
    }

    public function joinAnyRoom () {
        if (roomId == null) {
            // MAYBE: a joiningRoom var, OR a ConnectionStatus enum
            sendWsMessage('join-any-room');
        } else {
            trace('already in room');
        }
    }

    function sendWsMessage (type:String, ?payload:Dynamic) {
        if (!isServerConnected) {
            trace('not connected');
            return;
        }

        if (ws == null) {
            trace('Websocket not initialized');
            return;
        }

        ws.send({ type: type, payload: payload });
    }

    function handleWebsocketMessage (message:Dynamic) {
        final payload = message.payload;
        final type:String = message.type;
        switch (type) {
            // We created a room and are the host of it.
            case 'room-created':
                isHost = true;
                roomId = payload;
                rtc.createDataChannel();
            // we created a room and a peer joined.
            case 'peer-joined':
                trace('sending offer');
                rtc.createOffer(onOfferGenerated);
            // we joined as a peer
            case 'joined-room':
                isHost = false;
                roomId = payload;
            case 'sdp-offer':
                trace('got offer', payload);
                rtc.setRemoteDescription(payload, onAnswerGenerated);
            case 'sdp-answer':
                trace('got answer', payload);
                rtc.setAnswer(payload);
            case 'ice-candidate':
                trace('got candidate', payload);
                rtc.addIceCandidate(payload);
            default:
                trace('unhandled message', type, payload);
        }
    }

    function onOfferGenerated (offer:SessionDescriptionInit) {
        sendWsMessage('sdp-offer', { roomId: roomId, offer: offer });
    }

    function onAnswerGenerated (answer:SessionDescriptionInit) {
        sendWsMessage('sdp-answer', { roomId: roomId, answer:answer });
    }

    function handleIceCandidate (candidate:IceCandidate) {
        sendWsMessage('ice-candidate', { roomId: roomId, candidate: candidate });
    }
}
