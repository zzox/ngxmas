#if js
import squidzz.conn.Connection;
#end
import Main;
import flixel.*;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import squidzz.actors.DamageSource;
import squidzz.actors.FightableObject;
import squidzz.actors.FlxRollbackActor;
import squidzz.actors.fighters.*;
import squidzz.ext.AttackData;
import squidzz.ext.FlxSpriteExt;
import squidzz.ext.ListTypes.AnimSetData;
import squidzz.ext.ListTypes.AttackDataType;
import squidzz.ext.Lists;
import squidzz.ext.Paths;
import squidzz.ext.SoundPlayer;
import squidzz.ext.Utils;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;
import squidzz.states.BaseState;
import ui.Controls;

using Math;
using StringTools;
using flixel.util.FlxArrayUtil;

#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

// Just walk away... everything here is fine
// "No." - Squidly
