package squidzz.conn;

import js.html.rtc.IceCandidate;
import js.html.rtc.PeerConnection;

class Rtc {
    var pc:PeerConnection;

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
    }
}
