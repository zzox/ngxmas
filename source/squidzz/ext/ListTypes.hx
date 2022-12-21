package squidzz.ext;

/**
 * This is default animation sets associated with a particular spritesheet
 */
typedef AnimSetData = {
	var image:String;
	var animations:Array<AnimDef>;
	var dimensions:FlxPoint;
	var offset:FlxPoint;
	var offset_left:FlxPoint;
	var offset_right:FlxPoint;
	var flipOffset:FlxPoint;
	var hitbox:FlxPoint;
	var maxFrame:Int;
	var path:String;
	var reverse_mod:Bool;
}

/**
 * This an animation definition to be used with AnimSetData 
 */
typedef AnimDef = {
	var name:String;
	var frames:String;
	var fps:Int;
	var looping:Bool;
	var linked:String;
}

/**
 * For loading from file-paths.json
 */
typedef PathCacheType = {
	var paths:Array<{file:String, path:String}>;
}

/**
 * Attack Data
 */
typedef AttackDataType = {
	var name:String;
	var animation:String;
	var str_type:String;
	var str_mult:Float;
	var stun:Int;
	var defines:Array<String>;
	var inputs:Array<Array<AttackInput>>;
	var attack_links:Array<String>;
	var attack_inherited_links:Array<{inherits_from:String, except:Array<String>}>;
	var cancellableFrames:Array<Int>;
	var shortcut:Bool;
	var thrust:Array<{
		frames:Array<Int>,
		x:Float,
		y:Float,
		once:Bool,
		fixed:FlxPoint
	}>;
	var drag:Array<{frames:Array<Int>, x:Float, y:Float}>;
	var airOnly:Bool;
	var groundOnly:Bool;
	var flipOnFinish:Bool;
	var hitboxes:Array<HitboxType>;
	var offset_left:FlxPoint;
	var offset_right:FlxPoint;
	var flippableFrames:Array<Int>;
	var fx:Array<{
		frame:Int,
		name:String,
		offset_x:Int,
		offset_y:Int,
		layer:String
	}>;
	var ground_cancel_attack:GroundCancelAttackType;
	var wall_cancel_attack:WallCancelAttackType;
	var opponent_cancel_attack:OpponentCancelAttackType;
	var super_armor:Array<Int>;
	var invincible:Array<Int>;
	var auto_continue:Array<{on_complete:String, time:Int, lock:Bool}>;
	var homing_lock:Array<{frame:Int}>;
	var homing_velocity:Array<{
		frames:Array<Int>,
		speed:Int,
		time:Int,
		once:Bool,
		flip_towards:Bool
	}>;
	var auto_cancel:Array<{
		frames:Array<Int>,
		attack:String,
		radius:Int,
	}>;
	var gravity:Array<{
		frames:Array<Int>,
		amount:Int,
		once:Bool
	}>;
	var learnable:Bool;
	var max_uses:{count:Int, reset_on:String};
	var attack_landed:Bool;
	var input_cancel_attack:Bool;
	var summons:Array<SummonDataType>;
}

typedef HitboxType = {
	frames:Array<Int>,
	melee_id:Int,
	str:Float,
	kb:FlxPoint,
	kb_air:FlxPoint,
	kb_ground:FlxPoint,
	stun:Int,
	bonus_defines:Array<String>,
}

typedef SummonDataType = {
	name:String,
	frames:Array<Int>,
	max:Int
}

/**
 * An input in an attack with whether it's charged/hold
 */
typedef AttackInput = {
	var input:String;
	var input_release:String;
	var charge_time:Int;
}

typedef AsepriteJSON = {
	var meta:{app:String, version:String, frameTags:Array<AsepriteFrameTag>};
}

typedef AsepriteFrameTag = {
	name:String,
	from:Int,
	to:Int,
	color:String
}

typedef GroundCancelAttackType = {
	var name:String;
	var frames:Array<Int>;
}

typedef WallCancelAttackType = {
	var name:String;
	var frames:Array<Int>;
}

typedef OpponentCancelAttackType = {
	var name:String;
	var frames:Array<Int>;
}
