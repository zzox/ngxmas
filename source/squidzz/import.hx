#if js
import squidzz.conn.Connection;
#end
import Main;
import flixel.*;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import squidzz.actors.DamageSource;
import squidzz.actors.fighters.*;
import squidzz.ext.FlxSpriteExt;
import squidzz.ext.ListTypes.AnimSetData;
import squidzz.ext.Utils;
import squidzz.states.BaseState;
import ui.Controls;
#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

// Just walk away... everything here is fine
// "No." - Squidly
