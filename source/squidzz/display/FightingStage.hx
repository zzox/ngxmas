package squidzz.display;

import squidzz.actors.FlxRollbackActor;

class FightingStage {
	public var layers:Array<FlxRollbackActor> = [];

	public function new(stage_name:String) {
		switch (stage_name) {
			case "pub":
				create_pub();
		}
	}

	function create_pub() {
		add_layer("pub-4", 0.5, 0.75);
		add_layer("pub-3");
		add_layer("pub-2");
		add_layer("pub-1");

		for (l in layers)
			l.y -= 180;
	}

	function add_layer(layer_name:String, ?position:FlxPoint, ?scroll_x:Float = 1, ?scroll_x:Float = 1) {
		position = position == null ? new FlxPoint() : position;

		var layer:FlxRollbackActor = new FlxRollbackActor(position.x, position.y);
		layer.loadAllFromAnimationSet(layer_name);
		layer.scrollFactor.set(scroll_x, scroll_x);

		layers.push(layer);
	}
}
