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
