package squidzz.display;

class FightingStage {
	public var layers:Array<FlxSpriteExt> = [];

	public function new(stage_name:String) {
		switch (stage_name) {
			case "pub":
				create_pub();
			case "sauna":
				create_sauna();
		}
	}

	function create_pole() {}

	function create_pub() {
		add_layer("pub - 1 layer", 0.5, 0.75);
		add_layer("pub 0 layer");
		add_layer("pub +1 layer", 1.1);
		add_layer("pub +2 layer", FlxPoint.weak(0, -40), 1.2);

		for (l in layers)
			l.y -= 200;

		FlxG.camera.setScrollBounds(layers[0].x, layers[0].x + layers[0].width, layers[0].y, layers[0].y + layers[0].height);
	}

	function create_sauna() {
		add_layer("Yeti's Ice Sauna Layer 5", 0.8, 0.8);
		add_layer("Yeti's Ice Sauna Layer 4", 0.7, 0.7);
		add_layer("Yeti's Ice Sauna Layer 3", 0.6, 0.6);
		add_layer("Yeti's Ice Sauna Layer 2", 0.5, 0.5);
		add_layer("Yeti's Ice Sauna Layer 1", 0.4, 0.4);

		for (l in layers)
			l.y -= 180 + 48 + 16;

		FlxG.camera.setScrollBounds(layers[0].x, layers[0].x + layers[0].width, layers[0].y, layers[0].y + layers[0].height);
	}

	function add_layer(layer_name:String, ?position:FlxPoint, ?scroll_x:Float = 1, ?scroll_y:Float = 1) {
		position = position == null ? new FlxPoint() : position;

		var layer:FlxSpriteExt = new FlxSpriteExt(position.x, position.y);
		layer.loadAllFromAnimationSet(layer_name);
		layer.scrollFactor.set(scroll_x, scroll_y);

		layers.push(layer);
	}
}
