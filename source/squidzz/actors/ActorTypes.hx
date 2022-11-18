package squidzz.actors;

typedef DamageSourceAttributes = {
	var source:{path:String, frame:Int}
	var position:{x:Float, y:Float};
	var defines:Array<String>;
	var base_dmg:Int;
	var base_stun:Int;
}

/**Damage Defines for special interactions, specific numbers don't mean much
 * We might not need a lot of these
**/
enum abstract DamageDefines(Int) from Int to Int {
	/** Highs get beat by crouch/regular guard */
	var HIGH:Int = 101;

	/**Lows get blocked by crouch guard but go through regular guard*/
	var LOW:Int = 102;

	/**Overheads break crouch guard*/
	var OVERHEAD:Int = 103;

	/**Grabs beat all guards*/
	var GRAB:Int = 104;

	/**Unblockable beats all guards*/
	var UNBLOCKABLE:Int = 105;

	/**This is an enhanced attack*/
	var EX:Int = 106;

	/** This attack is attached to the body */
	var MELEE:Int = 201;

	/** This attack is a projectile */
	var PROJECTILE:Int = 202;

	/** This attack spikes i.e. stops all upwards momentum for the oppent and sends them straight down */
	var METEOR:Int = 301;

	/** This attack cannot be interrupted, but takes damage */
	var SUPER_ARMORED:Int = 302;

	/** This attack takes no damage during it at all */
	var INVINCIBLE:Int = 303;

	/** This attack is a parry */
	var PARRY:Int = 304;

	/** This attack will cause the attacker to follow */
	var TRACKING:Int = 305;

	/** Zap zap big stun */
	var ELECTRIC:Int = 401;

	/** Stops you entirely */
	var FREEZING:Int = 402;

	/** Fuck do I know */
	var BURNING:Int = 403;

	/** Breaks through crouching/standing guards and causes increased stun when it does*/
	var EARTHQUAKE:Int = 404;
}

enum abstract JumpDirection(Int) from Int to Int {
	var NONE:Int = 0;
	var FORWARDS:Int = 1;
	var BACKWARDS:Int = 2;
	var NEUTRAL:Int = 3;
}

enum abstract WalkDirection(Int) from Int to Int {
	var NONE:Int = 0;
	var FORWARDS:Int = 1;
	var BACKWARDS:Int = 2;
	var NEUTRAL:Int = 3;
}

enum abstract BlockingState(Int) from Int to Int {
	var NONE:Int = 0;
	var STANDING:Int = 1;
	var CROUCHING:Int = 2;
	var INVINCIBLE:Int = 3;
}

enum abstract ControlLock(Int) from Int to Int {
	/**You can do anything */
	var FULL_CONTROL:Int = 0;

	var JUMP_OK:Int = 1;
	var MOVE_OK:Int = 2;
	var ATTACK_OK:Int = 3;

	/**Most attacks fall into this category*/
	var ALL_LOCKED:Int = 4;
}

enum abstract JumpingStyle(Int) from Int to Int {
	/** Can't reposition midjump*/
	var TRADITIONAL:Int = 0;

	/**Smash style jumping*/
	var FREESTYLE:Int = 1;
}
