package squidzz.conn;

import haxe.Json;
import js.html.WebSocket;

class Ws {
    var ws:WebSocket;
    public var isOpen:Bool = false;
    var onOpenHandler:Void -> Void;
    var onCloseHandler:Void -> Void;
    var onMessageHandler:Dynamic -> Void;

    public function new (
        url:String,
        onOpen:Void -> Void,
        onClose:Void -> Void,
        onMessage:Dynamic -> Void
    ) {
        ws = new WebSocket(url);
        ws.onmessage = (message) -> {
            final parsed = Json.parse(message.data);
            trace('websocket message', parsed);
            onMessage(parsed);
        }

        ws.onopen = () -> {
            isOpen = true;
            onOpen();
            trace('websocket opened');
        }

        ws.onclose = () -> {
            isOpen = false;
            onClose();
            destroy();
            trace('websocket closed');
        }

        ws.onerror = (e) -> {
            trace('websocket error', e);
        }

        onOpenHandler = onOpen;
        onCloseHandler = onClose;
        onMessageHandler = onMessage;
    }

    public function send (message:Dynamic) {
        if (isOpen) {
            ws.send(Json.stringify(message));
        } else {
            trace('Failed to send message, websocket is closed.');
        }
    }

    public function destroy () {
        onOpenHandler = null;
        onCloseHandler = null;
        onMessageHandler = null;
        ws.onmessage = null;
        ws.onopen = null;
        ws.onclose = null;
        ws.onerror = null;
        ws.close();
    }
}
