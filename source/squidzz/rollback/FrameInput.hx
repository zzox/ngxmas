package squidzz.rollback;

import haxe.Json;

typedef FrameInput = Map<String, Bool>;
typedef RemoteInput = {
    var index:Int;
    var input:FrameInput;
};

function serializeInput (input:FrameInput):String {
    return Json.stringify(input);
}

function deserializeInput (inputString:String):FrameInput {
    return Json.parse(inputString);
}

function compareInput (input1:FrameInput, input2:FrameInput):Bool {
    for (keys in input1.keys()) {
        if (input1[keys] != input2[keys]) {
            return false;
        }
    }

    return true;
}
