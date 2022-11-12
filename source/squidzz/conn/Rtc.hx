package squidzz.conn;

import js.html.rtc.DataChannel;
import js.html.rtc.IceCandidate;
import js.html.rtc.PeerConnection;
import js.html.rtc.SessionDescription;
import js.html.rtc.SessionDescriptionInit;
import js.lib.Promise;

class Rtc {
    var pc:PeerConnection;
    var datachannel:DataChannel;

    public function new (onIceCandidate:IceCandidate -> Void) {
        pc = new PeerConnection(
            // { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] }
        );

        // Not in haxe?
        // pc.onconnectionstatechange = () -> {
        //     trace('connectionState: ' +  pc.connectionState);
        // }
    
        pc.onsignalingstatechange = (state) -> {
            trace('signalingState: ' +  pc.signalingState);
        }
    
        pc.onicecandidate = (data) -> {
            if (data.candidate != null) {
                onIceCandidate(data.candidate);
            }
        }

        pc.ondatachannel = handleDatachannelOpened;
    }

    function handleDatachannelOpened () {
        trace('channel opened');
    }

    public function handleDatachannelEvents () {
        // alert Connection class that we are live!
    }

    public function createDataChannel () {
        datachannel = pc.createDataChannel('main', { ordered: true });
        datachannel.onopen = () -> {
            handleDatachannelOpened();
        }
    }

    public function createOffer (onOfferGenerated:SessionDescriptionInit -> Void) {
        pc.createOffer().then((offer:SessionDescriptionInit) -> {
            pc.setLocalDescription(offer).then((_:Void) -> {
                onOfferGenerated(offer);
            });
        });
    }

    // following 3 methods can't cast to the types we want so type-checking is
    // done by initializing their type with a dynamic variable.

    // sets a remote description and generates an answer
    public function setRemoteDescription (
        answer:Dynamic, onAnswerGenerated: SessionDescriptionInit -> Void
    ) {
        pc.setRemoteDescription(new SessionDescription(answer)).then((_:Void) -> {
            pc.createAnswer().then((answer:SessionDescriptionInit) -> {
                onAnswerGenerated(answer);
                pc.setLocalDescription(answer);
            });
        });
    }

    // sets an answer only
    public function setAnswer (answer:Dynamic) {
        pc.setRemoteDescription(new SessionDescription(answer));
    }

    // adds and ice candidate
    public function addIceCandidate (candidate:Dynamic) {
        pc.addIceCandidate(new IceCandidate(candidate));
    }
}
