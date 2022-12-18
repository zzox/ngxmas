package squidzz.ext;

using StringTools;
using flixel.util.FlxArrayUtil;

class AttackData {
	static var data:Map<String, Map<String, AttackDataType>> = new Map<String, Map<String, AttackDataType>>();

	static var DEFAULT_STUN:Int = 10;

	public static function init() {
		Paths.recursive_file_operation("assets", "attacks.xml", get_all_attack_data);
	}

	public static function get_available_attacks(fighter_name:String, current_attack:String):Array<AttackDataType> {
		var all_attacks:Map<String, AttackDataType> = data.get(fighter_name);

		var available_attacks:Array<AttackDataType> = [];

		for (attack_link in all_attacks.get(current_attack).attack_links)
			available_attacks.push(all_attacks.get(attack_link));

		return available_attacks;
	}

	public static function get_attack_by_name(fighter_name:String, attack_name:String):AttackDataType
		return data.get(fighter_name).get(attack_name);

	static function get_all_attack_data(file:String):String {
		var xml:Xml = Utils.XMLloadAssist(file);
		var fighter_name:String = file.split("/").last().replace("-attacks.xml", "");

		data.set(fighter_name, new Map<String, AttackDataType>());

		for (attack in xml.elementsNamed("root").next().elementsNamed("attack")) {
			var attackData:AttackDataType = {
				name: "",
				animation: "",
				str_type: "",
				str_mult: 0,
				stun: 10,
				defines: [],
				inputs: [],
				attack_links: [],
				attack_inherited_links: [],
				cancellableFrames: [],
				shortcut: false,
				thrust: [],
				drag: [],
				airOnly: false,
				groundOnly: false,
				flipOnFinish: false,
				hitboxes: [],
				offset_right: null,
				offset_left: null,
				flippableFrames: [],
				fx: [],
				ground_cancel_attack: "",
				super_armor: [],
				invincible: [],
				auto_continue: [],
				homing_lock: [],
				homing_velocity: [],
				auto_cancel: [],
				gravity: [],
				learnable: false,
				max_uses: null,
				attack_landed: false
			};

			attackData.name = attack.get("name");
			attackData.animation = attack.get("name");

			var properties:Xml = attack.elementsNamed("properties").next();

			attackData.airOnly = attack.elementsNamed("air").hasNext();
			attackData.groundOnly = attack.elementsNamed("ground").hasNext();
			attackData.flipOnFinish = attack.elementsNamed("flipOnFinish").hasNext();

			if (properties != null) {
				if (properties.get("str") != null) {
					attackData.str_type = properties.get("str").indexOf("estr") > -1 ? "estr" : "mstr";
					attackData.str_mult = Std.parseFloat(properties.get("str").split("*")[1]);
				}

				if (properties.get("stun") != null)
					attackData.stun = Std.parseInt(properties.get("stun"));

				if (properties.get("defines") != null && properties.get("defines").length > 0)
					for (define in properties.get("defines").split(","))
						attackData.defines.push(define);
			}

			for (link in attack.elementsNamed("link"))
				attackData.attack_links.push(link.get("attack"));

			for (inherit in attack.elementsNamed("inherits"))
				attackData.attack_inherited_links.push({
					inherits_from: inherit.get("from"),
					except: inherit.get("except") != null ? inherit.get("except").split(",") : []
				});

			for (max_uses in attack.elementsNamed("max_uses"))
				attackData.max_uses = {count: Std.parseInt(max_uses.get("count")), reset_on: max_uses.get("reset_on")};

			attackData.ground_cancel_attack = get_xml_atr(attack, "ground_cancel_attack", "name");

			for (fx in attack.elementsNamed("fx")) {
				var offsetSplit:Array<String> = fx.get("offset") != null ? fx.get("offset").split(",") : [];
				attackData.fx.push({
					frame: Std.parseInt(fx.get("frame")),
					name: fx.get("name"),
					offset_x: offsetSplit.length > 0 ? Std.parseInt(offsetSplit[0]) : 0,
					offset_y: offsetSplit.length > 1 ? Std.parseInt(offsetSplit[1]) : 0,
					layer: fx.get("layer")
				});
			}

			if (attack.elementsNamed("super_armor").hasNext())
				attackData.super_armor = Utils.animFromString(attack.elementsNamed("super_armor").next().get("frames"));

			if (attack.elementsNamed("attack_landed").hasNext())
				attackData.attack_landed = true;

			// think, Aine, think!
			if (attack.elementsNamed("invincible").hasNext())
				attackData.invincible = Utils.animFromString(attack.elementsNamed("invincible").next().get("frames"));

			for (auto_continue in attack.elementsNamed("auto_continue"))
				attackData.auto_continue.push({
					on_complete: auto_continue.get("on_complete"),
					time: auto_continue.get("time") != null ? Std.parseInt(auto_continue.get("time")) : 0,
					lock: auto_continue.get("lock") == "true"
				});

			for (auto_cancel in attack.elementsNamed("auto_cancel"))
				attackData.auto_cancel.push({
					frames: Utils.animFromString(auto_cancel.get("frames")),
					attack: auto_cancel.get("attack"),
					radius: Std.parseInt(auto_cancel.get("radius"))
				});

			for (homing_lock in attack.elementsNamed("homing_lock"))
				attackData.homing_lock.push({
					frame: Std.parseInt(homing_lock.get("frame")),
				});

			for (gravity in attack.elementsNamed("gravity"))
				attackData.gravity.push({
					frames: Utils.animFromString(gravity.get("frames")),
					amount: gravity.get("amount") != "default" ? Std.parseInt(gravity.get("amount")) : -999,
					once: gravity.get("once") == "true"
				});

			for (homing_velocity in attack.elementsNamed("homing_velocity"))
				attackData.homing_velocity.push({
					frames: Utils.animFromString(homing_velocity.get("frames")),
					speed: homing_velocity.get("speed") != null ? Std.parseInt(homing_velocity.get("speed")) : 60,
					time: homing_velocity.get("time") != null ? Std.parseInt(homing_velocity.get("time")) : 0,
					once: homing_velocity.get("once") == "true",
					flip_towards: homing_velocity.get("flip_towards") == "true"
				});

			if (attack.elementsNamed("input").hasNext()) {
				for (inputSet in attack.elementsNamed("input")) {
					var cIndex:Int = attackData.inputs.length;
					attackData.inputs[cIndex] = [];
					for (control in inputSet.get("controls").split(",")) {
						var input_parts:Array<String> = StringTools.trim(control).split("_");
						var charge_time:Int = input_parts.length > 2 ? Std.parseInt(input_parts[2]) : 1;
						attackData.inputs[cIndex].push({
							input: charge_time <= 1 ? input_parts[0] : input_parts[0] + "_hold",
							input_release: charge_time > 1 && input_parts[1] == "CHARGE" ? input_parts[0] + "_release" : "",
							charge_time: charge_time
						});
					}
				}
			}

			if (attack.elementsNamed("learnable").hasNext())
				attackData.learnable = true;

			if (attack.elementsNamed("cancellable").hasNext())
				attackData.cancellableFrames = Utils.animFromString(attack.elementsNamed("cancellable").next().get("frames"));

			for (box in attack.elementsNamed("hitbox")) {
				var split:Array<String> = box.get("kb") != null ? box.get("kb").split(",") : [];
				attackData.hitboxes.push({
					frames: Utils.animFromString(box.get("frames")),
					melee_id: box.get("melee_id") != null ? Std.parseInt(box.get("melee_id")) : -999,
					str: box.get("str") != null ? Std.parseFloat(box.get("str")) : 0,
					kb: new FlxPoint(Std.parseInt(box.get("kb").split(",")[0]), Std.parseInt(box.get("kb").split(",")[1])),
					stun: box.get("stun") != null ? Std.parseInt(box.get("stun")) : DEFAULT_STUN,
					bonus_defines: box.get("bonus_defines") != null ? box.get("bonus_defines").split(",") : []
				});
			}

			for (drag in attack.elementsNamed("drag")) {
				var split:Array<String> = drag.get("rates").split(",");
				attackData.drag.push({
					frames: Utils.animFromString(drag.get("frames")),
					x: Std.parseFloat(split[0]),
					y: Std.parseFloat(split[1])
				});
			}

			for (thrust in attack.elementsNamed("thrust")) {
				var split:Array<String> = thrust.get("velocity").split(",");
				attackData.thrust.push({
					frames: Utils.animFromString(thrust.get("frames")),
					x: Std.parseInt(split[0]),
					y: Std.parseInt(split[1]),
					once: thrust.get("once") == "true"
				});
			}

			if (attack.elementsNamed("flippable").hasNext())
				attackData.flippableFrames = Utils.animFromString(attack.elementsNamed("flippable").next().get("frames"));

			if (attack.elementsNamed("offset").hasNext()) {
				var offsetXML:Xml = attack.elementsNamed("offset").next();
				if (offsetXML.get("right") != null) {
					var dragSplit:Array<String> = offsetXML.get("right").split(",");
					attackData.offset_right = new FlxPoint(Std.parseInt(dragSplit[0]), Std.parseInt(dragSplit[1]));
				}
				if (offsetXML.get("left") != null) {
					var dragSplit:Array<String> = offsetXML.get("left").split(",");
					attackData.offset_left = new FlxPoint(Std.parseInt(dragSplit[0]), Std.parseInt(dragSplit[1]));
				}
			}

			data.get(fighter_name).set(attackData.name, attackData);
		}

		for (attackData in data.get(fighter_name))
			for (inherit in attackData.attack_inherited_links)
				for (inherited_link in data.get(fighter_name).get(inherit.inherits_from).attack_links)
					if (attackData.attack_links.indexOf(inherited_link) <= -1 && inherit.except.indexOf(inherited_link) <= -1)
						attackData.attack_links.push(inherited_link);

		return "Added all links";
	}

	static function get_xml_atr(xml:Xml, element:String, attribute:String):String {
		if (xml.elementsNamed(element).hasNext())
			return xml.elementsNamed(element).next().get(attribute);
		return "";
	}
}
