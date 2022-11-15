This is the template minigame for advent 2022.

For the most part, just grab this,
and code your game as usual and I'll know how to include it.

## Setup

Use flixel 5.0.0 via github:
```
haxelib git flixel https://github.com/HaxeFlixel/flixel.git
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons.git
```
Use the latest haxelib releases of everything else.
```
haxelib install lime
haxelib install openfl
haxelib install newgrounds
```

## Making your Own
Copy this template and rename every namespace `templatemg` to whatever unique namespace you've
given your game(Hint: Use Ctrl+Shift+F). This will prevent naming conflicts with the main Advent game, as well as other
minigames.

## Controls
Advent is set up with an advanced control system that takes Gamepads and keyboard buttons and
combines them into one easy to use system. Instead of `FlxG.keys.justPressed.Z` or
`FlxG.gamepads.firstActive.justPressed.A`, you can just use `Controls.justPressed.A`.

Check out the full list of controls, [here](https://github.com/BrandyBuizel/Advent2022/blob/main/source/ui/Controls.hx#L53-L77).
We also plan to add on-screen buttons for mobile.

*But George i need more controller buttons!!*
Anything extra you can add the normal way!

## Caveats
To allow your game to work in both stand-alone as well as in Advent, use `Global` methods
- Use `Global.width/height` instead of `FlxG.width/height`.
- Use `Global.screenCenter(obj, XY)` instead of `obj.screenCenter(XY)`, since the latter uses `FlxG.width`.
- Use `Global.state` instead of `FlxG.state`.
- Use `Global.switchState` and `Global.resetState` instead of `FlxG.switchState` and `FlxG.resetState`.
- Use `Global.asset("assets/images/myFile.png")` whenever passing a path into an asset loader.
- Use `Global.cancelTweensOf` instead of `FlxTween.cancelTweensOf`.

Note: The `Global` and `Controls` class are auto imported everywhere, via `import.hx`.

When played via advent, all your asset paths will be renamed to "assets/templatemg/images/myFile.png",
and in stand-alone mode they will be "assets/images/myFile.png", hence why Global.assets in neccesary.
`AssetPaths.hx` is also not an option.

Any code you want to only run when in stand-alone mode should be wrapped in `#if STAND_ALONE` checks,
similarly and advent-only code should be wrapped in `#if ADVENT`.

Check out more information on Conditional Compilation, [here](https://haxe.org/manual/lf-condition-compilation.html).

## Rollback

This project uses rollback net code. It requires a signaling server, which is built in node.js and websockets. The server assists in the creating of rooms and establishing an initial collection connection between two browser clients. Once the connection is made, the servers connection is no longer needed, but we can keep it in place for other reasons. NOTE: There is no re-connect logic yet.

Both peers send each other messages over the WebRTC datachannel, the main message being sent is input. These are sent every frame. A local user tries to predict a remote users input based on previous input, and when they receive a correction, they roll back to the latest confirmed state and then replay the updated inputs on top to achieve the current state. When implemented correctly, it can closely simulate P2P multiplayer games as if they were being played on the same device.

## Dev Guide

The game state needs to be serialized every frame, and everything needs to be completely deterministic. The `AbsSerialize` interface that the rollback class uses requires serialize and unserialize methods. For this specific case I'm not using the built-in Haxe serializer as the state to be serialized may contain some circular references and maxes out the call stack. Because of this we have to do custom serialization, which requires saving every value that changes over the course of a match. All mutable state must be cloned in such a way to not cause reference issues across frames (unless we want to serialize and unserialize with JSON which is a whole other issue).

### Animation

Animations need to be completely deterministic. When an opponent cues an attack, due to the latency, we will get the input late. Attacks need to have longer wind ups because the remote player will only see the latter part of a Animation. Animations will need to be constructed in such a way that they can jump forward to a certain point so the remote player can at least see part of animations being played.

### Quick start

1. Open the app in two browsers.
2. If not running the signaling locally, use the herokuapp url.
3. Connect. (Z in menu)
4. In one browser, create a room (Z). In the other, join the room (X).
5. Fight should start immediately.
