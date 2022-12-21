package squidzz.actors;

class Projectile extends FightableObject {
	public var owner:Fighter;

	public function new(?X:Float, ?Y:Float, type:String, owner:Fighter) {
		super(X, Y, type);

		visible = false;

		set_group(owner.group);
		set_team(owner.team);
	}
}
