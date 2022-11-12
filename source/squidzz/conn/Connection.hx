package squidzz.conn;

import haxe.Json;
import js.html.rtc.IceCandidate;
import js.html.rtc.SessionDescription;
import js.html.rtc.SessionDescriptionInit;
import squidzz.conn.Rtc;
import squidzz.conn.Ws;

class Connection {
    public static var inst:Conn = new Conn();
}

class Conn {
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
    public var onPeerConnect:String -> Void;
    public var onPeerDisconnect:String -> Void;

    /** connection stuff **/
    public var roomId:Null<String> = null;

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

        this.onServerConnect = onServerConnect;
        this.onServerDisconnect = onServerDisconnect;
        this.onPeerConnect = onPeerConnect;
        this.onPeerDisconnect = onPeerDisconnect;

        ws = new Ws(
            'ws://localhost:6969',
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

        rtc = new Rtc(handleIceCandidate);

        // create peer connection
    }

    public function joinOrCreateRoom () {}

    public function createRoom () {
        if (roomId == null) {
            // MAYBE: a joiningRoom var
            sendWsMessage('create-room');
        } else {
            trace('already in room');
        }
    }

    public function joinAnyRoom () {
        if (roomId == null) {
            // MAYBE: a joiningRoom var
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

                // old
                // datachannel = pc.createDataChannel('main', { ordered: true })
                // datachannel.onopen = () => {
                //     handleDatachannelEvents()
                //     startPingInterval()
                // }
            case 'peer-joined':
                trace('sending offer');
                rtc.createOffer(onOfferGenerated);

                // old
                // const offer = await pc.createOffer()
                // await pc.setLocalDescription(offer)
            case 'joined-room':
                isHost = false;
                roomId = payload;
            case 'sdp-offer':
                trace('got offer', payload);

                rtc.setRemoteDescription(payload, onAnswerGenerated);

                // old
                // sendWsMessage('sdp-answer', { roomId: roomId, answer:answer })
                // await pc.setRemoteDescription(payload)
                // const answer = await pc.createAnswer()
                // await pc.setLocalDescription(answer)
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

    function handlePeerMessage (message:Dynamic) {}
}
