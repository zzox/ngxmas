package squidzz.actors;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import haxe.Json;
import squidzz.actors.ActorTypes.DamageSourceAttributes;
import squidzz.states.MatchState;

class DamageSource extends FlxRollbackActor {
	public var attributes:DamageSourceAttributes;

	public function new(?X:Float = 0, ?Y:Float = 0, ?stamp:FlxSpriteExt, ?attributes:DamageSourceAttributes) {
		super(X, Y);

		if (stamp != null || attributes == null) {
			stamp = stamp == null ? load_from_attributes(attributes) : stamp;

			makeGraphic(Math.floor(stamp.width), Math.floor(stamp.height), FlxColor.TRANSPARENT, true);
			setSize(stamp.width, stamp.height);
			this.stamp(stamp);
		}

		// TODO: Finish this to work with offsets and such
	}

	function load_from_attributes(source:DamageSourceAttributes):FlxSpriteExt {
		attributes = source;

		setPosition(attributes.position.x, attributes.position.y);

		var stamp:FlxSpriteExt = new FlxSpriteExt();
		stamp.loadAllFromAnimationSet(attributes.source.path);
		stamp.animation.frameIndex = attributes.source.frame;

		return stamp;
	}

	/**
	 * Serializes this DamageSource to a simple JSON object
	 * @param source the DamageSource to stringify
	 */
	public static inline function serialize(source:DamageSource) {
		return Json.stringify(source.attributes);
	}

	/**
	 * Creates a DamageSource from a DamageSourceAttributes objeect
	 * @param source attributes to deserialize
	 * @return DamageSource
	**/
	public static inline function deserialize(source:DamageSourceAttributes):DamageSource {
		var new_damage_source:DamageSource = new DamageSource();
		new_damage_source.load_from_attributes(source);
		return new_damage_source;
	}

	/**
	 * Returns an empty DamageSourceAttributes
	 * @return DamageSourceAttributes
	**/
	public static function get_empty_attributes():DamageSourceAttributes {
		return {
			source: {
				path: '',
				frame: 0
			},
			position: {
				x: 0,
				y: 0
			},
			defines: [],
			base_dmg: 0,
			base_stun: 0
		}
	}
}
