package squidzz.actors;

import flixel.animation.FlxAnimationController;
import flixel.math.FlxMath;
import flixel.util.FlxDirectionFlags;
import squidzz.actors.ActorTypes.ControlLock;
import squidzz.actors.ActorTypes.JumpDirection;
import squidzz.actors.ActorTypes.JumpingStyle;
import squidzz.actors.ActorTypes.WalkDirection;
import squidzz.display.FightingStage;
import squidzz.display.MatchUi;
import squidzz.ext.AttackData;
import squidzz.ext.ListTypes.HitboxType;
import squidzz.rollback.FlxRollbackGroup;
import squidzz.rollback.FrameInput;

using Math;

class FightableObject extends FlxRollbackActor {
	/**A seperated hurtbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hurtbox:FlxRollbackActor;

	/**A seperated hitbox anim that track this sprite and  is only used for hitbox spawning*/
	public var hitbox:FlxRollbackActor;

	/**A seperated graphic sheet, this is the only visible sheet*/
	public var visual:FlxRollbackActor;

	public var hurtbox_sheet:FlxRollbackActor;
	public var hitbox_sheet:FlxRollbackActor;
	public var cur_sheet(get, default):FlxRollbackActor;

	var cur_anim(get, default):FlxAnimationController;

	// team 1 = player 1, team 2 = player 2, team 0 = neutral (not used)
	public var team:Int = 0;

	/**Can't take damage inv > 0*/
	var inv:Int = 0;

	/**Can't act while stun > 0*/
	var stun:Int = 0;

	/**No hit animation while active, but takes damage*/
	var SUPER_ARMORED:Bool = false;

	var overlaps_fighter:Bool = false;

	public var collide_overlaps_fighter:Bool = false;

	public var sprite_atlas:Map<String, FlxRollbackActor> = new Map<String, FlxRollbackActor>();

	public var current_attack_data:AttackDataType;

	var match_ui:MatchUi;

	public var attack_hit_success:Bool = false;

	var prefix:String;

	var internal_flags:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(?X:Float = 0, ?Y:Float = 0, prefix:String) {
		super(X, Y);

		this.prefix = prefix;
		type = prefix;

		visual = new FlxRollbackActor();
		hurtbox = new FlxRollbackActor();
		hitbox = new FlxRollbackActor();

		visual.immovable = hurtbox.immovable = hitbox.immovable = true;
		visual.moves = hurtbox.moves = hitbox.moves = false;

		fill_sprite_atlas(prefix);
	}

	override function updateWithInputs(delta:Float, input:FrameInput) {
		update_offsets();
		update_graphics(delta, input);

		hitbox.visible = hurtbox.visible = Main.SHOW_HITBOX;

		super.updateWithInputs(delta, input);
	}

	override function anim(s:String) {
		var prev_sheet:FlxSpriteExt = cur_sheet;

		update_cur_sheet(s);

		if (prev_sheet != cur_sheet) {
			if (cur_anim != null) {
				cur_anim.reset();
				hitbox_sheet.animation.reset();
				hurtbox_sheet.animation.reset();
			}
		}

		cur_sheet.anim(s);
	}

	function update_graphics(delta:Float, input:FrameInput) {
		cur_sheet.updateWithInputs(delta, input);

		hitbox_sheet.animation.frameIndex = cur_anim.frameIndex;
		hurtbox_sheet.animation.frameIndex = cur_anim.frameIndex;

		for (box in [visual, hitbox, hurtbox]) {
			box.velocity.copyFrom(velocity);
			box.acceleration.copyFrom(acceleration);
			box.flipX = flipX;
			box.alpha = box == visual ? 1 : 0.5;
		}

		hitbox_sheet.updateWithInputs(delta, input);
		hurtbox_sheet.updateWithInputs(delta, input);

		stamp_ext(visual, cur_sheet);
		stamp_ext(hitbox, hitbox_sheet);
		stamp_ext(hurtbox, hurtbox_sheet);

		update_offsets();
	}

	function stamp_ext(target_sprite:FlxSpriteExt, stamp_sprite:FlxSpriteExt) {
		if (target_sprite.graphic == null)
			target_sprite.makeGraphic(stamp_sprite.frameWidth, stamp_sprite.frameHeight, FlxColor.TRANSPARENT, true);
		else
			target_sprite.graphic.bitmap.fillRect(target_sprite.graphic.bitmap.rect, FlxColor.TRANSPARENT);

		target_sprite.stamp(stamp_sprite);
	}

	public function current_hitbox_data():HitboxType {
		if (current_attack_data != null)
			for (hitbox_data in current_attack_data.hitboxes)
				if (hitbox_data.frames.indexOf(cur_anim.frameIndex) > -1)
					return hitbox_data;
		return null;
	}

	function update_offsets()
		for (box in [visual, hitbox, hurtbox]) {
			box.offset.copyFrom(!flipX ? cur_sheet.offset_left : cur_sheet.offset_right);
			box.setPosition(x, y);
		}

	function fill_sprite_atlas(prefix:String)
		for (animSet in Lists.animSets)
			if (animSet.image.indexOf(prefix) == 0)
				for (image in [animSet.image, '${animSet.image}-hitbox', '${animSet.image}-hurtbox']) {
					var sprite:FlxRollbackActor = new FlxRollbackActor();
					sprite.loadAllFromAnimationSet(image, animSet.image);
					sprite_atlas.set(image, sprite);
				}

	function find_anim_in_sprite_atlas(anim_name:String):FlxRollbackActor {
		for (sprite in sprite_atlas)
			for (anim in sprite.animation.getNameList())
				if (anim == anim_name)
					return sprite;
		return null;
	}

	function update_cur_sheet(anim_name:String) {
		cur_sheet = find_anim_in_sprite_atlas(anim_name);

		if (cur_sheet == null)
			throw "cur sheet is null, looking for " + anim_name;

		hitbox_sheet = sprite_atlas.get('${cur_sheet.loaded_image}-hitbox');
		hurtbox_sheet = sprite_atlas.get('${cur_sheet.loaded_image}-hurtbox');

		cur_sheet = find_anim_in_sprite_atlas(anim_name);

		if (graphic == null)
			makeGraphic(cur_sheet.width.floor(), cur_sheet.height.floor(), FlxColor.WHITE);
	}

	function get_cur_anim():FlxAnimationController
		return cur_sheet.animation;

	function get_cur_sheet():FlxRollbackActor
		return cur_sheet;

	public function set_team(team:Int)
		this.team = team;

	public function set_match_ui(match_ui:MatchUi)
		this.match_ui = match_ui;

	function make_hit_circle(X:Float, Y:Float, blocked:Bool = false) {
		var hit_circle:HitFX = new HitFX(X, Y, group, blocked);
		hit_circle.setPosition(hit_circle.x - hit_circle.width / 2, hit_circle.y - hit_circle.height / 2);
		group.add(hit_circle);
	}

	function add_self_to_group() {
		group.add(this);
		group.add(hitbox);
		group.add(hurtbox);
		group.add(visual);
	}

	public function fighter_hit_check(fighter:FightableObject)
		return;

	function get_object_count(name:String, team:Int = 0):Int {
		var count:Int = 0;
		for (sprite in group)
			if (Std.isOfType(sprite, FightableObject)) {
				var object:FightableObject = cast(sprite, FightableObject);
				if (object.alive && object.type == name && object.team == team)
					count++;
			}
		return count;
	}
}
